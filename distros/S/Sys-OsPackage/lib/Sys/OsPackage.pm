# Sys::OsPackage
# ABSTRACT: install OS packages and determine if CPAN modules are packaged for the OS
# Copyright (c) 2022 by Ian Kluft
# Open Source license Perl's Artistic License 2.0: <http://www.perlfoundation.org/artistic_license_2_0>
# SPDX-License-Identifier: Artistic-2.0

# This module is maintained for minimal dependencies so it can build systems/containers from scratch.

## no critic (Modules::RequireExplicitPackage)
# This resolves conflicting Perl::Critic rules which want package and strictures each before the other
use strict;
use warnings;
use utf8;
## use critic (Modules::RequireExplicitPackage)

package Sys::OsPackage;
$Sys::OsPackage::VERSION = '0.4.0';
use Config;
use Carp qw(carp croak confess);
use Sys::OsRelease;
use autodie;

BEGIN {
    # import methods from Sys::OsRelease to manage singleton instance
    Sys::OsRelease->import_singleton();
}

# system configuration
my %_sysconf = (

    # additional common IDs to provide to Sys::OsRelease to recognize as common platforms in ID_LIKE attributes
    # this adds to recognized common platforms:
    #   RHEL, SuSE, Ubuntu - common commercial platforms
    #   CentOS - because we use it to recognize Rocky and Alma as needing EPEL
    common_id => [qw(centos rhel suse ubuntu)],

    # command search list & path
    search_cmds => [
        qw(uname curl tar cpan cpanm rpm yum repoquery dnf apt apt-cache dpkg-query apk pacman brew
            zypper)
    ],
    search_path => [qw(/bin /usr/bin /sbin /usr/sbin /opt/bin /usr/local/bin)],
);

# platform/package configuration
# all entries in here have a second-level hash keyed on the platform
# TODO: refactor to delegate this to packaging driver classes
my %_platconf = (

    # platform packaging handler class name
    packager => {
        alpine   => "Sys::OsPackage::Driver::Alpine",
        arch     => "Sys::OsPackage::Driver::Arch",
        centos   => "Sys::OsPackage::Driver::RPM",   # CentOS no longer exists; CentOS derivatives supported via ID_LIKE
        debian   => "Sys::OsPackage::Driver::Debian",
        fedora   => "Sys::OsPackage::Driver::RPM",
        opensuse => "Sys::OsPackage::Driver::Suse",
        rhel     => "Sys::OsPackage::Driver::RPM",
        suse     => "Sys::OsPackage::Driver::Suse",
        ubuntu   => "Sys::OsPackage::Driver::Debian",
    },

    # package name override where computed name is not correct
    override => {
        debian => {
            "libapp-cpanminus-perl" => "cpanminus",
        },
        ubuntu => {
            "libapp-cpanminus-perl" => "cpanminus",
        },
        arch => {
            "perl-app-cpanminus" => "cpanminus",
            "tar"                => "core/tar",
            "curl"               => "core/curl",
        },
    },

    # prerequisite OS packages for CPAN
    prereq => {
        alpine   => [qw(perl-utils)],
        fedora   => [qw(perl-CPAN)],
        centos   => [qw(epel-release perl-CPAN)],    # CentOS no longer exists, still used for CentOS-derived systems
        debian   => [qw(perl-modules)],
        opensuse => [qw()],
        suse     => [qw()],
        ubuntu   => [qw(perl-modules)],
    },
);

# Perl-related configuration (read only)
my %_perlconf = (
    sources => {
        "App::cpanminus" => 'https://cpan.metacpan.org/authors/id/M/MI/MIYAGAWA/App-cpanminus-1.7046.tar.gz',
    },

    # Perl module dependencies
    # Sys::OsPackage doesn't have to declare these as dependencies because it will load them by package or CPAN before use
    # That maintains a light footprint for bootstrapping a container or system.
    module_deps => [qw(Term::ANSIColor Perl::PrereqScanner::NotQuiteLite HTTP::Tiny)],

    # OS package dependencies for CPAN
    cpan_deps => [qw(curl tar make)],

    # built-in modules/pragmas to skip processing as dependencies
    skip => {
        "strict"   => 1,
        "warnings" => 1,
        "utf8"     => 1,
        "feature"  => 1,
        "autodie"  => 1,
    },
);

#
# class data access functions
#

# helper function to allow methods to get the instance ref when called via the class name
sub class_or_obj
{
    my $coo = shift;
    return $coo if ref $coo;    # return it if it's an object

    # safety net: all-stop if we received an undef
    if ( not defined $coo ) {
        confess "class_or_obj() got undef from: " . ( join "|", caller 1 );
    }

    # return the instance
    my $inst_method = $coo->can("instance");
    if ( not $inst_method ) {
        confess "incompatible class $coo from:" . ( join "|", caller 1 );
    }
    return &$inst_method($coo);
}

# system configuration
sub sysconf
{
    my $key = shift;
    return if not exists $_sysconf{$key};
    return $_sysconf{$key};
}

