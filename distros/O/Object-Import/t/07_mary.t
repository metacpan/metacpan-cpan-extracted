use warnings; use strict;
use Test::More tests => 32;

{
package X;

sub little { small(@_) }
use constant {
	had => -52,
	lamb => 4,
	snow => "ho ho ho",
};
use constant a => (1, 9);
sub its; sub fleece; sub as;
sub white { q(<font color="#ffffff">) . $_[1] . q(</font>) };

use subs qw"
	and everywhere that Mary went
	that lamb was _sure _to go
";
AUTOLOAD { 
	$X::AUTOLOAD =~ /\A.*::(.*)\z/s or die;
	"<" . $1 . ">" . $_[1] . "</" . $1 . ">";
}

}

is(X->p("foo"), "<p>foo</p>", "direct AUTOLOADED method call");

{
package G;
use Test::More;

my %name;
use_ok("Object::Import", "X", savenames => \%name, exclude_methods => {was => 1}, exclude_imports => {go => 1});
my %name_expect; $name_expect{$_} = 1 for qw"
	Mary had a little lamb
	its fleece as white as snow
	and everywhere that Mary went
";
ok(!exists(&$_), "!exi\&$_") for qw"small was sure to go _was _sure _to _go";
is_deeply(\%name, \%name_expect, "savenames");
is(white(fleece(little(lamb()))), q(<font color="#ffffff"><fleece><small>4</small></fleece></font>), "&white");
is(Mary("go"), "<Mary>go</Mary>", "&Mary");
is(join(":", a()), "1:9", "&a");
ok(!exists(&small), "!exi&small");

}

{
package G1;

use Test::More;
my %name;
use_ok("Object::Import", "X", savenames => \%name, prefix => "_", exclude_methods => {was => 1, _fleece => 1}, exclude_imports => {_go => 1, white => 1});
my %name_expect; $name_expect{$_} = 1 for qw"
	_Mary _had _a _little _lamb
	_its _fleece _as _white _as _snow
	_and _everywhere _that _Mary _went
";
ok(!exists(&$_), "!exi\&$_") for qw"_small _was _sure _to _go __was __sure __to __go had";
is_deeply(\%name, \%name_expect, "savenames");
is(_white(_fleece(_little(_lamb()))), q(<font color="#ffffff"><fleece><small>4</small></fleece></font>), "&white");
is(_Mary("go"), "<Mary>go</Mary>", "&Mary");
is(join(":", _a()), "1:9", "&a");
ok(!exists(&_small), "!exi&small");

}


__END__

