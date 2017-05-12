#!perl
# vim:syn=perl

=head1 NAME

t/constructs.t

=head1 DESCRIPTION

constructor pass / fail tests.

=cut
use strict;
use warnings;
use Test::More tests  => 16;
use Test::Exception;
use lib qw( ./lib );

BEGIN {
	use_ok( 'SQL::Loader::MySQL' );
};

my $loader;
my $dbname = $ENV{LOADER_DBNAME} || 'loader_test';
my $dbuser = $ENV{LOADER_DBUSER} || 'loader_test';
my $dbpass = $ENV{LOADER_DBPASS} || 'loader_test';
my $url = 'http://www.benhare.org/';

# no options
dies_ok { $loader = SQL::Loader::MySQL->new() } "new Loader failed ( died ) - mandatory arguments not present";

# call constructor on base class
dies_ok { $loader = SQL::Loader->new() } "new Loader failed ( died ) - base class called directly";

# server response test only option
ok( $loader = SQL::Loader::MySQL->new(
	print_http_headers	=> 1,
	url	=> $url
), "new Loader - server response test only" );
isa_ok( $loader, 'SQL::Loader::MySQL' );
isa_ok( $loader, 'SQL::Loader' );

# mandatory options
ok( $loader = SQL::Loader::MySQL->new(
	url	=> $url,
	dbname	=> $dbname,
	dbuser	=> $dbuser,
	dbpass	=> $dbpass
), "new Loader - mandatory options" ); 
isa_ok( $loader, 'SQL::Loader::MySQL' );
isa_ok( $loader, 'SQL::Loader' );

# test init params set
ok( $loader->url eq $url, "url param correct" ); 
ok( $loader->dbname eq $dbname, "dbname param correct" ); 
ok( $loader->dbuser eq $dbuser, "dbuser param correct" ); 
ok( $loader->dbpass eq $dbpass, "dbpass param correct" ); 
my $class = ref $loader;
ok( $loader->initialized() == 1, "$class initialized" );

# subclass implements required methods
can_ok( $loader, ( 'create_table' ) );
can_ok( $loader, ( 'connect_string' ) );

__END__

=head1 AUTHOR

<benhare@gmail.com>

=cut

