package OpenAI::API::Request::Model::List;

use strict;
use warnings;

use Moo;
use strictures 2;
use namespace::clean;

extends 'OpenAI::API::Request';

use Types::Standard qw();

sub endpoint { 'models' }
sub method   { 'GET' }

1;

__END__

=head1 NAME

OpenAI::API::Request::Model::List - models endpoint

=head1 SYNOPSIS

    use OpenAI::API::Request::Model::List;

    my $request = OpenAI::API::Request::Model::List->new();

    my $res = $request->send();

=head1 DESCRIPTION

Lists the currently available models, and provides basic information
about each one such as the owner and availability.

=head1 METHODS

=head2 new()

=head1 SEE ALSO

OpenAI API Documentation: L<Models|https://platform.openai.com/docs/api-reference/models>
