$VERSION = '1.01';

package TapeChanger::MTX;
# -*- Perl -*- Fri Jan 16 11:07:17 CST 2004 
###############################################################################
# Written by Tim Skirvin <tskirvin@ks.uiuc.edu>
# Copyright 2001-2004, Tim Skirvin and UIUC Board of Trustees.  
# Redistribution terms are below.
###############################################################################
my $VERSION = '1.01';

=head1 NAME 

TapeChanger::MTX - use 'mtx' to manipulate a tape library

=head1 SYNOPSIS

  use TapeChanger::MTX;

  my $loaded = TapeChanger::MTX->loadedtape;
  print "Currently loaded: $loaded\n" if ($loaded);

  TapeChanger::MTX->loadtape('next');
  my $nowloaded = TapeChanger::MTX->loadedtape; 
  print "Currently loaded: $nowloaded\n" if ($nowloaded);
   
See below for more available functions.

=head1 DESCRIPTION

TapeChanger::MTX is a module to manipulate a tape library using the 'mtx' 
tape library program.  It is meant to work with a simple shell/perl script
to load and unload tapes as appropriate, and to provide a interface for
more complicated programs to do the same.  The below functions and
variables should do as good a job as explaining this as anything.

=cut

###############################################################################
### Initialization ############################################################
###############################################################################

require 5.6.0;
use strict;

###############################################################################
### Variables #################################################################
###############################################################################

=head1 VARIABLES

=over 4

=cut
                                         
use vars qw( $MTX $DRIVE $CONTROL $MT $EJECT $READY_TIME $DEBUG );

=item $TapeChanger::MTX::MT
=item $TapeChanger::MTX::MTX 

What is the location of the 'mt' and 'mtx' binaries?  Can be set with
'$MT' and '$MTX' in ~/.mtxrc, or defaults to '/usr/sbin/mt' and
'/usr/local/sbin/mtx'.

=cut

$MT      = "/usr/bin/mt";
$MTX     = "/usr/local/sbin/mtx";

=item $TapeChanger::MTX::DRIVE

=item $TapeChanger::MTX::CONTROL

What are the names of the tape (DRIVE) and changer (CONTROL) device
nodes?  Can be set with $DRIVE or $CONTROL in ~/.mtxrc, or default to
'/dev/rmt/0' and '/dev/changer' respectively.

=cut

$DRIVE   = "/dev/rmt/0";
$CONTROL = "/dev/changer";

=item $TapeChanger::MTX::EJECT

Does the tape drive have to eject the tape before the changer retrieves
it?  It's okay to say 'yes' if it's not necessary, in most cases.  Can be
set with $EJECT in ~/.mtxrc, or defaults to '1'.

=cut

$EJECT   = 1;

=item $TapeChanger::MTX::READY_TIME

How long should we wait to see if the drive is ready, in seconds, after
mounting a volume?  Can be set with $READY_TIME in ~/.mtxrc, or defaults
to 60.

=cut

$READY_TIME = 60;

=item $TapeChanger::MTX::DEBUG 

Print debugging information?  Set to '0' for normal verbosity, '1' for
debugging information, or '-1' for 'quiet mode' (be as quiet as possible).

=back

=cut

$DEBUG     = 0;

###############################################################################
### Internal Variables ########################################################
###############################################################################

## Define where .mtxrc actually is.  Doesn't get edited locally, so I'm not 
our $MTXRC     = "$ENV{HOME}/.mtxrc";	

## Default value for the internal "@RETURN".  
our @RETURN = ('');

###############################################################################
### Functions #################################################################
###############################################################################

=head1 USAGE 

This module uses the following functions:

=over 4

=cut

=item tape_cmd ( COMMAND )

=item mt_cmd ( COMMAND )

Runs 'mtx' and 'mt' as appropriate.  C<COMMAND> is the command you're
trying to send to them.  Uses 'warn()' to print the commands to the screen
if $TapeChanger::MTX::DEBUG is set.

=cut

