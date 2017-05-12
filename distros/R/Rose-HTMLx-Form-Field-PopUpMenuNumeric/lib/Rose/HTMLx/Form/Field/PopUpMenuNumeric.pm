package Rose::HTMLx::Form::Field::PopUpMenuNumeric;

use warnings;
use strict;
use Carp;
use base qw(
    Rose::HTML::Form::Field::PopUpMenu
);

our $VERSION = '0.001';

=head1 NAME

Rose::HTMLx::Form::Field::PopUpMenuNumeric - popup menu for numeric values

=head1 SYNOPSIS

 use Rose::HTMLx::Form::Field::PopUpMenuNumeric;
 my $menu = Rose::HTMLx::Form::Field::PopUpMenuNumeric->new(
        id       => 'mynum',
        name     => 'mynum',
        type     => 'menu',
        class    => 'numeric-popup',
        label    => 'My Number',
        options  => [qw( 1 2 3 )],
        labels   => { 1 => 'one', 2 => 'two', 3 => 'three' },
    );
 $menu->input_value('1');
 $menu->internal_value;  # returns 1
 $menu->input_value(''); 
 $menu->internal_value;  # returns undef

=head1 DESCRIPTION

Rose::HTMLx::Form::Field::PopUpMenuNumeric is like a normal RHTMLO PopUpMenu
but it returns an internal_value() like Rose::HTML::Form::Field::Numeric does.

This module exists mostly to ensure that popup menus representing numeric values
properly return undef instead of an empty string -- an important distinction when
you *really* want a numeric value and not a string.
 
=head1 METHODS

Only new or overridden method are documented here.

=cut

=head2 internal_value

Cribbed verbatim from Rose::HTML::Form::Field::Numeric.

=cut

sub internal_value {
    my ($self) = shift;

    my $value = $self->SUPER::internal_value(@_);

    if ( defined $value ) {
        for ($value) {
            s/-\s+/-/ || s/\+\s+//;
        }
    }

    return ( defined $value && $value =~ /\S/ ) ? $value : undef;
}

# This is $RE{num}{dec} from Regexp::Common::number
my $Match
    = qr{^(?:(?i)(?:[+-]?)(?:(?=[0123456789]|[.])(?:[0123456789]*)(?:(?:[.])(?:[0123456789]{0,}))?)(?:(?:[E])(?:(?:[+-]?)(?:[0123456789]+))|))$};

=head2 validate

Cribbed nearly verbatim from Rose::HTML::Form::Field::Numeric.

=cut

sub validate {
    my ($self) = shift;

    my $ok = $self->SUPER::validate(@_);
    return $ok unless ($ok);

    my $value = $self->internal_value;
    return 1 unless ( defined $value && length $value );

    return $value =~ $Match;
}

1;

__END__

=head1 AUTHOR

Peter Karman, C<< <karman@cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-rose-htmlx-form-field-popupmenunumeric@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.  I will be notified, and then you'll automatically be
notified of progress on your bug as I make changes.

=head1 ACKNOWLEDGEMENTS

The Minnesota Supercomputing Institute C<< http://www.msi.umn.edu/ >>
sponsored the development of this software.

=head1 COPYRIGHT & LICENSE

Copyright 2009 by the Regents of the University of Minnesota.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

