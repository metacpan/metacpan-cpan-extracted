package Net::HTTP::Spore::Middleware::Format::Text;
$Net::HTTP::Spore::Middleware::Format::Text::VERSION = '0.09';
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

version 0.09

=head1 SYNOPSIS

    my $client = Net::HTTP::Spore->new_from_spec('twitter.json');
    $client->enable('Format::Text');

=head1 DESCRIPTION

Net::HTTP::Spore::Middleware::Format::Text is a simple middleware to
handle requests in C<text/plain> format. It will set the appropriate
B<Accept> header in your request. If the request method is PUT or
POST, the B<Content-Type> header will also be set to C<text/plain>.

=head1 AUTHORS

=over 4

=item *

Franck Cuny <franck.cuny@gmail.com>

=item *

Ash Berlin <ash@cpan.org>

=item *

Ahmad Fatoum <athreef@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Linkfluence.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
