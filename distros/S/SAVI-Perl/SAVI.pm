#
# SAVI-Perl version 0.30
#
# Paul Henson <henson@acm.org>
#
# Copyright (c) 2002-2004 Paul Henson -- see COPYRIGHT file for details
#

package SAVI;

use strict;
use Carp;
use vars qw($VERSION @ISA @EXPORT $AUTOLOAD);

require Exporter;
require DynaLoader;
require AutoLoader;

@ISA = qw(Exporter DynaLoader);

@EXPORT = qw();

$VERSION = '0.30';

bootstrap SAVI $VERSION;

my %error_strings = (
    0x200 => "DLL failed to initialize",
    0x201 => "Error while unloading",
    0x202 => "Virus scan failed",
    0x203 => "A virus was detected",
    0x204 => "Attempt to use virus engine without initializing it",
    0x205 => "The installed version of SAVI is running an incompatible version of the InterCheck client",
    0x206 => "The process does not have sufficient rights to disable the InterCheck client",
    0x207 => "The InterCheck client could not be disabled - the request to scan the file has been denied",
    0x208 => "The disinfection failed",
    0x209 => "Disinfection was attempted on an uninfected file",
    0x20A => "An attempted upgrade to the virus engine failed",
    0x20B => "Sophos Anti Virus has been removed from this machine",
    0x20C => "Attempt to get/set SAVI configuration with incorrect name",
    0x20D => "Attempt to get/set SAVI configuration with incorrect type",
    0x20E => "Could not configure SAVI",
    0x20F => "Not supported in this SAVI implementation",
    0x210 => "File couldn't be accessed",
    0x211 => "File was compressed, but no virus was found on the outer level",
    0x212 => "File was encrypted",
    0x213 => "Additional virus location is unavailable",
    0x214 => "Attempt to initialize when already initialized",
    0x215 => "Attempt to use a stub library",
    0x216 => "Buffer supplied was too small",
    0x217 => "Returned from a callback function to continue with the current file",
    0x218 => "Returned from a callback function to skip to the next file",
    0x219 => "Returned from a callback function to stop the current operation",
    0x21A => "Sweep could not proceed, the file was corrupted",
    0x21B => "An attempt to re-enter SAVI from a callback notification was detected",
    0x21C => "An error was encountered in the SAVI client's callback function",
    0x21D => "A call requesting several pieces of information did not return them all",
    0x21E => "The main body of virus data is out of date",
    0x21F => "No valid temporary directory found",
    0x220 => "The main body of virus data is missing",
    0x221 => "The InterCheck client is active, and could not be disabled",
    0x222 => "The virus data main body has an invalid version",
    0x223 => "SAVI must be reinitialised - the virus engine has a version higher than the running version of SAVI supports",
    0x224 => "Cannot set option value - the virus engine will not permit its value to be changed, as this option is immutable",
    0x225 => "The file passed for scanning represented part of a multi volume archive - the file cannot be scanned",
    0x226 => "Returned from a callback function to request default processing",
    0x227 => "GetConfigValue() called for a grouped engine setting",
    0x228 => "Operation failed due to incompatible pending / ongoing activity on Virus data",
    0x229 => "ISaviStream implementation: ReadStream failed",
    0x22A => "ISaviStream implementation: WriteStream failed",
    0x22B => "ISaviStream implementation: SeekStream failed",
    0x22C => "ISaviStream implementation: GetLength failed",
    0x22D => "One of the files in a split-virus data set could not be located",
    0x22E => "One of the files in a split-virus data set could not be located",
    0x22F => "One of the files in a split-virus data set has the wrong checksum",
    0x230 => "One of the files in a split-virus data set has the wrong checksum",
    0x231 => "Scan aborted by SAVI AutoStop",
);

sub new {
    my ($class) = @_;

    my $self = {};

    $self->{savi_h} = new SAVI::handle;

    ref $self or return $self;

    $self->{options} = { $self->{savi_h}->options() };

    bless($self, "SAVI");
    return $self;
}

sub SAVI::options {
    my ($self) = @_;

    return (sort(keys (%{$self->{options}})));
}

sub SAVI::load_data {
    my ($self, $vdl_dir, $ide_dir) = @_;

    my $error;

    if ($vdl_dir) {

	$error = $self->set("VirusDataDir", $vdl_dir) and return $error;
	$error = $self->set("IdeDir", $ide_dir || $vdl_dir) and return $error;
	
	$self->{ide_dir} = $ide_dir || $vdl_dir;
    }
    elsif (! defined($self->{ide_dir})) {

	($self->{ide_dir}, $error) = $self->get("IdeDir");

	return $error if $error;
    }

    $self->{mtime} = (stat($self->{ide_dir}))[9];

    return $self->{savi_h}->load_data();
}

