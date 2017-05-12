package Silki::Markdent::Dialect::Silki::BlockParser;
{
  $Silki::Markdent::Dialect::Silki::BlockParser::VERSION = '0.29';
}

use strict;
use warnings;
use namespace::autoclean;

use Moose;
use MooseX::SemiAffordanceAccessor;
use MooseX::StrictConstructor;

extends 'Markdent::Dialect::Theory::BlockParser';

__PACKAGE__->meta()->make_immutable();

1;

# ABSTRACT: Parses span-level markup for the Silki Markdown dialect (currently empty)

__END__
=pod

=head1 NAME

Silki::Markdent::Dialect::Silki::BlockParser - Parses span-level markup for the Silki Markdown dialect (currently empty)

=head1 VERSION

version 0.29

=head1 AUTHOR

Dave Rolsky <autarch@urth.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2011 by Dave Rolsky.

This is free software, licensed under:

  The GNU Affero General Public License, Version 3, November 2007

=cut

