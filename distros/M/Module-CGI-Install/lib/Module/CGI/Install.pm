package Module::CGI::Install;

=pod

=head1 NAME

Module::CGI::Install - Installer for CGI applications

=head1 DESCRIPTION

B<Module::CGI::Install> is a package for installing CGI applications.

It is based on the principle that a particular application may need to
be installed multiple times on a single host.

So an application can be installed normally onto the system, and from
there the functionality provided by B<Module::CGI::Install> creates a way to

quickly, easily and safely move a copy of that application (or at least
the parts that matter) from the default system install location to
the specific CGI directory.

=head2 Intended for CGI Application Authors

The API described below is primarily for the benefit of CGI application
authors.

End-users looking to actually install the applications should be using
the L<cgiinstall> command line tool.

=head1 METHODS

=cut

use 5.005;
use strict;
use Config;
use Carp               ();
use File::Spec         ();
use File::Copy         ();
use File::Path         ();
use File::chmod        ();
use File::Remove       ();
use File::Basename     ();
use Scalar::Util       ();
use Params::Util       qw{ _STRING _CLASS _INSTANCE };
use Term::Prompt       ();
use URI::ToDisk        ();
use LWP::Simple        ();
use CGI::Capture       ();
use ExtUtils::Packlist ();

use vars qw{$VERSION $CGICAPTURE};
BEGIN {
	$VERSION = '0.07';
}

$CGICAPTURE ||= __PACKAGE__->_find_script('CGI::Capture', 'cgicapture');
unless ( $CGICAPTURE and -f $CGICAPTURE ) {
	Carp::croak("Failed to locate the 'cgicapture' application");
}

use Object::Tiny qw{
	force
	interactive
	install_cgi
	install_static
	install_config
	cgi_dir
	cgi_uri
	cgi_capture
	static_dir
	static_uri
	config_dir
	errstr
};






#####################################################################
# Constructor and Accessors

sub new {
	my $self = shift->SUPER::new(@_);

	# Create the arrays for scripts and libraries
	$self->{script} = [];
	$self->{class}  = [];
	$self->{config} = {};

	# By default, install CGI but not static or config
	unless ( defined $self->install_cgi ) {
		$self->{install_cgi}    = 1;
	}
	unless ( defined $self->install_static ) {
		$self->{install_static} = 0;
	}
	unless ( defined $self->install_config ) {
		$self->{install_config} = 0;
	}

	# Auto-detect interactive mode if needed
	unless ( defined $self->interactive ) {
		$self->{interactive} = $self->_is_interactive;
	}

	# Normalize the boolean flags
	$self->{force}          = !! $self->{force};
	$self->{interactive}    = !! $self->{interactive};
	$self->{install_cgi}    = !! $self->{install_cgi};
	$self->{install_static} = !! $self->{install_static};
	$self->{install_config} = !! $self->{install_config};

	# Delete params that should not have been provided
	unless ( $self->install_cgi ) {
		delete $self->{cgi_uri};
		delete $self->{cgi_dir};
	}
	unless ( $self->install_static ) {
		delete $self->{static_uri};
		delete $self->{static_dir};
	}
	unless ( $self->install_config ) {
		delete $self->{config_dir};
		delete $self->{config_keep};
	}

	return $self;
}

