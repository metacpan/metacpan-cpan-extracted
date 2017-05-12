package Statistics::R::REXP;
# ABSTRACT: base class for R objects (C<SEXP>s)
$Statistics::R::REXP::VERSION = '1.0001';
use 5.010;

use Scalar::Util qw( blessed );

use Class::Tiny::Antlers;

has attributes => (
    is => 'ro',
);

use overload
    eq => sub { shift->_eq(@_) },
    ne => sub { ! shift->_eq(@_) };


sub BUILD {
    my ($self, $args) = @_;

    die "This is an abstract class and must be subclassed" if ref($self) eq __PACKAGE__;

    # Required methods
    for my $req ( qw/sexptype to_pl/ ) {
        die "$req method required" unless $self->can($req);
    }
    
    # Required attribute type
    die "Attribute 'attributes' must be a hash reference" if defined $self->attributes && 
        ref($self->attributes) ne 'HASH'
}

sub _eq {
    my ($self, $obj) = (shift, shift);
    return undef unless _mutual_isa($self, $obj);
    
    my $a = $self->attributes;
    my $b = $obj->attributes;

    _compare_deeply($a, $b)
}


## Returns true if either argument is a subclass of the other
sub _mutual_isa {
    my ($a, $b) = (shift, shift);
    
    ref $a eq ref $b ||
        (blessed($a) && blessed($b) &&
         ($a->isa(ref $b) ||
          $b->isa(ref $a)))
}


sub _compare_deeply {
    my ($a, $b) = @_ or die 'Need two arguments';
    if (defined($a) and defined($b)) {
        return 0 unless _mutual_isa($a, $b);
        if (ref $a eq ref []) {
            return undef unless scalar(@$a) == scalar(@$b);
            for (my $i = 0; $i < scalar(@{$a}); $i++) {
                return undef unless _compare_deeply($a->[$i], $b->[$i]);
            }
        } elsif (ref $a eq ref {}) {
            return undef unless scalar(keys %$a) == scalar(keys %$b);
            foreach my $name (keys %$a) {
                return undef unless exists $b->{$name} &&
                    _compare_deeply($a->{$name}, $b->{$name});
            }
        } else {
            return undef unless $a eq $b;
        }
    } else {
        return undef if defined($a) or defined($b);
    }

    return 1;
}


sub is_null {
    return 0;
}


sub is_vector {
    return 0;
}


sub inherits {
    my ($self, $class) = @_;
    my $attributes = $self->attributes;
    return unless $attributes && $attributes->{'class'};
    
    grep {/^$class$/} @{$attributes->{'class'}->to_pl}
}

1; # End of Statistics::R::REXP

__END__

=pod

=encoding UTF-8

=head1 NAME

Statistics::R::REXP - base class for R objects (C<SEXP>s)

=head1 VERSION

version 1.0001

=head1 SYNOPSIS

    use Statistics::R::REXP;
    
    # we usually get REXPs from an RDS file:
    my $rexp = Statistics::R::IO::readRDS('file.rds');
    
    # REXPs are stringifiable
    say $rexp;
    
    # REXPs can be converted to the closest native Perl data type
    print $rexp->to_pl;

=head1 DESCRIPTION

An object of this class represents a native R object. This class
cannot be directly instantiated (it will die if you call C<new> on
it), because it is intended as a base abstract class with concrete
subclasses to represent specific object types.

An R object has a value and an optional set of named attributes, which
themselves are R objects. Because the meaning of 'value' depends on
the actual object type (for example, a vector vs. a C<NULL>, in R
terminology), C<REXP> does not provide a generic value accessor
method, although individual subclasses will typically have one.

=head1 METHODS

=over

=item attributes

Returns a hash reference to the object's attributes.

=item sexptype

Returns the I<name> of the corresponding R SEXP type, as listed in
L<SEXPTYPE|http://cran.r-project.org/doc/manuals/r-release/R-ints.html#SEXPTYPEs>.

=item to_pl

Returns I<Perl> representation of the object's value. This is an
abstract method; see concrete subclasses for the value returned by
specific object types, as well as the way to access the I<R> (-ish)
value of the object, if such makes sense.

=item is_null

Returns TRUE if the object is an R C<NULL> object. In C<REXP>'s
class hierarchy, this is the case only for C<Statistics::REXP::Null>.

=item is_vector

Returns TRUE if the object is an R vector object. In C<REXP>'s class
hierarchy, this is the case only for C<Statistics::REXP::Vector> and
its descendants.

=item inherits CLASS_NAME

Returns TRUE if the object is an instance of R S3-style class
C<CLASS_NAME>, in the same fashion as the R function C<L<base::inherits|http://stat.ethz.ch/R-manual/R-patched/library/base/html/class.html>>.

=back

=head1 OVERLOADS

C<REXP> overloads the stringification, C<eq> and C<ne> methods;
subclasses further specialize for their types if necesssary.

=head1 BUGS AND LIMITATIONS

Classes in the C<REXP> hierarchy are intended to be immutable. Please
do not try to change their value or attributes.

More C<is_*> accessors should be added.

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
