#
# This file is part of POE-Component-IRC-Plugin-Karma
#
# This software is copyright (c) 2011 by Apocalypse.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
use strict; use warnings;
package POE::Component::IRC::Plugin::Karma;
BEGIN {
  $POE::Component::IRC::Plugin::Karma::VERSION = '0.003';
}
BEGIN {
  $POE::Component::IRC::Plugin::Karma::AUTHORITY = 'cpan:APOCAL';
}

# ABSTRACT: A POE::Component::IRC plugin that keeps track of karma

use Moose;
use DBI;
use DBD::SQLite;
use POE::Component::IRC::Plugin qw( PCI_EAT_NONE );
use POE::Component::IRC::Common qw( parse_user );

# TODO split the datastore stuff into pocoirc-plugin-datastore
# so it can be used by other plugins that need to store data
# then we can code plugin-seen and plugin-awaymsg stuff and have it use the datastore
# make it as braindead ez to use as the bot-basicbot system of saving data :)
# Getty wants me to have it use dbic which would make it even more awesome...

# TODO do we need a help system? "bot: karma" should return whatever...

# TODO do we need a botsnack thingy? bot++ bot--
# seen in bot-basicbot-karma where a user tries to karma the bot itself and it replies with something

# TODO
# <@Hinrik> maybe you should separate the parsing from the IRC plugin
# <@Hinrik> so there'd be a Karma module which people could apply to any text (e.g. IRC logs)
# <@Hinrik> and also for people like buu who use an entirely different kind of IRC plugin

# TODO do we need a warn_selfkarma option so it warns the user trying to karma themselves?

# TODO
#<Getty> explain duckduckgo
#<Getty> explain karma duckduckgo
#<Getty> ah not implemented, ok

# TODO
#<Apocalypse> Hinrik: I was wondering - in my karma stuff I use lc( $nick ) to compare it for selfkarma
#<Apocalypse> Should I use the l_irc thingy? What reason does it exist for? :)
#<@Hinrik> because according to RFC1459, "foo{" if the lowercase version of and "FOO["
#<Apocalypse> parse fail - what did you meant to say? foo{ is the uc equivalent of FOO[ ?
#<@Hinrik> l_irc("FOO[") == "foo{"
#<@Hinrik> not all servers use the rfc1459 casemapping though, which is why it's safest to call the function with a casemapping parameter, which you can get via $irc->isupport('CASEMAPPING');
#<Apocalypse> why is the irc protocol that insane? ;)
#<@Hinrik> RFC1459 says that this particular insanity is due to the Finnish keyboard layout, I believe
#<Apocalypse> haha
#<@Hinrik> where shift+{ gives you [ or something
#<Apocalypse> alright thanks for the info, I'll attack it later and see what happens :)


has 'addressed' => (
	is	=> 'rw',
	isa	=> 'Bool',
	default	=> 0,
);


has 'casesens' => (
	is	=> 'rw',
	isa	=> 'Bool',
	default	=> 0,
);


has 'privmsg' => (
	is	=> 'rw',
	isa	=> 'Bool',
	default	=> 0,
);


has 'selfkarma' => (
	is	=> 'rw',
	isa	=> 'Bool',
	default	=> 0,
);


has 'replykarma' => (
	is	=> 'rw',
	isa	=> 'Bool',
	default	=> 0,
);


has 'extrastats' => (
	is	=> 'rw',
	isa	=> 'Bool',
	default	=> 0,
);


has 'sqlite' => (
	is	=> 'ro',
	isa	=> 'Str',
	default	=> 'karma_stats.db',
);

sub PCI_register {
	my ( $self, $irc ) = @_;

	$irc->plugin_register( $self, 'SERVER', qw( public msg ctcp_action ) );

	# setup the db
	$self->_setup_dbi( $self->_get_dbi );

	return 1;
}

sub PCI_unregister {
	my ( $self, $irc ) = @_;

	return 1;
}

sub S_ctcp_action {
	my ( $self, $irc ) = splice @_, 0 , 2;
	my ( $nick, $user, $host ) = parse_user( ${ $_[0] } );
	my $channel = ${ $_[1] }->[0];
	my $msg = ${ $_[2] };

	my $reply = $self->_karma(
		nick	=> $nick,
		user	=> $user,
		host	=> $host,
		where	=> $channel,
		str	=> ${ $_[2] },
	);

	if ( defined $reply ) {
		$irc->yield( 'privmsg', $channel, $nick . ': ' . $_ ) for @$reply;
	}

	return PCI_EAT_NONE;
}

