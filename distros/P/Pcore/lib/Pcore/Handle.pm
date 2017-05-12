package Pcore::Handle;

use Pcore -role;

has uri => ( is => 'ro', isa => InstanceOf ['Pcore::Util::URI'], required => 1 );

sub new ( $self, $uri, %args ) {
    $uri = P->uri($uri) if !ref $uri;

    my $class = P->class->load( $uri->scheme, ns => 'Pcore::Handle' );

    return $class->new( { uri => $uri, %args } );
}

1;
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::Handle

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head1 METHODS

=head1 SEE ALSO

=cut
