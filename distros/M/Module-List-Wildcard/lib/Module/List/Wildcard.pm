package Module::List::Wildcard;

our $DATE = '2021-01-16'; # DATE
our $VERSION = '0.004009'; # VERSION

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
    my @prefixes = ($prefix);
    my %seen_prefixes;
    my %results;
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
                    $results{$key} = $return_path ? "$dir/$entry" : undef
                        if $return_path || !exists($results{$key});
                } elsif(($list_prefixes || $recurse) &&
                            ($entry ne '.' && $entry ne '..') &&
                            $entry =~ $dir_rx &&
                            -d join("/", $dir,
                                    $entry)) {
                    my $newmod = $prefix.$entry;
                    my $newpfx = $newmod."::";
                    next if exists $seen_prefixes{$newpfx};
                    $results{$newpfx} = $return_path ? "$dir/$entry/" : undef
                        if ($return_path || !exists($results{$newpfx})) && $list_prefixes;
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
                    $results{$key} = $return_path ? "$dir/$entry" : undef;
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
# ABSTRACT: A fork of Module::List that groks wildcard

__END__

=pod

=encoding UTF-8

=head1 NAME

Module::List::Wildcard - A fork of Module::List that groks wildcard

=head1 VERSION

This document describes version 0.004009 of Module::List::Wildcard (from Perl distribution Module-List-Wildcard), released on 2021-01-16.

=head1 SYNOPSIS

Use like you would L<Module::List>, e.g.:

 use Module::List::Wildcard qw(list_modules);

 $id_modules = list_modules("Data::ID::", { list_modules => 1});
 $prefixes = list_modules("", { list_prefixes => 1, recurse => 1 });

Wildcard support:

 $modules = list_modules("Module::P*", { wildcard => 1, list_modules => 1});
 $modules = list_modules("Module::P**", { wildcard => 1, list_modules => 1});

C<all> option:

 $modules = list_modules("Module::", { list_modules => 1, all => 1});

=head1 DESCRIPTION

This module is a fork of L<Module::List>. It's exactly like Module::List 0.004,
except for the following differences:

=over

=item * lower startup overhead (with some caveats)

It strips the usage of L<Exporter>, L<IO::Dir>, L<Carp>, L<File::Spec>, with the
goal of saving a few milliseconds (a casual test on my PC results in 11ms vs
39ms).

Path separator is hard-coded as C</>.

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

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Module-List-Wildcard>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Module-List-Wildcard>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://github.com/perlancar/perl-Module-List-Wildcard/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Module::List>

L<Module::List::Tiny>

L<Module::List::More>, from which Module::List::Wildcard is actually forked
from. Module::List::More contains more features, including wildcard support. I'm
currently maintainng both modules. Eventually this duplication might be resolved
in the future.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021, 2020, 2019 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
