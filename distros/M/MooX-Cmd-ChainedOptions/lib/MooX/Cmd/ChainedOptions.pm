# --8<--8<--8<--8<--
#
# Copyright (C) 2015 Smithsonian Astrophysical Observatory
#
# This file is part of MooX-Cmd-ChainedOptions
#
# MooX-Cmd-ChainedOptions is free software: you can redistribute it
# and/or modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation, either version 3 of
# the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
# -->8-->8-->8-->8--

package MooX::Cmd::ChainedOptions;

use strict;
use warnings;

our $VERSION = '0.03';

use Import::Into;
use Moo::Role     ();
use MooX::Options ();

use MooX::Cmd::ChainedOptions::Role ();
use List::Util qw/ first /;

my %ROLE;

sub import {

    my $class  = shift;
    my $target = caller;

    unless ( $target->DOES( 'MooX::Cmd::Role' ) ) {
        require Carp;
        Carp::croak( "$target must use MooX::Cmd prior to using ",
            __PACKAGE__, "\n" );
    }

    # don't do this twice
    return if $ROLE{$target};

    # load MooX::Options into target class.
    MooX::Options->import::into( $target );

    # guess if an app or a command

    # if $target is a cmd, a parent class (app or cmd) must have
    # been loaded.  $target must be a direct descendant of a
    # parent class' command_base.  use the _build_command_base method
    # as it can be used as a class method; command_base is an object method

    my ( $base, $pkg ) = $target =~ /^(.*)?::([^:]+)$/;
    $base ||= '';
    my $parent = first { $base eq $_->_build_command_base } keys %ROLE;

    $ROLE{$target}
      = $parent
      ? MooX::Cmd::ChainedOptions::Role->build_variant( $parent,
        $ROLE{$parent} )
      : __PACKAGE__ . '::Base';

    # need only apply role to commands & subcommands
    Moo::Role->apply_roles_to_package( $target, $ROLE{$target} )
      if $parent;

    return;
}

1;


__END__

=pod

=head1 NAME

MooX::Cmd::ChainedOptions - easily access options from higher up the command chain

=head1 SYNOPSIS

  # MyApp.pm : App Base Class
  use Moo;
  use MooX::Cmd;
  use MooX::Cmd::ChainedOptions;

  option app_opt => ( is => 'ro', format => 's', default => 'BASE' );

  sub execute {
      print $_[0]->app_opt, "\n";
  }

  # MyApp/Cmd/cmd.pm : Command Class
  package MyApp::Cmd::cmd;
  use Moo;
  use MooX::Cmd;
  use MooX::Cmd::ChainedOptions;

  option cmd_opt => ( is => 'ro', format => 's', default => 'A' );

  sub execute {
      print $_[0]->app_opt, "\n";
      print $_[0]->cmd_opt, "\n";
  }

  # MyApp/Cmd/cmd/Cmd/subcmd.pm : Sub-Command Class
  package MyApp::Cmd::cmd::Cmd::subcmd;
  use Moo;
  use MooX::Cmd;
  use MooX::Cmd::ChainedOptions;

  option subcmd_opt => ( is => 'ro', format => 's', default => 'B' );

  sub execute {
      print $_[0]->app_opt, "\n";
      print $_[0]->cmd_opt, "\n";
      print $_[0]->subcmd_opt, "\n";
  }

=head1 DESCRIPTION

For applications using L<MooX::Cmd> and L<MooX::Options>,
B<MooX::Cmd::ChainedOptions> transparently provides access to command
line options from further up the command chain.

For example, if an application provides options at each level of the
command structure:

  app --app-opt cmd --cmd-opt subcmd --subcmd-opt

The B<subcmd> object will have direct access to the C<app_option> and
C<cmd_option> options via object attributes:

  sub execute {
      print $self->app_opt, "\n";
      print $self->cmd_opt, "\n";
      print $self->subcmd_opt, "\n";
  }


=head1 USAGE

Simply

  use MooX::Cmd::ChainedOptions;

instead of

  use MooX::Options;

Every layer in the application heirarchy (application class, command
class, sub-command class) must use B<MooX::Cmd::ChainedOptions>.  See
the L</SYNOPSIS> for an example.

=head1 COPYRIGHT AND LICENSE

Copyright 2015 Smithsonian Astrophysical Observatory

This software is released under the GNU General Public License.  You
may find a copy at

          http://www.gnu.org/licenses

=cut

=head1 AUTHOR

Diab Jerius (cpan:DJERIUS) <djerius@cfa.harvard.edu>

