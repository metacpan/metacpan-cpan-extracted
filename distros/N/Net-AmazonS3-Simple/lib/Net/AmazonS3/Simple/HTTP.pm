package Net::AmazonS3::Simple::HTTP;
use strict;
use warnings;

use HTTP::Request;

use Class::Tiny qw(http_client signer auto_region region secure host);

=head1 NAME

Net::AmazonS3::Simple::HTTP - request formater and caller

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 METHODS

=head2 new(%attributes)

=head3 %attributes

=head4 http_client

=head4 signer

=head4 auto_region

=head4 region

=head4 secure

=head4 host

=cut

sub BUILD {
    my ($self) = @_;

    foreach my $req ( qw/http_client signer auto_region region secure host/ ) {
        die "$req attribute required" if! defined $self->$req;
    }
}

=head2 request(%options)

=cut
sub request {
    my ($self, %options) = @_;

    $options{method} = 'GET' if !defined $options{method};

    foreach my $req (qw/bucket path/) {
        die "$req parameter required" if !defined $options{$req};
    }

    my $request = HTTP::Request->new(
        $options{method},
        $self->_uri(%options),
        ['x-amz-content-sha256' => 'UNSIGNED-PAYLOAD']
    );

    $self->signer->sign($request, $self->region, 'UNSIGNED-PAYLOAD');

    print $request->as_string() . "\n" if $ENV{AWS_S3_DEBUG};

    my $response = $self->http_client->request($request, $options{ content_to_file });

    print $response->as_string() . "\n" if $ENV{AWS_S3_DEBUG};

    if ($self->auto_region && $response->code == 400) {
        #I know - XML don't be parsed with regex, but for this simple case I do it
        #maybe with next versions I use XML::LibXML;)
        if ($response->content() =~ m{<Region>([-\w]+)</Region>}) {
            my $region = $1;

            print "# set region to: $region\n" if $ENV{AWS_S3_DEBUG};
            $self->region($region);

            $response = request(@_);
        }
    }

    if ($response->is_success()) {
        return $response;
    }

    die sprintf
        "Unknown response %s:\n:%s",
        $response->message,
        $response->content;
}

sub _uri {
    my ($self, %options) = @_;

    return sprintf
      '%s://%s.%s/%s',
      $self->secure ? 'https' : 'http',
      $options{bucket},
      $self->host,
      $options{path};
}

=head1 LICENSE

Copyright (C) Avast Software.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Jan Seidl E<lt>seidl@avast.comE<gt>

=cut

1;

