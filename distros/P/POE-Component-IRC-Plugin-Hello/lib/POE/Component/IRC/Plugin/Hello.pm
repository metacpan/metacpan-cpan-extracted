package POE::Component::IRC::Plugin::Hello;

use 5.014000;
use strict;
use warnings;
use utf8;
use Encode qw/encode decode/;
use Unicode::Normalize qw/NFC/;

our $VERSION = '0.001004';

use List::Util qw/first/;

use IRC::Utils qw/parse_user/;
use POE::Component::IRC::Plugin qw/PCI_EAT_NONE/;

sub new {
	my $class = shift;
	my $self = {
		greetings => [
			qw/privet hello salut salutari neata neaţa neața neatza
			   hola hey hi bonjour wassup sup hallo chikmaa
			   tungjatjeta parev salam namaskaar mingalarba ahoy
			   saluton allo moin aloha namaste shalom ciào ciao servus
			   salve ave merhaba witaj hei hola selam sawubona
			   goedemorgen mogge hoi καλημέρα/,
			'what\'s up', 'que tal', 'こんにちは', '你好', 'ni hao',
			'добро јутро', 'γεια σας', 'bom dia', 'hyvää huomenta'],
		@_
	};

	bless $self, $class
}

sub PCI_register {
	my ($self, $irc) = @_;
	$irc->plugin_register($self, SERVER => qw/public/);
	1
}

sub PCI_unregister { 1 }

sub S_public{
	my ($self, $irc, $rfullname, $rchannels, $rmessage) = @_;
	my $nick = parse_user $$rfullname;
	my $mynick = $irc->nick_name;
	my $message = NFC decode 'UTF-8', $$rmessage;
	my @hello = @{$self->{greetings}};

	my $match = first { $message =~ /^\s*(?:$mynick(?:)[:,])?\s*$_\s*[.!]?\s*$/is } @hello;
	my $randhello = encode 'UTF-8', $hello[int rand $#hello];
	$irc->yield(privmsg => $$rchannels->[0] => "$randhello, $nick") if $match;
	PCI_EAT_NONE
}

1;
__END__

=head1 NAME

POE::Component::IRC::Plugin::Hello - PoCo-IRC plugin that says hello

=head1 SYNOPSIS

  use POE::Component::IRC::Plugin::Hello;

  my $irc = POE::Component::IRC::State->spawn(...);
  $irc->plugin_add(Hello => POE::Component::IRC::Plugin::Hello->new);

=head1 DESCRIPTION

POE::Component::IRC::Plugin::Hello is a PoCo-IRC plugin that greets back
who greet him or a channel in public. It knows how to say hello in several
languages, and greets people in a randomly chosen language.

The list of greetings is configurable by the plugin user.

=head1 SEE ALSO

L<POE::Component::IRC::Plugin>

=head1 AUTHOR

Marius Gavrilescu, E<lt>marius@ieval.roE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2013-2017 by Marius Gavrilescu

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.14.2 or,
at your option, any later version of Perl 5 you may have available.


=cut
