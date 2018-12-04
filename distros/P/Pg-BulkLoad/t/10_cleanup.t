use 5.020;
use Try::Tiny;
use Mojo::Pg;
use Carp;
use Test::More;

=pod

This test is just the cleanup for the database from 01.
by moving the cleanup to a seperate test file the last state
of the database is left in tact for the developer to examine 
if the this test isn't run after them main tests in 01.

=cut

diag( "DB_TESTING VALUE $ENV{DB_TESTING}" );

sub db_clean {
    my $dbname     = 'postgres';
    my $host       = 'localhost';
    my $port       = 5432;
    my $username   = 'postgres';
    my $password   = 'postgres';
    my $pgpostgres = Mojo::Pg->new();
    my $dsn        = "DBI:Pg:dbname=$dbname;host=$host;port=$port;";
    $pgpostgres->dsn($dsn);
    $pgpostgres->username($username);
    $pgpostgres->password($password);

    try { $pgpostgres->db->query('DROP DATABASE testbulkload') }
    catch { croak "result of drop db = $_"; };  
} 


SKIP: {
      skip 'Cleanup Test Script, Nothing to do if Mocked DB Testing', 
      undef unless $ENV{DB_TESTING};

ok( db_clean() , 'dropped database successfully' );

} ; #SKIP

done_testing;