#
# This file is part of Net-Gandi
#
# This software is copyright (c) 2012 by Natal Ngétal.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
package Net::Gandi::Transport::XMLRPC;
{
  $Net::Gandi::Transport::XMLRPC::VERSION = '1.122180';
}

# ABSTRACT: A Perl interface for gandi api

use Moose::Role;

with 'Net::Gandi::Role::XMLRPC';

1;

__END__
=pod

=head1 NAME

Net::Gandi::Transport::XMLRPC - A Perl interface for gandi api

=head1 VERSION

version 1.122180

=head1 AUTHOR

Natal Ngétal

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Natal Ngétal.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

