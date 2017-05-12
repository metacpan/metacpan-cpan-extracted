use Test::More tests => 41;
BEGIN { use_ok('String::MkPasswd') };

String::MkPasswd->import("mkpasswd");

my $passwd = mkpasswd();

ok(length $passwd == 9, "length = 9");
ok(&count_digits($passwd) == 2, "digits = 2");
ok(&count_lower($passwd) == 4, "lower = 4");
ok(&count_upper($passwd) == 2, "upper = 2");
ok(&count_special($passwd) == 1, "special = 1");

$passwd = mkpasswd(
	-length		=> 20,
	-minnum		=> 4,
	-minlower	=> 7,
	-minupper	=> 6,
	-minspecial	=> 3,
);

ok(length $passwd == 20, "length = 20");
ok(&count_digits($passwd) == 4, "digits = 4");
ok(&count_lower($passwd) == 7, "lower = 7");
ok(&count_upper($passwd) == 6, "upper = 6");
ok(&count_special($passwd) == 3, "special = 3");

$passwd = mkpasswd(
	-minnum	=> 0,
);

ok(length $passwd == 9, "length = 9");
ok(&count_digits($passwd) == 0, "digits = 0");
ok(&count_lower($passwd) == 6, "lower = 6");
ok(&count_upper($passwd) == 2, "upper = 2");
ok(&count_special($passwd) == 1, "special = 1");

$passwd = mkpasswd(
	-minlower	=> 0,
);

ok(length $passwd == 9, "length = 9");
ok(&count_digits($passwd) == 2, "digits = 2");
ok(&count_lower($passwd) == 4, "lower = 4");
ok(&count_upper($passwd) == 2, "upper = 2");
ok(&count_special($passwd) == 1, "special = 1");

$passwd = mkpasswd(
	-minupper	=> 0,
);

ok(length $passwd == 9, "length = 9");
ok(&count_digits($passwd) == 2, "digits = 2");
ok(&count_lower($passwd) == 6, "lower = 6");
ok(&count_upper($passwd) == 0, "upper = 0");
ok(&count_special($passwd) == 1, "special = 1");

$passwd = mkpasswd(
	-minspecial	=> 0,
);

ok(length $passwd == 9, "length = 9");
ok(&count_digits($passwd) == 2, "digits = 2");
ok(&count_lower($passwd) == 5, "lower = 5");
ok(&count_upper($passwd) == 2, "upper = 2");
ok(&count_special($passwd) == 0, "special = 0");

$passwd = mkpasswd(
	-minnum		=> 0,
	-minlower	=> 0,
	-minupper	=> 0,
	-minspecial	=> 0,
);

ok(length $passwd == 9, "length = 9");
ok(&count_digits($passwd) == 0, "digits = 0");
ok(&count_lower($passwd) == 9, "lower = 9");
ok(&count_upper($passwd) == 0, "upper = 0");
ok(&count_special($passwd) == 0, "special = 0");

$passwd = mkpasswd(
	-length		=> 3,
	-minnum		=> 3,
	-minlower	=> 0,
	-minupper	=> 0,
	-minspecial	=> 0,
);

ok(length $passwd == 3, "length = 3");
ok(&count_digits($passwd) == 3, "digits = 3");
ok(&count_lower($passwd) == 0, "lower = 0");
ok(&count_upper($passwd) == 0, "upper = 0");
ok(&count_special($passwd) == 0, "special = 0");

sub count_digits {
	my $re = qr/([0-9])/;
	my $count = 0;
	$count++ while $_[0] =~ /$re/g;
	return $count;
}

sub count_lower {
	my $re = qr/([a-z])/;
	my $count = 0;
	$count++ while $_[0] =~ /$re/g;
	return $count;
}

sub count_special {
	my $re = qr/([!@#\$%~^&*()=_+\[\]{}\\|;:'"<>,.?\/-])/;
	my $count = 0;
	$count++ while $_[0] =~ /$re/g;
	return $count;
}

sub count_upper {
	my $re = qr/([A-Z])/;
	my $count = 0;
	$count++ while $_[0] =~ /$re/g;
	return $count;
}
