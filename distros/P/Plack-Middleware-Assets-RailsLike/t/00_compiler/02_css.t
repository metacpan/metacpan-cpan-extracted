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
    is $compiler->compile( manifest => $manifest, type => 'css' ),
        $content,
        $msg;
}

subtest 'minify => 0 ' => sub {
    my $c = new_ok 'Plack::Middleware::Assets::RailsLike::Compiler',
        [ minify => 0, search_path => [ catdir( $Bin, 'assets' ) ] ];

    my $oneline = <<EOM;
#foo {
    size: 5em;
}
EOM
    chomp $oneline;
    compile_ok( $c, '02_oneline.css', $oneline, 'oneline' );

    my $multi = <<EOM;
#foo {
    size: 5em;
}
.bar {
    width: 10%;
}
EOM
    chomp $multi;
    compile_ok( $c, '02_multilines.css', $multi, 'multi lines' );

    compile_ok( $c, '02_inline.css', <<EOM, 'inline' );
#foo {
    size: 5em;
}
.bar {
    width: 10%;
}
#inline { height: 50% }
EOM
};

subtest 'minify => 1' => sub {
    my $c = new_ok 'Plack::Middleware::Assets::RailsLike::Compiler',
        [ minify => 1, search_path => [ catdir( $Bin, 'assets' ) ] ];

    compile_ok( $c, '02_oneline.css', '#foo{size:5em}', 'oneline' );

    my $multi = "#foo{size:5em}.bar{width:10%}";
    compile_ok( $c, '02_multilines.css', $multi, 'multi lines' );

    my $inline
        = "#foo{size:5em}.bar{width:10%}#inline{height:50%}";
    compile_ok( $c, '02_inline.css', $inline, 'inline' );
};

done_testing;
