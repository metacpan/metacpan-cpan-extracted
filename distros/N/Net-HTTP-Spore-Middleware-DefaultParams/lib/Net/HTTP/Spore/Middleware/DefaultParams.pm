package Net::HTTP::Spore::Middleware::DefaultParams;
{
  $Net::HTTP::Spore::Middleware::DefaultParams::VERSION = '0.04';
}

# ABSTRACT: Middleware to set default params for every request made by a spore client
use Moose;
extends 'Net::HTTP::Spore::Middleware';


# remove the 'required parameters' checking, so that explicit required
# parameters are set through the middleware
# added also a 'SPORE_META' env variable, so that if you have a custom
# spore namespace, this is still applicable
BEGIN {
    my $meta = "Net::HTTP::Spore::Meta::Method";
    if ( defined( $ENV{SPORE_META} ) ) {
        $meta = $ENV{SPORE_META};
    }
    $meta->meta->remove_method('has_required_params');
    $meta->meta->add_method( 'has_required_params' => sub { return 0 } );
}


has default_params => (
    is       => 'rw',
    isa      => 'HashRef',
    required => 1
);

# when receiving the client, remove 'has_required_params' on it

sub call {
    my ( $self, $req ) = @_;
    $req->env->{'spore.params'} = [
        %{  +{  %{ $self->default_params },
                @{ $req->env->{'spore.params'} || [] }
            }
        }
    ];
}
1;




__END__
=pod

=head1 NAME

Net::HTTP::Spore::Middleware::DefaultParams - Middleware to set default params for every request made by a spore client

=head1 VERSION

version 0.04

=head1 SYNOPSIS

    my $client = Net::HTTP::Spore->new_from_spec('api.json'); 
    # foo=bar and blah=baz will be passed on each request. 
    $client->enable('DefaultParams', default_params => { foo => 'bar', blah => 'baz' }); 

=head1 NAME

Net::HTTP::Spore::Middleware::DefaultParams - Set default parameters for outgoing requests

=head1 WARNINGS 

    This middleware disables the checking of required parameters, so be sure of what you are doing !

=head1 AUTHOR

Emmanuel "BHS_error" Peroumalnaik <peroumalnaik.emmanuel@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Weborama R&D.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

