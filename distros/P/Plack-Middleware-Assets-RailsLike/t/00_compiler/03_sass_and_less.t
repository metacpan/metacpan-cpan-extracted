use lib qw(lib);
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

my $c = new_ok 'Plack::Middleware::Assets::RailsLike::Compiler',
    [ minify => 0, search_path => [ catdir( $Bin, 'assets' ) ] ];

subtest 'scss' => sub {

    my $oneline = '.foo {border-color:#3bbfce;color:#2ca2af;}';
    compile_ok( $c, '03_scss.css', $oneline, 'scss' );
};

subtest 'sass' => sub {

    my $oneline = <<EOM;
.foo {
  border-color: #3bbfce;
  color: #2ba1af;
}
EOM
    chomp $oneline;
    compile_ok( $c, '03_sass.css', $oneline, 'sass' );
};

subtest 'less' => sub {

    my $oneline = <<EOM;

.box { 
	color: saturate(#f938ab, 5%); 
	border-color: lighten(#f938ab, 30%); 
}
EOM
    chomp $oneline;
    compile_ok( $c, '03_less.css', $oneline, 'less' );
};
done_testing;
