#!/usr/bin/perl -w
##############################################################################
#
#	MakeMaker version for Installation Suite of Mirapoint Admin
#	utilities.
#
# Installation Instructions
#	perl Makefile.PL
#	make
#	make install
#
##############################################################################
#
use ExtUtils::MakeMaker qw(prompt WriteMakefile);
use MIME::Base64 qw(encode_base64);

sub trim
{
	my $str = shift;

	$str =~ s/[\r\n]+$//;
	$str =~ s/^\s*//;
	$str =~ s/\s*$//;
	return $str;
}

sub Prompt
{
	my ($prompt, $def) = @_;
	$def = "" unless defined $def;
	chomp($prompt);

	prompt($prompt, $def);
}

#
##############################################################################
#
WriteMakefile(
	NAME 		=> 	'Net::MirapointAdmin',
	VERSION_FROM	=>	'lib/Net/MirapointAdmin.pm',
	( $[ >= 5.005) ?
	(
	AUTHOR => 'Adrian Hall (ahall@mirapoint.com)',
	ABSTRACT => 'Modules to handle the Mirapoint Administration Protocol',
	) : (),
	PREREQ_PM => { 'IO::Socket' => 0 },
	SIGN => 0,
	clean => { FILES => ".config" },
);
#
##############################################################################
#
# For testing, enable remote tests
#
print <<_EOF;

Testing requires access to a Mirapoint host on port 10143 (and 10243 if you
are testing SSL connectivity). 

_EOF

my ($enable, $host, $user, $pass, $ssl);

do {
	$enable = Prompt("Do you wish to enable live testing?", "n");
	$enable = lc($enable);
} while ($enable ne "y" && $enable ne "n");
if ($enable eq "n") {
	open(F, ">.config") || die "Cannot write to .config: $^E\n";
	print F "disabled\n";
	close(F);
	goto SKIP_ALL;
}

do {
	$host = Prompt("Mirapoint host name?", "testmail");
	$host = lc($host);
} while (length($host) == 0 || length($host) > 255);

do {
	$user = Prompt("Enter Administrative Login", "Administrator");
} while (length($user) == 0 || length($user) > 64);

do {
	$pass = Prompt("Enter $user password", "");
} while (length($pass) == 0 || length($pass) > 64);
($pass = encode_base64($pass)) =~ s/[\r\n]+$//;

do {
	$ssl = Prompt("Do you wish to enable SSL tests?", "y");
	$ssl = lc($ssl);
} while ($ssl ne "y" && $ssl ne "n");

open(F, ">.config") || die "Cannot open .config: $!\n";
print F <<_EOF;
enabled
$host
$user
$pass
$ssl
_EOF
close(F);

#
##############################################################################
#
SKIP_ALL:
	exit 0;
