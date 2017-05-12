#!/usr/bin/perl -w
use strict;
use Test::More;
use DBIx::Connector;

use JSON qw(encode_json decode_json);

my $dbname = $ENV{DBNAME};

plan skip_all => 'set DBNAME for testing' unless $dbname;

my $conn = DBIx::Connector->new("dbi:Pg:dbname=$dbname", $ENV{USER}, '', {
  RaiseError => 1,
  AutoCommit => 1,
});

# Get the database handle and do something with it.
my $dbh  = $conn->dbh;
$dbh->do(_mk_func("postgrest_select", [req => "json"], "json", << 'END'));
({collection, l = 30, sk = 0, q, c}) ->
    query = "select * from #collection"
    [{count}] = plv8.execute "select count(*) from (#query) cnt"
    return { count } if c

    do
        paging: { count, l, sk }
        entries: plv8.execute "#query limit $1 offset $2" [l, sk]
END


# XXX: create table hosts and put some data into it
my $ary_ref = $dbh->selectall_arrayref("select postgrest_select(?)", {}, encode_json({collection => 'hosts', l => 10, sk => 50, c => 1}));
warn Dumper(decode_json($ary_ref->[0][0])) ;use Data::Dumper;

sub _mk_func {
    my ($name, $param, $ret, $body, $lang) = @_;
    my (@params, @args);
    $lang ||= 'plv8';

    while( my ($name, $type) = splice(@$param, 0, 2) ) {
        push @params, "$name $type";
        push @args, $name;
    }

    qq{CREATE OR REPLACE FUNCTION $name (@{[ join(',', @params) ]}) RETURNS $ret AS \$\$
return ($body)(@{[ join(',', @args) ]});
\$\$ LANGUAGE plls IMMUTABLE STRICT;}

}

done_testing;