# Perl configuration
sub perlconf
{
    my $key = shift;
    return if not exists $_perlconf{$key};
    return $_perlconf{$key};
}

# platform configuration
## no critic (Subroutines::ProhibitUnusedPrivateSubroutines)
sub _platconf { return \%_platconf; }    # for testing
## use critic (Subroutines::ProhibitUnusedPrivateSubroutines)
sub platconf
{
    my ( $class_or_obj, $key ) = @_;
    my $self = class_or_obj($class_or_obj);

    return if not defined $self->platform();
    return if not exists $_platconf{$key}{ $self->platform() };
    return $_platconf{$key}{ $self->platform() };
}

#
# initialization of the singleton instance
# imported methods from Sys::OsRelease: init new instance defined_instance clear_instance
#

# initialize a new instance
## no critic (Subroutines::ProhibitUnusedPrivateSubroutines) # called by imported instance() - perlcritic can't see it
sub _new_instance
{
    my ( $class, @params ) = @_;

    # enforce class lineage
    if ( not $class->isa(__PACKAGE__) ) {
        croak "cannot find instance: " . ( ref $class ? ref $class : $class ) . " is not a " . __PACKAGE__;
    }

    # obtain parameters from array or hashref
    my %obj;
    if ( scalar @params > 0 ) {
        if ( ref $params[0] eq 'HASH' ) {
            $obj{_config} = $params[0];
        } else {
            $obj{_config} = {@params};
        }
    }

    # bless instance
    my $obj_ref = bless \%obj, $class;

    # initialization
    if ( exists $obj_ref->{_config}{debug} ) {
        $obj_ref->{debug} = $obj_ref->{_config}{debug};
    } elsif ( exists $ENV{SYS_OSPACKAGE_DEBUG} ) {
        $obj_ref->{debug} = deftrue( $ENV{SYS_OSPACKAGE_DEBUG} );
    }
    if ( deftrue( $obj_ref->{debug} ) ) {
        print STDERR "_new_instance($class, " . join( ", ", @params ) . ")\n";
    }
    $obj_ref->{sysenv}           = {};
    $obj_ref->{module_installed} = {};
    $obj_ref->collect_sysenv();

    # instantiate object
    return $obj_ref;
}
## use critic (Subroutines::ProhibitUnusedPrivateSubroutines)

# utility: test if a value is defined and is true
sub deftrue
{
    my $value = shift;
    return ( ( defined $value ) and $value ) ? 1 : 0;
}

#
# functions that query instance data
#

# read/write accessor for debug flag
sub debug
{
    my ( $class_or_obj, $value ) = @_;
    my $self = class_or_obj($class_or_obj);

    if ( defined $value ) {
        $self->{debug} = $value;
    }
    return $self->{debug};
}

# read-only accessor for boolean flags
sub ro_flag_accessor
{
    my ( $class_or_obj, $name ) = @_;
    my $self = class_or_obj($class_or_obj);

    return deftrue( $self->{_config}{$name} );
}

# read-only accessor for quiet flag
sub quiet
{
    my ($class_or_obj) = @_;
    return ro_flag_accessor( $class_or_obj, "quiet" );
}

# read-only accessor for notest flag
sub notest
{
    my ($class_or_obj) = @_;
    return ro_flag_accessor( $class_or_obj, "notest" );
}

# read-only accessor for sudo flag
sub sudo
{
    my ($class_or_obj) = @_;
    return ro_flag_accessor( $class_or_obj, "sudo" );
}

# for generation of commands with sudo: return sudo or empty list depending on --sudo flag
# The sudo command is not generated if the user already has root privileges.
sub sudo_cmd
{
    my ($class_or_obj) = @_;
    my $self = class_or_obj($class_or_obj);
    if ( $self->sudo() and not $self->is_root() ) {
        return "sudo";
    }
    return ();
}

# read/write accessor for system environment data
# sysenv is the data collected about the system and commands
sub sysenv
{
    my ( $class_or_obj, $key, $value ) = @_;
    my $self = class_or_obj($class_or_obj);

    if ( defined $value ) {
        $self->{sysenv}{$key} = $value;
    }
    return $self->{sysenv}{$key};
}

# return system platform type
sub platform
{
    my ($class_or_obj) = @_;
    my $self = class_or_obj($class_or_obj);

    return $self->sysenv("platform");
}

# return system packager type, or undef if not determined
sub packager
{
    my ($class_or_obj) = @_;
    my $self = class_or_obj($class_or_obj);

    return $self->sysenv("packager");    # undef intentionally returned if it doesn't exist
}

# look up known exceptions for the platform's package naming pattern
sub pkg_override
{
    my ( $class_or_obj, $pkg ) = @_;
    my $self = class_or_obj($class_or_obj);

    my $override = $self->platconf("override");
    return if ( ( not defined $override ) or ( ref $override ne "HASH" ) );
    return $override->{$pkg};
}

