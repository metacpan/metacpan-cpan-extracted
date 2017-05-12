#!perl
# vim:syn=perl

=head1 NAME

t/dbh.t

=head1 DESCRIPTION

constructor pass / fail tests.

=cut
use strict;
use warnings;
use Test::More tests  => 6;
use lib qw( ./lib );

BEGIN {
	use_ok( 'SQL::Loader::MySQL' );
};

my $loader;
my $dbname = $ENV{LOADER_DBNAME} || 'loader_test';
my $dbuser = $ENV{LOADER_DBUSER} || 'loader_test';
my $dbpass = $ENV{LOADER_DBPASS} || 'loader_test';
my $url = 'http://www.benhare.org/';

# mandatory options
ok( $loader = SQL::Loader::MySQL->new(
	url	=> $url,
	dbname	=> $dbname,
	dbuser	=> $dbuser,
	dbpass	=> $dbpass
), "new Loader - mandatory options" ); 
isa_ok( $loader, 'SQL::Loader::MySQL' );
isa_ok( $loader, 'SQL::Loader' );

SKIP: {
	skip "to enable database connection tests set ENV variable LOADER_DBNAME to database name, LOADER_DBUSER to user, LOADER_DBPASS to dbpass", 2
		unless ( $ENV{LOADER_DBNAME} && $ENV{LOADER_DBUSER} && $ENV{LOADER_DBPASS} );
	ok( my $dbh = $loader->dbh(), "got dbh" );
	isa_ok( $dbh, 'DBI::db' );
};

__END__

=head1 AUTHOR

<benhare@gmail.com>

=cut

