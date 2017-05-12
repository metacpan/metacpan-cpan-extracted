use Test::Most;

{
  package TestObj;
  use Patterns::UndefObject::maybe;

  sub new { return bless \{}, shift }

  sub a { return 'a' }

  sub b { return undef }
}

ok my $t = TestObj->new;
is $t->a, 'a';
is $t->maybe::a, 'a';
ok !eval { $t->b->a; 1}, 'fails as expected';
ok eval { $t->maybe::b->a; 1}, 'Passes';
ok eval { $t->maybe::b->a->c->d; 1}, 'Passes';

done_testing;
