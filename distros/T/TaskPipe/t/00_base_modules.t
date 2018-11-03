use Test::More;

use strict;
use warnings;

my @base_modules = qw(
    Sample_Stubs
    UserAgentManager_ProxyNet_Open
    Template
    SchemaManager
    Template_Config_Project
    Template_Plan
    Template_Config_Project_SP500
    UserAgentManager_ProxyNet_TOR
    PathSettings
    UserAgentManager_ProxyNet
    PodReader
    Template_Task_ScrapeStub
    Template_Plan_Stub
    Template_Plan_SP500
    UserAgentManager
    TorManager
    PortManager
    Template_Task_SP500ScrapeCompanies
    Template_Config_System
    OpenProxyManager
    Sample_SP500
    Template_Config_Global
    JobManager
    Iterator
    Template_Task_SP500ScrapeQuote
    RunInfo
    Tool
    Sample
    InterpParam
    FileInstaller
    Template_Task
    LoggerManager
    Template_Config
);

my @need_gm = qw();

my @need_gm_and_sm = qw(
    Task
    Task_Scrape
    Task_SourceFromFile
    Task_SourceFromDB
    Task_Record
    ThreadManager
);
    
plan tests => 2 * ( @base_modules + @need_gm + @need_gm_and_sm );

foreach my $bm (@base_modules){

    my $mod = 'TaskPipe::'.$bm;

    require_ok( $mod );

    my $obj = $mod->new;
    isa_ok( $obj, $mod );

}

foreach my $ngm (@need_gm){

    my $mod = 'TaskPipe::'.$ngm;
    require_ok( $mod );

    my $gm = TaskPipe::SchemaManager->new;

    my $obj = $mod->new( gm => $gm );

    isa_ok( $obj, $mod );
}

foreach my $sgm (@need_gm_and_sm){

    my $mod = 'TaskPipe::'.$sgm;
    require_ok( $mod );

    my $gm = TaskPipe::SchemaManager->new;
    my $sm = TaskPipe::SchemaManager->new;

    my $obj = $mod->new( gm => $gm, sm => $sm );

    isa_ok( $obj, $mod );
}


done_testing();

1;





