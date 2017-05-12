package Net::Async::Webservice::Common::Exception;
$Net::Async::Webservice::Common::Exception::VERSION = '1.0.2';
{
  $Net::Async::Webservice::Common::Exception::DIST = 'Net-Async-Webservice-Common';
}
use Moo;
with 'Throwable','StackTrace::Auto';
use overload
  q{""}    => 'as_string',
  fallback => 1;


around _build_stack_trace_args => sub {
    my ($orig,$self) = @_;

    my $ret = $self->$orig();
    push @$ret, (
        no_refs => 1,
        respect_overload => 1,
        message => '',
        indent => 1,
    );

    return $ret;
};


sub as_string { "something bad happened at ". $_[0]->stack_trace->as_string }

{
package Net::Async::Webservice::Common::Exception::ConfigError;
$Net::Async::Webservice::Common::Exception::ConfigError::VERSION = '1.0.2';
{
  $Net::Async::Webservice::Common::Exception::ConfigError::DIST = 'Net-Async-Webservice-Common';
}
 use Moo;
 extends 'Net::Async::Webservice::Common::Exception';


 has file => ( is => 'ro', required => 1 );


 sub as_string {
     my ($self) = @_;

     return 'Bad config file: %s, at %s',
         $self->file,
         $self->stack_trace->as_string;
 }
}


{
package Net::Async::Webservice::Common::Exception::HTTPError;
$Net::Async::Webservice::Common::Exception::HTTPError::VERSION = '1.0.2';
{
  $Net::Async::Webservice::Common::Exception::HTTPError::DIST = 'Net-Async-Webservice-Common';
}
 use Moo;
 extends 'Net::Async::Webservice::Common::Exception';
 use Try::Tiny;


 has request => ( is => 'ro', required => 1 );
 has response => ( is => 'ro', required => 1 );
 has more_info => ( is => 'ro', default => '' );


 sub as_string {
     my ($self) = @_;

     return sprintf 'Error %sing %s: %s %s, at %s',
         $self->request->method,$self->request->uri,
         (try {$self->response->status_line} catch {'no response'}),
         $self->more_info,
         $self->stack_trace->as_string;
 }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::Async::Webservice::Common::Exception

=head1 VERSION

version 1.0.2

=head1 DESCRIPTION

These classes are based on L<Throwable> and L<StackTrace::Auto>. The
L</as_string> method should return something readable, with a full
stack trace.

=head1 NAME

Net::Async::Webservice::Common::Exception - exception classes

=head1 Classes

=head2 C<Net::Async::Webservice::Common::Exception>

Base class.

=head3 Methods

=head4 C<as_string>

Generic "something bad happened", with stack trace.

=head2 C<Net::Async::Webservice::Common::Exception::ConfigError>

exception thrown when the configuration file can't be parsed

=head3 Attributes

=head4 C<file>

The name of the configuration file.

=head3 Methods

=head4 C<as_string>

Mentions the file name, and gives the stack trace.

=head2 C<Net::Async::Webservice::Common::Exception::HTTPError>

exception thrown when the HTTP request fails

=head3 Attributes

=head4 C<request>

The request that failed.

=head4 C<response>

The failure response returned by the user agent

=head4 C<more_info>

Additional error information, usually set when there is no response at
all (failures in name lookup or connection, for example).

=head3 Methods

=head4 C<as_string>

Mentions the HTTP method, URL, response status line, and stack trace.

=head1 AUTHOR

Gianni Ceccarelli <gianni.ceccarelli@net-a-porter.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Net-a-porter.com.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
