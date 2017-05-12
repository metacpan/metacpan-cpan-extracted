package MojoX::Encode::Gzip;

# ABSTRACT: Gzip a Mojo::Message::Response

use strict;
use warnings;

use base 'Mojo::Base';

our $VERSION = '1.11';

use Compress::Zlib ();

__PACKAGE__->attr( min_bytes => 500 );
__PACKAGE__->attr( max_bytes => 500000 );

sub maybe_gzip {
    my $self = shift;
    my $tx = shift;
    my $req = $tx->req;
    my $res = $tx->res;

    my $accept = $req->headers->header('Accept-Encoding') || '';
    my $body   = $res->body;
    my $length = $res->body_size || 0;

    # Don't both unless:
    # - we have a success code
    # - we have a content type that makes sense to gzip
    # - a client is asking for giving
    # - the content is not already encoded.
    # - The body is not too small or too large to gzip
    # XXX content-types should be configurable.
    unless ( ( index( $accept, 'gzip' ) >= 0 )
            and ( $length > $self->min_bytes )
            and ( $length < $self->max_bytes  )
            and ( $res->code == 200 )
            and ( not $res->headers->header('Content-Encoding'))
            and ( $res->headers->content_type =~ qr{^text|xml$|javascript$|^application/json$} )
    ) {
        return undef;
    }

    eval { local $/; $body = <$body> } if ref $body;
    die "Response body is an unsupported kind of reference" if ref $body;

    $res->body( Compress::Zlib::memGzip( $body ) );
    $res->headers->content_length( $length );
    $res->headers->header('Content-Encoding' => 'gzip');
    $res->headers->add( 'Vary' => 'Accept-Encoding' );

    return 1;
}

1;

=pod

=encoding UTF-8

=head1 NAME

MojoX::Encode::Gzip - Gzip a Mojo::Message::Response

=head1 VERSION

version 1.11

=head1 SYNOPSIS

    use MojoX:Encode::Gzip;

    # Simple
    MojoX::Encode::Gzip->new->maybe_gzip($tx);

    # With options
    my $gzip = MojoX::Encode::Gzip->new(
        min_bytes => 600,
        max_bytes => 600000,
    );
    $success = $gzip->maybe_gzip($tx);

=head1 DESCRIPTION

Gzip compress a Mojo::Message::Response if client supports it.

=head2 ATTRIBUTES

=head2 C<min_bytes>

The minumum number of bytes in the body before we would try to gzip it. Trying to gzip really
small messages can take extra CPU power on the server and client without saving any times. Defaults
to 500.

=head2 C<max_bytes>

The maximum number of bytes in the body before we give up on trying gzip it. Gzipping very large messages
can delay the response and possibly exhaust system resources. Defaults to 500000.

=head1 METHODS

=head2 C<maybe_gzip>

    my $success = $gzip->maybe_gzip($tx);

Given a L<Mojo::Transaction> object, possibly gzips transforms the response by
gzipping it. Returns true if we gzip it, and undef otherwise.  The behavior is
modified by the C<< min_bytes >> and C<< max_bytes >> attributes.

Currently we only only try to gzip Content-types that start with "text/", or end in "xml" or "javascript",
along with "application/json". This may be configurable in the future.

=head1 AUTHOR

Mark Stosberg, C<< <mark at summersault.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-mojox-encode-gzip at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=MojoX-Encode-Gzip>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc MojoX::Encode::Gzip

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=MojoX-Encode-Gzip>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/MojoX-Encode-Gzip>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/MojoX-Encode-Gzip>

=item * Search CPAN

L<http://search.cpan.org/dist/MojoX-Encode-Gzip>

=back

=head1 ACKNOWLEDGEMENTS

 Inspired by Catalyst::Plugin::Compress::Gzip

=head1 COPYRIGHT & LICENSE

Copyright 2008 Mark Stosberg, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 AUTHOR

Renee Baecker <reneeb@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Renee Baecker.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__END__


1; # End of MojoX::Encode::Gzip
