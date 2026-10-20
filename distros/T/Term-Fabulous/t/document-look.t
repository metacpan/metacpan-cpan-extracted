use v5.32;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

use Test2::V0;

use Object::Pad 0.825;
use Term::Fabulous::Document::Look;
use Term::Fabulous::Termbox qw(TB_BOLD TB_ITALIC);
use Term::Fabulous::Theme;
use Term::Fabulous::Widget::Box;

my $dark  = Term::Fabulous::Theme->builtin('dark');
my $light = Term::Fabulous::Theme->builtin('light');

my $file = Term::Fabulous::Document::Look->new( theme => $light )->style('file');
is $file, { set => TB_ITALIC, clear => 0, color => $light->token('success'), background => undef }, 'a kind is a style from the theme tokens';

my $look = Term::Fabulous::Document::Look->new( theme => $dark );
$look->style('heading1')->{color}[0] = 1;
is $look->style('heading1'), { set => TB_BOLD, clear => 0, color => $dark->token('accent'), background => undef }, 'every call returns a copy';

like dies { $look->style('shiny') },                                  qr/unknown kind 'shiny'; the kinds are bold, clipped, /, 'an unknown kind dies with the known ones';
like dies { Term::Fabulous::Document::Look->new( theme => 'dark' ) }, qr/theme must be a Term::Fabulous::Theme/,               'a look needs a theme object';

my $box   = Term::Fabulous::Widget::Box->new;
my $first = Term::Fabulous::Document::Look->of($box);
is $first->theme, Term::Fabulous::Theme->default, 'a widget in no UI draws with the default theme';
ok( Term::Fabulous::Document::Look->of($box) == $first, 'and gets the same look again' );
Term::Fabulous::Theme::bump_generation();
ok( Term::Fabulous::Document::Look->of($box) != $first, 'until a theme changes: then the look is made again' );

class My::Look :isa(Term::Fabulous::Document::Look) {

	method recipes :common () {
		return ( $class->SUPER::recipes, title => { words => 'bold', color => 'accent' }, code => { color => 'danger' } );
	}
}

subtest 'a subclass adds and changes kinds' => sub {
	my $mine = My::Look->new( theme => $dark );
	is $mine->style('title'), { set => TB_BOLD, clear => 0, color => $dark->token('accent'), background => undef }, 'a kind of its own';
	is $mine->style('code')->{color}, $dark->token('danger'), 'a kind changed';
	is $mine->style('bold'),          $look->style('bold'),   'the rest as in the base look';
	ok( ( grep { $_ eq 'title' } My::Look->kinds ),                     'kinds lists it' );
	ok( My::Look->of($box) != Term::Fabulous::Document::Look->of($box), 'each class keeps a look of its own' );
	isa_ok( My::Look->of($box), ['My::Look'], 'of the class asked' );
};

done_testing;
