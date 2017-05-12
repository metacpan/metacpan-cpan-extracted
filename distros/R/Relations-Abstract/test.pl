
use DBI;
use Relations;
use Relations::Query;
use lib '.';
use Relations::Abstract;

configure_settings('abs_test','root','','localhost','3306') unless -e "Settings.pm";

eval "use Settings";

$dsn = "DBI:mysql:mysql:$host:$port";

$dbh = DBI->connect($dsn,$username,$password,{PrintError => 1, RaiseError => 0});

# Create a Relations::Abstract object using the database handle

$abs = new Relations::Abstract('fake');

die "create failed" unless ($abs->{dbh} eq 'fake');

$abs->set_dbh($dbh);

die "set_dbh failed" unless ($abs->{dbh} == $dbh);

# Drop, create and use a database

$abs->run_query("drop database if exists $database");
$abs->run_query("create database $database");
$abs->run_query("use $database");

# Create a table

$abs->run_query("
  create table sizes
    (
      size_id int unsigned auto_increment,
      num int unsigned,
      descr varchar(16),
      primary key (size_id),
      unique descr (descr),
      unique num (num),
      index (size_id)
    )
");

$descr = 'Wicked Small';

$abs->insert_row(-table => 'sizes',
                 -set   => {num   => 1,
                            descr => $dbh->quote($descr)});

$item_descr = $abs->select_field(-field => 'descr',
                                 -query => 'select descr from sizes where num=1');

die "insert_row or select_field failed" unless ($descr eq $item_descr);

$new_id = $abs->insert_id(-table => 'sizes',
                          -set   => {num   => 20,
                                     descr => $dbh->quote('Frickin\' Huge')});

$old_id = $abs->select_field(-field => 'size_id',
                             -table => 'sizes',
                             -where => {num => 20});

$qry = new Relations::Query(-select => 'size_id',
                            -from   => 'sizes',
                            -where  => {num => 20});

$qry_id = $abs->select_field(-field => 'size_id',
                             -query => $qry);

die "insert_id or select_field failed" unless (($new_id == $old_id) and  
                                               ($old_id == $qry_id));

$first_id = $abs->select_insert_id(-id    => 'size_id',
                                   -table => 'sizes',
                                   -where => {num   => 7},
                                   -set   => {num   => 7,
                                              descr => $dbh->quote('Average')});

$second_id = $abs->select_insert_id(-id    => 'size_id',
                                    -table => 'sizes',
                                    -where => {num   => 7},
                                    -set   => {num   => 7,
                                               descr => $dbh->quote('Average')});
 
die "select_insert_id failed" unless ($first_id == $second_id);

$row_hash = $abs->select_row(-table => 'sizes',
                             -where => {num => 7});

die "select_rows noquery failed" unless (($row_hash->{num} == 7) &&
                                         ($row_hash->{descr} eq 'Average'));

$qry->set(-select => '*',-where => {num => 7});

$row_hash = $abs->select_row(-query => $qry);

die "select_rows query failed" unless (($row_hash->{num} == 7) &&
                                       ($row_hash->{descr} eq 'Average'));

$abs->update_rows(-table => 'sizes',
                  -where => {num   => 7},
                  -set   => {descr => $dbh->quote('Plain')});

$matrix_ref = $abs->select_matrix(-table => 'sizes',
                                  -where => {1 => 1});

$should_be{'Wicked Small'} = 1;
$should_be{'Plain'} = 1;
$should_be{'Frickin\' Huge'} = 1;

foreach $matrix_row (@$matrix_ref) {

  die "update_rows or select_matrix failed" unless $should_be{$matrix_row->{descr}};

  $should_be{$matrix_row->{descr}} = 0;

}

die "update_rows or select_matrix failed" if ($should_be{'Wicked Small'} || 
                                                      $should_be{'Plain'} || 
                                                      $should_be{'Frickin\' Huge'});

$qry = new Relations::Query(-select => '*',
                            -from   => 'sizes');

$matrix_ref = $abs->select_matrix(-query => $qry);

$should_be{'Wicked Small'} = 1;
$should_be{'Plain'} = 1;
$should_be{'Frickin\' Huge'} = 1;

foreach $matrix_row (@$matrix_ref) {

  die "select_matrix query failed" unless $should_be{$matrix_row->{descr}};

  $should_be{$matrix_row->{descr}} = 0;

}

die "select_matrix query failed" if ($should_be{'Wicked Small'} || 
                                      $should_be{'Plain'} || 
                                      $should_be{'Frickin\' Huge'});

$column_ref = $abs->select_column(-field => 'num',
                                  -table => 'sizes',
                                  -where => {1 => 1});

$should_be[1] = 1;
$should_be[7] = 1;
$should_be[20] = 1;

foreach $column (@$column_ref) {

  die "select_column failed" unless $should_be[$column];

  $should_be[$column] = 0;

}

die "select_column failed" if ($should_be[1] || 
                               $should_be[7] || 
                               $should_be[20]);

$qry->set(-select => 'num');

$column_ref = $abs->select_column(-field => 'num',
                                  -query => $qry);

$should_be[1] = 1;
$should_be[7] = 1;
$should_be[20] = 1;

foreach $column (@$column_ref) {

  die "select_column query failed" unless $should_be[$column];

  $should_be[$column] = 0;

}

die "select_column query failed" if ($should_be[1] || 
                                     $should_be[7] || 
                                     $should_be[20]);

$affected_rows = $abs->delete_rows(-table => 'sizes',
                                   -where => {num => 20});

die "select_column failed" unless $affected_rows == 1;

$abs->run_query("drop database $database") or die "Couldn't drop database";

print "\nEverything seems fine.\n";