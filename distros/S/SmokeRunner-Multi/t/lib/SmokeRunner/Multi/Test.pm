use SmokeRunner::Multi::Test;

use strict;
use warnings;

use File::Copy qw( copy );
use File::Find::Rule;
use File::Path qw( mkpath );
use File::Spec;
use File::Temp qw( tempdir );
use YAML::Syck qw( DumpFile );

use base 'Exporter';

our @EXPORT
    = qw( test_setup write_t_files write_four_sets
          write_smolder_config root_dir set_dir test_dir );


{
    my $RootDir = tempdir( CLEANUP => 1 );
    my $ConfigFile = File::Spec->catfile( $RootDir, 'config.yml' );
    $ENV{SMOKERUNNER_CONFIG} = $ConfigFile;
    my $SetDir = File::Spec->catdir( $RootDir, 'set1' );
    my $TestDir = File::Spec->catdir( $SetDir,  't' );

    my %BaseConfig = ( root     => $RootDir,
                       runner   => 'Prove',
                       reporter => 'Test',
    );

    sub test_setup
    {
        DumpFile( $ConfigFile, \%BaseConfig );
    }

    sub root_dir { return $RootDir }
    sub config_file { return $ConfigFile }
    sub set_dir { return $SetDir }
    sub test_dir { return $TestDir }

    sub write_t_files
    {
        my $dir = shift || $TestDir;

        mkpath( $dir, 0, 0755 )
            unless -d $dir;

        my $source = File::Spec->catdir( 't', 'set' );

        for my $file ( qw( 01-a-t 02-b-t ) )
        {
            my $source = File::Spec->catfile( $source, $file );
            my $target = File::Spec->catfile( $dir, $file );
            $target =~ s/-t$/.t/;

            copy( $source => $target )
                or die "Cannot copy $source => $target: $!";
        }
    }

    sub write_four_sets
    {
        my $t1 = File::Spec->catdir( root_dir(), 'set1', 't' );
        write_t_files($t1);

        my $t2 = File::Spec->catdir( root_dir(), 'set2', 't' );
        write_t_files($t2);

        my $t3 = File::Spec->catdir( root_dir(), 'set3', 't' );
        write_t_files($t3);

        my $t4 = File::Spec->catdir( root_dir(), 'set4', 't' );
        write_t_files($t4);

        my $age = 3600;
        for my $dir ( $t4, $t3, $t2 )
        {
            my $past = time - $age;

            utime $past, $past, File::Find::Rule->file()->in($dir);

            $age += 3600;
        }
    }

    my %SmolderConfig = ( server   => 'http://localhost/',
                          username => 'username',
                          password => 'password',
                          project  => 'testing',
                        );

    sub write_smolder_config
    {
        DumpFile( $ConfigFile, { %BaseConfig, smolder => \%SmolderConfig } );

        # Hack!
        $SmokeRunner::Multi::Config::_instance = undef;
    }
}


1;
