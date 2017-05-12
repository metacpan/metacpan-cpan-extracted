#-----------------------------------------------------------------
# OWL::Config
# Author: Martin Senger <martin.senger@gmail.com>
# For copyright and disclaimer see below.
#
# $Id: Config.pm,v 1.1 2009-08-25 14:30:50 ubuntu Exp $
#-----------------------------------------------------------------

package OWL::Config;

use Config::Simple;
use File::Spec;
use File::HomeDir;
use vars qw( $DEFAULT_CONFIG_FILE $ENV_CONFIG_DIR );
use strict;

# add versioning to this module
use vars qw /$VERSION/;
$VERSION = sprintf "%d.%02d", q$Revision: 1.1 $ =~ /: (\d+)\.(\d+)/;

my %Config = ();     # here are all configuration parameters
my %Unsuccess = ();  # here are names (and reasons) of failed files
my %Success = ();    # here are names of successfully read files

BEGIN {
    $DEFAULT_CONFIG_FILE = 'owl2perl-config.cfg';
    $ENV_CONFIG_DIR = 'OWL_CFG_DIR';
}

# OO access; but there are no instance attributes - everything are
# class (shared) attributes

sub new {
    my ($class, @args) = @_;

    # create an object
    my $self = bless {}, ref ($class) || $class;

    # initialize the object
    $self->import (@args);

    # done
    return $self;
}


# this allows to specify a configuration file in the use clause:
#    use OWL::Config ( 'my.file', 'your.file', { cachedir => 'somewhere' } )

sub import {
    shift->init ($DEFAULT_CONFIG_FILE, @_);
}

# @configs can be mix of scalars (names of configuration files) or
# hash references (direct configuration parameters); can be called
# more times - everything is appended

sub init {
    shift;    # ignore invocant
    my (@configs) = @_;
    # add parameters AND resolve file names
    foreach my $config (@configs) {
	if (ref ($config) eq 'HASH') {
	    %Config = (%Config, %$config);
	} else {
	    my $file = OWL::Config->_resolve_file ($config);
	    unless ($file) {
		$Unsuccess{$config} = 'File not found.';
		next;
	    }
	    eval {
		Config::Simple->import_from ($file, \%Config);
	      };
	    if ($@) {
		$@ =~ s| /\S+Config/Simple.pm line \d+, <FH>||;
		#print STDERR "Reading configuration file '$file' failed: $@";
		$Unsuccess{$file} = $@;
	    } else {
		$Success{$file} = 1;
	    }
	}
    }
    # I do not like default.XXX (done by Config::Simple) - so
    # replicate these keys without the prefix 'default'
    foreach my $key (keys %Config) {
	my ($realkey) = ($key =~ /^$Config::Simple::DEFAULTNS\.(.*)/);
	if ($realkey && ! exists $Config{$realkey}) {
	    $Config{$realkey} = $Config{$key};
	}
    }
    # Remove potential whitespaces from the keys (Config::Simple may
    # leave theme there)
    map { my $orig_key = $_;
	  s/\s//g and $Config{$_} = delete $Config{$orig_key}  } keys %Config;
}

# try to locate given $filename, return its full path:
#  a) as it is - if such file exists
#  b) as $ENV{OWL_CFG_DIR}/$filename
#  c) in one of the @INC directories
#  d) return undef

sub _resolve_file {
    shift;    # ignore invocant
    my ($filename) = @_;
    return $filename if -f $filename;


    my $realfilename;
    if ($ENV{$ENV_CONFIG_DIR}) {
	$realfilename = File::Spec->catdir ($ENV{$ENV_CONFIG_DIR}, $filename);
	return $realfilename if -f $realfilename;
    }
	
	$realfilename = undef;
	$realfilename = File::Spec->catfile( File::Spec->catdir (File::HomeDir->my_home,  "Perl-OWL2Perl"), $filename);
	return $realfilename if -f $realfilename;
    
    foreach my $prefix (@INC) {
	$realfilename = File::Spec->catfile ($prefix, $filename);
	return $realfilename if -f $realfilename;
    }
    return undef;
}

# return value of a configuration argument; or add a new argument

sub param {
    shift;

    # If called with no arguments, return all the
    # possible keys
    return keys %Config unless @_;

    # if called with a single argument, return the value
    # matching this key
    return $Config{$_[0]} if @_ == 1;

    # more arguments means adding...
#    return $Config{$_[0]} = $_[1];
    my $ret = $Config{$_[0]} = $_[1];
    OWL::Config->import_names ('OWLCFG');
    return $ret;
}

# remove one, more, or all configuration arguments

sub delete {
    shift;

    # if called with no arguments, delete all keys
    %Config = () and return unless @_;

    # if called with arguments, delete the matching keys
    foreach my $key (@_) {
	delete $Config{$key};
    }
}

# return a stringified version of all configuration options; an
# optional argument is a name for variable into which it is
# stringified (I do not know how to express it better: simply speaking
# this argument is passed to the Data::Dumper->Dump as the variable
# name)

sub dump {
    shift;
    my $varname = @_ ? shift : 'CONFIG';
    require Data::Dumper;
    return Data::Dumper->Dump ( [\%Config], [$varname]);
}

# imports names into the caller's namespace as global variables;
# adapted from the same method in Config::Simple

sub import_names {
    shift;
    my $namespace = @_ ? shift : (caller)[0];
    return if $namespace eq 'OWL::Config';

    no strict 'refs';
    no warnings;   # avoid "Useless use of a variable..."
    while ( my ($key, $value) = each %Config ) {
	$key =~ s/\W/_/g;
	${$namespace . '::' . uc($key)} = $value;
    }
}

# return a list of configuration files successfully read (so far)

sub ok_files {
    return sort keys %Success;
}

# return a hash of configuration files un-successfully read (so far) -
# with corresponding error messages

sub failed_files {
    return %Unsuccess;
}



1;
__END__
