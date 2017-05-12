package POE::Component::IRC::Plugin::Seen;

our $VERSION = 0.001002;

use v5.14;
use strict;
use warnings;

use DB_File;

use IRC::Utils qw/lc_irc parse_user/;
use POE::Component::IRC::Plugin qw/PCI_EAT_NONE PCI_EAT_PLUGIN/;

##################################################

sub new{
	my $class = shift;
	my $self = { @_ };

	$self->{dbobj} = tie my %db, DB_File => $self->{filename};
	$self->{db} = \%db;
	bless $self, $class
}

sub log_event {
	my ($self, $nick, $event) = @_;
	my $time = localtime;
	$self->{db}->{$nick} = "$time $event";
	$self->{dbobj}->sync;
	PCI_EAT_NONE
}

sub seen {
	my ($self, $irc, $nick, $to, $from) = @_;
	if (exists $self->{db}->{$nick}) {
		$irc->yield(privmsg => $to => "I last saw $nick $self->{db}->{$nick}")
	} else {
		$irc->yield(privmsg => $to => "I haven't seen $nick")
	}
	PCI_EAT_PLUGIN
}

sub PCI_register {
	my ($self, $irc) = @_;
	$irc->plugin_register($self, SERVER => qw/ctcp_action join part public msg/);
	1
}

sub PCI_unregister { 1 }

sub S_ctcp_action {
	my ($self, $irc, $rfullname, $rchannels, $rmessage) = @_;
	my $nick = parse_user $$rfullname;

	log_event $self, $nick => "on $$rchannels->[0] doing: * $$rmessage"
}

sub S_public {
	my ($self, $irc, $rfullname, $rchannels, $rmessage) = @_;
	my $nick = parse_user $$rfullname;
	my $mynick = $irc->nick_name;

	seen $self, $irc, $1, $$rchannels->[0], $nick if $$rmessage =~ /^(?:$mynick [,:])?\s*!?seen\s+([^ ]+)/x;
	log_event $self, $nick => "on $$rchannels->[0] saying $$rmessage"
}

sub S_join {
	my ($self, $irc, $rfullname, $rchannel) = @_;
	my $nick = parse_user $$rfullname;

	log_event $self, $nick => "joining $$rchannel"
}

sub S_part {
	my ($self, $irc, $rfullname, $rchannel, $rmessage) = @_;
	my $nick = parse_user $$rfullname;
	my $msg = $$rmessage ? " with message '$$rmessage'" : '';

	log_event $self, $nick => "parting $$rchannel$msg"
}

sub S_msg {
	my ($self, $irc, $rfullname, $rtargets, $rmessage) = @_;
	my $nick = parse_user $$rfullname;

	seen $self, $irc, $1, $$rtargets->[0], $nick if $$rmessage =~ /^\s*!?seen\s+([^ ]+)/
}

1;
__END__

=head1 NAME

POE::Component::IRC::Plugin::Seen - PoCo-IRC plugin that remembers seeing people

=head1 SYNOPSIS

  use POE::Component::IRC::Plugin::Seen;

  my $irc = POE::Component::IRC->spawn;
  $irc->plugin_add(Seen => POE::Component::IRC::Plugin::Seen->new(filename => 'mycache.db'));

  # In chat
  # <mgv> Hi there!
  # <foo> !seen mgv
  # <bot> I last saw mgv [DATE] on channel #whatever saying Hi there!

=head1 DESCRIPTION

POE::Component::IRC::Plugin::Seen is a PoCo-IRC plugin that remembers
what each person around it did last. It remembers public messages,
joins and parts.

When somebody sends him a private message of the form 'seen NICKNAME'
or somebody says 'seen NICKNAME' or 'botnick: seen NICKNAME' in a
channel with the bot, the plugin answers with the last action NICKNAME
did. There can be an exclamation mark before the word 'seen'.

=head1 METHODS

=over

=item B<new>([I<filename> => value])

Creates a new plugin object suitable for L<POE::Component::IRC>'s
C<plugin_add> method.

Takes one optional argument, C<filename>, the name of the file to
store the plugin's state in. If C<undef> or not given, it keeps the
state in memory.

=back

=head1 SEE ALSO

L<POE::Component::IRC::Plugin>

=head1 AUTHOR

Marius Gavrilescu C<< <marius@ieval.ro> >>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2013-2015 by Marius Gavrilescu

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.14.2 or,
at your option, any later version of Perl 5 you may have available.


=cut
