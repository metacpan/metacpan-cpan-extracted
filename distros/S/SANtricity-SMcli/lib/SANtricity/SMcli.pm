package SANtricity::SMcli;
# $Id: SMcli.pm,v 1.6 2004/12/14 19:42:23 rbishop Exp $

use 5.008005;
use strict;
use warnings;
use File::Temp;

require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use SMcli ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	
);

our $VERSION = '0.02';


# Preloaded methods go here.

sub new {
  my $invocant = shift;
  my $class = ref($invocant) || $invocant;
  my $self = { debug => 0,
               pass => '',
               @_ };
  bless ($self,$class);
  return $self;
}


###############################################################
# Method: arrayStatus                                         #
#                                                             #
# Queries storage array status                                #
# Returns: 0 if array is OK                                   #
#          Array reference to output if a problem is detected #
###############################################################
sub arrayStatus {
  my $self = shift;

  my @output = $self->runCmd('show storageArray healthStatus');
  foreach my $line (@output) {
    if ($line =~ /^Storage array health status = (.+)\.$/) {
      return 0;
    }
  }
  return \@output;
}



##########################################################
# Method: checkVol                                       #
#                                                        #
# Gets information on a volume                           #
# Args: Volume to check                                  #
#                                                        #
# Returns: Hash ref with all volume information returned #
##########################################################
sub checkVol {
  my $self = shift;

  my $vol=shift;
  $vol=cleanInput($vol);
  my %results;
  foreach my $line ($self->runCmd("show volumes volume[\"$vol\"]")) {
    next if ($line =~ /^$/ || $line =~ /^VOLUME DETAILS$/);

    my ($key,$value)= $line =~ /^\s+([^:]+): (.+)$/;
    $results{$key}=$value;


  }
  return \%results;
}

#################################################################
# Method: showController                                        #
#                                                               #
# Shows controller information                                  #
# Args: Optional hash containing: controller => (a | b) or      #
#                                 allControllers => 1 (default) #
#                                 summary => 1                  #
# Returns: Array reference containing command output            #
#################################################################
sub showController {
  my $self = shift;

  my %args=@_;
  my $cmd;
  if (%args) {
    if ($args{controller}) {
      $cmd = " controller [ ". cleanInput($args{controller}) ." ]";
    } else {
      $cmd = " allControllers";
    }
    $cmd .= " summary" if ($args{summary});
  } else {
    $cmd = " allControllers";
  }

  my @output = $self->runCmd("show $cmd");
  foreach my $line (@output) {
    if ($line =~ /^Storage array health status = (.+)\.$/) {
      return 0;
    }
  }
  return \@output;
}


##################################################################################################
# Method: getEvents                                                                              #
#                                                                                                #
# Gets storage array events                                                                      #
# Args: (optional) hash containing eventType: all or critical (defaults to all)                  #
#                                  count:     number of events to get (don't specify to get all) #
# Returns: File::Temp object of the tempfile containing the event log                            #
##################################################################################################
sub getEvents {
  my $self = shift;

  my %args = @_;
  my $type = defined $args{eventType} ? cleanInput($args{eventType}) : "all";
  my $count = defined $args{count} ? "count=". cleanInput($args{count}) : '';
  my $file = new File::Temp;
  my $cmd = "save storageArray ${type}Events file=\"". $file->filename ."\" $count";
  foreach my $line ($self->runCmd($cmd)) {
    next if ($line =~ /^$/);
    warn "Unexpected output in downloading events on Array $self->{array}";
    return 0;
  }
  return $file;
}



##################################################################################################
# Method: getConfig                                                                              #
#                                                                                                #
# Gets storage array configuration                                                               #
# Args: (optional) hash containing any of the following keys:                                    #
#                    globalSettings, volumeConfigAndSettings, hostTopology, lunMappings          #
#                                                                                                #
# Returns: File::Temp object of the tempfile containing the event log                            #
##################################################################################################
sub getConfig {
  my $self = shift;

  my %args = @_;
  my $opts;

  if (%args) {
    foreach my $option qw(globalSettings volumeConfigAndSettings hostTopology lunMappings) {
      $opts .= " $option=";
      $opts .= $args{$option} ? "TRUE" : "FALSE";
    }
  } else {
    $opts=" allConfig";
  }

  my $file = new File::Temp;
  my $cmd = "save storageArray configuration file=\"". $file->filename ."\" $opts";
  foreach my $line ($self->runCmd($cmd)) {
    next if ($line =~ /^$/);
    warn "Unexpected output in downloading configuration on Array $self->{array}";
    return 0;
  }
  return $file;
}




