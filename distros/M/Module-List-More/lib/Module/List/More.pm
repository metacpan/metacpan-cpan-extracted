package Module::List::More;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-12-22'; # DATE
our $DIST = 'Module-List-More'; # DIST
our $VERSION = '0.004010'; # VERSION

#IFUNBUILT
# # use strict 'subs', 'vars';
# # use warnings;
#END IFUNBUILT

my $has_globstar;

# do our own exporting to start faster
sub import {
    my $pkg = shift;
    my $caller = caller;
    for my $sym (@_) {
        if ($sym eq 'list_modules') { *{"$caller\::$sym"} = \&{$sym} }
        else { die "$sym is not exported!" }
    }
}

sub list_modules($$) {
    my($prefix, $options) = @_;
    my $trivial_syntax = $options->{trivial_syntax};
    my($root_leaf_rx, $root_notleaf_rx);
    my($notroot_leaf_rx, $notroot_notleaf_rx);
    if($trivial_syntax) {
        $root_leaf_rx = $notroot_leaf_rx = qr#:?(?:[^/:]+:)*[^/:]+:?#;
        $root_notleaf_rx = $notroot_notleaf_rx =
            qr#:?(?:[^/:]+:)*[^/:]+#;
    } else {
        $root_leaf_rx = $root_notleaf_rx = qr/[a-zA-Z_][0-9a-zA-Z_]*/;
        $notroot_leaf_rx = $notroot_notleaf_rx = qr/[0-9a-zA-Z_]+/;
    }

    my $recurse = $options->{recurse};

    # filter by wildcard. we cannot do this sooner because wildcard can be put
    # at the end or at the beginning (e.g. '*::Path') so we still need
    my $re_wildcard;
    if ($options->{wildcard}) {
        require String::Wildcard::Bash;
        my $orig_prefix = $prefix;
        my @prefix_parts = split /::/, $prefix;
        $prefix = "";
        my $has_wildcard;
        while (defined(my $part = shift @prefix_parts)) {
            if (String::Wildcard::Bash::contains_wildcard($part)) {
                $has_wildcard++;
                # XXX limit recurse level to scalar(@prefix_parts), or -1 if has_globstar
                $recurse = 1 if @prefix_parts;
                last;
            } else {
                $prefix .= "$part\::";
            }
        }
        if ($has_wildcard) {
            $re_wildcard = convert_wildcard_to_re($orig_prefix);
        }
        $recurse = 1 if $has_globstar;
    }

    die "bad module name prefix `$prefix'"
        unless $prefix =~ /\A(?:${root_notleaf_rx}::
                               (?:${notroot_notleaf_rx}::)*)?\z/x &&
                                   $prefix !~ /(?:\A|[^:]::)\.\.?::/;

    my $list_modules = $options->{list_modules};
    my $list_prefixes = $options->{list_prefixes};
    my $list_pod = $options->{list_pod};
    my $use_pod_dir = $options->{use_pod_dir};
    return {} unless $list_modules || $list_prefixes || $list_pod;
    my $return_path = $options->{return_path};
    my $return_library_path = $options->{return_library_path};
    my $return_version = $options->{return_version};
    my $all = $options->{all};
    my @prefixes = ($prefix);
    my %seen_prefixes;
    my %results;
    my $_set_or_add_result = sub {
        my ($key, $result_field, $val, $always_all) = @_;
        if (!$result_field) {
            $results{$key} ||= undef;
        } elsif ($all || $always_all) {
            $results{$key}{$result_field} ||= [];
            push @{ $results{$key}{$result_field} }, $val;
        } else {
            $results{$key}{$result_field} = $val
                unless exists $results{$key}{$result_field};
        }
    };
    while(@prefixes) {
        my $prefix = pop(@prefixes);
        my @dir_suffix = split(/::/, $prefix);
        my $module_rx =
            $prefix eq "" ? $root_leaf_rx : $notroot_leaf_rx;
        my $pm_rx = qr/\A($module_rx)\.pmc?\z/;
        my $pod_rx = qr/\A($module_rx)\.pod\z/;
        my $dir_rx =
            $prefix eq "" ? $root_notleaf_rx : $notroot_notleaf_rx;
        $dir_rx = qr/\A$dir_rx\z/;
        foreach my $incdir (@INC) {
            my $dir = join("/", $incdir, @dir_suffix);
            opendir(my $dh, $dir) or next;
            while(defined(my $entry = readdir($dh))) {
                if(($list_modules && $entry =~ $pm_rx) ||
                       ($list_pod &&
                        $entry =~ $pod_rx)) {
                    my $key = $prefix.$1;
                    next if $re_wildcard && $key !~ $re_wildcard;
                    my $path = "$dir/$entry";
                    $_set_or_add_result->($key);
                    $_set_or_add_result->($key, 'module_path', $path) if $return_path;
                    $_set_or_add_result->($key, 'library_path', $incdir) if $return_library_path;
                    if ($return_version)      {
                        require ExtUtils::MakeMaker;
                        my $v = MM->parse_version($path);
                        $v = undef if $v eq 'undef';
                        $_set_or_add_result->($key, 'module_version', $v);
                    }
                } elsif(($list_prefixes || $recurse) &&
                            ($entry ne '.' && $entry ne '..') &&
                            $entry =~ $dir_rx &&
                            -d join("/", $dir,
                                    $entry)) {
                    my $newmod = $prefix.$entry;
                    my $newpfx = $newmod."::";
                    next if exists $seen_prefixes{$newpfx};
                    if ($list_prefixes) {
                        $_set_or_add_result->($newpfx);
                        $_set_or_add_result->($newpfx, 'prefix_paths', "$dir/$entry/", 'always_add') if $return_path;
                        $_set_or_add_result->($newpfx, 'library_path', $incdir, 'always_add') if $return_library_path;
                    }
                    push @prefixes, $newpfx if $recurse;
                }
            }
            next unless $list_pod && $use_pod_dir;
            $dir = join("/", $dir, "pod");
            opendir($dh, $dir) or next;
            while(defined(my $entry = readdir($dh))) {
                if($entry =~ $pod_rx) {
                    my $key = $prefix.$1;
                    next if $re_wildcard && $key !~ $re_wildcard;
                    $_set_or_add_result->($key);
                    $_set_or_add_result->($key, 'pod_path', "$dir/$entry") if $return_path;
                    $_set_or_add_result->($key, 'library_path', $incdir) if $return_library_path;
                }
            }
        }
    }

    # we cannot filter prefixes early with wildcard because we need to dig down
    # first and that would've been prevented if we had a wildcard like *::Foo.
    if ($list_prefixes && $re_wildcard) {
        for my $k (keys %results) {
            next unless $k =~ /::\z/;
            (my $k_nocolon = $k) =~ s/::\z//;
            delete $results{$k} unless $k =~ $re_wildcard || $k_nocolon =~ $re_wildcard;
        }
    }

    return \%results;
}

