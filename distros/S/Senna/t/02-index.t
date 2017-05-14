# $Id: /mirror/Senna-Perl/t/02-index.t 2734 2006-08-17T18:34:18.542025Z daisuke  $
#
# Copyright (c) 2005-2006 Daisuke Maki <dmaki@cpan.org>
# All rights reserved.

use strict;
use Test::More (tests => 17);
use File::Temp;

BEGIN
{
    use_ok("Senna");
    use_ok("Senna::Constants", ":key_size");
}

my $temp  = File::Temp->new(UNLINK => 1);
my $index = Senna::Index->create(
    path => $temp->filename,
);
my $r;

ok($index);
is($index->path, $temp->filename, 
    sprintf("index->path (%s) = temp->filename (%s)", $index->path, $temp->filename));
is($index->key_size, SEN_VARCHAR_KEY,
    sprintf("index->key_size (%s) = SEN_VARCHAR_KEY", $index->key_size));

{ 
    ok($index->insert(key => 'hoge', value => "ほげほげ"));

    $r = $index->select(query => "ほげ");
    ok($r);
    isa_ok($r, "Senna::Records");
    is($r->nhits, 1);
}


{
    ok($index->update(key => 'hoge', old   => "ほげほげ", new => "はげはげ"));

    $r = $index->select(query => "はげ");
    ok($r);
    isa_ok($r, "Senna::Records");
    is($r->nhits, 1);
}


{
    # rev187 fixes a bug in sen_index_select()
    ok($index->delete(key => 'hoge', value => "はげはげ"));
    $r = eval { $index->select(query => "はげ") };

    ok($r);
    isa_ok($r, "Senna::Records");
    is($r->nhits, 0);
}


1;
