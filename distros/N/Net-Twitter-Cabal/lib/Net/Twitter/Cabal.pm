package Net::Twitter::Cabal;

use strict;
use warnings;

use base 'Class::Accessor::Fast';
__PACKAGE__->mk_accessors( qw/
	config
	/
);

use Carp;

use Encode;
binmode STDOUT, ":utf8";

use Log::Log4perl ':easy';
Log::Log4perl->easy_init( $DEBUG );

use AnyEvent::XMPP::Client;
use AnyEvent::XMPP::Util qw / split_jid /;
use AnyEvent::XMPP::Ext::Disco;
use AnyEvent::XMPP::Ext::Version;
use AnyEvent::XMPP::Ext::VCard;
use AnyEvent::XMPP::Namespaces 'xmpp_ns';
use AnyEvent;

use Net::Twitter;
use Net::Twitter::Cabal::Config;
use Net::Twitter::Cabal::Tweet;

=head1 NAME

Net::Twitter::Cabal - Manage posters to a Twitter stream

You have a Twitter stream than can be updated by several people. Dealing with
authorisation is painful, and there's no way to identify a poster.

Net::Twitter::Cabal let's you manage this stream from a central point, where
you have full control of who can post and without the need to distribute the
account's credentials.

=head1 VERSION

Version 0.03

=cut

our $VERSION = '0.03';


=head1 SYNOPSIS

Using Net::Twitter::Cabal you can create centralised endpoints for a group
of people to post to a single Twitter stream:

    use Net::Twitter::Cabal;

    my $conspiracy = Net::Twitter::Cabal->new( {
		'config' => 'config.yml',
	} );
	
	$conspiracy->run;

=head1 FUNCTIONS

=head2 new

Create a new cabal and initialise the configuration.

	my $conspiracy = Net::Twitter::Cabal->new( {
		'config' => 'config.yml';
	} );

=cut

sub new {
	my $proto = shift;
	my $class = ref $proto || $proto;
	
	my $self = $class->SUPER::new;
	
	my $args  = shift;
	
	my $cfgfile = defined $args->{'config'}? $args->{'config'} : undef;
	my $config  = Net::Twitter::Cabal::Config->new( { file => $cfgfile } );
	
	$self->config( $config );
	
	return $self;
}

=head2 run

Start the Cabal:

	$conspiracy->run;
	
=cut

sub run {
	my $self = shift;
	
	my $j       = AnyEvent->condvar;
	my $c       = AnyEvent::XMPP::Client->new( debug => 1 );
	
	my $c_args  = {
		initial_presence     => undef,
		dont_retrieve_roster => 1,
	};
	
	my $disco   = AnyEvent::XMPP::Ext::Disco->new;
	my $version = AnyEvent::XMPP::Ext::Version->new;
	$c->add_extension( $disco );
	$c->add_extension( $version );

	my $jid = $self->config->jid;
	my $pwd = $self->config->password;

	my $twitter = Net::Twitter->new(
		source   => 'cabal',
		username => $self->config->twitter,
		password => $self->config->twitterpw,
	);
	
	$c->add_account( $jid, $pwd, undef, undef, $c_args );	
	my $vcard = AnyEvent::XMPP::Ext::VCard->new;

	$c->reg_cb(
		stream_ready  => sub {
			my ( $cl, $acc ) = @_;
			$vcard->hook_on( $acc->connection, 1 );
		},
		
		session_ready => sub {
			my ( $cl, $acc ) = @_;
			INFO $acc->jid . " connected.";
			
			$vcard->store( $acc->connection, $self->_vcard, sub {
				if ( $_[0] ) {
					WARN "Couldn't store vcard: " . $_[0]->string;
					$cl->finish;
				}
			} );
			
			$cl->set_presence(
				undef,
				"Accepting tweets for " . $self->config->name,
				5
			);
			
			$self->_update_roster( $acc );
		},
				
		error => sub {
			my ( $cl, $acc, $err ) = @_;
			ERROR $err->string;
			$j->broadcast;
		},
		
		disconnect => sub {
			WARN "Disconnected: [@_]";
			$j->broadcast;
		},
		
		message => sub { $self->_got_message( @_, $twitter->clone ); },
		
		contact_request_subscribe => sub { $self->_got_subs_req( @_ ); },
		
		contact_subscribed => sub {
			my ( $cl, $acc, $roster, $contact ) = @_;
			
			$cl->send_message( AnyEvent::XMPP::IM::Message->new(
				to   => $contact->jid,
				body => "Hi There! Ready to post your tweets to " .
						$self->config->name . "."
			) );
		},
		
		contact_did_unsubscribe => sub {
			my ( $cl, $acc, $roster, $contact ) = @_;
			my $jid = $contact->jid;
			INFO "$jid unsubscribed from us";
		},
		
		contact_unsubscribed => sub {
			my ( $cl, $acc, $roster, $contact ) = @_;
			my $jid = $contact->jid;
			WARN "$jid unsubscribed us";
		},
		
		roster_update => sub { $j->broadcast; },
	);
	
	$c->start;
	$j->wait;
}

