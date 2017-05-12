use utf8;
use strict;
use warnings;
use Test::More;
use Test::Name::FromLine;
use FindBin qw($Bin);
use File::Temp;
use File::Slurp;
use File::Spec::Functions qw(catfile catdir);
use Plack::Middleware::Assets::RailsLike::Compiler;

sub compile_ok {
    my ( $compiler, $file, $content, $msg ) = @_;
    my $manifest = read_file( catfile( $Bin, 'assets', $file ) );
    is $compiler->compile( manifest => $manifest, type => 'js' ),
        $content,
        $msg;
}

subtest 'minify => 0 ' => sub {
    my $c = new_ok 'Plack::Middleware::Assets::RailsLike::Compiler',
        [ minify => 0, search_path => [ catdir( $Bin, 'assets' ) ] ];

    compile_ok( $c, '01_oneline.js', 'var foo = 1;', 'oneline' );

    my $multi = <<EOM;
var foo = 1;
function bar() {
    alert('bar');
}
EOM
    chomp $multi;
    compile_ok( $c, '01_multilines.js', $multi, 'multi lines' );

    compile_ok( $c, '01_inline.js', <<EOM, 'inline' );
var foo = 1;
function bar() {
    alert('bar');
}
console.log('inline');
EOM
};

subtest 'minify => 1' => sub {
    my $c = new_ok 'Plack::Middleware::Assets::RailsLike::Compiler',
        [ minify => 1, search_path => [ catdir( $Bin, 'assets' ) ] ];

    compile_ok( $c, '01_oneline.js', 'var foo=1;', 'oneline' );

    my $multi = "var foo=1;function bar(){alert('bar');}";
    compile_ok( $c, '01_multilines.js', $multi, 'multi lines' );

    my $inline
        = "var foo=1;function bar(){alert('bar');}\nconsole.log('inline');";
    compile_ok( $c, '01_inline.js', $inline, 'inline' );
};

done_testing;
