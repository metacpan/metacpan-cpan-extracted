package POE::Component::IRC::Plugin::Logger::Irssi;

our $VERSION = '0.001002';

use 5.014000;
use strict;
use warnings;

use parent qw/Exporter/;

our @EXPORT_OK = qw/irssi_format/;

##################################################

my %irssi_format = (
	nick_change => sub { "-!- $_[0] is now known as $_[1]" },
	topic_is => sub { "-!- Topic for $_[0]: $_[1]"},
	topic_change => sub {
		my ($nick, $topic) = @_;
		return "-!- $nick changed the topic to: $topic" if $topic;
		return "-!- Topic unset by $nick" unless $topic;
	},
	privmsg => sub{ "<$_[0]> $_[1]" },
	notice => sub { "-$_[0]- $_[1]" },
	action => sub { "* $_[0] $_[1]" },
	join => sub { "-!- $_[0] [$_[1]] has joined $_[2]" },
	part => sub { "-!- $_[0] [$_[1]] has left $_[2] [$_[3]]" },
	quit => sub { "-!- $_[0] [$_[1]] has quit [$_[2]]"},
	kick => sub { "-!- $_[1] was kicked from $_[2] by $_[0] [$_[3]]"},
	topic_set_by => sub { "-!- Topic set by $_[1] [". localtime($_[2]) .']' },
);

for my $letter ('a' .. 'z', 'A' .. 'Z') {
	$irssi_format{"+$letter"} = sub { my $nick = shift; "-!- mode [+$letter @_] by $nick" };
	$irssi_format{"-$letter"} = sub { my $nick = shift; "-!- mode [-$letter @_] by $nick" }
}

sub irssi_format { \%irssi_format }

1;
__END__

=encoding utf-8

=head1 NAME

POE::Component::IRC::Plugin::Logger::Irssi - Log IRC events like irssi

=head1 SYNOPSIS

  use POE::Component::IRC::Plugin::Logger::Irssi qw/irssi_format/;
  ...
  $irc->plugin_add(Logger => POE::Component::IRC::Plugin::Logger->new(
    Format => irssi_format,
    ...
  ));

=head1 DESCRIPTION

POE::Component::IRC::Plugin::Logger::Irssi is an extension to the L<POE::Component::IRC::Plugin::Logger> PoCo-IRC plugin that logs everything in a format similar to the one used by the irssi IRC client.

It exports one function, B<irssi_format>, that returns a hashref to be used as the value to C<< POE::Component::IRC::Plugin::Logger->new >>'s C<format> argument.

=head1 AUTHOR

Marius Gavrilescu C<< <marius@ieval.ro> >>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2013 by Marius Gavrilescu

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.14.2 or,
at your option, any later version of Perl 5 you may have available.


=cut
