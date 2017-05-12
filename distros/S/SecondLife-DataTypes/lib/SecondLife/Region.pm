package SecondLife::Region;
{
  $SecondLife::Region::VERSION = '0.900';
}
# ABSTRACT: Second Life's region identifiers (a name, plus a location in the 2d grid of sims)
use Any::Moose;
use overload q{""} => \&stringify;
use Regexp::Common qw/ RE_num_int /;

has 'name' => ( is=>'rw', isa=>'Str' );
has [qw( x y )] => ( is=> 'rw', isa=>'Int' );

sub BUILDARGS {
    my $self = shift;
    my( $region ) = @_;
    my $num = RE_num_int();
    if ( @_==1 ) {
        if ( $region =~ /^ (.*?) \s* \( ($num), \s* ($num) \) $/xo ) {
            return { name=> $1, x=> $2, y=> $3 };
        }
        else {
            require Carp;
            Carp::croak( "Could not parse a region from $region" );
        }
    }
    elsif ( ! (@_ % 2) ) {
        return { @_ };
    }
    else {
        require Carp;
        Carp::croak( "Invalid region constructor" );
    }
}

sub stringify {
    my $self = shift;
    return $self->name . " (" . $self->x . ", " . $self->y .")";
}


no Any::Moose;
__PACKAGE__->meta->make_immutable;

1;


__END__
=pod

=head1 NAME

SecondLife::Region - Second Life's region identifiers (a name, plus a location in the 2d grid of sims)

=head1 VERSION

version 0.900

=head1 SYNOPSIS

    use SecondLife::DataTypes;
    my $region = SecondLife::Region->new( name=>"Dew Drop", x=>236544, y=>242944 );

    # Or from a string, for instance, in a PSGI handler:

    use Plack::Request;
    
    sub psgi_handler {
        my $req = Plack::Request->new( shift );
        my $region = SecondLife::Region->new( $req->header('X-SecondLife-Region') );
        my $res = $req->new_response( 200 );
        $res->content_type('text/plain');
        $res->body(
            "This request was made from the ".$region->name." region of SecondLife\n".
            "Which is located at the global coordinates ".$region->x.", ".$region->y."\n".
            "This would be expressed as $region normally."
        );
        return $res->finalize;
    }

=head1 DESCRIPTION

This parses and emits Second Life region identifiers, which are made up of a
name and coordinates of the region on the grid.  These can be turned into
the global coordinates for the top left of the region by multiplying by 256.

=head1 CONSTRUCTOR

=head2 our method new($class: Str :$name, Int :$x, Int :$y)

=head2 our method new($class: Str $region_str ) returns SecondLife::Region

The constructor either takes a single argument, a region string you want to
parse in the format: Region Name (X, Y)
Or a hash with the attributes you want to have started initialized.

=head1 ATTRIBUTES

=head2 has Str $.name is rw

The name of the region

=head2 has Int $.x is rw

=head2 has Int $.y is rw

The X and Y coordinates of the region on the grid.

=head1 METHODS

=head2 our method stringify() returns Str

Returns the region and coordinates as a string in the same form that Second
Life does.  Evalauting the object as a string will also produce this result.

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

