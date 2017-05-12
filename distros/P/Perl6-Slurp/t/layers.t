use Test::More "no_plan";
use utf8;
BEGIN {use_ok(Perl6::Slurp)};

my $FILENAME = 'layers.t.data';

my $desc;
sub TEST { $desc = $_[0] };

open FH, '>:utf8', $FILENAME or exit;
print FH map chr, 0..0x1FF;
close FH;

undef $/;

my @layers = ( qw(:raw :bytes :unix :stdio :perlio :crlf :utf8),
			   ":raw :utf8",
			   ":raw:utf8",
			 );


for my $layer (@layers) {
	open FH, "<$layer", $FILENAME or exit;
	$data{$layer} = <FH>;
	$len{$layer}  = length $data{$layer};
	close FH;
}

for my $layer (@layers) {
	TEST "scalar slurp from '<$layer', $FILENAME";
	$str = slurp "<$layer", $FILENAME;
	is $data{$layer}, $str, $desc;
	ok length($str) == $len{$layer}, "length of $desc";

	TEST "scalar slurp from '< $layer', $FILENAME";
	$str = slurp "< $layer", $FILENAME;
	is $data{$layer}, $str, $desc;
	ok length($str) == $len{$layer}, "length of $desc";
}

%opts = (
	':raw'       => [{raw=>1}],
	':utf8'      => [{utf8=>1}],
	':raw :utf8' => [{raw=>1}, {utf8=>1}],
	':raw:utf8'  => [[raw=>1, utf8=>1]],
);

for my $layer (keys %opts) {
	local $" = ", ";
	TEST "scalar option slurp from $FILENAME, $layer";
	$str = slurp $FILENAME, @{$opts{$layer}};
	is $data{$layer}, $str, $desc;
	ok length($str) == $len{$layer}, "length of $desc";

	TEST "scalar option slurp from $layer, $FILENAME";
	$str = slurp @{$opts{$layer}}, $FILENAME;
	is $data{$layer}, $str, $desc;
	ok length($str) == $len{$layer}, "length of $desc";

}

unlink $FILENAME;
