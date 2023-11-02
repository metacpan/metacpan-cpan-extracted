use Test2::V0;
use Test2::Mock;

use SQL::Inserter;

my @prepare = ();
my @execute = ();

my $dbh = mock {} => (
    add => [
        prepare => sub { my $self = shift; push @prepare, @_ ; return $self},
        execute => sub { shift; @execute = @_ ; return 1},
    ]
);

subtest 'single_buffer' => sub {
    my $sql = SQL::Inserter->new(dbh=>$dbh,table=>'table',cols=>[qw/col1 col2/],buffer=>1);

    is($sql->insert(1,2), 1, 'Execute returned 1');
    is([@prepare],["INSERT INTO table (col1,col2)\nVALUES (?,?)"], "Prepared statement");
    is($sql->{last_retval}, 1, "execute");
    is($sql->{row_total}, 1, "row_total");
    is([@execute],[1,2], "Bind variables correct");

    is($sql->insert(1,2,3,4), 1, 'Last execute returned 1');
    is(scalar(@prepare),1, "Reused prepared statement");
    is([@execute],[3,4], "Last execute bind vars");
    is($sql->{row_total}, 3, "New row_total");

    $sql->insert(); ## noop
    $sql->insert({col1=>'a'});
    is([$prepare[1]],["INSERT INTO table (col1,col2)\nVALUES (?,?)"], "New prepared statement");
    is([@execute],['a',undef], "Bind variables correct");
    is($sql->{row_total}, 4, "New row_total");
};

my $dual = "SELECT 1 FROM dual";
subtest 'single_buffer oracle' => sub {
    my $sql = SQL::Inserter->new(dbh=>$dbh,table=>'table',cols=>[qw/col1 col2/],buffer=>1,oracle=>1);
    @prepare = ();

    is($sql->insert(1,2), 1, 'Execute returned 1');
    is([@prepare],["INSERT ALL\nINTO table(col1,col2) VALUES(?,?)\n$dual"], "Prepared statement");
    is($sql->{last_retval}, 1, "execute");
    is($sql->{row_total}, 1, "row_total");
    is([@execute],[1,2], "Bind variables correct");

    is($sql->insert(1,2,3,4), 1, 'Last execute returned 1');
    is(scalar(@prepare),1, "Reused prepared statement");
    is([@execute],[3,4], "Last execute bind vars");
    is($sql->{row_total}, 3, "New row_total");

    $sql->insert(); ## noop
    $sql->insert({col1=>'a'});
    is([$prepare[1]],["INSERT ALL\nINTO table(col1,col2) VALUES(?,?)\n$dual"], "New prepared statement");
    is([@execute],['a',undef], "Bind variables correct");
    is($sql->{row_total}, 4, "New row_total");
};

subtest 'duplicates' => sub {
    my $exp_ignore = ["INSERT IGNORE INTO table (col1,col2)\nVALUES (?,?)"];
    my $exp_update = ["INSERT INTO table (col1,col2)\nVALUES (?,?)\nON DUPLICATE KEY UPDATE col1=VALUES(col1),col2=VALUES(col2)"];

    @prepare = ();
    my $sql = SQL::Inserter->new(dbh=>$dbh,table=>'table',cols=>[qw/col1 col2/],buffer=>1, duplicates=>'ignore');
    $sql->insert(1,2);
    is([@prepare], $exp_ignore, "Prepared statement");
    is([@execute],[1,2], "Bind variables correct");

    @prepare = ();
    $sql->insert({col1=>1,col2=>2});
    is([@prepare], $exp_ignore, "Prepared statement for hash insert");
    is([@execute],[1,2], "Bind variables correct");


    @prepare = ();
    $sql = SQL::Inserter->new(dbh=>$dbh,table=>'table',cols=>[qw/col1 col2/],buffer=>1, duplicates=>'update');
    $sql->insert(1,2);
    is([@prepare],$exp_update, "Prepared statement");
    is([@execute],[1,2], "Bind variables correct");

    @prepare = ();
    $sql->insert({col1=>1,col2=>2});
    is([@prepare], $exp_update, "Prepared statement for hash insert");
    is([@execute],[1,2], "Bind variables correct");
};

subtest 'null_undef' => sub {
    @prepare = ();
    my $sql = SQL::Inserter->new(dbh=>$dbh,table=>'table',cols=>[qw/col1 col2/],buffer=>1, null_undef=>1);
    $sql->insert(1,undef);
    is([@prepare],["INSERT INTO table (col1,col2)\nVALUES (?,?)"], "Prepared statement");
    is([@execute],[1,undef], "Bind variables correct");

    $sql->insert({col2=>1});
    is([$prepare[1]],["INSERT INTO table (col1,col2)\nVALUES (NULL,?)"], "New prepared statement");
    is([@execute],[1], "Bind variables correct");
};

