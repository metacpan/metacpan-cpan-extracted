package Module::Build::PinwheelApp;

use Pinwheel;
use Module::Build;
use File::Slurp;
use IO::File;

use strict;
use warnings;

use base 'Module::Build';

__PACKAGE__->add_property( 'database_schema' => 'db/schema.sql' );
__PACKAGE__->add_property( 'spec_file' );
__PACKAGE__->add_property( 'rpm_name' );
__PACKAGE__->add_property( 'rpm_description' => 'Web application built using the Pinwheel Framework.' );
__PACKAGE__->add_property( 'rpm_group' => 'Applications/Internet' );
__PACKAGE__->add_property( 'rpm_release' => 1 );


# Add to the defaults
sub _set_defaults {
    my $self = shift;

    $self->SUPER::_set_defaults();
    $self->build_requires->{'Module::Build'} = '0.28';
    $self->build_requires->{'Pinwheel'} = $Pinwheel::VERSION;
    $self->requires->{'Pinwheel'} = $Pinwheel::VERSION;
    
    $self->test_files("t/*/*.t");
}

# Overide the default install_map to just copy everything from blib
sub install_map {
    my ($self) = @_;
    die "Error: install_base is not set" unless $self->install_base;
    # Install everything in blib straight to the install base
    return {
      'read' => '',   # To keep ExtUtils::Install quiet
      'write' => '',
      'blib' => $self->install_base
    };
}

sub find_pinwheel_files {
  my ($self, $dir) = @_;
  my @result;
  local $_; # find() can overwrite $_, so protect ourselves
  my $subr = sub {
    if (-f $File::Find::name && $File::Find::name !~ /\/\./) {
      push @result, $File::Find::name;
    }
  };
  File::Find::find({wanted => $subr, no_chdir => 1}, $dir);
  return \@result;
}

sub copy_all_by_type {
    my ($self, $dir) = @_;
    my $files = $self->find_pinwheel_files($dir);
    foreach my $file (@$files) {
      next if $file =~ /\/\./;
      $self->copy_if_modified(from => $file, to => File::Spec->catfile($self->blib, $file) );
    }
}



sub ACTION_setup_test_db {
    my ($self) = @_;
    
    $self->depends_on('build');

    # Enable Pinwheel test mode
    $ENV{'PINWHEEL_TEST'} = 1;

    # Load the Pinwheel application configuration
    require "./blib/lib/Config/Pinwheel.pm";
    require Pinwheel::Database;
    
    # Drop existing tables
    foreach my $table (Pinwheel::Database::tables()) {
        Pinwheel::Database::do("DROP TABLE \`$table\`;") or
        die "Failed to drop table: $table\n";
    }
    
    # Open the database schema file
    my $schema = new IO::File($self->database_schema) or
    die "Failed to open database schema: $!";
    
    # Go through the file line by line, executing full statements
    my $statement = '';
    while(my $line = <$schema>) {
        next if $line =~ /^\s*--/;    # Ignore comment lines
        next if $line =~ /^\s*$/;     # Ignore blank lines
        $statement .= $line;
        if ($line =~ /;\s*$/) {
            Pinwheel::Database::do($statement) or
            die "Failed to execute SQL: $statement\n";
            $statement = '';
        }
    }
    $schema->close();
}

sub test_dir {
    my ($self, $dir) = @_;
    my $p = $self->{properties};

    # Enable Pinwheel test mode
    $ENV{'PINWHEEL_TEST'} = 1;
    
    # Temporary modification to list of test files 
    local $p->{test_files} = "t/$dir/*.t";
    
    # Protect others against our @INC changes
    local @INC = @INC;
    
    # Make sure we test the module in blib/
    unshift @INC, File::Spec->catdir($p->{base_dir}, $self->blib, 'lib');
    $self->do_tests;
}

sub ACTION_test {
    my ($self) = @_;
    $self->depends_on('setup_test_db');
    $self->test_dir('*');
}

sub ACTION_test_routes {
    my ($self) = @_;
    $self->depends_on('build');
    $self->test_dir('routes');
}

sub ACTION_test_controllers {
    my ($self) = @_;
    $self->depends_on('setup_test_db');
    $self->test_dir('controllers');
}

