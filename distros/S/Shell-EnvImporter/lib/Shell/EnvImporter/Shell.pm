package Shell::EnvImporter::Shell;

use strict;
use warnings;
no warnings 'uninitialized';

use IO::Handle;
use IO::Select;
use IPC::Open3;
use Shell::EnvImporter::Result;

use Class::MethodMaker 2.0 [
    new     => [qw(-init new)],
    scalar  => [qw(
      debuglevel

      name

      sourcecmd
      envcmd

      envsep
      cmdsep
      wordsep
      squotechar
      dquotechar
      escchar

      statusvar
    )],
    array  => [qw(
      flags

      ignore
    )],
  ];

# Block size
use constant BLKSIZE => 4096;

# Default -- the Bourne shell
use constant DEFAULTS => (
  name         => 'sh',      # Shell name

  flags        => ['-c'],      # Flag to pass a command/script to the shell

  sourcecmd    => '.',       # Command for sourcing a script file
  envcmd       => 'env',     # Command for printing the environment

  envsep       => '=',       # Env separator ('=' if envcmd returns '<key>=<value>')
  cmdsep       => ';',       # Command separator
  wordsep      => ' ',       # Word separator
  squotechar   => "'",       # Single-quote character
  dquotechar   => '"',       # Double-quote character
  escchar      => "\\",      # Escape character (to escape the quote character)

  statusvar    => '$?',      # Exit status of last command (shell variable)

  # These variables get changed in the normal course of shell execution
  # without being explicitly set
  ignore       => [qw(_ PWD SHLVL)],  
);



##########
sub init {
##########
  my $self     = shift;
  my %args     = @_;
  my %defaults = (DEFAULTS);

  # Set supplied fields with defaults
  my @fields = (keys %args, keys %defaults);
  my %fields; @fields{@fields} = (1) x @fields;
  @fields = keys %fields;

  foreach my $field (@fields) {
    if ($self->can($field)) {
      my $curval = $self->$field();
      my $arg    = exists($args{$field}) ? $args{$field} : $defaults{$field};
      if (ref($curval) =~ /ARRAY/) {
        $self->$field(@$arg);
      } elsif (ref($curval) =~ /HASH/) {
        $self->$field(%$arg);
      } else {
        $self->$field($arg);
      }
    }
  }
  

}




#########
sub run {
#########
  my $self    = shift;
  my %args    = @_;

  my $command = $args{'command'};

  # Make a random tag to split up the output
  my $tag = join('_', time, $$, int(rand(1) * 10000000));
  $self->dprint(4, "Output tag: $tag\n");

  # Create a result object
  my $rv = Shell::EnvImporter::Result->new();

  # Create the shell script
  my @script  = $self->make_script($command, $tag);

  $self->dprint(3, "EXECUTING: @script\n");

  # Run the shell script
  my $output  = $self->execute(@script);

  # Parse the results
  $self->dprint(1, "Parsing results\n");
  $self->parse_results($rv, $output, $tag);

  return $rv;

}



#################
sub make_script {
#################
  my $self      = shift;
  my $command   = shift;
  my $tag       = shift;

  my $statusvar = $self->statusvar;
  my $wordsep   = $self->wordsep;

  # Command to invoke the shell
  my $shellcmd  = join($wordsep, $self->name, $self->flags);

  # The script: print tag, run command, print tag, run 'env', print tag.
  my $script    = join($self->cmdsep,
    $self->echo_command($tag, 0),
    $command,
    $self->echo_command($tag, $statusvar),
    $self->envcmd,
    $self->echo_command($tag, $statusvar),
    );

  return ($self->name, $self->flags, $script);

}



#############
sub execute {
#############
  my $self   = shift;
  my @script = @_;

  # Establish STDIN, STDOUT, and STDERR pipes for the child
  my(%fh, %h2p);
  foreach my $pipename (qw(STDIN STDOUT STDERR)) {
    my $handle      = IO::Handle->new();
    $fh{$pipename}  = $handle;
    $h2p{"$handle"} = $pipename;
  }


  # Run that puppy
  my $pid = open3($fh{'STDIN'}, $fh{'STDOUT'}, $fh{'STDERR'}, @script);


  # No input.
  $fh{'STDIN'}->close();


  # Consume output until the child dies.
  my $s = IO::Select->new($fh{'STDOUT'}, $fh{'STDERR'});

  my $t0 = time;
  my %buf;
  while (1) {

    my @ready = $s->can_read();
    last unless (@ready);

    foreach my $ready (@ready) {
      my $pipename = $h2p{"$ready"};
      if ($ready->eof) {
        $s->remove($ready);
        last unless ($s->count);
      } else {
        $ready->read($buf{$pipename}, BLKSIZE, length($buf{$pipename}));
      }
    }

  }


  if ($s->count) {

    # Timed out -- kill the child
    kill 'TERM', $pid;

    $buf{'STDERR'} .= "ERROR: Timed out waiting for output";

  }


  # Reap the child process
  waitpid($pid, 0);


  return (\%buf);

}