sub tape_cmd { shift->_run("$MTX -f $CONTROL @_") }
sub mt_cmd   { shift->_run("$MT -f $DRIVE @_") }

### _run( STRING )
# Actually does the work of 'tape_cmd' and 'mt_cmd'.  Just runs the
# command that's supposed to be run.  Puts the return text into @RETURN 
# for future reference.  

sub _run {
  my ($self, $string) = @_;
  warn "$string\n" if debug();
  my @return;  
  my $return = open (CMD, "$string 2>&1 |") or
                        (warn "Couldn't run $string: $!\n" and return undef);
  if (debug()) { foreach (<CMD>) { print; chomp; push @return, $_ } } 
  else         { @return = <CMD>; chomp @return; }
  close(CMD);
  @RETURN = @return || ('');
  wantarray ? @return : join("\n", @return);
}

=item numdrives ()

=item numslots ()

=item loadedtape ()

=item numloaded ()

=item nummailslots ()

Returns the number of drives, number of slots, currently loaded tape,
number of loaded tapes, and number of Import/Export slots, respectively,
by parsing B<tape_cmd('status')>.  Not all of these will apply to all tape
drives.

=cut

sub numdrives    { (shift->_getchangerparms)[0] || 0 }
sub numslots     { (shift->_getchangerparms)[1] || 0 }
sub loadedtape   { (shift->_getchangerparms)[2] || 0 }
sub numloaded    { (shift->_getchangerparms)[3] || 0 }
sub nummailslots { (shift->_getchangerparms)[4] || 0 }

### _getchangerparms ()
# Does the work for the above functions.
sub _getchangerparms {
  my ($self) = @_;
  my @status = split("\n", $self->tape_cmd('status'));
  unless ($? eq 0) { return (0, 0, 0, 0, 0) }
  
  my ($numdrives, $numslots, $loadedtape, $numloaded, $mailslots) = 0;
  foreach (@status) 
   {
    if (/^Data Transfer Element/) 
       { 
       $numdrives++;
       if (/\(Storage Element (\d+) Loaded\).*$/) 
         { $loadedtape = $1, $numloaded ++ };
       }
    else
       { 
       if (/^\s*Storage Element \d+/) { $numslots++ };
       if (/^\s*Storage Element \d+ IMPORT\/EXPORT:/) { $mailslots++ };
       };
   }
  ($numdrives, $numslots, $loadedtape, $numloaded, $mailslots);
}

=item slothash ()

Returns a hash table (not hashref) of information about each slot.  The
keys of the hash are the slot numbers, and the values are arrayrefs that
contain three fields: 
  
  SlotType	"Import/Export" or empty string
  Full		"Full" or "Empty"
  VolumeTag	Tape barcode, if it exists

=cut

sub slothash {
  my $self = shift;
  my %slots;
  my @status = split("\n", $self->tape_cmd('status'));
  my @slot;
  unless ($? eq 0) { return undef }
  foreach (@status) {
    if (/^\s*Storage Element (\d+)(\s([^:]*))*:([^(:|\s)]*)\s*(:VolumeTag=([^\s]*))*.*/) {
    # $1-slot number, $3-slot type, $4-Full or Empty, $6 Volume tag if exist
    @slot=($3,$4,$6);
    $slots{$1}=[@slot]
    }
  }
 %slots;
}

=item drivehash ()

As with B<slothash>, but looks at the drives instead of the slots.

=cut

