package MooseX::Storage::MaybeDeferred;

use strict;
use warnings;
use namespace::autoclean;
use MooseX::Role::Parameterized;

our $VERSION = '0.0.5';

parameter 'default_format' => (
    isa      => 'Defined',
    required => 1,
);

parameter 'default_io' => (
    isa      => 'Defined',
    required => 1,
);

role {
    with 'MooseX::Storage::Deferred';

    my $p = shift;

    around 'thaw' => sub {
        my $orig        = shift;
        my $self        = shift;
        my $packed      = shift;
        my $type        = shift;
        $type->{format} = $p->default_format unless exists $type->{format};

        $self->$orig($packed, $type, @_);
    };
    around 'freeze' => sub {
        my $orig        = shift;
        my $self        = shift;
        my $type        = shift;
        $type->{format} = $p->default_format unless exists $type->{format};

        $self->$orig($type, @_);

    };
    around 'load' => sub {
        my $orig     = shift;
        my $self     = shift;
        my $filename = shift;
        my $type     = shift;
        $type->{io}  = $p->default_io unless exists $type->{io};

        $self->$orig($filename, $type, @_);
    };
    around 'store' => sub {
        my $orig     = shift;
        my $self     = shift;
        my $filename = shift;
        my $type     = shift;
        $type->{io}  = $p->default_io unless exists $type->{io};

        $self->$orig($filename, $type, @_);

    };
};

1;

__END__

=pod

=head1 NAME

MooseX::Storage::MaybeDeferred - A role for the less indecisive programmers

=head1 VERSION

0.0.4

=head1 SYNOPSIS

    package Point;
    use Moose;
    use MooseX::Storage;

    with MooseX::Storage::MaybeDeferred => {
        default_format => 'JSON',
        default_io     => 'File',
    };

    has 'x' => (is => 'rw', isa => 'Int');
    has 'y' => (is => 'rw', isa => 'Int');

    1;

    my $p = Point->new();
    $p->freeze();
    # or
    $p->freeze({format => 'Storable'});

    ...

    $p->store($filename);
    $p->store($filename, {format => 'Storable', io => 'AtomicFile'});

    ...

    my $another_point;
    $another_point = Point->load($filename);
    # or
    $another_point = Point->load($filename, {format => 'JSON', io => 'File'});

=head1 DESCRIPTION

With the module L<MooseX::Storage> you are hard coding the definition of the C<format> and maybe C<io> layer
in the classes you want to serialize. Whenever the methods C<freeze> or C<store> are called, it is not possible
to to change their behaviour. You always get what you have declared.

If you need to serialize into different formats you can use L<MooseX::Storage::Deferred>. Now, whenever you call
C<freeze> or C<store> you B<must> provide parameters which define the format and the io layer.

This module should give you the benefits of both worlds. You need to provide the C<default_format> and
C<default_io> layers in the definitions of the classes which you want to serialize. So classes that
used to use L<MooseX::Storage> should still behave as before. But if you need to serialize into a different format
you have the flexibility of MooseX::Storage::Deferred. Now you B<can> provide the C<format> and C<io> setting at
runtime.

=head1 SEE ALSO

=over

=item L<MooseX::Storage>

=item L<MooseX::Storage::Deferred>

=back

=head1 ACKNOWLEDGEMENTS

Thanks L<www.netdescribe.com>.

=head1 CHANGES

=over

=item version 0.0.5

Fixed tests so it is now  able to run on Perl 5.8.x

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2018 Martin Barth.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See L<http://dev.perl.org/licenses/> for more information.

=cut

