package Template::Iterator::XS;

use strict;
use warnings;

require DynaLoader;
require Template::Iterator;
require Template::Constants;

our $VERSION = 0.01;
our @ISA = qw( Template::Iterator DynaLoader );

bootstrap Template::Iterator::XS $VERSION;

_init( Template::Constants::STATUS_DONE() );

1;

=pod

=head1 NAME

Template::Iterator::XS - speedup TT2's Iterator

=head1 DESCRIPTION

The module is intended to function as a drop-in replacement for TT's native
Template::Iterator, for speedup. There is an existing mechanism for a similar
module, Template::Stash::XS which does the same, and can be selected during
configuration. The hope for this module is to function exacly in the same fashion.

=head1 USAGE

use Template;
use Template::Iterator::XS;
$Template::Config::ITERATOR = 'Template::Iterator::XS';

=head1 AUTHOR

Dmitry Karasik <dmitry@karasik.eu.org>

=head1 LICENCE

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

The work is sponsored by reg.ru .

=cut