sub drivehash()
{
  my ($self) = shift;
  my %drives;
  my @status = split("\n", $self->tape_cmd('status'));
  my @drive;
  unless ($? eq 0) { return undef }
  foreach (@status) {
    if (/Data Transfer Element (\d+):([^\s|\(]*)(\s*\(Storage Element (\d+) Loaded\))*(:VolumeTag = ([^\s]*))*.*/) {
      # $1-drive number, $2-Full, $4-Element loaded ,$6-VolumeTag
      @drive=($2,$4,$6);
      $drives{$1}=[@drive];
    }
  }
 %drives;
}

=item loadtape ( SLOT [, DRIVE] )

Loads a tape into the tape changer, and waits until the drive is again
ready to be written to.  C<SLOT> can be any of the following (with the
relevant function indicated):

  current	C<loadedtape()>
  prev		C<loadprevtape()>
  next 		C<loadnexttape()>
  first		C<loadfirsttape()>
  last		C<loadlasttape()>
  0		C<_ejectdrive()>
  1..99		Loads the specified tape number, ejecting whatever is
		currently in the drive.

C<DRIVE> is the drive to load, and defaults to 0.  Returns 0 if
successful, an error string otherwise.

=cut

sub loadtape {
  my ($self, $slot, $drive) = @_;	$drive ||= 0;
  
  if    (lc $slot eq 'current') { $self->loadedtape } 
  elsif (lc $slot eq 'prev')    { $self->loadprevtape($drive) }
  elsif (lc $slot eq 'next')    { $self->loadnexttape($drive) } 
  elsif (lc $slot eq 'first')   { $self->loadfirsttape($drive) }
  elsif (lc $slot eq 'last')    { $self->loadlasttape($drive) }
  elsif (lc $slot =~ /^(\d+)$/) { $self->_doloadtape($1, $drive) }
  else { return "No valid slot specified" }

  $self->checkdrive || return "Drive wouldn't report ready: @RETURN\n";
}

### _doloadtape( SLOT, DRIVE )
# Does the actual work for loading tapes, when it's not done by mtx itself.
sub _doloadtape {
  my ($self, $slot, $drive) = @_;  $slot ||= 0;
  my $loaded = $self->loadedtape || 0;
  return 1 if ($slot eq $loaded);
  if ($loaded) { $self->_ejectdrive && $self->tape_cmd('unload') }
  $loaded = $self->loadedtape || 0;
  return "Couldn't unload tape $loaded" if $loaded;
  $slot ? $self->tape_cmd('load', $slot, $drive) : "No slot to load";
}

=item loadnexttape ()

=item loadprevtape ()

=item loadfirsttape ()

=item loadlasttape ()

Loads the next, previous, first, and last tapes in the changer
respectively.  Use B<tape_cmd('next')>, B<tape_cmd('previous')>, 
B<tape_cmd('first')>, and B<tape_cmd('last')>, respectively.

=cut

sub loadnexttape  { 
  my $self = shift;
  $self->_ejectdrive();
  $self->tape_cmd('next',     @_) 
}
sub loadprevtape  { 
  my $self = shift;
  $self->_ejectdrive();
  $self->tape_cmd('previous', @_) 
}
sub loadfirsttape { 
  my $self = shift;
  $self->_ejectdrive();
  $self->tape_cmd('first',    @_) 
}
sub loadlasttape  { 
  my $self = shift;
  $self->_ejectdrive();
  $self->tape_cmd('last',     @_) 
}

=item transfertape ( FROM, TO )

Transfers a tape from slot C<FROM> to slot C<TO>.  Returns 0 on success.
Makes sure the necessary slots are empty/full as appropriate.

=cut

sub transfertape {
  my ($self, $from, $to) = @_;
  my %slots = $self->slothash;
  
  if ($slots{$from}[1] eq 'Empty') {
    print "Cannot transfer from Empty slot\n";
    return 1;
  }
  if ($slots{$to}[1] eq 'Full') {
    print "Cannot transfer to Full slot\n";
    return 1;
  }
  $self->tape_cmd('transfer', $from, $to);
}

=item tagtoslot ( TAG )

Returns the slot that the tape with volume tag C<TAG> is in, or '0' if
it's not in the tape changer.

=cut

sub tagtoslot {
  my ($self, $tag) = @_;
  chomp($tag);
  my @status = split("\n", $self->tape_cmd('status'));
  unless ($? eq 0) { return 0 }
   
  my $slot;
  foreach( @status ) {
    if (/^\s*Storage Element (\d+)[^:]*:Full :VolumeTag=$tag/) { $slot = $1 }
  }
  $slot || 0;
}

=item slottotag ( SLOT ) 

Returns the volume tag of the tape in slot C<SLOT>, or '' if there is no
tag or tape.

=cut

sub slottotag {
  my ($self, $slot) = @_;
    
  my @status = split("\n", $self->tape_cmd('status'));
  unless ($? eq 0) { return 0 }

  my $tag = "";
  foreach(@status) {
    if (/^\s*Storage Element $slot[^:]*:Full :VolumeTag=(.*)/) { $tag = $1 }
  }
  return $tag;
}

=item tagtodrive ( TAG ) 

Returns the drive that the tape with volume tag C<TAG> is in, or '-1' if
it's not in a drive.

=cut

sub tagtodrive {
  my ($self, $tag) = @_;

  chomp($tag);
  my @status = split("\n", $self->tape_cmd('status'));
  unless ($? eq 0) { return -1 }
  
  my $drive;
  foreach(@status) {
    if (/^Data Transfer Element (\d+):Full (Storage Element \d+ Loaded):VolumeTag = $tag/) { $drive=$1 }
  };
  return $drive || -1;
}

=item drivetotag ( DRIVE ) 

Returns the volume tag of the tape in drive C<DRIVE>, or '' if there is no
tag or tape.

=cut

sub drivetotag {
  my ($self, $drive) = @_;

  my @status = split("\n", $self->tape_cmd('status'));
  unless ($? eq 0) { return '' }

  my $tag;
  foreach (@status) {
    if (/^Data Transfer Element $drive:Full \(Storage Element \d+ Loaded\):VolumeTag = ([^\s]*)/) { $tag=$1 }
  }
  return $tag || "";
}

=item ejecttape ()

Ejects the tape, by first ejecting the tape from the drive
(B<mt_cmd(rewind)> then B<mt_cmd(offline)>) and then returning it to its
slot (B<tape_cmd(unload)>).  Returns 1 if successful, 0 otherwise.

=cut

sub ejecttape {
  my ($self, $drive) = @_;	$drive ||= 0;
  my ($drives, $slots, $loaded) = $self->_getchangerparms;
  if ($loaded) {
    $self->_ejectdrive($drive);
    $self->tape_cmd('unload');   
    return $? ? 0 : 1;
  } else { return 1 }	# Already unloaded
}

### _ejectdrive ( [DRIVE] )
# Does the rewinding, and that's it
sub _ejectdrive {
  my ($self) = @_;
  my $loaded = $self->loadedtape;
  return 1 unless $loaded;
  if ($EJECT) { 
    $self->mt_cmd('rewind');
    if ($? ne 0) { 	# rewind failed
      return 0 if ($RETURN[0] !~ /no tape/);	# not because there was no tape
    }
    $self->mt_cmd('offline');
  } 
  1;
}

=item resetchanger ()

Resets the changer, ejecting the tape and loading the first one from the
changer.  

=cut

sub resetchanger {
  my ($self) = @_;
  $self->_ejectdrive;
  $self->loadtape('first');
}

=item checkdrive ()

Checks to see if the drive is ready or not, by waiting for up to 
$TapeChanger::MTX::READY_TIME seconds to see if it can get status
information using B<mt_cmd(status)>.  Returns 1 if so, 0 otherwise.

=cut

sub checkdrive {
  my ($self) = @_;
  my $start = time;	# We're using clock-seconds here
  while (time - $start < $READY_TIME) {	
    $self->mt_cmd('status');
    return 1 unless $?;
    sleep 1;
  }
  return 0;
}

=item reportstatus

Returns a string containing the loaded tape and the drive that it's
mounted on.

=cut

sub reportstatus { (shift->loadedtape || 'unloaded') . " $DRIVE" }

=item inventory ()

Runs a tape inventroy, if supported by the tape changer.  This works out
volume tags and such.

=cut

sub inventory  { shift->tape_cmd('inventory'); }


=item cannot_run ()

Does some quick checks to see if you're actually capable of using this
module, based on your user permissions.  Returns a list of problems if
there are any, 0 otherwise.

=cut

sub cannot_run {
  my @problems;

  unless (-x $MTX)     { push @problems, "Can't run $MTX" }
  unless (-x $MT)      { push @problems, "Can't run $MT" }
  unless (-r $DRIVE)   { push @problems, "Can't read from $DRIVE" }
  unless (-w $DRIVE)   { push @problems, "Can't write to $DRIVE" }
  unless (-r $CONTROL) { push @problems, "Can't read from $CONTROL" }
  unless (-w $CONTROL) { push @problems, "Can't write to $CONTROL" }
  
  return scalar @problems ? @problems : ();
}

=back

=cut

###############################################################################
### Internal Subroutines ######################################################
###############################################################################

sub doit { 
  my $file = shift || return undef;
  if (-f $file) { 
    my $return = do $file;
    unless ($return) {
      warn "couldn't parse $file: $@" if $@;
      warn "couldn't do $file: $!" unless defined $return;
      warn "couldn't run $file" unless $return;
    }
    $return;
  } else { return undef }
}

sub debug { $DEBUG > 0 ? 1 : 0 }
sub quiet { $DEBUG < 0 ? 1 : 0 }

###############################################################################
### main() ####################################################################
###############################################################################

doit($MTXRC);		# Override the defaults with what's in $MTXRC
1;

=head1 NOTES

~/.mtxrc is automatically loaded when this module is used, if it exists,
using do().  This could cause security problems if you're trying to use
this with setuid() programs - so just don't do that.  If you want someone
to have permission to mess with the tape drive and/or changer, let them
have that permission directly.

=head1 REQUIREMENTS

Perl 5.6.0 or better, an installed 'mtx' binary, and a tape changer and
reader connected to the system.  

=head1 TODO

Theoretically allows multiple drives per changer and I/E slots, but I
haven't tested it, so I may have missed something.  'load previous'
doesn't actually work, because mtx doesn't support it (though the help
says it does).

=head1 SEE ALSO

B<mtx>, B<mt>, B<tapechanger>.  Inspired by B<stc-changer>, which comes
with the AMANDA tape backup package (http://www.amanda.org), and MTX,
available at http://mtx.sourceforge.net.

=head1 AUTHOR

Tim Skirvin <tskirvin@uiuc.edu>.  

=head1 THANKS TO...

Code for multi-slot tape drives and volume tags from Hubert Mikulicz
<hmikulicz@hotmail.com>.

=head1 LICENSE

This code is distributed under the University of Illinois Open Source
License.  See
C<http://www.ks.uiuc.edu/Development/MDTools/tapechanger-mtx/license.html> for
details.

=head1 COPYRIGHT

Copyright 2001-2004 by the University of Illinois Board of Trustees and 
Tim Skirvin <tskirvin@ks.uiuc.edu>.

=cut

##### Version History
# v0.5b 	Fri Nov  9 15:39:15 CST 2001
### Initial version, based off old mtx-changer code (also self-written).
### Documentation and such are written.
# v0.51b 	Tue Nov 13 09:16:49 CST 2001
### Took out support for multiple drives in the 'eject' option, because it 
### operates weirdly.  'reportstatus' is a bit different.
# v0.60b	Tue Nov 13 16:00:29 CST 2001
### Fixed 'nexttape' and such to eject the drive first.  
# v0.61b	Fri Dec 14 15:22:25 CST 2001
### Took out 'eject from drive #' from eject(), because it didn't work.
# v0.70b	Fri Feb  1 13:13:08 CST 2002
### Fixed _doloadtape() to eject the tape first.
# v0.71b	Fri Feb  1 13:38:13 CST 2002
### Changed _doloadtape() again to check the return status
# v1.00		Fri Jan 16 11:07:23 CST 2004 
### Might as well make this v1.0 some time.  Added a fair bit of contributed 
### code to support multi-slot tape drives and volume tags.
# v1.01		Mon Mar 01 16:57:54 CST 2004 
### Doesn't echo STDERR in _run() anymore, which makes things look
### cleaner, unless we're debugging.
