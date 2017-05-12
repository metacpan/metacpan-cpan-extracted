package Mock::LWP::Request;

use strict;
use warnings;

our $VERSION = '0.01';

use Moo;
use HTTP::Status    qw( :constants );
use HTTP::Response;

has old_lwp_request => (
    is          => 'ro',
    init_arg    => undef,
    default     => sub {
        return \&LWP::UserAgent::request;
    },
);

has default_response => (
    is          => 'rw',
    isa         => sub {
        die "default_response must be a HTTP::Response object"
            unless (ref $_[0] && ref $_[0] eq 'HTTP::Response');
    },
    default     => sub {
        return HTTP::Response->new( HTTP_PRECONDITION_FAILED );
    },
);

has missing_response_action => (
    is          => 'rw',
    isa         => sub {
        die "missing_response_action must be either die or default"
            unless $_[0] eq 'die' || $_[0] eq 'default';
    },
    default     => sub {
        return 'die';
    },
);

has response_list => (
    is          => 'rw',
    isa         => sub {
        die "$_[0] is not an ARRAY ref"
            unless ( ref $_[0] && ref $_[0] eq 'ARRAY' );
    },
    default     => sub { return []; },
);

has enabled => (
    is          => 'rwp',
    init_arg    => undef,
    default     => sub { return 0; },
);

has debug => (
    is          => 'rw',
    default     => sub { return 0; },
);

sub enable {
    my $self = shift;

    return if $self->enabled;

    no warnings 'redefine';
    *LWP::UserAgent::request = sub {
        my $class = shift;

        warn "IN REDEFINED LWP::UserAgent::request" if $self->debug;
        
        my $response = shift @{ $self->response_list };
        return $response if defined $response;
        die "No response" if $self->missing_response_action eq 'die';
        return $self->default_response;
    };
    use warnings 'redefine';
    $self->_set_enabled(1);
}

sub disable {
    my $self = shift;

    return unless $self->enabled;

    no warnings 'redefine';
    *LWP::UserAgent::request = $self->old_lwp_request;
    use warnings 'redefine';
    $self->_set_enabled(0);
}

sub add_response {
    my ($self, $response) = @_;

    die "Response must be a HTTP::Response object"
        unless ref $response && ref $response eq 'HTTP::Response';

    push @{ $self->response_list }, $response;
}

sub DEMOLISH {
    my $self = shift;

    $self->disable();
}

1;
__END__
=head1 NAME

Mock::LWP::Request - Perl extension for mocking calls to LWP::UserAgent's
request method.

=head1 SYNOPSIS

  use Mock::LWP::Request;
  use LWP::UserAgent;

  my $mocked_lwp = Mock::LWP::Request->new();

  foreach my $response_object ( @list_of_http_response_objects ) {
    $mocked_lwp->add_response( $response_object );
  }

  ...

  my $ua = LWP::UserAgent->new();

  my $first_response = $ua->get('http://www.example.com/');

  # $first_response contains the result of attempting to make a real
  # connection to www.example.com

  $mocked_lwp->enable();

  my $second_response = $ua->get('http://www.example.com.ua/');

  # $second_response contains the first HTTP::Response object from
  # @list_of_http_response_objects above

  $mocked_lwp->disable();

=head1 DESCRIPTION

This class provides a simple way to mock the request method from
LWP::UserAgent by injecting HTTP Response objects which subsequent
calls to request() will return in the order they are injected.

=head1 METHODS

=head2 new

Instantiate an object of the class and set configuration options.

=over 1

=item default_response

Set or default HTTP::Response object to be returned if no responses are
available and missing_response_action is set to default.

=item missing_response_action

What action to take when a call is made to request and mocking is enabled
but there are no responses available. Must be either 'die' or 'default'.

If set to 'die' such a request call will die.
If set to 'default' the default response will be returned.

=item response_list

An array reference containing a list of HTTP::Response objects which
will be returned in order for each request().

=item debug

If true a warning will be issued for each call to LWP::UserAgent->request
when mocking is enabled.

=back

=head2 add_response

Adds a HTTP Response object to the list of responses.

=head2 default_response

Set a default HTTP Response for calls to LWP::UserAgent->request() to
return when mocking is enabled if missing_response_action is not set to
'die'.

The response must be a valid HTTP Response object. If none is provided
a default response with status code 412 (Precondition Failed) and no
body is the default.

=head2 enable

Enables mocking of LWP::Request->request() calls.

=head2 disable

Disables mocking of LWP::Request->request() calls.

=head2 debug

Pass a true value to enable debug or 0 to disable.

=head1 SEE ALSO

LWP::UserAgent 

=head1 AUTHOR

Jason Clifford, E<lt>jason@ukfsn.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2013 by Jason Clifford

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10 or,
at your option, any later version of Perl 5 you may have available.


=cut
