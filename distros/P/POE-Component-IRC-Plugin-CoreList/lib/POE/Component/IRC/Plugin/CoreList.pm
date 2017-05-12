package POE::Component::IRC::Plugin::CoreList;
$POE::Component::IRC::Plugin::CoreList::VERSION = '1.06';
#ABSTRACT: A POE::Component::IRC plugin that provides Module::CoreList goodness.

use strict;
use warnings;
use Module::CoreList;
use POE::Component::IRC::Plugin qw(:ALL);

my $cmds  = qr/find|search|release|date/;

sub new {
  my $package = shift;
  my %args = @_;
  $args{lc $_} = delete $args{$_} for keys %args;
  bless \%args, $package;
}

sub PCI_register {
  my ($self,$irc) = @_;
  $irc->plugin_register( $self, 'SERVER', qw(public msg) );
  return 1;
}

sub PCI_unregister {
  return 1;
}

sub S_public {
  my ($self,$irc) = splice @_, 0 , 2;
  my ($nick,$userhost) = ( split /!/, ${ $_[0] } )[0..1];
  my $channel = ${ $_[1] }->[0];
  my $what = ${ $_[2] };
  my $mynick = $irc->nick_name();
  my $cmdstr = $self->{command} || '';
  my ($string) = $what =~ m/^\s*\Q$mynick\E[\:\,\;\.]?\s*(.*)$/i;
  return PCI_EAT_NONE unless ( $string and $string =~ /^\Q$cmdstr\E\s*(?:($cmds))?\s*(.*)/io );
  my ( $command, $module, @args ) = ( $1 || 'release', split /\s+/, $2 );
  my $reply = _corelist( $command, $module, @args );
  $irc->yield( 'privmsg', $channel, $reply );
  return PCI_EAT_NONE;
}

sub S_msg {
  my ($self,$irc) = splice @_, 0 , 2;
  my ($nick,$userhost) = ( split /!/, ${ $_[0] } )[0..1];
  my $string = ${ $_[2] };
  my $cmdstr = $self->{command} || '';
  return PCI_EAT_NONE unless ( $string and $string =~ /^\Q$cmdstr\E\s*(?:($cmds))?\s*(.*)/io );
  my ( $command, $module, @args ) = ( $1 || 'release', split /\s+/, $2 );
  my $reply = _corelist( $command, $module, @args );
  $irc->yield( ( $self->{privmsg} ? 'privmsg' : 'notice' ), $nick, $reply );
  return PCI_EAT_NONE;
}

sub _corelist {
  my ($command,$module,@args) = @_;
  # compute the reply
  my $reply;
  if ( $command =~ /^(?:find|search)$/i ) {
        my @modules = Module::CoreList->find_modules( qr/$module/, @args );

        # shorten large response lists
        @modules = (@modules[0..8], '...') if @modules > 9;

        local $" = ', ';
        my $where = ( @args ? " in perl @args" : '' );
        $reply = ( @modules
            ? "Found @modules"
            : "Found no module matching /$module/" )
            . $where;
  }
  else {
        my ( $release, $patchlevel, $date )
            = ( Module::CoreList->first_release($module), '', '' );
        if ($release) {
            $date  = $Module::CoreList::released{$release};
        }
        my $rem;
        if ( Module::CoreList->can('removed_from') ) {
          my $removed = Module::CoreList->removed_from($module);
          if ( $removed ) {
            my $remdate = $Module::CoreList::released{$removed};
            $rem = " and removed from $removed (released on $remdate)";
          }
        }
        $reply = $release
            ? "$module was first released with perl $release ("
            . "released on $date)"
            . ( $rem ? $rem : '' )
            : "$module is not in the core";
  }
  return $reply;
}

qq[Apple::Core];

__END__

=pod

=encoding UTF-8

=head1 NAME

POE::Component::IRC::Plugin::CoreList - A POE::Component::IRC plugin that provides Module::CoreList goodness.

=head1 VERSION

version 1.06

=head1 SYNOPSIS

  use strict;
  use warnings;
  use POE qw(Component::IRC Component::IRC::Plugin::CoreList);

  my $nickname = 'Core' . $$;
  my $ircname = 'CoreList Bot';
  my $ircserver = 'irc.bleh.net';
  my $port = 6667;
  my $channel = '#IRC.pm';

  my $irc = POE::Component::IRC->spawn(
        nick => $nickname,
        server => $ircserver,
        port => $port,
        ircname => $ircname,
        debug => 0,
        plugin_debug => 1,
        options => { trace => 0 },
  ) or die "Oh noooo! $!";

  POE::Session->create(
        package_states => [
                'main' => [ qw(_start irc_001) ],
        ],
  );

  $poe_kernel->run();
  exit 0;

  sub _start {
    # Create and load our CoreList plugin
    $irc->plugin_add( 'CoreList' =>
        POE::Component::IRC::Plugin::CoreList->new( command => 'core' ) );

    $irc->yield( register => 'all' );
    $irc->yield( connect => { } );
    undef;
  }

  sub irc_001 {
    $irc->yield( join => $channel );
    undef;
  }

=head1 DESCRIPTION

POE::Component::IRC::Plugin::CoreList is a port of L<Bot::BasicBot::Pluggable::Module::CoreList> to the
L<POE::Component::IRC> plugin framework. It is a frontend to the excellent L<Module::CoreList> module 
which will let you know what modules shipped with which versions of perl, over IRC.

=for Pod::Coverage PCI_register PCI_unregister S_msg S_public

=head1 CONSTRUCTOR

=over

=item C<new>

Creates a new plugin object. Takes some optional parameter:

  'command', define a command that will proceed subcommands;
  'privmsg', set to a true value to specify that the bot should reply with PRIVMSG instead of 
	     NOTICE to privmsgs that it receives.

=back

=head1 IRC USAGE

The bot replies to requests in the following form:

    <optional_command> <subcommand> [args]

=head2 Commands

The bot understand the following subcommands:

=over 4

=item * C<release>

=item * C<date>

    < you> bot: release Test::More
    < bot> you: Test::More was first released with perl 5.7.3 (patchlevel perl/15039, released on 2002-03-05)

If no command is given, C<release> is the default.

    < you> bot: Test::More
    < bot> you: Test::More was first released with perl 5.7.3 (patchlevel perl/15039, released on 2002-03-05)

=item * C<search>

=item * C<find>

    < you> bot search Data
    < bot> Found Data::Dumper, Module::Build::ConfigData

Perl version numbers can be passed as optional parameters to restrict
the search:

    < you> bot: search Data 5.006
    < bot> Found Data::Dumper in perl 5.006

The search never returns more than 9 replies, to avoid flooding the channel:

    < you> bot: find e
    < bot> Found AnyDBM_File, AutoLoader, B::Assembler, B::Bytecode, B::Debug, B::Deparse, B::Disassembler, B::Showlex, B::Terse, ... 

=back

=head1 SEE ALSO

L<POE::Component::IRC>

L<Bot::BasicBot::Pluggable::Module::CoreList>

=head1 AUTHORS

=over 4

=item *

Chris Williams <chris@bingosnet.co.uk>

=item *

Philippe "BooK" Bruhat <book@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Chris Williams and Philippe Bruhat.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
