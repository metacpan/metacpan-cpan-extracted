use strict;
use warnings;
package Parse::IRCLog::Result;
# ABSTRACT: results of parsing an IRC logfile
$Parse::IRCLog::Result::VERSION = '1.106';
# =head1 SYNOPSIS
#
# 	use Parse::IRCLog;
#
# 	$result = Parse::IRCLog->parse("perl-2004-02-01.log");
#
# 	my %to_print = ( msg => 1, action => 1 );
#
# 	for ($result->events) {
# 		next unless $to_print{ $_->{type} };
# 		print "$_->{nick}: $_->{text}\n";
# 	}
#
# =head1 DESCRIPTION
#
# See L<Parse::IRCLog>.  This module describes the result of parsing.
#
# =method new
#
#   my $result = $class->new(@events);
#
# This method is not user-serviceable.  It is called by Parse::IRCLog to create
# the Result object.
#
# =cut

sub new {
  my $class = shift;
	my @events = @_;
  return if ref $class;
	return unless @events;

  bless { events => \@events } => $class;
}

# =method events
#
# This method returns the list of events in the result set.
#
# =cut

sub events {
  my $self = shift;
  @{$self->{events}};
}

# =head1 TODO
#
# Provide iterator functionality.  Five minutes of looking didn't find a mixin
# class for iterators, so I might end up just delegating iterator methods to a
# tied array object or something.  This can wait.
#
# =cut

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Parse::IRCLog::Result - results of parsing an IRC logfile

=head1 VERSION

version 1.106

=head1 SYNOPSIS

	use Parse::IRCLog;

	$result = Parse::IRCLog->parse("perl-2004-02-01.log");

	my %to_print = ( msg => 1, action => 1 );

	for ($result->events) {
		next unless $to_print{ $_->{type} };
		print "$_->{nick}: $_->{text}\n";
	}

=head1 DESCRIPTION

See L<Parse::IRCLog>.  This module describes the result of parsing.

=head1 METHODS

=head2 new

  my $result = $class->new(@events);

This method is not user-serviceable.  It is called by Parse::IRCLog to create
the Result object.

=head2 events

This method returns the list of events in the result set.

=head1 TODO

Provide iterator functionality.  Five minutes of looking didn't find a mixin
class for iterators, so I might end up just delegating iterator methods to a
tied array object or something.  This can wait.

=head1 AUTHOR

Ricardo SIGNES <rjbs@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2004 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
