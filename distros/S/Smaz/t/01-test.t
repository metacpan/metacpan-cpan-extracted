use Test::More;

use Smaz qw/all/;

my @strings = (
        "This is a small string",
        "foobar",
        "the end",
        "not-a-g00d-Exampl333",
        "Smaz is a simple compression library",
        "Nothing is more difficult, and therefore more precious, than to be able to decide",
        "this is an example of what works very well with smaz",
        "1000 numbers 2000 will 10 20 30 compress very little",
        "and now a few italian sentences:",
        "Nel mezzo del cammin di nostra vita, mi ritrovai in una selva oscura",
        "Mi illumino di immenso",
	"L'autore di questa libreria vive in Sicilia",
	"try it against urls",
        "http://google.com",
        "http://programming.reddit.com",
        "http://github.com/antirez/smaz/tree/master",
        "/media/hdb1/music/Alben/The Bla",
);

for my $string (@strings) {
	ok(my $comp = smaz_compress($string));
	ok(my $decomp = smaz_decompress($comp));
	is($decomp, $string);
}

done_testing();
