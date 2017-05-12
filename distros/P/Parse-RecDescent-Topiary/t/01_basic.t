# -*- perl -*-

# t/01_basic.t - basic module functionality test

use Test::More tests => 23;
use Parse::RecDescent;

#01
BEGIN { use_ok('Parse::RecDescent::Topiary'); }

# Example taken from parsetree.pl demo in Parse::RecDescent distribution

my $grammar1 = <<'END';

	<autotree>
	
	expr	:	disj
	
	disj	:	conj 'or' disj | conj

	conj	:	unary 'and' conj | unary

	unary	:	'not' atom
		|	'(' expr ')'
		|	atom

	atom	:	/[a-z]+/i

END

my $parser1 = Parse::RecDescent->new($grammar1);

#02
isa_ok( $parser1, 'Parse::RecDescent' );

my $tree1 = $parser1->expr('a and b and not c');

#03
isa_ok( $tree1, 'expr' );

use Parse::RecDescent::Topiary::Base;
@Foo::Bar::expr::ISA  = qw(Parse::RecDescent::Topiary::Base);
@Foo::Bar::disj::ISA  = qw(Parse::RecDescent::Topiary::Base);
@Foo::Bar::conj::ISA  = qw(Parse::RecDescent::Topiary::Base);
@Foo::Bar::unary::ISA = qw(Parse::RecDescent::Topiary::Base);
@Foo::Bar::atom::ISA  = qw(Parse::RecDescent::Topiary::Base);

my $tree2 = topiary(
    tree      => $tree1,
    namespace => 'Foo::Bar'
);

#04
isa_ok( $tree2, 'Foo::Bar::expr' );

@Foo::Bar::Expr::ISA = qw(Parse::RecDescent::Topiary::Base);
@Foo::Baz::Disj::ISA = qw(Parse::RecDescent::Topiary::Base);
@Foo::Baz::Conj::ISA = qw(Parse::RecDescent::Topiary::Base);

$tree2 = topiary(
    tree      => $tree1,
    namespace => [qw/Foo::Bar Foo::Baz/],
    ucfirst   => 1,
    args      => 'wombat',
);

#05
isa_ok( $tree2, 'Foo::Bar::Expr' );

#06
is( $tree2->{test}, 'OK', "Root Node was constructed properly" );

#07
is( $tree2->{__ARGS__}, 'wombat', "Args passed in properly" );

my $disj = $tree2->{disj};

#08
isa_ok( $disj, 'Foo::Baz::Disj' );

my $conj = $disj->{conj};

#09
isa_ok( $conj, 'Foo::Baz::Conj' );

my $unary = $conj->{unary};

#10
is( ref($unary), 'HASH', "unmatched nodes unblessed" );

my $grammar2 = <<'END';
<autotree>

main:   forename(?) surname

forename: /\w+/ ','

surname: /\w+/

END

my $parser2 = Parse::RecDescent->new($grammar2);

#11
isa_ok( $parser2, 'Parse::RecDescent' );

my $tree3 = $parser2->main('John, Smith');
my $tree4 = $parser2->main('Caruthers');

@Foo::Main::ISA     = qw(Parse::RecDescent::Topiary::Base);
@Foo::Surname::ISA  = qw(Parse::RecDescent::Topiary::Base);
@Foo::Forename::ISA = qw(Parse::RecDescent::Topiary::Base);

my $tree5 = topiary(
    tree        => $tree3,
    namespace   => qw/Foo/,
    ucfirst     => 1,
    consolidate => 1,
);

#12
isa_ok( $tree5, 'Foo::Main' );

#13
ok( exists( $tree5->{surname} ), 'JS has a surname' );

my $sn = $tree5->{surname};

#14
isa_ok( $sn, 'Foo::Surname' );

#15
is_deeply( $sn, { __VALUE__ => 'Smith' }, 'Correct object' );

#16
ok( exists( $tree5->{forename} ), 'JS has a forename' );

my $fn = $tree5->{forename};

#17
isa_ok( $fn, 'Foo::Forename' );

#18
is_deeply(
    $fn,
    { __PATTERN1__ => 'John', __STRING1__ => ',' },
    'Correct object'
);

my $tree6 = topiary(
    tree        => $tree4,
    namespace   => qw/Foo/,
    ucfirst     => 1,
    consolidate => 1,
);

#19
isa_ok( $tree6, 'Foo::Main' );

#20
ok( exists( $tree6->{surname} ), 'Caruthers has a surname' );

$sn = $tree6->{surname};

#21
isa_ok( $sn, 'Foo::Surname' );

#22
is_deeply( $sn, { __VALUE__ => 'Caruthers' }, 'Correct object' );

#23
ok( !exists( $tree6->{forename} ), 'No key for forename' );

package Foo::Bar::Expr;

sub new {
    my $pkg = shift;

    my $self = $pkg->SUPER::new(@_);
    $self->{test} = 'OK';
    $self;
}
