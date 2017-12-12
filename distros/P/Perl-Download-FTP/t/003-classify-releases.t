# -*- perl -*-
# t/003-classify-releases.t
use strict;
use warnings;
use 5.10.1;

use Perl::Download::FTP;
use Test::More;
unless ($ENV{PERL_ALLOW_NETWORK_TESTING}) {
    plan 'skip_all' => "Set PERL_ALLOW_NETWORK_TESTING to conduct live tests";
}
else {
    plan tests =>  68;
}
use Test::RequiresInternet ('ftp.cpan.org' => 21);
use List::Compare::Functional qw(
    is_LsubsetR
);
use Capture::Tiny qw( capture_stdout );

my ($self, $host, $dir);
my (@allarchives, $allcount, @gzips, @bzips, @xzs);
my $default_host = 'ftp.cpan.org';
my $default_dir  = '/pub/CPAN/src/5.0';

$self = Perl::Download::FTP->new( {
    dir         => $default_dir,
    Passive     => 1,
} );
ok(defined $self, "Constructor returned defined object when using default values");
isa_ok ($self, 'Perl::Download::FTP');

@allarchives = $self->ls();
$allcount = scalar(@allarchives);
ok($allcount, "ls(): returned >0 elements: $allcount");

my $classified = $self->classify_releases();
my $classified_count =
    (scalar keys %{$classified->{dev}}) +
    (scalar keys %{$classified->{prod}}) +
    (scalar keys %{$classified->{rc}});
is($classified_count, $allcount,
    "Got expected number of classified entries: $allcount");

my (@prod, @dev, @rc, @three_oldest);
my (@prod1, @dev1, @rc1);

note("production releases");

@prod = $self->list_releases( {
    type            => 'production',
    compression     => 'gz',
} );
cmp_ok(scalar(@prod), '>=', 1, "Non-zero number of .gz tarballs listed");
@three_oldest = (
  "perl-5.6.0.tar.gz",
  "perl5.005.tar.gz",
  "perl5.004.tar.gz",
);
for (my $i = 0; $i <= $#three_oldest; $i++) {
    is($prod[$i-3], $three_oldest[$i], "Got $three_oldest[$i] where expected");
}

@prod = $self->list_releases( {
    type            => 'production',
    compression     => 'bz2',
} );
cmp_ok(scalar(@prod), '>=', 1, "Non-zero number of .bz2 tarballs listed");
@three_oldest = (
  "perl-5.8.4.tar.bz2",
  "perl-5.8.3.tar.bz2",
  "perl-5.8.2.tar.bz2",
);
for (my $i = 0; $i <= $#three_oldest; $i++) {
    is($prod[$i-3], $three_oldest[$i], "Got $three_oldest[$i] where expected");
}

@prod = $self->list_releases( {
    type            => 'production',
    compression     => 'xz',
} );
cmp_ok(scalar(@prod), '>=', 1, "Non-zero number of .xz tarballs listed");
@three_oldest = (
    "perl-5.22.2.tar.xz",
    "perl-5.22.1.tar.xz",
    "perl-5.22.0.tar.xz",
);
for (my $i = 0; $i <= $#three_oldest; $i++) {
    is($prod[$i-3], $three_oldest[$i], "Got $three_oldest[$i] where expected");
}

note("development releases");

@dev = $self->list_releases( {
    type            => 'development',
    compression     => 'gz',
} );
cmp_ok(scalar(@dev), '>=', 1, "Non-zero number of .gz tarballs listed");
@three_oldest = (
    "perl5.004_02.tar.gz",
    "perl5.004_01.tar.gz",
    "perl5.003_07.tar.gz",
);
for (my $i = 0; $i <= $#three_oldest; $i++) {
    is($dev[$i-3], $three_oldest[$i], "Got $three_oldest[$i] where expected");
}

note("list_releases() default case: type: dev compression: gz");

@dev = $self->list_releases();
cmp_ok(scalar(@dev), '>=', 1,
    "list_releases() default case: Non-zero number of .gz tarballs listed");
for (my $i = 0; $i <= $#three_oldest; $i++) {
    is($dev[$i-3], $three_oldest[$i],
        "list_releases() default case: Got $three_oldest[$i] where expected");
}

@dev = $self->list_releases( {
    type            => 'development',
    compression     => 'bz2',
} );
cmp_ok(scalar(@dev), '>=', 1, "Non-zero number of .bz2 tarballs listed");
@three_oldest = (
    "perl-5.11.1.tar.bz2",
    "perl-5.11.0.tar.bz2",
    "perl-5.9.0.tar.bz2",
);
for (my $i = 0; $i <= $#three_oldest; $i++) {
    is($dev[$i-3], $three_oldest[$i], "Got $three_oldest[$i] where expected");
}

@dev = $self->list_releases( {
    type            => 'development',
    compression     => 'xz',
} );
cmp_ok(scalar(@dev), '>=', 1, "Non-zero number of .xz tarballs listed");
@three_oldest = (
    "perl-5.21.8.tar.xz",
    "perl-5.21.7.tar.xz",
    "perl-5.21.6.tar.xz",
);
for (my $i = 0; $i <= $#three_oldest; $i++) {
    is($dev[$i-3], $three_oldest[$i], "Got $three_oldest[$i] where expected");
}

note("rc releases");

