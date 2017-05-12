package OpenInteract::Package;

# $Id: Package.pm,v 1.40 2003/01/25 16:16:07 lachoy Exp $

# This module manipulates information from individual packages to
# perform some action in the package files.

use strict;

use Archive::Tar       ();
use Cwd                qw( cwd );
use Data::Dumper       qw( Dumper );
use ExtUtils::Manifest ();
use File::Basename     ();
use File::Copy         qw( cp );
use File::Path         ();
use SPOPS::HashFile    ();
use SPOPS::Utility     ();
require Exporter;

@OpenInteract::Package::ISA       = qw( Exporter );
$OpenInteract::Package::VERSION   = sprintf("%d.%02d", q$Revision: 1.40 $ =~ /(\d+)\.(\d+)/);
@OpenInteract::Package::EXPORT_OK = qw( READONLY_FILE );

use constant READONLY_FILE => '.no_overwrite';

# Define the subdirectories present in a package

my @PKG_SUBDIR        = qw( conf data doc struct template script html html/images );

# Fields in our package/configuration

my @PKG_FIELDS = qw( name version author url description notes
                     module template_plugin template_block filter
                     base_dir website_dir package_dir website_name
                     dependency script_install script_upgrade
                     script_uninstall sql_installer installed_on
                     installed_by last_updated_on last_updated_by );


# Name of the package configuration file, always found in the
# package's root directory

my $DEFAULT_CONF_FILE = 'package.conf';

# Define the keys in 'package.conf' that can be a list, meaning you
# can have multiple items defined:
#
#  author  Larry Wall <larry@wall.org>
#  author  Chris Winters <chris@cwinters.com>

my %CONF_LIST_KEYS    = map { $_ => 1 }
                        qw( author script_install script_upgrade script_uninstall module );

# Define the keys in 'package.conf' that can be a hash, meaning that
# you can have items defined as multiple key-value pairs
# (space-separated):
#
#  dependency base_linked 1.09
#  dependency static_page 1.18

my %CONF_HASH_KEYS    = map { $_ => 1 } qw( dependency template_plugin template_block filter );

# For exporting a package, the following variables are required in
# 'package.conf'

my @EXPORT_REQUIRED   = qw( name version );

# Global for holding Archive::Tar errors

my $ARCHIVE_ERROR     = undef;

# Fields NOT to copy over in conf/spops.perl when creating package in
# website from base installation (the first three are ones we
# manipulate by hand)

my %SPOPS_CONF_KEEP   = map { $_ => 1 } qw( class has_a links_to );

# These are the default public and site admin group IDs; we use them
# when copying over the SPOPS configuration files (see
# _copy_spops_config_file())

use constant PUBLIC_GROUP_ID     => 2;
use constant SITE_ADMIN_GROUP_ID => 3;

use constant DEBUG => 0;


# Create subdirectories for a package.

sub create_subdirectories {
    my ( $class, $dir, $main_class ) = @_;
    $main_class ||= 'OpenInteract';
    return undef unless ( -d $dir );
    foreach my $sub_dir ( @PKG_SUBDIR, $main_class,
                          "$main_class/Handler",
                          "$main_class/SQLInstall" ) {
        mkdir( "$dir/$sub_dir", 0775 )
             || die "Cannot create package subdirectory $dir/$sub_dir: $!";
    }
    return 1;
}


# Creates a package directories using our base subdirectories
# along with a package.conf file and some other goodies (?)

sub create_skeleton {
    my ( $class, $repository, $name ) = @_;
    my $pwd = cwd;

    my $cleaned_pkg = $class->_clean_package_name( $name );

    # Check directories

    unless ( $repository ) {
        die "Cannot create package skeleton: no existing base ",
            "installation repository specified!\n";
    }

    my $base_dir = $repository->{META_INF}{base_dir};

    if ( -d $cleaned_pkg ) {
        die "Cannot create package skeleton: directory ($cleaned_pkg) already exists!\n";
    }
    mkdir( $cleaned_pkg, 0775 ) || die "Cannot create package directory $cleaned_pkg: $!\n";
    chdir( $cleaned_pkg );

    # Then create the subdirectories for the package

    $class->create_subdirectories( '.' );

    # This does a replacement so that 'static_page' becomes StaticPage

    my $uc_first_name = ucfirst $cleaned_pkg;
    $uc_first_name =~ s/_(\w)/\U$1\U/g;

    # Copy over files from the samples (located in the base OpenInteract
    # directory), doing replacements as necessary

    $class->replace_and_copy({ from_file => "$base_dir/conf/sample-package.conf",
                               to_file   => "package.conf",
                               from_text => [ '%%NAME%%', '%%UC_FIRST_NAME%%' ],
                               to_text   => [ $cleaned_pkg, $uc_first_name ] });

    $class->replace_and_copy({ from_file => "$base_dir/conf/sample-package.pod",
                               to_file   => "doc/$cleaned_pkg.pod",
                               from_text => [ '%%NAME%%' ],
                               to_text   => [ $cleaned_pkg ] });

    $class->replace_and_copy({ from_file => "$base_dir/conf/sample-doc-titles",
                               to_file   => "doc/titles",
                               from_text => [ '%%NAME%%' ],
                               to_text   => [ $cleaned_pkg ] });

    $class->replace_and_copy({ from_file => "$base_dir/conf/sample-SQLInstall.pm",
                               to_file   => "OpenInteract/SQLInstall/$uc_first_name.pm",
                               from_text => [ '%%NAME%%', '%%UC_FIRST_NAME%%' ],
                               to_text   => [ $cleaned_pkg, $uc_first_name ] });

    $class->replace_and_copy({ from_file => "$base_dir/conf/sample-Handler.pm",
                               to_file   => "OpenInteract/Handler/$uc_first_name.pm",
                               from_text => [ '%%NAME%%', '%%UC_FIRST_NAME%%' ],
                               to_text   => [ $cleaned_pkg, $uc_first_name ] });

    cp( "$base_dir/conf/sample-spops.perl", "conf/spops.perl" )
      || _w( 0, "Cannot copy sample (conf/spops.perl): $!" );
    cp( "$base_dir/conf/sample-action.perl", "conf/action.perl" )
      || _w( 0, "Cannot copy sample (conf/action.perl): $!" );
    cp( "$base_dir/conf/sample-MANIFEST.SKIP", "MANIFEST.SKIP" )
      || _w( 0, "Cannot copy sample (MANIFEST.SKIP): $!" );
    cp( "$base_dir/conf/sample-dummy-template.meta", "template/dummy.meta" )
      || _w( 0, "Cannot copy sample (template/dummy.meta): $!" );
    cp( "$base_dir/conf/sample-dummy-template.tmpl", "template/dummy.tmpl" )
      || _w( 0, "Cannot copy sample (template/dummy.tmpl): $!" );

    # Create a 'Changes' file

    eval {  open( CHANGES, "> Changes" ) || die $! };
    if ( $@ ) {
        _w( 0, "Cannot open 'Changes' file ($!). Please create your ",
               "own so people can follow your progress." );
    }
    else {
        my $time_stamp = scalar localtime;
        print CHANGES <<INIT;
Revision history for OpenInteract package $cleaned_pkg.

0.01  $time_stamp

      Package skeleton created by oi_manage

INIT
        close( CHANGES );
    }

    # Create a MANIFEST from the pwd

    $class->_create_manifest();

    # Go back to the original dir and return the name

    chdir( $pwd );
    return $cleaned_pkg;
}


