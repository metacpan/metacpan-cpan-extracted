package Net::HTTP::Spore::Middleware::Format::Text;
$Net::HTTP::Spore::Middleware::Format::Text::VERSION = '0.01';
# ABSTRACT: middleware for Text format
use Moose;
extends 'Net::HTTP::Spore::Middleware::Format';

sub encode       { $_[1] }
sub decode       { $_[1] }
sub accept_type  { ( 'Accept' => 'text/plain' ) }
sub content_type { ( 'Content-Type' => 'text/plain' ) }

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::HTTP::Spore::Middleware::Format::Text - middleware for Text format

=head1 VERSION

version 0.01

=head1 SYNOPSIS

    my $client = Net::HTTP::Spore->new_from_spec('twitter.json');
    $client->enable('Format::Text');

=head1 DESCRIPTION

Net::HTTP::Spore::Middleware::Format::Text is a middleware to handle
requests in C<text/plain> format. It will set the appropriate
B<Accept> header in your request. If the request method is PUT or
POST, the B<Content-Type> header will also be set to C<text/plain>.

It is intended for use with L<Net::HTTP::Spore>; see their
documentation for more information. This particular module may be
deleted if it eventually gets merged into the main Net:HTTP::Spore
module.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
https://github.com/gempesaw/Net-HTTP-Spore-Middleware-Format-Text/issues

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

Daniel Gempesaw <gempesaw@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Daniel Gempesaw.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
