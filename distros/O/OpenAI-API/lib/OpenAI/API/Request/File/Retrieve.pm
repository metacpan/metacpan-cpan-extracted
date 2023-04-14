package OpenAI::API::Request::File::Retrieve;

use strict;
use warnings;

use Types::Standard qw(Str);

use Moo;
use strictures 2;
use namespace::clean;

extends 'OpenAI::API::Request';

has file_id => ( is => 'ro', isa => Str, required => 1 );

sub endpoint {
    my ($self) = @_;
    return 'files/' . $self->{file_id};
}

sub method { 'GET' }

1;

__END__

=head1 NAME

OpenAI::API::Request::File::Retrieve - retrieve file details

=head1 SYNOPSIS

    use OpenAI::API::Request::File::Retrieve;

    # retrieve an existing file id
    my $file_id = OpenAI::API::Request::File::List->new->send->{data}[0]->{id};

    if ($file_id) {
        my $request = OpenAI::API::Request::File::Retrieve->new(
            file_id => $file_id,
        );

        my $res = $request->send();

        my $filename = $res->{filename};
    }

=head1 DESCRIPTION

Returns information about a specific file.

=head1 METHODS

=head2 new()

=over

=item file_id

=back

=head2 send()

Sends the request and returns a data structured similar to the one
documented in the API reference.

=head1 SEE ALSO

OpenAI API Reference: L<Files|https://platform.openai.com/docs/api-reference/files>
