package RDF::Server::Protocol::FCGI;

use Moose::Role;
with 'RDF::Server::Protocol';
with 'MooseX::Daemonize';

use FCGI;
#use Log::Log4perl;

use RDF::Server::Types qw( Exception );

has 'socket' => (
    is => 'ro',
    isa => 'Str',
    required => 1
);

after 'start' => sub {
    my $self = shift;

    return unless $self -> foreground || $self -> is_daemon;

    my $env = { };

    my $request = FCGI::Request(
      \*STDIN,
      \*STDOUT,
      \*STDERR,
      $env,
      FCGI::OpenSocket($self -> socket, 100)
    );

    while($request->Accept() >= 0) {
        if ( $env->{SERVER_SOFTWARE} && $env->{SERVER_SOFTWARE} =~ /lighttpd/ ) {
            $env->{PATH_INFO} ||= delete $env->{SCRIPT_NAME};
        }
        my $req = HTTP::Request -> new(
            $env -> {REQUEST_METHOD},
            $env -> {PATH_INFO}
        );
        $req -> header('Content-Type' => $env -> {CONTENT_TYPE});
        my $length = 0+($env -> {CONTENT_LENGTH} || 0);
        $req -> header('Content-Length' => $length);
        if($length) {
            my $c;
            read(STDIN, $c, $length);
            $req -> content($c);
        }
        my $resp = HTTP::Response -> new;
        $resp -> request($req);
        eval {
            $self -> handle_request($req, $resp);
        };

        my $e = $@;
        if($e) {
            if(is_Exception($e)) {
                $resp -> code( $e -> status );
                $resp -> content( $e -> content );
                $resp -> headers -> push_header( $_ => $e -> headers -> {$_} )
                    foreach keys %{$e -> headers};
            }
            else { 
              $self -> logger -> error( $e );
              $resp -> code( 500 );
              $resp -> content( 'Uh oh! ' . $e );
            }
        }
#        print STDERR 'Status: ' . $resp -> as_string;
        $self -> log_request($req, $resp);

        print 'Status: ' . $resp -> as_string;
    }
};

1;

__END__

=pod

=head1 NAME

RDF::Server::Protocol::FCGI - FastCGI protocol handler for RDF::Server

=head1 SYNOPSIS

 package My::Server;

 use RDF::Server;
 with 'MooseX::SimpleConfig';
 with 'MooseX::Getopt';

 protocol 'FCGI';
 interface 'SomeInterface';
 semantic 'SomeSemantic';

=head1 DESCRIPTION

This protocol handler interfaces between the RDF::Server framework and the
FCGI server library.

The MooseX::Daemonize role is included in this module.  The C<start> method is
extended to run the FastCGI request loop in the daemonized process.

=head1 CONFIGURATION

=over 4

=item socket

This is the UNIX socket on which the server listens.

=back

=head1 METHODS

=over 4

=item start

=back

=head1 SEE ALSO

L<FCGI>,
L<MooseX::Daemonize>.

=head1 AUTHOR

James Smith, C<< <jsmith@cpan.org> >>

=head1 LICENSE
  
Copyright (c) 2008  Texas A&M University.

This library is free software.  You can redistribute it and/or modify
it under the same terms as Perl itself.
    
=cut

