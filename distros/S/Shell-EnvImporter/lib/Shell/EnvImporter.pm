package Shell::EnvImporter;

use strict;
use warnings;
no warnings 'uninitialized';

our @ISA = qw();

our $VERSION = '1.06';

use Shell::EnvImporter::Shell;

use Class::MethodMaker 2.0 [
    new     => [qw(-init new)],
    scalar  => [qw(
      debuglevel

      command
      file
      shell

      auto_run
      auto_import
      import_modified
      import_added
      import_removed
      import_filter

      shellobj
      result
    )],

  ];



use constant DEFAULT_SHELL    => 'sh';


use constant DEFAULTS => (
  auto_run         => 1,
  auto_import      => 1,
  import_modified  => 1,
  import_added     => 1,
  import_removed   => 0,

  shell            => DEFAULT_SHELL,
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

  # Create a shell object
  $self->dprint(1, "Creating shell object\n");
  my $shellobj = $self->_get_shell() or return;

  # If file is supplied, command is to source the file.
  if (defined($self->file)) {
    $self->dprint(1, "Setting command to source '", $self->file, "'\n");
    $self->command($shellobj->sourcecommand($self->file));
  }

  # Run the command if requested.
  $self->run() if ($self->auto_run);

}



#########
sub run {
#########
  my $self    = shift;
  my $command = shift || $self->command;

  $self->dprint(1, "Executing command\n");

  unless (defined($command)) {
    $@ = "Can't run without a command";
    return undef;
  };

  my $rv = $self->shellobj->run(
             command => $command,
           );

  $self->result($rv);

  if ($self->auto_import) {
    if ($self->import_filter) {
      $self->env_import_filtered();
    } else {
      $self->env_import;
    }
  }

  return $rv;


}


################
sub env_import {
################
  my $self   = shift;
  my @vars;

  $self->dprint(1, "Performing policy import\n");

  unless (defined($self->result)) {
    $@ = "Can't import before a successful run";
    return undef;
  }

  if (ref($_[0])) {
    @vars = @{$_[0]};
  } elsif (@_) {
    @vars = @_;
  } else {
    @vars = $self->result->changed_keys;
  }

  my %import; @import{@vars} = (1) x @vars;

  foreach my $var ($self->result->changed_keys) {
    next unless ($import{$var});
    my $type   = $self->result->changed_index($var)->type;
    my $newval = $self->result->changed_index($var)->value;
    my $fn = "import_${type}";
    next unless ($self->$fn());

    $self->dprint(2, "Importing $type var $var=$newval\n");

    $self->_import_var($var, $newval, $type);

  }

  return $self->result;

}


#########################
sub env_import_filtered {
#########################
  my $self   = shift;
  my $filter = shift || $self->import_filter;

  $self->dprint(1, "Performing filtered import\n");

  unless (ref($filter)) {
    $@ = "Can't do filtered import without a filter";
    return undef;
  }
  unless (defined($self->result)) {
    $@ = "Can't import before a successful run";
    return undef;
  }

  foreach my $var ($self->result->changed_keys) {
    my $type   = $self->result->changed_index($var)->type;
    my $newval = $self->result->changed_index($var)->value;
    next unless ($filter->($var, $newval, $type));

    $self->dprint(2, "Importing $type var $var=$newval\n");

    $self->_import_var($var, $newval, $type);

  }

  return $self->result;

}




