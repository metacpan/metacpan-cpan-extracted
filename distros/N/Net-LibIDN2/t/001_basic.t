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
ok(IDN2_LABEL_MAX_LENGTH>32);
ok(IDN2_DOMAIN_MAX_LENGTH>32);

is(IDN2_NFC_INPUT, 1);
is(IDN2_ALABEL_ROUNDTRIP, 2);

is(Net::LibIDN2::idn2_strerror(0), 'success');
is(Net::LibIDN2::idn2_strerror_name(0), 'IDN2_OK');

ok(Net::LibIDN2::idn2_check_version(IDN2_VERSION));
ok(!defined(Net::LibIDN2::idn2_check_version("99999999.99999")));

{
	my $result = Net::LibIDN2::idn2_lookup_u8("m\N{U+00FC}\N{U+00DF}li.de");

	is($result, "xn--mli-5ka8l.de");

	if ($local_charset)
	{
		my $result = Net::LibIDN2::idn2_lookup_ul(encode($local_charset, "m\N{U+00FC}\N{U+00DF}li.de"));

		is($result, "xn--mli-5ka8l.de");
	}
}

{
	my $rc = 0;
	my $result = Net::LibIDN2::idn2_lookup_u8(
		"\x65\x78\x61\x6d\x70\x6c\x65\x2e\xe1\x84\x80\xe1\x85\xa1\xe1\x86\xa8",
		0,
		$rc);

	is(Net::LibIDN2::idn2_strerror_name($rc), "IDN2_NOT_NFC");
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
	local $TODO = "IDN2_ALABEL_ROUNDTRIP not implemented in 0.9 yet";

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
	local $TODO = "IDN2_ALABEL_ROUNDTRIP not implemented in 0.9 yet";

	my $rc = 0;
	my $result = Net::LibIDN2::idn2_lookup_u8("xn--mli-5ka8l", IDN2_ALABEL_ROUNDTRIP, $rc);

	is(Net::LibIDN2::idn2_strerror_name($rc), "IDN2_OK");
	is($result, "xn--mli-5ka8l");

	if ($local_charset)
	{
		my $rc = 0;
		my $result = Net::LibIDN2::idn2_lookup_u8("xn--mli-5ka8l", IDN2_ALABEL_ROUNDTRIP, $rc);

		is(Net::LibIDN2::idn2_strerror_name($rc), "IDN2_OK");
		is($result, "xn--mli-5ka8l");
	}
}

{
	my $result = Net::LibIDN2::idn2_register_u8("m\N{U+00FC}\N{U+00DF}li");

	is($result, "xn--mli-5ka8l");

	if ($local_charset)
	{
		my $result = Net::LibIDN2::idn2_register_ul(encode($local_charset, "m\N{U+00FC}\N{U+00DF}li"));

		is($result, "xn--mli-5ka8l");
	}
}

{
	my $result = Net::LibIDN2::idn2_register_u8("m\N{U+00FC}\N{U+00DF}li", undef);

	is($result, "xn--mli-5ka8l");

	if ($local_charset)
	{
		my $result = Net::LibIDN2::idn2_register_ul(encode($local_charset, "m\N{U+00FC}\N{U+00DF}li"), undef);

		is($result, "xn--mli-5ka8l");
	}
}

{
	my $result = Net::LibIDN2::idn2_register_u8("m\N{U+00FC}\N{U+00DF}li", undef, undef);

	is($result, "xn--mli-5ka8l");

	if ($local_charset)
	{
		my $result = Net::LibIDN2::idn2_register_ul(
			encode($local_charset, "m\N{U+00FC}\N{U+00DF}li"), undef, undef);

		is($result, "xn--mli-5ka8l");
	}
}

{
	my $rc = 0;
	my $result = Net::LibIDN2::idn2_register_u8("m\N{U+00FC}\N{U+00DF}li", undef, undef, $rc);

	is(Net::LibIDN2::idn2_strerror_name($rc), "IDN2_OK");
	is($result, "xn--mli-5ka8l");

	if ($local_charset)
	{
		my $rc = 0;
		my $result = Net::LibIDN2::idn2_register_ul(
			encode($local_charset, "m\N{U+00FC}\N{U+00DF}li"), undef, undef, $rc);

		is(Net::LibIDN2::idn2_strerror_name($rc), "IDN2_OK");
		is($result, "xn--mli-5ka8l");
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

done_testing();

1;
