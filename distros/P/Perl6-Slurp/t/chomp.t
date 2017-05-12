use Test::More "no_plan";
BEGIN {use_ok(Perl6::Slurp)};

my $desc;
sub TEST { $desc = $_[0] };

my $line1 = "line 1";
my $line2 = "line 2";
my $line3 = "line 3";
my $line4 = "line 4";

my $para1 = $line1."\n".$line2."\n\n";
my $para2 = $line3."\n".$line4."\n";

my $data = $para1.$para2;

TEST "scalar slurp no chomp";
$str = slurp \$data;
is $str, $data, $desc;

TEST "list slurp no chomp";
@str = slurp \$data;
is_deeply \@str, ["$line1\n", "$line2\n", "\n", "$line3\n", "$line4\n"], $desc;

# Regular chomp

TEST "scalar slurp with chomp";
$str = slurp \$data, {chomp=>1};
is $str, $line1.$line2.$line3.$line4, $desc;

TEST "list slurp with chomp";
@str = slurp \$data, {chomp=>1};
is_deeply \@str, [$line1, $line2, "", $line3, $line4], $desc;

TEST "scalar slurp with chomp and :irs(\"\\n\")";
$str = slurp \$data, {irs=>"\n", chomp=>1};
is $str, $line1.$line2.$line3.$line4, $desc;

TEST "list slurp with chomp :irs(\"\\n\")";
@str = slurp \$data, {irs=>"\n", chomp=>1};
is_deeply \@str, [$line1, $line2, "", $line3, $line4], $desc;

TEST "scalar slurp with chomp :irs(\"\\n\\n\")";
$str = slurp \$data, {chomp=>1, irs=>"\n\n"};
is $str, $line1."\n".$line2.$line3."\n".$line4."\n", $desc;

TEST "list slurp with chomp :irs(\"\\n\\n\")";
@str = slurp \$data, {chomp=>1, irs=>"\n\n"};
is_deeply \@str, [$line1."\n".$line2, $line3."\n".$line4."\n"], $desc;

TEST "scalar slurp with chomp :irs(undef)";
$str = slurp \$data, {chomp=>1, irs=>undef};
is $str, $data, $desc;

TEST "list slurp with chomp :irs(undef)";
@str = slurp \$data, {chomp=>1, irs=>undef};
is_deeply \@str, [$data], $desc;

TEST "scalar slurp with chomp :irs('ne')";
$str = slurp \$data, {chomp=>1, irs=>'ne'};
is $str, "li 1\nli 2\n\nli 3\nli 4\n", $desc;

TEST "list slurp with chomp :irs('ne')";
@str = slurp \$data, {chomp=>1, irs=>'ne'};
is_deeply \@str, [split /ne/, $data], $desc;

TEST "scalar slurp with chomp :irs(qr/\\n+|3/)";
$str = slurp \$data, {irs=>qr/\n+|3/, chomp=>1};
is $str, "line 1line 2line line 4", $desc;

TEST "list slurp with chomp :irs(qr/\\n+|3/)";
@str = slurp \$data, {irs=>qr/\n+|3/, chomp=>1};
is_deeply \@str, ["line 1","line 2","line ","","line 4"], $desc;

# Chomp with substitution

TEST "scalar slurp with substitution chomp";
$str = slurp \$data, {chomp=>"foo"};
is $str, $line1."foo".$line2."foofoo".$line3."foo".$line4."foo", $desc;

TEST "list slurp with substitution chomp";
@str = slurp \$data, {chomp=>"foo"};
is_deeply \@str, [$line1."foo", $line2."foo", "foo", $line3."foo", $line4."foo"], $desc;

TEST "scalar slurp with substitution chomp of '1'";
$str = slurp \$data, {chomp=>"1"};
is $str, $line1."1".$line2."11".$line3."1".$line4."1", $desc;

TEST "list slurp with substitution chomp of '1'";
@str = slurp \$data, {chomp=>"1"};
is_deeply \@str, [$line1."1", $line2."1", "1", $line3."1", $line4."1"], $desc;

TEST "scalar slurp with substitution chomp and :irs(\"\\n\")";
$str = slurp \$data, {irs=>"\n", chomp=>"foo"};
is $str, $line1."foo".$line2."foofoo".$line3."foo".$line4."foo", $desc;

TEST "list slurp with substitution chomp :irs(\"\\n\")";
@str = slurp \$data, {irs=>"\n", chomp=>"foo"};
is_deeply \@str, [$line1."foo", $line2."foo", "foo", $line3."foo", $line4."foo"], $desc;

TEST "scalar slurp with substitution chomp :irs(\"\\n\\n\")";
$str = slurp \$data, {chomp=>"foo", irs=>"\n\n"};
is $str, $line1."\n".$line2."foo".$line3."\n".$line4."\n", $desc;

TEST "list slurp with substitution chomp :irs(\"\\n\\n\")";
@str = slurp \$data, {chomp=>"foo", irs=>"\n\n"};
is_deeply \@str, [$line1."\n".$line2."foo", $line3."\n".$line4."\n"], $desc;

TEST "scalar slurp with substitution chomp :irs(undef)";
$str = slurp \$data, {chomp=>"foo", irs=>undef};
is $str, $data, $desc;

TEST "list slurp with substitution chomp :irs(undef)";
@str = slurp \$data, {chomp=>"foo", irs=>undef};
is_deeply \@str, [$data], $desc;

TEST "scalar slurp with substitution chomp :irs('ne')";
$str = slurp \$data, {chomp=>"foo", irs=>'ne'};
is $str, "lifoo 1\nlifoo 2\n\nlifoo 3\nlifoo 4\n", $desc;

TEST "list slurp with substitution chomp :irs('ne')";
@str = slurp \$data, {chomp=>"foo", irs=>'ne'};
is_deeply \@str, ["lifoo", " 1\nlifoo", " 2\n\nlifoo", " 3\nlifoo", " 4\n"], $desc;

TEST "scalar slurp with substitution chomp :irs(qr/\\n+|3/)";
$str = slurp \$data, {irs=>qr/\n+|3/, chomp=>"foo"};
is $str, "line 1fooline 2fooline foofooline 4foo", $desc;

TEST "list slurp with substitution chomp :irs(qr/\\n+|3/)";
@str = slurp \$data, {irs=>qr/\n+|3/, chomp=>"foo"};
is_deeply \@str, ["line 1foo","line 2foo","line foo","foo","line 4foo"], $desc;

