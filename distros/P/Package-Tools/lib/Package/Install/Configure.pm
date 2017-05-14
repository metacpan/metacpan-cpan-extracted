package Package::Install::Configure;

use strict;
use Carp qw(confess);
use Data::Dumper;
use Getopt::Long;
use SelfLoader;
use Term::ANSIColor;
use Text::ParseWords;
use Text::Wrap;

#can't use it here b/c it may not be installed when Package-Tools is
#installed, so we require it later.
#use Config::IniFiles;

use vars qw($AUTOLOAD);

use constant CACHE    => 'pkg_config.cache';
use constant TEMPLATE => 'pkg_config.in';

=head1 SYNOPSIS

  my $config = Package::Install::Configure->new();
  my $value1 = $config->setting1();               #get
  $config->setting1('a new value for setting 1'); #set

=head1 DESCRIPTION

Package::Install::Configure - Access package configuration values
from command-line options (Getopt::Long style), previously specified
cached settings, or default values.  This package is a kindred spirit to
the GNU automake and autoconf tools.

When a Package::Install::Configure object is instantiated, the following
happens:

  1. A. If F<pkg_config.cache> exists, load it into L</ini()> accessor as a
        Config::IniFiles object.
     B. Otherwise, if F<pkg_config.in> exists, load that.
     C. Otherwise, load nothing.

  2. If a configuration file was loaded, process commandline arguments
     Using Getopt::Long, overriding configuration setings with those provided
     from Getopt::Long.

  3. A. If C<--help> was given as a Makefile.PL argument, render the configuration
        as a usage document to STDOUT and exit(0).

        -otherwise-

     B. If a configuration file was loaded, and C<--interactive> was given as a
        Makefile.PL argument, query the user on STDOUT/STDIN for new configuration
        values.

  4. Variable values may also be accessed using C<$config-E<gt>my_setting_name()>
     to get the current value, or C<$config-E<gt>my_setting_name('a new value')> to
     update the value of the variable.

  5. When the object is destroyed (by falling out of scope, being undefined, etc),
     the current state of the object is written to F<pkg_config.cache>.

=head1 CONFIGURATION FILES pkg_config.in AND pkg_config.cache

The configuration files are in INI format, and are parsed using Config::IniFiles.
You should be familiar with the INI format and L<Config::IniFiles>.

=head2 RESERVED VARIABLES

These variables have a built-in function and are reserved for use by
Package::Install::Configure.

* help
* interactive

Run C<Makefile.PL --help> for a display of what parameters are available, and
C<Makefile.PL --interactive> for an interactive query for values of said
parameters.

=head2 DECLARING CONFIGURATION VARIABLES

Package::Install::Configure recognizes variables in the following INI sections:

for single value parameters:

* [option integer]
* [option float]
* [option string]
* [option dir]
* [option file]

for multi value parameters:

* [option integers]
* [option floats]
* [option strings]
* [option dirs]
* [option files]

Comments on sections/parameters are recognized and displayed when F<Makefile.PL> is
run with the C<--help> option.

Typechecking is performed on the integer, float, dir, and file sections, see
L</validate_type()>.

for scripts:

* [PL_FILES]
* [EXE_FILES]

thes sections are special -- they are passed to ExtUtils::MakeMaker to
determine which scripts are processed at make-time (PL_FILES), and which are installed
(EXE_FILES).  See L<ExtUtils::MakeMaker> for details on how that system works.

=head2 SETTING VARIABLE VALUES

See L<Config::IniFiles>

Default values can be set in F<pkg_config.in>, as well as collected from the
command-line using Getopt::Long-style options, or with interactive question/answer.

The Getopt::Long parameters available are created dynamically from the variable names
in F<pkg_config.in> or F<pkg_config.cache> (preferred if present).

=head3 EDITING CONFIGURATION FILE

See L<Config::IniFiles> for a description of the configuration file format.

=head3 COMMAND-LINE OPTIONS

For a script called F<script.pl>, valid executions of the script might be:

C<script.pl --color red --number 9>

C<script.pl>

