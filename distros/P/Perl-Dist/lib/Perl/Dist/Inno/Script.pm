package Perl::Dist::Inno::Script;

use 5.006;
use strict;
use warnings;
use Carp                       qw{ croak };
use File::Spec                 ();
use File::Temp                 ();
use IPC::Run3                  ();
use Params::Util               qw{ _STRING _IDENTIFIER };
use Perl::Dist::Inno::File     ();
use Perl::Dist::Inno::Icon     ();
use Perl::Dist::Inno::Registry ();
use Perl::Dist::Inno::System   ();

use vars qw{$VERSION};
BEGIN {
	$VERSION = '1.16';
}

use Object::Tiny qw{
	app_id
	app_name
	app_publisher
	app_publisher_url
	default_group_name
	default_dir_name
	output_dir
	source_dir
	bin_compil32
};

sub new {
	my $self = shift->SUPER::new(@_);

	# Apply defaults
	unless ( defined $self->output_dir ) {
		$self->{output_dir} = File::Spec->rel2abs(
			File::Spec->curdir,
		);
	}
	unless ( defined $self->default_group_name ) {
		$self->{default_group_name} = $self->app_name;
	}

	# Check and default params
	unless ( _IDENTIFIER($self->app_id) ) {
		croak("Missing or invalid app_id param");
	}
	unless ( _STRING($self->app_name) ) {
		croak("Missing or invalid app_name param");
	}
	unless ( _STRING($self->app_ver_name) ) {
		croak("Missing or invalid app_ver_name param");
	}
	unless ( _STRING($self->app_publisher) ) {
		croak("Missing or invalid app_publisher param");
	}
	unless ( _STRING($self->app_publisher_url) ) {
		croak("Missing or invalid app_publisher_uri param");
	}
	unless ( _STRING($self->default_group_name) ) {
		croak("Missing or invalid default_group_name param");
	}
	unless ( _STRING($self->default_dir_name) ) {
		croak("Missing or invalid default_dir_name");
	}
	unless ( _STRING($self->output_dir) ) {
		croak("Missing or invalid output_dir param");
	}
	unless ( -d $self->output_dir ) {
		croak("The output_dir " . $self->output_dir . "directory does not exist");
	}
	unless ( -w $self->output_dir ) {
		croak("The output_dir directory is not writable");
	}
	unless ( _STRING($self->output_base_filename) ) {
		croak("Missing or invalid output_base_filename");
	}
	unless ( _STRING($self->source_dir) ) {
		croak("Missing or invalid source_dir param");
	}
	unless ( -d $self->source_dir ) {
		croak("The source_dir directory does not exist");
	}

	# Set ISS element collections
	$self->{files}    = [];
	$self->{icons}    = [];
	$self->{registry} = [];
	$self->{system}   = [];

	# Find the compil32 program
	unless ( $ENV{PROGRAMFILES} and -d $ENV{PROGRAMFILES} ) {
		die("Failed to find the Program Files directory\n");
	}
	my $innosetup_dir  = File::Spec->catdir(  $ENV{PROGRAMFILES}, "Inno Setup 5" );
	my $innosetup_file = File::Spec->catfile( $innosetup_dir,     'Compil32.exe' );
	unless ( -f $innosetup_file ) {
		die("Failed to find the Inno Setup Compil32.exe program");
	}
	$self->{bin_compil32} = $innosetup_file;

	return $self;
}

# Default the versioned name to an unversioned name
sub app_ver_name {
	$_[0]->{app_ver_name} or
	$_[0]->app_name;
}

# Default the output filename to the id plus the current date
sub output_base_filename {
	$_[0]->{output_base_filename} or
	$_[0]->app_id . '-' . $_[0]->output_date_string;
}

# Convenience method
sub output_date_string {
	my @t = localtime;
	return sprintf( "%04d%02d%02d", $t[5] + 1900, $t[4] + 1, $t[3] );
}

sub files {
	return @{ $_[0]->{files} };
}

sub icons {
	return @{ $_[0]->{icons} };
}

sub registry {
	return @{ $_[0]->{registry} };
}

sub system {
	return @{ $_[0]->{system} };
}






#####################################################################
# Main Methods

sub write_exe {
	my $self = shift;

	# Write out the .iss file
	my $content         = $self->as_string;
	my ($fh, $filename) = File::Temp::tempfile();
	$fh->print( $content );
	$fh->close;

	# Compile the .iss file
	my $cmd = [
		$self->bin_compil32,
		'/cc',
		$filename,
	];
	my $rv = IPC::Run3::run3( $cmd, \undef, \undef, \undef );

	# Return the name of the exe file generated
	my $output_exe = File::Spec->catfile(
		$self->output_dir,
		$self->output_base_filename . '.exe',
	);
	unless ( -f $output_exe ) {
		croak("Failed to find $output_exe");
	}

	return $output_exe;
}





