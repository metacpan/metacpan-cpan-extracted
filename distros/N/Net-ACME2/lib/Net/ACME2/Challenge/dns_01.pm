package Net::ACME2::Challenge::dns_01;

use strict;
use warnings;

use parent qw( Net::ACME2::ChallengeBase::HasToken );

#not very useful, but.
use constant TXT_PREFIX => '_acme-challenge';

=encoding utf-8

=head1 NAME

Net::ACME2::Challenge::dns_01

=head1 DESCRIPTION

This module is instantiated by L<Net::ACME2::Authorization> and is a
subclass of L<Net::ACME2::Challenge>.

There’s not much of interest here, really; it’s just a placeholder
for the C<token> attribute.

=cut

1;
