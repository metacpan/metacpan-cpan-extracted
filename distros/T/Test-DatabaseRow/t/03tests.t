#!/usr/bin/perl -w

use strict;

use Test::More tests => 17;

use Test::DatabaseRow;
use Test::Builder::Tester;

$Test::DatabaseRow::dbh = FakeDBI->new();

# cope with the fact that regular expressions changed
# stringification syntax in 5.13.6
my $DEFAULT = $] >= 5.01306 ? '^' : '-xism';

test_out("ok 1 - matches");
row_ok(table => "dummy",
       where => [ dummy => "dummy" ],
       label => "matches");
test_test("no tests");

test_out("ok 1 - matches");
row_ok(table => "dummy",
       where => [ dummy => "dummy" ],
       tests => [ fooid => 123,
                  name  => "fred",
                  name  => qr/re/  ],
       description => "matches");
test_test("matching with shortcut");

test_out("ok 1 - matches");
row_ok(table => "dummy",
       where => [ dummy => "dummy" ],
       tests => { "==" => { fooid => 123    },
                  "eq" => { name  => "fred" },
                  "=~" => { name  => qr/re/ },},
       label => "matches");
test_test("matching without shortcut");

test_out("ok 1 - simple db test");
row_ok(table => "dummy",
       where => [ dummy => "dummy" ],
       tests => { "==" => { fooid => 123    },
                  "eq" => { name  => "fred" },
                  "=~" => { name  => qr/re/ },},);
test_test("default test name");

test_out("not ok 1 - matches");
test_fail(+4);
test_diag("While checking column 'fooid' on 1st row");
test_diag("         got: 123");
test_diag("    expected: 124");
row_ok(table => "dummy",
       where => [ dummy => "dummy" ],
       tests => [ fooid => 124,
                  name  => "fred",
                  name  => qr/re/  ],
       label => "matches");
test_test("failing ==");

test_out("not ok 1 - matches");
test_fail(+7);
test_diag("While checking column 'fooid' on 1st row");
test_diag("         got: 123");
test_diag("    expected: 124");
test_diag("The SQL executed was:");
test_diag("  SELECT * FROM dummy WHERE dummy = qtd<dummy>");
test_diag("on database 'bob'");
row_ok(table => "dummy",
       where => [ dummy => "dummy" ],
       tests => [ fooid => 124,
                  name  => "fred",
                  name  => qr/re/  ],
       label => "matches",
       verbose => 1);
test_test("failing == verbose");

test_out("not ok 1 - matches");
test_fail(+9);
test_diag("While checking column 'fooid' on 1st row");
test_diag("         got: 123");
test_diag("    expected: 124");
test_diag("The SQL executed was:");
test_diag("  SELECT * FROM dummy WHERE dummy = ?");
test_diag("The bound parameters were:");
test_diag("  'dummy'");
test_diag("on database 'bob'");
row_ok(sql => [ "SELECT * FROM dummy WHERE dummy = ?", "dummy"],
       tests => [ fooid => 124,
                  name  => "fred",
                  name  => qr/re/  ],
       label => "matches",
       verbose => 1);
test_test("failing == verbose bind");

test_out("not ok 1 - matches");
test_fail(+4);
test_diag("While checking column 'name' on 1st row");
test_diag(qq{         got: 'fred'});
test_diag(qq{    expected: 'frea'});
row_ok(table => "dummy",
       where => [ dummy => "dummy" ],
       tests => [ fooid => 123,
                  name  => "frea",
                  name  => qr/re/  ],
       label => "matches");
test_test("failing eq");

test_out("not ok 1 - matches");
test_fail(+7);
test_diag("While checking column 'name' on 1st row");
test_diag(qq{         got: 'fred'});
test_diag(qq{    expected: 'frea'});
test_diag("The SQL executed was:");
test_diag("  SELECT * FROM dummy WHERE dummy = qtd<dummy>");
test_diag("on database 'bob'");
row_ok(table => "dummy",
       where => [ dummy => "dummy" ],
       tests => [ fooid => 123,
                  name  => "frea",
                  name  => qr/re/  ],
       label => "matches",
       verbose => 1);
test_test("failing eq verbose");

