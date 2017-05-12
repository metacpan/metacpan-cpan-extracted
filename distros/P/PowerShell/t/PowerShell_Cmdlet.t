use strict;
use warnings;

use lib 't/lib';

use File::Basename;
use File::Spec;
use Log::Any;
use Test::More tests => 5;

BEGIN { use_ok('PowerShell::Cmdlet') }

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
    $logger->debug("basic cmdlet");

    is( PowerShell::Cmdlet->new('Mount-DiskImage')->command(),
        'Mount-DiskImage', 'basic no parameters' );
    is( PowerShell::Cmdlet->new('Mount-DiskImage')->parameter( Image => 'C:\\foo\\bar' )
            ->command(),
        'Mount-DiskImage -Image \'C:\\foo\\bar\'',
        'basic one parameter'
    );
    is( PowerShell::Cmdlet->new('Mount-DiskImage')->parameter( Image => 'C:\\foo\\bar' )
            ->parameter( StorageType => 'ISO' )->command(),
        'Mount-DiskImage -Image \'C:\\foo\\bar\' -StorageType \'ISO\'',
        'basic two parameter'
    );
    is( PowerShell::Cmdlet->new('Get-Volume')->parameter('G')->command(),
        'Get-Volume \'G\'',
        'basic one param no value'
    );
}
