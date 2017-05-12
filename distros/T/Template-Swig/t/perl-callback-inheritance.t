#!/usr/bin/env perl
use strict;
use warnings;

use Template::Swig;
use Test::Exception;
use Test::More;
use File::Slurp qw(read_file);

my $perl_handler = sub {
	my ($filename, $encoding) = @_;
	if ( -e $filename ) {
		my $template = read_file($filename);
		return $template;
	} else {
		die "Unable to locate $filename";
	}
};

my $expected_output = <<EOT;
<!doctype html>
<head>
	<title>Custom Title!</title>
</head>
<body>
	custom content too!
</body>
EOT

my ($output, $swig);

$swig = Template::Swig->new(
	extends_callback => $perl_handler,
	template_dir => './t',
);

# Testing standard callback with inheritance
{
	dies_ok { $swig->compileFromFile('/unkown/path/template.t') } "compileFromFile will die if an invalid template is passed";
	lives_ok { $swig->compileFromFile('page.html') } "compileFromFile will live if a template is found";

	$output = $swig->render('page.html');
	$output = trim_whitespace($output);
	$expected_output = trim_whitespace($expected_output);

	is($output, $expected_output, 'rendered output matches what we expect');
}

# Testing standard callback with inheritance and check cache store sanity
{
	my ($locale, $en_us_output, $en_ca_output);
	my @cache_keys;
	$swig->{context}->bind('cache_inspect' => sub {
		my $cache = shift;
		push @cache_keys, [ sort keys %$cache ];
	});
	confess $@ if $@;

	$locale = 'en_US';
	$expected_output = trim_whitespace(<<EOT);
<!doctype html>
<head>
	<title>Custom Title!</title>
</head>
<body>
	custom content too!
	$locale
</body>
EOT
	lives_ok { $swig->compileFromFile({ filename => 'page.html', locale => $locale }) } "compileFromFile with a data structure with a key of filename will live";
	$en_us_output = trim_whitespace($swig->render({ filename => 'page.html', locale => $locale }, {locale => $locale} ));
	is($en_us_output, $expected_output, 'rendered output matches what we expect');

	$swig->{context}->eval(q~cache_inspect(templates)~);
	confess $@ if $@;
	is_deeply \@cache_keys,
		[ [ 'page.html', '{"filename":"page.html","locale":"en_US"}' ] ],
		"the cache store should just contain the entries we expect";
	@cache_keys = ();

	$locale = 'en_CA';
	$expected_output = trim_whitespace(<<EOT);
<!doctype html>
<head>
	<title>Custom Title!</title>
</head>
<body>
	custom content too!
	$locale
</body>
EOT
	lives_ok { $swig->compileFromFile({ filename => 'page.html', locale => $locale }) } "compileFromFile with a data structure with a key of filename will live";
	$en_ca_output = trim_whitespace($swig->render({ filename => 'page.html', locale => $locale }, {locale => $locale} ));
	is($en_ca_output, $expected_output, 'rendered output matches what we expect');

	$swig->{context}->eval(q~cache_inspect(templates)~);
	is_deeply \@cache_keys,
		[ [ 'page.html', '{"filename":"page.html","locale":"en_CA"}', '{"filename":"page.html","locale":"en_US"}' ] ],
		"the cache store should just contain the entries we expect";
	@cache_keys = ();

	lives_ok { $swig->compileFromFile({ filename => 'page.html', locale => $locale }) } "compileFromFile with a data structure with a key of filename will live";
	$en_ca_output = trim_whitespace($swig->render({ filename => 'page.html', locale => $locale }, {locale => $locale} ));
	is($en_ca_output, $expected_output, 'rendered output matches what we expect');

	$swig->{context}->eval(q~cache_inspect(templates)~);
	is_deeply \@cache_keys, [ [ 'page.html', '{"filename":"page.html","locale":"en_CA"}', '{"filename":"page.html","locale":"en_US"}' ] ], "the cache store should not have any new entries";
	@cache_keys = ();
}

done_testing;

sub trim_whitespace {

	my ($string) = @_;

	$string =~ s/\s+/ /gs;
	$string =~ s/\s+$//gs;

	return $string;
}