# check if a package name is actually a pragma and may as well be skipped because it's built in to Perl
sub mod_is_pragma
{
    my ( $class_or_obj, $module ) = @_;
    my $self = class_or_obj($class_or_obj);

    my $perl_skip = perlconf("skip");
    return if ( ( not defined $perl_skip ) or ( ref $perl_skip ne "HASH" ) );
    return ( deftrue( $perl_skip->{$module} ) ? 1 : 0 );
}

# find platform-specific prerequisite packages for installation of CPAN
sub cpan_prereqs
{
    my ($class_or_obj) = @_;
    my $self = class_or_obj($class_or_obj);

    my @prereqs     = @{ perlconf("cpan_deps") };
    my $plat_prereq = $self->platconf("prereq");
    if (    ( defined $plat_prereq )
        and ( ref $plat_prereq eq "ARRAY" ) )
    {
        push @prereqs, @{$plat_prereq};
    }
    return @prereqs;
}

# determine if a Perl module is installed, or if a value is provided act as a write accessor for the module's flag
sub module_installed
{
    my ( $class_or_obj, $name, $value ) = @_;
    my $self  = class_or_obj($class_or_obj);
    my $found = 0;

    # check each path element for the module
    my $modfile = join( "/", split( /::/x, $name ) );
    foreach my $element (@INC) {
        my $filepath = "$element/$modfile.pm";
        if ( -f $filepath ) {
            $found = 1;
            last;
        }
    }

    # if a value is provided, act as a write accessor to the module_installed flag for the module
    # Set it to true if a true value was provided and the module was found in the @INC path.
    if ( defined $value ) {
        if ( $found and $value ) {
            $self->{module_installed}{$name} = $found;
        }
    }

    return $found;
}

# run an external command and capture its standard output
# optional \%args in first parameter
#   carp_errors - carp full details in case of errors
#   list - return an array of result lines
sub capture_cmd
{
    my ( $class_or_obj, @cmd ) = @_;
    my $self = class_or_obj($class_or_obj);
    $self->debug() and print STDERR "debug(capture_cmd): " . join( " ", @cmd ) . "\n";

    # get optional arguments if first element of @cmd is a hashref
    my %args;
    if ( ref $cmd[0] eq "HASH" ) {
        %args = %{ shift @cmd };
    }

    # capture output
    my @output;
    my $cmd = join( " ", @cmd );

    # @cmd is concatenated into $cmd - any args which need quotes should have them included
    {
        no autodie;
        open my $fh, "-|", $cmd
            or croak "failed to run pipe command '$cmd': $!";
        while (<$fh>) {
            chomp;
            push @output, $_;
        }
        if ( not close $fh ) {
            if ( deftrue( $args{carp_errors} ) ) {
                carp "failed to close pipe for command '$cmd': $!";
            }
        }
    }

    # detect and handle errors
    if ( $? != 0 ) {

        # for some commands displaying errors are unnecessary - carp errors if requested
        if ( deftrue( $args{carp_errors} ) ) {
            carp "exit status $? from command '$cmd'";
        }
        return;
    }

    # return results
    if ( deftrue( $args{list} ) ) {

        # return an array if list option set
        return @output;
    }
    return wantarray ? @output : join( "\n", @output );
}

# get working directory (with minimal library prerequisites)
sub pwd
{
    my ($class_or_obj) = @_;
    my $self = class_or_obj($class_or_obj);

    my $pwd = $self->capture_cmd('pwd');
    $self->debug() and print STDERR "debug: pwd = $pwd\n";
    return $pwd;
}

# find executable files in the $PATH and standard places
sub cmd_path
{
    my ( $class_or_obj, $name ) = @_;
    my $self = class_or_obj($class_or_obj);

    # collect and cache path info
    if ( not defined $self->sysenv("path_list") or not defined $self->sysenv("path_flag") ) {
        $self->sysenv( "path_list", [ split /:/x, $ENV{PATH} ] );
        $self->sysenv( "path_flag", { map { ( $_ => 1 ) } @{ $self->sysenv("path_list") } } );
        my $path_flag = $self->sysenv("path_flag");
        foreach my $dir ( @{ sysconf("search_path") } ) {
            -d $dir or next;
            if ( not exists $path_flag->{$dir} ) {
                push @{ $self->sysenv("path_list") }, $dir;
                $path_flag->{$dir} = 1;
            }
        }
    }

    # check each path element for the file
    foreach my $element ( @{ $self->sysenv("path_list") } ) {
        my $filepath = "$element/$name";
        if ( -x $filepath ) {
            return $filepath;
        }
    }
    return;
}

