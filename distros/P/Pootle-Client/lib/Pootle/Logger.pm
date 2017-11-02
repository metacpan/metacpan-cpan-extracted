# Copyright (C) 2017 Koha-Suomi
#
# This file is part of Pootle-Client.

package Pootle::Logger;

use Modern::Perl '2015';
use utf8;
binmode STDOUT, ':encoding(UTF-8)';
binmode STDERR, ':encoding(UTF-8)';
use feature 'signatures'; no warnings "experimental::signatures";
use Carp::Always;
use Try::Tiny;
use Scalar::Util qw(blessed);
use Data::Dumper;

=head2 Pootle::Logger

Wrapper for the awesome Log::Log4perl

=head2 Synopsis

    $ENV{POOTLE_CLIENT_VERBOSITY} = 'DEBUG'; #Set the log verbosity using Log::Log4perl log levels

    use Pootle::Logger;
    my $l = bless({}, 'Pootle::Logger'); #Lazy load package logger this way to avoid circular dependency issues with logger includes from many packages

    sub faraway {
        $l->debug("Debugging params: "$l->flatten(@_)) if $l->is_debug();
    }

$l->isa('Log::Log4perl') logger. Have fun!

=cut

use Log::Log4perl;
our @ISA = qw(Log::Log4perl);
Log::Log4perl->wrapper_register(__PACKAGE__);

my $environmentAdjustmentDone; #Adjust all appenders only once

sub AUTOLOAD {
  my $l = shift(@_);
  my $method = our $AUTOLOAD;
  $method =~ s/.*://;
  unless (blessed($l)) {
    die __PACKAGE__." invoked with an unblessed reference??";
  }
  unless ($l->{_log}) {
    $l->{_log} = get_logger($l);
  }
  return $l->{_log}->$method(@_);
}

sub get_logger {
  initLogger() unless Log::Log4perl->initialized();
  my $l = Log::Log4perl->get_logger();
  return $l;
}

sub initLogger {
  Log::Log4perl->easy_init({
    level => _levelToLog4perlLevelInt($ENV{POOTLE_CLIENT_VERBOSITY} || 'WARN'),
    utf8 => 1,
    layout   => '[%d{HH:mm:ss}] %p %M(): %m%n',
  });
}

=head2 _levelToLog4perlLevelInt

There is a bug in Log4perl, where loading
    use Log::Log4perl qw(:easy);
to namespace in this file causes
    Deep recursion on subroutine "Log::Log4perl::get_logger" at /usr/share/perl5/Log/Log4perl.pm line 339, <FH> line 92.

Work around by not importing log levels, and manually duplicating them here.
see /usr/share/perl5/Log/Log4perl/Level.pm for level integers

=cut

sub _levelToLog4perlLevelInt($level) {
  return 0             if $level =~ /ALL/i;
  return 5000          if $level =~ /TRACE/i;
  return 10000         if $level =~ /DEBUG/i;
  return 20000         if $level =~ /INFO/i;
  return 30000         if $level =~ /WARN/i;
  return 40000         if $level =~ /ERROR/i;
  return 50000         if $level =~ /FATAL/i;
  return (2 ** 31) - 1 if $level =~ /OFF/i;  #presumably INT MAX
  die "_levelToLog4perlLevelInt():> Unknown log level POOTLE_CLIENT_VERBOSITY=$level";
}

=head2 flatten

    my $string = $logger->flatten(@_);

Given a bunch of $@%, the subroutine flattens those objects to a single human-readable string.

 @PARAMS Anything, concatenates parameters to one flat string
 @RETURNS String, params flattened

=cut

sub flatten {
  my $self = shift;
  die __PACKAGE__."->flatten() invoked improperly. Invoke it with \$logger->flatten(\@params)" unless ((blessed($self) && $self->isa(__PACKAGE__)) || ($self eq __PACKAGE__));

  return Data::Dumper->new([@_],[])->Terse(1)->Indent(1)->Varname('')->Maxdepth(0)->Sortkeys(1)->Quotekeys(1)->Dump();
}

1;
