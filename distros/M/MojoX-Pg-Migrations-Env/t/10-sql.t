use Mojo::Base -strict, -signatures;

use lib 'lib';
use lib 'local/lib/perl5';

use Test2::V0;
use Mojo::File qw(path);
use Mojo::Pg::Migrations;

use MojoX::Pg::Migrations::Env;

# A subclass that knows more about its migrations than their version, and counts how often it is asked
package Local::Migrations::Labelled {
    use Mojo::Base 'MojoX::Pg::Migrations::Env', -signatures;

    has asked => 0;

    sub label_for ( $self, $version )
    {
        $self->asked( $self->asked + 1 );
        return "Migration $version (needs-env-$version)";
    }

    sub sql_for ( $self, $from, $to ) { return $self->SUPER::sql_for( $from, $to ) }
}

my $fixtures = path('t/fixtures');

sub load ( $file, %env )
{
    return MojoX::Pg::Migrations::Env->new( name => 'test', env => {%env} )->from_file( $fixtures->child($file) );
}

# Up sql of a single migration holding $sql, without the marker line
sub render ( $sql, %env )
{
    my $m = MojoX::Pg::Migrations::Env->new( env => {%env} )->from_string("-- 1 up\n$sql\n");
    return $m->sql_for( 0, 1 ) =~ s/\A-- 1 up\n//r =~ s/\n\z//r;
}

sub placeholders ($sql)
{
    return MojoX::Pg::Migrations::Env->new( env => {} )->from_string("-- 1 up\n$sql\n")->placeholders(1);
}

