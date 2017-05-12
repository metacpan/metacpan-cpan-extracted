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
"I guess it's easier just to create the sig with something that's going to\n" .
"do it properly.\n\n" .
"This is data.\n" .
"= yes, that's a straight equals sign.\n" .
"\xA3 should be a pound sign\n" .
"does it work?\n";

if($pgp->data ne $sigdata) {
    print "not ";
}
print "ok 4\n";

$data=~s/create the sig/create the sog/;

$pgp=new PGP::Mail($data,$hash);

if($pgp->status ne "bad") {
    print "not ";
}
print "ok 5\n";

__DATA__
Date: Sat, 11 Jan 2003 15:08:20 +0000
From: Matthew Byng-Maddick <mbm@colondot.net>
To: mbm@colondot.net
Subject: testing
Content-Type: multipart/signed; micalg=pgp-sha1;
        protocol="application/pgp-signature"; boundary="Kj7319i9nmIyA2yE"
Content-Disposition: inline

this is part of the mime data

--Kj7319i9nmIyA2yE
Content-Type: text/plain; charset=iso-8859-1
Content-Disposition: inline
Content-Transfer-Encoding: quoted-printable

I guess it's easier just to create the sig with something that's going to
do it properly.

This is data.
=3D yes, that's a straight equals sign.
=A3 should be a pound sign
does it work?

--Kj7319i9nmIyA2yE
Content-Type: application/pgp-signature
Content-Disposition: inline

-----BEGIN PGP SIGNATURE-----
Version: GnuPG v1.2.1 (FreeBSD)

iD8DBQE+IDNhiGjP99nB6xERAlcMAJ9yUT1tepglFKL9Wk1yiN4kId1OsQCePd01
ucfd7cpZ0KTJK7mxg7Hr950=
=FVae
-----END PGP SIGNATURE-----

--Kj7319i9nmIyA2yE--
