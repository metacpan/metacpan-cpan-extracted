use Mojo::Base -strict;

use Test::More;
use Mojolicious::Lite;
use Mojo::Pg;

{
    package Mojo::Promise::Role::Fake;
    use Mojo::Base -role;
    sub the_answer_to_everything {
	return 42;
    }
}

my $class = Mojo::Pg->with_roles('+PromiseClass');
ok(defined $class, "class->with_roles works");
my $pg = $class->new->promise_roles('+Fake');
ok($pg->database_class->does('Mojo::Pg::Database::Role::PgPromiseClass'));

# if (TEST_EVIL) {
#    how to test without Postgresql / DBD::Pg installed?
#
{
    package FakeStmt;
    use Mojo::Base -base;
    sub execute { 1 }
}
{
    package FakeDBH;
    use Mojo::Base -base;
    sub ping { 1 }
    sub prepare_cached { FakeStmt->new }
    sub new { shift->SUPER::new(Active => 1) }
}
sub fake_db {
    my $pg = shift;
    $pg->_enqueue(FakeDBH->new);
    my $db = $pg->db;
    $db->{watching}++;
    return $db;
}
is(fake_db($pg)->query_p('SELECT 1')->the_answer_to_everything, '42');
is(fake_db($pg)->select_p('a_table')->the_answer_to_everything, '42');
#
# }

done_testing();
