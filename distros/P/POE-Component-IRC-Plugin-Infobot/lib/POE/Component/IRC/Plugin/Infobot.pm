package POE::Component::IRC::Plugin::Infobot;

use 5.014000;
use strict;
use warnings;
use re '/s';

our $VERSION = '0.001003';

use DB_File;

use IRC::Utils qw/parse_user/;
use POE::Component::IRC::Plugin qw/PCI_EAT_NONE/;

use constant +{ ## no critic (Capitalization)
	OK => [ 'sure, %s', 'ok, %s', 'gotcha, %s'],
	A_IS_B => [ '%s is %s', 'I think %s is %s', 'hmmm... %s is %s', 'it has been said that %s is %s', '%s is probably %s', 'rumour has it %s is %s', 'i heard %s was %s', 'somebody said %s is %s', 'i guess %s is %s', 'well, %s is %s', '%s is, like, %s', 'methinks %s is %s'],
	I_DONT_KNOW => [ 'I don\'t know, %s', 'Dunno, %s', 'No idea, %s', '%s: huh?', 'nem tudom, %s', 'anlamıyorum, %s', 'bilmiyorum, %s', 'nu ştiu d\'astea, %s', 'Je ne sais pas, %s', 'Я не знаю, %s'],
};

sub new { ## no critic (RequireArgUnpacking)
	my $class = shift;
	my $self = {
		filename => 'factoids.db',
		@_
	};

	my %db;
	$self->{dbobj} = tie %db, DB_File => $self->{filename} if defined $self->{filename}; ## no critic (ProhibitTie)
	$self->{db} = \%db;
	bless $self, $class
}

