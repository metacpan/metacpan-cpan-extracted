#!perl
use strict;
use warnings;
use Test::More tests => 21;

use FindBin qw($Bin);
use File::Spec;
BEGIN{
	eval 'use Fcntl;1' or *O_RDWR = sub(){ 2 };
}

use Fatal qw(unlink);

#use subs 'open';
#sub open(*;$@){
#	my($fh, $layers, @arg) = @_;
#	no strict 'refs';
#	my $st = CORE::open(*$fh, $layers, @arg);
#	if(!$st){
#		diag "open failed: $!";
#	}
#	return $st;
#}

my $file = File::Spec->join($Bin, 'util', 'creat');

ok !-e $file, "before open: the file doesn't exist";

my $in;
ok open($in, "<:creat", $file), "open with :creat";

ok -e $file, "after open: the file does exist";


close $in;
unlink $file;
ok open($in, "<:utf8 :creat", $file), "open with :utf8 :creat -> failure";
ok scalar(grep { $_ eq 'utf8' } $in->get_layers()), 'utf8 on';
ok -e $file, "... not exist";

ok open($in, "<:creat :utf8", $file), "open with :creat :utf8";
ok -e $file, "... exist";

close $in;
unlink $file;
ok open($in, "<:raw :creat", $file), "open with :raw :creat";
ok -e $file, "... exist";


close $in;
unlink $file;
ok open($in, "<:unix :creat", $file), "open with :unix :creat";
ok -e $file, "... exist";


close $in;
unlink $file;
ok open($in, "<:crlf :creat", $file), "open with :crlf :creat";
ok -e $file, "... exist";

close $in;
unlink $file;
ok open($in, "<:creat :crlf", $file), "open with :creat :crlf";
ok -e $file, "... exist";



my @layers = $in->get_layers();

ok scalar( grep{ $_ eq 'crlf' } @layers ), "has other layers (in [@layers])";

close $in;
unlink $file;

{
	use open IO => ':creat';

	ok sysopen($in, $file, O_RDWR), "sysopen with :creat";

	ok -e $file, "... exist";

}

eval{
	use warnings FATAL => 'layer';
	binmode $in, ":creat";
};

like $@, qr/Too late/, "Useless use of :creat";

ok close($in), "close";


END{
	unlink $file if defined($file) and -e $file;
}