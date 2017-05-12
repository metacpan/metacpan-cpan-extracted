use strict;
use warnings;

use Test::More;
my $tests;

plan tests => $tests;

use Padre::Plugin::Vi;
use Padre::Plugin::Vi::Editor;

my $editor = Padre::Plugin::Vi::Editor->new();
isa_ok( $editor, 'Padre::Plugin::Vi::Editor' );
BEGIN { $tests += 1; }

# TODO: what should happen when ESC pressed with Ctrl or other modifier?
#{
#	is($editor->key_down(0, Wx::WXK_ESCAPE), 0);
#	BEGIN { $tests += 1; }
#}

__END__
my @res;

{
	no warnings 'redefine';
	package Padre::Plugin::Vi::Editor;
	sub move_right { push @res, ['move_right', @_] };
}


{
	@res = ();
	is($editor->get_char(0, ord('l'), 'l'), 0);
	diag Dumper \@res;
	BEGIN { $tests += 1; }
}

#{
#	is($editor->key_down(0, ord('L')), 0);
#	is($e->GetCurrentPos, 1);
#	BEGIN { $tests += 2; }
#}
#
#{
#	is($editor->key_down(0, ord('3')), 0);
#	is($editor->key_down(0, ord('L')), 0);
#	is($e->GetCurrentPos, 4);
#	BEGIN { $tests += 3; }
#}
#
#{
#	is($editor->key_down(0, ord('2')), 0);
#	is($editor->key_down(0, ord('H')), 0);
#	is($e->GetCurrentPos, 2);
#	BEGIN { $tests += 3; }
#}
#
#{
#	is($editor->key_down(0, ord('5')), 0);
#	is($editor->key_down(0, ord('H')), 0);
#	is($e->GetCurrentPos, 0);
#	BEGIN { $tests += 3; }
#}
#
#{
#	is($editor->key_down(0, ord('J')), 0);
#	is($e->GetCurrentPos, 23);
#	BEGIN { $tests += 2; }
#}
#{
#	is($editor->key_down(0, ord('K')), 0);
#	is($e->GetCurrentPos, 0);
#	BEGIN { $tests += 2; }
#}
#

# code: Wx::WXK_ESCAPE

# mode:  Wx::wxMOD_META  (Num Lock being pressed on Linux)
# (Wx::wxMOD_ALT() + Wx::wxMOD_CMD() + Wx::wxMOD_SHIFT());