# de-duplicate a colon-delimited path
# utility function
sub _dedup_path
{
    my ( $class_or_obj, @in_paths ) = @_;
    my $self = class_or_obj($class_or_obj);

    # construct path lists and deduplicate
    my @out_path;
    my %path_seen;
    foreach my $dir ( map { split /:/x, $_ } @in_paths ) {
        $self->debug() and print STDERR "debug: found $dir\n";
        if ( $dir eq "." ) {

            # omit "." for good security practice
            next;
        }

        # add the path if it hasn't already been seen, and it exists
        if ( not exists $path_seen{$dir} and -d $dir ) {
            push @out_path, $dir;
            $self->debug() and print STDERR "debug: pushed $dir\n";
        }
        $path_seen{$dir} = 1;
    }
    return join ":", @out_path;
}

# save library hints where user's local Perl modules go, observed in search/cleanup of paths
sub _save_hint
{
    my ( $item, $lib_hints_ref, $hints_seen_ref ) = @_;
    if ( not exists $hints_seen_ref->{$item} ) {
        push @{$lib_hints_ref}, $item;
        $hints_seen_ref->{$item} = 1;
    }
    return;
}

# more exhaustive search for user's local perl library directory
sub user_perldir_search_loop
{
    my ($class_or_obj) = @_;
    my $self = class_or_obj($class_or_obj);

    if ( not defined $self->sysenv("perlbase") ) {
    DIRLOOP:
        foreach my $dirpath ( $self->sysenv("home"), $self->sysenv("home") . "/lib", $self->sysenv("home") . "/.local" )
        {
            foreach my $perlname (qw(perl perl5)) {
                if ( -d "$dirpath/$perlname" and -w "$dirpath/$perlname" ) {
                    $self->sysenv( "perlbase", $dirpath . "/" . $perlname );
                    last DIRLOOP;
                }
            }
        }
    }
    return;
}

# make sure directory path exists
sub build_path
{
    my @path_parts = @_;
    my $need_path;
    foreach my $need_dir (@path_parts) {
        $need_path = ( defined $need_path ) ? "$need_path/$need_dir" : $need_dir;
        if ( not -d $need_path ) {
            no autodie;
            mkdir $need_path, 0755
                or return 0;    # give up if we can't create the directory
        }
    }
    return 1;
}

# if the user's local perl library doesn't exist, see if we can create it
sub user_perldir_create
{
    my ($class_or_obj) = @_;
    my $self = class_or_obj($class_or_obj);

    # bail out on Win32 because XDG directory standard only applies to Unix-like systems
    if ( $self->sysenv("os") eq "MSWin32" or $self->sysenv("os") eq "Win32" ) {
        return 0;
    }

    # try to create an XDG-compatible perl library directory under .local
    if ( not defined $self->sysenv("perlbase") ) {

        # use a default that complies with XDG directory structure
        if ( build_path( $self->sysenv("home"), ".local", "perl" ) ) {
            $self->sysenv( "perlbase", $self->sysenv("home") . "/.local/perl" );
        }
    }
    build_path( $self->sysenv("perlbase"), "lib", "perl5" );
    return;
}

# find or create user's local Perl directory
sub user_perldir_search
{
    my ($class_or_obj) = @_;
    my $self = class_or_obj($class_or_obj);

    # use environment variables to look for user's Perl library
    my @lib_hints;
    my %hints_seen;
    my $home = $self->sysenv("home");
    if ( exists $ENV{PERL_LOCAL_LIB_ROOT} ) {
        foreach my $item ( split /:/x, $ENV{PERL_LOCAL_LIB_ROOT} ) {
            if ( $item =~ qr(^$home/)x ) {
                $item =~ s=/$==x;    # remove trailing slash if present
                _save_hint( $item, \@lib_hints, \%hints_seen );
            }
        }
    }
    if ( exists $ENV{PERL5LIB} ) {
        foreach my $item ( split /:/x, $ENV{PERL5LIB} ) {
            if ( $item =~ qr(^$home/)x ) {
                $item =~ s=/$==x;         # remove trailing slash if present
                $item =~ s=/[^/]+$==x;    # remove last directory from path
                _save_hint( $item, \@lib_hints, \%hints_seen );
            }
        }
    }
    if ( exists $ENV{PATH} ) {
        foreach my $item ( split /:/x, $ENV{PATH} ) {
            if ( $item =~ qr(^$home/)x and $item =~ qr(/perl[5]?/)x ) {
                $item =~ s=/$==x;         # remove trailing slash if present
                $item =~ s=/[^/]+$==x;    # remove last directory from path
                _save_hint( $item, \@lib_hints, \%hints_seen );
            }
        }
    }
    foreach my $dirpath (@lib_hints) {
        if ( -d $dirpath and -w $dirpath ) {
            $self->sysenv( "perlbase", $dirpath );
            last;
        }
    }

    # more exhaustive search for user's local perl library directory
    $self->user_perldir_search_loop();

    # if the user's local perl library doesn't exist, create it
    $self->user_perldir_create();
    return;
}

