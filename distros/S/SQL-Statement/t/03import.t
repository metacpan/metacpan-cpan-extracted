#!/usr/bin/perl -w
use strict;
use warnings;
use lib qw(t);

use Test::More;
use TestLib qw(connect prove_reqs show_reqs test_dir default_recommended);

my ( $required, $recommended ) = prove_reqs( { default_recommended(), ( MLDBM => 0 ) } );
my ( undef, $extra_recommended ) = prove_reqs( { 'DBD::SQLite' => 0, } );
show_reqs( $required, { %$recommended, %$extra_recommended } );
my @test_dbds = ( 'SQL::Statement', grep { /^dbd:/i } keys %{$recommended} );
my $testdir = test_dir();

my @external_dbds = ( keys %$extra_recommended, grep { /^dbd::(?:dbm|csv)/i } keys %{$recommended} );

foreach my $test_dbd (@test_dbds)
{
    my $dbh;
    note("Running tests for $test_dbd");
    my $temp = "";
    # XXX
    # my $test_dbd_tbl = "${test_dbd}::Table";
    # $test_dbd_tbl->can("fetch") or $temp = "$temp";
    $test_dbd eq "DBD::File"      and $temp = "TEMP";
    $test_dbd eq "SQL::Statement" and $temp = "TEMP";

    my %extra_args;
    if ( $test_dbd eq "DBD::DBM" and $recommended->{MLDBM} )
    {
        $extra_args{dbm_mldbm} = "Storable";
    }
    $dbh = connect(
                    $test_dbd,
                    {
                       PrintError => 0,
                       RaiseError => 0,
                       f_dir      => $testdir,
                       %extra_args,
                    }
                  );

    my $external_dsn;
    if (%$extra_recommended)
    {
        if ( $extra_recommended->{'DBD::SQLite'} )
        {
            $external_dsn = "DBI:SQLite:dbname=" . File::Spec->catfile( $testdir, 'sqlite.db' );
        }
    }
    elsif (@external_dbds)
    {
        if ( $test_dbd eq $external_dbds[0] and @external_dbds > 1 )
        {
            $external_dsn = $external_dbds[1];
        }
        else
        {
            $external_dsn = $external_dbds[0];
        }
        $external_dsn =~ s/^dbd::(\w+)$/dbi:$1:/i;
        my @valid_dsns = DBI->data_sources( $external_dsn, { f_dir => $testdir } );
        $external_dsn = $valid_dsns[0];
    }

    my ( $sth, $str );

    ####################
    # IMPORT($AoA)
    ####################
    $sth = $dbh->prepare("SELECT word FROM IMPORT(?) ORDER BY id DESC");
    my $AoA = [
                [qw( id word    )], [qw( 4  Just    )], [qw( 3  Another )], [qw( 2  Perl    )],
                [qw( 1  Hacker  )],
              ];

    $sth->execute($AoA);
    $str = '';
    while ( my $r = $sth->fetch_row() ) { $str .= "@$r^"; }
    cmp_ok( $str, 'eq', 'Just^Another^Perl^Hacker^', 'IMPORT($AoA)' );

    #######################
    # IMPORT($AoH)
    #######################
    my $aoh = [
                {
                   c1 => 1,
                   c2 => 9
                },
                {
                   c1 => 2,
                   c2 => 8
                }
              ];
    $sth = $dbh->prepare("SELECT C1,c2 FROM IMPORT(?)");
    $sth->execute($aoh);
    $str = '';
    while ( my $r = $sth->fetch_row() ) { $str .= "@$r^"; }
    cmp_ok( $str, 'eq', '1 9^2 8^', 'IMPORT($AoH)' );

    #######################
    # IMPORT($internal_sth)
    #######################
  SKIP:
    {
        skip( "Need DBI statement handle - can't use when executing direct", 7 )
          if ( $dbh->isa('TestLib::Direct') );

        ok( $dbh->do( "CREATE $temp TABLE aoh AS IMPORT(?)", {}, $aoh ), 'CREATE AS IMPORT($aoh)' )
          or diag( $dbh->errstr() );
        $sth = $dbh->prepare("SELECT C1,c2 FROM aoh");
        $sth->execute();
        $str = '';
        while ( my $r = $sth->fetch_row() ) { $str .= "@$r^"; }
        cmp_ok( $str, 'eq', '1 9^2 8^', 'SELECT FROM IMPORTED($AoH)' );

        ok( $dbh->do( "CREATE $temp TABLE aoa AS IMPORT(?)", {}, $AoA ), 'CREATE AS IMPORT($aoa)' )
          or diag( $dbh->errstr() );
        $sth = $dbh->prepare("SELECT word FROM aoa ORDER BY id DESC");
        $sth->execute();
        $str = '';
        while ( my $r = $sth->fetch_row() ) { $str .= "@$r^"; }
        cmp_ok( $str, 'eq', 'Just^Another^Perl^Hacker^', 'SELECT FROM IMPORTED($AoA)' );

        ok( $dbh->do("CREATE $temp TABLE tbl_copy AS SELECT * FROM aoa"), 'CREATE AS SELECT *' )
          or diag( $dbh->errstr() );
        $sth = $dbh->prepare("SELECT * FROM tbl_copy ORDER BY id ASC");
        $sth->execute();
        $str = '';
        while ( my $r = $sth->fetch_row() ) { $str .= "@$r^"; }
        cmp_ok( $str, 'eq', '1 Hacker^2 Perl^3 Another^4 Just^', 'SELECT FROM "SELECTED(*)" tbl_copy' );

        ok( $dbh->do("CREATE $temp TABLE tbl_extract AS SELECT * FROM aoa WHERE word LIKE 'H%'"), 'CREATE AS SELECT * with quoted restriction' )
          or diag( $dbh->errstr() );
        $sth = $dbh->prepare("SELECT * FROM tbl_extract ORDER BY id ASC");
        $sth->execute();
        $str = '';
        while ( my $r = $sth->fetch_row() ) { $str .= "@$r^"; }
        cmp_ok( $str, 'eq', '1 Hacker^', 'SELECT FROM "SELECTED(*)" tbl_extract' );

        $dbh->do($_) for split /\n/, <<"";
        CREATE $temp TABLE tmp (id INTEGER, xphrase VARCHAR(30))
        INSERT INTO tmp VALUES(1,'foo')

        my $internal_sth = $dbh->prepare('SELECT * FROM tmp')->{sth};    # XXX breaks abstraction
        $internal_sth->execute();
        $sth = $dbh->prepare('SELECT * FROM IMPORT(?)');
        $sth->execute($internal_sth);
        $str = '';
        while ( my $r = $sth->fetch_row() ) { $str .= "@$r^"; }
        cmp_ok( $str, 'eq', '1 foo^', 'IMPORT($internal_sth)' );
    }

    #######################
    # IMPORT($external_sth)
    #######################
  SKIP:
    {
        skip( 'No external usable data source installed', 2 ) unless ($external_dsn);

        my $xb_dbh = DBI->connect($external_dsn);
        $xb_dbh->do($_) for split /\n/, <<"";
    CREATE TABLE xb (id INTEGER, xphrase VARCHAR(30))
    INSERT INTO xb VALUES(1,'foo')

        my $xb_sth = $xb_dbh->prepare('SELECT * FROM xb');
        $xb_sth->execute();

        $sth = $dbh->prepare('SELECT * FROM IMPORT(?)');
        $sth->execute($xb_sth);
        $str = '';
        while ( my $r = $sth->fetch_row() ) { $str .= "@$r^"; }
        cmp_ok( $str, 'eq', '1 foo^', 'SELECT IMPORT($external_sth)' );

      SKIP:
        {
            skip( "Need DBI statement handle - can't use when executing direct", 2 )
              if ( $dbh->isa('TestLib::Direct') );

            $xb_sth = $xb_dbh->prepare('SELECT * FROM xb');
            $xb_sth->execute();

            ok( $dbh->do( "CREATE $temp TABLE xbi AS IMPORT(?)", {}, $xb_sth ),
                'CREATE AS IMPORT($sth)' )
              or diag( $dbh->errstr() );
            $sth = $dbh->prepare('SELECT * FROM xbi');
            $sth->execute();
            $str = '';
            while ( my $r = $sth->fetch_row() ) { $str .= "@$r^"; }
            cmp_ok( $str, 'eq', '1 foo^', 'SELECT FROM IMPORTED ($external_sth)' );
        }

        $xb_dbh->do("DROP TABLE xb");
    }
}

done_testing();
