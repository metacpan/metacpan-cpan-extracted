package POE::Filter::JSON;

use Carp;
use JSON::Any;

use strict;
use warnings;

use base qw( POE::Filter );

our $VERSION = '0.04';

sub BUFFER () { 0 }
sub OBJ    () { 1 }
sub PARAMS () { 2 }

sub new {
    my $class = shift;
    croak "$class requires an even number of parameters" if @_ % 2;
    my %opts = @_;
    my %anyopts = ( $opts{json_any} ) ? %{$opts{json_any}} : ();
    bless( [
        [],                         # BUFFER
        JSON::Any->new( %anyopts ), # OBJ
        \%opts,                     # PARAMS
    ], ref $class || $class );
}

sub get {
    my ($self, $lines) = @_;
    my $ret = [];

    foreach my $json (@$lines) {
        if ( my $obj = eval { $self->[ OBJ ]->jsonToObj( $json ) } ) {
            push( @$ret, $obj );
        } else {
            warn "Couldn't convert json to an object: $@";
        }
    }
    return $ret;
}

sub get_one_start {
    my ($self, $lines) = @_;
    $lines = [ $lines ] unless ( ref( $lines ) );
    push( @{ $self->[ BUFFER ] }, @{ $lines } );
}

sub get_one {
    my $self = shift;
    my $ret = [];

    if ( my $line = shift ( @{ $self->[ BUFFER ] } ) ) {
        if ( my $json = eval { $self->[ OBJ ]->jsonToObj( $line ) } ) {
            push( @$ret, $json );
        } else {
            warn "Couldn't convert json to object: $@";
        }
    }

    return $ret;
}

sub put {
    my ($self, $objects) = @_;
    my $ret = [];

    foreach my $obj (@$objects) {
        if ( my $json = eval { $self->[ OBJ ]->objToJson( $obj, $self->[ PARAMS ] ) } ) {
            push( @$ret, $json );
        } else {
            warn "Couldn't convert object to json\n";
        }
    }
    
    return $ret;
}

1;

__END__

=head1 NAME

POE::Filter::JSON - A POE filter using JSON

=head1 SYNOPSIS

    use POE::Filter::JSON;

    my $filter = POE::Filter::JSON->new(
        json_any => {
            allow_nonref => 1,  # see the new() method docs
        },
        delimiter => 0,
    );
    my $obj = { foo => 1, bar => 2 };
    my $json_array = $filter->put( [ $obj ] );
    my $obj_array = $filter->get( $json_array );

    use POE qw( Filter::Stackable Filter::Line Filter::JSON );

    my $filter = POE::Filter::Stackable->new();
    $filter->push(
        POE::Filter::JSON->new( delimiter => 0 ),
        POE::Filter::Line->new(),
    );

=head1 DESCRIPTION

POE::Filter::JSON provides a POE filter for performing object conversion using L<JSON>. It is
suitable for use with L<POE::Filter::Stackable>.  Preferably with L<POE::Filter::Line>.

=head1 METHODS

=over

=item *

new

Creates a new POE::Filter::JSON object. It takes arguments that are passed to objToJson() (as the 2nd argument). See L<JSON> for details.
This module uses L<JSON::Any> internally.  To pass params to L<JSON::Any>'s new call, use json_any => { }

=item *

get

Takes an arrayref which is contains json lines. Returns an arrayref of objects.

=item *

put

Takes an arrayref containing objects, returns an arrayref of json linee.

=back

=head1 AUTHOR

David Davis <xantus@cpan.org>

=head1 LICENSE

Artistic

=head1 SEE ALSO

L<POE>, L<JSON::Any>, L<POE::Filter::Stackable>, L<POE::Filter::Line>

=cut