sub prepare {
	my $self = shift;

	# Check the cgi params if installing CGI
	if ( $self->install_cgi ) {
		# Get and check the base cgi path
		if ( $self->interactive and ! defined $self->cgi_dir ) {
			$self->{cgi_dir} = Term::Prompt::prompt(
				'x', 'CGI Directory:', '',
				File::Spec->rel2abs( File::Spec->curdir ),
			);
		}
		my $cgi_dir = $self->cgi_dir;
		unless ( defined $cgi_dir ) {
			return $self->prepare_error("No cgi_dir provided");
		}
		unless ( -d $cgi_dir ) {	
			return $self->prepare_error("The cgi_dir '$cgi_dir' does not exist");
		}
		unless ( -w $cgi_dir ) {
			return $self->prepare_error("The cgi_dir '$cgi_dir' is not writable");
		}

		# Get and check the cgi_uri
		if ( $self->interactive and ! defined $self->cgi_uri ) {
			$self->{cgi_uri} = Term::Prompt::prompt(
				'x', 'CGI URI:', '', '',
			);
		}
		unless ( defined _STRING($self->cgi_uri) ) {
			return $self->prepare_error("No cgi_dir provided");
		}

		# Validate the CGI settings
		unless ( $self->force or $self->validate_cgi_dir($self->cgi_map) ) {
			return $self->prepare_error("CGI mapping failed testing");
		}
	}

	# Check the config params if installing config
	if ( $self->install_config ) {
		# Get and check the base config directory
		if ( $self->interactive and ! defined $self->config_dir ) {
			my $default = $self->install_cgi
				? $self->cgi_dir
				: File::Spec->rel2abs( File::Spec->curdir );
			$self->{config_dir} = Term::Prompt::prompt(
				'x', 'Config Directory:', '',
				$default
			);
		}
		my $config_dir = $self->config_dir;
		unless ( defined $config_dir ) {
			return $self->prepare_error("No config_dir provided");
		}
		unless ( -d $config_dir ) {	
			return $self->prepare_error("The config_dir '$config_dir' does not exist");
		}
		unless ( -w $config_dir ) {
			return $self->prepare_error("The config_dir '$config_dir' is not writable");
		}

	}
		
	# Check the static params if installing static
	if ( $self->install_static ) {
		# Get and check the base cgi directory
		if ( $self->interactive and ! defined $self->static_dir ) {
			$self->{static_dir} = Term::Prompt::prompt(
				'x', 'Static Directory:', '',
				File::Spec->rel2abs( File::Spec->curdir ),
			);
		}
		my $static_dir = $self->static_dir;
		unless ( defined $static_dir ) {
			return $self->prepare_error("No static_dir provided");
		}
		unless ( -d $static_dir ) {	
			return $self->prepare_error("The static_dir '$static_dir' does not exist");
		}
		unless ( -w $static_dir ) {
			return $self->prepare_error("The static_dir '$static_dir' is not writable");
		}

		# Get and check the cgi_uri
		if ( $self->interactive and ! defined $self->static_uri ) {
			$self->{static_uri} = Term::Prompt::prompt(
				'x', 'Static URI:', '', '',
			);
		}
		unless ( defined _STRING($self->static_uri) ) {
			return $self->prepare_error("No static_dir provided");
		}

		# Validate the CGI settings
		unless ( $self->force or $self->validate_static_dir($self->static_map) ) {
			return $self->prepare_error("Static mapping failed testing");
		}
	}

	return 1;
}

sub run {
	my $self = shift;

	# Install any binary files
	foreach my $script ( @{$self->{script}} ) {
		my $from = $script->[2];
		unless ( $from and -f $from ) {
			die "Unexpectedly failed to find '$script->[1]'";
		}
		my $to = $self->cgi_map->catfile($script->[1])->path;
		File::Copy::copy( $from => $to );
		unless ( -f $to ) {
			die "Unexpectedly failed to create '$to'";
		}
		unless ( File::chmod::chmod('a+rx', $to) ) {
			die "Failed to set executable permissions";
		}
	}

	# Install any class files
	foreach my $class ( @{$self->{class}} ) {
		my $from = $self->_module_path($class);
		my $to   = File::Spec->catfile(
			$self->cgi_map->catdir('lib')->path,
			File::Spec->catfile(split /::/, $class) . '.pm',
		);
		my $dirname = File::Basename::dirname($to);
		File::Path::mkpath( $dirname, 0, 0755 );
		unless ( -d $dirname ) {
			die "Failed to create directory '$dirname'";
		}
		File::Copy::copy( $from => $to );
		unless ( -f $to ) {
			die "Unexpectedly failed to create '$to'";
		}
	}

	# Install any config files
	foreach my $name ( %{$self->{config}} ) {
		my $from = $self->{config}->{$name};
		my $to   = File::Spec->catfile(
			$self->config_dir,
			$name,
		);
		if (
			_INSTANCE($from, 'YAML::Tiny')
			or
			_INSTANCE($from, 'Config::Tiny')
		) {
			unless ( $from->write($to) ) {
				die "Failed to write to config file '$name'";
			}
		}
	}

	return 1;
}





