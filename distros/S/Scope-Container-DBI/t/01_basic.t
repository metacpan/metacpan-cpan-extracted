use strict;
use Test::More;
use Test::SharedFork;
use File::Temp qw/tempfile tempdir/;
use Scope::Container;
use Scope::Container::DBI;

{
    my $sc = start_scope_container();
    my ($fh1, $tmp1) = tempfile(UNLINK=>1);

    my $dbh = Scope::Container::DBI->connect("dbi:SQLite:dbname=$tmp1","","");
    ok($dbh);

    my $dbh2 = Scope::Container::DBI->connect("dbi:SQLite:dbname=$tmp1","","");
    ok($dbh2);
    is($dbh,$dbh2);
   
    my $dbh3 = Scope::Container::DBI->connect("dbi:SQLite:dbname=$tmp1","","", { RaiseError => 1 } );
    ok($dbh3);
    isnt($dbh,$dbh3);

    my $dbh4 = Scope::Container::DBI->connect("dbi:SQLite:dbname=$tmp1","","", { RaiseError => 1, ScopeContainerConnectRetry => 2 } );
    ok($dbh4);

    my $dbh5 = Scope::Container::DBI->connect("dbi:SQLite:dbname=$tmp1","","", { RaiseError => 1, ScopeContainerConnectRetry => 2 } );
    ok($dbh5);
    is($dbh4,$dbh5);
}


{
    my $sc = start_scope_container();
    my ($fh1, $tmp1) = tempfile(UNLINK=>1);
    my ($fh2, $tmp2) = tempfile(UNLINK=>1);

    my $dbh = Scope::Container::DBI->connect(
        ["dbi:SQLite:dbname=$tmp1","",""],
        ["dbi:SQLite:dbname=$tmp2","",""],
    );
    ok($dbh);

    my $dbh2 = Scope::Container::DBI->connect(
        ["dbi:SQLite:dbname=$tmp1","",""],
        ["dbi:SQLite:dbname=$tmp2","",""],
    );
    ok($dbh2);
    is($dbh,$dbh2);
}

{
    my ($fh1, $tmp1) = tempfile(UNLINK=>1);
    local $Log::Minimal::PRINT=sub{};
    for (1..10){
        my $dbh = Scope::Container::DBI->connect(
            ["dbi:SQLite:dbname=$tmp1","",""],
            ["dbi:SQLite:fooo=$tmp1","","",{ PrintError=>0,RaiseError =>0}],
        );
        ok($dbh);
    }
}


{
    my $sc = start_scope_container();
    my ($fh1, $tmp1) = tempfile(UNLINK=>0);

    my $dbh = Scope::Container::DBI->connect("dbi:SQLite:dbname=$tmp1","","");
    ok($dbh);
    my $refaddr = "$dbh";

    my $pid = fork();
    if ($pid == 0) {
        my $dbh2 = Scope::Container::DBI->connect("dbi:SQLite:dbname=$tmp1","","");
        ok($dbh2);
        isnt($refaddr, $dbh2);
        exit;
    }
    elsif ( $pid ) {
        waitpid($pid,0);
    }

    unlink($tmp1);
}

{
    my $sc = start_scope_container();
    my $dir = tempdir( CLEANUP => 1 );
    chmod '0400', $dir;

    my $pid = fork();
    if ($pid == 0) {
        sleep 1;
        chmod '0755', $dir;
        exit;
    }

    my $dbh = Scope::Container::DBI->connect("dbi:SQLite:dbname=$dir/foo","","", { RaiseError => 1, ScopeContainerConnectRetry => 4, ScopeContainerConnectRetrySleep => 500 } );
    ok($dbh);

    waitpid($pid,0);
}


done_testing();