# Rules for a clean package name:
#   - Package name cannot have spaces (s/ /_/)
#   - Package name cannot have dashes (s/-/_/)
#   - Package name cannot start with a number (die)
#   - Package name cannot have nonword characters except '_'

sub _clean_package_name {
    my ( $class, $name ) = @_;
    my ( @clean_actions, @die_actions );
    $name =~ s/ /_/g  && push @clean_actions, "Name must not have spaces";
    $name =~ s/\-/_/g && push @clean_actions, "Name must not have dashes";
    $name =~ /^\d/    && push @die_actions,   "Name must not start with a number";
    $name =~ /\W/     && push @die_actions,   "Name must not have non-word characters";
    if ( scalar @die_actions ) {
        die "Package name unacceptable: \n",
            join( "\n", @die_actions, @clean_actions ), "\n";
    }
    return $name;
}


# Takes a package file and installs the package to the base
# OpenInteract directory.

sub install_distribution {
    my ( $class, $p ) = @_;
    my $old_pwd = cwd;

    # ------------------------------
    # Taken from CGI.pm
    # FIGURE OUT THE OS WE'RE RUNNING UNDER
    # Some systems support the $^O variable.  If not
    # available then require() the Config library
    my $OS = undef;
    unless ( $OS = $^O ) {
        require Config;
        $OS = $Config::Config{'osname'};
    }
    # ------------------------------

    unless ( -f $p->{package_file} ) {
        die "Package file for installation ($p->{package_file}) does not exist\n";
    }

    # TODO: Use File::Spec for this?

    # Note that this should NOT be just 'win' since 'Darwin' gives a
    # (very) false positive

    if ( $OS =~ /Win32/i ) {
        unless ( $p->{package_file} =~ /^\w:\// ) {
            $p->{package_file} = join( '/', $old_pwd, $p->{package_file} );
        }
    }
    else {
        unless ( $p->{package_file} =~ /^\// ) {
            $p->{package_file} = join( '/', $old_pwd, $p->{package_file} );
        }
    }
    DEBUG && _w( 1, "Package file used for distribution: ($p->{package_file}" );

    # This is the repository we'll be using

    my $repos = $p->{repository} ||
                eval { OpenInteract::PackageRepository->fetch( 
                                        undef, { directory => $p->{base_dir},
                                                 perm      => 'write' } ) };
    unless ( $repos ) { die "Cannot open repository: $@\n" }
    my $base_dir = $repos->{META_INF}{base_dir};

    my $base_package_file = File::Basename::basename( $p->{package_file} );
    my ( $package_base ) = $base_package_file =~ /^(.*)\.tar\.gz$/;
    DEBUG && _w( 1, "Package base: $package_base" );

    my $rv = $class->_extract_archive( $p->{package_file} );
    unless ( $rv ) {
        my $msg = "Error found trying to unpack the distribution! " .
                  "Error: " . $ARCHIVE_ERROR;
        my $removed_files = $class->_remove_directory_tree( $package_base );
        die $msg;
    }

    # Read in the package config and grab the name/version

    chdir( $package_base );
    DEBUG && _w( 1, "Trying to find config file in ($package_base/)" );
    my $conf_file = $p->{package_conf_file} || $DEFAULT_CONF_FILE;
    my $conf    = $class->read_config({ file => $conf_file });
    die "No valid package config read!\n" unless ( scalar keys %{ $conf } );

    my $name    = $conf->{name};
    my $version = $conf->{version};
    chdir( $old_pwd );

    # We're all done with the temp stuff, so get rid of it.

    my $removed_files = $class->_remove_directory_tree( $package_base );
    DEBUG && _w( 2, "Removed extracted tree, config file found ok." );

    # Check to see if the package/version already exists

    my $error_msg = undef;
    my $exist_info = $repos->fetch_package_by_name({ name => $name,
                                                     version => $version });
    if ( $exist_info ) {
        die "Cannot install since package $name-$version already " .
            "exists in the base installation repository. (It was installed on " .
            "$exist_info->{installed_on}).\n\nAborting package installation.\n";
    }
    DEBUG && _w( 1, "Package does not currently exist in repository." );

    # Now see if the package has specified any modules that are
    # necessary for its operation. For now, we will refuse to install
    # a package that does not have supporting modules.

    if ( ref $conf->{module} eq 'ARRAY' ) {
        my @failed_modules = $class->_check_module_install( @{ $conf->{module} } );
        if ( scalar @failed_modules ) {
            die "Package $name-$version requires the following modules " .
                "that are not currently installed: " . join( ', ', @failed_modules ) .
                ". Please install them and try again.\n";
        }
    }

    # Create some directory names and move to the base package directory
    # -- the directory that holds all of the package definitions

    my $new_pkg_dir  = join( '/', 'pkg', "$name-$version" );
    my $full_pkg_dir = join( '/', $base_dir, $new_pkg_dir );
    if ( -d $full_pkg_dir ) {
        die "The directory into which the distribution should be unpacked ",
            "($full_pkg_dir) already exists. Please remove it and try again.\n";
    }
    chdir( join( '/', $base_dir, 'pkg' ) );

    # Unarchive the package; note that since the archive creates a
    # directory name-version/blah we don't need to create the directory
    # ourselves and then chdir() to it.

    my $extract_rv = $class->_extract_archive( $p->{package_file} );
    unless ( $extract_rv ) {
        chdir( $base_dir );
        $class->_remove_directory_tree( $full_pkg_dir );
        die "Cannot unpack the distribution into its final " .
            "directory ($full_pkg_dir)! Error: " . $ARCHIVE_ERROR;
    }
    DEBUG && _w( 1, "Unpackaged package into $base_dir/pkg ok" );

    # Create the package info and try to save; if we're successful, return the
    # package info.

    my $info = {
         base_dir     => $base_dir,
         package_dir  => $new_pkg_dir,
         installed_on => $repos->now };
    foreach my $conf_field ( keys %{ $conf } ) {
        $info->{ $conf_field } = $conf->{ $conf_field };
    }
    DEBUG && _w( 1, "Trying to save package info: ", Dumper( $info ) );

    $repos->save_package( $info );
    eval { $repos->save() };
    if ( $@ ) {
        chdir( $base_dir );
        $class->_remove_directory_tree( $full_pkg_dir );
        die "Could not save data to installed package database. " .
            "Error returned: $@ " .
            "Aborting package installation.";
    }
    DEBUG && _w( 1, "Saved repository ok." );
    chdir( $old_pwd );
    return $info;
}


# Install a package from the base OpenInteract directory to a website
# directory. This is known in 'oi_manage' terms as 'applying' a
# package. Note that if you're upgrading the app calling this module
# must first get rid of the old package.