# set up user library and environment variables
# this is called for non-root users
sub set_user_env
{
    my ($class_or_obj) = @_;
    my $self = class_or_obj($class_or_obj);

    # find or create library under home directory
    if ( exists $ENV{HOME} ) {
        $self->sysenv( "home", $ENV{HOME} );
    }
    $self->user_perldir_search();

    #
    # set user environment variables similar to local::lib
    #
    {
        # allow environment variables to be set without "local" in this block - this updates them for child processes
        ## no critic (Variables::RequireLocalizedPunctuationVars)

        # update PATH
        if ( exists $ENV{PATH} ) {
            $ENV{PATH} = $self->_dedup_path( $ENV{PATH}, $self->sysenv("perlbase") . "/bin" );
        } else {
            $ENV{PATH} = $self->_dedup_path( "/usr/bin:/bin", $self->sysenv("perlbase") . "/bin", "/usr/local/bin" );
        }

        # because we modified PATH: remove path cache/flags and force them to be regenerated
        delete $self->{sysenv}{path_list};
        delete $self->{sysenv}{path_flag};

        # update PERL5LIB
        if ( exists $ENV{PERL5LIB} ) {
            $ENV{PERL5LIB} = $self->_dedup_path( $ENV{PERL5LIB}, $self->sysenv("perlbase") . "/lib/perl5" );
        } else {
            $ENV{PERL5LIB} = $self->_dedup_path( @INC, $self->sysenv("perlbase") . "/lib/perl5" );
        }

        # update PERL_LOCAL_LIB_ROOT/PERL_MB_OPT/PERL_MM_OPT for local::lib
        if ( exists $ENV{PERL_LOCAL_LIB_ROOT} ) {
            $ENV{PERL_LOCAL_LIB_ROOT} = $self->_dedup_path( $ENV{PERL_LOCAL_LIB_ROOT}, $self->sysenv("perlbase") );
        } else {
            $ENV{PERL_LOCAL_LIB_ROOT} = $self->sysenv("perlbase");
        }
        {
            ## no critic (Variables::RequireLocalizedPunctuationVars)
            $ENV{PERL_MB_OPT} = '--install_base "' . $self->sysenv("perlbase") . '"';
            $ENV{PERL_MM_OPT} = 'INSTALL_BASE=' . $self->sysenv("perlbase");
        }

        # update MANPATH
        if ( exists $ENV{MANPATH} ) {
            $ENV{MANPATH} = $self->_dedup_path( $ENV{MANPATH}, $self->sysenv("perlbase") . "/man" );
        } else {
            $ENV{MANPATH} =
                $self->_dedup_path( "usr/share/man", $self->sysenv("perlbase") . "/man", "/usr/local/share/man" );
        }
    }

    # display updated environment variables
    if ( not $self->quiet() ) {
        print "using environment settings: (add these to login shell rc script if needed)\n";
        print "" . ( '-' x 75 ) . "\n";
        foreach my $varname (qw(PATH PERL5LIB PERL_LOCAL_LIB_ROOT PERL_MB_OPT PERL_MM_OPT MANPATH)) {
            print "export $varname=$ENV{$varname}\n";
        }
        print "" . ( '-' x 75 ) . "\n";
        print "\n";
    }
    return;
}

# collect info and deduce platform type
sub resolve_platform
{
    my ($class_or_obj) = @_;
    my $self = class_or_obj($class_or_obj);

    # collect uname info
    my $uname = $self->sysenv("uname");
    if ( defined $uname ) {

        # Unix-like systems all have uname
        $self->sysenv( "os",      $self->capture_cmd( $uname, "-s" ) );
        $self->sysenv( "kernel",  $self->capture_cmd( $uname, "-r" ) );
        $self->sysenv( "machine", $self->capture_cmd( $uname, "-m" ) );
    } else {

        # if the platform doesn't have uname (mainly Windows), get what we can from the Perl configuration
        $self->sysenv( "os",      $Config{osname} );
        $self->sysenv( "machine", $Config{archname} );
    }

    # initialize Sys::OsRelease and set platform type
    my $osrelease = Sys::OsRelease->instance( common_id => sysconf("common_id") );
    $self->sysenv( "platform", $osrelease->platform() );

    # determine system's packager if possible
    my $plat_packager = $self->platconf("packager");
    if ( defined $plat_packager ) {
        $self->sysenv( "packager", $plat_packager );
    }

    # display system info
    my $detected;
    if ( defined $osrelease->osrelease_path() ) {
        if ( $self->platform() eq $osrelease->id() ) {
            $detected = $self->platform();
        } else {
            $detected = $osrelease->id() . " -> " . $self->platform();
        }
        if ( defined $self->sysenv("packager") ) {
            $detected .= " handled by " . $self->sysenv("packager");
        }

    } else {
        $detected = $self->platform() . " (no os-release data)";
    }
    if ( not $self->quiet() ) {
        print $self->text_green() . "system detected: $detected" . $self->text_color_reset() . "\n";
    }
    return;
}

