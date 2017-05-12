use v5.10.0;
use Any::Moose;
use Template::JavaScript;
use Test::More qw(no_plan);
use FindBin qw($Bin);
use File::Spec::Functions qw(catdir catfile);
use File::Slurp qw(slurp);
use Template;

ok(1);

my $data_dir = catdir($Bin, 'swamp');
my $root = catfile($data_dir, 'root.tt');

my $ctx = Template::JavaScript->new(
    include_path => $data_dir,
);
$ctx->output( \my $out );
$ctx->tmpl_file( $root );
$ctx->run;

is( $out, <<'OUTPUT', 'can do variable includes' );
I am a header

I am a footer


hello there

What's up?
OUTPUT