subtest 'sql without placeholders is what the parent produces' => sub {
    my $plain  = $fixtures->child('plain.sql');
    my %source = (
        from_string => [ $plain->slurp ],
        from_file   => ["$plain"],
        from_dir    => [ $fixtures->child('plain')->to_string ],
        from_data   => [ 'main', 'plain' ],
    );

    # Older versions of the parent have no from_dir
    for my $loader ( grep { Mojo::Pg::Migrations->can($_) } sort keys %source ) {
        my $parent = Mojo::Pg::Migrations->new->$loader( @{ $source{$loader} } );
        my $m      = MojoX::Pg::Migrations::Env->new( env => {} )->$loader( @{ $source{$loader} } );
        isa_ok $m, 'Mojo::Pg::Migrations';
        is $m->latest, $parent->latest, "$loader: latest";
        is $m->latest, 10,              "$loader: migrations are loaded";
        for my $path ( [ 0, 10 ], [ 0, 1 ], [ 1, 2 ], [ 2, 10 ], [ 10, 0 ], [ 10, 1 ], [ 2, 1 ], [ 2, 2 ], [ 0, 0 ], [ 10, 10 ] ) {
            is $m->sql_for(@$path), $parent->sql_for(@$path), "$loader: sql from $path->[0] to $path->[1]";
        }
        like $m->sql_for( 0, 10 ), qr/create table a.*\$5.*\$WHO \$\{1\} \$\{\} \$\{WHO.*\$1 \* 1\.25.*ten comes after two/s,
          "$loader: up sql";
        like $m->sql_for( 10, 0 ), qr/drop function add_tax.*drop table a/s, "$loader: down sql";
        is $m->placeholders($_), [], "$loader: version $_ has no placeholders" for 1, 2, 10;
    }
};

subtest 'env' => sub {
    local $ENV{ENV_TEST_USER} = 'alice';
    my $sql = "-- 1 up\ngrant select on c to \${ENV_TEST_USER};\n";
    my $m   = MojoX::Pg::Migrations::Env->new->from_string($sql);
    ref_is $m->env, \%ENV, 'env defaults to %ENV';
    like $m->sql_for( 0, 1 ), qr/grant select on c to alice;/, 'value is taken from %ENV';

    my $env = { ENV_TEST_USER => 'bob' };
    $m = MojoX::Pg::Migrations::Env->new( env => $env )->from_string($sql);
    ref_is $m->env, $env, 'env can be given';
    like $m->sql_for( 0, 1 ), qr/grant select on c to bob;/, 'given env is used instead of %ENV';

    $env->{ENV_TEST_USER} = 'carol';
    like $m->sql_for( 0, 1 ), qr/grant select on c to carol;/, 'values are looked up each time the sql is produced';
};

subtest 'placeholder syntax' => sub {
    my $sql = 'grant select on c to ${ENV_TEST_USER:-current_user};';
    is render($sql), 'grant select on c to current_user;', 'fallback is used when the variable is unset';
    is render( $sql, ENV_TEST_USER => 'bob' ), 'grant select on c to bob;',          'value is taken from env';
    is render( $sql, ENV_TEST_USER => '' ),    'grant select on c to current_user;', 'empty value falls back';

    is render('comment on table a is \'${NOTE:-}\';'), q{comment on table a is '';}, 'empty fallback is a valid fallback';
    is render( 'comment on table a is \'${NOTE:-}\';', NOTE => 'hi' ), q{comment on table a is 'hi';},
      'value wins over an empty fallback';

    is render( 'grant select on a to ${WHO}; grant select on b to ${WHO};', WHO => 'bob' ),
      'grant select on a to bob; grant select on b to bob;', 'a name used twice is replaced in both places';
    is render( 'grant ${HOW:-select} on ${WHAT} to ${WHO};', WHO => 'bob', WHAT => 'c' ), 'grant select on c to bob;',
      'several placeholders in one migration';
    is render( '${_a1}',                          _a1       => 'x' ), 'x', 'name with underscore, lower case and digit';
    is render( 'grant all on a to ${MUST_HAVE};', MUST_HAVE => 0 ),   'grant all on a to 0;', 'zero is a value';

    is render( 'select \'$WHO\', \'${1}\', \'${}\', \'${WHO\';', WHO => 'bob' ), q[select '$WHO', '${1}', '${}', '${WHO';],
      'text that is not a placeholder is left alone';
    is render( "create function f(text) returns text as \$\$\n  select '\${WHO}' || \$1;\n\$\$ language sql;", WHO => 'bob' ),
      "create function f(text) returns text as \$\$\n  select 'bob' || \$1;\n\$\$ language sql;",
      'dollar quoting and numbered parameters around a placeholder are left alone';
    is render( "create function f() returns text as \$body\$ select '\${WHO}' \$body\$ language sql;", WHO => 'bob' ),
      q[create function f() returns text as $body$ select 'bob' $body$ language sql;], 'tagged dollar quoting is left alone';
};

subtest 'escapes' => sub {
    is render('select \'$${NOT_A_VAR}\';'), q[select '${NOT_A_VAR}';], 'doubled dollar escapes the placeholder';
    is render( 'select \'$${NOT_A_VAR}\';', NOT_A_VAR => 'x' ), q[select '${NOT_A_VAR}';],
      'escaped placeholder is not replaced when the variable is set';
    is render( 'select \'$${NOT_A_VAR:-y}\';', NOT_A_VAR => 'x' ), q[select '${NOT_A_VAR:-y}';],
      'escaped placeholder keeps its fallback';
    is render('select \'$${NOT_A_VAR:-}\';'), q[select '${NOT_A_VAR:-}';], 'escaped placeholder keeps an empty fallback';
};

subtest 'placeholders are replaced per migration' => sub {
    my $m = load( 'placeholders.sql', ENV_TEST_WHO => 'bob', ENV_TEST_GREETING => 'hi' );
    is $m->latest, 2, 'migrations are loaded';
    like $m->sql_for( 0, 2 ), qr/up 1 as bob.*select 'hi ' \|\| \$1;.*up 2 for bob/s, 'up sql in order with values from env';
    like $m->sql_for( 2, 0 ), qr/down 2 for bob, literally \$\{ENV_TEST_WHO\}.*drop table notes/s,
      'down sql in order with values from env';
    is $m->sql_for( 2, 2 ), '', 'nothing to do';

    $m = load('placeholders.sql');
    like $m->sql_for( 0, 1 ), qr/up 1 as nobody/, 'a migration off the path is not looked at';
    like dies { $m->sql_for( 0, 2 ) },
      qr/^Migration 2 needs environment variable ENV_TEST_WHO, which is not set and has no fallback at \Q${\__FILE__}\E line/,
      'missing variable on the way up dies, names the version and the variable and blames the caller';
    like dies { $m->sql_for( 2, 1 ) },
      qr/^Migration 2 needs environment variable ENV_TEST_WHO, which is not set and has no fallback/,
      'missing variable on the way down dies';
    like dies { load( 'placeholders.sql', ENV_TEST_WHO => '' )->sql_for( 1, 2 ) }, qr/^Migration 2 needs environment variable/,
      'empty variable without a fallback dies';
};

subtest 'label_for' => sub {
    my $m = load('placeholders.sql');
    is $m->label_for(4), 'Migration 4', 'a migration is named by its version';

    my $file = $fixtures->child('placeholders.sql');
    $m = Local::Migrations::Labelled->new( name => 'test', env => { ENV_TEST_WHO => 'bob' } )->from_file($file);
    like $m->sql_for( 0, 2 ), qr/up 1 as bob.*up 2 for bob/s, 'sql is produced by a subclass with its own label';
    is $m->asked, 0, 'the label is not asked for when nothing is missing';

    $m->env( {} );
    like dies { $m->sql_for( 0, 2 ) },
      qr/^Migration 2 \(needs-env-2\) needs environment variable ENV_TEST_WHO, which is not set and has no fallback at \Q${\__FILE__}\E line/,
      'the label of a subclass is in the error, which still blames the caller';
    is $m->asked, 1, 'the label is asked for once, for the migration that fails';
    like dies { $m->sql_for( 2, 1 ) }, qr/^Migration 2 \(needs-env-2\) needs environment variable ENV_TEST_WHO/,
      'the label is used on the way down too';
};

subtest 'placeholders' => sub {
    my $m = load('placeholders.sql');
    is $m->placeholders(1), [ { name => 'ENV_TEST_WHO', fallback => 'nobody' } ], 'placeholder with a fallback';
    is $m->placeholders(2), [ { name => 'ENV_TEST_GREETING', fallback => 'hello' }, { name => 'ENV_TEST_WHO', fallback => undef } ],
      'up then down sql, each name once, escaped ones skipped';
    is $m->placeholders(3), [], 'unknown version';
    is load( 'placeholders.sql', ENV_TEST_WHO => 'bob' )->placeholders(1), [ { name => 'ENV_TEST_WHO', fallback => 'nobody' } ],
      'listing does not depend on env';

    is placeholders('grant all on a to ${MUST_HAVE};'), [ { name => 'MUST_HAVE', fallback => undef } ],
      'required placeholder has no fallback';
    is placeholders('select \'${NOTE:-}\';'), [ { name => 'NOTE', fallback => '' } ], 'empty fallback is listed as empty';
    is placeholders('select \'$${NOT_A_VAR}\', \'$${ALSO_NOT:-x}\';'), [],            'escaped placeholders are not listed';
    is placeholders('grant ${HOW:-select} on ${WHAT} to ${WHO}; revoke ${HOW:-all} on ${WHAT} from ${OTHER};'),
      [
        { name => 'HOW',   fallback => 'select' },
        { name => 'WHAT',  fallback => undef },
        { name => 'WHO',   fallback => undef },
        { name => 'OTHER', fallback => undef },
      ],
      'each name once, in order of first appearance';
    is placeholders('select \'$${WHO}\', \'${WHO}\';'), [ { name => 'WHO', fallback => undef } ],
      'a name that is escaped in one place is listed for the other';

    $m = MojoX::Pg::Migrations::Env->new( env => {} )->from_string("-- 1 up\n\${UP}\n-- 1 down\n\${DOWN} \${UP:-x}\n");
    is $m->placeholders(1), [ { name => 'UP', fallback => undef }, { name => 'DOWN', fallback => undef } ],
      'a name used by both up and down sql is listed once';
};

subtest 'resolve' => sub {
    my $m = MojoX::Pg::Migrations::Env->new( env => { WHO => 'bob', EMPTY => '', ZERO => 0 } );
    is [ $m->resolve( 'WHO', undef ) ],   [ 'env',      'bob' ], 'value from env';
    is [ $m->resolve( 'WHO', 'x' ) ],     [ 'env',      'bob' ], 'value from env wins over the fallback';
    is [ $m->resolve('WHO') ],            [ 'env',      'bob' ], 'fallback can be left out';
    is [ $m->resolve( 'ZERO', 'x' ) ],    [ 'env',      0 ],     'zero is a value';
    is [ $m->resolve( 'UNSET', 'x' ) ],   [ 'fallback', 'x' ],   'fallback when the variable is unset';
    is [ $m->resolve( 'EMPTY', 'x' ) ],   [ 'fallback', 'x' ],   'fallback when the variable is empty';
    is [ $m->resolve( 'UNSET', '' ) ],    [ 'fallback', '' ],    'empty fallback is a fallback';
    is [ $m->resolve( 'UNSET', undef ) ], [ 'missing',  undef ], 'missing when unset and there is no fallback';
    is [ $m->resolve( 'EMPTY', undef ) ], [ 'missing',  undef ], 'missing when empty and there is no fallback';
    ok lives { $m->resolve('UNSET') }, 'missing does not die';
};

done_testing;

__DATA__
@@ plain
-- 1 up
create table a (id serial primary key, price text default '$5', note text default '$WHO ${1} ${} ${WHO');
-- 1 down
drop table a;

-- 2 up
create function add_tax(numeric) returns numeric as $$
  select $1 * 1.25;
$$ language sql;
-- 2 down
drop function add_tax(numeric);

-- 10 up
insert into a (note) values ('ten comes after two');