#####################################################################
# Accessor-Derived Methods

sub cgi_map {
	$_[0]->install_cgi or return undef;
	URI::ToDisk->new( $_[0]->cgi_dir => $_[0]->cgi_uri );
}

sub static_map {
	$_[0]->install_static or return undef;
	URI::ToDisk->new( $_[0]->static_dir => $_[0]->static_uri );
}





#####################################################################
# Manipulation

sub add_script {
	my $self   = shift;
	my $class  = _CLASS(shift)  or die "Invalid class name";
	my $script = _STRING(shift) or die "Invalid script name";
	my $path   = $self->_find_script($class, $script);
	unless ( $path and -f $path ) {
		Carp::croak( "Failed to find '$script'");
	}
	push @{$self->{script}}, [ $class, $script, $path ];
	return 1;
}

sub add_class {
	my $self  = shift;
	my $class = _CLASS(shift)     or die "Invalid class name";
	$self->_module_exists($class) or die "Failed to find '$class'";
	push @{$self->{class}}, $class;
	return 1;
}

sub add_config {
	my $self   = shift;
	my $config = shift;
	my $name   = _STRING(shift) or die "Did not provide a config file name";
	if ( _CLASSISA($config, 'Config::Tiny') ) {
		$config = $config->new;
	}
	if ( _CLASSISA($config, 'YAML::Tiny') ) {
		$config = $config->new( {} );
	}
	unless (
		_INSTANCE($config, 'Config::Tiny')
		or
		_INSTANCE($config, 'Config::YAML')
	) {
		die "Missing, invalid, or unsupported config object";
	}
	$self->{config}->{$name} = $config;
	return 1;
}





#####################################################################
# Functional Methods

sub validate_cgi_dir {
	my $self = shift;
	my $dir  = _INSTANCE(shift, 'URI::ToDisk')
		or Carp::croak("Did not pass a URI::ToDisk object to valid_cgi");
	my $file = $dir->catfile('cgicapture');

	# Copy the cgicapture application to the CGI path
	unless ( File::Copy::copy( $CGICAPTURE, $file->path ) ) {
		return undef;
		# Carp::croak("Failed to copy cgicapture into place");
	}
	unless ( File::chmod::chmod('a+rx', $file->path) ) {
		return undef;
		# Carp::croak("Failed to set executable permissions");
	}

	# Call the URI
	my $www = LWP::Simple::get( $file->URI );

	# Clean up the file now, before we check for errors
	File::Remove::remove( $file->path );

	# Continue and check for errors
	unless ( defined $www ) {
		return undef;
		# Carp::croak("Nothing returned from the cgicapture web request");
	}
	if ( $www =~ /^\#\!\/usr\/bin\/perl/ ) {
		return undef;
		# Carp::croak("URI is not a CGI path");
	}
	unless ( $www =~ /^---\nARGV\:/ ) {
		return undef;
		# Carp::croak("Unknown value returned from URI");
	}

	# Superficially ok, convert to capture object
	$self->{cgi_capture} = CGI::Capture->from_yaml_string($www);
	unless ( _INSTANCE($self->cgi_capture, 'CGI::Capture') ) {
		return undef;
		# Carp::croak("Failed to create capture object");
	}

	return 1;
}