#########################################################################################
# Method: monitorPerformance                                                            #
#                                                                                       #
# Monitor's array performance & returns stats                                           #
# Args: Optional Hash containing: interval - seconds between data capture (default: 5)  #
#                                 iterations - # of data points to collect (default: 5) #
# Returns: File::Temp object to file containing performance data                        #
#########################################################################################
sub monitorPerformance {
  my $self = shift;
  my %args = @_;

  my $cmd;
  if (%args) {
    my $int = defined $args{interval} ? $args{interval} : 5;
    $int = $int =~ tr/0-9//cd;

    my $iter = defined $args{iterations} ? $args{iterations} : 5;
    $iter = $iter =~ tr/0-9//cd;

    $cmd = "set session performanceMonitorInterval=$int performanceMonitorIterations=$iter ; ";
  }
  my $file = new File::Temp;
  $cmd .= "save storageArray performanceStats file=\"". $file->filename ."\"";
  foreach my $line ($self->runCmd($cmd)) {
    next if ($line =~ /^$/);
    warn "Unexpected output in downloading configuration on Array $self->{array}";
    return 0;
  }
  return $file;
}





#####################################
# Method: stopSnap                  #
#                                   #
# Stops (suspends) a snapshot       #
# Args: Snapshot to stop            #
# Returns: 0 if snapshot stopped OK #
#          1 if problem detected    #
#####################################
sub stopSnap {
  my $self = shift;

  my $vol=shift;
  $vol=cleanInput($vol);
  foreach my $line ($self->runCmd("stop snapshot volume [\"$vol\"]")) {
    next if ($line =~ /^$/);
    warn "Unexpected output in stopping snapshot $vol on Array $self->{array}";
    return 1;
  }

  return 0;
}



#######################################
# Method: recreateSnap                #
#                                     #
# Recreates a snapshot                #
# Args: Snapshot to recreate          #
# Returns: 0 if snapshot recreated OK #
#          1 if problem detected      #
#######################################
sub recreateSnap {
  my $self = shift;

  my $vol=shift;
  $vol=cleanInput($vol);
  foreach my $line ($self->runCmd("recreate snapshot volume [\"$vol\"]")) {
    next if ($line =~ /^$/);
    warn "Unexpected output in recreating snapshot $vol on Array $self->{array}";
    return 1;
  }

  return 0;
}



#########################################################
# Method: suspendRVM                                    #
#                                                       #
# Suspends an RVM mirror (must be run on primary array) #
# Args: Primary side of mirror to the suspended         #
# Returns: 0 if successful                               #
#          1 if problem detected                        #
#########################################################
sub suspendRVM {
  my $self = shift;

  my $vol=shift;
  $vol=cleanInput($vol);
  foreach my $line ($self->runCmd("suspend remoteMirror primary [\"$vol\"]")) {
    next if ($line =~ /^$/);
    warn "Unexpected output in suspending RVM  mirror $vol on Array $self->{array}";
    return 1;
  }

  return 0;
}




########################################################
# Method: resumeRVM                                    #
#                                                      #
# Resumes an RVM mirror (must be run on primary array) #
# Args: Primary side of mirror to the resumed          #
# Returns: 0 if successful                              #
#          1 if problem detected                       #
########################################################
sub resumeRVM {
  my $self = shift;

  my $vol=shift;
  foreach my $line ($self->runCmd("resume remoteMirror primary [\"$vol\"]")) {
    next if ($line =~ /^$/);
    warn "Unexpected output in resuming RVM mirror $vol on Array $self->{array}";
    return 1;
  }

  return 0;
}




#########################################################
# Method: runCmd                                        #
#                                                       #
# Builds and runs an SMcli command                      #
# Args: smcli string to run                             #
#                                                       #
# Returns: Array containing all SMcli output            #
# This should not be called from outside of this module #
#########################################################
sub runCmd {
  my $self=shift;

  my $smcli_string=shift;
  my $cmd = "SMcli -n $self->{array} ";
  $cmd .= "-p $self->{pass} " if ($self->{pass});
  $cmd .= "-c '$smcli_string;'";

  print "$cmd\n" if ($self->{debug});


  open SMCLI,"$cmd 2>&1 |" or die "Can't run SMcli: $!";
  my (@return,$data);
  while (<SMCLI>) {
    print $_ if ($self->{debug});
    $data = 0 if (/Script execution complete.$/);
    push @return,$_ if ($data);
    warn "SMcli error" if (/^SMcli failed.$/);
    $data=1 if (/^Executing script...$/);
  }
  close SMCLI;

  return @return;
}



