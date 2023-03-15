package OpenAI::API::ConfigurationRole;

use Types::Standard qw(Str);

use Moo::Role;
use strictures 2;
use namespace::clean;

my $DEFAULT_API_BASE = 'https://api.openai.com/v1';

has api_key  => ( is => 'rw', isa => Str, default => sub { $ENV{OPENAI_API_KEY} }, required => 1 );
has api_base => ( is => 'rw', isa => Str, default => sub { $ENV{OPENAI_API_BASE} // $DEFAULT_API_BASE }, );

1;
