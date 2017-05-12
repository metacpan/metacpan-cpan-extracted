use PGP::Mail;

print "1..5\nok 1\n";

my $data=join "",<DATA>;
close DATA;

my $hash={
	"no_options" => 1,
	"extra_args" =>
	    [
		"--no-default-keyring",
		"--keyring" => "t/mbm-pgp.pub",
		"--secret-keyring" => "t/mbm-pgp.sec",
		"--keyserver-options" => "no-auto-key-retrieve",
	    ],
	"always_trust" => 1,
	};

my $pgp=new PGP::Mail($data, $hash);

if($pgp->status ne "good") {
    print "not ";
}
print "ok 2\n";

if($pgp->keyid ne "0x8868CFF7D9C1EB11") {
    print "not ";
}
print "ok 3\n";

my $sigdata=
    "This is a test message, I'm going to clearsign it, and then I'm\n" .
    "also going to detach sign it to be able to use as a PGP::Mail\n" .
    "test.\n\n" .
    "This should be the data.\n";

if($pgp->data ne $sigdata) {
    print "not ";
}
print "ok 4\n";

$data=~s/test message/tost message/;

$pgp=new PGP::Mail($data, $hash);

if($pgp->status ne "bad") {
    print "not ";
}
print "ok 5\n";

__DATA__
From: Matthew Byng-Maddick <mbm@example.com>
To: Testing <test@example.com>
Subject: a test

-----BEGIN PGP SIGNED MESSAGE-----
Hash: SHA1

This is a test message, I'm going to clearsign it, and then I'm 
also going to detach sign it to be able to use as a PGP::Mail
test.

This should be the data.
-----BEGIN PGP SIGNATURE-----
Version: GnuPG v1.2.0 (GNU/Linux)

iD8DBQE+IC4SiGjP99nB6xERAjBcAJ96Xy2wVFZinDCnEwc8TaaiiIvnzwCeMJS5
TGYoMuRf9KdBEgFRO6FYROE=
=sXwy
-----END PGP SIGNATURE-----

This should not be the data.
