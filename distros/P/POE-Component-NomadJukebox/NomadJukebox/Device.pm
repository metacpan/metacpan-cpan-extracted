package POE::Component::NomadJukebox::Device;

use 5.006;
use strict;
use warnings;
use Errno;
use Carp;

require Exporter;
require DynaLoader;
use AutoLoader;

our $VERSION = '0.03';

our @ISA = qw(Exporter DynaLoader);

# This allows declaration use POE::Component::NomadJukebox::Device ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	DD_BSDKDEBUG
	DD_SUBTRACE
	DD_USBBLK
	DD_USBBLKLIM
	DD_USBCTL
	
	EO_ABORTED
	EO_AGAIN
	EO_BADCOUNT
	EO_BADDATA
	EO_BADNJBID
	EO_BADSTATUS
	EO_CANTMOVE
	EO_DEVICE
	EO_EOF
	EO_EOM
	EO_INIT
	EO_INVALID
	EO_NOMEM
	EO_NULLTMP
	EO_RDSHORT
	EO_SRCFILE
	EO_TIMEOUT
	EO_TMPFILE
	EO_TOOBIG
	EO_USBBLK
	EO_USBCTL
	EO_WRFILE
	EO_WRSHORT
	EO_XFERDENIED
	EO_XFERERROR
	
	ID_DATA_ASCII
	ID_DATA_BIN
	LIBNJB_COMPILED_FOR_LIBUSB
	NJB_Get_File
	NJB_MAX_DEVICES
	
	NJB_PL_CHNAME
	NJB_PL_CHTRACKS
	NJB_PL_END
	NJB_PL_NEW
	NJB_PL_START
	NJB_PL_UNCHANGED
	
	NJB_POWER_AC_CHARGED
	NJB_POWER_AC_CHARGING
	NJB_POWER_BATTERY
	OWNER_STRING_LENGTH
	
	NJB_DEVICE_NJB1
	NJB_DEVICE_NJB2
	NJB_DEVICE_NJB3
	NJB_DEVICE_NJBZEN
	NJB_DEVICE_NJBZEN2
	NJB_DEVICE_NJBZENNX
	NJB_DEVICE_NJBZENXTRA
	NJB_DEVICE_DELLDJ
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	Discover
	Open
	TrackList
	PlayList
	FileList
	DeletePlayList
	GetTrack
	SendTrack
	SendFile
	PlayTrack
	QueueTrack
	DeleteTrack
	DeleteFile
	StopPlay
	PausePlay
	ResumePlay
	SeekTrack
	AdjustSound
	GetOwner
	SetOwner
	GetTmpDir
	SetTmpDir
	DiskUsage
	Close
	ProgressFunc	
	
	DD_BSDKDEBUG
	DD_SUBTRACE
	DD_USBBLK
	DD_USBBLKLIM
	DD_USBCTL
	
	EO_ABORTED
	EO_AGAIN
	EO_BADCOUNT
	EO_BADDATA
	EO_BADNJBID
	EO_BADSTATUS
	EO_CANTMOVE
	EO_DEVICE
	EO_EOF
	EO_EOM
	EO_INIT
	EO_INVALID
	EO_NOMEM
	EO_NULLTMP
	EO_RDSHORT
	EO_SRCFILE
	EO_TIMEOUT
	EO_TMPFILE
	EO_TOOBIG
	EO_USBBLK
	EO_USBCTL
	EO_WRFILE
	EO_WRSHORT
	EO_XFERDENIED
	EO_XFERERROR
	
	ID_DATA_ASCII
	ID_DATA_BIN
	LIBNJB_COMPILED_FOR_LIBUSB
	NJB_Get_File
	NJB_MAX_DEVICES
	
	NJB_PL_CHNAME
	NJB_PL_CHTRACKS
	NJB_PL_END
	NJB_PL_NEW
	NJB_PL_START
	NJB_PL_UNCHANGED
	
	NJB_POWER_AC_CHARGED
	NJB_POWER_AC_CHARGING
	NJB_POWER_BATTERY
	OWNER_STRING_LENGTH
	
	NJB_DEVICE_NJB1
	NJB_DEVICE_NJB2
	NJB_DEVICE_NJB3
	NJB_DEVICE_NJBZEN
	NJB_DEVICE_NJBZEN2
	NJB_DEVICE_NJBZENNX
	NJB_DEVICE_NJBZENXTRA
	NJB_DEVICE_DELLDJ
);

sub AUTOLOAD {
	# This AUTOLOAD is used to 'autoload' constants from the constant()
	# XS function.  If a constant is not found then control is passed
	# to the AUTOLOAD in AutoLoader.

	my $constname;
	our $AUTOLOAD;
	($constname = $AUTOLOAD) =~ s/POE::Component::NomadJukebox::Device:://;
	croak "&$_[0] not defined in NomadJukebox::Device" if $constname eq 'constant';
	my $val = constant($constname, @_ ? $_[0] : 0);
	if ($! != 0) {
		if ($!{EINVAL}) {
		    $AutoLoader::AUTOLOAD = $AUTOLOAD;
		    goto &AutoLoader::AUTOLOAD;
		} else {
		    croak "Your vendor has not defined NomadJukebox::Device macro $constname";
		}
	}
	{
		no strict 'refs';
		# Fixed between 5.005_53 and 5.005_61
		if ($] >= 5.00561) {
		    *$AUTOLOAD = sub () { $val };
		} else {
		    *$AUTOLOAD = sub { $val };
		}
	}
	goto &$AUTOLOAD;
}

POE::Component::NomadJukebox::Device->bootstrap($VERSION);

# Preloaded methods go here.

# Autoload methods go after =cut, and are processed by the autosplit program.

# documentation to come later
1;
__END__

=head1 NAME

POE::Component::NomadJukebox::Device - perl api to libnjb

=head1 AUTHOR

David Davis, E<lt>xantus@cpan.orgE<gt>

=head1 TODO

Documentation ;)

=cut