#################
sub restore_env {
#################
  my $self = shift;

  $self->dprint(1, "Restoring environment\n");

  unless (defined($self->result)) {
    $@ = "Can't restore before a successful run";
    return undef;
  }

  # Delete all environment variables
  map(delete($ENV{$_}), keys %ENV);

  # Restore them from the result backup
  @ENV{$self->result->start_env_keys} = $self->result->start_env_values;

  return 1;

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




##############################################################################
########################### Private subroutines  #############################
##############################################################################



################
sub _get_shell {
################
  my $self      = shift;
  my $shellname = $self->shell;

  my $shellclass = join("::", ref($self), 'Shell', $shellname);

  $self->dprint(2, "Shell class: $shellclass\n");

  eval "use $shellclass;";
  return undef if ($@);

  my $shellobj;
  unless ($shellobj = $shellclass->new(debuglevel => $self->debuglevel)) {
    $@ = "Couldn't create shell object";
    return undef;
  }

  $self->shellobj($shellobj);

  return $shellobj;

}




#################
sub _import_var {
#################
  my $self   = shift;
  my $var    = shift;
  my $newval = shift;
  my $type   = shift;

  if ($type eq 'removed') {
    delete($ENV{$var});
  } else {
    $ENV{$var} = $newval;
  }
  $self->result->imported_push($var);
}






1;

__END__
=head1 NAME

Shell::EnvImporter - Perl extension for importing environment variable
changes from external commands or shell scripts

=head1 SYNOPSIS

  use Shell::EnvImporter;

  # Import environment variables exported from a shell script
  my $sourcer  = Shell::EnvImporter->new(
                   file => $filename,
                 );

  # Import environment variables exported from a shell command
  my $runner   = Shell::EnvImporter->new(
                   command => $shell_command,
                 );


  # Exert more control over the process
  my $importer = Shell::EnvImporter->new(
                   shell           => $shellname,

                   command         => $command,
                   # -- OR --
                   file            => $file,

                   auto_run        => 0, 
                   auto_import     => 0,

                   import_modified => 1,
                   import_added    => 1,
                   import_removed  => 1,
                   # -- OR --
                   import_filter   => $coderef
                 );

  my $result = $importer->run() or die "Run failed: $@";


  # Manual import by policy
  $importer->env_import();

  # -- OR --

  # Manual import by filter
  $importer->env_import_filtered();


  # Restore environment
  $importer->restore_env or die "Restore failed: $@";


=head1 DESCRIPTION

Shell::EnvImporter allows you to import environment variable changes
exported by an external script or command into the current environment.
The process happens in (up to) three stages:

=head3 Execution

 - saves a backup copy of the current environment (%ENV)

 - creates a shell script that sources the specified file (or runs the
   specified command) and prints out the environment

 - runs the shell script in a separate process

 - parses the output to determine success or failure and, on success,
   any changes to the environment

=head3 Importation

 - imports variable changes by policy or filter.  

=head3 Restoration

 - restores the environment (%ENV) to pre-run state


If 'auto_run' is true (the default), execution is kicked off automatically
by the constructor.  If 'auto_import' is true (the default), importation
is kicked off automatically after execution.  Restoration never happens
automatically; you must call the restore() method explicitly.


=head1 CONTROLLING IMPORTS

Imports are controlled by two factors:

  - the shell ignore list

  - the import policy or the import filter

The shell ignore list is a list of variables to ignore, maintained by
the shell object.  These are generally variables that are changed
automatically by the shell (e.g. SHLVL and PWD), providing little
information to a noninteractive shell.  The ignore list can be modified
using the shell object's B<ignore()> and B<ignore_*()> methods; see
the L<Shell::EnvImporter::Shell> documentation for details.  The ignore
list overrides the import policy or the import filter (whichever is in
effect).  

An import policy indicates what action to take for each kind of
environment change.  If B<import_added> is true, new variables added
to the environment will be imported.  If B<import_modified> is true,
variables whose value is changed will be imported.  If B<import_removed>
is true, variables unset by the external script or command will be
removed from the environment.  The default policy is to import added
and modified variables but not removed variables.

An import filter provides more control over importation.  The import
filter is a reference to a function that will be called with the
variable name, the new value, and the type of change ('added', 'modified'
or 'removed'); if it returns a true value, the variable will be imported.
The import filter, if provided, overrides the import policy.


=head1 CONSTRUCTOR

=over 4

=item B<new()>

  Create a new Shell::EnvImporter object.  Parameters are:

=item B<shell>

Name of the shell to use.  Currently supported: 'bash', 'csh', 'ksh', 'sh',
'tcsh', 'zsh', and of course, 'perl'.  :)

=item B<command>

Command to run in the language of the specified shell.  Overridden by
B<file>.

=item B<file>

File to be "sourced" by the specified shell.

=item B<auto_run>

If set to a true value (the default), Shell::EnvImporter will run the
shell command (or source the file) immediately, from the constructor.
Set to a false value to delay execution until B<run()> is called.

=item B<auto_import>

If set to a true value (the default), import the changed environment
immediately after running the command.  Set to a false value to delay
the import until B<import()> (or B<import_filtered()>) is called.