###################
sub parse_results {
###################
  my $self   = shift;
  my $rv     = shift;
  my $output = shift;
  my $tag    = shift;

  # Save STDERR if present
  if (defined($output->{'STDERR'})) {
    $rv->stderr($output->{'STDERR'});
    $self->dprint(3, "STDERR: $output->{'STDERR'}\n");
  }

  # Parse the output, ferreting out exit status and environment based on
  # the tag.
  my @lines = split(/\n/, $output->{'STDOUT'});
  my %output;

  # STDOUT FORMAT:
  #   <output from shell startup, if any>
  #   <tag> 0
  #   <output from environment-altering command>
  #   <tag> <status of environment-altering command>
  #   <output from 'env' command>
  #   <tag> <status of 'env' command>


  # Read the shell startup output
  my @shell_output;
  while (@lines) {
    my $line = shift(@lines);
    if ($line =~ /^$tag 0/) {
      $rv->shell_status(0);
      $self->dprint(4, "SHELL STATUS:  ", $rv->shell_status, "\n");
      last;
    } else {
      push(@shell_output, $line);
    }
  }
  if (@shell_output) {
    $rv->shell_output(join("\n", @shell_output));
    $self->dprint(4, "SHELL OUTPUT:  ", $rv->shell_output, "\n");
  }


  # Read the env command output
  my @command_output;
  while (@lines) {
    my $line = shift(@lines);
    if ($line =~ /^$tag (\d+)/) {
      $rv->command_status($1);
      $self->dprint(4, "COMMAND STATUS:  ", $rv->command_status, "\n");
      last;
    } else {
      push(@command_output, $line);
    }
  }
  if (@command_output) {
    $rv->command_output(join("\n", @command_output));
    $self->dprint(4, "COMMAND OUTPUT:  ", $rv->command_output, "\n");
  }


  # Read the environment
  my %new_env;
  while (@lines) {
    my $line = shift(@lines);
    if ($line =~ /^$tag (\d+)/) {
      $rv->env_status($1);
      $self->dprint(4, "ENV STATUS:  ", $rv->env_status, "\n");
      last;
    } else {
      my($key, $value) = $self->parse_env($line);
      $new_env{$key} = $value;
    }
  }


  # Finally, diff the new environment and the old, but only if the 
  # commands succeeded
  if ($rv->shell_status   == 0 and 
      $rv->command_status == 0 and 
      $rv->env_status     == 0     ) {

    $self->dprint(1, "Comparing environments\n");
    $self->env_diff($rv, \%new_env);

  } else {

    $@ = "Command failed -- check status and output";

  }


}




###############
sub parse_env {
###############
  my $self = shift;
  my $line = shift;

  # Given a line of output from $self->envcmd, return (key, value)
  return(split($self->envsep, $line, 2));

}



############
sub squote {
############
  my $self   = shift;
  my $string = shift;

  my $qc = $self->squotechar;
  my $ec = $self->escchar;

  # Escape existing quotes
  $string =~ s/$qc/${qc}${ec}${qc}${qc}/g;

  # Add enclosing quotes
  return join('', $qc, $string, $qc);

}

############
sub dquote {
############
  my $self   = shift;
  my $string = shift;

  my $qc = $self->dquotechar;
  my $ec = $self->escchar;

  # Escape existing quotes
  $string =~ s/$qc/${qc}${ec}${qc}${qc}/g;

  # Add enclosing quotes
  return join('', $qc, $string, $qc);

}



###################
sub sourcecommand {
###################
  my $self = shift;
  my $file = shift;

  # Given a filename, generate the 'source' command for this shell

  # Quote the file in case it contains shell-special characters
  my $filestr = $self->squote($file);

  return(join($self->wordsep, $self->sourcecmd, $filestr));

}


##################
sub echo_command {
##################
  my $self = shift;
  my $str  = $self->dquote("@_");

  return "echo $str";

}



