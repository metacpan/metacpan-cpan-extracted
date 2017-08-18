#!perl

use strict;
use warnings;

use Test::More;

{
    package My::Component;
    BEGIN { $INC{'My/Component.pm'} = __FILE__ }
    use strict;
    use warnings;

    sub new {
        my $class = shift;
        bless { @_ } => $class;
    }
}

{
    package App;
    use Moxie;

    extends 'Moxie::Object', 'My::Component';

    has 'foo';
    has 'bar' => sub { "BAR" };

    my sub _foo : private(foo);

    sub bar : ro;

    sub REPR {
        my ($class, $proto) = @_;
        $class->My::Component::new( %$proto );
    }

    sub BUILD ($self, $params) {
        _foo = $params->{'foo'};
    }

    sub call { "HELLO " . _foo }
}

my $app = App->new( foo => 'WORLD' );
isa_ok($app, 'App');
isa_ok($app, 'My::Component');

is($app->call, 'HELLO WORLD', '... got the value we expected');
is($app->bar, 'BAR');

{
    package My::DBI;
    BEGIN { $INC{'My/DBI.pm'} = __FILE__ }
    use strict;
    use warnings;

    sub connect {
        my $class = shift;
        my ($dsn) = @_;
        bless { dsn => $dsn } => $class;
    }

    sub dsn { shift->{dsn} }
}

{
    package My::DBI::MOP;
    use Moxie;

    extends 'Moxie::Object', 'My::DBI';

    has 'foo';
    has 'bar' => sub { "BAR" };

    my sub _foo : private(foo);

    sub bar : ro;

    sub connect { (shift)->new( dsn => @_ ) }

    sub REPR {
        my ($class, $proto) = @_;
        $class->My::DBI::connect( $proto->{dsn} );
    }

    sub BUILD ($self, $params) {
        _foo = 'WORLD';
    }

    sub call { "HELLO " . _foo }
}

my $dbh = My::DBI::MOP->connect('dbi:hash');
isa_ok($dbh, 'My::DBI::MOP');
isa_ok($dbh, 'My::DBI');

is($dbh->call, 'HELLO WORLD', '... got the value we expected');
is($dbh->bar, 'BAR');
is($dbh->dsn, 'dbi:hash');

done_testing;
