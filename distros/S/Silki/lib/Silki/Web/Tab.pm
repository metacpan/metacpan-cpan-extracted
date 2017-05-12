package Silki::Web::Tab;
{
  $Silki::Web::Tab::VERSION = '0.29';
}

use strict;
use warnings;
use namespace::autoclean;

use Moose;
use MooseX::SemiAffordanceAccessor;
use MooseX::StrictConstructor;

has uri => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

has label => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

has tooltip => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

has id => (
    is      => 'ro',
    isa     => 'Str',
    lazy    => 1,
    default => sub { $_[0]->label() },
);

has is_selected => (
    is      => 'rw',
    isa     => 'Bool',
    default => 0,
);

__PACKAGE__->meta()->make_immutable();

1;

# ABSTRACT: A tab in the web UI

__END__
=pod

=head1 NAME

Silki::Web::Tab - A tab in the web UI

=head1 VERSION

version 0.29

=head1 AUTHOR

Dave Rolsky <autarch@urth.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2011 by Dave Rolsky.

This is free software, licensed under:

  The GNU Affero General Public License, Version 3, November 2007

=cut

