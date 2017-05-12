use Test::More "no_plan";
BEGIN {use_ok(Perl6::Slurp)};

my $desc;
sub TEST { $desc = $_[0] };

my $line1 = "line 1\n";
my $line2 = "line 2\n";
my $line3 = "line 3\n";
my $line4 = "line 4\n";

my $para1 = $line1.$line2."\n";
my $para2 = $line3.$line4;

my $data = $para1.$para2;

TEST "scalar slurp no irs";
$str = slurp \$data;
is $str, $data, $desc;

TEST "list slurp no irs";
@str = slurp \$data;
is_deeply \@str, [$line1, $line2, "\n", $line3, $line4], $desc;

TEST "scalar slurp :irs(\"\\n\")";
$str = slurp \$data, {irs=>"\n"};
is $str, $data, $desc;

TEST "list slurp :irs(\"\\n\")";
@str = slurp \$data, {irs=>"\n"};
is_deeply \@str, [$line1, $line2, "\n", $line3, $line4], $desc;

TEST "scalar slurp :irs(\"\\n\\n\")";
$str = slurp \$data, {irs=>"\n\n"};
is $str, $data, $desc;

TEST "list slurp :irs(\"\\n\\n\")";
@str = slurp \$data, {irs=>"\n\n"};
is_deeply \@str, [$para1, $para2], $desc;

TEST "scalar slurp :irs(undef)";
$str = slurp \$data, {irs=>undef};
is $str, $data, $desc;

TEST "list slurp :irs(undef)";
@str = slurp \$data, {irs=>undef};
is_deeply \@str, [$data], $desc;

TEST "scalar slurp :irs('ne')";
$str = slurp \$data, {irs=>'ne'};
is $str, $data, $desc;

TEST "list slurp :irs('ne')";
@str = slurp \$data, {irs=>'ne'};
is_deeply \@str, [split /(?<=ne)/, $data], $desc;

TEST "scalar slurp :irs(qr/\\n+|3/)";
$str = slurp \$data, {irs=>qr/\n+|3/};
is $str, $data, $desc;

TEST "list slurp :irs(qr/\\n+|3/)";
@str = slurp \$data, {irs=>qr/\n+|3/};
is_deeply \@str, ["line 1\n","line 2\n\n","line 3","\n","line 4\n"], $desc;
