package Sub::Alias;
use 5.012;
use strict;
use warnings;

our $VERSION = '1.0.0';

use Keyword::Declare;

sub import {
    keyword alias (Ident $new_ident, Comma, Str $old_name) {
        my $old_ident = substr($old_name, 1, -1);
        return qq! {; no strict "refs"; *{"${new_ident}"} = *{"${old_ident}"}; }; !;
    };

    keyword alias (Str $new_name, Comma, Str $old_name) {
        my $new_ident = substr($new_name, 1, -1);
        my $old_ident = substr($old_name, 1, -1);
        return qq! {; no strict "refs"; *{"${new_ident}"} = *{"${old_ident}"}; }; !;
    };

    keyword alias (Ident $new_ident, Comma, /\\&(?&PerlIdentifier)/ $sub_ref) {
        my $old_ident = substr($sub_ref, 2);
        return qq! {; no strict "refs"; *{"${new_ident}"} = *{"${old_ident}"}; }; !;
    };

    keyword alias (Str $new_name, Comma, /\\&(?&PerlIdentifier)/ $sub_ref) {
        my $new_ident = substr($new_name, 1, -1);
        my $old_ident = substr($sub_ref, 2);
        my $caller = caller(2);
        return qq! {; no strict "refs"; *{"${new_ident}"} = *{"${old_ident}"}; }; !;
    };

    keyword alias (VariableScalar $new_name, Comma, Str $old_name) {
        my $old_ident = substr($old_name, 1, -1);
        return qq! {; no strict "refs"; *{"${new_name}"} = *{"${old_ident}"}; }; !;
    };

    keyword alias (VariableScalar $new_name, Comma, /\\&(?&PerlIdentifier)/ $sub_ref) {
        my $old_ident = substr($sub_ref, 2);
        return qq! {; no strict "refs"; *{"${new_name}"} = *{"${old_ident}"}; }; !;
    };
}

sub unimport {
    unkeyword alias;
}

1;

__END__

=head1 NAME

Sub::Alias - Simple subroutine alias.

=head1 VERSION

This document describes Sub::Alias version 0.01

=head1 SYNOPSIS

    use Sub::Alias;

    sub name { "David" }
    alias get_name => 'name';

    print get_name; # "David"

=head1 DESCRIPTION

This module does a compile-time code injection to let you define
subroute aliases by names or code refs.

=head1 INTERFACE

By <use Sub::Alias>, an new keyword 'alias' is introduced in the
scope. Let's say there is an existing subroutine named "wine"
and we want to create an alias to it named "vino".

The following 2 ways should be trivial to understand:

    # By name
    alias vino => "wine";

    # By code reference
    alias vino => \&wine;

The first argument can be a scalar variable containing the new name:

    my $n = "vino";
    alias $n => \&wine;

Complex exressions that computes a new name is not supported.

=head1 DEPENDENCIES

L<Keyword::Declare>

=head1 INCOMPATIBILITIES

Perl versions older than 5.12 are not supported.

=head1 BUGS AND LIMITATIONS

Please report any bugs or feature requests to Github Issue at
L<https://github.com/gugod/Sub-Alias/issues>

=head1 AUTHOR

Kang-min Liu  C<< <gugod@gugod.org> >>


=head1 LICENCE AND COPYRIGHT

Copyright (c) 2020, Kang-min Liu C<< <gugod@gugod.org> >>.

This is free software, licensed under:

    The MIT (X11) License


=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.
