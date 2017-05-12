use Test::More "no_plan";
use utf8;
BEGIN {use_ok(Perl6::Slurp)};

my $FILENAME = 'no_source.t.data';

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

$_ = $FILENAME;

%opts = (
	':raw'       => [{raw=>1}],
	':utf8'      => [{utf8=>1}],
	':raw :utf8' => [{raw=>1}, {utf8=>1}],
	':raw:utf8'  => [[raw=>1, utf8=>1]],
);

for my $layer (keys %opts) {
	local $" = ", ";
	TEST "scalar option slurp from implied \$_, $layer";
	$str = slurp @{$opts{$layer}};
	is $data{$layer}, $str, $desc;
	ok length($str) == $len{$layer}, "length of $desc";
}

unlink $FILENAME;
