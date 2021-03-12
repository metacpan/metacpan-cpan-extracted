package
    Pinto::Remote::SelfContained::Httptiny::Handle;

use v5.10;
use strict;
use warnings;

use Class::Method::Modifiers qw(around);

use namespace::clean;

our $VERSION = '1.000';

use HTTP::Tiny ();
use parent -norequire, 'HTTP::Tiny::Handle';

# "around" to ensure the method already exists
around write_request_header => sub {
    my (undef, $self, $method, $request_uri, $headers, $header_case) = @_;
    return $self->write_header_lines($headers, $header_case, "$method $request_uri HTTP/1.0\x0D\x0A");
};

1;
__END__

=head1 NAME

Pinto::Remote::SelfContained::Httptiny::Handle - HTTP/1.0 handle subclass for HTTP::Tiny

=head1 AUTHOR

Aaron Crane, E<lt>arc@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright 2020 Aaron Crane.

=head1 LICENSE

This library is free software and may be distributed under the same terms
as perl itself. See L<http://dev.perl.org/licenses/>.

=cut
