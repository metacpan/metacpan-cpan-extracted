#!/usr/bin/perl

use strict;
use warnings;

=head1 NAME

sql_loader_example.pl

=head1 SYNOPSIS

perl sql_loader_example.pl --url=<schema url> --dbname=<dbname> --dbuser=<dbuser> --dbpass=<dbpass> [ --quiet ]

perl sql_loader_example.pl --url=<schema url> --print_http_headers

perl sql_loader_example.pl --help

=head2 Arguments:

	- Pass the url to use to scrape db schema from with --url flag.
	- specify dbname with --dbname
	- specify dbuser with --dbuser
	- specify dbpass with --dbpass
	- show this screen and exit with --help
	- Test server response by requesting headers only with --print_http_headers flag ( does not rebuild db )
	- do not print any informational messages with --quiet option

The database specified by dbname must already exist and note that this script DROPS all existing tables found, as it is assumed if you are running this script you are either creating a new db for first time or you are rebuilding your db for testing/development purposes.

=head1 DESCRIPTION

screen scrape db schema from intranet and create sql to load into db.

=head1 SEE ALSO

L<SQL::Loader>

=cut

use lib qw( ./lib );

use Getopt::Long;
use SQL::Loader::MySQL;

my $url;
my $print_http_headers;
my $dbname;
my $dbuser;
my $dbpass;
my $help;
my $quiet;

my $args = GetOptions(
	"url=s"	=> \$url, # string
	"dbname=s"	=> \$dbname,
	"dbuser=s"	=> \$dbuser,
	"dbpass=s"	=> \$dbpass,
	"print_http_headers"	=> \$print_http_headers,
	"help"	=> \$help,
	"quiet"	=> \$quiet
);

if ($help) {
	_usage();
}

$print_http_headers ||= 0;

my $loader = SQL::Loader::MySQL->new(
	url	=> $url,
	dbname	=> $dbname,
	dbuser	=> $dbuser,
	dbpass	=> $dbpass,
	print_http_headers	=> $print_http_headers || 0,
	quiet	=> $quiet || 0
);
$loader->run;

sub _usage {
	print <<EOF;
Usage:

perl $0 --url=<schema url> --dbname=<dbname> --dbuser=<dbuser> --dbpass=<dbpass> [ --quiet ]

perl $0 --url=<schema url> --print_http_headers

perl $0 --help

Arguments:

	- Pass the url to use to scrape db schema from with --url flag.
	- specify dbname with --dbname
	- specify dbuser with --dbuser
	- specify dbpass with --dbpass
	- show this screen and exit with --help
	- Test server response by requesting headers only with --print_http_headers flag ( does not rebuild db )
	- do not print any informational messages with --quiet option

The database specified by dbname must already exist and note that this script DROPS all existing tables found, as it is assumed if you are running this script you are either creating a new db for first time or you are rebuilding your db for testing/development purposes.

See also: perldoc $0
EOF

exit 0;
}

__END__

