=head1 NAME

Package::Base::Devel - Perl extension for blah blah blah

=head1 SYNOPSIS


  #don't use this module directly, but rather inherit from it.
  package My::Package;
  use base qw(Package::Base::Devel);

  #... see Package::Base for details on the new() and init() methods
  #that are inherited by Package::Base::Devel.

  #it isn't necessary to use new() or init() in your class hierarchy,
  #Package::Base::Devel is smart enough to initialize itself the first
  #time you call an inherited method.

=head1 DESCRIPTION

Provides the the same base functionality as Package::Base, but
additionally provides automatic setup of Log::Log4perl loggging.

=head1 TRAPPED SIGNALS: warn() AND die().

Package::Base::Devel traps $SIG{__WARN__} and $SIG{__DIE__}.  This is
so we can log warn() and die() calls and what package they come from.  After
trapping the signal the default warn() and die() methods (CORE::warn() and
CORE::die(), respectively) are called.

This signal trapping may not play nicely with other modules that also alter
Perl's default exception handling behaviour.  If you find this to be the
case, please let me know, I do not use and have not tested against these
other modules.  If there is a way to detect signal handling clashes, please
also let me know and I will modify this module appropriately.

=head1 CUSTOMIZED LOGGING

When the first instance of a class inheriting from Package::Base::Devel
is instantiated, a Log::Log4perl::Logger is created.  This uses a call
to Log::Log4perl->init() for initialization of the logging object.  The
default Log::Log4perl configuration template used for this by
Package::Base::Devel is:

  log4perl.logger.%s   = DEBUG, %s
  log4perl.appender.%s = Log::Log4perl::Appender::Screen
  log4perl.appender.%s.stdout = 0
  log4perl.appender.%s.stderr = 1
  log4perl.appender.%s.layout = Log::Log4perl::Layout::PatternLayout
  log4perl.appender.%s.layout.ConversionPattern =[%%d{HH:mm:ss}] %%-5p - %%-30c %%40M() in file .../%%F{2} (%%4L): %%m%%n

A few comments on the above configuration stanza:

* Notice there are B<several> (seven) %s strings.  If you guessed that this
stanza is interpreted using an sprintf() call, you are right.  The %s are
replaced by a mangled version of the namespace of the package for which logging
is being set up.

* Notice the word DEBUG.  This is the default logging level for any
class set up with this template.  See L</loglevel()> for a listing of valid
strings here.

* This string can have as many %s slots as you like, so you have great flexibility
as to how you want to set up your configuration stanza.  This string must contain at
B<at least two> %s, as it is the minimum necessary for a valid configuration stanza.

To customize the default configuration stanza, just update
$Package::Base::Devel::log4perl_template to something else recognizable by
Log::Log4perl.

B<Caveat>: Any time this string is changed I<before> the first instantiation
of a class inheriting from Package::Base::Devel, the instantiation event will
cause a full reinitialization of Log::Log4perl using this template for all
classes.  Therefore it is recommended you set this template once in package main,
startup.pl if you're using mod_perl, or in some other high-level package.  This
will prevent multiple reinitializations of the loggers, and potentially unintended
results.  Consider the following code:

  package main;
  use My::Class::A; #which inherits from Package::Base::Devel
  use My::Class::B; #also inherits...

  my $a = My::Class::A->new(some => 'args');

  $Package::Base::Devel::log4perl_template = "this is an invalid log4perl stanza";

  $a->log->info('this info STILL goes to the logger with the default config, no problem');

  my $b = My::Class::B->new(some => 'args');
  #the loggers were reinitialized with the updated template.
  $b->log->info('this message fails');
  $a->log->info('this message also fails');

The main thing you're likely to want to change at runtime is the log level.  See
L</loglevel()> or L<Log::Log4perl> to learn about log levels.  To accomodate this,
Package::Base::Devel provides the L</loglevel()> shortcut function that allows calls like:

  my $a1 = My::Class::A->new();
  my $a2 = My::Class::A->new();

  $a1->log->debug('debugging message'); #goes to log, DEBUG is the default log level, remember?
  $a2->log->debug('this goes through to the logger also');

  $a1->loglevel('FATAL'); #only show fatal messages
  $a1->log->debug('this does not go through, log level too high');
  $a2->log->debug('calls from $a2 are now also blocked, '.
                  'as the logger is effectively a class instance');

=head1 AUTHOR

Allen Day, E<lt>allenday@ucla.eduE<gt>

=head1 SEE ALSO

L<Package::Base>.

=cut

package Package::Base::Devel;

use strict;
use base qw(Package::Base);
use Data::Dumper;
use Log::Log4perl qw(get_logger);
use Log::Log4perl::Level;
use Carp qw(cluck);

