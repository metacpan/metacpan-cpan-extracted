# vim:set tabstop=4 shiftwidth=4 noexpandtab:

use strict;
use warnings;
no warnings 'uninitialized';

use Encode;
use Test::More;

BEGIN
{
	use_ok( 'Net::LibIDN2');
}

my $local_charset;
eval
{
	require POSIX;

	my $lctype = POSIX::setlocale(POSIX::LC_CTYPE(), 'en_US.ISO8859-1');

	$local_charset = $1 if $lctype && $lctype =~ m/^[^.]+.(\S+)$/;
};

ok(length(IDN2_VERSION)>0);
ok(IDN2_VERSION_NUMBER>0);
ok(IDN2_VERSION_MAJOR>=2);
ok(IDN2_VERSION_MINOR>=0);
ok(IDN2_VERSION_PATCH>=0);
ok(IDN2_LABEL_MAX_LENGTH>32);
ok(IDN2_DOMAIN_MAX_LENGTH>32);

is(IDN2_NFC_INPUT, 1);
is(IDN2_ALABEL_ROUNDTRIP, 2);
is(IDN2_TRANSITIONAL, 4);
is(IDN2_NONTRANSITIONAL, 8);
is(IDN2_ALLOW_UNASSIGNED, 16);
is(IDN2_USE_STD3_ASCII_RULES, 32);
my $tr46_default = 0;
if(Net::LibIDN2::idn2_check_version("2.0.5")) {
	no strict;
	is(IDN2_NO_TR46, 64);
	$tr46_default = IDN2_NO_TR46;
}
if(Net::LibIDN2::idn2_check_version("2.2.0")) {
	no strict;
	is(IDN2_NO_ALABEL_ROUNDTRIP, 128);
}

is(Net::LibIDN2::idn2_strerror(0), 'success');
is(Net::LibIDN2::idn2_strerror_name(0), 'IDN2_OK');

ok(Net::LibIDN2::idn2_check_version(IDN2_VERSION));
ok(!defined(Net::LibIDN2::idn2_check_version("99999999.99999")));


my $muesli_unicode = "m\N{U+00FC}\N{U+00DF}li";
my $muesli_utf8 = Encode::encode_utf8($muesli_unicode);
my $muesli_punycode = "xn--mli-5ka8l";
my $muesli_dot_de_unicode = "m\N{U+00FC}\N{U+00DF}li.de";
my $muesli_dot_de_utf8 = Encode::encode_utf8($muesli_dot_de_unicode);
my $muesli_dot_de_punycode = "xn--mli-5ka8l.de";

{
	my $result = Net::LibIDN2::idn2_lookup_u8($muesli_dot_de_utf8);

	is($result, $muesli_dot_de_punycode);

	$result = Net::LibIDN2::idn2_to_ascii_8($muesli_dot_de_utf8);

	is($result, $muesli_dot_de_punycode);

	if ($local_charset)
	{
		my $result = Net::LibIDN2::idn2_lookup_ul(encode($local_charset, $muesli_dot_de_unicode));

		is($result, $muesli_dot_de_punycode);

		$result = Net::LibIDN2::idn2_to_ascii_l(encode($local_charset, $muesli_dot_de_unicode));

		is($result, $muesli_dot_de_punycode);
	}
}

{
	my $rc = 0;
	my $result = Net::LibIDN2::idn2_lookup_u8(
		"\x65\x78\x61\x6d\x70\x6c\x65\x2e\xe1\x84\x80\xe1\x85\xa1\xe1\x86\xa8",
		$tr46_default,
		$rc);

	is(Net::LibIDN2::idn2_strerror_name($rc), "IDN2_NOT_NFC");
	is($rc, Net::LibIDN2::IDN2_NOT_NFC);
	is($result, undef);
}

{
	my $rc = 0;
	my $result = Net::LibIDN2::idn2_lookup_u8(
		"\x65\x78\x61\x6d\x70\x6c\x65\x2e\xe1\x84\x80\xe1\x85\xa1\xe1\x86\xa8",
		IDN2_NFC_INPUT,
		$rc);

	is(Net::LibIDN2::idn2_strerror_name($rc), "IDN2_OK");
	is($result, "example.xn--p39a");
}

{
	my $rc = 0;
	my $result = Net::LibIDN2::idn2_lookup_u8("xn--mli-x5ka8l.de", 0, $rc);

	is(Net::LibIDN2::idn2_strerror_name($rc), "IDN2_OK");
	is($result, "xn--mli-x5ka8l.de");
}

