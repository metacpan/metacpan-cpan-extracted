package OpenAI::API::Request::File::List;

use strict;
use warnings;

use Moo;
use strictures 2;
use namespace::clean;

extends 'OpenAI::API::Request';

use Types::Standard qw();

sub endpoint { 'files' }
sub method   { 'GET' }

1;

__END__

=head1 NAME

OpenAI::API::Request::File::List - files endpoint

=head1 SYNOPSIS

    use OpenAI::API::Request::File::List;

    my $request = OpenAI::API::Request::File::List->new();

    my $res = $request->send();

=head1 DESCRIPTION

Returns a list of files that belong to the user's organization.

=head1 METHODS

=head2 new()

=head1 SEE ALSO

OpenAI API Documentation: L<Files|https://platform.openai.com/docs/api-reference/files>
