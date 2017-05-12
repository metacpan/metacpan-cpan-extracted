package Net::Async::Webservice::UPS::Response::Image;
$Net::Async::Webservice::UPS::Response::Image::VERSION = '1.1.4';
{
  $Net::Async::Webservice::UPS::Response::Image::DIST = 'Net-Async-Webservice-UPS';
}
use Moo;
use Types::Standard qw(Str);
use Net::Async::Webservice::UPS::Types qw(:types);
use MIME::Base64;
use namespace::autoclean;

# ABSTRACT: an image in a UPS response


has format => (
    is => 'ro',
    isa => ImageType,
    required => 0,
);


has data => (
    is => 'ro',
    isa => Str,
    required => 0,
);


around BUILDARGS => sub {
    my ($orig,$class,@etc) = @_;
    my $args = $class->$orig(@etc);

    if (my $b64 = delete $args->{base64_data}) {
        $args->{data} = decode_base64($b64);
    }

    return $args;
};


sub BUILDARGS {
    my ($class,$hash) = @_;

    my ($format_key) = grep {/ImageFormat$/} keys %$hash;

    if ($format_key) {
        return {
            format => $hash->{$format_key}{Code},
            base64_data => $hash->{GraphicImage},
        };
    }
    else {
        return $hash;
    }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::Async::Webservice::UPS::Response::Image - an image in a UPS response

=head1 VERSION

version 1.1.4

=head1 ATTRIBUTES

=head2 C<format>

Enum of type L<Net::Async::Webservice::UPS::Types/ImageType>, one of
C<EPL>, C<ZPL>, C<SPL>, C<STARPL>, C<GIF>.

=head2 C<data>

String of bytes, containing the actual image data. You can pass the
argument C<base64_data> to the constructor instead of C<data>, to have
it decoded automatically.

=head1 METHODS

=head2 C<BUILDARGS>

  my $miage = Net::Async::Webservice::UPS::Response::Image
                ->new($piece_of_ups_response);

If you call the constructor with a hashref with at least a key
matching C</ImageFormat$/> and a key of C<GraphicImage>, this will
extract the image.

=for Pod::Coverage BUILDARGS

=head1 AUTHORS

=over 4

=item *

Gianni Ceccarelli <gianni.ceccarelli@net-a-porter.com>

=item *

Sherzod B. Ruzmetov <sherzodr@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Gianni Ceccarelli <gianni.ceccarelli@net-a-porter.com>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
