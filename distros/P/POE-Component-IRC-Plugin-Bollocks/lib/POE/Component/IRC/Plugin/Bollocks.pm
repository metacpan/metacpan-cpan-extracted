package POE::Component::IRC::Plugin::Bollocks;
$POE::Component::IRC::Plugin::Bollocks::VERSION = '1.02';
#ABSTRACT: A POE::Component::IRC plugin that talks bollocks.

use strict;
use warnings;
use Dev::Bollocks;
use POE::Component::IRC::Plugin qw(:ALL);

my @phrases = (
  "So, let's ", 'We can ', 'We should ', 'Our mission is to ',
  'Our job is to ', 'Your job is to ', 'And next we ', 'We better ',
  'All of us plan to ', 'It is important to ', 'We were told to ',
  'Our mission is to ', 'According to our plan we ');

sub new {
  my $package = shift;
  my %args = @_;
  $args{lc $_} = delete $args{$_} for keys %args;
  bless \%args, $package;
}

sub PCI_register {
  my ($self,$irc) = @_;
  $irc->plugin_register( $self, 'SERVER', qw(public) );
  return 1;
}

sub PCI_unregister {
  return 1;
}

sub S_public {
  my ($self,$irc) = splice @_, 0, 2;
  my ($nick,$userhost) = ( split /!/, ${ $_[0] } )[0..1];
  my $channel = ${ $_[1] }->[0];
  my $what = ${ $_[2] };
  my $mynick = $irc->nick_name();
  my ($command) = $what =~ m/^\s*\Q$mynick\E[\:\,\;\.]?\s*(.*)$/i;
  return PCI_EAT_NONE unless $command;
  my @cmd = split /\s+/, $command;
  return PCI_EAT_NONE unless uc( $cmd[0] ) eq 'BOLLOCKS';
  $irc->yield( privmsg =>
	       $channel =>
	       $phrases[int(rand(scalar @phrases))] . Dev::Bollocks->rand( int(rand(3) + 3)) );
  return PCI_EAT_NONE;
}

qq[It's all bollocks];

__END__

=pod

=encoding UTF-8

=head1 NAME

POE::Component::IRC::Plugin::Bollocks - A POE::Component::IRC plugin that talks bollocks.

=head1 VERSION

version 1.02

=head1 SYNOPSIS

  use strict;
  use warnings;
  use POE qw(Component::IRC Component::IRC::Plugin::Bollocks);

  my $nickname = 'Pointy' . $$;
  my $ircname = 'Pointy Haired Boss';
  my $ircserver = 'irc.blah.org';
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
    # Create and load our CTCP plugin
    $irc->plugin_add( 'Bollocks' =>
        POE::Component::IRC::Plugin::Bollocks->new() );

    $irc->yield( register => 'all' );
    $irc->yield( connect => { } );
    undef;
  }

  sub irc_001 {
    $irc->yield( join => $channel );
    undef;
  }

=head1 DESCRIPTION

POE::Component::IRC::Plugin::Bollocks is a L<POE::Component::IRC> plugin generates management bullshit whenever you need it.

=for Pod::Coverage PCI_register PCI_unregister S_public

=head1 CONSTRUCTOR

=over

=item C<new>

Creates a new plugin object.

=back

=head1 IRC INPUT

=over

=item C<BOLLOCKS>

If your bot is addressed by name with the command 'BOLLOCKS' (case doesn't matter), it will write some
random management bollocks to the channel.

=back

=head1 SEE ALSO

L<POE::Component::IRC>

L<Dev::Bollocks>

=head1 AUTHOR

Chris Williams <chris@bingosnet.co.uk>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Chris Williams.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