our $VERSION = '0.01';

#trap signals
$SIG{__DIE__}  = \&_die;
$SIG{__WARN__} = \&_warn;

our %logconfig = (''=>'');
our %black = map {$_=>1} qw(
                            Carp
                            ExtUtils::MakeMaker
                            Log::Log4perl::Logger
                            Package::Install
                           ); #don't trap signals from these

our %level = ( #these scalars are exported by Log::Log4perl::Level
              OFF   => $OFF,
              FATAL => $FATAL,
              ERROR => $ERROR,
              WARN  => $WARN,
              INFO  => $INFO,
              DEBUG => $DEBUG,
              ALL   => $ALL,
             );

our $log4perl_template = <<_HERE_;
log4perl.logger.%s   = DEBUG, %s
log4perl.appender.%s = Log::Log4perl::Appender::Screen
log4perl.appender.%s.stdout = 0
log4perl.appender.%s.stderr = 1
log4perl.appender.%s.layout = Log::Log4perl::Layout::PatternLayout
log4perl.appender.%s.layout.ConversionPattern =[%%d{HH:mm:ss}] %%-5p - %%-30c %%40M() in file .../%%F{2} (%%4L): %%m%%n
_HERE_

=head1 METHODS

=head2 new()

Identical functionality to Package::Base::new().

=cut

sub new {
  my($class,%arg) = @_;

  if($class eq __PACKAGE__){
    cluck( __PACKAGE__." is an abstract base class, and not directly instantiable" );
    return undef;
  }

  my $self = $class->SUPER::new(%arg);
  #superclass calls init() for us
  return $self;
}

=head2 is_initialized()

 Usage   : $boolean = $object->is_initialized();
 Returns : true or false
 Args    : none
 Function: check to see if init() has been called or not.

=cut

sub is_initialized {
  return shift->{'__PackageBaseDevel_init'};
}

=head2 init()

 Usage   : $object->init(key1 => 'value1', key2 => 'value2');
 Returns : a reference to the calling object
 Args    : an anonymous hash of object attribute/value pairs.
 Function: uses anonymous hash parameters to initialize object just as
           Package::Base.  See Package::Base::init() for details.

           Additionally sets up a Log::Log4perl configuration and logger
           instance for the object's class (ref($object)) if a Log::Log4perl
           configuration does not already exist.  The Log::Log4perl
           configuration template is customizable by setting
           $Package::Base::Devel::log4perl_template, See L</CUSTOMIZED LOGGING>.

=cut

sub init {
  my($self,%arg) = @_;
  $self->{'__PackageBaseDevel_init'} = 1;

  $self->SUPER::init(%arg);

  {
    my $tmp1 = $Data::Dumper::Maxdepth;
    my $tmp2 = $Data::Dumper::Terse;
    $Data::Dumper::Maxdepth = 2;
    $Data::Dumper::Indent   = 1;
    my $dump = join "\n", grep {$_ if $_ !~ /[\{\}]/} split("\n",Data::Dumper::Dumper(\%arg));
    my $argstring = keys(%arg) ? ".  shallow dump:\n".$dump : '.';
    $self->log->info("constructed a new ".ref($self)." object".$argstring);
    $Data::Dumper::Maxdepth = $tmp1;
    $Data::Dumper::Terse = $tmp2;
  }


#  $self->log();
  return $self;
}

=head2 log()

 Usage   : $object->log->debug('some debugging message');
           $object->log->info('some info');
           $object->log->warn('something bad happened');
           $object->log->fatal('something really bad happened');
 Returns : a Log::Log4perl::Logger instance
 Args    : none
 Function: This gives access to the $object's logging instance.
           L<Log::Log4perl> for more details.  See L</CUSTOMIZED LOGGING>
           for additional info on how to affect logging behavior
           for your subclass.

=cut

sub log {
  my($self) = @_;
  $self->init() if ref($self) && !$self->is_initialized();

  #warn get_logger(ref($self)||$self);
  #warn get_logger("");

  my $class = ref($self) || $self;

  $logconfig{$class} = '' if !defined($logconfig{$class});

  if($logconfig{$class} eq $logconfig{''}){
    $self->logconfig( _mangle_package($class) );
  }

  my $logger = get_logger($class);
  return $logger;
}

=head2 logconfig()

 Usage   : $object->logconfig('a Log4perl configuration stanza');
 Returns : the configuration stanza for $object
 Args    : a Log4perl configuration stanza.  L<Log::Log4perl> for details
 Function: This method allows you to set the configuration parameters for
           your subclass on a fine-grained level.  You can call this method
           at any time, and all logged packages will have their configurations
           reloaded.

           I've created a shortcut method, L</loglevel()> to easily update the
           Log::Log4perl::Logger instance's verbosity level() -- it's a lot
           easier than rewriting the configuration stanza.  If you would like
           easy access to other logger methods let me know and I'll add them.

