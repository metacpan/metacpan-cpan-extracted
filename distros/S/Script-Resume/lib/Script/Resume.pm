package Script::Resume;

use strict;
use vars qw($VERSION);
use Data::Dumper;
use File::Basename;
use FileHandle;

$VERSION = '1.0';

our $NAME = "Script::Resume";

# SCRIPT_STATE - Script specific state (ref to a ref to an object or hash or array or scalar)
# STATE_FILE   - File to store state of everything
# RESUME       - Continue where left off (default = 1)
# DEBUG        - Print out debug info
# RETAIN_STATE - Keep the state around even after the script finishes 
#                (You'll want to delete this by hand before running the script again)
# STAGES       - The list of stage names
# STOP_AFTER   - Stop after state X is run.
sub new
{
  my $this = shift;
  my $class = ref($this) || $this;
  my %opts = @_;
  my $tmpdir = $ENV{TEMP} || $ENV{TMP} || "/tmp";
  my $def_state_file = "$tmpdir/" . basename($0) . ".state";

  my $self = { _istate => {ORDER => 0,
                           STOP_AFTER => $opts{STOP_AFTER},
                           SFILE => $opts{STATE_FILE} || $def_state_file,
                           DEBUG => $opts{DEBUG},
                           RETAIN_STATE => $opts{RETAIN_STATE}},
               _stages => {},
               _estate => {RESULTS => {}}};

  $self->{_estate}->{SCRIPT} = ${$opts{SCRIPT_STATE}} if $opts{SCRIPT_STATE};
  bless $self, $class;

  $self->debug("Resume: unlinking file $opts{RESUME}"), unlink($self->{_istate}->{SFILE}) if (defined $opts{RESUME} && $opts{RESUME} == 0);
  $self->{_istate}->{SFH} = new FileHandle($self->{_istate}->{SFILE}, O_RDWR|O_CREAT) or die "$NAME: Couldn't open state file $self->{_istate}->{SFILE}: $!\n";

  $self->addStages(@{$opts{STAGES}}) if $opts{STAGES};
  $self->readState($opts{SCRIPT_STATE});

  return $self;
}

# NAME
# FUNC
# ALWAYS
# ORDER
sub addStage
{
  my $self = shift;
  my $name = shift;
  my $caller_name = $name;
  $caller_name = $self->getCallingPackage() . "::$caller_name" unless (index($caller_name, "::") >= 0);

  die "$NAME: addStage: Need a name for the stage" unless $name;
  %{$self->{_stages}->{$name}} = @_;
  $self->{_stages}->{$name}->{FUNC} = \&{$caller_name} unless $self->{_stages}->{$name}->{FUNC};
  $self->{_stages}->{$name}->{ORDER} = ++$self->{_istate}->{ORDER} unless defined $self->{_stages}->{$name}->{ORDER};
  $self->debug("Adding stage = $name order = $self->{_stages}->{$name}->{ORDER}");
  die "$NAME: FUNC for stage $name not defined\n" unless defined &{$self->{_stages}->{$name}->{FUNC}};
}

sub getCallingPackage
{
  my $self = shift;
  my $i = 0;
  my $caller;
  while ( ($caller = (caller($i))[0]) eq $NAME) {
    $i++;
  }
  
  return $caller;
}


sub addStages
{
  my $self = shift;
  $self->addStage($_) foreach @_;
}

sub setStageAttributes
{
  my $self = shift;
  my $name = shift;
  my %opts = @_;

  die "$NAME: addStage: Need a name for the stage" unless $name;
  die "$NAME: No such stage $name\n" unless $self->{_stages}->{$name};

  $self->{_stages}->{$name}->{$_} = $opts{$_} foreach (keys %opts);
}

sub debug
{
  my $self = shift;

  return unless $self->{_istate}->{DEBUG};
  my $msg = shift;
  print "$NAME: $msg\n";
}

sub readState
{
  my $self = shift;
  my $script_state = shift;
  my $fh = $self->{_istate}->{SFH};
  my $dumpy;

  $fh->seek(0,0);

  $dumpy = join("", <$fh>);

  if ($dumpy) {
    my $VAR1;
    $self->{_estate} = eval($dumpy);
    die "$NAME: Couldn't read in state: $@\n" if $@;
    $$script_state = $self->{_estate}->{SCRIPT} if ($script_state);
    return 1;
  }
  return 0;
}

sub runAllStages
{
  my $self = shift;
  my $stage;
  foreach $stage (sort {$self->{_stages}->{$a}->{ORDER} <=> $self->{_stages}->{$b}->{ORDER}} keys %{$self->{_stages}}) {
    $self->runStage($stage, @_);
  }
}

sub runStage
{
  my $self = shift;
  my $name = shift;

  $self->debug("Running Stage: $name"), $self->{_estate}->{RESULTS}->{$name} = [&{$self->{_stages}->{$name}->{FUNC}}(@_)] if ($self->{_stages}->{$name}->{ALWAYS} || ! defined $self->{_estate}->{RESULTS}->{$name}); # RJP: remove the "defined" and replace RESULTS with RUN
  #$self->{_estate}->{RUN}->{$name} = 1; #RJP 

  $self->writeState();
  $self->debug("Stopping after $name because STOP_AFTER = $name"), exit(0) if $self->{_istate}->{STOP_AFTER} eq $name;
  return wantarray ? @{$self->{_estate}->{RESULTS}->{$name}} : $self->{_estate}->{RESULTS}->{$name}->[0];
}

sub writeState
{
  my $self = shift;

  return if $self->{_istate}->{DONE};
  my $fh = $self->{_istate}->{SFH};
  $fh->seek(0,0);
  print $fh Dumper($self->{_estate});
  $fh->flush();
}

