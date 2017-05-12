use strict;
use warnings;
package Parse::IRCLog;
# ABSTRACT: parse internet relay chat logs
$Parse::IRCLog::VERSION = '1.106';
use Carp ();
use Parse::IRCLog::Result;
use Symbol ();

# =head1 SYNOPSIS
#
#   use Parse::IRCLog;
#
#   $result = Parse::IRCLog->parse("perl-2004-02-01.log");
#
#   my %to_print = ( msg => 1, action => 1 );
#
#   for ($result->events) {
#     next unless $to_print{ $_->{type} };
#     print "$_->{nick}: $_->{text}\n";
#   }
#
# =head1 DESCRIPTION
#
# This module provides a simple framework to parse IRC logs in arbitrary formats.
#
# A parser has a set of regular expressions for matching different events that
# occur in an IRC log, such as "msg" and "action" events.  Each line in the log
# is matched against these rules and a result object, representing the event
# stream, is returned.
#
# The rule set, described in greated detail below, can be customized by
# subclassing Parse::IRCLog.  In this way, Parse::IRCLog can provide a generic
# interface for log analysis across many log formats, including custom formats.
#
# Normally, the C<parse> method is used to create a result set without storing a
# parser object, but a parser may be created and reused.
#
# =method new
#
# This method constructs a new parser (with C<< $class->construct >>) and
# initializes it (with C<< $obj->init >>).  Construction and initialization are
# separated for ease of subclassing initialization for future pipe dreams like
# guessing what ruleset to use.
#
# =cut

sub new {
  my $class = shift;
  Carp::croak "new is a class method" if ref $class;

  $class->construct->init;
}

# =method construct
#
# The parser constructor just returns a new, empty parser object.  It should be a
# blessed hashref.
#
# =cut

sub construct { bless {} => shift; }

# =method init
#
# The initialization method configures the object, loading its ruleset.
#
# =cut

sub init {
  my $self = shift;
  $self->{patterns} = $self->patterns;
  $self;
}

# =method patterns
#
# This method returns a reference to a hash of regular expressions, which are
# used to parse the logs.  Only a few, so far, are required by the parser,
# although internally a few more are used to break down the task of parsing
# lines.
#
# C<action> matches an action; that is, the result of /ME in IRC.  It should
# return the following matches:
#
#  $1 - timestamp
#  $2 - nick prefix
#  $3 - nick
#  $4 - the action
#
# C<msg> matches a message; that is, the result of /MSG (or "normal talking") in
# IRC.  It should return the following matches:
#
#  $1 - timestamp
#  $2 - nick prefix
#  $3 - nick
#  $3 - channel
#  $5 - the action
#
# Read the source for a better idea as to how these regexps break down.  Oh, and
# for what it's worth, the default patterns are based on my boring, default irssi
# configuration.  Expect more rulesets to be included in future distributions.
#
# =cut

