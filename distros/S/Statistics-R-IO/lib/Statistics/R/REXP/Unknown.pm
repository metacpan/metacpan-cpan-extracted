package Statistics::R::REXP::Unknown;
# ABSTRACT: R object not representable in Rserve
$Statistics::R::REXP::Unknown::VERSION = '1.0001';
use 5.010;

use Scalar::Util qw(looks_like_number blessed);

use Class::Tiny::Antlers qw(-default around);
use namespace::clean;

extends 'Statistics::R::REXP';

has sexptype => (
    is => 'ro',
);

use overload
    '""' => sub { 'Unknown' };

sub BUILDARGS {
    my $class = shift;
    my $attributes = {};
    
    if ( scalar @_ == 1) {
        if ( ref $_[0] eq 'HASH' ) {
            $attributes = $_[0]
        }
        else {
            $attributes->{sexptype} = $_[0]
        }
    }
    elsif ( @_ % 2 ) {
        die "The new() method for $class expects a hash reference or a key/value list."
                . " You passed an odd number of arguments\n";
    }
    else {
        $attributes = { @_ };
    }
    
    if (blessed($attributes->{sexptype}) &&
        $attributes->{sexptype}->isa('Statistics::R::REXP::Unknown')) {
        $attributes->{sexptype} = $attributes->{sexptype}->sexptype
    }
    $attributes
}


sub BUILD {
    my ($self, $args) = @_;

    die "Attribute 'sexptype' must be a number in range 0-255" unless
        looks_like_number($self->sexptype) &&
        ($self->sexptype >= 0) && ($self->sexptype <= 255)
}


around _eq => sub {
    my $orig = shift;
    $orig->(@_) and ($_[0]->sexptype eq $_[1]->sexptype);
};


sub to_pl {
    undef
}


1; # End of Statistics::R::REXP::Unknown

__END__

=pod

=encoding UTF-8

=head1 NAME

Statistics::R::REXP::Unknown - R object not representable in Rserve

=head1 VERSION

version 1.0001

=head1 SYNOPSIS

    use Statistics::R::REXP::Unknown;
    
    my $unknown = Statistics::R::REXP::Unknown->new(4);
    say $unknown->sexptype;
    say $unknown->to_pl;

=head1 DESCRIPTION

An object of this class represents an R object that's currently not
representable by the Rserve protocol.

=head1 METHODS

C<Statistics::R::REXP::Unknown> inherits from L<Statistics::R::REXP> and
adds no methods of its own.

=head2 ACCESSORS

=over

=item sexptype

The R L<SEXPTYPE|http://cran.r-project.org/doc/manuals/r-release/R-ints.html#SEXPTYPEs> of the object.

=item to_pl

The Perl value of the unknown type is C<undef>.

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
