#!/usr/bin/perl
#

use Module::Build;
use strict;


# Create the Build script
my $build = Module::Build->subclass(
    code => q{
        sub test_dir {
            my ($self, $dir) = @_;
            my $p = $self->{properties};
            
            # Temporary modification to list of test files 
            local $p->{test_files} = "t/$dir/*.t";
            
            # Protect others against our @INC changes
            local @INC = @INC;
            
            # Make sure we test the module in blib/
            unshift @INC, File::Spec->catdir($p->{base_dir}, $self->blib, 'lib');
            $self->do_tests;
        }
        
        sub ACTION_testunit {
            my ($self) = @_;
            $self->depends_on('build');
            $self->test_dir('unit');
        }
        
        sub ACTION_testfunc { 
            my ($self) = @_;
            $self->depends_on('build');
            $self->test_dir('func');
        }

        sub ACTION_test_mysql { 
            my ($self) = @_;
            $self->depends_on('build');
            $ENV{'PINWHEEL_TEST_DB'} = 'dbi:mysql:dbname=framework_test;host=localhost';
            $ENV{'PINWHEEL_TEST_USER'} = 'root';
            $ENV{'PINWHEEL_TEST_PASS'} = '';
            $self->test_dir('*');
        }

        ## FIXME: this is a copy of code in Module::Build::PinwheelApp        
        sub ACTION_rpm {
            my ($self) = @_;
            
            #$self->depends_on('spec');
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
    }
)->new(
    module_name => 'Pinwheel',
    license => 'perl',
    build_requires => {
        'Module::Build' => '0.28',
    #test_requires => {
        'Test::Builder' => 0,
        'Test::More' => 0,
        'Test::Harness' => 0,
        'Test::Pod' => '1.20',
        'DBD::SQLite' => '1.14',
        #'Devel::Cover' => 0,
        #'Test::Pod::Coverage' => 0,
    },
    requires => {
        'perl' => '5.8.8',         # 5.8.8 needed for freeze/thaw
        'Carp' => 0,
        'Cwd' => 0,
        'Data::Dumper' => 0,
        'Exporter' => 0,
        'DBI' => '1.52',
        'File::Basename' => 0,
        'File::Find' => 0,
        'File::Slurp' => 0,
        'File::Spec' => 0,
        'FindBin' => 0,
        'Getopt::Std' => 0,
        'PPI' => '1.201',
        'Scalar::Util' => 0,
        'Storable' => 0,
        'Time::Local' => 0,
        'XML::XPath' => '1.13',
        'YAML::Tiny' => '1.25',
    },
    recommends => {
        'Cache::Memcached' => '1.24',
        'DBD::mysql' => 0,
        'DBD::SQLite' => '1.14',
        'HTTP::Daemon' => 0,        # Needed for ./script/server
        'HTML::Entities' => 0,
        'HTTP::Request' => 0,
        'HTTP::Status' => 0,
        'Term::ReadLine' => 0,      # Needed for ./script/console
        'XML::LibXML' => '1.61',
    },
    test_files => "t/*/*.t"
);

$build->create_build_script;
