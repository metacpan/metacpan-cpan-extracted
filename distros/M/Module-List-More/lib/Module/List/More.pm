## no critic: TestingAndDebugging::RequireUseStrict
package Module::List::More;

#IFUNBUILT
# # use strict 'subs', 'vars';
# # use warnings;
#END IFUNBUILT

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2022-08-12'; # DATE
our $DIST = 'Module-List-More'; # DIST
our $VERSION = '0.004011'; # VERSION

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
    if ($options->{wildcard} || $options->{ls_mode}) {
        require String::Wildcard::Bash;
        my $orig_prefix = $prefix;
        #print "DEBUG: orig_prefix = <$orig_prefix>\n";
        my @prefix_parts = split /::/, $prefix;
        pop @prefix_parts if $options->{ls_mode} && @prefix_parts && $orig_prefix !~ /::\z/
            && !String::Wildcard::Bash::contains_wildcard($orig_prefix);
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
        #print "DEBUG: has_wildcard = $has_wildcard\n";
        if ($options->{wildcard} && $has_wildcard) {
            $re_wildcard = String::Wildcard::Bash::convert_wildcard_to_re({path_separator=>':', dotglob=>1, globstar=>1}, $orig_prefix);
            $re_wildcard = qr/\A(?:$re_wildcard)\z/;
        } else {
            $re_wildcard = $orig_prefix =~ /::\z/ ? qr/\A\Q$orig_prefix\E/ : qr/\A\Q$orig_prefix\E(?:\z|::)/;
        }
        #print "DEBUG: re_wildcard = $re_wildcard\n";
        $recurse = 1 if String::Wildcard::Bash::contains_globstar_wildcard($orig_prefix);
        #print "DEBUG: recurse = $recurse\n";
    }
    #print "DEBUG: prefix = <$prefix>\n";

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
    #use DD; dd \@prefixes;
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
                    #print "DEBUG: key=<$key>\n";
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

1;
# ABSTRACT: Module::List, with more options

__END__

=pod

=encoding UTF-8

=head1 NAME

Module::List::More - Module::List, with more options

=head1 VERSION

This document describes version 0.004011 of Module::List::More (from Perl distribution Module-List-More), released on 2022-08-12.

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

=item * Recognize c<ls_mode> option

This makes C<list_modules()> behave more like Unix B<ls> utility. When given
prefix e.g. C<strict> then it will search from the root namespace instead of
from C<strict::> thus finding C<strict.pm> itself. When given prefix e.g.
C<Module::List> it will start search in the C<Module::> namespace instead of
C<Module::List::> thus finding C<Module::List> itself.

However, given C<strict::> or C<Module::List::> will force search from that
namespace.

=back

=for Pod::Coverage .+

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Module-List-More>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Module-List-More>.

=head1 SEE ALSO

L<Module::List>

L<Module::List::Tiny>

L<Module::List::Wildcard> is spun off from this module with the main feature of
wildcard. I might deprecate one of the modules in the future, but currently I
maintain both.

=head1 HISTORY

This module began its life as L<PERLANCAR::Module::List>, my personal
experimental fork of L<Module::List>. The experiment has also produced other
forks like L<Module::List::Tiny>, L<Module::List::Wildcard>.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 CONTRIBUTING


To contribute, you can send patches by email/via RT, or send pull requests on
GitHub.

Most of the time, you don't need to build the distribution yourself. You can
simply modify the code, then test via:

 % prove -l

If you want to build the distribution (e.g. to try to install it locally on your
system), you can install L<Dist::Zilla>,
L<Dist::Zilla::PluginBundle::Author::PERLANCAR>,
L<Pod::Weaver::PluginBundle::Author::PERLANCAR>, and sometimes one or two other
Dist::Zilla- and/or Pod::Weaver plugins. Any additional steps required beyond
that are considered a bug and can be reported to me.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2022, 2020 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Module-List-More>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
