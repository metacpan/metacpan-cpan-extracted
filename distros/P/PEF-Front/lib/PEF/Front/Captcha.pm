package PEF::Front::Captcha;

use strict;
use warnings;
use Carp;

use PEF::Front::Config;
use Digest::SHA qw{sha1_hex};
use Storable;
use MLDBM::Sync;
use MLDBM qw(MLDBM::Sync::SDBM_File Storable);
use Fcntl qw(:DEFAULT :flock);

our $cfg_captcha_db;
our $cfg_www_static_captchas_dir;
our $cfg_captcha_image_class;
our $initialized = 0;

sub initialize {
	$cfg_captcha_db              = cfg_captcha_db();
	$cfg_www_static_captchas_dir = cfg_www_static_captchas_dir();
	$cfg_captcha_image_class     = cfg_captcha_image_class();
	no strict 'refs';
	for ($cfg_captcha_db, $cfg_www_static_captchas_dir) {
		die "$_ must be directory "         unless -d $_;
		die "directory $_ must be writable" unless -w $_;
		$_ .= "/" unless substr ($_, -1, 1) eq '/';
	}
	$cfg_captcha_image_class = "PEF::Front::SecureCaptcha"
	  if not $cfg_captcha_image_class
	  or not %{$cfg_captcha_image_class . "::"}
	  or not $cfg_captcha_image_class->can("generate_image");
	eval "use $cfg_captcha_image_class";
	croak "error loading captcha image class $cfg_captcha_image_class: $@" if $@;
	$initialized = 1;
}

sub _random {
	my $max = $_[0];
	open (my $rf, "<", "/dev/urandom") or die $!;
	binmode $rf;
	my $cu;
	sysread ($rf, $cu, 8);
	close ($rf);
	my $l = unpack "Q", $cu;
	return $l % $max;
}

sub generate_code {
	my ($size, $expire) = @_;
	my $str     = '';
	my $symbols = cfg_captcha_symbols();
	my $num     = @$symbols;
	$str .= $symbols->[_random($num)] for (1 .. $size);
	my %dbm;
	tie (%dbm, 'MLDBM::Sync', "${cfg_captcha_db}captcha.dbm", O_CREAT | O_RDWR, 0666) or die "$!";
	my $sha1 = sha1_hex(lc ($str) . cfg_captcha_secret());
	$dbm{$sha1} = time + $expire;
	return ($str, $sha1);
}

sub make_captcha {
	my $req = $_[0];
	initialize if not $initialized;
	my ($str, $sha1) = generate_code($req->{size}, cfg_captcha_expire_sec());
	my $image_init = cfg_captcha_image_init();
	$image_init = {} if not $image_init or 'HASH' ne ref $image_init;
	no strict 'refs';
	&{"${cfg_captcha_image_class}::generate_image"}(
		width      => $req->{width},
		height     => $req->{height},
		size       => $req->{size},
		str        => $str,
		code       => $sha1,
		out_folder => $cfg_www_static_captchas_dir,
		font       => cfg_captcha_font(),
		%$image_init,
	);
	return {result => "OK", code => $sha1};
}

sub check_code {
	my ($code, $sha1sum) = @_;
	my $sha1 = sha1_hex(lc ($code) . cfg_captcha_secret());
	my %dbm;
	my $sync_obj = tie (%dbm, 'MLDBM::Sync', "${cfg_captcha_db}captcha.dbm", O_CREAT | O_RDWR, 0666) or die "$!";
	$sync_obj->Lock;
	for my $cc (keys %dbm) {
		if ($dbm{$cc} < time) {
			unlink "${cfg_www_static_captchas_dir}$cc.jpg";
			delete $dbm{$cc};
		}
	}
	my $passed = 0;
	if (exists $dbm{$sha1sum} && $sha1sum eq $sha1) {
		delete $dbm{$sha1sum};
		$passed = 1;
	}
	$sync_obj->UnLock;
	return $passed;
}

sub check_captcha {
	my ($input, $md5sum) = @_;
	return check_code($input, $md5sum) == 1;
}

1;
