use 5.10.0;
use strict;
use warnings;

package OpenGbg::Exceptions;

our $AUTHORITY = 'cpan:CSSON'; # AUTHORITY
our $VERSION = '0.1404';

use Throwable::SugarFactory;

exception BadResponseFromService
       => 'Failed to get response from service'
       => has => [service => (is => 'ro')]
       => has => [url => (is => 'ro')]
       => has => [status => (is => 'ro')]
       => has => [reason => (is => 'ro')]
       ;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

OpenGbg::Exceptions

=head1 VERSION

Version 0.1404, released 2018-05-19.

=head1 SOURCE

L<https://github.com/Csson/p5-OpenGbg>

=head1 HOMEPAGE

L<https://metacpan.org/release/OpenGbg>

=head1 AUTHOR

Erik Carlsson <info@code301.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Erik Carlsson.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
