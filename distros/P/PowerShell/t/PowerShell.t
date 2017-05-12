use strict;
use warnings;

use lib 't/lib';

use File::Basename;
use File::Spec;
use Log::Any;
use POSIX qw(WIFEXITED WEXITSTATUS);
use PowerShell::Pipeline;
use Test::More tests => 2;

BEGIN { use_ok('PowerShell') }

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

SKIP: {
    $logger->debug("basic powershell");
    `which powershell`;
    skip( 'powershell not found', 1 )
        unless ( WIFEXITED( ${^CHILD_ERROR_NATIVE} ) && !WEXITSTATUS( ${^CHILD_ERROR_NATIVE} ) );

    like(
        PowerShell->new( 'Get-Command', 'Get-Command' )
            ->pipe_to( 'Select', [ 'ExpandProperty', 'Name' ] )->execute(),
        qr/Get-Command\s+$/,
        'basic Get-Command'
    );
}
