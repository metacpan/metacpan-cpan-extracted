package OpenAI::API::Resource::Model;

use strict;
use warnings;

use Moo;
use strictures 2;
use namespace::clean;
use Types::Standard qw();

sub endpoint { 'models' }

1;

__END__

=head1 NAME

OpenAI::API::Resource::Model - models endpoint

=head1 DESCRIPTION

Lists the currently available models, and provides basic information
about each one such as the owner and availability.

=head1 METHODS

=head2 new()

=head1 SEE ALSO

OpenAI API Documentation: L<Models|https://platform.openai.com/docs/api-reference/models>
