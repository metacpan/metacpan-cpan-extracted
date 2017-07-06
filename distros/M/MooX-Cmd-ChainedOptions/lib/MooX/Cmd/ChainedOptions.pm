package MooX::Cmd::ChainedOptions;

# ABSTRACT: easily access options from higher up the command chain

use strict;
use warnings;

our $VERSION = '0.04';

use Import::Into;
use Moo::Role     ();
use MooX::Options ();

use MooX::Cmd::ChainedOptions::Role ();
use List::Util qw/ first /;

use namespace::clean;

my %ROLE;

sub import {

    shift;
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

    my ( $base ) = $target =~ /^(.*)?::([^:]+)$/;
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

#
# This file is part of MooX-Cmd-ChainedOptions
#
# This software is Copyright (c) 2017 by Smithsonian Astrophysical Observatory.
#
# This is free software, licensed under:
#
#   The GNU General Public License, Version 3, June 2007
#

=pod

=head1 NAME

MooX::Cmd::ChainedOptions - easily access options from higher up the command chain

=head1 VERSION

version 0.04

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

Every layer in the application hierarchy (application class, command
class, sub-command class) must use B<MooX::Cmd::ChainedOptions>.  See
the L</SYNOPSIS> for an example.

=head1 BUGS AND LIMITATIONS

You can make new bug reports, and view existing ones, through the
web interface at L<https://rt.cpan.org/Public/Dist/Display.html?Name=MooX-Cmd-ChainedOptions>.

=head1 AUTHOR

Diab Jerius <djerius@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2017 by Smithsonian Astrophysical Observatory.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut

__END__

#pod =pod
#pod
#pod =head1 SYNOPSIS
#pod
#pod   # MyApp.pm : App Base Class
#pod   use Moo;
#pod   use MooX::Cmd;
#pod   use MooX::Cmd::ChainedOptions;
#pod
#pod   option app_opt => ( is => 'ro', format => 's', default => 'BASE' );
#pod
#pod   sub execute {
#pod       print $_[0]->app_opt, "\n";
#pod   }
#pod
#pod   # MyApp/Cmd/cmd.pm : Command Class
#pod   package MyApp::Cmd::cmd;
#pod   use Moo;
#pod   use MooX::Cmd;
#pod   use MooX::Cmd::ChainedOptions;
#pod
#pod   option cmd_opt => ( is => 'ro', format => 's', default => 'A' );
#pod
#pod   sub execute {
#pod       print $_[0]->app_opt, "\n";
#pod       print $_[0]->cmd_opt, "\n";
#pod   }
#pod
#pod   # MyApp/Cmd/cmd/Cmd/subcmd.pm : Sub-Command Class
#pod   package MyApp::Cmd::cmd::Cmd::subcmd;
#pod   use Moo;
#pod   use MooX::Cmd;
#pod   use MooX::Cmd::ChainedOptions;
#pod
#pod   option subcmd_opt => ( is => 'ro', format => 's', default => 'B' );
#pod
#pod   sub execute {
#pod       print $_[0]->app_opt, "\n";
#pod       print $_[0]->cmd_opt, "\n";
#pod       print $_[0]->subcmd_opt, "\n";
#pod   }
#pod
#pod =head1 DESCRIPTION
#pod
#pod For applications using L<MooX::Cmd> and L<MooX::Options>,
#pod B<MooX::Cmd::ChainedOptions> transparently provides access to command
#pod line options from further up the command chain.
#pod
#pod For example, if an application provides options at each level of the
#pod command structure:
#pod
#pod   app --app-opt cmd --cmd-opt subcmd --subcmd-opt
#pod
#pod The B<subcmd> object will have direct access to the C<app_option> and
#pod C<cmd_option> options via object attributes:
#pod
#pod   sub execute {
#pod       print $self->app_opt, "\n";
#pod       print $self->cmd_opt, "\n";
#pod       print $self->subcmd_opt, "\n";
#pod   }
#pod
#pod
#pod =head1 USAGE
#pod
#pod Simply
#pod
#pod   use MooX::Cmd::ChainedOptions;
#pod
#pod instead of
#pod
#pod   use MooX::Options;
#pod
#pod Every layer in the application hierarchy (application class, command
#pod class, sub-command class) must use B<MooX::Cmd::ChainedOptions>.  See
#pod the L</SYNOPSIS> for an example.
#pod
#pod =head1 SEE ALSO
#pod