subtest 'multi_buffer' => sub {
    @prepare = ();
    my $sql = SQL::Inserter->new(dbh=>$dbh,table=>'table',cols=>[qw/col1 col2/],buffer=>3);
    is($sql->insert(1,2),0, "No execute");
    is([@prepare],[], "No prepared statement");
    is($sql->{row_total}, undef, "No row_total");

    is($sql->insert(1..12),1, "Execute returned 1");
    is([@prepare],["INSERT INTO table (col1,col2)\nVALUES (?,?),\n(?,?),\n(?,?)"], "Single prepared statement");
    is([@execute],[5..10], "Last execute bind vars");
    is($sql->{row_total}, 2, "Two executes");
    is($sql->{bind}, [11,12], "Two left");

    $sql->insert();
    is($prepare[1],"INSERT INTO table (col1,col2)\nVALUES (?,?)", "Empty buffer prepared statement");
    is([@execute],[11,12], "Last execute bind vars");
    is($sql->{row_total}, 3, "3 executes");

    @prepare = ();
    $sql->insert({});
    is($sql->insert({}),0, "No execute");
    is([@prepare],[], "No prepared statement");
    is($sql->insert({col1=>\"NULL"}), 1, 'Execute returned 1');
    is([@prepare],["INSERT INTO table (col1,col2)\nVALUES (?,?),\n(?,?),\n(NULL,?)"], "Prepared statement");
    is([@execute],[(undef) x 5], "Last execute bind vars");
    is($sql->{row_total}, 4, "4 executes");
    $sql->insert({});
    $sql->insert({});
    $sql->insert({});
    $sql->insert({col2=>\"NOW()"});
    is($prepare[1],"INSERT INTO table (col1,col2)\nVALUES (?,?),\n(?,?),\n(?,?)", "New prepared statement");
    is([@execute],[(undef) x 6], "Last execute bind vars");
    is($sql->{row_total}, 5, "6 executes");
    $sql = undef;
    is($prepare[2],"INSERT INTO table (col1,col2)\nVALUES (?,NOW())", "New prepared statement on destroy");
    is([@execute],[undef], "Last execute bind vars on destroy");

    @prepare = ();
    {
        my $sql = SQL::Inserter->new(dbh=>$dbh,table=>'table',cols=>[qw/col/]);
        $sql->insert(1..102);
        is([@execute],[1..100], "Bind vars");
    }
    is([@execute],[101,102], "Last execute bind vars on destroy");
};

subtest 'multi_buffer oracle' => sub {
    @prepare = ();
    my $sql = SQL::Inserter->new(dbh=>$dbh,table=>'table',cols=>[qw/col1 col2/],buffer=>3,oracle=>1);
    is($sql->insert(1,2),0, "No execute");
    is([@prepare],[], "No prepared statement");
    is($sql->{row_total}, undef, "No row_total");

    is($sql->insert(1..12),1, "Execute returned 1");
    is([@prepare],["INSERT ALL\nINTO table(col1,col2) VALUES(?,?)\nINTO table(col1,col2) VALUES(?,?)\nINTO table(col1,col2) VALUES(?,?)\n$dual"], "Single prepared statement");
    is([@execute],[5..10], "Last execute bind vars");
    is($sql->{row_total}, 2, "Two executes");
    is($sql->{bind}, [11,12], "Two left");

    $sql->insert();
    is($prepare[1],"INSERT ALL\nINTO table(col1,col2) VALUES(?,?)\n$dual", "Empty buffer prepared statement");
    is([@execute],[11,12], "Last execute bind vars");
    is($sql->{row_total}, 3, "3 executes");

    @prepare = ();
    $sql->insert({});
    is($sql->insert({}),0, "No execute");
    is([@prepare],[], "No prepared statement");
    is($sql->insert({col1=>\"NULL"}), 1, 'Execute returned 1');
    is([@prepare],["INSERT ALL\nINTO table(col1,col2) VALUES(?,?)\nINTO table(col1,col2) VALUES(?,?)\nINTO table(col1,col2) VALUES(NULL,?)\n$dual"], "Prepared statement");
    is([@execute],[(undef) x 5], "Last execute bind vars");
    is($sql->{row_total}, 4, "4 executes");
    $sql->insert({});
    $sql->insert({});
    $sql->insert({});
    $sql->insert({col2=>\"NOW()"});
    is($prepare[1],"INSERT ALL\nINTO table(col1,col2) VALUES(?,?)\nINTO table(col1,col2) VALUES(?,?)\nINTO table(col1,col2) VALUES(?,?)\n$dual", "New prepared statement");
    is([@execute],[(undef) x 6], "Last execute bind vars");
    is($sql->{row_total}, 5, "6 executes");
    $sql = undef;
    is($prepare[2],"INSERT ALL\nINTO table(col1,col2) VALUES(?,NOW())\n$dual", "New prepared statement on destroy");
    is([@execute],[undef], "Last execute bind vars on destroy");
};

subtest 'no_cols' => sub {
    my $sql = SQL::Inserter->new(dbh=>$dbh,table=>'table',buffer=>1);
    my $hash = {col1=>'a', col2=>'b', col3=>'c'};
    $sql->insert($hash);
    is([sort @{$sql->{cols}}], [sort keys %$hash], "Cols");
    is([@execute],[map {$hash->{$_}} @{$sql->{cols}}], "Bind variables correct");
    is($sql->{row_total}, 1, "row_total");
};

subtest 'new' => sub {
    my $sql = SQL::Inserter->new(dbh=>{Driver => {Name => 'Oracle'}},table=>'table');
    ok($sql->{oracle}, "Oracle detected");
    $sql = SQL::Inserter->new(dbh=>{Driver => {Name => 'MySQL'}},table=>'table');
    ok(!$sql->{oracle}, "Oracle not detected");
};

done_testing;