sub convert_wildcard_to_re {
    $has_globstar = 0;
    my $re = _convert_wildcard_to_re(@_);
    $re = qr/\A$re\z/;
    #print "DEBUG: has_globstar=<$has_globstar>, re=$re\n";
    $re;
}

# modified from String::Wildcard::Bash 0.040's convert_wildcard_to_re
sub _convert_wildcard_to_re {
    my $opts = ref $_[0] eq 'HASH' ? shift : {};
    my $str = shift;

    my $opt_brace   = $opts->{brace} // 1;

    my @res;
    my $p;
    while ($str =~ /$String::Wildcard::Bash::RE_WILDCARD_BASH/g) {
        my %m = %+;
        if (defined($p = $m{bash_brace_content})) {
            push @res, quotemeta($m{slashes_before_bash_brace}) if
                $m{slashes_before_bash_brace};
            if ($opt_brace) {
                my @elems;
                while ($p =~ /($String::Wildcard::Bash::re_bash_brace_element)(,|\z)/g) {
                    push @elems, $1;
                    last unless $2;
                }
                #use DD; dd \@elems;
                push @res, "(?:", join("|", map {
                    convert_wildcard_to_re({
                        bash_brace => 0,
                    }, $_)} @elems), ")";
            } else {
                push @res, quotemeta($m{bash_brace});
            }

        } elsif (defined($p = $m{bash_joker})) {
            if ($p eq '?') {
                push @res, '[^:]';
            } elsif ($p eq '*') {
                push @res, '[^:]*';
            } elsif ($p eq '**') {
                $has_globstar++;
                push @res, '.*';
            }

        } elsif (defined($p = $m{literal_brace_single_element})) {
            push @res, quotemeta($p);
        } elsif (defined($p = $m{bash_class})) {
            # XXX no need to escape some characters?
            push @res, $p;
        } elsif (defined($p = $m{sql_joker})) {
            push @res, quotemeta($p);
        } elsif (defined($p = $m{literal})) {
            push @res, quotemeta($p);
        }
    }

    join "", @res;
}

1;
# ABSTRACT: Module::List, with more options

__END__

=pod

=encoding UTF-8

=head1 NAME

Module::List::More - Module::List, with more options

=head1 VERSION

This document describes version 0.004010 of Module::List::More (from Perl distribution Module-List-More), released on 2020-12-22.

