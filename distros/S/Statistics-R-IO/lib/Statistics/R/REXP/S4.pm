package Statistics::R::REXP::S4;
# ABSTRACT: an R closure
$Statistics::R::REXP::S4::VERSION = '1.0001';
use 5.010;

use Scalar::Util qw(blessed);

use Class::Tiny::Antlers qw(-default around);
use namespace::clean;

extends 'Statistics::R::REXP';


use constant sexptype => 'S4SXP';

has class => (
    is => 'ro',
);

has 'package' => (
    is => 'ro',
);

has slots => (
    is => 'ro',
    default => sub { {} },
);

use overload
    '""' => sub { shift->_to_s };

sub BUILD {
    my ($self, $args) = (shift, shift);

    # Required attribute
    die "Attribute 'class' is required" unless defined $args->{class};
    
    # Required attribute type
    die "Attribute 'class' must be a scalar value" unless defined($self->class) && !ref($self->class);
    
    die "Attribute 'slots' must be a reference to a hash of REXPs or undefs" if ref($self->slots) ne 'HASH' ||
        grep { defined($_) && ! (blessed($_) && $_->isa('Statistics::R::REXP')) } values(%{$self->slots});
    
    die "Attribute 'package' must be a scalar value" unless defined($self->package) && !ref($self->package);
}

around _eq => sub {
    my $orig = shift;
    return unless $orig->(@_);
    my ($self, $obj) = (shift, shift);
    Statistics::R::REXP::_compare_deeply($self->class, $obj->class) &&
        Statistics::R::REXP::_compare_deeply($self->slots, $obj->slots) &&
        Statistics::R::REXP::_compare_deeply($self->package, $obj->package)
};

sub _to_s {
    my $self = shift;

    "object of class '" . $self->class . "' (package " . $self->package . ") with " .
        scalar(keys(%{$self->slots})) . " slots"
}

sub to_pl {
    my $self = shift;
    
    { class => $self->class, slots => $self->slots, package => $self->package }
}

1; # End of Statistics::R::REXP::S4

__END__

=pod

=encoding UTF-8

=head1 NAME

Statistics::R::REXP::S4 - an R closure

=head1 VERSION

version 1.0001

=head1 SYNOPSIS

    use Statistics::R::REXP::S4;
    
    my $s4 = Statistics::R::REXP::S4->new(class => ['some name'], package = '.GlobalEnv');
    print $s4->class;

=head1 DESCRIPTION

An object of this class represents an R S4 object (C<S4SXP>).

=head1 METHODS

C<Statistics::R::REXP::S4> inherits from L<Statistics::R::REXP>.

=head2 ACCESSORS

=over

=item class

Name of the object's class.

=item package

Name of the package in which the object's class is defined (or
".GlobalEnv" if it's defined in the global environment).

=item slots

A hash reference to the object's slots.

=item sexptype

SEXPTYPE of symbols is C<S4SXP>.

=item to_pl

Perl value of an S4 instance is a hash with elements C<class>, C<slots>, and C<package>.

=back

=head1 BUGS AND LIMITATIONS

Classes in the C<REXP> hierarchy are intended to be immutable. Please
do not try to change their value or attributes.

There are no known bugs in this module. Please see
L<Statistics::R::IO> for bug reporting.

=head1 SUPPORT

See L<Statistics::R::IO> for support and contact information.

=for Pod::Coverage BUILD

=head1 AUTHOR

Davor Cubranic <cubranic@stat.ubc.ca>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2016 by University of British Columbia.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