Argument names are identical to those in F<pkg_config.in> or F<pkg_config.cache>.

=head3 INTERACTIVE QUERY

A few runs of C<script.pl --interactive> might look like the following:

 [14:38]aday@asti:~/cvsroot/Package-Tools> /usr/bin/perl ./script.pl --interactive
 color - what is your favorite color? (currently: "blue")? red
 number - what is your favorite number? (currently: "2")? 9

 [14:38]aday@asti:~/cvsroot/Package-Tools> /usr/bin/perl ./script.pl --interactive
 color - what is your favorite color? (currently: "red")? yellow
 number - what is your favorite number? (currently: "9")? 8

 [14:38]aday@asti:~/cvsroot/Package-Tools> /usr/bin/perl ./script.pl --interactive --color 6 --number orange
 Value "orange" invalid for option number (number expected)
 color - what is your favorite color? (currently: "6")? orange
 number - what is your favorite number? (currently: "8")? 6

=head1 AUTHOR

Allen Day, E<lt>allenday@ucla.eduE<gt>

=cut

=head1 METHODS

=cut

=head2 AUTOLOAD()

FIXME internal method, undocumented

=cut

sub AUTOLOAD {
  my $self = shift;
  my $val  = shift;

  #return undef unless $self && $self->ini();

  my $symbol = $AUTOLOAD;
  my $sub = $symbol;
  $sub =~ s/^.+::([\w]+?)$/$1/;

  my $sect = undef;
  my $i = 0;
  foreach my $section ($self->ini()->Sections){
    if(grep {$_ eq $sub} $self->ini()->Parameters($section)){
      $sect = $section;
      $i++;
    }

  }

  if($i == 0){
    die "no such parameter or method '$sub'";
  } elsif($i == 1){
    no strict 'refs';

    *$symbol = sub {
      my($self,@val) = @_;
      if(@val){
        return $self->ini()->setval($sect,$sub,@val);
      } else {
        return $self->ini()->val($sect,$sub);
      }
    };

    return $self->$sub(@_);
  } else {
    warn "parameters in multiple ($i) sections named $sub, use
  \$install->config->ini()->val('section',$sub)
  \$install->config->ini()->setval('section,$sub,\@newvals)
for access";
    return undef;
  }

  return undef;
}

=head2 new()

 Usage   : $config = Package::Install::Configure->new();
 Function: constructs a new object, reads variables and their default/cached
           values from state files F<pkg_config.in> and F<pkg_config.cache>.
           Also handles command-line arguments by delegating to Getopt::Long.
 Returns : a Package::Install::Configure object
 Args    : none.

=cut

sub new {
  my($class,%arg) = @_;

  my $self = bless {}, $class;

  my $ini;

  if(!$arg{bootstrap}){
    require Config::IniFiles;
    if (-f CACHE) {
      $ini = Config::IniFiles->new( -file => CACHE );
      print STDERR colored("\rusing cached configuration values from ".CACHE,'cyan')."\n";
    } elsif (-f TEMPLATE) {
      $ini = Config::IniFiles->new( -file => TEMPLATE );
      print STDERR colored("\rusing default configuration values from ".TEMPLATE,'cyan')."\n";
    } else {
      #no config file
      $ini = Config::IniFiles->new();
    }

    if(!$ini){
      print STDERR colored('config parse failed: '.join(' ',@Config::IniFiles::errors),'red')."\n";
      exit(1);
    }

    $self->ini($ini);

    #override defaults and cache with command-line args
    $self->process_options();

    #query user interactively
    $self->process_interactive() if $self->interactive();

    #validate parameters
    $self->validate_configuration();
  }

  $self->ini()->WriteConfig(CACHE) if $self->ini();

  return $self;
}

=head2 validate_type()

 Usage   : $obj->validate_type('type','thing_to_check');
 Function: attempts to validate a value as a particular type
           valid values for argument 1 are: integer, float, string, dir, file.
 Returns : 1 on success
 Args    : anonymous list:
           argument 1: type to validate against
           argument 2: value to validate

=cut

sub validate_type {
  my ($self,$type,$val) = @_;

     if($type eq 'integer') { return 1 if $val =~ /^-?\d+$/ }
  elsif($type eq 'float')   { return 1 if $val =~ /^-?\d*\.?\d*$/ }
  elsif($type eq 'string')  { return 1 }
  elsif($type eq 'dir')     { return 1 if -d $val }
  elsif($type eq 'file')    { return 1 if -f $val }

  return 0;
}


=head2 validate_configuration()

 Usage   : $obj->validate_configuration();
 Function: internal method.  attempts to validate values
           from the configuration file by calling L</validate_type()>
           on each.
 Returns : n/a
 Args    : none

=cut

sub validate_configuration {
  my ($self) = @_;

  my $cfg = $self->ini;

  foreach my $section ( $cfg->GroupMembers('option') ) {
    foreach my $param ($cfg->Parameters("option $section")){
      my $die = 0;

      #single
      if($section !~ /s$/){
        my $val = val("option $section",$param);
        my $type = $section;
        $type =~ s/option //;
        $die++ unless $self->validate_type($type,$val);
      }

      #plural
      else {
        my @val = val("option $section",$param);
        foreach my $val (@val){
          my $type = $section;
          $type =~ s/option //;
          $type =~ s/s$//;
          $die++ unless $self->validate_type($type,$val);
        }
      }

      #did the param(s) validate?
      if($die){
        $section =~ s/option //;
        die "[option $section] $param: value is not a valid '$section'";
      }
    }
  }
}

=head2 process_interactive()

 Usage   : $obj->process_interactive();
 Function: iterates over [option *] and [EXE_FILES] sections from
           configuration file and prompts user for new values.  values
           are validated using L</validate_type()> before being
           accepted.  lists of values are accepted and split using
           L<Text::ParseWords::shellwords>
 Returns : n/a
 Args    : none

=cut

sub process_interactive {
  my ($self) = @_;

  my $ask = qq(\r%s [%s] - %s (currently: "%s")? );

  foreach my $section ( $self->ini()->Sections ){
    next unless $section =~ /^option/;
    foreach my $param ( $self->ini()->Parameters($section) ){
      my $type = $section;
      $type =~ s/^option //;

      my $comment = join('', map{s/^#//;$_} $self->ini()->GetParameterComment($section,$param));

      print sprintf($ask,
                    $param,
                    $type,
                    $comment,
                    $self->ini()->val($section,$param)
                   );
      my $response = <>;
      chomp $response;

      if($response eq ''){
        print colored("\ryou didn't respond, skipping.  this may break the build",'red')."\n";
        next;
      }

      my $valid = 1;
      #single
      if($type !~ /s$/){
        if(!$self->validate_type($type,$response)){
          $valid = 0;
        } else {
          #commit it
          $self->ini()->setval($section,$param,$response);
        }
      }
      #plural
      else {
        $type =~ s/s$//;
        my @response = shellwords($response);
        foreach my $response (@response) {
          if(!$self->validate_type($type,$response)){
            $valid = 0;
            last;
          } else {
            $self->ini()->setval($section,$param,@response);
          }
        }
        if($valid == 1) {
          #commit it
          $self->ini()->setval($section,$param,@response);
        }
      }
      if(!$valid){
        print colored("\rinvalid value(s), try again",'red')."\n";
        redo;
      }
    }
  }

  $ask = qq(\rinstall %s - %s [Y/n]? );

  foreach my $exe ( $self->ini()->Parameters('EXE_FILES') ){
    my $target = $exe;

    $target =~ s/\.PLS?$//;

    my $comment = join('', map{s/^#//;$_} $self->ini()->GetParameterComment('EXE_FILES',$exe));

    print sprintf($ask,
                  $target,
                  $comment,
                  $self->ini()->val('EXE_FILES',$exe)
                 );
    my $response = <>;
    chomp $response;

    if($response !~ /^n/i){
      $self->ini()->setval('EXE_FILES',$exe,'yes')
    } else {
      $self->ini()->setval('EXE_FILES',$exe,'no')
    }
  }
}


=head2 process_options()

 Usage   : $config->process_options();
 Function: Internal method that processes command-line options.

=cut

sub process_options {
  my $self = shift;

  my $cfg = $self->ini();

  my %slot = ();
  my %sect = ();
  my @protos = ();

  #hardcode in --help
  $slot{help} = undef;
  push @protos, 'help!';
  $slot{interactive} = undef;
  push @protos, 'interactive!';

  foreach my $section ($cfg->GroupMembers('option')) {
    foreach my $param ($cfg->Parameters($section)) {
      $sect{$param} = $section;
      $slot{$param} = undef;

      #single
         if($section eq 'option integer') { push @protos, "$param=i" }
      elsif($section eq 'option float')   { push @protos, "$param=f" }
      elsif($section eq 'option file')    { push @protos, "$param=s" }
      elsif($section eq 'option dir')     { push @protos, "$param=s" }
      elsif($section eq 'option string')  { push @protos, "$param=s" }

      #plural
      elsif($section eq 'option integers'){ push @protos, "$param=i@" }
      elsif($section eq 'option floats')  { push @protos, "$param=f@" }
      elsif($section eq 'option files')   { push @protos, "$param=s@" }
      elsif($section eq 'option dirs')    { push @protos, "$param=s@" }
      elsif($section eq 'option strings') { push @protos, "$param=s@" }
    }
  }

  GetOptions(\%slot,@protos);

  #if help requested, give it and bail out
  if($slot{help}){
    $self->show_help();
    exit 0;
  }

  #if interactive requested, set a flag to do a query later
  if($slot{interactive}){
    $self->interactive(1);
  }

  #handle setteds
  foreach my $k (keys %slot){
    next unless defined($slot{$k});
    if(ref($slot{$k}) eq 'ARRAY'){
      $cfg->setval($sect{$k},$k,@{ $slot{$k} });
    } else {
      $cfg->setval($sect{$k},$k,$slot{$k});
    }
  }
}

=head2 show_help()

 Usage   : $obj->show_help();
 Function: render configuration file sections/parameters with
           descriptions to STDOUT.  program exits and call does
           not return.
 Returns : exit code on program termination
 Args    : exits 0 (success)

=cut

sub show_help {
  my ($self) = @_;

  my $i = 4;

  print "Usage: $0 [options]\n";
  print "Available options, organized by section:\n\n";

  foreach my $section ($self->ini->Sections()){
    next unless $section =~ /^option/;
    next unless $self->ini->Parameters($section);

    my $comment = join(' ', map {s/^#+//; $_} $self->ini->GetSectionComment($section));
    $comment ||= 'no description for this section';
    print( (' ' x $i)."[$section] $comment\n" );

    $i += 4;

    foreach my $param ($self->ini->Parameters($section)){
      my $comment = join(' ', map {s/^#+//; $_} $self->ini->GetParameterComment($section,$param));
      $comment ||= 'no description for this parameter';
      print( (' ' x $i).'--'.$param." : $comment\n" );
    }

    $i -= 4;

    print "\n";
  }
}

=head2 ini()

 Usage   : $obj->ini($newval)
 Function: holds a Config::IniFiles instance
 Returns : value of ini (a scalar)
 Args    : on set, new value (a scalar or undef, optional)


=cut

sub ini {
  my($self,$val) = @_;
  $self->{'ini'} = $val if defined($val);
  return $self->{'ini'};
}

=head2 interactive()

 Usage   : $obj->interactive($newval)
 Function: flag for whether or not the user should be interactively
           queried for configuration values.
 Returns : value of interactive (a scalar)
 Args    : on set, new value (a scalar or undef, optional)


=cut

sub interactive {
  my($self,$val) = @_;
  $self->{'interactive'} = $val if defined($val);
  return $self->{'interactive'};
}

=head2 DESTROY()

called when the object is destroyed.  writes object's variables' states
to F<pkg_config.cache> to be read at next instantiation.

=cut

sub DESTROY {
  my $self = shift;
  $self->ini->WriteConfig(CACHE) if $self->ini();
}

1;