sub install_to_website {
    my ( $class, $base_repository, $website_repository, $info, $CONFIG ) = @_;

    # Be sure to have the website directory, website name, and package
    # directory set

    unless ( $info->{website_name} ) {
        die "Website name not set in package object.\n";
    }
    my $package_name_version = "$info->{name}-$info->{version}";
    $info->{website_dir} ||= $website_repository->{META_INF}{base_dir};
    $info->{package_dir} ||= join( '/', 'pkg', $package_name_version );

    # Then create package directory within the website directory

    my $pkg_dir = join( '/', $info->{website_dir}, $info->{package_dir} );
    if ( -d $pkg_dir ) { die "Package directory $pkg_dir already exists.\n" }
    mkdir( $pkg_dir, 0775 ) || die "Cannot create $pkg_dir : $!";

    # Next move to the base package directory (we return to the original
    # directory just before the routine exits)

    my $pwd = cwd;
    chdir( "$info->{base_dir}/pkg/$package_name_version" );

    # ...then ensure that it has all its files

    my @missing = ExtUtils::Manifest::manicheck;
    if ( scalar @missing ) {
        die "Cannot install package $info->{name}-$info->{version} to website ",
            "-- the base package has files that are specified in MANIFEST missing ",
            "from the filesystem: @missing. Please fix the situation.\n";
    }

    # ...and get all the filenames from MANIFEST

    my $BASE_FILES = ExtUtils::Manifest::maniread;

    # Now create the subdirectories and copy the configs

    $class->create_subdirectories( $pkg_dir, $info->{website_name} );
    $class->_copy_spops_config_file( $info, $CONFIG, 'spops.perl' );
    $class->_copy_spops_config_file( $info, $CONFIG, 'spops.perl.ldap' );
    $class->_copy_action_config_file( $info, $CONFIG );

    # Now copy over the struct/, script/, data/, template/, html/,
    # html/images/ and doc/ files -- intact with no translations, as
    # long as they appear in the MANIFEST file (read in earlier)

    # The value of the subdir key is the root where the files will be
    # copied -- so files in the 'widget' directory of the package will
    # be copied to the 'template/' subdirectory of the website, while
    # the files in the 'data' directory of the package will be copied
    # to the 'data' directory of the *package* in the website.

    my %subdir_match = (
      struct      => "$pkg_dir/struct",
      data        => "$pkg_dir/data",
      template    => "$pkg_dir/template",
      widget      => "$info->{website_dir}/template",
      doc         => "$pkg_dir/doc",
      script      => "$pkg_dir/script",
      html        => "$info->{website_dir}/html" );

    my $pkg_file_list = [ keys %{ $BASE_FILES } ];
    foreach my $sub_dir ( sort keys %subdir_match ) {
        $class->_copy_package_files( $subdir_match{ $sub_dir },
                                     $sub_dir,
                                     $pkg_file_list );
    }

    ########################################
    # TODO: For each file copied over to the /html directory, create a
    # 'page' object in the system for it. Note that we might have to
    # hook this up with the system that ensures we don't overwrite
    # certain files. So we might need to either remove it from the
    # _copy_package_files() routine, or add an argument to that
    # routine that lets us pass in a coderef to execute with every
    # item copied over.

    # ACK -- here's a problem. We don't know if we can even create an
    # $R yet, because (1) the base_page package might not have even
    # been installed yet (when creating a website) and (2) the user
    # hasn't yet configured the database (etc.)

    # We can get around this whenever we rewrite
    # Package/PackageRepository/oi_manage, but until then we will tell
    # people to include the relevant data inserts with packages that
    # include HTML documents.

    # Until then, here's what this might look like :-)

#    # Now do the HTML files, but also create records for each of the
#    # HTML files in the 'page' table

#    my $copied = $class->_copy_package_files( "$info->{website_dir}/html",
#                                              'html',
#                                              $pkg_file_list );
#    my @html_locations = map { s/^html//; $_ } @{ $copied };
#    foreach my $location ( @html_locations ) {
#        my $page = $R->page->fetch( $location, { skip_security => 1 } );
#        next if ( $page );
#        eval {
#            $R->page->new({ location => $location,
#                                       ... })
#                    ->save({ skip_security => 1 });
#        };
#    }

    # Now copy the MANIFEST.SKIP file and package.conf, so we can run
    # 'check_package' on the package directory (once complete) as well as
    # generate a MANIFEST once we're done copying files

    foreach my $root_file ( 'MANIFEST.SKIP', 'package.conf' ) {
        cp( $root_file, "$pkg_dir/$root_file" )
          || _w( 0, "Cannot copy $root_file to $pkg_dir/$root_file : $!" );
    }

    $class->_copy_handler_files( $info, $BASE_FILES );

    # Now go to our package directory and create a new MANIFEST file

    chdir( $pkg_dir );
    $class->_create_manifest();

    # Finally, save this package information to the site

    $website_repository->save_package( $info );
    $website_repository->save();

    chdir( $pwd );
    return $pkg_dir;
}



# Dump the package from the current directory (or the directory
# specified in $p->{directory} into a tar.gz distribution file

sub export {
    my ( $class, $p ) = @_;
    $p ||= {};

    my $old_pwd = cwd;
    chdir( $p->{directory} ) if ( -d $p->{directory} );

    my $cwd = cwd;
    DEBUG && _w( 1, "Current directory exporting from: [$cwd]" );

    # If necessary, Read in the config and ensure that it has all the
    # right information

    my $config_file = $p->{config_file} || $DEFAULT_CONF_FILE;
    my $config = $p->{config} ||
                 eval { $class->read_config( { file => $config_file } ) };
    if ( $@ ) {
        die "Package configuration file cannot be opened -- \n" ,
            "are you chdir'd to the package directory? (Reported reason \n",
            "for failure: $@)\n";
    }
    DEBUG && _w( 2, "Package config read in: ", Dumper( $config ) );

    # Check to ensure that all required fields have something in them; we
    # might do a 'version' check in the future, but not until it proves
    # necessary

    my @missing_fields = ();
    foreach my $required_field ( @EXPORT_REQUIRED ) {
        unless ( $config->{ $required_field } ) {
            push @missing_fields, $required_field;
        }
    }
    if ( scalar @missing_fields ) {
        die "Configuration file exists [$cwd/$DEFAULT_CONF_FILE] ",
            "but is missing the following fields: (",
            join( ', ', @missing_fields ), "). Please add these fields and try again.\n";
    }
    DEBUG && _w( 1, "Required fields ok in package configuration file." );

    # Now, do a check on this package's MANIFEST - are there files in
    # MANIFEST that don't exist?

    warn "Package $config->{name}: checking MANIFEST for discrepancies\n";
    my @missing = ExtUtils::Manifest::manicheck();
    if ( scalar @missing ) {
        warn "\nIf the files specified do not need to be in MANIFEST any longer,\n",
             "please remove them from MANIFEST and re-export the package. Otherwise\n",
             "users installing the package will get a warning.\n";
    }
    else {
        warn "Looks good\n\n";
    }

    # Next see if there are files NOT in the MANIFEST

    warn "Package $config->{name}: checking filesystem for files not in MANIFEST\n";
    my @extra = ExtUtils::Manifest::filecheck();
    if ( scalar @extra ) {
        warn "\nBuilding a package without these files is OK, but you can also\n",
             "add them as necessary to the MANIFEST and re-export the package.\n";
    }
    else {
        warn "Looks good\n\n";
    }

    # Read in the MANIFEST

    my $package_files = ExtUtils::Manifest::maniread();
    DEBUG && _w( 2, "Package info read in:\n", Dumper( $package_files ) );

    # Now, create a directory of this name-version and copy the files

    my $package_id = join( '-', $config->{name}, $config->{version} );
    if ( -d $package_id ) {
        die "Cannot create directory [$cwd/$package_id] to ",
            "archive the package because it already exists.\n";
    }
    mkdir( $package_id, 0777 )
         || die "Cannot create directory [$cwd/$package_id] to ",
                "archive the package! Error: $!";
    {
        local $ExtUtils::Manifest::Quiet = 1;
        ExtUtils::Manifest::manicopy( $package_files, "$cwd/$package_id" );
    }

    # And prepend the directory name to all the files so they get
    # un-archived in the right way

    my @archive_files = map { "$package_id/$_" } keys %{ $package_files };

    # Create the tardist

    my $filename = "$cwd/$package_id.tar.gz";
    if ( -f $filename ) {
        $class->_remove_directory_tree( "$cwd/$package_id" );
        die "Cannot create archive [$filename] - file already exists.\n";
    }
    my $rv = eval { $class->_create_archive( $filename, @archive_files ) };
    die "Error creating archive: $@\n" if ( $@ );

    # And remove the directory we just created

    $class->_remove_directory_tree( "$cwd/$package_id" );

    # Return the filename and the name/version information for the
    # package distribution we just created

    chdir( $old_pwd );
    if ( $rv ) {
        warn "\n";
        return { name    => $config->{name},
                 version => $config->{version},
                 file    => "$filename" };
    }
    die "Cannot create distribution [$filename]. Error: ", Archive::Tar->error(), "\n";
}


