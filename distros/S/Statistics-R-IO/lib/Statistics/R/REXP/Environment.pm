package Statistics::R::REXP::Environment;
# ABSTRACT: an R environment
$Statistics::R::REXP::Environment::VERSION = '1.0001';
use 5.010;

use Scalar::Util qw(refaddr blessed);

use Class::Tiny::Antlers qw(-default around);
use namespace::clean;

extends 'Statistics::R::REXP';

use constant sexptype => 'ENVSXP';

has frame => (
    is => 'ro',
    default => sub {
        { }
    },
);

has enclosure => (
    is => 'ro',
);


use overload
    '""' => sub { 'environment '. shift->name };


sub BUILDARGS {
    my $class = shift;
    if ( scalar @_ == 1 ) {
        if ( ref $_[0] eq 'HASH' ) {
            return $_[0];
        } elsif ( blessed $_[0] && $_[0]->isa('Statistics::R::REXP::Environment') ) {
            # copy constructor from another environment
            return { frame => $_[0]->frame,
                     enclosure => $_[0]->enclosure };
        }
        die "Single parameters to new() must be a HASH data"
            ." or a Statistics::R::REXP::Environment object => ". $_[0] ."\n";
    }
    elsif ( @_ % 2 ) {
        die "The new() method for $class expects a hash reference or a key/value list."
                . " You passed an odd number of arguments\n";
    }
    else {
        return {@_};
    }
}


sub BUILD {
    my ($self, $args) = @_;

    # Required attribute type
    die "Attribute 'frame' must be a reference to a hash of REXPs" if ref($self->frame) ne 'HASH' ||
        grep { ! (blessed($_) && $_->isa('Statistics::R::REXP')) } values(%{$self->frame});
    
    die "Attribute 'enclosure' must be an instance of Environment" if defined $self->enclosure &&
        !(blessed($self->enclosure) && $self->enclosure->isa('Statistics::R::REXP::Environment'));
}


around _eq => sub {
    my $orig = shift;
    return unless $orig->(@_);
    my ($self, $obj) = (shift, shift);
    Statistics::R::REXP::_compare_deeply($self->frame, $obj->frame) &&
        Statistics::R::REXP::_compare_deeply($self->enclosure, $obj->enclosure)
};


sub name {
    my $self = shift;
    ($self->attributes && exists $self->attributes->{name}) ?
        $self->attributes->{name} :
        '0x' . sprintf('%x', refaddr $self)
}


sub to_pl {
    die "Environments do not have a native Perl representation"
}


1; # End of Statistics::R::REXP::Environment

__END__

=pod

=encoding UTF-8

=head1 NAME

Statistics::R::REXP::Environment - an R environment

=head1 VERSION

version 1.0001

=head1 SYNOPSIS

    use Statistics::R::REXP::Environment
    
    my $env = Statistics::R::REXP::Environment->new({
        x => Statistics::R::REXP::Character->new(['foo', 'bar']),
        b => Statistics::R::REXP::Double->new([1, 2, 3]),
    });
    print $env->elements;

=head1 DESCRIPTION

An object of this class represents an R environment (C<ENVSXP>).
Environments in R consist of a I<frame>, a set of symbol-value pairs,
and an I<enclosure>, a pointer to an enclosing (also called "parent")
environment. Environments form a tree structure, with a special
I<emptyenv> environment at the root, which has no parent.

These objects represent calls (such as model formulae), with first
element a reference to the function being called, and the remainder
the actual arguments of the call. Names of arguments, if given, are
recorded in the 'names' attribute (itself as
L<Statistics::R::REXP::Character> vector), with unnamed arguments
having name C<''>. If no arguments were named, the environment objects
will not have a defined 'names' attribute.

You shouldn't create instances of this class, it exists mainly to
handle deserialization of C<ENVSXP>s by the C<IO> classes.

=head1 METHODS

C<Statistics::R::REXP:Environment> inherits from
L<Statistics::R::REXP::Vector>, with the added restriction that its
first element has to be a L<Statistics::R::REXP::Symbol> or another
C<Environment> instance. Trying to create a Environment instance that
doesn't follow this restriction will raise an exception.

=head2 ACCESSORS

=over

=item frame

Returns a reference to the hash of symbol-value pairs representing the
environment's frame, i.e., the variable with bound values in the
environment.

=item enclosure

Returns a reference to the parent Environment, if it is defined.

=item name

Environments can be named, although this is not normally settable from
R code. Typically, only the system environments (such as namespaces),
and environments created by C<attach>-ing an object, have a name.

=item sexptype

SEXPTYPE of environments is C<ENVSXP>.

=item to_pl

Environments do not have a native Perl representation and trying to
call this access will raise an exception.

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