sub S_public {
	my ( $self, $irc ) = splice @_, 0 , 2;
	my ( $nick, $user, $host ) = parse_user( ${ $_[0] } );
	my $channel = ${ $_[1] }->[0];
	my $msg = ${ $_[2] };
	my $string;

	# check addressed mode first
	my $mynick = $irc->nick_name();
	($string) = $msg =~ m/^\s*\Q$mynick\E[\:\,\;\.]?\s*(.*)$/i;
	if ( ! defined $string and ! $self->addressed ) {
		$string = $msg;
	}

	if ( defined $string ) {
		my $reply = $self->_karma(
			nick	=> $nick,
			user	=> $user,
			host	=> $host,
			where	=> $channel,
			str	=> $string,
		);

		if ( defined $reply ) {
			foreach my $r ( @$reply ) {
				if ( $self->privmsg ) {
					$irc->yield( 'privmsg', $nick, $r );
				} else {
					$irc->yield( 'privmsg', $channel, $nick . ': ' . $r );
				}
			}
		}
	}

	return PCI_EAT_NONE;
}

sub S_msg {
	my ( $self, $irc ) = splice @_, 0 , 2;
	my ( $nick, $user, $host ) = parse_user( ${ $_[0] } );

	my $reply = $self->_karma(
		nick	=> $nick,
		user	=> $user,
		host	=> $host,
		where	=> 'privmsg',
		str	=> ${ $_[2] },
	);

	if ( defined $reply ) {
		$irc->yield( 'privmsg', $nick, $_ ) for @$reply;
	}

	return PCI_EAT_NONE;
}