#
# check_package
#
# What we check for:
#   package.conf      -- has name, version and author defined; all modules defined exist
#   conf/*.perl       -- pass an 'eval' test (through SPOPS::HashFile)
#   OpenInteract/*.pm -- pass a 'require' test
#   MyApp/*.pm        -- pass a 'require' test
#
# Parameters:
#   package_dir
#   package_name
#   website_name (optional)

sub check {
    my ( $class, $p ) = @_;
    my $status = { ok => 0 };
    if ( ! $p->{package_dir} and $p->{info} ) {
        my $main_dir = $p->{info}{website_dir} || $p->{info}{base_dir};
        $p->{package_dir} = join( '/', $main_dir, $p->{info}{package_dir} );
        $p->{website_name} = $p->{info}{website_name};
    }
    unless ( -d $p->{package_dir} ) {
        die "No valid package dir to check! (Given: $p->{package_dir})";
    }
    my $pwd = cwd;
    chdir( $p->{package_dir} );

    # First ensure the package config exists

    unless ( -f "package.conf" ) {
        $status->{msg} .= "\n-- Package config (package.conf) does not " .
                          "exist in package!\n";
    }
    if ( $p->{website_name} and ! -d "$p->{website_name}/" ) {
        $status->{msg} .= "\n-- Website directory ($p->{website_name}/) " .
                          "does not exist in package!\n";
    }
    return $status if ( $status->{msg} );

    DEBUG && _w( 1, " - package.conf and website_name directory (if app.) ok" );

    # Set this after we do the initial sanity checks

    $status->{ok}++;

    # This is just a warning

    if ( -f 'Changes' ) {
        $status->{msg} .= "\n++ File (Changes) to show package Changelog: ok" ;
    }
    else {
        $status->{msg} .= "\n-- File (Changes) to show package Changelog: DOES NOT EXIST\n" ;
    }

    DEBUG && _w( 1, " - Changes file exists" );

    my $pkg_files = ExtUtils::Manifest::maniread();

    # Now, first go through the config perl files

    my @perl_files = grep /^conf.*\.perl$/, keys %{ $pkg_files };
    foreach my $perl_file ( sort @perl_files ) {
        DEBUG && _w( 1, " checking perl file ($perl_file)" );
        my $filestatus = 'ok';
        my $sig = '++';
        my $obj = eval { SPOPS::HashFile->new({ filename => $perl_file }) };
        if ( $@ ) {
            $status->{ok} = 0;
            $filestatus   = "cannot be read in. $@\n";
            $sig          = '--';
        }
        elsif ( $perl_file =~ /spops/ ) {
            foreach my $spops_key ( keys %{ $obj } ) {
                my $typeof = ref $obj->{ $spops_key } || 'not a reference';
                unless ( $typeof eq 'HASH' ) {
                    $status->{ok} = 0;
                    $filestatus   = "invalid SPOPS configuration: value of each key must be " .
                                    "a hashref and the value [$spops_key] is [$typeof]\n";
                    $sig          = '--';
                }
            }
        }
        $status->{msg} .= "\n$sig File ($perl_file) $filestatus";
    }

    # Next all the .pm files - stick the package directory (cwd) into
    # @INC so we don't have any ambiguity about where the modules
    # being tested come from

    unshift @INC, cwd;

    # We suppress warnings within this block so all the interesting
    # stuff goes into the status

    {
        local $SIG{__WARN__} = sub { return undef };
        my @pm_files = grep /\.pm$/, keys %{ $pkg_files };
        foreach my $pm_file ( sort @pm_files ) {
            DEBUG && _w( 1, " checking module file ($pm_file)" );
            my $filestatus = 'ok';
            my $sig = '++';
            eval { require "$pm_file" };
            if ( $@ ) {
                $status->{ok} = 0;
                $filestatus = "cannot be require'd.\n$@\n";
                $sig = '--';
            }
            $status->{msg} .= "\n$sig File ($pm_file) $filestatus";
        }
    }

    # Check all the .dat files in data/ -- they should be valid perl files.

    my @data_files = grep /^data\/.*\.dat$/, keys %{ $pkg_files };
    foreach my $data_file ( sort @data_files ) {
        DEBUG && _w( 1, " checking data file ($data_file)" );
        my $filestatus = 'ok';
        my $sig = '++';
        eval { $class->read_data_file( $data_file ) };
        if ( $@ ) {
            $status->{ok} = 0;
            $filestatus = "is not a valid Perl structure.\n$@\n";
            $sig = '--';
        }
        $status->{msg} .= "\n$sig File ($data_file) $filestatus";
    }


    # See if all the templates pass a basic syntax test -- do not log
    # 'plugin not found' or 'no providers for template prefix' errors,
    # since we assume those will be ok when it runs in the environment

    require Template;
    my $template = Template->new();
    my @template_files = grep ! /(\.meta|~|\.bak)$/,
                         grep /^(template|widget)/,
                              keys %{ $pkg_files };
    my ( $out );
    my @template_errors_ok = ( 'plugin not found', 'no providers for template prefix', 'file error' );
    my $template_errors_re = '(' . join( '|', @template_errors_ok ) . ')';
    foreach my $template_file ( sort @template_files ) {
        DEBUG && _w( 1, " checking template ($template_file)" );
        my $filestatus = 'ok';
        my $sig = '++';
        eval { $template->process( $template_file, undef, \$out )
                          || die $template->error(), "\n" };
        if ( $@ ) {
            unless ( $@ =~ /$template_errors_re/ ) {
                $status->{ok} = 0;
                $filestatus = "is not a valid Template Toolkit template.\n$@\n";
                $sig = '--';
            }
        }
        $status->{msg} .= "\n$sig File ($template_file) $filestatus";
    }

    # Now open up the package.conf and check to see that name, version
    # and author exist

    DEBUG && _w( 1, " checking package.conf validity" );
    my $config = $class->read_config({ directory => '.' });
    $status->{name} = $config->{name};
    my $conf_msg = '';
    unless ( $config->{name} ) {
        $conf_msg .= "\n-- package.conf: required field 'name' is not defined.";
    }
    unless ( $config->{version} ) {
        $conf_msg .= "\n-- package.conf: required field 'version' is not defined.";
    }
    unless ( $config->{author} ) {
        $conf_msg .= "\n-- package.conf: required field 'author' is not defined.";
    }
    if ( ref $config->{module} eq 'ARRAY' ) {
        my @failed_modules = $class->_check_module_install( @{ $config->{module} } );
        if ( scalar @failed_modules ) {
            $conf_msg .= "\n-- package.conf: the following modules are used by " .
                         "package but not installed: " .
                         "(" . join( ', ', @failed_modules ) . ") " .
                         "INSTALL THESE PACKAGES BEFORE CONTINUING."
        }
    }
    if ( $conf_msg ) {
        $status->{msg} .= "$conf_msg\n";
        $status->{ok}   = 0;
    }
    else {
        $status->{msg} .= "\n++ package.conf: ok";
    }

    # While we have the package.conf open, see if there are any
    # modules and whether they're available



    # Now do the check to ensure that all files in the MANIFEST exist
    # -- just get feedback from the manifest module, don't let it
    # print out results of its findings (Quiet)

    DEBUG && _w( " checking MANIFEST against files" );
    $ExtUtils::Manifest::Quiet = 1;
    my @missing = ExtUtils::Manifest::manicheck();
    if ( scalar @missing ) {
        $status->{msg} .= "\n-- MANIFEST files not all in package. " .
                          "Following not found: \n     " .
                          join( "\n     ", @missing ) . "\n";
    }
    else {
        $status->{msg} .= "\n++ MANIFEST files all exist in package: ok";
    }

    # Now do the check to see if any extra files exist than are in the MANIFEST

    my @extra = ExtUtils::Manifest::filecheck();
    if ( scalar @extra ) {
        $status->{msg} .= "\n-- Files in package not in MANIFEST:\n     " .
                          join( "\n     ", @extra ) . "\n";
    }
    else {
        $status->{msg} .= "\n++ All files in package also in MANIFEST: ok";
    }

    $status->{msg} .= "\n";

    chdir( $pwd );
    return $status;
}

