package Silki::AppRole::Tabs;
{
  $Silki::AppRole::Tabs::VERSION = '0.29';
}

use strict;
use warnings;
use namespace::autoclean;

use Scalar::Util qw( blessed );
use Silki::Web::Tab;
use Tie::IxHash;

use Moose::Role;

has _tabs => (
    is       => 'ro',
    isa      => 'Tie::IxHash',
    lazy     => 1,
    default  => sub { Tie::IxHash->new() },
    init_arg => undef,
    handles  => {
        tabs      => 'Values',
        _add_tab  => 'Push',
        tab_by_id => 'FETCH',
    },
);

sub add_tab {
    my $self = shift;
    my $tab  = shift;

    $tab = Silki::Web::Tab->new( %{$tab} )
        unless blessed $tab;

    $self->_add_tab( $tab->id() => $tab );
}

1;

# ABSTRACT: Adds tab-related methods to the Catalyst object

__END__
=pod

=head1 NAME

Silki::AppRole::Tabs - Adds tab-related methods to the Catalyst object

=head1 VERSION

version 0.29

=head1 AUTHOR

Dave Rolsky <autarch@urth.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2011 by Dave Rolsky.

This is free software, licensed under:

  The GNU Affero General Public License, Version 3, November 2007

=cut

