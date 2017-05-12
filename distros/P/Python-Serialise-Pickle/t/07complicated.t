use Test::More qw/no_plan/;
use strict;
use_ok('Python::Serialise::Pickle');


ok(my $ps = Python::Serialise::Pickle->new('t/complicated'));


my $var = { 'a' => [
                   '1',
                   '2',
                   'one',
                   'two',
                   {
                     'foo' => 'bar',
                     'quirka' => [
                                   'f',
                                   'l',
                                   'e'
                                 ]
                   }
                 ],
          'b' => 'something'
	};


ok(my $pw = Python::Serialise::Pickle->new('>t/tmp'));


ok ($pw->dump($var), "dump complicated");
ok ($pw->dump($var), "dump complicated");

ok($pw->close());



#ok(my $pr = Python::Serialise::Pickle->new('t/tmp'));
#is_deeply ($pr->load(), $var,   "dogfood complicated");
#is_deeply ($pr->load(), $var,   "dogfood complicated again");