# Copy all modules from a particular package (site directory AND base
# directory) to another directory

sub copy_modules {
    my ( $class, $info, $to_dir ) = @_;

    my $site_pkg_dir = join( '/', $info->{website_dir}, $info->{package_dir} );
    my $site_modules = $class->_copy_module_files( $site_pkg_dir, $to_dir );

    my $base_pkg_dir = join( '/', $info->{base_dir}, $info->{package_dir} );
    my $base_modules = $class->_copy_module_files( $base_pkg_dir, $to_dir );

    return [ sort @{ $base_modules }, @{ $site_modules } ];
}


sub _copy_module_files {
    my ( $class, $pkg_dir, $to_dir ) = @_;
    unless ( -d $pkg_dir ) {
        die "Package directory ($pkg_dir) does not exist -- cannot copy files.\n";
    }
    unless ( -d $to_dir ) {
        die "Destination for package modules ($to_dir) does not exist -- cannot copy files.\n";
    }
    my $current_dir = cwd;
    chdir( $pkg_dir );
    $to_dir =~ s|/$||;
    my $pkg_files = ExtUtils::Manifest::maniread;
    my @module_files = grep /\.pm$/, keys %{ $pkg_files };
    my @module_files_full = ();
    my ( %dir_ok );
    foreach my $filename ( @module_files ) {
        my $full_dest_file = join( '/', $to_dir, $filename );
        #warn "Trying to copy file ($filename) to ($full_dest_file)\n";
        next if ( -f $full_dest_file );
        my $full_dest_dir  = File::Basename::dirname( $full_dest_file );
        unless ( $dir_ok{ $full_dest_dir } ) {
            File::Path::mkpath( $full_dest_dir );
            $dir_ok{ $full_dest_dir }++;
        }
        cp( $filename, $full_dest_file );
        push @module_files_full, $full_dest_file;
    }
    chdir( $current_dir );
    return \@module_files_full;
}


sub read_data_file {
    my ( $class, $filename ) = @_;
    open( D, $filename ) || die "Cannot open: $@";
    local $/ = undef;
    my $raw = <D>;
    close( D );
    my ( $dat );
    {
        no strict 'vars';
        $dat = eval $raw;
        die $@ if ( $@ );
    }
    return $dat;
}

sub remove {
    my ( $class, $repository, $info, $opt ) = @_;
    $repository->remove_package( $info );
    $repository->save();
    my $base_dir = $info->{website_dir} || $info->{base_dir};
    my $full_dir = join( '/', $base_dir, $info->{package_dir} );
    if ( $opt eq 'directory' ) {
        return $class->_remove_directory_tree( $full_dir );
    }
    return 1;
}