test_out("not ok 1 - matches");
test_fail(+5);
test_diag("While checking column 'name' on 1st row");
test_diag(qq{    'fred'});
test_diag(qq{        =~});
test_diag(qq{    '(?$DEFAULT:rd)'});
row_ok(table => "dummy",
       where => [ dummy => "dummy" ],
       tests => [ fooid => 123,
                  name  => "fred",
                  name  => qr/rd/  ],
       label => "matches");
test_test("failing =~");

test_out("not ok 1 - matches");
test_fail(+8);
test_diag("While checking column 'name' on 1st row");
test_diag(qq{    'fred'});
test_diag(qq{        =~});
test_diag(qq{    '(?$DEFAULT:rd)'});
test_diag("The SQL executed was:");
test_diag("  SELECT * FROM dummy WHERE dummy = qtd<dummy>");
test_diag("on database 'bob'");
row_ok(table => "dummy",
       where => [ dummy => "dummy" ],
       tests => [ fooid => 123,
                  name  => "fred",
                  name  => qr/rd/  ],
       label => "matches",
       verbose => 1);
test_test("failing =~ verbose");

test_out("not ok 1 - matches");
test_fail(+5);
test_diag("While checking column 'fooid' on 1st row");
test_diag(qq{    '123'});
test_diag(qq{        <});
test_diag(qq{    '12'});
row_ok(table => "dummy",
       where => [ dummy => "dummy" ],
       tests => { "<", { fooid => 12 }},
       label => "matches");
test_test("failing <");

test_out("not ok 1 - matches");
test_fail(+5+3);
test_diag("While checking column 'fooid' on 1st row");
test_diag(qq{    '123'});
test_diag(qq{        <});
test_diag(qq{    '12'});
test_diag("The SQL executed was:");
test_diag("  SELECT * FROM dummy WHERE dummy = qtd<dummy>");
test_diag("on database 'bob'");
row_ok(table => "dummy",
       where => [ dummy => "dummy" ],
       tests => { "<", { fooid => 12 }},
       label => "matches",
       verbose => 1);
test_test("failing < verbose");

test_out("not ok 1 - matches");
test_fail(+2);
test_diag("No matching row returned");
row_ok(dbh   => FakeDBI->new(nomatch => 1),
       sql   => "dummy",
       tests => [ "fooid" => 1 ],
       label => "matches");
test_test("no returned data");

test_out("not ok 1 - matches");
test_fail(+7);
test_diag("No matching row returned");
test_diag("The SQL executed was:");
test_diag("  foo");
test_diag("  bar");
test_diag("  baz");
test_diag("on database 'bob'");
row_ok(dbh   => FakeDBI->new(nomatch => 1),
       sql   => "foo\nbar\nbaz",
       tests => [ "fooid" => 1 ],
       label => "matches",
       verbose => 1);
test_test("no returned data verbose 1");


test_out("not ok 1 - matches");
test_fail(+5);
test_diag("No matching row returned");
test_diag("The SQL executed was:");
test_diag("  SELECT * FROM foo WHERE fooid = qtd<1>");
test_diag("on database 'bob'");
row_ok(dbh   => FakeDBI->new(nomatch => 1),
       table => "foo",
       where => [ "fooid" => 1 ],
       tests => [ "fooid" => 1 ],
       label => "matches",
       verbose => 1);
test_test("no returned data verbose 2");

test_out("ok 1 - right");
row_ok(table => "dummy",
       where => [ dummy => "dummy" ],
       label => "wrong",
       description => "right");
test_test("description trumps label");

# fake database package
package FakeDBI;
sub new { my $class = shift; return bless { @_, Name => "bob" }, $class };
sub quote { return "qtd<$_[1]>" };

sub prepare
{
  my $this = shift;

  # die if we need to
  if ($this->fallover)
    { die "Khaaaaaaaaaaaaan!" }

  return FakeSTH->new($this);
}

sub nomatch  { return $_[0]->{nomatch} }
sub fallover { return $_[0]->{fallover} }

package FakeSTH;
sub new { return bless { parent => $_[1] }, $_[0] };
sub execute { return 1 };
sub fetchrow_hashref
{
  my $this = shift;
  my $parent = $this->{parent};

  # return undef after the first call)
  if ($this->{called})
    { return }
  else
    { $this->{called} = 1 }

  return
    ($parent->nomatch)
     ?  ()
     : { fooid => 123, name => "fred" }
}
