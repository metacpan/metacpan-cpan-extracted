package Term::ShellKit::DBI;

require Term::ShellKit;
use DBI;
use Data::ShowTable;

######################################################################

use vars qw( $Connection );

sub dbi_connect {
  if ( ! scalar @_ ) {
    $_[0] ||= &{ $Term::ShellKit::SubReadLine }( "DBI connect string: " );
    $_[1] ||= &{ $Term::ShellKit::SubReadLine }( "DBI user name: " ) if ( $_[0] );
    $_[2] ||= &{ $Term::ShellKit::SubReadLine }( "DBI password: " ) if ( $_[1] );
  }
  $_[3] ||= { RaiseError => 1 };
  
  $Connection = DBI->connect( @_ );
}

########################################################################

sub dbi_execute {
  my $sql = shift;
  dbi_connect() unless $Connection;
  
  my $count = ( $sql =~ tr[?][?] );
  my @params;
  my $p_i = 1;
  foreach ( 1 .. $count ) {
    push @params, &{ $Term::ShellKit::SubReadLine }( "Parameter $p_i: " );
    $p_i ++;
  }
  
  my $sth = $Connection->prepare_cached( $sql );
  my $rv = $sth->execute(@params);
  $sth, $rv;
}

sub dbi_do ($) {
  my $sql = shift;
  my ($sth, $rv) = dbi_execute( $sql );
  $sth->finish;
  defined($rv) ? "Query affected ". ($rv < 0 ? 'unknown number of rows' : $rv < 1 ? 'no rows' : $rv < 2 ? '1 row' : ( $rv + 0) . " rows") : "Query failed";
}

sub dbi_fetch ($) {
  my $sql = shift;
  my ($sth, $rv) = dbi_execute( $sql );
  my $cols = $sth->{'NAME'};
  my $types = eval { $sth->{'TYPE'} } || [ ( 'varchar' ) x $#$cols ];
  my $lengths = eval { $sth->{'PRECISION'} } || [ ( 32 ) x $#$cols ];
  my $rows = $sth->fetchall_arrayref( {} );
  $sth->finish;  
  
  my $i = 0;
  ShowBoxTable( 
    $cols, 
    $types, 
    $lengths, 
    sub { 
      if ( shift ) { $i = 0; return 1 } 
      my $row = $rows->[ $i++ ];
      return unless $row;
      map $row->{$_}, @$cols
    }
  );
  return;
}

########################################################################

sub select ($) { dbi_fetch( "select $_[0]" ) }
sub update ($) {    dbi_do( "update $_[0]" ) }
sub insert ($) {    dbi_do( "insert $_[0]" ) }
sub delete ($) {    dbi_do( "delete $_[0]" ) }
sub create ($) {    dbi_do( "create $_[0]" ) }
sub drop ($)   {    dbi_do( "drop $_[0]"   ) }

########################################################################

1;

__END__

=head1 NAME

Term::ShellKit::DBI - Simple DBI shell


=head1 SYNOPSIS

  > perl -Iblib/lib -MTerm::ShellKit -eshell "kit DBI"
  Term::ShellKit: Starting interactive shell; commands include help, exit.
  Activating Term::ShellKit::Commands
  Activating Term::ShellKit::DBI
  
  Term::ShellKit> dbi_connect dbi:AnyData:
  DBI::db=HASH(0x33ed90)
  
  Term::ShellKit> create table foo ( id int, name varchar(42) )
  Query affected 0 rows
  
  Term::ShellKit> insert into foo values (3, 'Joe')
  Query affected 1 rows
  
  Term::ShellKit> insert into foo values (?, ?)      
  Parameter 1: 5
  Parameter 2: Dave
  Query affected 1 rows
  
  Term::ShellKit> select * from foo
  +----+------+
  | id | name |
  +----+------+
  | 3  | Joe  |
  | 5  | Dave |
  +----+------+

  Term::ShellKit> drop table foo
  Query affected 0 rows
  
  Term::ShellKit> exit


=head1 DESCRIPTION

This module ties Term::ShellKit to DBI's general-purpose SQL execution framework.


=head1 SEE ALSO

L<Term::ShellKit>

=cut

