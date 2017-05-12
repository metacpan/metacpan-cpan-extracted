#!/usr/bin/perl

use Test::More;
use Template;
use Template::Constants qw( :debug );
use DBI;

if(!$ENV{DBI_DSN})
{
    warn "No DBI_DSN variable set, testing with SQLite, and './testing.db'\n";
    $ENV{DBI_DSN} = 'dbi:SQLite:dbname=./testing.db';
}

BEGIN {
    eval { use DBD::SQLite; };
    plan $@ 
        ? ( skip_all => 'needs DBD::SQLite for testing' )
        : ( tests => 4 );
}

my @auth = ();
@auth = ($ENV{DBI_USER}, $ENV{DBI_PASSWD}) if(defined $ENV{DBI_USER} && defined $ENV{DBI_PASSWD});

my $dbh = DBI->connect($ENV{DBI_DSN}, @auth) or die "Couldn't connect to a database! $DBI::errstr";
# my $newtable = "CREATE TABLE templates (filename VARCHAR(30), modified TIMESTAMP DEFAULT CURRENT_TIMESTAMP, template VARCHAR(1024))";
my $newtable = "CREATE TABLE templates (filename VARCHAR(30), template VARCHAR(1024))";

$dbh->do($newtable) or die "Couldn't create table in DB $DBI::errstr";

my $create_tmpl = "INSERT INTO templates (filename, template) VALUES ('testtemplate.tt', 'A DBI template: [%- content -%]');";
$dbh->do($create_tmpl) or die "Couldn't insert template into DB $DBI::errstr";

BEGIN { use_ok('Template::Provider::DBI'); };

my $dbi = Template::Provider::DBI->new({
    DBI_DBH => $dbh});
isa_ok($dbi, 'Template::Provider::DBI');
isa_ok($dbi, 'Template::Provider');

my $tt2  = Template->new({
    LOAD_TEMPLATES => [ $dbi ],
#    DEBUG => DEBUG_ALL | DEBUG_CALLER,
#     PREFIX_MAP => {
#        dbi     => '0',     # file:foo.html
#        http    => '1',     # http:foo.html
#        default => '0',     # foo.html => file:foo.html
#    }
});

# my $foott = Template->new({});
# $foott->process('testme.tt');

my $output;
$tt2->process('testtemplate.tt', { content => 'Inserted text' }, \$output);

is($output, 'A DBI template: Inserted text', 'Parsed template');

$dbh->do("DROP TABLE templates");

# unlink './testing.db';
