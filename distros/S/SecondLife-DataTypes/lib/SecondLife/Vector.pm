package SecondLife::Vector;
{
  $SecondLife::Vector::VERSION = '0.900';
}
# ABSTRACT: Second Life's vectors (an x, y and z representing a location );
use Any::Moose;
use Regexp::Common qw/ RE_num_real /;

has [qw(x y z)] => (is=>'rw', isa=>'Num');
use overload q{""} => \&stringify;

sub BUILDARGS {
    my $self = shift;
    if ( @_ == 1 ) {
        my( $vec ) = @_;
        my $num = RE_num_real();
        if ( $vec =~ /^ [(<] \s* ($num), \s* ($num), \s* ($num) \s* [)>] $/xo ) {
            return { x=> $1, y=> $2, z=> $3 };
        }
        else {
            require Carp;
            Carp::croak( "Could not parse a vector from $vec" );
        }
    }
    else {
        return { @_ };
    }
}

sub stringify {
    my $self = shift;
    return "<".join(", ",$self->x,$self->y,$self->z).">";
}

no Any::Moose;
__PACKAGE__->meta->make_immutable;

1;


__END__
=pod

=head1 NAME

SecondLife::Vector - Second Life's vectors (an x, y and z representing a location );

=head1 VERSION

version 0.900

=head1 SYNOPSIS

    use SecondLife::DataTypes;
    
    my $vec  = SecondLife::Vector->new( "<1,2,3>" );
    my $vec2 = SecondLife::Vector->new( x=>1, y=>2, z=>3 ); # same
    
    print "$vec\n"; # Print out <1, 2, 3>

=head1 DESCRIPTION

This represents a Second Life vector, a location with x, y and z components. 
These objects can be manipulated by methods in SecondLife::Rotation.

=head1 CONSTRUCTOR

=head2 our method new($class: Str $vector_str) returns SecondLife::Vector

=head2 our method new($class: :$x, :$y, :$z) returns SecondLife::Vector

=head1 ATTRIBUTES

=head2 our Num $x is rw

The X value of this vector.

=head2 our Num $y is rw

The Y value of this vector.

=head2 our Num $z is rw

The Z value of this vector.

=head1 METHODS

=head2 our method stringify() returns Str

Returns the Second Life vector representation.

=head1 SEE ALSO

Please see those modules/websites for more information related to this module.

=over 4

=item *

L<SecondLife::DataTypes|SecondLife::DataTypes>

=back

=head1 AUTHOR

Rebecca Turner <becca@referencethis.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Rebecca Turner.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT
WHEN OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER
PARTIES PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND,
EITHER EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
PURPOSE. THE ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE
SOFTWARE IS WITH YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME
THE COST OF ALL NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE LIABLE
TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE THE
SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH
DAMAGES.

=cut