# collect system environment info
sub collect_sysenv
{
    my ($class_or_obj) = @_;
    my $self           = class_or_obj($class_or_obj);
    my $sysenv         = $self->{sysenv};

    # find command locations
    foreach my $cmd ( @{ sysconf("search_cmds") } ) {
        if ( my $filepath = $self->cmd_path($cmd) ) {
            $sysenv->{$cmd} = $filepath;
        }
    }
    $sysenv->{perl} = $Config{perlpath};

    # collect info and deduce platform type
    $self->resolve_platform();

    # check if user is root
    if ( $> == 0 ) {

        # set the flag to indicate they are root
        $sysenv->{root} = 1;

        # on Alpine, refresh the package data
        if ( exists $sysenv->{apk} ) {
            $self->run_cmd( $sysenv->{apk}, "update" );
        }
    } else {

        # set user environment variables as necessary (similar to local::lib but without that as a dependency)
        $self->set_user_env();
    }

    # debug dump
    if ( $self->debug() ) {
        print STDERR "debug: sysenv:\n";
        foreach my $key ( sort keys %$sysenv ) {
            if ( ref $sysenv->{$key} eq "ARRAY" ) {
                print STDERR "   $key => [" . join( " ", @{ $sysenv->{$key} } ) . "]\n";
            } else {
                print STDERR "   $key => " . ( exists $sysenv->{$key} ? $sysenv->{$key} : "(undef)" ) . "\n";
            }
        }
    }
    return;
}

# run an external command
sub run_cmd
{
    my ( $class_or_obj, @cmd ) = @_;
    my $self = class_or_obj($class_or_obj);

    $self->debug() and print STDERR "debug(run_cmd): " . join( " ", @cmd ) . "\n";
    {
        no autodie;
        system @cmd;
    }
    if ( $? == -1 ) {
        print STDERR "failed to execute '" . ( join " ", @cmd ) . "': $!\n";
        exit 1;
    } elsif ( $? & 127 ) {
        printf STDERR "child '" . ( join " ", @cmd ) . "' died with signal %d, %s coredump\n",
            ( $? & 127 ), ( $? & 128 ) ? 'with' : 'without';
        exit 1;
    } else {
        my $retval = $? >> 8;
        if ( $retval != 0 ) {
            printf STDERR "child '" . ( join " ", @cmd ) . "' exited with value %d\n", $? >> 8;
            return 0;
        }
    }

    # it gets here if it succeeded
    return 1;
}

# check if the user is root - if so, return true
sub is_root
{
    my ($class_or_obj) = @_;
    my $self = class_or_obj($class_or_obj);

    return deftrue( $self->sysenv("root") );
}

# handle various systems' packagers
# op parameter is a string:
#   implemented: 1 if packager implemented for this system, otherwise undef
#   pkgcmd: 1 if packager command found, 0 if not found
#   modpkg(module): find name of package for Perl module
#   find(pkg): 1 if named package exists, 0 if not
#   install(pkg): 0 = failure, 1 = success
# returns undef if not implemented
#   for ops which return a numeric status: 0 = failure, 1 = success
#   some ops return a value such as query results
sub call_pkg_driver
{
    my ( $class_or_obj, %args ) = @_;
    my $self = class_or_obj($class_or_obj);

    if ( not exists $args{op} ) {
        croak "call_pkg_driver() requires op parameter";
    }

    # check if packager is implemented for currently-running system
    if ( $args{op} eq "implemented" ) {
        if ( $self->sysenv("os") eq "Linux" ) {
            if ( not defined $self->platform() ) {

                # for Linux packagers, we need ID to tell distros apart - all modern distros should provide one
                return;
            }
            if ( not defined $self->packager() ) {

                # it gets here on Linux distros which we don't have a packager implementation
                return;
            }
        } else {

            # add handlers for more packagers as they are implemented
            return;
        }
        return 1;
    }

    # if a pkg parameter is present, apply package name override if one is configured
    if ( exists $args{pkg} and $self->pkg_override( $args{pkg} ) ) {
        $args{pkg} = $self->pkg_override( $args{pkg} );
    }

    # if a module parameter is present, add mod_parts parameter
    if ( exists $args{module} ) {
        $args{mod_parts} = [ split /::/x, $args{module} ];
    }

    # look up function which implements op for package type
    ## no critic (BuiltinFunctions::ProhibitStringyEval) # need stringy eval to load a class from a string
    if ( not eval "require " . $self->packager() ) {
        croak "failed to load driver class " . $self->packager();
    }
    ## use critic (BuiltinFunctions::ProhibitStringyEval)
    my $funcname = $self->packager() . "::" . $args{op};
    $self->debug()
        and print STDERR "debug: $funcname(" . join( " ", map { $_ . "=" . $args{$_} } sort keys %args ) . ")\n";
    my $funcref = $self->packager()->can( $args{op} );
    if ( not defined $funcref ) {

        # not implemented - subroutine name not found in driver class
        $self->debug() and print STDERR "debug: $funcname not implemented\n";
        return;
    }

    # call the function with parameters: driver class (class method call), Sys::OsPackage instance, arguments
    return $funcref->( $self->packager(), $self, \%args );
}

