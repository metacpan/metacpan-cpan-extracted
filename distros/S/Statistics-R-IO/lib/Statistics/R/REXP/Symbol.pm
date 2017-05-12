package Statistics::R::REXP::Symbol;
# ABSTRACT: an R symbol
$Statistics::R::REXP::Symbol::VERSION = '1.0001';
use 5.010;

use Scalar::Util qw(blessed);

use Class::Tiny::Antlers qw(-default around);
#use Statistics::R::REXP::Types;
use namespace::clean;

extends 'Statistics::R::REXP';


use constant sexptype => 'SYMSXP';

has name => (
    is => 'ro',
    default => '',
);

use overload
    '""' => sub { 'symbol `'. shift->name .'`' };

sub BUILDARGS {
    my $class = shift;
    my $attributes = {};
    
    if ( scalar @_ == 1) {
        if ( ref $_[0] eq 'HASH' ) {
            $attributes = $_[0]
        }
        else {
            $attributes->{name} = $_[0]
        }
    }
    elsif ( @_ % 2 ) {
        die "The new() method for $class expects a hash reference or a key/value list."
                . " You passed an odd number of arguments\n";
    }
    else {
        $attributes = { @_ };
    }
    
    if (blessed($attributes->{name}) &&
        $attributes->{name}->isa('Statistics::R::REXP::Symbol')) {
        $attributes->{name} = $attributes->{name}->name
    }
    $attributes
}

sub BUILD {
    my ($self, $args) = @_;

    die "Attribute 'name' must be a scalar value" unless ref(\$self->name) eq 'SCALAR'
}

around _eq => sub {
    my $orig = shift;
    $orig->(@_) and ($_[0]->name eq $_[1]->name);
};


sub to_pl {
    my $self = shift;
    $self->name
}


1; # End of Statistics::R::REXP::Symbol

__END__

=pod

=encoding UTF-8

=head1 NAME

Statistics::R::REXP::Symbol - an R symbol

=head1 VERSION

version 1.0001

=head1 SYNOPSIS

    use Statistics::R::REXP::Symbol;
    
    my $sym = Statistics::R::REXP::Symbol->new('some name');
    print $sym->name;

=head1 DESCRIPTION

An object of this class represents an R symbol/name object (C<SYMSXP>).

=head1 METHODS

C<Statistics::R::REXP::Symbol> inherits from L<Statistics::R::REXP>.

=head2 ACCESSORS

=over

=item name

String value of the symbol.

=item sexptype

SEXPTYPE of symbols is C<SYMSXP>.

=item to_pl

Perl value of the symbol is just its C<name>.

=back

=head1 BUGS AND LIMITATIONS

Classes in the C<REXP> hierarchy are intended to be immutable. Please
do not try to change their value or attributes.

There are no known bugs in this module. Please see
L<Statistics::R::IO> for bug reporting.

=head1 SUPPORT

See L<Statistics::R::IO> for support and contact information.

=for Pod::Coverage BUILDARGS BUILD

=head1 AUTHOR

Davor Cubranic <cubranic@stat.ubc.ca>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2016 by University of British Columbia.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