#####################################################################
# Manipulation Methods

sub add_file {
	my $self = shift;
	my $file = Perl::Dist::Inno::File->new(@_);
	push @{$self->{files}}, $file;
	return 1;
}

sub add_dir {
	my $self = shift;
	my $name = shift;
	$self->add_file(
		source             => "$name\\*",
		dest_dir           => "{app}\\$name",
		recurse_subdirs    => 1,
		create_all_subdirs => 1,
	);
	return 1;
}

sub add_icon {
	my $self = shift;
	my $icon = Perl::Dist::Inno::Icon->new(@_);
	push @{$self->{icons}}, $icon;
	return 1;
}

sub add_uninstall {
	my $self = shift;
	my $name = $self->app_name;
	$self->add_icon(
		name     => "{cm:UninstallProgram,$name}",
		filename => '{uninstallexe}',
	);
	return 1;
}

sub add_registry {
	my $self     = shift;
	my $registry = Perl::Dist::Inno::Registry->new(@_);
	push @{$self->{registry}}, $registry;
	return 1;
}

sub add_env {
	my $self     = shift;
	my $registry = Perl::Dist::Inno::Registry->env(@_);
	push @{$self->{registry}}, $registry;
	return 1;
}

sub add_system {
	my $self   = shift;
	my $system = Perl::Dist::Inno::System->new(@_);
	push @{$self->{system}}, $system;
	return 1;
}

sub add_run {
	my $self   = shift;
	my $system = Perl::Dist::Inno::System->run(@_);
	push @{$self->{system}}, $system;
	return 1;
}

sub add_uninstallrun {
	my $self   = shift;
	my $system = Perl::Dist::Inno::System->uninstallrun(@_);
	push @{$self->{system}}, $system;
	return 1;
}





#####################################################################
# Serialization

sub as_string {
	my $self  = shift;
	my @lines = (
		'; Inno Setup Script for ' . $self->app_name,
		'; Generated by '          . ref($self),
		'',
	);

	# Add the setup area
	push @lines, (
		'[Setup]',
		'; Distribution Identification',
		'AppName='            . $self->app_name,
		'AppVerName='         . $self->app_ver_name,
		'AppPublisher='       . $self->app_publisher,
		'AppPublisherURL='    . $self->app_publisher_url,
		'AppId='              . $self->app_id,
		'',
		'; Start Menu Icons',
		'DefaultGroupName='   . $self->default_group_name,
		'AllowNoIcons='       . 'yes',
		'',
		'; Installation Path (This is always hard-coded)',
		'DefaultDirName='     . $self->default_dir_name,
		'DisableDirPage='     . 'yes',
		'',
		'; Where the output goes',
		'OutputDir='          . $self->output_dir,
		'OutputBaseFilename=' . $self->output_base_filename,
		'UsePreviousAppDir='  . 'no',
		'',
		'; Source location',
		'SourceDir='          . $self->source_dir,
		'',
		'; Win2K or newer required',
		'MinVersion='         . '4.0.950,4.0.1381',
		'',
		'; Miscellaneous settings',
		'Compression='        . 'lzma',
		'SolidCompression='   . 'yes',
		'ChangesEnvironment=' . 'yes',
		'',
		'; Delete old install',
		'[InstallDelete]',
		'Type: filesandordirs; Name: "' . $self->source_dir . '"',
		'',
	);

	# Start with only English for now
	push @lines, (
		'[Languages]',
		'Name: eng; MessagesFile: compiler:Default.isl',
		'',
	);

	# Add the files to be installed
	push @lines, '[Files]';
	foreach my $file ( $self->files ) {
		push @lines, $file->as_string;
	}
	push @lines, '';

	# Add the icons to be installed
	push @lines, '[Icons]';
	foreach my $icon ( $self->icons ) {
		push @lines, $icon->as_string;
	}
	push @lines, '';

	# Add the registry entries to be added
	push @lines, '[Registry]';
	foreach my $registry ( $self->registry ) {
		push @lines, $registry->as_string;
	}
	push @lines, '';

	# Add any (optional) entries for [Run]
	my @run = grep { $_->section eq 'Run' } $self->system;
	if ( @run ) {
		push @lines, '[Run]';
		foreach my $system ( @run ) {
			push @lines, $system->as_string;
		}
		push @lines, '';
	}

	# Add any (optional) entries for [UninstallRun]
	my @uninstall = grep { $_->section eq 'UninstallRun' } $self->system;
	if ( @uninstall ) {
		push @lines, '[UninstallRun]';
		foreach my $system ( @uninstall ) {
			push @lines, $system->as_string;
		}
		push @lines, '';
	}

	# Combine it all
	return join "\n", @lines;
}

1;
