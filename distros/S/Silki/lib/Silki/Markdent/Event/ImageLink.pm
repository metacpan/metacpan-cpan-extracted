package Silki::Markdent::Event::ImageLink;
{
  $Silki::Markdent::Event::ImageLink::VERSION = '0.29';
}

use strict;
use warnings;
use namespace::autoclean;

use Markdent::Types qw( Str );

use Moose;
use MooseX::StrictConstructor;

has link_text => (
    is       => 'ro',
    isa      => Str,
    required => 1,
);

with 'Markdent::Role::Event';

__PACKAGE__->meta()->make_immutable();

1;

# ABSTRACT: Represents a link to an image (to be embedded in the page)

__END__
=pod

=head1 NAME

Silki::Markdent::Event::ImageLink - Represents a link to an image (to be embedded in the page)

=head1 VERSION

version 0.29

=head1 AUTHOR

Dave Rolsky <autarch@urth.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2011 by Dave Rolsky.

This is free software, licensed under:

  The GNU Affero General Public License, Version 3, November 2007

=cut

