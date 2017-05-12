package Poet::Plack::Request;
$Poet::Plack::Request::VERSION = '0.16';
use Poet::Moose;
extends 'Plack::Request';

1;

__END__

=pod

=head1 NAME

Poet::Plack::Request - Poet's subclass of Plack::Request

=head1 DESCRIPTION

This is a Poet-specific subclass of L<Plack::Request|Plack::Request>, reserved
for future additions and overrides.

=head1 SEE ALSO

L<Poet|Poet>

=head1 AUTHOR

Jonathan Swartz <swartz@pobox.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Jonathan Swartz.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
