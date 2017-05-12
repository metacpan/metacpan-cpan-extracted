## no critic (RequireUseStrict)
package Plack::VCR;
$Plack::VCR::VERSION = '0.06';
## use critic (RequireUseStrict)
use strict;
use warnings;

use Carp qw(croak);
use HTTP::Request;
use Sereal qw(decode_sereal);
use IO::File;
use Plack::VCR::Interaction;
use UNIVERSAL;

use namespace::clean;

sub new {
    my ( $class, %opts ) = @_;

    my $filename = $opts{'filename'} or croak "filename parameter required";

    my $file = IO::File->new($filename, 'r') or croak $!;

    return bless {
        file => $file,
    }, $class;
}

sub next {
    my ( $self ) = @_;

    my $file = $self->{'file'};

    my $size = '';
    my $bytes = $file->read($size, 4);
    return if $bytes == 0;
    croak "Unexpected end of file" unless $bytes == 4;

    $size = unpack('N', $size);
    if($size > -s $file) {
        croak "Invalid file contents";
    }
    my $request = '';
    $bytes = $file->read($request, $size);
    croak "Unexpected end of file" unless $bytes == $size;
    $request = decode_sereal($request);

    croak "Invalid file contents"
        unless UNIVERSAL::isa($request, 'HTTP::Request');

    return Plack::VCR::Interaction->new(
        request => $request,
    );
}

1;

# ABSTRACT: API for interacting with a frozen request file

__END__

=pod

=encoding UTF-8

=head1 NAME

Plack::VCR - API for interacting with a frozen request file

=head1 VERSION

version 0.06

=head1 SYNOPSIS

  use Plack::VCR;

  my $vcr = Plack::VCR->new(filename => 'requests.out');

  while(my $interaction = $vcr->next) {
    my $req = $interaction->request;
    # $req is an HTTP::Request object; do something with it
  }

=head1 DESCRIPTION

Plack::VCR provides an API for iterating over the HTTP interactions
saved to a file by L<Plack::Middleware::Recorder>.

=head1 METHODS

=head2 new(filename => $filename)

Creates a new VCR that will iterate over the interactions contained
in C<$filename>.

=head2 next

Returns the next HTTP interaction in the stream.

=head1 SEE ALSO

L<Plack::Middleware::Recorder>, L<Plack::VCR::Interaction>

=head1 AUTHOR

Rob Hoelz <rob@hoelz.ro>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Rob Hoelz.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<https://github.com/hoelzro/plack-middleware-recorder/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