# return string to turn text green
sub text_green
{
    my ($class_or_obj) = @_;
    my $self = class_or_obj($class_or_obj);

    $self->module_installed('Term::ANSIColor') or return "";
    require Term::ANSIColor;
    return Term::ANSIColor::color('green');
}

# return string to turn text back to normal
sub text_color_reset
{
    my ($class_or_obj) = @_;
    my $self = class_or_obj($class_or_obj);

    $self->module_installed('Term::ANSIColor') or return "";
    require Term::ANSIColor;
    return Term::ANSIColor::color('reset');
}

# install a Perl module as an OS package
sub module_package
{
    my ( $class_or_obj, $module ) = @_;
    my $self = class_or_obj($class_or_obj);

    # check if we can install a package
    if ( not $self->is_root() and not $self->sudo() ) {

        # must be root or set sudo flag in order to install an OS package
        return 0;
    }
    if ( not $self->call_pkg_driver( op => "implemented" ) ) {
        return 0;
    }

    # handle various package managers
    my $pkgname = $self->call_pkg_driver( op => "modpkg", module => $module );
    return 0 if ( not defined $pkgname ) or length($pkgname) == 0;
    if ( not $self->quiet() ) {
        print "\n";
        print $self->text_green()
            . "install $pkgname for $module using "
            . $self->sysenv("packager")
            . $self->text_color_reset() . "\n";
    }

    return $self->call_pkg_driver( op => "install", pkg => $pkgname );
}

# check if OS package is installed
sub pkg_installed
{
    my ( $class_or_obj, $pkgname ) = @_;
    my $self = class_or_obj($class_or_obj);

    return 0 if ( not defined $pkgname ) or length($pkgname) == 0;
    return $self->call_pkg_driver( op => "is_installed", pkg => $pkgname );
}

# check if module is installed, and install it if not present
# throws exception on failure
sub install_module
{
    my ( $class_or_obj, $name ) = @_;
    my $self = class_or_obj($class_or_obj);
    $self->debug() and print STDERR "debug: install_module($name) begin\n";
    my $result = $self->module_installed($name);

    # check if module is installed
    if ($result) {
        $self->debug() and print STDERR "debug: install_module($name) skip - already installed\n";
    } else {

        # print header for module installation
        if ( not $self->quiet() ) {
            print $self->text_green() . ( '-' x 75 ) . "\n";
            print "install $name" . $self->text_color_reset() . "\n";
        }

        # try first to install it with an OS package (root required)
        if ( $self->is_root() or $self->sudo() ) {
            if ( $self->module_package($name) ) {
                $result = $self->module_installed( $name, 1 );
            }
        }

        # try again with CPAN or CPANMinus if it wasn't installed by a package
        if ( not $result ) {
            my ( $cmd, @test_param );
            if ( defined $self->sysenv("cpan") ) {
                $cmd = $self->sysenv("cpan");
                $self->notest() and push @test_param, "-T";
            } else {
                $cmd = $self->sysenv("cpanm");
                $self->notest() and push @test_param, "--notest";
                push @test_param, "--without-recommends";
                push @test_param, "--without-suggests";
            }
            $self->run_cmd( $cmd, @test_param, $name )
                or croak "failed to install $name module";
            $result = $self->module_installed( $name, 1 );
        }
    }
    $self->debug() and print STDERR "debug: install_module($name) result=$result\n";
    return $result;
}

# bootstrap CPAN-Minus in a subdirectory of the current directory
sub bootstrap_cpanm
{
    my ($class_or_obj) = @_;
    my $self = class_or_obj($class_or_obj);

    # save current directory
    my $old_pwd = $self->pwd();

    # make build directory and change into it
    if ( not -d "build" ) {
        no autodie;
        mkdir "build", 0755
            or croak "can't make build directory in current directory: $!";
    }
    chdir "build";

    # verify required commands are present
    my @missing;
    foreach my $cmd ( @{ perlconf("cpan_deps") } ) {
        if ( not defined $self->sysenv("$cmd") ) {
            push @missing, $cmd;
        }
    }
    if ( scalar @missing > 0 ) {
        croak "missing " . ( join ", ", @missing ) . " command - can't bootstrap cpanm";
    }

    # download cpanm
    my $perl_sources = perlconf("sources");
    $self->run_cmd( $self->sysenv("curl"), "-L", "--output", "app-cpanminus.tar.gz", $perl_sources->{"App::cpanminus"} )
        or croak "download failed for App::cpanminus";
    my @cpanm_path = grep { qr(/bin/cpanm$)x }
        ( $self->capture_cmd( { list => 1 }, $self->sysenv("tar"), qw(-tf app-cpanminus.tar.gz) ) );
    my $cpanm_path = pop @cpanm_path;
    $self->run_cmd( $self->sysenv("tar"), "-xf", "app-cpanminus.tar.gz", $cpanm_path );
    {
        no autodie;
        chmod 0755, $cpanm_path
            or croak "failed to chmod $cpanm_path:$!";
    }
    $self->sysenv( "cpanm", $self->pwd() . "/" . $cpanm_path );

    # change back up to previous directory
    chdir $old_pwd;
    return;
}

