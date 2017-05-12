use Test;
BEGIN { plan tests => 7 };
use Sub::Regex;
ok(1);

sub /look(s|ing)?_for/ { "Here" }
ok( look_for("Amanda"), "Here" );
ok( looks_for("Amanda"), "Here" );
ok( looking_for("Amanda"), "Here" );
ok( LOOK_FOR("Amanda"), "Here" );
ok( LOOKs_FOR("Amanda"), "Here" );
ok( LooKing_FOR("Amanda"), "Here" );