=item B<import_added>

=item B<import_modified>

=item B<import_removed>

Specify import policy. (See CONTROLLING IMPORTS above).

=item B<import_filter>

Use the supplied code ref to filter imports.  Overrides import policy
settings. (See CONTROLLING IMPORTS above).

=back

=head1 METHODS

=over 4

=item B<run()>

=item B<run($command)>

Run the supplied command, or run the command (or source the file) supplied 
during construction, returning a Shell::EnvImporter::Result object or undef
with $@ set on error.  It is an error to call B<run()> without a command if
none was supplied in the constructor.

=item B<env_import()>

=item B<env_import($var)>

=item B<env_import(@vars)>

=item B<env_import(\@vars)>

Perform a policy import (see CONTROLLING IMPORTS above).  If an optional
list (or array reference) of variable names is supplied, the import is 
restricted to those variables (subject to import policy).  Returns a
Shell::EnvImporter::Result object or undef with $@ set on error.

=item B<env_import_filtered()>

=item B<env_import_filtered(\&filter)>

Perform a filtered import (see CONTROLLING IMPORTS above), returning a
Shell::EnvImporter::Result object or undef with $@ set on error.  If no
filter is supplied, the filter supplied to the constructor is used.  It
is an error to call B<env_import_filtered()> without a filter if none
was supplied in the constructor.

=item B<restore_env()>

Restores the current environment (%ENV) to its state before shell script
execution.  It is an error to call restore_env before a successful run.

=back

=head1 DATA MEMBERS

=over 4

=item B<result()>

Returns the importer's Shell::EnvImporter::Result object.

=item B<shellobj()>

Returns the importer's Shell::EnvImporter::Shell object.

=back

=head1 EXAMPLES

=head2 - Command Import

    # Import environment variables set by a shell command
    my $importer = Shell::EnvImporter->new(
                     command => 'ssh-agent'
                   ) or die $@;

=head2 - "Sourced" File Import


    # Import environment variables exported by a configuration file
    my $importer = Shell::EnvImporter->new(
                     file => "$ENV{'HOME'}/.profile"
                   ) or die $@;


=head2 - Policy import - modified only, bash script

    my $importer = Shell::EnvImporter->new(
                     file            => '/etc/bashrc',
                     shell           => 'bash',
                     import_modified => 1,
                     import_added    => 0,
                     import_removed  => 0,
                   );


=head2 - Import a specific variable

    my $file     = '/etc/mydaemon.conf';
    my $importer = Shell::EnvImporter->new(
                     file            => $file,
                     shell           => 'bash',
                     auto_import     => 0,
                   );

    my $result = $importer->env_import('MAX_CLIENTS');

    if ($result->succeeded) {
      print "Max clients: $ENV{'MAX_CLIENTS'}\n";
    } else {
      die("Error:  Source of '$file' failed: ", $result->stderr, "\n");
    }


=head2 - Filtered import - all 'DB*' vars whose value references my homedir

    my $file     = '/etc/mydaemon.conf';

    my $filter = sub {
      my($var, $value, $change) = @_;

      return ($var =~ /^DB/ and $value =~ /$ENV{HOME}/);
    };

    my $importer = Shell::EnvImporter->new(
                     file            => $file,
                     shell           => 'bash',
                     import_filter   => $filter,
                   );

    print "Imported:  ", join(", ", $importer->result->imported), "\n";


=head2 - Unexported Variables in Bourne-like shells

    # Get the default system font from /etc/sysconfig/i18n (a /bin/sh
    # script).  Note that the variable is NOT exported, only set, so we
    # use the 'set' command to print the environment.

    my $sourcer  = Shell::EnvImporter->new(
                     file => '/etc/sysconfig/i18n',
                   ) or die $@;

    $sourcer->shellobj->envcmd('set');

    $sourcer->run();

    print "System font: $ENV{SYSFONT}\n";




=head1 SEE ALSO

L<Shell::EnvImporter::Result> L<Shell::EnvImporter::Shell>

=head1 AUTHOR

David Faraldo, E<lt>dfaraldo@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

  Copyright (C) 2005-2006 by Dave Faraldo

  This library is free software; you can redistribute it and/or modify it
  under the same terms as Perl itself.  No warranty is expressed or implied.



=cut
