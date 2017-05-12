package SNA::Network::Node::Plugin::Test;

use warnings;
use strict;

require Exporter;
use base qw(Exporter);
our @EXPORT = qw(node_plugin_test);


=head1 NAME

SNA::Network::Node::Plugin::Test - Test plugin for SNA::Network::Node


=head1 METHODS

=head2 node_plugin_test

returns 1

=cut

sub node_plugin_test {
	return 1;
}


=head1 AUTHOR

Darko Obradovic, C<< <dobradovic at gmx.de> >>


=head1 COPYRIGHT & LICENSE

Copyright 2009 Darko Obradovic, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;