############################################################################
# Method: cleanInput                                                       #
#                                                                          #
# Makes a stab at cleaning up input before it's passed to the command line #
# Args: String to clean                                                    #
#                                                                          #
# Returns: Cleaned string                                                  #
############################################################################
sub cleanInput {
  my $string=shift;
  $string =~ tr/-_+A-Za-z0-9//cd;
  return $string;
}

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME


SANtricity::SMcli - Perl extension to manipulate SAN controllers using SANtricity
Command Line

=head1 SYNOPSIS

  use SANtricity::SMcli;

  my $array = SANtricity::SMcli->new(array => "MyArray");

  # Check array status
  my $status = $array->arrayStatus;
  if ($status != 0) {
    print @$status;
  }

  # Get information on a volume
  my $volStatus = $array->checkVol("MYVOLUME");
  foreach my $key (keys %$volStatus) {
    print "$key -> ${$volStatus}{$key}\n";
  }

  # Print the 5 most recent events
  my $fh = $array->getEvents(eventType=>'all',
                             count=>5);
  while(<$fh>) {
    print ;
  }


  # Stop & Recreate a snapshot
  if ($array->stopSnap("MYSNAP") != 0) {
    die "Failed to stop snapshot";
  }

  if ($array->recreateSnap("MYSNAP") != 0) {
    die "Failed to recreate snapshot";
  }




=head1 DESCRIPTION

SANtricity::SMcli is a perl interface to Engenio's SMcli. It has been developed
with Santricity version 9.1 on Linux - it will probably work on any
Unix system (and maybe windows), but some functions probably won't
work with other versions of Santricity due to syntax changes. It
currently offers a fairly small number of commands, which may be
expanded as time and motivation allow.

All methods given here run the SMcli binary, so you need the correct permissions
(or be root). Obviously it's quite possible to break your array configuration
using the command line and therefore with this module. Things seem to work OK for
me but there's no guarantee.

=head2 CONSTRUCTOR

new(array => 'ARRAYNAME', OPTIONS)
    Creates a new SANtricity::SMcli object. ARRAYNAME is the name of 
    the storage array (SMcli -d shows all defined arrays).

    OPTIONS can be:

    pass => 'PASSWORD'
          Use a password.

    debug => 1
          Enable some debugging output in the SMcli calls.

=head2 METHODS

    arrayStatus()
          Checks the overall status of the array. Returns 0 if the
          array is OK, otherwise an array reference to the output from
          the SMcli command.


    checkVol("VOLNAME")
          Checks the status of volume VOLNAME. Returns a hash reference
          containing all the volume information (which varies by volume
          type).


    getConfig( ARGS )
          Get storage array config. If no args are specified this is run
          with the SMcli allConfig option. To specify the data to get set
          any of the following hash keys to 1:
               globalSettings, volumeConfigAndSettings, hostTopology, lunMappings

          Returns a File::Temp object of the file containing the config data


    getEvents( ARGS )
          Get information from the array event log. Optional arguments are:
               eventType => all | critical (defaults to all)
               count     => n              (# of events to get, omit to
                                            get all)

          Returns a File::Temp object of the file containing the event log
          data.


    monitorPerformance( ARGS )
          Get array performance statistics. Optional arguments are:
               interval   => n (seconds between data capture, defaults to 5)
               iterations => n (# of iterations, defaults to 5)

          Returns a File::Temp object of the file containing the performance
          data.


    recreateSnap("SNAPNAME")
          Recreates a previously stopped snapshot. Argument is snapshot
          name, returns 0 if successful, otherwise 1.


    resumeRVM("PRIMARY-NAME")
          Resumes a previously suspended RVM remote mirror. This command 
          must be run on the primary array. Argument is name of RVM
          primary, returns 0 if successful, otherwise 1.


    showController( ARGS )
          Gets information on array controllers. Optional args are:
               controller     => a | b (Controller to report on) OR
               allControllers => 1     (All controllers - default)
               summary        => 1     (Summary mode - off by default)

          Returns an array reference containing the command output.


    stopSnap("SNAPNAME")
          Stops a snapshot. Argument is snapshot name, returns 0 if
          successful, otherwise 1.


    suspendRVM("PRIMARY-NAME")
          Suspends an RVM remote mirror. This command must be run on the
          primary array. Argument is name of RVM primary, returns 0 if
          successful, otherwise 1.


=head2 EXPORT

None by default.



=head1 SEE ALSO

Online help for Script Editor & CLI Usage in the Santricity Enterprise
Management window.


=head1 AUTHOR

Rich Bishop, E<lt>rjb@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2004 by Rich Bishop

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.5 or,
at your option, any later version of Perl 5 you may have available.


=cut