@rc = $self->list_releases( {
    type            => 'rc',
    compression     => 'gz',
} );
cmp_ok(scalar(@rc), '>=', 1, "Non-zero number of .gz tarballs listed");
@three_oldest = (
  "perl-5.6.1-TRIAL3.tar.gz",
  "perl-5.6.1-TRIAL2.tar.gz",
  "perl-5.6.1-TRIAL1.tar.gz",
);
for (my $i = 0; $i <= $#three_oldest; $i++) {
    is($rc[$i-3], $three_oldest[$i], "Got $three_oldest[$i] where expected");
}

@rc = $self->list_releases( {
    type            => 'rc',
    compression     => 'bz2',
} );
cmp_ok(scalar(@rc), '>=', 1, "Non-zero number of .bz2 tarballs listed");
@three_oldest = (
    "perl-5.12.2-RC1.tar.bz2",
    "perl-5.12.1-RC2.tar.bz2",
    "perl-5.12.1-RC1.tar.bz2",
);
for (my $i = 0; $i <= $#three_oldest; $i++) {
    is($rc[$i-3], $three_oldest[$i], "Got $three_oldest[$i] where expected");
}

@rc = $self->list_releases( {
    type            => 'rc',
    compression     => 'xz',
} );
cmp_ok(scalar(@rc), '>=', 1, "Non-zero number of .xz tarballs listed");
@three_oldest = (
    "perl-5.22.1-RC1.tar.xz",
    "perl-5.22.0-RC2.tar.xz",
    "perl-5.22.0-RC1.tar.xz",

);
for (my $i = 0; $i <= $#three_oldest; $i++) {
    is($rc[$i-3], $three_oldest[$i], "Got $three_oldest[$i] where expected");
}

###########################################################

note("Call a list_*_releases() method without previously calling classify_releases()");

my $self1;
$self1 = Perl::Download::FTP->new( {
    host        => $default_host,
    dir         => $default_dir,
    Passive     => 1,
} );
ok(defined $self1, "Constructor returned defined object when using default values");
isa_ok ($self1, 'Perl::Download::FTP');

@allarchives = $self1->ls();
$allcount = scalar(@allarchives);
ok($allcount, "ls(): returned >0 elements: $allcount");

note("production releases");

@prod = $self1->list_releases( {
    compression         => 'gz',
    type                => 'prod',
} );
cmp_ok(scalar(@prod), '>=', 1, "Non-zero number of .gz tarballs listed");
@three_oldest = (
  "perl-5.6.0.tar.gz",
  "perl5.005.tar.gz",
  "perl5.004.tar.gz",
);
for (my $i = 0; $i <= $#three_oldest; $i++) {
    is($prod[$i-3], $three_oldest[$i], "Got $three_oldest[$i] where expected");
}

note("development releases");

@dev = $self1->list_releases( {
    compression         => 'gz',
    type                => 'dev',
} );
cmp_ok(scalar(@dev), '>=', 1, "Non-zero number of .gz tarballs listed");
@three_oldest = (
    "perl5.004_02.tar.gz",
    "perl5.004_01.tar.gz",
    "perl5.003_07.tar.gz",
);
for (my $i = 0; $i <= $#three_oldest; $i++) {
    is($dev[$i-3], $three_oldest[$i], "Got $three_oldest[$i] where expected");
}

note("rc releases");

@rc = $self1->list_releases( {
    compression         => 'gz',
    type                => 'rc',
} );
cmp_ok(scalar(@rc), '>=', 1, "Non-zero number of .gz tarballs listed");
@three_oldest = (
  "perl-5.6.1-TRIAL3.tar.gz",
  "perl-5.6.1-TRIAL2.tar.gz",
  "perl-5.6.1-TRIAL1.tar.gz",
);
for (my $i = 0; $i <= $#three_oldest; $i++) {
    is($rc[$i-3], $three_oldest[$i], "Got $three_oldest[$i] where expected");
}

###########################################################

note("verbose output");

my ($self2, $stdout, $type, $compression);

$self2 = Perl::Download::FTP->new( {
    host        => $default_host,
    dir         => $default_dir,
    Passive     => 1,
    verbose     => 1,
} );
ok(defined $self2, "Constructor returned defined object when using default values");
isa_ok ($self2, 'Perl::Download::FTP');

$stdout = capture_stdout { @allarchives = $self2->ls(); };
$allcount = scalar(@allarchives);
ok($allcount, "ls(): returned >0 elements: $allcount");
like(
    $stdout,
    qr|Identified \d+ perl releases at ftp://${default_host}${default_dir}|,
    "ls(): Got expected verbose output"
);

$compression = 'gz';
$type = 'prod';
$stdout = capture_stdout {
    @prod = $self2->list_releases( {
        compression         => $compression,
        type                => $type,
    } );
};
like(
    $stdout,
    qr/Preparing list of '$type' releases with '$compression' compression/,
    "list_releases(): Got expected verbose output"
);
cmp_ok(scalar(@prod), '>=', 1, "Non-zero number of .gz tarballs listed");
@three_oldest = (
  "perl-5.6.0.tar.gz",
  "perl5.005.tar.gz",
  "perl5.004.tar.gz",
);
for (my $i = 0; $i <= $#three_oldest; $i++) {
    is($prod[$i-3], $three_oldest[$i], "Got $three_oldest[$i] where expected");
}

