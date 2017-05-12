  use strict;
  use warnings;
  use POE qw(Component::IRC Component::IRC::Plugin::RSS::Headlines);

  my $nickname = 'RSSHead' . $$;
  my $ircname = 'RSSHead the Sailor Bot';
  my $ircserver = 'irc.perl.org';
  my $port = 6667;
  my $channel = '#IRC.pm';
  my $rss_url = 'http://eekeek.org/jerkcity.cgi';

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
                'main' => [ qw(_start irc_001 irc_join irc_rssheadlines_items) ],
        ],
  );

  $poe_kernel->run();
  exit 0;

  sub _start {
    # Create and load our plugin
    $irc->plugin_add( 'RSSHead' =>
        POE::Component::IRC::Plugin::RSS::Headlines->new() );

    $irc->yield( register => 'all' );
    $irc->yield( connect => { } );
    undef;
  }

  sub irc_001 {
    $irc->yield( join => $channel );
    undef;
  }

  sub irc_join {
    my ($kernel,$sender,$channel) = @_[KERNEL,SENDER,ARG1];
    print STDERR "$channel $rss_url\n";
    $kernel->yield( 'get_headline', { url => $rss_url, _channel => $channel } );
    undef;
  }

  sub irc_rssheadlines_items {
    my ($kernel,$sender,$args) = @_[KERNEL,SENDER,ARG0];
    my $channel = delete $args->{_channel};
    $kernel->post( $sender, 'privmsg', $channel, join(' ', @_[ARG1..$#_] ) );
    undef;
  }
