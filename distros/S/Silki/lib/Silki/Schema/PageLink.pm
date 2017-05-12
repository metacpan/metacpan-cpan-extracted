package Silki::Schema::PageLink;
{
  $Silki::Schema::PageLink::VERSION = '0.29';
}

use strict;
use warnings;
use namespace::autoclean;

use Silki::Schema;

use Fey::ORM::Table;

has_policy 'Silki::Schema::Policy';

has_table( Silki::Schema->Schema()->table('PageLink') );

__PACKAGE__->meta()->make_immutable();

1;

# ABSTRACT: Represents a link from one page to another

__END__
=pod

=head1 NAME

Silki::Schema::PageLink - Represents a link from one page to another

=head1 VERSION

version 0.29

=head1 AUTHOR

Dave Rolsky <autarch@urth.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2011 by Dave Rolsky.

This is free software, licensed under:

  The GNU Affero General Public License, Version 3, November 2007

=cut