sub SAVI::stale {
    my ($self) = @_;

    my $new_mtime = (stat($self->{ide_dir}))[9];

    return ($new_mtime > $self->{mtime}) ? 1 : 0;
}


sub SAVI::version {
    my ($self) = @_;

    return $self->{savi_h}->version();
}

sub SAVI::set {
    my ($self, $param, $value) = @_;

    my $type = $self->{options}{$param} || $self->{savi_h}->type_u32();

    return $self->{savi_h}->set($param, $value, $type);
}

sub SAVI::get {
    my ($self, $param) = @_;

    my $type = $self->{options}{$param} || $self->{savi_h}->type_u32();

    return $self->{savi_h}->get($param, $type);
}

sub SAVI::scan {
    my ($self, $path) = @_;

    return $self->{savi_h}->scan($path);
}

sub SAVI::scan_fh {
    my ($self, $fh) = @_;

    return $self->{savi_h}->scan_fh($fh);
}

sub SAVI::error_string {
    my ($class, $code) = @_;

    defined ($error_strings{$code}) and return $error_strings{$code};

    return "Unknown error";
}

1;
__END__


=head1 NAME

SAVI - Perl module interface to Sophos Anti-Virus Engine

=head1 DESCRIPTION

=head1 Initialization

=over 4

=item $savi = new SAVI();

Creates a new instance of the virus scanning engine. Returns a reference
to an object of type SAVI on success or a numeric error code on failure.
    
=back

=head1 SAVI methods

=over 4

=item $error = $savi->load_data(vdl_dir, ide_dir);

Explicitly loads or reloads virus data. Virus data is automatically loaded
the first time it is needed, or can be explicitly loaded with this function.
This function can also be used to refresh virus data within an existing
SAVI object. The optional parameters define where the main virus data and the
ancillary ide files can be found. If neither are supplied, the default
environment variable SAV_IDE is used. If the second parameter is not supplied
the value of the first will be used for both. Returns undef on success or a
numeric error code on failure.

=back

=over 4

=item $version = $savi->version();

Returns a reference to an object of type SAVI::version on success,
a numeric error code in the case of failure of the underlying API call,
or undef upon failure to allocate memory.

=back

=over 4

=item $savi->stale();

Returns true if the virus data in use is stale and should be reloaded.
This is implemented by saving the mtime of the IDE directory when
the virus data is loaded and comparing the current mtime of that
directory to the saved value. If the current mtime is greater than
the saved value, the virus data is assumed to be stale.

=back

=over 4

=item @options = $savi->options();

Returns an array listing valid options for the in-use version of the SAVI
engine.

=back

=over 4

=item $error = $savi->set(param, value);

Sets the given parameter to the given value. Returns
undef on success and a numeric error code on failure.

=back

=over 4

=item ($value, $error) = $savi->get(param);

Returns the current value of the given parameter. $error is
undef on success and a numeric error code on failure.

=back

=over 4

=item $results = $savi->scan(path);

Initiates a scan on the given file. Returns a reference to an object of type
SAVI::results on success, or a numeric error code on failure.

=back

=over 4

=item $results = $savi->scan_fh(FH);

Initiates a scan on the given file handle. Returns a reference to an object
of type SAVI::results on success, or a numeric error code on failure.

=back

=over 4

=item $savi->error_string(code);

Returns an error message corresponding to the given code. Can also
be called as SAVI->error_string(code) if the failure resulted from
initializing the $savi object itself.

=back

=head1 SAVI::version methods

=over 4

=item $version->string

Returns the version number of the product.
    
=back
    
=over 4

=item $version->major

Returns the major portion of the version number of the virus engine.
    
=back
    
=over 4

=item $version->minor

Returns the minor portion of the version number of the virus engine.
    
=back
    
=over 4

=item $version->count

Returns the number of viruses recognized by the engine.
    
=back
    
=over 4

=item @ide_list = $version->ide_list

Returns a list of references to objects of type SAVI::ide, describing
what virus definition files are in use.
    
=back

=head1 SAVI::ide methods

=over 4

=item $ide->name

Returns the name of the virus definition file.
    
=back

=over 4

=item $ide->date

Returns the release date of the virus definition file.

=back

=head1 SAVI::results methods

=over 4

=item $results->infected

Returns true if the scan discovered a virus.

=back

=over 4

=item $results->viruses

Returns a list of the viruses discovered by the scan.
    
=back

=head1 AUTHOR

Paul B. Henson <henson@acm.org>

=head1 SEE ALSO

perl(1).

=cut
