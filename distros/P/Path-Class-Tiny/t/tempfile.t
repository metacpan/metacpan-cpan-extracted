use Test::Most 0.25;

use Path::Class::Tiny;

use File::Spec ();


my $name;
{
	my $tmp;
	lives_ok { $tmp = tempfile('bmoogle-XXXX') } 'properly exporting tempfile';
	isa_ok $tmp, 'Path::Class::Tiny', 'return from tempfile';
	$name = $tmp->stringify;
	ok -e $name, 'tempfile created automatically';
	ok dir( File::Spec->tmpdir )->subsumes($tmp), 'tempfile created in proper dir';
	like $tmp->basename, qr/^bmoogle-/, 'tempfile honors template';
}
ok ! -e $name, "tempfile removed automatically [$name]";

{
	my $tmp;
	lives_ok { $tmp = tempfile() } 'can create tempfile with no template';
	isa_ok $tmp, 'Path::Class::Tiny', 'return from tempfile (no template)';
	$name = $tmp->stringify;
	ok -e $name, 'tempfile created automatically (no template)';
	ok dir( File::Spec->tmpdir )->subsumes($tmp), 'tempfile created in proper dir (no template)';
}
ok ! -e $name, "tempfile removed automatically [$name]";


done_testing;
