#-*-perl-*-
#
# Copyright (c) 1997 Kevin Johnson <kjj@pobox.com>.
# Copyright (c) 2001 Rob Brown <rob@roobik.com>.
#
# All rights reserved. This program is free software; you can
# redistribute it and/or modify it under the same terms as Perl
# itself.
#
# $Id: Bind.pm,v 1.4 2002/04/18 02:22:47 rob Exp $

require 5.003;

use strict;

package Net::Bind;

use Carp;

use vars qw($VERSION);


$VERSION = '0.05';

=head1 NAME

Net::Bind - load various Net::Bind modules

=head1 SYNOPSIS

  use Net::Bind;

=head1 DESCRIPTION

C<Net::Bind> provides a simple mechanism to load all of the
C<Net::Bind> modules in one fell swoop.

Currently, this includes the following modules:

  Net::Bind::Resolv

Futures releases will include:

  Net::Bind::Boot
  Net::Bind::Zone
  Net::Bind::Dump
  Net::Bind::Conf

=cut

use Net::Bind::Resolv;

=head1 AUTHORS

Kevin Johnson <kjj@pobox.com>
Rob Brown <rob@roobik.com>

=head1 COPYRIGHT

Copyright (c) 1997 Kevin Johnson <kjj@pobox.com>.
Copyright (c) 2001 Rob Brown <rob@roobik.com>.

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=cut

1;
