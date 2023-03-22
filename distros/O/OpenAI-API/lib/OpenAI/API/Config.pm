package OpenAI::API::Config;

use Types::Standard qw(Int Num Str);

use Moo;
use strictures 2;
use namespace::clean;

my $DEFAULT_API_BASE = 'https://api.openai.com/v1';

has api_key  => ( is => 'rw', isa => Str, default => sub { $ENV{OPENAI_API_KEY} }, required => 1 );
has api_base => ( is => 'rw', isa => Str, default => sub { $ENV{OPENAI_API_BASE} // $DEFAULT_API_BASE }, );

has timeout => ( is => 'rw', isa => Num, default => sub { 60 } );
has retry   => ( is => 'rw', isa => Int, default => sub { 3 } );
has sleep   => ( is => 'rw', isa => Num, default => sub { 1 } );

1;

__END__

=head1 NAME

OpenAI::API::Config - Configuration options for OpenAI::API

=head1 SYNOPSIS

    use OpenAI::API::Config;

    my $config = OpenAI::API::Config->new(
        api_base => 'https://api.openai.com/v1',
        timeout  => 60,
        retry    => 3,
        sleep    => 1,
    );

    # Later...

    {
        use OpenAI::API;
        my $openai = OpenAI::API->new( config => $config );
        my $res    = $openai->models();
    }

    # or...
    {
        use OpenAI::API::Request::Model::List;
        my $request = OpenAI::API::Request::Model::List->new( config => $config );
        my $res     = $request->send();
    }

=head1 DESCRIPTION

This module defines a configuration object for the OpenAI API client. It
provides default values for various options, such as the API base URL,
the API key, and the timeout period for API requests.

=head1 ATTRIBUTES

=over 4

=item * api_key

The API key to use when making requests to the OpenAI API. This is a
required attribute, and if not provided, it will default to the value
of the C<OPENAI_API_KEY> environment variable.

=item * api_base

The base URL for the OpenAI API. This defaults to
'https://api.openai.com/v1', but can be overridden by setting the
C<OPENAI_API_BASE> environment variable.

=item * timeout

The timeout period (in seconds) for API requests. This defaults to
60 seconds.

=item * retry

The number of times to retry a failed API request. This defaults to
3 retries.

=item * sleep

The number of seconds to wait between retry attempts. This defaults to
1 second.

=back

=head1 METHODS

=over 4

=item * new(%args)

Constructs a new OpenAI::API::Config object with the provided options. The
available options are the same as the attributes listed above.

=back

=head1 SEE ALSO

=over

=item * L<OpenAI::API>

=item * L<OpenAI::API::Request> modules

=back