################
sub env_export {
################
  my $self   = shift;
  my %values = (@_ == 1 ? %{$_[0]} : @_);

  my @sets;
  foreach my $var (sort keys %values) {
    if (defined($values{$var})) {
      push(@sets, "${var}=$values{$var}");
    } else {
      push(@sets, "unset $var");
    }
  }

  my $sets   = join($self->cmdsep, @sets);
  my $export = join($self->wordsep, 'export', sort keys %values);

  return join($self->cmdsep, $sets, $export);

}



##############
sub env_diff {
##############
  my $self    = shift;
  my $rv      = shift;
  my $new_env = shift;

  # Make an ignore hash from the shell ignore list
  my @ignores = $self->ignore;
  my %ignore; @ignore{@ignores} = (1) x @ignores;


  my %old_env = $rv->start_env;
  foreach my $var (keys %$new_env) {

    unless ($ignore{$var}) {

      if (exists($old_env{$var})) {

        if ($old_env{$var} ne $new_env->{$var}) {

          # Variable was modified
          $self->dprint(3, "MODIFIED: $var\n");
          my $change = Shell::EnvImporter::Change->new(
            type  => 'modified',
            value => $new_env->{$var},
          );
          $rv->changed_set($var => $change);
        }

      } else {

        # Var was added
        $self->dprint(3, "ADDED: $var\n");
        my $change = Shell::EnvImporter::Change->new(
          type  => 'added',
          value => $new_env->{$var},
        );
        $rv->changed_set($var => $change);

      }

    }

    delete($old_env{$var});

  }

  # Whatever's left in old_env was removed
  foreach my $var (keys %old_env) {
    next if ($ignore{$var});
    $self->dprint(3, "REMOVED: $var\n");
    my $change = Shell::EnvImporter::Change->new(
      type  => 'removed',
    );
    $rv->changed_set($var => $change);
  }

}


############
sub dprint {
############
  my $self  = shift;
  my $level = shift;

  my($package, $filename, $line) = caller;

  print STDERR "-" x $level, " $package:$line : ", @_ 
    if ($self->debuglevel >= $level);

}


1;

__END__
=head1 NAME

package Shell::EnvImporter::Shell - Shell abstraction for Shell::EnvImporter

=head1 SYNOPSIS

  use Shell::EnvImporter;

  # Have Shell::EnvImporter create the shell object
  my $sourcer  = Shell::EnvImporter->new(
                   command  => $command,
                   shell    => $shellname,
                   auto_run => 0,
                 );

  # Fetch the shell object
  my $shellobj = $sourcer->shellobj;

  # Set the shell invocation flags
  $shellobj->flags($flags);

  # Set an alternative 'env' command
  $shellobj->envcmd($envcmd);


  # Manipulate the ignore list:

  # - set
  $shellobj->ignore(qw(_ PWD SHLVL));  

  # - add to
  $shellobj->ignore_push(qw(HOME));  

  # - clear
  $shellobj->ignore_clear();


  # Run the command with the modified shell
  $sourcer->run();


=head1 DESCRIPTION

Shell::EnvImporter allows you to import environment variable changes
exported by an external script or command into the current environment.
The Shell::EnvImporter::Shell object provides more control over
interaction with the shell.

=head1 METHODS

=over 4

=item B<flags()>

=item B<flags(@flags)>

=item B<flags_push(@flags)>

Get or set the flags passed to the shell.  E.g. default Bash flags are
'-norc -noprofile -c', to prevent the sourcing of startup scripts.
Note: If you set the flags, you MUST include the '-c' flag (or equivalent)
for passing commands to the shell on the command line.


=item B<envcmd()>

=item B<envcmd($command)>

Get or set the command used to print out the environment.  E.g., under
the Bourne shell and variants, the default command is 'env'.  Since 'env'
only prints exported environment variables, you can change the command
to 'set' to see all shell environment variables, exported or not.


=item B<ignore()>

=item B<ignore(@variables)>

=item B<ignore_push(@variables)>

=item B<ignore_clear()>

Get, set, append to, or clear the shell ignore list.  The shell ignore
list is a list of variables that are never imported.  These are
generally variables that are changed automatically by the shell (e.g.
SHLVL and PWD), providing little information to a noninteractive shell.  

=back


=head1 AUTHOR

David Faraldo, E<lt>dfaraldo@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

  Copyright (C) 2005-2006 by Dave Faraldo

  This library is free software; you can redistribute it and/or modify it
  under the same terms as Perl itself.  No warranty is expressed or implied.


=cut