{
	local $TODO = "IDN2_ALABEL_ROUNDTRIP not implemented in 2.0.4 yet";

	my $rc = 0;
	my $result = Net::LibIDN2::idn2_lookup_u8("xn--mli-x5ka8l.de", IDN2_ALABEL_ROUNDTRIP, $rc);

	is(Net::LibIDN2::idn2_strerror_name($rc), "IDN2_UNKNOWN");
	is($result, undef);

	if ($local_charset)
	{
		my $rc = 0;
		my $result = Net::LibIDN2::idn2_lookup_ul("xn--mli-x5ka8l.de", IDN2_ALABEL_ROUNDTRIP, $rc);

		is(Net::LibIDN2::idn2_strerror_name($rc), "IDN2_UNKNOWN");
		is($result, undef);
	}
}

{
	local $TODO = "IDN2_ALABEL_ROUNDTRIP not implemented in 2.0.4 yet";

	my $rc = 0;
	my $result = Net::LibIDN2::idn2_lookup_u8($muesli_punycode, IDN2_ALABEL_ROUNDTRIP, $rc);

	is(Net::LibIDN2::idn2_strerror_name($rc), "IDN2_OK");
	is($result, $muesli_punycode);

	if ($local_charset)
	{
		my $rc = 0;
		my $result = Net::LibIDN2::idn2_lookup_u8($muesli_punycode, IDN2_ALABEL_ROUNDTRIP, $rc);

		is(Net::LibIDN2::idn2_strerror_name($rc), "IDN2_OK");
		is($result, $muesli_punycode);
	}
}

{
	my $result = Net::LibIDN2::idn2_register_u8($muesli_utf8);

	is($result, $muesli_punycode);

	if ($local_charset)
	{
		my $result = Net::LibIDN2::idn2_register_ul(encode($local_charset, $muesli_unicode));

		is($result, $muesli_punycode);
	}
}

{
	my $result = Net::LibIDN2::idn2_register_u8($muesli_utf8, undef);

	is($result, $muesli_punycode);

	if ($local_charset)
	{
		my $result = Net::LibIDN2::idn2_register_ul(encode($local_charset, $muesli_unicode), undef);

		is($result, $muesli_punycode);
	}
}

{
	my $result = Net::LibIDN2::idn2_register_u8($muesli_utf8, undef, undef);

	is($result, $muesli_punycode);

	if ($local_charset)
	{
		my $result = Net::LibIDN2::idn2_register_ul(
			encode($local_charset, $muesli_unicode), undef, undef);

		is($result, $muesli_punycode);
	}
}

{
	my $rc = 0;
	my $result = Net::LibIDN2::idn2_register_u8($muesli_utf8, undef, undef, $rc);

	is(Net::LibIDN2::idn2_strerror_name($rc), "IDN2_OK");
	is($result, $muesli_punycode);

	if ($local_charset)
	{
		my $rc = 0;
		my $result = Net::LibIDN2::idn2_register_ul(
			encode($local_charset, $muesli_unicode), undef, undef, $rc);

		is(Net::LibIDN2::idn2_strerror_name($rc), "IDN2_OK");
		is($result, $muesli_punycode);
	}
}

{
	my $rc = 0;
	my $result = Net::LibIDN2::idn2_register_u8(
		"\xe1\x84\x80\xe1\x85\xa1\xe1\x86\xa8", 
		undef, 0, $rc);

	is(Net::LibIDN2::idn2_strerror_name($rc), "IDN2_NOT_NFC");
	is($result, undef);
}

{
	my $rc = 0;
	my $result = Net::LibIDN2::idn2_register_u8(
		"\xe1\x84\x80\xe1\x85\xa1\xe1\x86\xa8", 
		undef, IDN2_NFC_INPUT, $rc);

	is(Net::LibIDN2::idn2_strerror_name($rc), "IDN2_OK");
	is($result, "xn--p39a");
}

{
	my $result = Net::LibIDN2::idn2_to_unicode_88($muesli_dot_de_punycode);

	is($result, $muesli_dot_de_utf8);

	$result = Net::LibIDN2::idn2_to_unicode_88($result);

	is($result, $muesli_dot_de_utf8);

	if ($local_charset)
	{
		my $result = Net::LibIDN2::idn2_to_unicode_8l($muesli_dot_de_punycode);

		is($result, encode($local_charset, $muesli_dot_de_unicode));

		$result = Net::LibIDN2::idn2_to_unicode_8l($muesli_dot_de_utf8);

		is($result, encode($local_charset, $muesli_dot_de_unicode));

		$result = Net::LibIDN2::idn2_to_unicode_ll($muesli_dot_de_punycode);

		is(decode($local_charset, $result), $muesli_dot_de_unicode);

		$result = Net::LibIDN2::idn2_to_unicode_ll($result);

		is($result, encode($local_charset, $muesli_dot_de_unicode));
	}
}


done_testing();

1;