=head1 SYNOPSIS

Use like you would L<Module::List>, e.g.:

 use Module::List::More qw(list_modules);

 $id_modules = list_modules("Data::ID::", { list_modules=>1, return_path=>1, return_library_path=>1, return_version=>1});
 # Sample result:
 # {
 #   'Data::ID::One' => {
 #     module_path=>"/home/s1/perl5/perlbrew/perls/perl-5.30.2/lib/site_perl/5.30.2/Data/ID/One.pm",
 #     library_path=>"/home/s1/perl5/perlbrew/perls/perl-5.30.2/lib/site_perl/5.30.2",
 #     module_version=>'0.01',
 #   },
 #   'Data::ID::Two' => {
 #     module_path=>"/home/s1/perl5/perlbrew/perls/perl-5.30.2/lib/site_perl/5.30.2/Data/ID/Two.pm",
 #     library_path=>"/home/s1/perl5/perlbrew/perls/perl-5.30.2/lib/site_perl/5.30.2",
 #     module_version=>'0.02',
 #   },
 # }

 {
   local @INC = ('lib', @INC);
   $id_modules = list_modules("Data::ID::", { list_modules=>1, all=>1, return_path=>1, return_version=>1});
 }
 # Sample result:
 # {
 #   'Data::ID::One' => {
 #     module_path=>["lib/Data/ID/One.pm", "/home/s1/perl5/perlbrew/perls/perl-5.30.2/lib/site_perl/5.30.2/Data/ID/One.pm"],
 #     module_version=>[undef, '0.01'],
 #   },
 #   'Data::ID::Two' => {
 #     module_path=>["/home/s1/perl5/perlbrew/perls/perl-5.30.2/lib/site_perl/5.30.2/Data/ID/Two.pm"],
 #     module_version=>['0.02'],
 #   },
 # }

=head1 DESCRIPTION

This module is like L<Module::List>, except for the following differences:

=over

=item * lower startup overhead (with some caveats)

It avoids using L<Exporter> and implements its own import(). It avoids
L<IO::Dir>, L<Carp>, L<File::Spec>, with the goal of saving a few milliseconds
(a casual test on my PC results in 11ms vs 39ms).

Path separator is hard-coded as C</>.

=item * Recognize C<all> option

If set to true and C<return_path> is also set to true, will return all found
paths for each module instead of just the first found one. The values of result
will be an arrayref containing all found paths.

=item * Recognize C<return_library_path> option

If set to true, will return a C<library_path> result key, which is the
associated @INC entry that produces the result.

=item * Recognize C<return_version> option

If set to true, will parse module source file with L<ExtUtils::MakeMaker>'s
C<parse_version> and return the result in C<module_version> key. If version
cannot be detected, a proper undefined value C<undef> (instead of the string
C<'undef'>) is returned.

=item * Recognize C<wildcard> option

This boolean option can be set to true to recognize wildcard pattern in prefix.
Wildcard patterns such as jokers (C<?>, C<*>, C<**>), classes (C<[a-z]>), as
well as braces (C<{One,Two}>) are supported. C<**> implies recursive listing
(sets C<recurse> option to 1).

Examples:

 list_modules("Module::P*", {wildcard=>1, list_modules=>1});

results in something like:

 {
     "Module::Patch"             => undef,
     "Module::Path"              => undef,
     "Module::Pluggable"         => undef,
 }

while:

 list_modules("Module::P**", {wildcard=>1, list_modules=>1});

results in something like:

 {
     "Module::Patch"             => undef,
     "Module::Path"              => undef,
     "Module::Path::More"        => undef,
     "Module::Pluggable"         => undef,
     "Module::Pluggable::Object" => undef,
 }

while:

 list_modules("Module::**le", {wildcard=>1, list_modules=>1});

results in something like:

 {
     "Module::Depakable"                => undef,
     "Module::Install::Admin::Bundle"   => undef,
     "Module::Install::Admin::Makefile" => undef,
     "Module::Install::Bundle"          => undef,
     "Module::Install::Makefile"        => undef,
     "Module::Pluggable"                => undef,
 }

=back

=for Pod::Coverage .+

=head1 HISTORY

This module began its life as L<PERLANCAR::Module::List>, my personal
experimental fork of L<Module::List>. The experiment has also produced other
forks like L<Module::List::Tiny>, L<Module::List::Wildcard>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Module-List-More>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Module-List-More>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://github.com/perlancar/perl-Module-List-More/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Module::List>

L<Module::List::Tiny>

L<Module::List::Wildcard> is spun off from this module with the main feature of
wildcard. I might deprecate one of the modules in the future, but currently I
maintain both.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