# establish CPAN if not already present
sub establish_cpan
{
    my ($class_or_obj) = @_;
    my $self = class_or_obj($class_or_obj);

    # first get package dependencies for CPAN (and CPAN too if available via OS package)
    if ( $self->is_root() ) {

        # package dependencies for CPAN (i.e. make, or oddly-named OS package that contains CPAN)
        my @deps = $self->cpan_prereqs();
        $self->call_pkg_driver( op => "install", pkg => \@deps );

        # check for commands which were installed by their package name, and specifically look for cpan by any package
        foreach my $dep ( @deps, "cpan" ) {
            if ( my $filepath = $self->cmd_path($dep) ) {
                $self->sysenv( $dep, $filepath );
            }
        }
    }

    # install CPAN-Minus if neither CPAN nor CPAN-Minus exist
    if ( not defined $self->sysenv("cpan") and not defined $self->sysenv("cpanm") ) {

        # try to install CPAN-Minus as an OS package
        if ( $self->is_root() ) {
            if ( $self->module_package("App::cpanminus") ) {
                $self->sysenv( "cpanm", $self->cmd_path("cpanm") );
            }
        }

        # try again if it wasn't installed by a package
        if ( not defined $self->sysenv("cpanm") ) {
            $self->bootstrap_cpanm();
        }
    }

    # install CPAN if it doesn't exist
    if ( not defined $self->sysenv("cpan") ) {

        # try to install CPAN as an OS package
        if ( $self->is_root() ) {
            if ( $self->module_package("CPAN") ) {
                $self->sysenv( "cpan", $self->cmd_path("cpan") );
            }
        }

        # try again with cpanminus if it wasn't installed by a package
        if ( not defined $self->sysenv("cpan") ) {
            if ( $self->run_cmd( $self->sysenv("perl"), $self->sysenv("cpanm"), "CPAN" ) ) {
                $self->sysenv( "cpan", $self->cmd_path("cpan") );
            }
        }
    }

    # install modules used by Sys::OsPackage or CPAN
    foreach my $dep ( @{ perlconf("module_deps") } ) {
        $self->install_module($dep);
    }
    return 1;
}

1;

=pod

=encoding UTF-8

=head1 NAME

Sys::OsPackage - install OS packages and determine if CPAN modules are packaged for the OS 

=head1 VERSION

version 0.4.0

=head1 SYNOPSIS

  use Sys::OsPackage;
  my $ospackage = Sys::OsPackage->instance();
  foreach my $module ( qw(module-name ...)) {
    $ospackage->install_module($module);
  }

=head1 DESCRIPTION

I<Sys::OsPackage> is used for installing Perl module dependencies.
It can look up whether a Perl module is available under some operating systems' packages.
If the module is available as an OS package, it installs it via the packaging system of the OS.
Otherwise it runs CPAN to install the module.

The use cases of I<Sys::OsPackage> include setting up systems or containers with Perl modules using OS packages
as often as possible. It can also be used for installing dependencies for a Perl script on an existing system.

OS packaging systems currently supported by I<Sys::OsPackage> are the Linux distributions Alpine, Arch, Debian,
Fedora and OpenSuse.
Using L<Sys::OsRelease> it's able to detect operating systems derived from a supported platform use the correct driver.

RHEL and CentOS are supported by the Fedora driver.
CentOS-derived systems Rocky and Alma are supported by recognizing them as derivatives.
Ubuntu is supported by the Debian driver.

Other packaging systems for Unix-like operating systems should be feasible to add by writing a driver module.

=head1 SEE ALSO

L<fetch-reqs.pl> comes with I<Sys::OsPackage> to provide a command-line interface.

L<Sys::OsPackage::Driver>

"pacman/Rosetta" at Arch Linux Wiki compares commands of 5 Linux packaging systems L<https://wiki.archlinux.org/title/Pacman/Rosetta>

GitHub repository for Sys::OsPackage: L<https://github.com/ikluft/Sys-OsPackage>

=head1 BUGS AND LIMITATIONS

Please report bugs via GitHub at L<https://github.com/ikluft/Sys-OsPackage/issues>

Patches and enhancements may be submitted via a pull request at L<https://github.com/ikluft/Sys-OsPackage/pulls>

=head1 LICENSE INFORMATION

Copyright (c) 2022 by Ian Kluft

This module is distributed in the hope that it will be useful, but it is provided “as is” and without any express or implied warranties. For details, see the full text of the license in the file LICENSE or at L<https://www.perlfoundation.org/artistic-license-20.html>.

=head1 AUTHOR

Ian Kluft <cpan-dev@iankluft.com>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2022 by Ian Kluft.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut

__END__

# POD documentation