=cut

sub logconfig {
  my($self,$stanza) = @_;
  $self->init() if ref($self) && !$self->is_initialized();

  my $class = ref($self) || $self;

  my $changed = 0;

  #initialize the logger, stanza doesn't exist for this package yet
  if($stanza eq _mangle_package($class)){
    $changed = 1;
    my $pack = $class;
    $pack =~ s/::/./g;
    my $name = _mangle_package($class);
    my $logformat = $log4perl_template;

    #warn "********".$logformat;

    my @i = $logformat =~ /%s/gs;
    my $i = scalar(@i);
    die qq(invalid \$Package::Base::Devel::log4perl_template must contain at least 2 '%s', contains only $i.) if $i < 2;
    my @slots = ();
    push @slots, $name for 1..$i-1;

    $stanza = sprintf($logformat, $pack, @slots );

  #got a new  stanza, reinitialize the logger
  } elsif(defined($stanza) and !ref($stanza) and $stanza ne $logconfig{$class}){

    $changed = 2;
  }

  if($changed){
    $logconfig{$class} = $stanza;
    my $all = join "\n", values %logconfig;
    Log::Log4perl->init(\$all);

    if($changed == 1){
      get_logger($class)->info("created logger for ".$class);
    } elsif($changed == 2){
      get_logger($class)->info("recreated logger for ".$class);
    } else {
      get_logger($class)->info("what does $changed mean? ".$class);
    }

  } elsif(!Log::Log4perl->initialized){
    Log::Log4perl->init(); #FIXME
  }

  return $logconfig{$class};
}

=head2 loglevel()

 Usage   : $self->loglevel('FATAL'); #only log fatal messages
 Returns : 
 Args    : a level string.  valid values, in order of ascending verbosity:
           OFF, FATAL, ERROR, WARN, INFO, DEBUG, ALL
 Function: adjust Log::Log4perl::Logger logging level


=cut

sub loglevel {
  my ($self,$level) = @_;
  $self->init() if ref($self) && !$self->is_initialized();

  if(defined($level{$level})){
    $self->log->level($level{$level});
  } elsif(defined($level)) {
    $self->log->error("Log level of '$level' is not valid, no action taken.  Valid values are: ".join(" ",keys %level));
    return undef;
  }

  foreach my $key (keys %level){
    return $key if $level{$key} == $self->log->level(); #stringify the numeric level
  }

  #unrecognized numeric levels get here.  should never happen
  $self->log->error("unexpected log level ".$self->log->level.".  please inform the author of ".__PACKAGE__);
  return $self->log->level;
}

=head2 _mangle_package()

 Usage   : An internal method, not intended to be called
           externally.
 Returns : A mangled package string
 Args    : A package name
 Function: this is an internal utility method for generating
           valid Log::Log4perl::Logger names

=cut

sub _mangle_package {
  my $pack = shift;
  $pack =~ s/::/_/g;
  return $pack;
}

=head2 _make_logger()

An internal method.  Returns a Log::Log4perl::Logger instance

=cut

sub _make_logger {
  my $pack = shift;
  if(!$logconfig{$pack} and !$black{$pack}){
    logconfig($pack);
  }
  return get_logger($pack);
}

=head1 INTERNAL UTILITY METHODS FOR LOGGING AND DIE/WARN TRAPPING

=head2 _die()

 Usage   : This is an internal method, not intended to be called
           externally.
 Function: logs a fatal message and calls CORE::die().
           Package::Base::Devel signal-traps die() calls to log
           them before really dying (via CORE::die()).
 Returns : never.  program exits.
 Args    : An epitaph for your program

=cut

sub _die {
  my $pack = (caller())[0];

  my $logger = _make_logger($pack);
  $logger->fatal(@_);

  CORE::die @_; # Now terminate really
};

=head2 _warn()

 Usage   : This is an internal method, not intended to be called
           externally.
 Function: logs a warning message and calls CORE::warn().
           Package::Base::Devel signal-traps warn() calls to log
           them before really warning (via CORE::warn()).
 Returns : 1
 Args    : A warning message for your program.

=cut

sub _warn {
  my $pack = (caller())[0];

  $Log::Log4perl::caller_depth++;

  my $logger = _make_logger($pack);
  $logger->warn(@_);
  CORE::warn @_; # Now do the real warning
  $Log::Log4perl::caller_depth--;
  return 1;
};

1;
__END__