sub doneEarly
{
  my $self = shift;
  $self->{_istate}->{DONE} = 1;
}

sub DESTROY
{
  my $self = shift;
  $self->writeState();
  $self->{_istate}->{SFH}->close();

  unlink $self->{_istate}->{SFILE} if (!$self->{_istate}->{RETAIN_STATE} && ($self->{_istate}->{DONE} || scalar keys %{$self->{_stages}} == scalar keys %{$self->{_estate}->{RESULTS}}));#RUN - RJP
}

1;

__END__

=head1 NAME

Script::Resume - State keeper for scripts that might abort in the middle of execution but need to pick up where they left off in later invocations.

=head1 SYNOPSIS

    use Script::Resume;

    my $state = {Robin => "Jason Todd"};
    my $rez = new Script::Resume(SCRIPT_STATE => \$state, STAGES => ["do_this", "then_that", "finally_this"]);
    $rez->addStage("oh_and_this_too", FUNC => \&this_too, ALWAYS=>1);

    $rez->runAllStages();

    print "Result: Robin = $state->{Robin}\n";

    sub do_this      { print "I'm doing this\n";}
    sub then_that    { print "I'm doing that\n"; $state->{Robin} = "Dick Grayson"; }
    sub finally_this { print "I'm finally doing this\n"; $state->{Robin} = "Tim Drake"; }
    sub this_too     { print "I'm doing this too\n";}

Here's a script that runs it with more explicit control

    use Script::Resume;

    my $robin;
    my $now = time();
    my $rez = new Script::Resume();
    $rez->addStage("my_first_stage",  FUNC => \&stage_one);
    $rez->addStage("my_second_stage", FUNC => \&stage_two);
    $rez->addStage("my_third_stage",  FUNC => \&stage_three);

    $robin = $rez->runStage("my_first_stage", "Jason Todd");
    print "Result: Robin 1 = $robin\n";

    $robin = $rez->runStage("my_second_stage", "Dick Grayson");
    print "Result: Robin 2 = $robin\n";

    $robin = $rez->runStage("my_third_stage", "Tim Drake");
    print "Result: Robin3 = $robin\n";

    sub stage_one { return shift;}
    sub stage_two { return shift;}
    sub stage_three { return shift;}

=head1 DESCRIPTION

C<Script::Resume> Allows you to automatically break your script into
stages with state such that if the script bails out in the middle
somewhere, you can fix the problem, rerun the script and it'll pick up
where it left off, with the previous state and all. This is useful for
tasks where you can't start from the beginning again and/or you
wouldn't want to, such as scripts involved in copying massive files
around.

State is maintained in a plain Data::Dumper format file in
$ENV{TEMP}/$0.state or /tmp/$0.state (or wherever you designate) so
you can tweak it before re-running. It will store the SCRIPT_STATE you
pass into the constructor along with all return values from all the
stages.  If the stage has already been run in a previous invocation of
your script, the return value will be returned without actually
re-running the stage.

=head1 METHODS

=over 4

=item C<my $rez = Script::Resume-E<gt>new(%config)>

Construct a new object. Optional parameters include:

   $rez = new Script::Resume(DEBUG        => 1,            # Print out debug info. (Default = 0)
                             RETAIN_STATE => 1,            # Keep the state around even after the script finishes 
                                                           # (You'll want to delete this by hand before running the script again)
                                                           # For debugging only. (Default = 0)
                             RESUME       => 0,            # Continue where left off (Default = 1)
                             SCRIPT_STATE => \$my_state,   # Script specific state (reference to a reference to an 
                                                           # object or hash or array or scalar). (Default = undef)
                             STATE_FILE   => "/tmp/X",     # Filename of state file where state is to be stored
                                                           # (Default = "$ENV{TEMP}/$0.state" or "/tmp/$0.state")
                             STAGES       => ["s1", "s2"], # Reference to an array of stage names. (Default = undef)
                             STOP_AFTER   => "s2");        # Stop after state "s2" is run. For debugging only. (Default = undef)

=item C<$rez-E<gt>addStage($stage_name, %config)>

addStage() is where you specify the stage name and optionally map it to a function reference. If no
function reference is given, it'll try to use the name as a function reference in the calling package.

    $rez->addStage("stage_name",
                   FUNC    => \&my_func_ref,               # Function reference to call for this stage
                   ALWAYS  => 1);                          # Always run this stage. (Default = 0)

=item C<$rez-E<gt>addStages(@stage_names)>

This is a convenience function that in turn calls addStage(). You can only call this if all of your
stage_names map to function names.

=item C<$rez-E<gt>setStageAttributes($stage_name, %config)>

Sets a stage's attributes, such as:

    $rez->setStageAttribute("MyThirdStage", ALWAYS => 1, FUNC => \&my_func);

=item C<$rez-E<gt>runStage($stage_name, @stage_parameters)>

Runs the stage matching the name $stage_name passing in @stage_parameters and returning the result of running that stage.
If the stage has already been run in a previous invocation, it will return that saved data.

=item C<$rez-E<gt>runAllStages($stage_name, @stage_parameters)>

Runs all stages in order, passing in @stage_parameters.

=item C<$rez-E<gt>doneEarly()>

Call this when you don't want to run the rest of the stages. Calling this function tells Script::Resume that
there is no further work to be done and the state can be deleted.

=back

=head1 LEGALESE

Copyright 2006 by Robert Powers, 
all rights reserved. This program is free 
software, you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 AUTHOR

2006, Robert Powers <batman@cpan.org>
