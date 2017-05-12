  use strict;
  use warnings;
  use POE qw(Component::IRC Component::IRC::Plugin::Trac::RSS);

  my $nickname = 'TracRSS' . $$;
  my $ircname = 'TracRSS Name';
  my $ircserver = 'irc.nnnnn.net';
  my $port = 6667;
  my $channel = '#channel';
  my $rss_url = 'http://';
  my $rss_username = 'username';
  my $rss_password = 'password';

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
                'main' => [ qw(_start irc_001 irc_join irc_tracrss_items) ],
        ],
  );

  $poe_kernel->run();
  exit 0;

  sub _start {
    # Create and load our plugin
    $irc->plugin_add( 'TracRSS' =>
        POE::Component::IRC::Plugin::Trac::RSS->new() );

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
    $kernel->yield( 'get_tracrss', { url => $rss_url, username => $rss_username, password => $rss_password, _channel => $channel } );
    undef;
  }

  sub irc_tracrss_items {
    my ($kernel,$sender,$args) = @_[KERNEL,SENDER,ARG0];
    my $channel = delete $args->{_channel};
    #foreach(@_[ARG1..$#_]) {
    foreach(@_[ARG1..ARG4]) {
    print '$_\n';
    $kernel->post( $sender, 'privmsg', $channel,  $_ );
    }
    undef;
  
  }