sub ACTION_test_helpers {
    my ($self) = @_;
    $self->depends_on('build');
    $self->test_dir('helpers');
}

sub ACTION_test_models {
    my ($self) = @_;
    $self->depends_on('setup_test_db');
    $self->test_dir('models');
}



# Override the default build action - just copy stuff to blib
sub ACTION_build {
    my ($self) = @_;
    $self->copy_all_by_type('cgi-bin');
    $self->copy_all_by_type('conf');
    $self->copy_all_by_type('htdocs');
    $self->copy_all_by_type('lib');
    $self->copy_all_by_type('script');
    $self->copy_all_by_type('tmpl');
}

sub _print_spec_requires {
    my ($self,$spec,$hash,$speckey) = @_;
    foreach my $pkg (keys %$hash) {
        my $version = $self->build_requires->{$pkg};
        $pkg =~ s/::/-/g;
        $spec->print("$speckey: perl-$pkg");
        $spec->print(" >= $version") if ($version);
        $spec->print("\n");
    }
}


sub ACTION_spec {
    my ($self) = @_;
    
    # Open the spec file
    my $spec_file = $self->spec_file || $self->dist_name . '.spec';
    unless (-f $spec_file) {
        die "Error: install_base is not set" unless ($self->install_base);
        my $changelog = (-f 'ChangeLog' ? read_file( 'ChangeLog' ) : undef);
        $self->log_info("Creating $spec_file\n");
        my $spec = new IO::File(">$spec_file") or die "Failed to open spec file ($spec_file): $!";
        $spec->print("Name: ".($self->rpm_name || $self->dist_name)."\n");
        $spec->print("Summary: ".$self->dist_abstract."\n");
        $spec->print("Version: ".$self->dist_version."\n");
        $spec->print("Release: ".$self->rpm_release."\n");
        $spec->print("License: ".$self->license."\n");
        $spec->print("Group: ".$self->rpm_group."\n");
        $spec->print("Source: ".$self->dist_dir.".tar.gz\n");
        $spec->print("BuildRoot: %{_tmppath}/%{name}-%{version}-%{release}-root\n");
        $spec->print("BuildArch: noarch\n");
        $self->_print_spec_requires($spec, $self->build_requires, 'BuildRequires');
        $self->_print_spec_requires($spec, $self->requires, 'Requires');
        $spec->print("\n");
        $spec->print("%description\n".$self->rpm_description."\n");
        $spec->print("\n");
        $spec->print("%prep\n");
        $spec->print("%setup -n %{name}-%{version}\n");
        $spec->print("\n");
        $spec->print("%build\n");
        $spec->print("%{__perl} Build.PL\n");
        $spec->print("%{__perl} Build\n");
        $spec->print("\n");
        $spec->print("%install\n");
        $spec->print("%{__rm} -rf %{buildroot}\n");
        $spec->print("PERL_INSTALL_ROOT=\"%{buildroot}\" %{__perl} Build install\n");
        $spec->print("\n");
        $spec->print("%clean\n");
        $spec->print("%{__rm} -rf %{buildroot}\n");
        $spec->print("\n");
        $spec->print("%files\n");
        $spec->print("%defattr(-, root, root, 0755)\n");
        $spec->print($self->install_base . "/*\n");
        $spec->print("\n");
        $spec->print("%changelog\n" . $changelog ."\n") if ($changelog);
        $spec->close();
   }
}

sub ACTION_rpm {
    my ($self) = @_;
    
    $self->depends_on('manifest') unless ( -e 'MANIFEST' );
    $self->depends_on('spec');
    $self->depends_on('distdir');
  
    my $dist_dir = $self->dist_dir;
    my $filename = $dist_dir;
    my $tarball = "$filename.tar.gz";
    
    # Delete an old tarball if it already exists
    $self->delete_filetree($tarball) if (-e $tarball);
    
    # Build the new tarball
    $self->make_tarball($dist_dir, $filename);
    $self->delete_filetree($dist_dir);
    
    # Is the workspace variable set?
    my @ARGS = ();
    push(@ARGS, '--nodeps', '--define', "_topdir $ENV{'WORKSPACE'}") if ($ENV{'WORKSPACE'});
    push(@ARGS, '-ta', $tarball);
    $self->do_system('rpmbuild', @ARGS);
}

1;
