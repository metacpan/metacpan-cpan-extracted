package Perinci::Sub::Dep::pm;

use 5.010001;
use strict;
use warnings;
use Log::ger;

use Perinci::Sub::DepUtil qw(declare_function_dep);

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2022-03-20'; # DATE
our $DIST = 'Perinci-Sub-Dep-pm'; # DIST
our $VERSION = '0.301'; # VERSION

declare_function_dep(
    name => 'pm',
    schema => ['str*' => {}],
    check => sub {
        my ($val) = @_;

        $val = {name=>$val} unless ref $val eq 'HASH';

        my $mod = $val->{name} or return "BUG: Module name not specified in the 'pm' dependency";

        (my $mod_pm = "$mod.pm") =~ s!::!/!g;
        eval { require $mod_pm };
        return "Can't load module $mod: $@" if $@;
        no strict 'refs'; ## no critic: ProhibitNoStrict
        if (defined $val->{min_version}) {
            require Version::Util;
            my $mod_ver = ${"$mod\::VERSION"};
            defined($mod_ver) or return "Can't get version from module $mod";
            log_trace "Comparing version of module $mod ($mod_ver vs minimum wanted $val->{min_version})";
            return "Version of $mod too old ($mod_ver, minimum $val->{min_version})"
                if Version::Util::version_lt($mod_ver, $val->{min_version});
        }
        "";
    }
);

1;
# ABSTRACT: Depend on a Perl module

__END__

=pod

=encoding UTF-8

=head1 NAME

Perinci::Sub::Dep::pm - Depend on a Perl module

=head1 VERSION

This document describes version 0.301 of Perinci::Sub::Dep::pm (from Perl distribution Perinci-Sub-Dep-pm), released on 2022-03-20.

=head1 SYNOPSIS

 # in function metadata
 deps => {
     ...
     pm => 'Foo::Bar',
 }

 # specify version requirement
 deps => {
     ...
     pm => {
         name => 'Foo::Bar',
         min_version => '0.123',
     },
 }

 # specify multiple modules
 deps => {
     all => [
         {pm => 'Foo'},
         {pm => {name=>'Bar', min_version=>'1.23'}},
         {pm => 'Baz'},
     ],
 }

 # specify alternatives
 deps => {
     any => [
         {pm => 'Qux'},
         {pm => 'Quux'},
     ],
 }

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Perinci-Sub-Dep-pm>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Perinci-Sub-Dep-pm>.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 CONTRIBUTOR

=for stopwords Steven Haryanto

Steven Haryanto <stevenharyanto@gmail.com>

=head1 CONTRIBUTING


To contribute, you can send patches by email/via RT, or send pull requests on
GitHub.

Most of the time, you don't need to build the distribution yourself. You can
simply modify the code, then test via:

 % prove -l

If you want to build the distribution (e.g. to try to install it locally on your
system), you can install L<Dist::Zilla>,
L<Dist::Zilla::PluginBundle::Author::PERLANCAR>, and sometimes one or two other
Dist::Zilla plugin and/or Pod::Weaver::Plugin. Any additional steps required
beyond that are considered a bug and can be reported to me.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2022, 2015, 2012 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Perinci-Sub-Dep-pm>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
