package POE::Component::Server::HTTPServer::Handler;
use strict;
use Carp;
use base 'Exporter';
our @EXPORT = qw( H_CONT H_FINAL );

use constant H_CONT => 0;
use constant H_FINAL => 1;

sub new {
  my $class = shift;
  my $self = bless {}, $class;
  $self->_init(@_);
  return $self;
}

sub _init { }

sub handle {
  croak "Cannot call handle on unextended package ", __PACKAGE__, "\n";
}

1;
__END__

=pod

=head1 NAME

POE::Component::Server::HTTPServer::Handler - request handler interface

=head1 SYNOPSIS

    package MyHandler;
    use base 'POE::Component::Server::HTTPServer::Handler';
    # import H_CONT and H_FINAL:
    use POE::Component::Server::HTTPServer::Handler;
    
    sub _init {
      my $self = shift;
      my @args = @_;
      # ...
    }
    
    sub handle {
      my $self = shift;
      my $context = shift;
    
      if ( $context->{use_myhandler} ) {
        $context->{response}->code(200);
        $context->{response}->content("Boo!");
        return H_FINAL;
      } else {
        return H_CONT;
      }
    }

    1;

=head1 DESCRIPTION

This package defines the standard interface for request handlers.  You
can subclass this package to define custom behavior.

=head1 METHODS

=over 4

=item B<$self-E<gt>handle( $context )>

HTTPServer invokes this method on the handler when it determines that
the handler should process the request.  C<$context> is the request
context, which is a hash reference containing data set by the server
and by previously executed handlers.  Of particular note are the
attributes C<$context-E<gt>{request}> and C<$context-E<gt>{response}>.
See L<POE::Component::Server::HTTPServer> for more details).

C<handle()> should return one of two values (defined in this package,
and exported by default): C<H_FINAL> indicates that processing of the
request should stop, or C<H_CONT> which indicates that the HTTPServer
should continue running handlers.

A request handler will typically either set the headers and content of
the response object (and return C<H_FINAL>), or set attributes in the
context for later handlers to use (and return C<H_CONT>).  A handler
may also need to tell the HTTPServer to restart the request
dispatching process.  The idiom for this is:

    return $context->{dispatcher}->dispatch( $context, "/new/path/to/dispatch/to" );

=item B<$self-E<gt>_init( @args )>

This method is called by the constructor with all the arguments passed
to C<new()>.  If you need to handle arguments passed to the
constructor, prefer overriding this method to overriding C<new()>.

=back

=head1 SEE ALSO

L<POE::Component::Server::HTTPServer>,
L<POE::Component::Server::HTTPServer::NotFoundHandler>,
L<POE::Component::Server::HTTPServer::BasicAuthenHandler>,
L<POE::Component::Server::HTTPServer::ParameterParseHandler>,
L<POE::Component::Server::HTTPServer::StaticHandler>

=head1 AUTHOR

Greg Fast <gdf@speakeasy.net>

=head1 COPYRIGHT

Copyright 2003 Greg Fast.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
