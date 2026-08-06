#!perl
use 5.016;
use strict;
use warnings;
use Test::More;
use File::Temp ();
use Template::Stencil;

my $dir = File::Temp::tempdir(CLEANUP => 1);

sub put {
    my ($name, $content) = @_;
    open my $fh, '>', "$dir/$name" or die $!;
    print $fh $content;
    close $fh;
}

my $s = Template::Stencil->new(template_dir => $dir);

# Compile error in a string template.
eval { $s->render("line1\n{% if x %}oops", {}) };
like($@, qr/^Template::Stencil: <string>:2:1: unclosed 'if' block/,
     'string compile error format');

# Compile error in a file names the file.
put('broken.tmpl', "ok\n{% 9bad %}");
eval { $s->render('broken.tmpl', {}) };
like($@, qr/broken\.tmpl:2:4: expected a name or keyword/,
     'file compile error names the file');

# Strict render error carries unit and line.
put('deep.tmpl', "a\nb\n{% x.y.z %}");
eval { $s->render('deep.tmpl', {}, { strict => 1 }) };
like($@, qr/deep\.tmpl:3: undef value for 'x\.y\.z'/,
     'strict render error format');

# Include-chain errors name the failing unit.
put('inner.tmpl', "\n{% oops.deep %}");
put('outer.tmpl', '{% include inner.tmpl %}');
eval { $s->render('outer.tmpl', {}, { strict => 1 }) };
like($@, qr/inner\.tmpl:2: undef value for 'oops\.deep'/,
     'error inside include names the include');

# A path-like argument that does not resolve renders as literal text
# (the documented dispatch rule), not an error.
is($s->render('nosuch.name', {}), 'nosuch.name',
   'unresolvable name renders as literal string');

# Missing include is a link error.
put('badinc.tmpl', '{% include gone.tmpl %}');
eval { $s->render('badinc.tmpl', {}) };
like($@, qr/badinc\.tmpl:1:1: cannot find include 'gone\.tmpl'/,
     'missing include error');

done_testing;
