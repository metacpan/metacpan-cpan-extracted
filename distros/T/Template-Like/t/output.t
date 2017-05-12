use Test::More tests => 8;

BEGIN { use_ok('Template::Like') };


use Cwd;
use File::Spec::Functions;

my $old_cwd = Cwd::getcwd();

my $tmpdir = File::Spec->tmpdir();

my $abstmpdir = Cwd::abs_path($tmpdir);

chdir $tmpdir;

mkdir 'tmpl', 0755;


my $t = Template::Like->new;
my $t2 = Template::Like->new({ OUTPUT_PATH => "tmpl/" });
my $t3 = Template::Like->new({ OUTPUT_PATH => "tmpl" });

my $input = q{<!DOCTYPE html PUBLIC "-//W3C//DTD HTML 4.01//EN">
<html>
<head>
<meta http-equiv="Content-Type" content="text/html; charset=EUC-JP">
<link rel="stylesheet" href="default.css">
<title>TITLE</title>
</head>
<body>
<p>[% group %]</p>
</body>
</html>};
my $result = q{<!DOCTYPE html PUBLIC "-//W3C//DTD HTML 4.01//EN">
<html>
<head>
<meta http-equiv="Content-Type" content="text/html; charset=EUC-JP">
<link rel="stylesheet" href="default.css">
<title>TITLE</title>
</head>
<body>
<p>hoge foo bar</p>
</body>
</html>};

my $output1;
my $output2;
my $output3;
my $output4;
my $output5;
my $output6;
my @output7;

{ package Apache::Request; sub new { bless {}, $_[0] }; sub print { $output6 = $_[1]; } };

my $r = Apache::Request->new;

$t->process(\$input, { group => "hoge foo bar" }, \$output1);
$t->process(\$input, { group => "hoge foo bar" }, "tmpl/test001.out");
$t2->process(\$input, { group => "hoge foo bar" }, "test002.out");
$t3->process(\$input, { group => "hoge foo bar" }, "test003.out");
$t->process(\$input, { group => "hoge foo bar" }, sub { $output3 = $_[0] });
$t->process(\$input, { group => "hoge foo bar" }, $r);
$t->process(\$input, { group => "hoge foo bar" }, \@output7);

open my $fh, "tmpl/test001.out";
$output2 = join "", <$fh>;
close $fh;
undef $fh;

open $fh, "tmpl/test002.out";
$output4 = join "", <$fh>;
close $fh;
undef $fh;

open $fh, "tmpl/test003.out";
$output5 = join "", <$fh>;
close $fh;
undef $fh;

my $output7 = join "\n", @output7;

is($result, $output1, "scalarref");
is($result, $output2, "filename");
is($result, $output3, "coderef");
is($result, $output4, "filename and output_path1");
is($result, $output5, "filename and output_path2");
is($result, $output6, "Apache::Request");
is($result, $output7, "arrayref");


unlink <tmpl/*>;

rmdir 'tmpl';

chdir $old_cwd;