sub read_config {
    my ( $class, $p )  = @_;
    if ( ( $p->{info} or $p->{directory} ) and ! $p->{file} ) {
        my $dir = $p->{directory};
        unless ( -d $dir ) {
            $dir = $p->{info}{website_dir} || $p->{info}{base_dir};
            $dir = join( '/', $dir, $p->{info}{package_dir} );
        }
        $p->{file} = join( '/', $dir, $DEFAULT_CONF_FILE );
    }
    unless ( -f $p->{file} ) {
        die "Package configuration file ($p->{file}) does not exist.\n";
    }
    open( CONF, $p->{file} ) || die "Error opening $p->{file}: $!";
    my $config = {};
    while ( <CONF> ) {  
        next if ( /^\s*\#/ );
        next if ( /^\s*$/ );
        chomp;
        s/\r//g;
        s/^\s+//;
        s/\s+$//;
        my ( $k, $v ) = split /\s+/, $_, 2;
        last if ( $k eq 'description' );

        # If there are multiple values possible, make a list

        if ( $CONF_LIST_KEYS{ $k } ) {
            push @{ $config->{ $k } }, $v;
        }

        # Otherwise, if it's a key -> key -> value set; add to list

        elsif ( $CONF_HASH_KEYS{ $k } ) {
            my ( $sub_key, $sub_value ) = split /\s+/, $v, 2;
            $config->{ $k }{ $sub_key } = $sub_value;
        }

        # If not all that, then simple key -> value

        else {
            $config->{ $k } = $v;
        }
    }

    # Once all that is done, read the description in all at once
    {
        local $/ = undef;
        $config->{description} = <CONF>;
    }
    chomp $config->{description};
    close( CONF );
    return $config;
}


# Read in a file (parameter 'from_file') and write it to a file
# (parameter 'to_file'), doing replacements on keys along the way. The
# keys are found in the list 'from_text' and the replacements are
# found in the list 'to_text'.

sub replace_and_copy {
    my ( $class, $p ) = @_;
    unless ( $p->{from_text} and $p->{to_text}
             and $p->{from_file} and $p->{to_file} ) {
        die "Not enough params for copy/replace! ", Dumper( $p ), "\n";
    }
    cp( $p->{from_file}, "$p->{to_file}.old" )
      || die "No copy $p->{from_file} -> $p->{to_file}.old: $!";
  open( OLD, "$p->{to_file}.old" )
      || die "Cannot open copied file: $!";
  open( NEW, "> $p->{to_file}" )
      || die "Cannot open new file: $!";
    while ( <OLD> ) {
        my $line = $_;
        for ( my $i = 0; $i < scalar @{ $p->{from_text} }; $i++ ) {
            $line =~ s/$p->{from_text}->[ $i ]/$p->{to_text}->[ $i ]/g;
        }
        print NEW $line;
    }
    close( NEW );
    close( OLD );
    unlink( "$p->{to_file}.old" )
          || warn qq/Cannot erase temp file (you should do a /,
                  qq/'rm -f `find . -name "*.old"`' after this is done): $!\n/;
}


# Find a file that exists in either the website directory or the base
# installation directory. @file_list defines a number of choices
# available for the file to be named.
#
# Returns: the full path and filename of the first match

sub find_file {
    my ( $class, $info, @file_list ) = @_;
    return undef unless ( scalar @file_list );
    foreach my $base_file ( @file_list ) {
        if ( $info->{website_dir} ) {
            my $filename = join( '/', $info->{website_dir}, $info->{package_dir}, $base_file );
            DEBUG && _w( 1, "Created filename <<$filename>> using the website directory" );
            return $filename if ( -f $filename );
        }
        my $filename = join( '/', $info->{base_dir}, $info->{package_dir}, $base_file );
        DEBUG && _w( 1, "Created filename <<$filename>> using the base installation directory" );
        return $filename if ( -f $filename );
    }
    DEBUG && _w( 1, "No existing filename found matching @file_list" );
    return undef;
}


# Put the base and website package directories into @INC
#
# NOTE: THIS WILL PROBABLY BE REMOVED

sub add_to_inc {
    my ( $class, $info ) = @_;
    my @my_inc = ();
    my $base_package_dir = join( '/', $info->{base_dir}, $info->{package_dir} );
    unshift @my_inc, $base_package_dir  if ( -d $base_package_dir );
    if ( $info->{website_dir} ) {
        my $app_package_dir = join( '/', $info->{website_dir}, $info->{package_dir} );
        unshift @my_inc, $app_package_dir if ( -d $app_package_dir );
    }
    #unshift @INC, @my_inc;
    return @my_inc;
}


sub _check_module_install {
    my ( $class, @modules ) = @_;
    my ( @failed_modules );
MODULE:
    foreach my $module ( @modules ) {
        next unless ( $module );
        if ( $module =~ /\|\|/ ) {
            my @alt_modules = split /\s*\|\|\s*/, $module;
            foreach my $alt_module ( @alt_modules ) {
                eval "require $alt_module";
                next MODULE unless ( $@ );
            }
            push @failed_modules, join( ' or ', @alt_modules );
        }
        else {
            eval "require $module";
            push @failed_modules, $module if ( $@ );
        }
    }
    return @failed_modules;
}


sub _create_archive {
    my ( $class, $filename, @files ) = @_;
    return undef unless ( $filename and scalar @files );
    DEBUG && _w( 2, "Creating archive ($filename) with files:\n", join( ' -- ', @files ) );
    die "file exits" if ( -f $filename );
    my $rv = undef;
    if ( Archive::Tar->VERSION >= 0.20 ) {
        DEBUG && _w( 1, "Creating archive using NEW Archive::Tar syntax." );
        $rv = Archive::Tar->create_archive( $filename, 9, @files );
        unless ( $rv ) { $ARCHIVE_ERROR = Archive::Tar->error() }
    }
    else {
        DEBUG && _w( 1, "Creating archive using OLD Archive::Tar syntax." );
        my $tar = Archive::Tar->new();
        $tar->add_files( @files );
        $tar->write( $filename, 1 );
        if ( $Archive::Tar::error ) {
            $ARCHIVE_ERROR = "Possible errors: $Archive::Tar::error / $@ / $!";
        }
        else {
            $rv++;
        }
    }
    return $rv;
}

# Used to accommodate earlier versions of Archive::Tar (such as those
# shipped with ActivePerl, sigh)

# * You should already be chdir'd to the directory where this will be
# unpacked

# * I'm not sure if the version reference below is correct -- I
# *think* it might be 0.20, but I'm not entirely sure.

sub _extract_archive {
    my ( $class, $filename ) = @_;
    return undef unless ( -f $filename );
    my $rv = undef;
    if ( $Archive::Tar::VERSION >= 0.20 ) {
        $rv = Archive::Tar->extract_archive( $filename );
        unless ( $rv ) { $ARCHIVE_ERROR = Archive::Tar->error() }
    }
    else {
        my $tar = Archive::Tar->new();
        $tar->read( $filename, 1 );
        my @files = $tar->list_files();
        $tar->extract( @files );
        if ( $Archive::Tar::error ) {
            $ARCHIVE_ERROR = "Possible errors: $Archive::Tar::error / $@ / $!";
        }
        else {
            $rv++;
        }
  }
  return $rv;
}


# Copy the spops.perl file from the base install package directory to
# the website package directory Note that we have changed this
# recently (Jan 01) to keep only certain configuration variables
# *behind* -- all others are copied over to the website

# Also, this works with spops.perl AND spops.perl.IMPL, where 'IMPL'
# right now is generally 'ldap'

sub _copy_spops_config_file {
    my ( $class, $info, $CONFIG, $filename ) = @_;
    my $interact_pkg_dir = join( '/', $info->{base_dir}, $info->{package_dir} );
    my $website_pkg_dir  = join( '/', $info->{website_dir}, $info->{package_dir} );

    my $spops_conf = "conf/$filename";

    unless ( -f "$interact_pkg_dir/$spops_conf" ) {
        return undef;
    }
    my $spops_base  = eval { SPOPS::HashFile->new({
                                   filename => "$interact_pkg_dir/$spops_conf" }) };
    if ( $@ ) {
        _w( 0, "Cannot eval $spops_conf in ($info->{name}-$info->{version}): $@" );
        return undef;
    }
    my $new_config_file = "$website_pkg_dir/$spops_conf";
    my $spops_pkg = SPOPS::HashFile->new({
                               filename => $new_config_file,
                               perm => 'new' });

    foreach my $spops_key ( keys %{ $spops_base } ) {

        # Change the class to reflect the website name

        if ( my $old_class = $spops_base->{ $spops_key }{class} ) {
            $spops_pkg->{ $spops_key }{class} = $class->_change_class_name( $info, $old_class );
        }

        # Both the has_a and links_to use class names as keys to link
        # objects; change the class names from 'OpenInteract' to the
        # website name

        if ( my $old_has_a = $spops_base->{ $spops_key }{has_a} ) {
            foreach my $old_class ( keys %{ $old_has_a } ) {
                my $new_class = $class->_change_class_name( $info, $old_class );
                $spops_pkg->{ $spops_key }{has_a}{ $new_class } = $old_has_a->{ $old_class };
            }
        }

        if ( my $old_links_to = $spops_base->{ $spops_key }{links_to} ) {
            foreach my $old_class ( keys %{ $old_links_to } ) {
                my $new_class = $class->_change_class_name( $info, $old_class );
                $spops_pkg->{ $spops_key }{links_to}{ $new_class } = $old_links_to->{ $old_class };
            }
        }

        # Copy over all the fields verbatim except those specified in the
        # global %SPOPS_CONF_KEEP. Note that it's ok we're copying
        # references here since we're going to dump the information to a
        # file anyway

        foreach my $to_copy ( keys %{ $spops_base->{ $spops_key } } ) {
            next if ( $SPOPS_CONF_KEEP{ $to_copy } );
            next if ( ref $spops_base->{ $spops_key }{ $to_copy } eq 'CODE' );

            # For the 'creation_security', we want to check to see if
            # we need to modify the group IDs to match what the server
            # has configured

            if ( $to_copy eq 'creation_security' ) {
                my ( %new_security );
                my $orig = $spops_base->{ $spops_key }{ $to_copy }; # alias to save typing...
                foreach my $scope ( keys %{ $orig } ) { 
                    unless ( $scope eq 'g' ) {
                        $new_security{ $scope } = $orig->{ $scope };
                        next;
                    }
                    next unless ( ref $orig->{g} eq 'HASH' and keys %{ $orig->{g} } );
                    foreach my $scope_id ( keys %{ $orig->{g} } ) {
                        my $new_scope = $scope_id;
                        if ( $scope_id == PUBLIC_GROUP_ID ) {
                            $new_scope = $CONFIG->{default_objects}{public_group} || PUBLIC_GROUP_ID;
                        }
                        elsif ( $scope_id == SITE_ADMIN_GROUP_ID ) {
                            $new_scope = $CONFIG->{default_objects}{site_admin_group} || SITE_ADMIN_GROUP_ID;
                        }
                        $new_security{g}->{ $new_scope } = $orig->{g}{ $scope_id };
                    }
                }
                $spops_pkg->{ $spops_key }{ $to_copy } = \%new_security;
            }
            else {
                $spops_pkg->{ $spops_key }{ $to_copy } = $spops_base->{ $spops_key }{ $to_copy };
            }
        }
    }

    eval { $spops_pkg->save({ dumper_level => 1 }) };
    die "Cannot save package spops file: $@\n"  if ( $@ );
    return $new_config_file;
}


# Copy the conf/action.perl file over from the base installation to
# the website. This is somewhat easier because there are no nested
# classes we need to modify

sub _copy_action_config_file {
    my ( $class, $info, $CONFIG  ) = @_;
    my $interact_pkg_dir = join( '/', $info->{base_dir},
                                      $info->{package_dir} );
    my $website_pkg_dir  = join( '/', $info->{website_dir},
                                      $info->{package_dir} );
    DEBUG && _w( 1, "Coping action info from ($interact_pkg_dir)",
                    "to ($website_pkg_dir)" );

    my $action_conf = 'conf/action.perl';
    my $base_config_file = "$interact_pkg_dir/$action_conf";
    my $action_base = eval { SPOPS::HashFile->new({
                                        filename => $base_config_file }) };
    if ( $@ ) {
        DEBUG && _w( 1, "No action info for $info->{name}-$info->{version}",
                        "(generally ok: $@)" );
        return undef;
    }

    my $new_config_file = "$website_pkg_dir/$action_conf";
    my $action_pkg  = eval { SPOPS::HashFile->new({
                                        filename => $new_config_file,
                                        perm     => 'new' }) };

    # Go through all of the actions and all of the keys and copy them
    # over to the new file. The only modification we make is to a field
    # named 'class': if it exists, we modify it to fit in the website's
    # namespace.

    foreach my $action_key ( keys %{ $action_base } ) {
        foreach my $action_item_key ( keys %{ $action_base->{ $action_key } } ) {
            next if ( ref $action_base->{ $action_key }{ $action_item_key } eq 'CODE' );
            my $value = $action_base->{ $action_key }{ $action_item_key };
            if ( $action_item_key eq 'class' ) {
                if ( $value =~ /^OpenInteract::Handler/ ) {
                    $value = $class->_change_class_name( $info, $value );
                }
            }
            $action_pkg->{ $action_key }{ $action_item_key } = $value;
        }
    }

    eval { $action_pkg->save({ dumper_level => 1 }) };
    die "Cannot save package action file: $@\n"  if ( $@ );
    return $new_config_file;
}


# Copy files from the current (package) directory into a website's
# directory and package

sub _copy_package_files {
    my ( $class, $root_dir, $sub_dir, $file_list ) = @_;
    my @copy_file_list = grep /^$sub_dir/, @{ $file_list };
    my %no_copy = map { $_ => 1 } $class->read_readonly_file( $root_dir );

    foreach my $sub_dir_file ( @copy_file_list ) {
        my $just_filename = $sub_dir_file;
        $just_filename =~ s|^$sub_dir/||;
        my $new_name = join( '/', $root_dir, $just_filename );
        next if ( $no_copy{ $just_filename } );
        eval { $class->_create_full_path( $new_name ) };
        if ( $@ ) { die "Cannot create path to file ($new_name): $@" }
        eval { cp( $sub_dir_file, "$new_name" ) || die $! };
        if ( $@ ) {
            _w( 0, "Cannot copy ($sub_dir_file) to ($new_name) : $@" );
        }
        else {
            chmod( 0775, $new_name );
        }	
    }
    return \@copy_file_list;
}


sub read_readonly_file {
    my ( $class, $dir ) = @_;
    my $overwrite_check_file = join( '/', $dir, READONLY_FILE );
    return () unless ( -f $overwrite_check_file );
    my ( @no_write );
    if ( open( NOWRITE, $overwrite_check_file ) ) {
        while ( <NOWRITE> ) {
            chomp;
            next if ( /^\s*$/ );
            next if ( /^\s*\#/ );
            s/^\s+//;
            s/\s+$//;
            push @no_write, $_;
        }
        close( NOWRITE );
    }
    return @no_write;
}


# Copy handlers from the base installation to the website directory,
# putting class names into the namespace of the website

sub _copy_handler_files {
    my ( $class, $info, $base_files ) = @_;
    my $website_pkg_dir = join( '/', $info->{website_dir},
                                     $info->{package_dir} );

    # We're only operating on the files that begin with
    # 'OpenInteract/Handler'...

    my @handler_file_list = grep /^OpenInteract\/Handler/,
                                 keys %{ $base_files };
    foreach my $handler_filename ( @handler_file_list ) {

        # First create the old/new class names...

        my $handler_class = $handler_filename;
        $handler_class  =~ s|/|::|g;
        $handler_class  =~ s/\.pm$//;
        my $new_handler_class = $class->_change_class_name( $info, $handler_class );
        DEBUG && _w( 1, "Old name: $handler_class; New name: $new_handler_class" );

        # ... then the new filename

        my $new_filename = "$website_pkg_dir/$handler_filename";
        $new_filename =~ s|OpenInteract/Handler|$info->{website_name}/Handler|;

        # Now read in the old handler and write out the new one, replacing
        # the 'OpenInteract::Handler::xx' with '$WEBSITE_NAME::Handler::xx'

        open( OLDHANDLER, $handler_filename )
              || die "Cannot read handler ($handler_filename): $!";
        eval { $class->_create_full_path( $new_filename ) };
        if ( $@ ) {
            die "Cannot create a dir tree to handler ($new_filename): $@";
        }
        open( NEWHANDLER, "> $new_filename" )
              || die "Cannot write to handler ($new_filename): $!";
        while ( <OLDHANDLER> ) {
            s/$handler_class/$new_handler_class/g;
            print NEWHANDLER;
        }
        close( OLDHANDLER );
        close( NEWHANDLER );
    }
    return \@handler_file_list;
}


# auxiliary routine to create necessary directories for a file, given
# the file; die on error, otherwise return a true value

sub _create_full_path {
    my ( $class, $filename ) = @_;
    my $dirname = File::Basename::dirname( $filename );
    return 1 if ( -d $dirname );
    eval { File::Path::mkpath( $dirname, undef, 0755 ) };
    return 1 unless ( $@ );
    _w( 0, "Cannot create path ($dirname): $@" );
    die $@;
}


# Create a manifest file in the current directory. (Note that the
# 'Quiet' and 'Verbose' parameters won't work properly until
# ExtUtils::Manifest is patched which won't likely be until 5.6.1)

sub _create_manifest {
    my ( $class ) = @_;
    local $SIG{__WARN__} = sub { return undef };
    $ExtUtils::Manifest::Quiet   = 1;
    $ExtUtils::Manifest::Verbose = 0;
    ExtUtils::Manifest::mkmanifest();
}


# Remove a directory and all files/directories beneath it. Return the
# number of removed files.

sub _remove_directory_tree {
    my ( $class, $dir ) = @_;
    my $removed_files = File::Path::rmtree( $dir, undef, undef );
    DEBUG && _w( 1, "Removed ($removed_files) files/directories from ($dir)" );
    return $removed_files;
}


# Modify the first argument by replacing 'OpenInteract' with either
# the second argument or the property 'website_name' of the zeroth
# argument.

sub _change_class_name {
    my ( $class, $info, $old_class, $new_name ) = @_;
    if ( ref $info and ! $new_name ) {
        $new_name = $info->{website_name};
    }
    $old_class =~ s/OpenInteract/$new_name/g;
    return $old_class;
}



sub _w {
    my $lev = shift;
    return unless ( DEBUG >= $lev );
    my ( $pkg, $file, $line ) = caller;
    my @ci = caller(1);
    warn "$ci[3] ($line) >> ", join( ' ', @_ ), "\n";
}

1;

__END__

=pod

=head1 NAME

OpenInteract::Package - Perform actions on individual packages

=head1 SYNOPSIS

=head1 DESCRIPTION

This module defines actions to be performed on individual
packages. The first argument for many of the methods that

=head1 METHODS

B<create_subdirectories( $root_dir, $main_class )>

Creates subdirectories in a package directory -- currently the list of
subdirectories is held in the package lexical @PKG_SUBDIR, plus we
also create the directories:

 $main_class
 $main_class/Handler
 $main_class/SQLInstall

If there is no $main_class passed in, 'OpenInteract' is assumed.

B<create_package_skeleton( $package_name, $base_install_dir )>

Creates the skeleton for a package in the current directory. The
skeleton can then be used to for a fully functioning package.

The skeleton creates the directories found in @PKG_SUBDIR and copies a
number of files from the base OpenInteract installation to the
skeleton. These include:

 Changes
 package.conf
 MANIFEST
 MANIFEST.SKIP
 conf/spops.perl
 conf/action.perl
 doc/package.pod
 doc/titles
 template/dummy.meta
 template/dummy.tmpl
 <PackageName>/SQLInstall/<PackageName>.pm
 <PackageName>/Handler/<PackageName>.pm

We fill in as much default information as we know in the files above,
and several of the files have helpful hints about the type information
that goes in each.

B<install_distribution>

Install a package distribution file to the base OpenInteract
installation. We do not need to do any localization work here since we
are just putting the distribution in the base installation, so the
operation is fairly straightforward.

More work and testing likely needs to be done here to ensure it works
on Win32 systems as well as Unix systems. The use of L<File::Spec> and
L<File::Path> should help with this, but there are still issues with
the version of L<Archive::Tar> shipped with ActiveState Perl.

B<install_to_website( \%params )>

Installs a package from the base OpenInteract installation to a
website. The package B<must> already have defined 'website_name',
'website_dir' and 'package_dir' object_properties. Also, the
directory:

 website_dir/pkg/pkg-version

should not exist, otherwise the method will die.

Note that we use the routines C<_copy_spops_config_file()> and
C<_copy_action_config_file()>, which localize the C<spops.perl> and
C<action.perl> configuration files for the website. The localization
consists of changing the relevant class names from 'OpenInteract' to
'MyWebsiteName'.

B<export_package( \%params )>

Exports the package whose root directory is the current directory into
a distribution file in tarred-gzipped format, also placed into the
current directory.

Parameters:

=over 4

=item *

config_file ($) (optional)

Name of configuration file for package.

=item *

config (\%) (optional)

Hashref of package configuration file information.

=back

Returns: Information about the new package in hashref format with the
following keys:

=over 4

=item *

name ($)

Name of package

=item *

version ($)

Version of package

=item *

file ($)

Full filename of distribution file created

=back

B<read_config( \%params )>

Reads in a package configuration file. This file is in a simple
name-value format, although the file supports lists and hashes as
well. Whether a parameter supports a list or a hash is defined in the
package lexical variables %CONF_LIST_KEYS and %CONF_HASH_KEYS. The
reading goes like this:

If a key is not in %CONF_LIST_KEYS or %CONF_HASH_KEYS, it is just a
simple key/value pair; a key in %CONF_LIST_KEYS gets the value pushed
onto a stack, and a key found in %CONF_HASH_KEYS has its value split
on whitespace again and that assigned to the hashref indexed by the
original key. Once we hit the 'description' key, the rest of the file
is read in at once and assigned to the description. Note that comments
and blank lines are skipped until we get to the description when it is
all just slurped in.

Returns: hashref of configuration information with the configuration
keys as hashref keys.

Parameters:

=over 4

=item *

file ($)

Full filename of package file to be read in

=item *

info ($)

Hashref of package information to read package config from

=item *

directory ($)

Directory from which to read the package config.

=back

B<replace_and_copy( \%params )>

Copy a file from one place to another and in the process do a
search-and-replace of certain keys.

Parameters:

=over 4

=item *

from_file ($)

File from which we should read text.

=item *

to_file ($)

File to which we write changed text.

=item *

from_text (\@)

List of keys to replace

=item *

to_text (\@)

Replacement values for each of the keys in 'from_text'

=back

B<copy_modules( $pkg_info, $to_dir )>

Copy all module files (everything ending in C<.pm>) from this package
to a separate directory.

Returns: arrayref with the full destination path of all files copied.

=head1 HELPER METHODS

B<_check_module_install( @modules )>

Check to see if all the C<@modules> are installed on the local
machine. Return value is a list of all modules that are NOT installed,
so an empty list is good.

B<_create_full_path( $filename )>

If necessary, creates the full path necessary to reach
C<$filename>.

Returns: true if the necessary path already exists or was successfully
created, throws a C<die> if it cannot be created.

B<_clean_package_name( $package_name )>

Ensures that the package name can be used in OpenInteract, which
basically checks whether we can turn it into a valid Perl namespace.

Returns: cleaned package name, or throws a C<die> if the errors cannot
be cleaned.

B<_extract_archive( $archive_filename )>

This method is a wrapper around L<Archive::Tar> to try and account for
some of the differences between versions of the module. Errors found
during extraction will be found in the package lexical
C<$ARCHIVE_ERROR>.

Note that before calling this you should already be in the directory
where the archive will be extracted.

B<_create_manifest>

Creates a MANIFEST file in the current directory. This file follows
the same rules as found in L<ExtUtils::Manifest> since we use the
C<mkmanifest()> routine from that module.

Note that we turn on the 'Quiet' and turn off the 'Verbose' parameters
in hopes that the operation will be silent (too confusing), but the
current version of ExtUtils::Manifest does not make its sub-operations
silent. The version shipped with 5.6.1 should take care of this.

B<_remove_directory_tree( $dir )>

Remove a directory and all files/directories beneath it. Return the
number of removed files.

B<_change_class_name( $old_class, $new_name )>

Changes the name from 'OpenInteract' to $new_name within
$old_class. For instance:

 my $old_class = 'OpenInteract::Handler::FormProcess';
 my $new_class = $class->_change_class_name( $old_class, 'MyWebsiteName' );
 print "New class is: $new_class\n";

 >> New class is: MyWebsiteName::Handler::FormProcess

If the method is called from an object and the second argument
($new_name) is not given, we default it to:
C<$object-E<gt>{website_name}>.

=head1 TO DO

Documentation.

=head1 BUGS

None known.

=head1 SEE ALSO

L<OpenInteract::PackageRepository>

=head1 COPYRIGHT

Copyright (c) 2001-2002 intes.net, inc.. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHORS

Chris Winters <chris@cwinters.com>

=cut
