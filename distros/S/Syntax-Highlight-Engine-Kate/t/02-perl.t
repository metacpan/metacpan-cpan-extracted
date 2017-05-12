
use strict;
use warnings;

use Test::More;
use Test::Warn;

use Syntax::Highlight::Engine::Kate;

my @languages = ('Perl', 'PHP (HTML)', 'PHP/PHP');

plan tests => 2 + scalar @languages;

foreach my $language (@languages) {
    my $hl = Syntax::Highlight::Engine::Kate->new(
        language => $language,
    );
    isa_ok($hl, 'Syntax::Highlight::Engine::Kate');
}

subtest klingon => sub {
    plan tests => 2;
	my $err;
    warnings_like {
		eval {
			Syntax::Highlight::Engine::Kate->new(
           		language => 'Klingon',
       		);
    	};
		$err = $@;
	} {carped => [qr{undefined language: 'Klingon'}, qr{cannot create plugin for language 'Klingon'}]}, 'warn';
	like $err, qr{Plugin for language 'Klingon' could not be found};
};

subtest basecontext => sub {
    plan tests => 2;
	my $err;
    warnings_like {
		eval {
			Syntax::Highlight::Engine::Kate->new(
           		language => 'PHP (HTML) ',
       		);
    	};
		$err = $@;
	} {carped => [qr{undefined language: 'PHP \(HTML\) '}, qr{cannot create plugin for language 'PHP \(HTML\) '}]}, 'warn';
	like $err, qr{Plugin for language 'PHP \(HTML\) ' could not be found};
};