sub _karma {
	my( $self, %args ) = @_;

	# many different ways to get karma...
	if ( $args{'str'} =~ /^\s*karma\s*(.+)$/i ) {
		# return the karma of the requested string
		return [ $self->_get_karma( $1 ) ];

	# TODO are those worth it to implement?
#	} elsif ( $args{'str'} =~ /^\s*karmahigh\s*$/i ) {
#		# return the list of highest karma'd words
#		return [ $self->_get_karmahigh ];
#	} elsif ( $args{'str'} =~ /^\s*karmalow\s*$/i ) {
#		# return the list of lowest karma'd words
#		return [ $self->_get_karmalow ];
#	} elsif ( $args{'str'} =~ /^\s*karmalast\s*(.+)$/ ) {
#		# returns the list of last karma contributors
#		my $karma = $1;
#
#		# clean the karma
#		$karma =~ s/^\s+//;
#		$karma =~ s/\s+$//;
#
#		return [ $self->_get_karmalast( $karma ) ];

	} else {
		# get the list of karma matches
		# TODO still needs a bit more work, see t/parsing.t
		my @matches = ( $args{'str'} =~ /(\([^\)]+\)|\S+)(\+\+|--)\s*(\#.+)?/g );
		if ( @matches ) {
			my @replies;
			while ( my( $karma, $op, $comment ) = splice( @matches, 0, 3 ) ) {
				# clean the karma of spaces and () as we had to capture them
				$karma =~ s/^[\s\(]+//;
				$karma =~ s/[\s\)]+$//;

				# Is it a selfkarma?
				if ( ! $self->selfkarma and lc( $karma ) eq lc( $args{'nick'} ) ) {
					next;
				} else {
					# clean the comment
					$comment =~ s/^\s*\#\s*// if defined $comment;

					$self->_add_karma(
						karma	=> $karma,
						op	=> $op,
						comment	=> $comment,
						%args,
					);

					if ( $self->replykarma ) {
						push( @replies, $self->_get_karma( $karma ) );
					}
				}
			}

			return \@replies;
		}
	}

	return;
}

sub _get_karma {
	my( $self, $karma ) = @_;

	# case-sensitive search or not?
	my $sql = 'SELECT mode, count(mode) AS count FROM karma WHERE karma = ?';
	if ( ! $self->casesens ) {
		$sql .= ' COLLATE NOCASE';
	}
	$sql .= ' GROUP BY mode';

	# Get the score from the DB
	my $dbh = $self->_get_dbi;
	my $sth = $dbh->prepare_cached( $sql ) or die $dbh->errstr;
	$sth->execute( $karma ) or die $sth->errstr;
	my( $up, $down ) = ( 0, 0 );
	while ( my $row = $sth->fetchrow_arrayref ) {
		if ( $row->[0] == 1 ) {
			$up = $row->[1];
		} else {
			$down = $row->[1];
		}
	}
	$sth->finish;

	my $score = $up - $down;
	$score = undef if ( $up == 0 and $down == 0 );

	my $result;
	if ( ! defined $score ) {
		$result = "'$karma' has no karma";
	} else {
		if ( $score == 0 ) {
			$result = "'$karma' has neutral karma";
			if ( $self->extrastats ) {
				my $total = $up + $down;
				$result .= " [ $total votes ]";
			}
		} else {
			$result = "'$karma' has karma of $score";
			if ( $self->extrastats ) {
				if ( $up and $down ) {
					$result .= " [ $up ++ and $down -- votes ]";
				} elsif ( $up ) {
					$result .= " [ $up ++ votes ]";
				} else {
					$result .= " [ $down -- votes ]";
				}
			}
		}
	}

	return $result;
}

sub _add_karma {
	my( $self, %args ) = @_;

	# munge the nick back into original format
	$args{'who'} = $args{'nick'} . '!' . $args{'user'} . '@' . $args{'host'};

	# insert it into the DB!
	my $dbh = $self->_get_dbi;
	my $sth = $dbh->prepare_cached( 'INSERT INTO karma ( who, "where", timestamp, karma, mode, comment, said ) VALUES ( ?, ?, ?, ?, ?, ?, ? )' ) or die $dbh->errstr;
	$sth->execute(
		$args{'who'},
		$args{'where'},
		scalar time,
		$args{'karma'},
		( $args{'op'} eq '++' ? 1 : 0 ),
		$args{'comment'},
		$args{'str'},
	) or die $sth->errstr;
	$sth->finish;

	return;
}

sub _get_dbi {
	my $self = shift;

	my $dbh = DBI->connect_cached( "dbi:SQLite:dbname=" . $self->sqlite, '', '' );

	# set some SQLite tweaks
	$dbh->do( 'PRAGMA synchronous = OFF' ) or die $dbh->errstr;
	$dbh->do( 'PRAGMA locking_mode = EXCLUSIVE' ) or die $dbh->errstr;

	return $dbh;
}

sub _setup_dbi {
	my( $self, $dbh ) = @_;

	# create the table itself
	$dbh->do( 'CREATE TABLE IF NOT EXISTS karma ( ' .
		'who TEXT NOT NULL, ' .			# who made the karma
		'"where" TEXT NOT NULL, ' .		# privmsg or in chan
		'timestamp INTEGER NOT NULL, ' .	# unix timestamp of karma
		'karma TEXT NOT NULL, ' .		# the stuff being karma'd
		'mode BOOL NOT NULL, ' .		# 1 if it was a ++, 0 if it was a --
		'comment TEXT, ' .			# the comment given with the karma ( optional )
		'said TEXT NOT NULL ' .			# the full text the user said
	')' ) or die $dbh->errstr;

	# create the indexes to speed up searching
	$dbh->do( 'CREATE INDEX IF NOT EXISTS karma_karma ON karma ( karma )' ) or die $dbh->errstr;
	$dbh->do( 'CREATE INDEX IF NOT EXISTS karma_mode ON karma ( mode )' ) or die $dbh->errstr;

	return;
}

no Moose;
__PACKAGE__->meta->make_immutable;
1;


__END__
=pod

=for :stopwords Apocalypse cpan testmatrix url annocpan anno bugtracker rt cpants kwalitee
diff irc mailto metadata placeholders karma

=encoding utf-8

=for Pod::Coverage PCI_register PCI_unregister S_msg S_public S_ctcp_action

=head1 NAME

POE::Component::IRC::Plugin::Karma - A POE::Component::IRC plugin that keeps track of karma

=head1 VERSION

  This document describes v0.003 of POE::Component::IRC::Plugin::Karma - released April 15, 2011 as part of POE-Component-IRC-Plugin-Karma.

=head1 SYNOPSIS

	# A simple bot to showcase karma capabilities
	use strict; use warnings;

	use POE qw( Component::IRC Component::IRC::Plugin::Karma Component::IRC::Plugin::AutoJoin );

	# Create a new PoCo-IRC object
	my $irc = POE::Component::IRC->spawn(
		nick => 'karmabot',
		ircname => 'karmabot',
		server  => 'localhost',
	) or die "Oh noooo! $!";

	# Setup our plugins + tell the bot to connect!
	$irc->plugin_add( 'AutoJoin', POE::Component::IRC::Plugin::AutoJoin->new( Channels => [ '#test' ] ));
	$irc->plugin_add( 'Karma', POE::Component::IRC::Plugin::Karma->new( extrastats => 1 ) );
	$irc->yield( connect => { } );

	POE::Kernel->run;

=head1 DESCRIPTION

This plugin keeps track of karma ( perl++ or perl-- ) said on IRC and provides an interface to retrieve statistics.

The bot will watch for karma in channel messages, privmsgs and ctcp actions.

=head2 IRC USAGE

=over 4

=item *

thing++ # comment

Increases the karma for <thing> ( with optional comment )

=item *

thing-- # comment

Decreases the karma for <thing> ( with optional comment )

=item *

(a thing with spaces)++ # comment

Increases the karma for <a thing with spaces> ( with optional comment )

=item *

karma thing

Replies with the karma rating for <thing>

=item *

karma ( a thing with spaces )

Replies with the karma rating for <a thing with spaces>

=back

=head1 ATTRIBUTES

=head2 addressed

If this is a true value, the karma commands has to be sent to the bot.

	# addressed = true
	<you> bot: perl++

	# addressed = false
	<you> perl++

The default is: false

=head2 casesens

If this is a true value, karma checking will be done in a case-sensitive way.

The default is: false

=head2 privmsg

If this is a true value, all karma replies will be sent to the user in a privmsg.

The default is: false

=head2 selfkarma

If this is a true value, users are allowed to karma themselves.

The default is: false

=head2 replykarma

If this is a true value, this bot will reply to all karma additions with the current score.

The default is: false

=head2 extrastats

If this is a true value, this bot will display extra stats about the karma on reply.

The default is: false

=head2 sqlite

Set the path to the SQLite database which will hold the karma stats.

From the L<DBD::SQLite> docs: Although the database is stored in a single file, the directory containing the
database file must be writable by SQLite because the library will create several temporary files there.

The default is: karma_stats.db

BEWARE: In the future this might be changed to a more "fancy" system!

=head1 SEE ALSO

Please see those modules/websites for more information related to this module.

=over 4

=item *

L<POE::Component::IRC|POE::Component::IRC>

=item *

L<Bot::BasicBot::Pluggable::Module::Karma|Bot::BasicBot::Pluggable::Module::Karma>

=back

=head1 SUPPORT

=head2 Perldoc

You can find documentation for this module with the perldoc command.

  perldoc POE::Component::IRC::Plugin::Karma

=head2 Websites

The following websites have more information about this module, and may be of help to you. As always,
in addition to those websites please use your favorite search engine to discover more resources.

=over 4

=item *

Search CPAN

L<http://search.cpan.org/dist/POE-Component-IRC-Plugin-Karma>

=item *

RT: CPAN's Bug Tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=POE-Component-IRC-Plugin-Karma>

=item *

AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/POE-Component-IRC-Plugin-Karma>

=item *

CPAN Ratings

L<http://cpanratings.perl.org/d/POE-Component-IRC-Plugin-Karma>

=item *

CPAN Forum

L<http://cpanforum.com/dist/POE-Component-IRC-Plugin-Karma>

=item *

CPANTS Kwalitee

L<http://cpants.perl.org/dist/overview/POE-Component-IRC-Plugin-Karma>

=item *

CPAN Testers Results

L<http://cpantesters.org/distro/P/POE-Component-IRC-Plugin-Karma.html>

=item *

CPAN Testers Matrix

L<http://matrix.cpantesters.org/?dist=POE-Component-IRC-Plugin-Karma>

=back

=head2 Email

You can email the author of this module at C<APOCAL at cpan.org> asking for help with any problems you have.

=head2 Internet Relay Chat

You can get live help by using IRC ( Internet Relay Chat ). If you don't know what IRC is,
please read this excellent guide: L<http://en.wikipedia.org/wiki/Internet_Relay_Chat>. Please
be courteous and patient when talking to us, as we might be busy or sleeping! You can join
those networks/channels and get help:

=over 4

=item *

irc.perl.org

You can connect to the server at 'irc.perl.org' and join this channel: #perl-help then talk to this person for help: Apocalypse.

=item *

irc.freenode.net

You can connect to the server at 'irc.freenode.net' and join this channel: #perl then talk to this person for help: Apocal.

=item *

irc.efnet.org

You can connect to the server at 'irc.efnet.org' and join this channel: #perl then talk to this person for help: Ap0cal.

=back

=head2 Bugs / Feature Requests

Please report any bugs or feature requests by email to C<bug-poe-component-irc-plugin-karma at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=POE-Component-IRC-Plugin-Karma>. You will be automatically notified of any
progress on the request by the system.

=head2 Source Code

The code is open to the world, and available for you to hack on. Please feel free to browse it and play
with it, or whatever. If you want to contribute patches, please send me a diff or prod me to pull
from your repository :)

L<http://github.com/apocalypse/perl-pocoirc-karma>

  git clone git://github.com/apocalypse/perl-pocoirc-karma.git

=head1 AUTHOR

Apocalypse <APOCAL@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Apocalypse.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

The full text of the license can be found in the LICENSE file included with this distribution.

=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT
WHEN OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER
PARTIES PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND,
EITHER EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
PURPOSE. THE ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE
SOFTWARE IS WITH YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME
THE COST OF ALL NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE LIABLE
TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE THE
SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH
DAMAGES.

=cut

