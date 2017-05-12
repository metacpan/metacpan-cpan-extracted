#!/usr/bin/perl -w
$|=1;
use strict;
#use lib  qw( ../lib );
use vars qw($DEBUG);
use Data::Dumper;
use Test::More tests => 2;
use SQL::Statement;
printf "SQL::Statement v.%s\n", $SQL::Statement::VERSION;
$DEBUG=0;
my $p = SQL::Parser->new();
my($stmt,$cache)=(undef,{});
do_(" CREATE TEMP TABLE tbl (c1 INT)   ");
do_(" INSERT INTO tbl VALUES($_) ") for 0..9;  # MySQL LIMIT is 0-based!
ok( '5^6^7^' eq fetchStr("SELECT * FROM tbl ORDER BY c1 LIMIT 5,3")
  , 'limit with order by');
ok( '5^6^7^' eq fetchStr("SELECT * FROM tbl LIMIT 5,3")
  , 'limit without order by');

sub parse {
    my($sql)=@_;
    eval { $stmt = SQL::Statement->new($sql,$p) };
    warn $@ if $@ and $DEBUG;
    return ($@) ? 0 : 1;
}
sub do_ {
    my($sql,@params)=@_;
    @params = () unless @params;
    $stmt = SQL::Statement->new($sql,$p);
    eval { $stmt->execute($cache,@params) };
    return ($@) ? 0 : 1;
}
sub fetchStr {
    my($sql,@params)=@_;
    do_($sql,@params);
    my $str='';
    while (my $r=$stmt->fetch) {
        $str .= sprintf "%s^",join'~',@$r;
    }
    return $str;
}
__DATA__
SELECT a FROM b JOIN c WHERE c=? AND e=7 ORDER BY f DESC LIMIT 5,2
