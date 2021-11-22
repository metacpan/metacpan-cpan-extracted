use Test::Most 0.25;

use Path::Class::Tiny;

use File::Spec ();


my $name;
{
	my $tmp;
	lives_ok { $tmp = tempdir('bmoogle-XXXX') } 'properly exporting tempdir';
	isa_ok $tmp, 'Path::Class::Tiny', 'return from tempdir';
	$name = $tmp->stringify;
	ok -d $name, 'tempdir created automatically';
	ok dir( File::Spec->tmpdir )->subsumes($tmp), 'tempdir created in proper dir';
	like $tmp->basename, qr/^bmoogle-/, 'tempdir honors template';
}
ok ! -e $name, "tempdir removed automatically [$name]";

{
	my $tmp;
	lives_ok { $tmp = tempdir() } 'can create tempdir with no template';
	isa_ok $tmp, 'Path::Class::Tiny', 'return from tempdir (no template)';
	$name = $tmp->stringify;
	ok -d $name, 'tempdir created automatically (no template)';
	ok dir( File::Spec->tmpdir )->subsumes($tmp), 'tempdir created in proper dir (no template)';
}
ok ! -e $name, "tempdir removed automatically [$name]";


done_testing;