sub patterns {
  my ($self) = @_;

  return $self->{patterns} if ref $self and defined $self->{patterns};

  my $p;

  # nick and chan are (mostly) specified in RFC2812, section 2.3.1

  my $letter  = qr/[\x41-\x5A\x61-\x7A]/;   # A-Z / a-z
  my $digit   = qr/[\x30-\x39]/;            # 0-9
  my $special = qr/[\x5B-\x60\x7B-\x7D]/;   # [\]^_`{|}

  $p->{nick} = qr/( (?: $letter | $special )
                    (?: $letter | $digit | $special | - )* )/x;

  my $channelid = qr/[A-Z0-9]{5}/;
  my $chanstring = qr/[^\x00\a\r\n ,:]*/;

  $p->{chan} = qr/( (?: \# | \+ | !$channelid | & ) $chanstring
                    (?: :$chanstring )? )/x;

  # the other regexes are more relevant to the way irssi formats logs

  $p->{nick_container} = qr/
  <
    \s*
    ([+%@])?
    \s*
    $p->{nick}
    (?:
      :
      $p->{chan}
    )?
    \s*
  >
  /x;

  $p->{timestamp} = qr/\[?(\d\d:\d\d(?::\d\d)?)?\]?/;

  $p->{action_leader} = qr/\*/;

  $p->{msg} = qr/
    $p->{timestamp}
    \s*
    $p->{nick_container}
    \s+
    (.+)
  /x;

  $p->{action} = qr/
    $p->{timestamp}
    \s*
    $p->{action_leader}
    \s+
    ([%@])?
    \s*
    $p->{nick}
    \s
    (.+)
  /x;

  $self->{patterns} = $p if ref $self;
  $p;
}

# =method parse
#
#   my $result = $parser->parse($file)
#
# This method parses the file named and returns a Parse::IRCLog::Result object
# representing the results.  The C<parse> method can be called on a parser object
# or on the class.  If called on the class, a parser will be instantiated for the
# method call and discarded when C<parse> returns.
#
# =cut

sub parse {
  my $self = shift;
  $self = $self->new unless ref $self;

  my $symbol = Symbol::gensym;
  open $symbol, "<", $_[0] or Carp::croak "couldn't open $_[0]: $!";

  my @events;
  push @events, $self->parse_line($_) while (<$symbol>);
  Parse::IRCLog::Result->new(@events);
}

# =method parse_line
#
#   my $info = $parser->parse_line($line);
#
# This method is used internally by C<parse> to turn each line into an event.
# While it could someday be made slick, it's adequate for now.  It attempts to
# match each line against the required patterns from the C<patterns> result and
# if successful returns a hashref describing the event.
#
# If no match can be found, an "unknown" event is returned.
#
# =cut

sub parse_line {
  my ($self, $line) = @_;
  if ($line) {
    return { type => 'msg',    timestamp => $1, nick_prefix => $2, nick => $3, text => $5 }
      if $line =~ $self->patterns->{msg};
    return { type => 'action', timestamp => $1, nick_prefix => $2, nick => $3, text => $4 }
      if $line =~ $self->patterns->{action};
  }
  return { type => 'unknown', text => $line };
}

# =head1 TODO
#
# Write a few example subclasses for common log formats.
#
# Add a few more default event types: join, part, nick.  Others?
#
# Possibly make the C<patterns> sub an module, to allow subclassing to override
# only one or two patterns.  For example, to use the default C<nick> pattern but
# override the C<nick_container> or C<action_leader>.  This sounds like a very
# good idea, actually, now that I write it down.
#
# =cut

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Parse::IRCLog - parse internet relay chat logs

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

This module provides a simple framework to parse IRC logs in arbitrary formats.

A parser has a set of regular expressions for matching different events that
occur in an IRC log, such as "msg" and "action" events.  Each line in the log
is matched against these rules and a result object, representing the event
stream, is returned.

The rule set, described in greated detail below, can be customized by
subclassing Parse::IRCLog.  In this way, Parse::IRCLog can provide a generic
interface for log analysis across many log formats, including custom formats.

Normally, the C<parse> method is used to create a result set without storing a
parser object, but a parser may be created and reused.

=head1 METHODS

=head2 new

This method constructs a new parser (with C<< $class->construct >>) and
initializes it (with C<< $obj->init >>).  Construction and initialization are
separated for ease of subclassing initialization for future pipe dreams like
guessing what ruleset to use.

=head2 construct

The parser constructor just returns a new, empty parser object.  It should be a
blessed hashref.

=head2 init

The initialization method configures the object, loading its ruleset.

=head2 patterns

This method returns a reference to a hash of regular expressions, which are
used to parse the logs.  Only a few, so far, are required by the parser,
although internally a few more are used to break down the task of parsing
lines.

C<action> matches an action; that is, the result of /ME in IRC.  It should
return the following matches:

 $1 - timestamp
 $2 - nick prefix
 $3 - nick
 $4 - the action

C<msg> matches a message; that is, the result of /MSG (or "normal talking") in
IRC.  It should return the following matches:

 $1 - timestamp
 $2 - nick prefix
 $3 - nick
 $3 - channel
 $5 - the action

Read the source for a better idea as to how these regexps break down.  Oh, and
for what it's worth, the default patterns are based on my boring, default irssi
configuration.  Expect more rulesets to be included in future distributions.

=head2 parse

  my $result = $parser->parse($file)

This method parses the file named and returns a Parse::IRCLog::Result object
representing the results.  The C<parse> method can be called on a parser object
or on the class.  If called on the class, a parser will be instantiated for the
method call and discarded when C<parse> returns.

=head2 parse_line

  my $info = $parser->parse_line($line);

This method is used internally by C<parse> to turn each line into an event.
While it could someday be made slick, it's adequate for now.  It attempts to
match each line against the required patterns from the C<patterns> result and
if successful returns a hashref describing the event.

If no match can be found, an "unknown" event is returned.

=head1 TODO

Write a few example subclasses for common log formats.

Add a few more default event types: join, part, nick.  Others?

Possibly make the C<patterns> sub an module, to allow subclassing to override
only one or two patterns.  For example, to use the default C<nick> pattern but
override the C<nick_container> or C<action_leader>.  This sounds like a very
good idea, actually, now that I write it down.

=head1 AUTHOR

Ricardo SIGNES <rjbs@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2004 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
