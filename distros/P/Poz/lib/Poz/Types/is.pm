package Poz::Types::is;
use parent 'Poz::Types::scalar';
use 5.032;
use strict;
use warnings;

sub new {
    my ($class, $is) = @_;
    my $opts = {
        is => $is,
        required_error => 'required',
        invalid_type_error => 'Not a ' . $is,
    };
    my $self = $class->SUPER::new($opts);
    return $self;
}

sub rule {
    my ($self, $value) = @_;
    return $self->{required_error} unless defined $value;
    return $self->{invalid_type_error} unless $value->isa($self->{is});
    return;
}

1;

=head1 NAME

Poz::Types::is - Type handling for Poz framework

=head1 SYNOPSIS

    use Poz qw/z/;

    my $is_type = z->is('Some::Class');
    my $obj = bless {}, 'Some::Class';
    my $other_obj = bless {}, 'Some::Other::Class';
    $is_type->parse($obj); # returns $obj
    $is_type->parse($other_obj); # throws exception

=head1 DESCRIPTION

Poz::Types::is provides methods to handle types based on their class within the Poz. It allows setting default values, marking values as nullable or optional, and coercing values.

=head2 METHODS

=over 4

=item new

Creates a new instance of Poz::Types::is.

=item rule

Validates the value against the type.

=back

=head1 SEE ALSO

L<Poz::Types>, L<Poz::Types::scalar>

=head1 AUTHOR

ytnobody E<lt>ytnobody@gmail.comE<gt>

=cut