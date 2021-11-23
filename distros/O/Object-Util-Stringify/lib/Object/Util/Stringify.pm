package Object::Util::Stringify;

use 5.018000;
use strict;
use warnings;

use Scalar::Util qw(blessed refaddr);

use Exporter qw(import);

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2021-11-23'; # DATE
our $DIST = 'Object-Util-Stringify'; # DIST
our $VERSION = '0.003'; # VERSION

our @EXPORT_OK = qw(
                       set_stringify
                       unset_stringify
               );

my %Overloaded_Packages;
my %Object_Strings; # key=refaddr, val=string
sub set_stringify {
    require overload;

    my ($obj, $str) = @_;

    die "First argument must be a blessed reference" unless blessed($obj);

    my $obj_pkg = ref $obj;
    $Object_Strings{ refaddr($obj) } = $str;
    $obj_pkg->overload::OVERLOAD(q("") => \&_overload_string)
        unless $Overloaded_Packages{$obj_pkg}++;

    # return the obj for convenience
    $obj;
}

sub unset_stringify {
    my ($obj, $str) = @_;

    die "First argument must be a blessed reference" unless blessed($obj);

    my $obj_pkg = ref $obj;
    delete $Object_Strings{ refaddr($obj) };

    # return the obj for convenience
    $obj;
}

sub _overload_string {
    my $obj = shift;
    my $key = refaddr $obj;
    exists($Object_Strings{$key}) ? $Object_Strings{$key} : $obj;
}

1;
# ABSTRACT: Utility routines related to object stringification

__END__

=pod

=encoding UTF-8

=head1 NAME

Object::Util::Stringify - Utility routines related to object stringification

=head1 VERSION

This document describes version 0.003 of Object::Util::Stringify (from Perl distribution Object-Util-Stringify), released on 2021-11-23.

=head1 SYNOPSIS

 use Object::Util::Stringify qw(
     set_stringify
     unset_stringify
 );

 # An easy way to set what string an object should stringify to
 set_stringify($obj, "oh my!");
 print $obj; # => prints "oh my!"

 # Remove stringification
 unset_stringify($obj);
 print $obj; # => prints the standard stringification, e.g. My::Package=HASH(0x562847e245e8)

=head1 DESCRIPTION

Keywords: overload, stringify, stringification

=for Pod::Coverage ^(.+)$

=head1 FUNCTIONS

=head2 set_stringify

Usage:

 set_stringify($obj, $str);

Set object stringification to C<$str>.

Caveats: cloned object currently will not inherit the stringification,
serialization currently does not serialize the stringification information.

=head2 unset_stringify

Usage:

 unset_stringify($obj);

Reset/remove object stringification.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Object-Util-Stringify>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Object-Util-Stringify>.

=head1 SEE ALSO

L<overload>

L<TPrintable>

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
L<Dist::Zilla::PluginBundle::Author::PERLANCAR>, and sometimes one or two other
Dist::Zilla plugin and/or Pod::Weaver::Plugin. Any additional steps required
beyond that are considered a bug and can be reported to me.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Object-Util-Stringify>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
