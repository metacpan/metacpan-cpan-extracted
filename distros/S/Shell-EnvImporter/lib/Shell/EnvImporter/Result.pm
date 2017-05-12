package Shell::EnvImporter::Result;

use strict;
use warnings;
no warnings 'uninitialized';

use Shell::EnvImporter::Change;

use Class::MethodMaker 2.0 [
    new     => [qw(-hash -init new)],
    scalar  => [qw(
      shell_status
      command_status
      env_status

      shell_output
      command_output
      stderr
    )],
    array  => [qw(
      imported
    )],
    hash  => [qw(
      start_env

      changed
    )],
  ];

use constant DEFAULTS => (
  shell_status    => -255,
  command_status  => -255,
  env_status      => -255,
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

  # Copy the environment when constructed
  $self->_copy_env;


}


############
sub failed {
############
  my $self = shift;

  return $self->shell_status ||
         $self->command_status ||
         $self->env_status;

}


###############
sub succeeded {
###############
  my $self = shift;

  return $self->shell_status   == 0 and
         $self->command_status == 0 and
         $self->env_status     == 0;

}





##############################################################################
########################### Private subroutines  #############################
##############################################################################


###############
sub _copy_env {
###############
  my $self = shift;

  my %envbak;
  @envbak{keys %ENV} = values %ENV;
  
  $self->start_env(%envbak);

}




1;


__END__
=head1 NAME

package Shell::EnvImporter::Result - Results of a Shell::EnvImporter run

=head1 SYNOPSIS

  use Shell::EnvImporter;

  my $sourcer = Shell::EnvImporter->new(
                  command  => $command,
                ) or die "$@";


  my $result = $sourcer->result;

  if ($result->succeeded()) {

    print "Variables imported:  ", join(", ", $result->imported), "\n";

  } else {

    print "Command failed! with ", $result->command_status, " status\n";
    print "STDERR:  ", $result->stderr, "\n";

  }




=head1 DESCRIPTION

Shell::EnvImporter allows you to import environment variable changes
exported by an external script or command into the current environment.
The Shell::EnvImporter::Shell object provides more control over
interaction with the shell.

=head1 METHODS

=over 4

=item B<failed()>

Summary status.  Returns true if any of the shell status, user command
status, or 'env' command status are nonzero, and returns false
otherwise.  

=item B<succeeded()>

Summary status.  Returns true if the shell status, user command status,
and 'env' command status are all zero, and returns false otherwise.  

=back


=head1 DATA MEMBERS

=over 4

=item B<shell_status()>

Status of the shell - zero if the shell was successfully spawned, nonzero
otherwise.

=item B<shell_output()>

Output produced by the shell when spawning (e.g. output from startup
scripts).


=item B<command_status()>

Status of the user command.

=item B<command_output()>

Output produced by the user command.


=item B<env_status()>

Status of the 'env' command.


=item B<stderr()>

Standard error output produced by the shell, the user command, and/or the
'env' command.


=item B<imported()>

List of variables imported by the shell.


=head1 AUTHOR

David Faraldo, E<lt>dfaraldo@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

  Copyright (C) 2005-2006 by Dave Faraldo

  This library is free software; you can redistribute it and/or modify it
  under the same terms as Perl itself.  No warranty is expressed or implied.


=cut
