package Net::Libwebsockets::X::General;

use strict;
use warnings;

=encoding utf-8

=head1 NAME

Net::Libwebsockets::X::General

=head1 DESCRIPTION

This class represents a general failure at some level,
probably some bizarre, unforeseen failure like failure
to create a LWS context.

=cut

#----------------------------------------------------------------------

use parent 'Net::Libwebsockets::X::Base';

#----------------------------------------------------------------------

1;
