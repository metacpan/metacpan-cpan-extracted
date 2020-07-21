package SignalR::Hub;

use strict;
use warnings;

our $VERSION = '0.001';

1;

__END__

=pod

=encoding utf-8

=head1 NAME

SignalR::Hub - Perl Implementation of the SignalR 2-way RPC Hub Protocol

=head1 VERSION

0.001

=head1 DESCRIPTION

The SignalR Protocol is a protocol for two-way RPC over any Message-based transport. 
Either party in the connection may invoke procedures on the other party, 
and procedures can return zero or more results or an error.

=head1 AUTHOR

James Wright <jwright@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by James Wright.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.