sub validate_static_dir {
	my $self = shift;
	my $dir  = _INSTANCE(shift, 'URI::ToDisk')
		or Carp::croak("Did not pass a URI::ToDisk object to valid_static");
	my $file = $dir->catfile('cgiinstall.txt');

	# Write a test file to the directory
	my $test_string = int(rand(100000000+1000));
	open( FILE, '>' . $file->path ) or die "open: $!";
	print FILE $test_string           or die "print: $!";
	close FILE                        or die "close: $!";

	# Call the URI
	my $www = LWP::Simple::get( $file->URI );

	# Clean up the file now, before we check for errors
	File::Remove::remove( $file->path );

	# Continue and check for errors
	unless ( defined $www ) {
		return undef;
		# Carp::croak("Nothing returned from the cgicapture web request");
	}

	# Check the result
	unless ( $www eq $test_string ) {
		return undef;
		# Carp::croak("Unknown value returned from URI");
	}

	return 1;
}





#####################################################################
# Utility Methods

sub new_error {
	my $self = shift;
	$self->{errstr} = _STRING(shift) || 'Unknown error';
	return;
}

sub prepare_error {
	my $self = shift;
	return _STRING(shift) || 'Unknown error';
}

# Copied from IO::Interactive
sub _is_interactive {
	my $self = shift;

	# Default to default output handle
	my ($out_handle) = (@_, select);  

	# Not interactive if output is not to terminal...
	return 0 if not -t $out_handle;

	# If *ARGV is opened, we're interactive if...
	if ( Scalar::Util::openhandle *ARGV ) {
		# ...it's currently opened to the magic '-' file
		return -t *STDIN if defined $ARGV && $ARGV eq '-';

		# ...it's at end-of-file and the next file is the magic '-' file
		return @ARGV > 0 && $ARGV[0] eq '-' && -t *STDIN if eof *ARGV;

		# ...it's directly attached to the terminal
		return -t *ARGV;
	}

	# If *ARGV isn't opened, it will be interactive if *STDIN is attached 
	# to a terminal and either there are no files specified on the command line
	# or if there are files and the first is the magic '-' file
	return -t *STDIN && (@ARGV==0 || $ARGV[0] eq '-');
}

sub _module_exists {
	my $self = shift;
	my $path = $self->_module_path(shift);
	return !! $path;
}

sub _module_path {
	my $self  = shift;
	my @parts = split /::/, $_[0];
	my @found =
		grep { -f $_ }
		map  { File::Spec->catdir($_, @parts) . '.pm' }
		grep { -d $_ } @INC;
	return $found[0];
}

sub _find_script {
	my $either = shift;
	my $module = shift;
	my $script = shift;
	my @dirs   = grep { -e } ( $Config{archlibexp}, $Config{sitearchexp} );
	my $file   = File::Spec->catfile(
		'auto', split( /::/, $module), '.packlist',
	);

	foreach my $dir ( @dirs ) {
		my $path = File::Spec->catfile( $dir, $file );
		next unless -f $path;

		# Load the file
		my $packlist = ExtUtils::Packlist->new($path);
		unless ( $packlist ) {
			die "Failed to load .packlist file for $module";
		}

		my $regex  = quotemeta $script;
		my @script = sort grep { /\b$regex$/ } keys %$packlist;
		die "Unexpectedly found more than one $script file" if @script > 1;
		die "Failed to find $script script" unless @script;
		return $script[0];
	}
	die "Failed to locate .packfile for $module";
}

1;

=pod

=head1 SUPPORT

All bugs should be filed via the bug tracker at

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Module-CGI-Install>

For other issues, or commercial enhancement or support, contact the author.

=head1 AUTHORS

Adam Kennedy E<lt>adamk@cpan.orgE<gt>

=head1 SEE ALSO

L<http://ali.as/>, L<CGI::Capture>

=head1 COPYRIGHT

Copyright 2007 - 2008 Adam Kennedy.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
