package RDF::Server::Protocol::HTTP;

use Moose::Role;

with 'RDF::Server::Protocol';
with 'MooseX::Daemonize';

use POE::Component::Server::HTTP ();
use HTTP::Status qw(RC_OK RC_NOT_FOUND RC_METHOD_NOT_ALLOWED RC_INTERNAL_SERVER_ERROR);
use Log::Log4perl;
use HTTP::Request;
use HTTP::Response;

use RDF::Server::Exception;

use RDF::Server::Types qw(Exception);


has port => (
    is => 'ro',
    isa => 'Str',
    default => '8080',
);

has address => (
    is => 'ro',
    isa => 'Str',
    default => '127.0.0.1',
);

has uri_base => (
    is => 'ro',
    isa => 'Str',
    lazy => 1,
    default => sub { '/' }
);


has aliases => (
    is => 'ro',
    isa => 'HashRef',
    lazy => 1,
    noGetOpt => 1,
    default => sub {
        my $self = shift;
        POE::Component::Server::HTTP -> new(
           Port => $self -> port,
           Address => $self -> address,
           ContentHandler => {
               $self -> uri_base => sub { $self -> handle(@_) },
           },
           Headers => { Server => "RDF Server $RDF::Server::VERSION" },
        );
    }
);

after 'start' => sub {
    my $self = shift;

    return unless $self -> foreground || $self -> is_daemon;

    if(defined $self->aliases->{httpd}) {
        POE::Kernel -> run();
    }
};


no Moose::Role;

sub handle {
    my($self, $request, $response) = @_;

    eval {
        $self -> handle_request($request, $response);
    };

    my $e = $@;
    if($e) {
        if(is_Exception($e)) {
            $response -> code( $e -> status );
            $response -> content( $e -> content );
            $response -> headers -> push_header( $_ => $e -> headers -> {$_} )
                foreach keys %{$e -> headers};
        }
        else { 
          $self -> logger -> error( $e ); 
          $response -> code( 500 );
          $response -> content( 'Uh oh! ' . $e );
        }
    }

    # log the request and resulting return code
    my $logger = Log::Log4perl -> get_logger($self -> meta -> name);
#10.211.55.2 dev.local:81 - [08/Mar/2008:01:50:29 -0600] "GET /RDF-Server/cover_db/blib-lib-RDF-Server-Role-Mutable-pm.html HTTP/1.1" 200 3624 "http://dev.local:81/RDF-Server/cover_db/coverage.html" "Mozilla/5.0 (Macintosh; U; Intel Mac OS X; en-us) AppleWebKit/523.15.1 (KHTML, like Gecko) Version/3.0.4 Safari/523.15"

    $self -> log_request($request, $response);

    return $response -> code;
}

1;

__END__

=pod

=head1 NAME

RDF::Server::Protocol::HTTP - POE-based standalone HTTP server

=head1 SYNOPSIS

 package My::Server;

 use RDF::Server;
 with 'MooseX::SimpleConfig';
 with 'MooseX::Getopt';

 protocol 'HTTP';
 interface 'SomeInterface';
 semantic 'SomeSemantic';

=head1 DESCRIPTION

This protocol handler interfaces between the RDF::Server framework and
a POE::Component::Server::HTTP server.  

The MooseX::Daemonize role is included in this module.  The C<start>
method is extended to start the POE::Kernal event loop in the daemonized 
process.

=head1 CONFIGURATION

=over 4

=item address

This is the IP address on which the server should listen.

Default: 127.0.0.1 (localhost)

=item port

This is the port on which the server should listen.

Default: 8080

=item uri_base

This is the base URI at which the server should respond to requests.  This
is the location at which the content handler responds in the
POE::Component::Server::HTTP object.  See L<POE::Component::Server::HTTP>
for more information.

=back

=head1 METHODS

=over 4

=item handle ($request, $response)

Passes the request and response objects to the appropriate interface handler.
Returns the appropriate code to the POE::Component::Server::HTTP server.

=back

=head1 SEE ALSO

L<MooseX::Daemonize>,
L<POE::Component::Server::HTTP>.

=head1 AUTHOR 
            
James Smith, C<< <jsmith@cpan.org> >>
      
=head1 LICENSE
    
Copyright (c) 2008  Texas A&M University.
    
This library is free software.  You can redistribute it and/or modify
it under the same terms as Perl itself.
            
=cut

