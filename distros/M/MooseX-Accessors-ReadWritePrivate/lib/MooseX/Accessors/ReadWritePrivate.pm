package MooseX::Accessors::ReadWritePrivate;

use 5.008;
use utf8;
use strict;
use warnings;

use version; our $VERSION = qv('v1.4.0');

use Moose 2.0 qw< >;
use Moose::Exporter 2.0;
use Moose::Util::MetaRole 2.0;

use MooseX::Accessors::ReadWritePrivate::Role::Attribute;


my %metaroles = (
    class_metaroles => {
        attribute => [
            qw< MooseX::Accessors::ReadWritePrivate::Role::Attribute >
        ],
    },
    role_metaroles => {
        applied_attribute => [
            qw< MooseX::Accessors::ReadWritePrivate::Role::Attribute >
        ],
    },
);

Moose::Exporter->setup_import_methods(%metaroles);


1;

__END__

=pod

=encoding utf8

=for stopwords ro rwp

=head1 NAME

MooseX::Accessors::ReadWritePrivate - Name your accessors get_foo() and set_foo() or _set_foo().


=head1 SYNOPSIS

    package Some::Class;

    use Moose;
    use MooseX::Accessors::ReadWritePrivate;

    has foo => {
        is => 'rw',  # Will create get_foo() and set_foo().
        ...
    };
    has _foo => {
        is => 'rw',  # Will create _get_foo() and _set_foo().
        ...
    };
    has __foo => {
        is => 'rw',  # Will create __get_foo() and __set_foo().
        ...
    };
    has bar => {
        is => 'ro',  # Will create get_bar().
        ...
    };
    has bar => {
        is => 'rop',  # Will create _get_bar().
        ...
    };
    has baz => {
        is => 'rpwp', # Will create _get_baz() and _set_baz().
        ...
    };
    has _baz => {
        is => 'rpwp', # Will create _get_baz() and _set_baz().
        ...
    };
    has __baz => {
        is => 'rpwp', # Will create _get_baz() and _set_baz().
        ...
    };

    has special_reader => {
        is      => 'rw',
        reader  => 'blah_blah', # Will still create set_special_reader().
        ...
    };
    has special_writer => {
        is      => 'rw',
        writer  => 'blah_blah', # Will still create get_special_writer().
        ...
    };

    has is_hot => {
        isa => 'Bool',
        is  => 'rw',    # Will create is_hot() and set_is_hot().
        ...
    };
    has is_cold => {
        isa => 'Bool',
        is  => 'ro',    # Will create is_cold().
        ...
    };
    has is_tepid => {
        isa => 'Bool',
        is  => 'rwp',   # Will create is_tepid() and _set_is_tepid().
        ...
    };


=head1 VERSION

This document describes MooseX::Accessors::ReadWritePrivate version 1.4.0.


=head1 DESCRIPTION

This module does not provide any methods.  Simply loading it changes the
default naming policy for the loading class so that accessors are separated
into a selector and a mutator.

Assuming that there is no "p" or "wo" in the C<is> declaration, the selector
will be named the same as the attribute with "get_" prefixed, unless the
attributes is a C<Bool> or a C<Maybe[Bool]>, in which case the selector will
have the same name as the attribute.

If there is no "ro", in the C<is> declaration, a mutator will be created.
Assuming that there is no "p" in the declaration, the mutator will be named
the same as the attribute with "set_" prefixed, modulo leading underscores.

Appending a "p" in the C<is> declaration after a given component indicates
that you want the accessor "private" (as much as anything in Perl is private),
by having a single leading underscore in the name, regardless of the number of
leading underscores in the attribute name.  For example, using "rpw" will make
the selector private and the mutator private and using "rop" will make the
selector private and not create a mutator.

If the attribute has any leading underscores, those will moved to the front of
the accessor names, unless the accessor is supposed to be private, in which
case the mutator will have a single underscore at the front.

To be absolutely plain, here's the complete list of acceptable values for C<is>:

=over

=item rw

=item ro

=item wo

=item rpw

=item rwp

=item rpwp

=item rop

=item wop

=item bare

=back


Unlike many other accessor naming schemes for L<Moose>, specifying a value for
the "reader" only or the "writer" only does not disable the behavior of this
module for the other accessor.


=head1 DIAGNOSTICS

None.


=head1 CONFIGURATION AND ENVIRONMENT

None other than what you specify for your attributes.


=head1 DEPENDENCIES

perl 5.8

L<Moose> 0.94

L<Moose::Exporter>

L<Moose::Util::MetaRole>

L<version>


=head1 AUTHOR

Elliot Shank C<< <perl@galumph.com> >>


=head1 LICENSE AND COPYRIGHT

Copyright ©2009-2010, Elliot Shank C<< <perl@galumph.com> >>.

Based upon L<MooseX::FollowPBP>, copyright ©2008 Dave Rolsky.

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself. See L<perlartistic>.


=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY FOR THE
SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN OTHERWISE
STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES PROVIDE THE
SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER EXPRESSED OR IMPLIED,
INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND
FITNESS FOR A PARTICULAR PURPOSE. THE ENTIRE RISK AS TO THE QUALITY AND
PERFORMANCE OF THE SOFTWARE IS WITH YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE,
YOU ASSUME THE COST OF ALL NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING WILL ANY
COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR REDISTRIBUTE THE
SOFTWARE AS PERMITTED BY THE ABOVE LICENSE, BE LIABLE TO YOU FOR DAMAGES,
INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING
OUT OF THE USE OR INABILITY TO USE THE SOFTWARE (INCLUDING BUT NOT LIMITED TO
LOSS OF DATA OR DATA BEING RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR
THIRD PARTIES OR A FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER
SOFTWARE), EVEN IF SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE
POSSIBILITY OF SUCH DAMAGES.

=cut


# setup vim: set filetype=perl tabstop=4 softtabstop=4 expandtab :
# setup vim: set shiftwidth=4 shiftround textwidth=78 autoindent :
# setup vim: set foldmethod=indent foldlevel=0 :
