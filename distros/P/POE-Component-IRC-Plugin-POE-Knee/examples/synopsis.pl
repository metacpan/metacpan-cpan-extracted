  use strict;
  use warnings;
  use POE qw(Component::IRC::State Component::IRC::Plugin::POE::Knee);

  my $nickname = 'PoeKnee' . $$;
  my $ircname = 'PoeKnee the Sailor Bot';
  my $ircserver = 'irc.blah.org';
  my $port = 6667;
  my $channel = '#IRC.pm';

  my $irc = POE::Component::IRC::State->spawn(
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
                'main' => [ qw(_start irc_001 irc_poeknee_results) ],
        ],
  );

  $poe_kernel->run();
  exit 0;

  sub _start {
    # Create and load our CTCP plugin
    $irc->plugin_add( 'PoeKnee' =>
        POE::Component::IRC::Plugin::POE::Knee->new( stages => 8 ) );

    $irc->yield( register => 'all' );
    $irc->yield( connect => { } );
    undef;
  }

  sub irc_001 {
    $irc->yield( join => $channel );
    undef;
  }

  sub irc_poeknee_results {
    my ($channel,$results) = @_[ARG0,ARG1];
    print "$channel\n";
    print "$_\n" for @{ $results };
    undef;
  }