sub _got_message {
	my ( $self, $cl, $acc, $msg, $twitter ) = @_;
	
	my ( $user, $domain, $resource ) = split_jid( $msg->from );
	my $jid = $user . '@' . $domain;
	my $nick = $self->config->accept->{$jid};
	if ( ! defined $nick ) {
		$cl->send_message( AnyEvent::XMPP::IM::Message->new(
			to   => $msg->from,
			body => "Sorry, you're not on the list.",
		) );
		$self->_unsubscribe_from( $acc, $jid );
		return;
	}
	
	my $text = $msg->any_body;
	INFO "[$nick]: " . $text;
	
	my $tweet = Net::Twitter::Cabal::Tweet->new( {
		poster  => $nick,
		content => "[$nick]: $text",
	} );
	my $res = $twitter->update( $tweet->content );
	
	if ( ! defined $res ) {
		$cl->send_message( AnyEvent::XMPP::IM::Message->new(
			to   => $msg->from,
			body => "Urgh. Your message '$text' wasn't posted."
		) );
	} else {
		$cl->send_message( AnyEvent::XMPP::IM::Message->new(
			to   => $msg->from,
			body => "Message sent."
		) );
	}
	0;
}

sub _got_subs_req {
	my ( $self, $cl, $acc, $roster, $contact ) = @_;
	my $jid = $contact->jid;
	INFO "Subscription request from $jid";
	
	if ( exists $self->config->accept->{$jid} ) {
		$contact->send_subscribed;
		$contact->send_subscribe;
		INFO "Subscribed to $jid";
	} else {
		$contact->send_unsubscribed;
		INFO "Refused subscription from $jid";
	}
	
	0;
}

sub _unsubscribe_from {
	my ( $self, $acc, $from ) = @_;
	
	my $roster  = $acc->connection->roster;
	my $contact = $roster->get_contact( $from );
	
	if ( $contact ) {
		$contact->send_unsubscribed;
		$contact->send_unsubscribe;
	}
	
	INFO "Unsubscribed '$from', which isn't in my accept list.";
}

sub _update_roster {
	my ( $self, $acc ) = @_;
	
	my $roster = $acc->connection->roster;
	for my $contact ( $roster->get_contacts ) {
		my ( $user, $domain, $resource ) = split_jid( $contact->jid );
		my $jid = $user . '@' . $domain;
		if ( ! exists $self->config->accept->{$jid} ) {
			$self->_unsubscribe_from( $acc, $jid );
		}
	}
}

sub _vcard {
	my $self = shift;
	my %vcard;
	
	$vcard{'URL'} = [ $self->config->url ]
		if $self->config->url;
	$vcard{'FN'} = [ $self->config->name ];

	$vcard{'_avatar_type'} = $self->config->avatar->{'type'};
	$vcard{'_avatar'}      = $self->config->avatar->{'image'};

	return \%vcard;
}

=head1 AUTHOR

Pedro Figueiredo, C<< <me at pedrofigueiredo.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-net-twitter-cabal at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Net-Twitter-Cabal>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Net::Twitter::Cabal


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Net-Twitter-Cabal>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Net-Twitter-Cabal>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Net-Twitter-Cabal>

=item * Search CPAN

L<http://search.cpan.org/dist/Net-Twitter-Cabal/>

=back


=head1 ACKNOWLEDGEMENTS

=over 4

=item * Pedro Melo, for suggestions, testing, and holding my hand wrt XMPP

=item * Robin Redeker, author of AnyEvent::XMPP, for listening to my whining
        and clearing my doubts

=item * Nuno Nunes, for testing

=back

=head1 COPYRIGHT & LICENSE

Copyright 2009 Pedro Figueiredo, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

45; # End of Net::Twitter::Cabal