sub getstr {
	my $rstrings = shift;
	my @strings = @$rstrings;
	sprintf $strings[int rand $#strings], @_
}

sub infobot_add { ## no critic (ProhibitManyArgs)
	my ($self, $irc, $key, $value, $to, $nick) = @_;
	if (exists $self->{db}->{$key}) {
		$irc->yield(privmsg => $to => "I already had it that way, $nick") if $value eq $self->{db}->{$key};
		$irc->yield(privmsg => $to => "... but $key is $self->{db}->{$key}!") unless $value eq $self->{db}->{$key};
	} else {
		$self->{db}->{$key} = $value;
		$self->{dbobj}->sync if exists $self->{dbobj};
		$irc->yield(privmsg => $to => getstr OK, $nick);
	}
}

sub infobot_query { ## no critic (ProhibitManyArgs)
	my ($self, $irc, $key, $to, $nick, $addressed) = @_;
	if (exists $self->{db}->{$key}) {
		my @answers = split /\s+[|]\s+/, $self->{db}->{$key};
		local $_ = $answers[int rand $#answers];

		if (/^<action> (.+)$/i) {
			$irc->yield(ctcp => $to => "ACTION $1")
		} elsif (/^<reply> (.*)$/i) {
			$irc->yield(privmsg => $to => $1)
		} else {
			$irc->yield(privmsg => $to => getstr A_IS_B, $key, $_)
		}
	} elsif ($addressed) {
		$irc->yield(privmsg => $to => getstr I_DONT_KNOW, $nick)
	}
}

sub infobot_forget {
	my ($self, $irc, $key, $to, $nick) = @_;
	if (exists $self->{db}->{$key}) {
		delete $self->{db}->{$key};
		$self->{dbobj}->sync if exists $self->{dbobj};
		$irc->yield(privmsg => $to => "$nick: I forgot $key")
	} else {
		$irc->yield(privmsg => $to => "I didn't have anything matching $key, $nick")
	}
}

sub runcmd{  ## no critic (ProhibitManyArgs)
	my ($self, $irc, $to, $nick, $message, $addressed) = @_;

	local $_= $message;

	if (/^(.+)\s+is\s+(.*[^?])$/x) {
		infobot_add $self, $irc, $1, $2, $to, $nick if $addressed
	} elsif (/^(.+)[?]$/) {
		infobot_query $self, $irc, $1, $to, $nick, $addressed
	} elsif ($addressed && /^!?forget\s+(.*)$/ || /^!forget\s+(.*)$/) {
		infobot_forget $self, $irc, $1, $to, $nick
	}
}

sub PCI_register { ## no critic (Capitalization)
	my ($self, $irc) = @_;
	$irc->plugin_register($self, SERVER => qw/public msg/);
	1
}

sub PCI_unregister{ 1 } ## no critic (Capitalization)

sub S_public { ## no critic (Capitalization)
	my ($self, $irc, $rfullname, $rchannels, $rmessage) = @_;
	my $nick = parse_user $$rfullname;

	for my $channel (@$$rchannels) {
		local $_ = $$rmessage;

		my $addressed=0;
		my $mynick=$irc->nick_name;
		if (/^$mynick [,:]\s+/x) {
			$addressed=1;
			s/^$mynick [,:]\s+//x;
		}

		runcmd $self, $irc, $channel, $nick, $_, $addressed
	}

	PCI_EAT_NONE
}

sub S_msg{ ## no critic (Capitalization)
	my ($self, $irc, $rfullname, $rtargets, $rmessage) = @_;
	my $nick = parse_user $$rfullname;

	runcmd $self, $irc, $nick, $nick, $$rmessage, 1;

	PCI_EAT_NONE
}

1;
__END__

=encoding utf-8

=head1 NAME

POE::Component::IRC::Plugin::Infobot - Add infobot features to an PoCo-IRC

=head1 SYNOPSIS

  use POE::Component::IRC::Plugin::Infobot;
  $irc->plugin_add(Infobot => POE::Component::Plugin::Infobot->new(filename => '/tmp/stuff.db'))

=head1 DESCRIPTION

POE::Component::IRC::Plugin::Infobot is a PoCo-IRC plugin that makes a PoCo-IRC behave like a simple infobot.

It stores factoids in a DB_File database and lets IRC users add, remove and retreive factoids.

The constructor takes one optional argument, I<filename>, the path to the factoids database. It is 'factoids.db' by default.

=head1 IRC COMMANDS

=over

=item B<add>

Any message of the form "X is Y" which is addressed to the bot or sent in private is an add command. This will not overwrite a previous factoid with the same key.

Example session:

  < mgv> bot: IRC is Internet Relay Chat
  <+bot> OK, mgv
  < mgv> bot: IRC is Internet Relay Chat
  <+bot> I already had it that way, mgv
  < mgv> bot: IRC is Internally-Routed Communication
  <+bot> ... but IRC is Internet Relay Chat!
  < mgv> bot: x is <reply> y!
  <+bot> sure, mgv
  < mgv> bot: whistle is <action> whistles
  <+bot>

=item B<forget>

Any message of the form "forget X" which is addressed to the bot or sent in private is a forget command. This command will erase any previous factoid with this key.

Example session:

  < mgv> bot: forget IRC
  <+bot> mgv: I forgot IRC
  < mgv> bot: forget IRC
  <+bot> I didn't have anything matching IRC, mgv

=item B<query>

Any message ending in a question mark is a query command. If a factoid with that key is found, the plugin will respond. If no such factoid is found AND the message is either addressed to the bot or sent in private, the bot will say that it doesn't know the answer to the question.

If the factoid starts with C<< <reply> >>, everything after the C<< <reply> >> is sent. If it starts with C<< <action> >>, it is sent as a CTCP ACTION. Otherwise, a message of the form C<factoid_key is factoid_value> is sent.

Example session:

  < mgv> IRC?
  <+bot> methinks IRC is Internet Relay Chat
  < mgv> ASD?
  < mgv> bot: ASD?
  <+bot> Dunno, mgv
  < mgv> x?
  <+bot> y!
  < mgv> whistle?
  * bot whistles

=back

=head1 SEE ALSO

L<POE::Component::IRC::Plugin>, L<http://infobot.sourceforge.net/>

=head1 AUTHOR

Marius Gavrilescu, E<lt>marius@ieval.roE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2013-2015 by Marius Gavrilescu

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.14.2 or,
at your option, any later version of Perl 5 you may have available.


=cut
