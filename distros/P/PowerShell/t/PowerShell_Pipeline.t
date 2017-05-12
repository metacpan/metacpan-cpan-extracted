use strict;
use warnings;

use lib 't/lib';

use File::Basename;
use File::Spec;
use Log::Any;
use Test::More tests => 6;

BEGIN { use_ok('PowerShell::Pipeline') }

eval {
    require Getopt::Long;
    Getopt::Long::Configure( 'pass_through', 'bundling' );
    my $level = 'error';
    Getopt::Long::GetOptions( 'log:s' => \$level );

    require Log::Any::Adapter;
    Log::Any::Adapter->set( 'Stdout',
        log_level => Log::Any::Adapter::Util::numeric_level($level) );
};

my $logger = Log::Any->get_logger();

my $test_dir = dirname( File::Spec->rel2abs($0) );

{
    $logger->debug("basic pipeline");

    is( PowerShell::Pipeline->new()->add('Mount-DiskImage')->command(),
        'Mount-DiskImage', 'basic one cmdlet' );
    is( PowerShell::Pipeline->new()->add( 'Get-Volume', 'G' )->command(),
        'Get-Volume \'G\'',
        'basic one cmdlet with inline value only param'
    );
    is( PowerShell::Pipeline->new()->add( PowerShell::Cmdlet->new('Mount-DiskImage') )
            ->add( PowerShell::Cmdlet->new('Get-Volume') )->command(),
        'Mount-DiskImage|Get-Volume',
        'basic two cmdlet'
    );
    is( PowerShell::Pipeline->new()->add(
            PowerShell::Cmdlet->new('Mount-DiskImage')->parameter( 'Image', 'C:\\foo\\bar' )
                ->parameter( 'StorageType', 'ISO' )
            )->add( PowerShell::Cmdlet->new('Get-Volume') )->command(),
        'Mount-DiskImage -Image \'C:\\foo\\bar\' -StorageType \'ISO\'|Get-Volume',
        'basic two cmdlet with parameters'
    );
    is( PowerShell::Pipeline->new()->add( 'Mount-DiskImage', [ Image => 'C:\\foo\\bar' ] )
            ->add('Get-Volume')->command(),
        'Mount-DiskImage -Image \'C:\\foo\\bar\'|Get-Volume',
        'basic two cmdlet with inline name/value parameter'
    );
}
