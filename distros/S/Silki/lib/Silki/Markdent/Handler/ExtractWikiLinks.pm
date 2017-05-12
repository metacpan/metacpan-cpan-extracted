package Silki::Markdent::Handler::ExtractWikiLinks;
{
  $Silki::Markdent::Handler::ExtractWikiLinks::VERSION = '0.29';
}

use strict;
use warnings;
use namespace::autoclean;

use List::AllUtils qw( any );
use Silki::Types qw( HashRef );

use Moose;
use MooseX::SemiAffordanceAccessor;
use MooseX::StrictConstructor;

with 'Markdent::Role::Handler', 'Silki::Markdent::Role::WikiLinkResolver';

has links => (
    traits   => ['Hash'],
    is       => 'ro',
    isa      => HashRef [HashRef],
    init_arg => undef,
    default  => sub { {} },
    handles  => {
        _add_link => 'set',
    },
);

# The WikiLinkResolver role does everything we need done for event handling.
sub handle_event { }

sub _replace_placeholder {
    my $self      = shift;
    my $id        = shift;
    my $link_data = shift;

    return unless $link_data && $link_data->{wiki};

    $self->_add_link( $id => $link_data );

    return;
}

__PACKAGE__->meta()->make_immutable();

1;

# ABSTRACT: Extracts all links from a Silki Markdown document

__END__
=pod

=head1 NAME

Silki::Markdent::Handler::ExtractWikiLinks - Extracts all links from a Silki Markdown document

=head1 VERSION

version 0.29

=head1 AUTHOR

Dave Rolsky <autarch@urth.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2011 by Dave Rolsky.

This is free software, licensed under:

  The GNU Affero General Public License, Version 3, November 2007

=cut

