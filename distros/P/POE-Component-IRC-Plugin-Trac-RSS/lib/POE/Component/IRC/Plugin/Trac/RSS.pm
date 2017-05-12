package POE::Component::IRC::Plugin::Trac::RSS;

use strict;
use warnings;
use POE;
use POE::Component::Client::HTTP;
use POE::Component::IRC::Plugin qw(:ALL);
use XML::RSS;
use HTTP::Request;
use vars qw($VERSION);

$VERSION = '0.11';

sub new {
	my $package = shift;
	my %args = @_;
	
	$args{lc $_} = delete $args{$_} for keys %args;
	return bless \%args, $package;
}

sub PCI_register {
	my ($self,$irc) = @_;
	
	$self->{irc} = $irc;
	$irc->plugin_register( $self, 'SERVER', qw(spoof) );
	
	unless ( $self->{http_alias} ) {
		$self->{http_alias} = join('-', 'ua-trac-rss', 
			$irc->session_id() );
		$self->{follow_redirects} ||= 2;
		POE::Component::Client::HTTP->spawn(
	   	Alias           => $self->{http_alias},
	   	Timeout         => 30,
	   	FollowRedirects => $self->{follow_redirects},
		);
  	}
  
	$self->{session_id} = POE::Session->create(
		object_states => [ 
		$self => [ qw(_shutdown _start _get_tracrss _response) ],
		],
  	)->ID();
	$poe_kernel->state( 'get_tracrss', $self );
	return 1;
}

sub PCI_unregister {
	my ($self,$irc) = splice @_, 0, 2;
	
	$poe_kernel->state( 'get_tracrss' );
	$poe_kernel->call( $self->{session_id} => '_shutdown' );
	delete $self->{irc};
	return 1;
}

sub _start {
	my ($kernel,$self) = @_[KERNEL,OBJECT];
	
	$self->{session_id} = $_[SESSION]->ID();
	$kernel->refcount_increment( $self->{session_id}, __PACKAGE__ );
	undef;
}

sub _shutdown {
	my ($kernel,$self) = @_[KERNEL,OBJECT];
  
	$kernel->alarm_remove_all();
	$kernel->refcount_decrement( $self->{session_id}, __PACKAGE__ );
	$kernel->call( $self->{http_alias} => 'shutdown' );
	undef;
}

sub get_tracrss {
	my ($kernel,$self,$session) = @_[KERNEL,OBJECT,SESSION];
	$kernel->post( $self->{session_id}, '_get_tracrss', @_[ARG0..$#_] );
	undef;
}

sub _get_tracrss {
	my ($kernel,$self) = @_[KERNEL,OBJECT];
	my %args;
  
	if ( ref $_[ARG0] eq 'HASH' ) {
		%args = %{ $_[ARG0] };
	} else {
		%args = @_[ARG0..$#_];
	}
  
	$args{lc $_} = delete $args{$_} for grep { !/^_/ } keys %args;
	return unless $args{url};
	$args{irc_session} = $self->{irc}->session_id();
  
	my $req = HTTP::Request->new( GET => $args{url});
	$req->authorization_basic($args{username}, $args{password});

	$kernel->post( $self->{http_alias}, 'request', '_response', $req, 
		\%args );

	undef;
}

sub _response {
	my ($kernel,$self,$request,$response) = @_[KERNEL,OBJECT,ARG0,ARG1];
	my $args = $request->[1];
	my @params;

	push @params, delete $args->{irc_session}, '__send_event';
	my $result = $response->[0];

	if ( $result->is_success ) {
		my $str = $result->content;
		my $rss = XML::RSS->new();
		eval { $rss->parse($str); };
		if ($@) {
			push @params, 'irc_tracrss_error', $args, $@;
		} else {
			push @params, 'irc_tracrss_items', $args;
			
			foreach (@{ $rss->{'items'} }) {
				my $say = $_->{'title'} . ": ";
				$say .= $_->{'link'};
				push @params, $say;
			}
	}

  
	} else {
		push @params, 'irc_tracrss_error', $args, $result->status_line;
	}
	$kernel->post( @params );
}

1;
__END__

=head1 NAME

POE::Component::IRC::Plugin::Trac::RSS - A POE::Component::IRC plugin that provides RSS headline retrieval.

=head1 SYNOPSIS

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
    $kernel->post( $sender, 'privmsg', $channel, join(' ', @_[ARG1..$#_] ) );
    undef;
  }

=head1 DESCRIPTION

POE::Component::IRC::Plugin::Trac::RSS, is a L<POE::Component::IRC> plugin that provides
a mechanism for retrieving Trac/RSS headlines from given URLs.

=head1 CONSTRUCTOR

=over 

=item new

Creates a new plugin object. Takes the following optional arguments:

  'http_alias', you may provide the alias of an existing POE::Component::Client::HTTP 
		component that the plugin will use instead of spawning it's own;
  'follow_redirects', this argument is passed to PoCoCl::HTTP to inform it how to deal with
		following redirects, default is 2;

=back

=head1 INPUT EVENTS

The plugin registers the following state handler within your session:

=over

=item get_trac_rss

Takes a hashref as an argument with the following keys:

  'url', the RSS based url to retrieve items for;
  'username', Username to login in trac.
  'password', Password to login in trac.

You may pass arbitary key/value pairs, but the keys must be prefixed with an underscore.

=back

=head1 OUTPUT

The following irc event is generated with the result of a 'get_headline' command:

=over

=item irc_tracrss_items

Has the following parameters:

  'ARG0', the original hashref that was passed;
  'ARG1' .. $#_, RSS headline item titles;

=item irc_tracrss_error

Has the following parameters:

  'ARG0', the original hashref that was passed;
  'ARG1', the error text;

=back

=head1 AUTHOR

Thiago Berlitz Rondon

=head1 LICENSE

Copyright C<(c)> Thiago Berlitz Rondon

This module may be used, modified, and distributed under the same terms as Perl itself. Please see the license that came with your Perl distribution for details.

=head1 SEE ALSO

L<POE::Component::IRC>

