#!/usr/bin/perl -w

# test new operators submitted by Ben Sommer

use strict;

use lib "t";
use lib "t/misc";
use TestNeeds qw(Set::Object);
use DBConfig;

use Test::More;

my $db_cs = $DBConfig::cs || '';

if ($db_cs !~ /^dbi:Pg/) {
    plan skip_all => "Test without PostgreSQL";
} else {
    plan tests => 6;
}

require "t/Capture.pm";

use Tangram;
use Tangram::Relational;
use Tangram::Schema;

my $schema = Tangram::Relational->schema(
 {
   classes => [
      Fascisto => {
         fields => {
            string   => [ qw( name rank ) ],
            int      => [ qw( serialnumber ) ],
         }
      },
   ]
 }
);

my $output = new Capture();
$output->capture_print();

my @cp = ($db_cs, $DBConfig::user, $DBConfig::passwd);

my $dbh = DBI->connect( @cp, { PrintError => 0 } )
    or skip "could not connect to database", 1;
eval { Tangram::Relational->retreat($schema, $dbh, { PrintError => 0 }) };
eval { Tangram::Relational->deploy($schema, $dbh) };
is( $@, "", "Fascists deployed!" );
my $result = $output->release_stdout();

my $storage = Tangram::Relational->connect( $schema, @cp );


use Fascisto;

my $command_in_chief = Fascisto->new( name => 'GWB',
				      rank => 'C.I.C.',
				      serialnumber => 1, );

my $id = $storage->insert($command_in_chief) || 'no id';

ok($id && $id =~ /\d+/, 'got an ID');

undef $command_in_chief;

my $fascisto = $storage->load($id);

ok( ref $fascisto eq 'Fascisto',
    'revived the not-long-for-this-world fascisto' );

my $fascisto_ = $storage->remote('Fascisto');
my ($fascisto_who_wont_die) = $storage->select
				( $fascisto_,
				  $fascisto_->{name}->match('~*', '^G*')
				);

ok( $fascisto_who_wont_die->{name} eq 'GWB', "hail the fascisto!" );

$fascisto_who_wont_die->{rank} = undef;

$storage->update($fascisto_who_wont_die);

my ($noname_fascisto) = $storage->select( $fascisto_,
					  $fascisto_->{rank}->is_null );

#use Data::Dumper;
#diag( Dumper($noname_fascisto) );

ok( $noname_fascisto->{name} eq 'GWB', 'going, going....' );

$storage->erase($noname_fascisto);

my ($fascisto_alive) = $storage->select( $fascisto_,
				    	 $fascisto_->{serialnumber} == 1);

ok( ! $fascisto_alive, '...gone...phew!' );

1;
