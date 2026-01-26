#!/usr/bin/perl

package Test::CVE;

=head1 NAME

Test::CVE - Test against known CVE's

=head1 SYNOPSIS

 use Test::CVE;

 my $cve = Test::CVE->new (
    verbose  => 0,
    deps     => 1,
    perl     => 1,
    core     => 1,
    minimum  => 0,
    cpansa   => "https://cpan-security.github.io/cpansa-feed/cpansa.json",
    cpanfile => "cpanfile",
    meta_jsn => "META.json",
    meta_yml => "META.yml",     # NYI
    make_pl  => "Makefile.PL",
    build_pl => "Build.PL",     # NYI
    want     => [],
    skip     => "CVE.SKIP",
    );

 $cve->skip ("CVE.SKIP");
 $cve->skip ([qw( CVE-2011-0123 CVE-2020-1234 )]);

 $cve->want ("Foo::Bar", "4.321");
 $cve->want ("ExtUtils-MakeMaker");

 $cve->test;
 print $cve->report (width => $ENV{COLUMNS} || 80);
 my $csv = $cve->csv;

 has_no_cves (....);

=cut

use 5.014000;
use warnings;

our $VERSION = "0.12";

use version;
use Carp;
use HTTP::Tiny;
use Text::Wrap;
use JSON::MaybeXS;
use Module::CoreList;
use YAML::PP     ();
use List::Util qw( first uniq );
use base       qw( Test::Builder::Module );

use parent "Exporter";
our @EXPORT  = qw( has_no_cves );

# TODO:
# * NEW! https://fastapi.metacpan.org/cve/CPANSA-YAML-LibYAML-2012-1152
#        https://fastapi.metacpan.org/cve/release/YAML-1.20_001
# * Module::Install Makefile.PL's
#   use inc::Module::Install;
#   name            'Algorithm-Diff-XS';
#   license         'perl';
#   all_from        'lib/Algorithm/Diff/XS.pm';
# * Module::Build

sub new {
    my $class = shift;
    @_ % 2 and croak "Uneven number of arguments";
    my %self  = @_;
    $self{cpansa}   ||= "https://cpan-security.github.io/cpansa-feed/cpansa.json";
    $self{deps}     //= 1;
    $self{perl}     //= 1;
    $self{core}     //= 1;
    $self{minimum}  //= 0;
    $self{verbose}  //= 0;
    $self{width}    //= $ENV{COLUMNS} // 80;
    $self{want}     //= [];
    $self{cpanfile} ||= "cpanfile";
    $self{meta_jsn} ||= "META.json";
    $self{meta_yml} ||= "META.yml";
    $self{make_pl}  ||= "Makefile.PL";
    $self{build_pl} ||= "Build.PL";
    $self{CVE}        = {};
    ref $self{want} or $self{want} = [ $self{want} ]; # new->(want => "Foo")
    my $obj = bless \%self => $class;
    $obj->skip ($self{skip} // "CVE.SKIP");
    return $obj;
    } # new

sub skip {
    my $self = shift;
    if (@_) {
	if (my $skip = shift) {
	    if (ref $skip eq "HASH") {
		$self->{skip} = $skip;
		}
	    elsif (ref $skip eq "ARRAY") {
		$self->{skip} = { map { $_ => 1 } @$skip };
		}
	    elsif ($skip =~ m/^\x20-\xff]+$/ and open my $fh, "<", $skip) {
		my %s;
		while (<$fh>) {
		    s/[\s\r\n]+\z//;
		    m/^\s*(\w[-\w]+)(?:\s+(.*))?$/ or next;
		    $s{$1} = $2 // "";
		    }
		close $fh;
		$self->{skip} = { %s };
		}
	    else {
		$self->{skip} = {
		    map  { $_ => 1 }
		    grep { m/^\w[-\w]+$/ }
		    $skip, @_
		    };
		}
	    }
	else {
	    $self->{skip} = undef;
	    }
	}
    $self->{skip} ||= {};
    return [ sort keys %{$self->{skip}} ];
    } # skip

sub _read_cpansa {
    my $self = shift;
    my $src  = $self->{cpansa} or croak "No source for CVE database";
    $self->{verbose} and warn "Reading $src ...\n";

    # Old format
    # 'Compress-LZ4'   => [
    #   { affected_versions => [
    #       '<0.20'
    #       ],
    #     cpansa_id         => 'CPANSA-Compress-LZ4-2014-01',
    #     cves              => [],
    #     description       => 'Outdated LZ4 source code with security issue on 32bit systems.
    #
    #     references        => [
    #       'https://metacpan.org/changes/distribution/Compress-LZ4',
    #       'https://github.com/gray/compress-lz4/commit/fc503812b4cbba16429658e1dfe20ad8bbfd77a0'
    #       ],
    #     reported          => '2014-07-07',
    #     severity          => undef
    #     }
    #   ],

    # New format
    # "Compress-Raw-Bzip2" : [
    #  {  "affected_releases" : [   ],
    #     "cpansec_index" : "abc76ca939abad86a25c686b4d73fbecb8332f21",
    #     "cve" : "{\"dataType\":\"CVE_RECORD\",\"dataVersion\":\"5.1\",\"containers\":{\"adp\":[{\"providerMetadata\":{\"orgId\":\"af854a3a-2127-422b-91ae-364da2661108\",\"shortName\":\"CVE\",\"dateUpdated\":\"2024-08-07T00:45:12.275Z\"},\"title\":\"CVE Program Container\",\"references\":[{\"tags\":[\"vendor-advisory\",\"x_refsource_UBUNTU\",\"x_transferred\"],\"name\":\"USN-986-3\",\"url\":\"http://www.ubuntu.com/usn/USN-986-3\"},{\"url\":\"http://git.clamav.net/gitweb?p=clamav-devel.git%3Ba=blob_plain%3Bf=ChangeLog%3Bhb=clamav-0.96.3\",\"tags\":[\"x_refsource_CONFIRM\",\"x_transferred\"]},{\"url\":\"http://lists.fedoraproject.org/pipermail/package-announce/2010-November/051278.html\",\"name\":\"FEDORA-2010-17439\",\"tags\":[\"vendor-advisory\",\"x_refsource_FEDORA\",\"x_transferred\"]},{\"url\":\"http://www.ubuntu.com/usn/usn-986-1\",\"name\":\"USN-986-1\",\"tags\":[\"vendor-advisory\",\"x_refsource_UBUNTU\",\"x_transferred\"]},{\"name\":\"USN-986-2\",\"tags\":[\"vendor-advisory\",\"x_refsource_UBUNTU\",\"x_transferred\"],\"url\":\"http://www.ubuntu.com/usn/USN-986-2\"},{\"url\":\"http://secunia.com/advisories/41452\",\"name\":\"41452\",\"tags\":[\"third-party-advisory\",\"x_refsource_SECUNIA\",\"x_transferred\"]},{\"url\":\"http://secunia.com/advisories/42404\",\"tags\":[\"third-party-advisory\",\"x_refsource_SECUNIA\",\"x_transferred\"],\"name\":\"42404\"},{\"tags\":[\"third-party-advisory\",\"x_refsource_SECUNIA\",\"x_transferred\"],\"name\":\"48378\",\"url\":\"http://secunia.com/advisories/48378\"},{\"url\":\"https://wwws.clamav.net/bugzilla/show_bug.cgi?id=2230\",\"tags\":[\"x_refsource_CONFIRM\",\"x_transferred\"]},{\"name\":\"ADV-2010-3073\",\"tags\":[\"vdb-entry\",\"x_refsource_VUPEN\",\"x_transferred\"],\"url\":\"http://www.vupen.com/english/advisories/2010/3073\"},{\"url\":\"http://www.vupen.com/english/advisories/2010/2455\",\"name\":\"ADV-2010-2455\",\"tags\":[\"vdb-entry\",\"x_refsource_VUPEN\",\"x_transferred\"]},{\"tags\":[\"vendor-advisory\",\"x_refsource_APPLE\",\"x_transferred\"],\"name\":\"APPLE-SA-2011-03-21-1\",\"url\":\"http://lists.apple.com/archives/security-announce/2011/Mar/msg00006.html\"},{\"url\":\"http://secunia.com/advisories/42530\",\"tags\":[\"third-party-advisory\",\"x_refsource_SECUNIA\",\"x_transferred\"],\"name\":\"42530\"},{\"tags\":[\"x_refsource_CONFIRM\",\"x_transferred\"],\"url\":\"https://wwws.clamav.net/bugzilla/show_bug.cgi?id=2231\"},{\"url\":\"http://marc.info/?l=oss-security&m=128506868510655&w=2\",\"name\":\"[oss-security] 20100921 bzip2 CVE-2010-0405 integer overflow\",\"tags\":[\"mailing-list\",\"x_refsource_MLIST\",\"x_transferred\"]},{\"tags\":[\"third-party-advisory\",\"x_refsource_SECUNIA\",\"x_transferred\"],\"name\":\"42529\",\"url\":\"http://secunia.com/advisories/42529\"},{\"url\":\"http://www.securityfocus.com/archive/1/515055/100/0/threaded\",\"name\":\"20101207 VMSA-2010-0019 VMware ESX third party updates for Service Console\",\"tags\":[\"mailing-list\",\"x_refsource_BUGTRAQ\",\"x_transferred\"]},{\"url\":\"http://secunia.com/advisories/41505\",\"name\":\"41505\",\"tags\":[\"third-party-advisory\",\"x_refsource_SECUNIA\",\"x_transferred\"]},{\"tags\":[\"vdb-entry\",\"x_refsource_VUPEN\",\"x_transferred\"],\"name\":\"ADV-2010-3052\",\"url\":\"http://www.vupen.com/english/advisories/2010/3052\"},{\"tags\":[\"vendor-advisory\",\"x_refsource_REDHAT\",\"x_transferred\"],\"name\":\"RHSA-2010:0703\",\"url\":\"http://www.redhat.com/support/errata/RHSA-2010-0703.html\"},{\"name\":\"RHSA-2010:0858\",\"tags\":[\"vendor-advisory\",\"x_refsource_REDHAT\",\"x_transferred\"],\"url\":\"http://www.redhat.com/support/errata/RHSA-2010-0858.html\"},{\"name\":\"FEDORA-2010-1512\",\"tags\":[\"vendor-advisory\",\"x_refsource_FEDORA\",\"x_transferred\"],\"url\":\"http://lists.fedoraproject.org/pipermail/package-announce/2010-November/051366.html\"},{\"tags\":[\"x_refsource_CONFIRM\",\"x_transferred\"],\"url\":\"http://blogs.sun.com/security/entry/cve_2010_0405_integer_overflow\"},{\"name\":\"42405\",\"tags\":[\"third-party-advisory\",\"x_refsource_SECUNIA\",\"x_transferred\"],\"url\":\"http://secunia.com/advisories/42405\"},{\"url\":\"http://xorl.wordpress.com/2010/09/21/cve-2010-0405-bzip2-integer-overflow/\",\"tags\":[\"x_refsource_CONFIRM\",\"x_transferred\"]},{\"tags\":[\"x_refsource_CONFIRM\",\"x_transferred\"],\"url\":\"https://bugzilla.redhat.com/show_bug.cgi?id=627882\"},{\"name\":\"ADV-2010-3126\",\"tags\":[\"vdb-entry\",\"x_refsource_VUPEN\",\"x_transferred\"],\"url\":\"http://www.vupen.com/english/advisories/2010/3126\"},{\"name\":\"GLSA-201301-05\",\"tags\":[\"vendor-advisory\",\"x_refsource_GENTOO\",\"x_transferred\"],\"url\":\"http://security.gentoo.org/glsa/glsa-201301-05.xml\"},{\"url\":\"http://www.vmware.com/security/advisories/VMSA-2010-0019.html\",\"tags\":[\"x_refsource_CONFIRM\",\"x_transferred\"]},{\"tags\":[\"x_refsource_CONFIRM\",\"x_transferred\"],\"url\":\"http://www.bzip.org/\"},{\"url\":\"http://www.vupen.com/english/advisories/2010/3127\",\"name\":\"ADV-2010-3127\",\"tags\":[\"vdb-entry\",\"x_refsource_VUPEN\",\"x_transferred\"]},{\"name\":\"ADV-2010-3043\",\"tags\":[\"vdb-entry\",\"x_refsource_VUPEN\",\"x_transferred\"],\"url\":\"http://www.vupen.com/english/advisories/2010/3043\"},{\"name\":\"SUSE-SR:2010:018\",\"tags\":[\"vendor-advisory\",\"x_refsource_SUSE\",\"x_transferred\"],\"url\":\"http://lists.opensuse.org/opensuse-security-announce/2010-10/msg00000.html\"},{\"url\":\"http://secunia.com/advisories/42350\",\"name\":\"42350\",\"tags\":[\"third-party-advisory\",\"x_refsource_SECUNIA\",\"x_transferred\"]},{\"tags\":[\"x_refsource_CONFIRM\",\"x_transferred\"],\"url\":\"http://support.apple.com/kb/HT4581\"}]}],\"cna\":{\"descriptions\":[{\"value\":\"Integer overflow in the BZ2_decompress function in decompress.c in bzip2 and libbzip2 before 1.0.6 allows context-dependent attackers to cause a denial of service (application crash) or possibly execute arbitrary code via a crafted compressed file.\",\"lang\":\"en\"}],\"datePublic\":\"2010-09-21T00:00:00\",\"affected\":[{\"vendor\":\"n/a\",\"product\":\"n/a\",\"versions\":[{\"version\":\"n/a\",\"status\":\"affected\"}]}],\"references\":[{\"tags\":[\"vendor-advisory\",\"x_refsource_UBUNTU\"],\"name\":\"USN-986-3\",\"url\":\"http://www.ubuntu.com/usn/USN-986-3\"},{\"url\":\"http://git.clamav.net/gitweb?p=clamav-devel.git%3Ba=blob_plain%3Bf=ChangeLog%3Bhb=clamav-0.96.3\",\"tags\":[\"x_refsource_CONFIRM\"]},{\"url\":\"http://lists.fedoraproject.org/pipermail/package-announce/2010-November/051278.html\",\"name\":\"FEDORA-2010-17439\",\"tags\":[\"vendor-advisory\",\"x_refsource_FEDORA\"]},{\"url\":\"http://www.ubuntu.com/usn/usn-986-1\",\"tags\":[\"vendor-advisory\",\"x_refsource_UBUNTU\"],\"name\":\"USN-986-1\"},{\"name\":\"USN-986-2\",\"tags\":[\"vendor-advisory\",\"x_refsource_UBUNTU\"],\"url\":\"http://www.ubuntu.com/usn/USN-986-2\"},{\"url\":\"http://secunia.com/advisories/41452\",\"name\":\"41452\",\"tags\":[\"third-party-advisory\",\"x_refsource_SECUNIA\"]},{\"url\":\"http://secunia.com/advisories/42404\",\"name\":\"42404\",\"tags\":[\"third-party-advisory\",\"x_refsource_SECUNIA\"]},{\"url\":\"http://secunia.com/advisories/48378\",\"tags\":[\"third-party-advisory\",\"x_refsource_SECUNIA\"],\"name\":\"48378\"},{\"url\":\"https://wwws.clamav.net/bugzilla/show_bug.cgi?id=2230\",\"tags\":[\"x_refsource_CONFIRM\"]},{\"url\":\"http://www.vupen.com/english/advisories/2010/3073\",\"name\":\"ADV-2010-3073\",\"tags\":[\"vdb-entry\",\"x_refsource_VUPEN\"]},{\"tags\":[\"vdb-entry\",\"x_refsource_VUPEN\"],\"name\":\"ADV-2010-2455\",\"url\":\"http://www.vupen.com/english/advisories/2010/2455\"},{\"url\":\"http://lists.apple.com/archives/security-announce/2011/Mar/msg00006.html\",\"name\":\"APPLE-SA-2011-03-21-1\",\"tags\":[\"vendor-advisory\",\"x_refsource_APPLE\"]},{\"url\":\"http://secunia.com/advisories/42530\",\"tags\":[\"third-party-advisory\",\"x_refsource_SECUNIA\"],\"name\":\"42530\"},{\"url\":\"https://wwws.clamav.net/bugzilla/show_bug.cgi?id=2231\",\"tags\":[\"x_refsource_CONFIRM\"]},{\"name\":\"[oss-security] 20100921 bzip2 CVE-2010-0405 integer overflow\",\"tags\":[\"mailing-list\",\"x_refsource_MLIST\"],\"url\":\"http://marc.info/?l=oss-security&m=128506868510655&w=2\"},{\"url\":\"http://secunia.com/advisories/42529\",\"name\":\"42529\",\"tags\":[\"third-party-advisory\",\"x_refsource_SECUNIA\"]},{\"url\":\"http://www.securityfocus.com/archive/1/515055/100/0/threaded\",\"tags\":[\"mailing-list\",\"x_refsource_BUGTRAQ\"],\"name\":\"20101207 VMSA-2010-0019 VMware ESX third party updates for Service Console\"},{\"tags\":[\"third-party-advisory\",\"x_refsource_SECUNIA\"],\"name\":\"41505\",\"url\":\"http://secunia.com/advisories/41505\"},{\"name\":\"ADV-2010-3052\",\"tags\":[\"vdb-entry\",\"x_refsource_VUPEN\"],\"url\":\"http://www.vupen.com/english/advisories/2010/3052\"},{\"url\":\"http://www.redhat.com/support/errata/RHSA-2010-0703.html\",\"tags\":[\"vendor-advisory\",\"x_refsource_REDHAT\"],\"name\":\"RHSA-2010:0703\"},{\"tags\":[\"vendor-advisory\",\"x_refsource_REDHAT\"],\"name\":\"RHSA-2010:0858\",\"url\":\"http://www.redhat.com/support/errata/RHSA-2010-0858.html\"},{\"tags\":[\"vendor-advisory\",\"x_refsource_FEDORA\"],\"name\":\"FEDORA-2010-1512\",\"url\":\"http://lists.fedoraproject.org/pipermail/package-announce/2010-November/051366.html\"},{\"url\":\"http://blogs.sun.com/security/entry/cve_2010_0405_integer_overflow\",\"tags\":[\"x_refsource_CONFIRM\"]},{\"url\":\"http://secunia.com/advisories/42405\",\"name\":\"42405\",\"tags\":[\"third-party-advisory\",\"x_refsource_SECUNIA\"]},{\"url\":\"http://xorl.wordpress.com/2010/09/21/cve-2010-0405-bzip2-integer-overflow/\",\"tags\":[\"x_refsource_CONFIRM\"]},{\"url\":\"https://bugzilla.redhat.com/show_bug.cgi?id=627882\",\"tags\":[\"x_refsource_CONFIRM\"]},{\"tags\":[\"vdb-entry\",\"x_refsource_VUPEN\"],\"name\":\"ADV-2010-3126\",\"url\":\"http://www.vupen.com/english/advisories/2010/3126\"},{\"name\":\"GLSA-201301-05\",\"tags\":[\"vendor-advisory\",\"x_refsource_GENTOO\"],\"url\":\"http://security.gentoo.org/glsa/glsa-201301-05.xml\"},{\"url\":\"http://www.vmware.com/security/advisories/VMSA-2010-0019.html\",\"tags\":[\"x_refsource_CONFIRM\"]},{\"url\":\"http://www.bzip.org/\",\"tags\":[\"x_refsource_CONFIRM\"]},{\"name\":\"ADV-2010-3127\",\"tags\":[\"vdb-entry\",\"x_refsource_VUPEN\"],\"url\":\"http://www.vupen.com/english/advisories/2010/3127\"},{\"name\":\"ADV-2010-3043\",\"tags\":[\"vdb-entry\",\"x_refsource_VUPEN\"],\"url\":\"http://www.vupen.com/english/advisories/2010/3043\"},{\"url\":\"http://lists.opensuse.org/opensuse-security-announce/2010-10/msg00000.html\",\"name\":\"SUSE-SR:2010:018\",\"tags\":[\"vendor-advisory\",\"x_refsource_SUSE\"]},{\"url\":\"http://secunia.com/advisories/42350\",\"name\":\"42350\",\"tags\":[\"third-party-advisory\",\"x_refsource_SECUNIA\"]},{\"tags\":[\"x_refsource_CONFIRM\"],\"url\":\"http://support.apple.com/kb/HT4581\"}],\"problemTypes\":[{\"descriptions\":[{\"type\":\"text\",\"lang\":\"en\",\"description\":\"n/a\"}]}],\"providerMetadata\":{\"dateUpdated\":\"2018-10-10T18:57:01\",\"shortName\":\"mitre\",\"orgId\":\"8254265b-2729-46b6-b9e3-3dfca2d5bfca\"},\"x_legacyV4Record\":{\"affects\":{\"vendor\":{\"vendor_data\":[{\"product\":{\"product_data\":[{\"product_name\":\"n/a\",\"version\":{\"version_data\":[{\"version_value\":\"n/a\"}]}}]},\"vendor_name\":\"n/a\"}]}},\"data_type\":\"CVE\",\"data_format\":\"MITRE\",\"problemtype\":{\"problemtype_data\":[{\"description\":[{\"value\":\"n/a\",\"lang\":\"eng\"}]}]},\"description\":{\"description_data\":[{\"value\":\"Integer overflow in the BZ2_decompress function in decompress.c in bzip2 and libbzip2 before 1.0.6 allows context-dependent attackers to cause a denial of service (application crash) or possibly execute arbitrary code via a crafted compressed file.\",\"lang\":\"eng\"}]},\"data_version\":\"4.0\",\"references\":{\"reference_data\":[{\"url\":\"http://www.ubuntu.com/usn/USN-986-3\",\"name\":\"USN-986-3\",\"refsource\":\"UBUNTU\"},{\"refsource\":\"CONFIRM\",\"name\":\"http://git.clamav.net/gitweb?p=clamav-devel.git;a=blob_plain;f=ChangeLog;hb=clamav-0.96.3\",\"url\":\"http://git.clamav.net/gitweb?p=clamav-devel.git;a=blob_plain;f=ChangeLog;hb=clamav-0.96.3\"},{\"url\":\"http://lists.fedoraproject.org/pipermail/package-announce/2010-November/051278.html\",\"name\":\"FEDORA-2010-17439\",\"refsource\":\"FEDORA\"},{\"name\":\"USN-986-1\",\"refsource\":\"UBUNTU\",\"url\":\"http://www.ubuntu.com/usn/usn-986-1\"},{\"url\":\"http://www.ubuntu.com/usn/USN-986-2\",\"name\":\"USN-986-2\",\"refsource\":\"UBUNTU\"},{\"name\":\"41452\",\"refsource\":\"SECUNIA\",\"url\":\"http://secunia.com/advisories/41452\"},{\"url\":\"http://secunia.com/advisories/42404\",\"name\":\"42404\",\"refsource\":\"SECUNIA\"},{\"url\":\"http://secunia.com/advisories/48378\",\"refsource\":\"SECUNIA\",\"name\":\"48378\"},{\"url\":\"https://wwws.clamav.net/bugzilla/show_bug.cgi?id=2230\",\"refsource\":\"CONFIRM\",\"name\":\"https://wwws.clamav.net/bugzilla/show_bug.cgi?id=2230\"},{\"name\":\"ADV-2010-3073\",\"refsource\":\"VUPEN\",\"url\":\"http://www.vupen.com/english/advisories/2010/3073\"},{\"url\":\"http://www.vupen.com/english/advisories/2010/2455\",\"refsource\":\"VUPEN\",\"name\":\"ADV-2010-2455\"},{\"refsource\":\"APPLE\",\"name\":\"APPLE-SA-2011-03-21-1\",\"url\":\"http://lists.apple.com/archives/security-announce/2011/Mar/msg00006.html\"},{\"name\":\"42530\",\"refsource\":\"SECUNIA\",\"url\":\"http://secunia.com/advisories/42530\"},{\"url\":\"https://wwws.clamav.net/bugzilla/show_bug.cgi?id=2231\",\"name\":\"https://wwws.clamav.net/bugzilla/show_bug.cgi?id=2231\",\"refsource\":\"CONFIRM\"},{\"url\":\"http://marc.info/?l=oss-security&m=128506868510655&w=2\",\"name\":\"[oss-security] 20100921 bzip2 CVE-2010-0405 integer overflow\",\"refsource\":\"MLIST\"},{\"refsource\":\"SECUNIA\",\"name\":\"42529\",\"url\":\"http://secunia.com/advisories/42529\"},{\"name\":\"20101207 VMSA-2010-0019 VMware ESX third party updates for Service Console\",\"refsource\":\"BUGTRAQ\",\"url\":\"http://www.securityfocus.com/archive/1/515055/100/0/threaded\"},{\"name\":\"41505\",\"refsource\":\"SECUNIA\",\"url\":\"http://secunia.com/advisories/41505\"},{\"name\":\"ADV-2010-3052\",\"refsource\":\"VUPEN\",\"url\":\"http://www.vupen.com/english/advisories/2010/3052\"},{\"url\":\"http://www.redhat.com/support/errata/RHSA-2010-0703.html\",\"name\":\"RHSA-2010:0703\",\"refsource\":\"REDHAT\"},{\"url\":\"http://www.redhat.com/support/errata/RHSA-2010-0858.html\",\"refsource\":\"REDHAT\",\"name\":\"RHSA-2010:0858\"},{\"name\":\"FEDORA-2010-1512\",\"refsource\":\"FEDORA\",\"url\":\"http://lists.fedoraproject.org/pipermail/package-announce/2010-November/051366.html\"},{\"refsource\":\"CONFIRM\",\"name\":\"http://blogs.sun.com/security/entry/cve_2010_0405_integer_overflow\",\"url\":\"http://blogs.sun.com/security/entry/cve_2010_0405_integer_overflow\"},{\"url\":\"http://secunia.com/advisories/42405\",\"refsource\":\"SECUNIA\",\"name\":\"42405\"},{\"name\":\"http://xorl.wordpress.com/2010/09/21/cve-2010-0405-bzip2-integer-overflow/\",\"refsource\":\"CONFIRM\",\"url\":\"http://xorl.wordpress.com/2010/09/21/cve-2010-0405-bzip2-integer-overflow/\"},{\"name\":\"https://bugzilla.redhat.com/show_bug.cgi?id=627882\",\"refsource\":\"CONFIRM\",\"url\":\"https://bugzilla.redhat.com/show_bug.cgi?id=627882\"},{\"refsource\":\"VUPEN\",\"name\":\"ADV-2010-3126\",\"url\":\"http://www.vupen.com/english/advisories/2010/3126\"},{\"refsource\":\"GENTOO\",\"name\":\"GLSA-201301-05\",\"url\":\"http://security.gentoo.org/glsa/glsa-201301-05.xml\"},{\"url\":\"http://www.vmware.com/security/advisories/VMSA-2010-0019.html\",\"name\":\"http://www.vmware.com/security/advisories/VMSA-2010-0019.html\",\"refsource\":\"CONFIRM\"},{\"url\":\"http://www.bzip.org/\",\"name\":\"http://www.bzip.org/\",\"refsource\":\"CONFIRM\"},{\"refsource\":\"VUPEN\",\"name\":\"ADV-2010-3127\",\"url\":\"http://www.vupen.com/english/advisories/2010/3127\"},{\"refsource\":\"VUPEN\",\"name\":\"ADV-2010-3043\",\"url\":\"http://www.vupen.com/english/advisories/2010/3043\"},{\"url\":\"http://lists.opensuse.org/opensuse-security-announce/2010-10/msg00000.html\",\"refsource\":\"SUSE\",\"name\":\"SUSE-SR:2010:018\"},{\"url\":\"http://secunia.com/advisories/42350\",\"refsource\":\"SECUNIA\",\"name\":\"42350\"},{\"name\":\"http://support.apple.com/kb/HT4581\",\"refsource\":\"CONFIRM\",\"url\":\"http://support.apple.com/kb/HT4581\"}]},\"CVE_data_meta\":{\"STATE\":\"PUBLIC\",\"ID\":\"CVE-2010-0405\",\"ASSIGNER\":\"cve@mitre.org\"}}}},\"cveMetadata\":{\"assignerOrgId\":\"8254265b-2729-46b6-b9e3-3dfca2d5bfca\",\"dateReserved\":\"2010-01-27T00:00:00\",\"dateUpdated\":\"2024-08-07T00:45:12.275Z\",\"cveId\":\"CVE-2010-0405\",\"assignerShortName\":\"mitre\",\"datePublished\":\"2010-09-28T17:00:00\",\"state\":\"PUBLISHED\"}}",
    #     "cve_id" : "CVE-2010-0405",
    #     "distribution" : "Compress-Raw-Bzip2",
    #     "references" : [
    #        "https://metacpan.org/changes/distribution/Compress-Raw-Bzip2"
    #        ],
    #     "title" : "Integer overflow in the BZ2_decompress function in decompress.c in bzip2 and libbzip2 before 1.0.6 allows context-dependent attackers to cause a denial of service (application crash) or possibly execute arbitrary code via a crafted compressed file.\n",
    #     "version_range" : [   ]
    #     },
    #  {  "affected_releases" : [   ],
    #     "cpansec_index" : "6a5ff392457db9df98944eb4d6b0b390b11e09d2",
    #     "cve" : "{\"cveMetadata\":{\"assignerOrgId\":\"53f830b8-0a3f-465b-8143-3b8a9948e749\",\"dateReserved\":\"2009-06-02T00:00:00\",\"dateUpdated\":\"2024-08-07T05:27:54.590Z\",\"cveId\":\"CVE-2009-1884\",\"datePublished\":\"2009-08-19T17:00:00\",\"assignerShortName\":\"redhat\",\"state\":\"PUBLISHED\"},\"containers\":{\"cna\":{\"problemTypes\":[{\"descriptions\":[{\"type\":\"text\",\"lang\":\"en\",\"description\":\"n/a\"}]}],\"references\":[{\"url\":\"http://secunia.com/advisories/36415\",\"tags\":[\"third-party-advisory\",\"x_refsource_SECUNIA\"],\"name\":\"36415\"},{\"url\":\"https://www.redhat.com/archives/fedora-package-announce/2009-August/msg00999.html\",\"tags\":[\"vendor-advisory\",\"x_refsource_FEDORA\"],\"name\":\"FEDORA-2009-8888\"},{\"name\":\"FEDORA-2009-8868\",\"tags\":[\"vendor-advisory\",\"x_refsource_FEDORA\"],\"url\":\"https://www.redhat.com/archives/fedora-package-announce/2009-August/msg00982.html\"},{\"tags\":[\"x_refsource_CONFIRM\"],\"url\":\"https://bugzilla.redhat.com/show_bug.cgi?id=518278\"},{\"url\":\"http://www.securityfocus.com/bid/36082\",\"name\":\"36082\",\"tags\":[\"vdb-entry\",\"x_refsource_BID\"]},{\"url\":\"http://secunia.com/advisories/36386\",\"name\":\"36386\",\"tags\":[\"third-party-advisory\",\"x_refsource_SECUNIA\"]},{\"url\":\"http://security.gentoo.org/glsa/glsa-200908-07.xml\",\"tags\":[\"vendor-advisory\",\"x_refsource_GENTOO\"],\"name\":\"GLSA-200908-07\"},{\"name\":\"compressrawbzip2-bzinflate-dos(52628)\",\"tags\":[\"vdb-entry\",\"x_refsource_XF\"],\"url\":\"https://exchange.xforce.ibmcloud.com/vulnerabilities/52628\"},{\"url\":\"https://bugs.gentoo.org/show_bug.cgi?id=281955\",\"tags\":[\"x_refsource_CONFIRM\"]}],\"providerMetadata\":{\"orgId\":\"53f830b8-0a3f-465b-8143-3b8a9948e749\",\"shortName\":\"redhat\",\"dateUpdated\":\"2017-08-16T14:57:01\"},\"datePublic\":\"2009-08-18T00:00:00\",\"affected\":[{\"versions\":[{\"status\":\"affected\",\"version\":\"n/a\"}],\"product\":\"n/a\",\"vendor\":\"n/a\"}],\"descriptions\":[{\"lang\":\"en\",\"value\":\"Off-by-one error in the bzinflate function in Bzip2.xs in the Compress-Raw-Bzip2 module before 2.018 for Perl allows context-dependent attackers to cause a denial of service (application hang or crash) via a crafted bzip2 compressed stream that triggers a buffer overflow, a related issue to CVE-2009-1391.\"}]},\"adp\":[{\"providerMetadata\":{\"orgId\":\"af854a3a-2127-422b-91ae-364da2661108\",\"dateUpdated\":\"2024-08-07T05:27:54.590Z\",\"shortName\":\"CVE\"},\"title\":\"CVE Program Container\",\"references\":[{\"tags\":[\"third-party-advisory\",\"x_refsource_SECUNIA\",\"x_transferred\"],\"name\":\"36415\",\"url\":\"http://secunia.com/advisories/36415\"},{\"tags\":[\"vendor-advisory\",\"x_refsource_FEDORA\",\"x_transferred\"],\"name\":\"FEDORA-2009-8888\",\"url\":\"https://www.redhat.com/archives/fedora-package-announce/2009-August/msg00999.html\"},{\"name\":\"FEDORA-2009-8868\",\"tags\":[\"vendor-advisory\",\"x_refsource_FEDORA\",\"x_transferred\"],\"url\":\"https://www.redhat.com/archives/fedora-package-announce/2009-August/msg00982.html\"},{\"url\":\"https://bugzilla.redhat.com/show_bug.cgi?id=518278\",\"tags\":[\"x_refsource_CONFIRM\",\"x_transferred\"]},{\"url\":\"http://www.securityfocus.com/bid/36082\",\"tags\":[\"vdb-entry\",\"x_refsource_BID\",\"x_transferred\"],\"name\":\"36082\"},{\"tags\":[\"third-party-advisory\",\"x_refsource_SECUNIA\",\"x_transferred\"],\"name\":\"36386\",\"url\":\"http://secunia.com/advisories/36386\"},{\"url\":\"http://security.gentoo.org/glsa/glsa-200908-07.xml\",\"tags\":[\"vendor-advisory\",\"x_refsource_GENTOO\",\"x_transferred\"],\"name\":\"GLSA-200908-07\"},{\"tags\":[\"vdb-entry\",\"x_refsource_XF\",\"x_transferred\"],\"name\":\"compressrawbzip2-bzinflate-dos(52628)\",\"url\":\"https://exchange.xforce.ibmcloud.com/vulnerabilities/52628\"},{\"url\":\"https://bugs.gentoo.org/show_bug.cgi?id=281955\",\"tags\":[\"x_refsource_CONFIRM\",\"x_transferred\"]}]}]},\"dataVersion\":\"5.1\",\"dataType\":\"CVE_RECORD\"}",
    #     "cve_id" : "CVE-2009-1884",
    #     "distribution" : "Compress-Raw-Bzip2",
    #     "references" : [
    #        "http://security.gentoo.org/glsa/glsa-200908-07.xml",
    #        "https://bugs.gentoo.org/show_bug.cgi?id=281955",
    #        "https://www.redhat.com/archives/fedora-package-announce/2009-August/msg00999.html",
    #        "https://www.redhat.com/archives/fedora-package-announce/2009-August/msg00982.html",
    #        "http://www.securityfocus.com/bid/36082",
    #        "http://secunia.com/advisories/36386",
    #        "https://bugzilla.redhat.com/show_bug.cgi?id=518278",
    #        "http://secunia.com/advisories/36415",
    #        "https://exchange.xforce.ibmcloud.com/vulnerabilities/52628"
    #        ],
    #     "title" : "Off-by-one error in the bzinflate function in Bzip2.xs in the Compress-Raw-Bzip2 module before 2.018 for Perl allows context-dependent attackers to cause a denial of service (application hang or crash) via a crafted bzip2 compressed stream that triggers a buffer overflow, a related issue to CVE-2009-1391.\n",
    #     "version_range" : [   ]
    #     }
    #  ],

    if (-s $src) {
	open my $fh, "<", $src or croak "$src: $!\n";
	local $/;
	$self->{j}{db} = decode_json (<$fh>);
	close $fh;
	}
    else {
	my $r = HTTP::Tiny->new (verify_SSL => 1)->get ($src);
	$r->{success} or die "$src: $@\n";

	$self->{verbose} > 1 and warn "Got it. Decoding\n";
	if (my $c = $r->{content}) {
	    # Skip warning part
	    # CPANSA-perl-2023-47038 has more than 1 range bundled together in '>=5.30.0,<5.34.3,>=5.36.0,<5.36.3,>=5.38.0,<5.38.2'
	    # {"Alien-PCRE2":[{"affected_versions":["<0.016000"],"cpansa_id":"CPANSA-Alien-PCRE2-2019-20454","cves":["CVE-2019-20454"],"description":"An out-
	    $c =~ s/^\s*([^{]+?)[\s\r\n]*\{/{/s and warn "$1\n";
	    $self->{j}{db} = decode_json ($c);

	    ### JSON strings to JSON structs in new format
	    if (ref $self->{j}{db} eq "HASH" and my @jk = sort keys %{$self->{j}{db}}) {
		foreach my $k (@jk) {
		    foreach my $r (@{$self->{j}{db}{$k} || []}) {
			my $s = $r->{cve} or next;
			ref $s and next;
			$s =~ m/^{/ or next;
			$r->{cve} = decode_json ($s);
			}
		    }
		}
	    }
	else {
	    $self->{j}{db} = undef;
	    }
	}
    $self->{j}{mod} = [ sort keys %{$self->{j}{db} // {}} ];
    $self;
    } # _read_cpansa

sub _read_MakefilePL {
    my ($self, $mf) = @_;
    $mf ||= $self->{make_pl};

    $self->{verbose} and warn "Reading $mf ...\n";
    open my $fh, "<", $mf or return $self;
    my $mfc = do { local $/; <$fh> };
    close $fh;

    $mfc or return $self;

    my ($pv, $release, $nm, $v, $vf) = ("");
    foreach my $mfx (grep { m/=>/ }
		     map  { split m/\s*[;(){}]\s*/ }
		     map  { split m/\s*,(?!\s*=>)/ }
			    split m/[,;]\s*(?:#.*)?\r*\n/ => $mfc) {
	$mfx =~ s/[\s\r\n]+/ /g;
	$mfx =~ s/^\s+//;
	$mfx =~ s/^(['"])(.*?)\1/$2/;	# Unquote key
	my $a = qr{\s* (?:,\s*)? => \s* (?|"([^""]*)"|'([^'']*)'|([-\w.]+))}x;
	$mfx =~ m/^ VERSION          $a /ix and $v       //= $1;
	$mfx =~ m/^ VERSION_FROM     $a /ix and $vf      //= $1;
	$mfx =~ m/^     NAME         $a /ix and $nm      //= $1;
	$mfx =~ m/^ DISTNAME         $a /ix and $release //= $1;
	$mfx =~ m/^ MIN_PERL_VERSION $a /ix and $pv      ||= $1;
	}

    unless ($release || $nm) {
	carp "Cannot get either NAME or DISTNAME, so cowardly giving up\n";
	return $self;
	}
    unless ($pv) {
	$mfc =~ m/^\s*(?:use|require)\s+v?(5[.0-9]+)/m and $pv = $1;
	}
    $pv =~ m/^5\.(\d+)\.(\d+)$/ and $pv = sprintf "5.%03d%03d", $1, $2;
    $pv =~ m/^5\.(\d{1,3})$/    and $pv = sprintf "5.%03d000",  $1;

    $release //= $nm =~ s{-}{::}gr;
    $release eq "." && $nm and $release = $nm =~ s{::}{-}gr;
    if (!$v && $vf and open $fh, "<", $vf) {
	warn "Trying to fetch VERSION from $vf ...\n" if $self->{verbose};
	while (<$fh>) {
	    m/\b VERSION \s* = \s* ["']? ([^;'"\s]+) /x or next;
	    $v = $1;
	    last;
	    }
	close $fh;
	}
    unless ($v) {
	$mfc =~ m/\$\s*VERSION\s*=\s*["']?(\S+?)['"]?\s*;/ and $v = $1;
	}
    unless ($v) {
	carp "Could not derive a VERSION from Makefile.PL\n";
	carp "Please tell me where I did wrong\n";
	carp "(ideally this should be done by a CORE module)\n";
	}
    $self->{mf} = { name => $nm, version => $v, release => $release, mpv => $pv };
    $self->{verbose} and warn "Analysing for $release-", $v // "?", $pv ? " for minimum perl $pv\n" : "\n";
    $self->{prereq}{$release}{v}{$v // "-"} = "current";
    $self;
    } # _read_MakefilePL

sub _read_cpanfile {
    my ($self, $cpf) = @_;
    $cpf ||= $self->{cpanfile};

    -s $cpf or return; # warn "No cpanfile. Scan something else (Makefile.PL, META.json, ...\n";
    $self->{verbose} and warn "Reading $cpf ...\n";
    open my $fh, "<", $cpf or croak "$cpf: $!\n";
    while (<$fh>) {
	my ($t, $m, $v) = m{ \b
	  ( requires | recommends | suggest ) \s+
	  ["'] (\S+) ['"]
	  (?: \s*(?:=>|,)\s* ["'] (\S+) ['"])?
	  }x or next;
	$m =~ s/::/-/g;
	$self->{prereq}{$m}{v}{$v // ""} = $t;
	$self->{prereq}{$m}{$t}          = $v;

	# Ingnore syntax in cpanfile:
	# require File::Temp, # ignore=CPANSA-File-Temp-2011-4116
	# require File::Temp, # ignore : CVE-2011-4116
	if (m/#.*\bignore\s*[=:]?\s*(\S+)/i) {
	    my $i = $1;
	    $self->{prereq}{$m}{i}{$i =~ s{["''"]+}{}gr}++;
	    }
	}
    push @{$self->{want}} => sort grep { $self->{j}{db}{$_} } keys %{$self->{prereq}};
    $self;
    } # _read_cpanfile

sub _read_META {
    my ($self, $mmf) = @_;
    $mmf ||= first { length && -s }
	$self->{meta_jsn}, "META.json",
	$self->{meta_yml}, "META.yml",
	"MYMETA.json", "MYMETA.yml";

    $mmf && -s $mmf or return;
    $self->{verbose} and warn "Reading $mmf ...\n";
    open my $fh, "<", $mmf or croak "$mmf: $!\n";
    local $/;
    my $j;
    if ($mmf =~ m/\.yml$/) {
	$self->{meta_yml} = $mmf;
	$j = YAML::PP::Load (<$fh>);
	$j->{prereqs} //= {
	    configure => {
		requires   => $j->{configure_requires},
		recommends => $j->{configure_recommends},
		suggests   => $j->{configure_suggests},
		},
	    build     => {
		requires   => $j->{build_requires},
		recommends => $j->{build_recommends},
		suggests   => $j->{build_suggests},
		},
	    test      => {
		requires   => $j->{test_requires},
		recommends => $j->{test_recommends},
		suggests   => $j->{test_suggests},
		},
	    runtime   => {
		requires   => $j->{requires},
		recommends => $j->{recommends},
		suggests   => $j->{suggests},
		},
	    };
	}
    else {
	$self->{meta_jsn} = $mmf;
	$j = decode_json (<$fh>);
	}
    close $fh;

    unless ($self->{mf}) {
	my $rls = $self->{mf}{release} = $j->{name} =~ s{::}{-}gr;
	my $vsn = $self->{mf}{version} = $j->{version};
	my $nm  = $self->{mf}{name}    = $j->{name} =~ s{-}{::}gr;
	$self->{prereq}{$rls}{v}{$vsn // "-"} = "current";
	}
    $self->{mf}{mpv} ||= $j->{prereqs}{runtime}{requires}{perl};

    my $pr = $j->{prereqs} or return $self;
    foreach my $p (qw( configure build test runtime )) {
	foreach my $t (qw( requires recommends suggests )) {
	    my $x = $pr->{$p}{$t} or next;
	    foreach my $m (keys %$x) {
		my $v = $x->{$m};
		$m =~ s/::/-/g;
		$self->{prereq}{$m}{v}{$v // ""} = $t;
		$self->{prereq}{$m}{$t}          = $v;
		}
	    }
	}
    push @{$self->{want}} => sort grep { $self->{j}{db}{$_} } keys %{$self->{prereq}};
    $self;
    } # _read_META

sub set_meta {
    my ($self, $m, $v) = @_;
    $self->{mf} = {
	name    => $m,
	release => $m =~ s{::}{-}gr,
	version => $v // "-",
	};
    $self;
    } # set_meta

sub want {
    my ($t, $self, $m, $v) = ("requires", @_);
    $m =~ s/::/-/g;
    unless (first { $_ eq $m } @{$self->{want}}) {
	$self->{prereq}{$m}{v}{$v // ""} = $t;
	$self->{prereq}{$m}{$t}          = $v;
	$self->{j}         or $self->_read_cpansa;
	$self->{j}{db}{$m} and push @{$self->{want}} => $m;
	}
    $self;
    } # want

sub test {
    my $self = shift;
    my $meta = 0;

    $self->{mf}      or $self->_read_MakefilePL;
    $self->{mf}      or $self->_read_META && $meta++;
    my $rel  = $self->{mf}{release} or return $self;
    $self->{verbose} and warn "Processing for $self->{mf}{release} ...\n";

    $self->{j}{mod}  or $self->_read_cpansa;
    @{$self->{want}} or $self->_read_cpanfile           if $self->{deps};
    @{$self->{want}} or $self->_read_META               if $self->{deps} && !$meta;
    @{$self->{want}} or $self->_read_META ("META.json") if $self->{deps};

    $self->{j}{db}{$rel} and unshift @{$self->{want}} => $rel;

    $self->{want} = [ uniq @{$self->{want}} ];

    my @w = @{$self->{want}} or return $self; # Nothing to report

    foreach my $m (@w) {
	$m eq "perl" && !$self->{perl} and next;

	my @mv = sort map { $_ || 0 } keys %{$self->{prereq}{$m}{v} || {}};
	if ($self->{core} and my $pv = $self->{mf}{mpv}
			  and "@mv" !~ m/[1-9]/) {
	    my $pmv = $Module::CoreList::version{$pv}{$m =~ s/-/::/gr} // "";
	    $pmv and @mv = ($pmv =~ s/\d\K_.*//r);
	    }
	$self->{verbose} and warn "$m: ", join (" / " => grep { $_ } @mv), "\n";
	my $cv = ($self->{minimum} ? $mv[0] : $mv[-1]) || 0; # Minimum or recommended
	$self->{CVE}{$m} = {
	    mod => $m,
	    vsn => $self->{prereq}{$m}{t},
	    min => $cv,
	    cve => [],
	    };

	#DDumper $self->{j}{db}{$m};
	foreach my $c (@{$self->{j}{db}{$m}}) {
	    # Ignored: references
	    my $cid = $c->{cpansa_id};
	    my $cds = $c->{cves} || $c->{cve} || [];
	    if (ref $cds ne "ARRAY") {
	       $cds =~ m/^{/ and $cds = decode_json ($cds);
	       use DP;die DDumper $cds;
	       }
	    my @cve = @$cds;
	       @cve = grep { !exists $self->{skip}{$_} } @cve;
	    my $dte = $c->{reported};
	    my $sev = $c->{severity};
	    my $dsc = $c->{description};
	    my @vsn = @{$c->{affected_versions} || []};
	    if (my $i = $self->{prereq}{$m}{i}) {
		my $p = join "|" => reverse sort keys %$i;
		my $m = join "#" => sort @cve, $cid;
		"#$m#" =~ m/$p/ and next;
		}
	    if (@vsn) {
		$self->{verbose} > 2 and warn "CMP<: $m-$cv\n";
		$self->{verbose} > 4 and warn "VSN : (@vsn)\n";
		# >=5.30.0,<5.34.3,>=5.36.0,<5.36.3,>=5.38.0,<5.38.2
		my $cmp = join " or " =>
		    map { s/\s*,\s*/") && XV /gr
		       =~ s/^/XV /r
		       =~ s/\s+=(?=[^=<>])\s*/ == /r	# = => ==
		       =~ s/\s*([=<>]+)\s*/$1 version->parse ("/gr
		       =~ s/$/")/r
		       =~ s/\bXV\b/version->parse ("$cv")/gr
		       =~ s/\)\K(?=\S)/ /gr
		       } @vsn;
		$self->{verbose} > 2 and warn "CMP>: $cmp\n";
		eval "$cmp ? 0 : 1" and next;
		$self->{verbose} > 3 and warn "TAKE!\n";
		}
	    else {
		warn "Oops: NO V or CVE?\n";
		use DP;DDumper $c->{cve};
		}
	    push @{$self->{CVE}{$m}{cve}} => {
		cid => $cid,
		dte => $dte,
		cve => [ @cve ],
		sev => $sev,
		av  => [ @vsn ],
		dsc => $dsc,
		};
	    #die DDumper { c => $c, cv => $cv, cve => $self->{CVE}{$m}, vsn => \@vsn };
	    }
	}
    $self;
    } # test

sub report {
    my $self = shift;

    $self->{j} or return;

    @_ % 2 and croak "Uneven number of arguments";
    my %args = @_;

    local $Text::Wrap::columns = ($args{width} || $self->{width}) - 4;

    my $n;
    foreach my $m (@{$self->{want}}) {
	my $C = $self->{CVE}{$m} or next;
	my @c = @{$C->{cve}}     or next;
	say "$m: ", $C->{min} // "-";
	foreach my $c (@c) {
	    my $cve = "@{$c->{cve}}" || $c->{cid};
	    printf "  %-10s %-12s %-12s %s\n",
		$c->{dte}, "@{$c->{av}}", $c->{sev} // "-", $cve;
	    print s/^/       /gmr for wrap ("", "", $c->{dsc});
	    $n++;
	    }
	}
    $n or say "There heve been no CVE detections in this process";
    } # report

sub cve {
    my $self = shift;

    $self->{j} or return;

    @_ % 2 and croak "Uneven number of arguments";
    my %args = @_;

    local $Text::Wrap::columns = $args{width} || $self->{width};

    my @cve;
    foreach my $m (@{$self->{want}}) {
	my $C = $self->{CVE}{$m} or next;
	my @c = @{$C->{cve}}     or next;
	push @cve => { release => $m, vsn => $C->{min}, cve => [ @c ] };
	}
    @cve;
    } # cve

sub has_no_cves {
    my %attr = @_;
    my $tb = __PACKAGE__->builder;

    # By default skip this test is not in a development env
    if (!exists $attr{author} and
	 ((caller)[1] =~ m{(?:^|/)xt/[^/]+\.t$} or
	  $ENV{AUTHOR_TESTING}                  or
	  -d ".git" && $^X =~ m{/perl$})) {
	$attr{author}++;
	}
    unless ($attr{author}) {
	$tb->ok (1, "CVE tests skipped: no author environment");
	return;
	}

    $attr{perl} //= 0;

    my $cve = Test::CVE->new (@_);
    $cve->test;
    my @cve = $cve->cve;
    if (@cve) {
	$tb->ok (0, "This release found open CVEs");
	foreach my $r (@cve) {
	    my ($m, $v) = ($r->{release}, $r->{vsn});
	    foreach my $c (@{$r->{cve}}) {
		my $cve = join ", "  => @{$c->{cve}};
		my $av  = join " & " => @{$c->{av}};
		$tb->diag (0, "$m-$v : $cve for $av");
		}
	    }
	}
    else {
	$tb->ok (1, "This release found no open CVEs");
	}
    } # has_no_cves

1;

__END__

=head1 INCENTIVE

On the Perl Toolchain Summit 2023, the CPAN Security Working Group (CPAN-SEC)
was established to receive and handle reports of undisclosed vulnerabilities
for CPAN releases and to assist the community in dealing with those.

The resources available enabled passive checks to existing releases and single
files against the database with known vulnerabilities.

The goal of this module is to be able to check if known vulnerabilities exist
before the release would be uploaded to CPAN.

The analysis is based on declarations and/or actual use and supports three
levels: C<requires>, C<recommends>, and C<suggests>. C<suggests> is unused in
giving advice.

The functionality explicitly limits to passive analysis: the is no active
scanning of source code to find security vulnerabilities.

=head1 DESCRIPTION

Test::CVE provides functionality to test a (CPAN)release or a single (perl)
script against known CVE's

It enables checking the current release only or include its prereqs too.

=head2 Functions and methods

=head3 new

 my $cve = Test::CVE->new (
    verbose  => 0,
    deps     => 1,
    minimum  => 0,
    cpansa   => "https://cpan-security.github.io/cpansa-feed/cpansa.json",
    make_pl  => "Makefile.PL",
    cpanfile => "cpanfile",
    want     => [],
    skip     => "CVE.SKIP",
    );

=head4 verbose

Set verbosity level. This will report what files are opened and read and what
modules are taken into account. Higher verbose will show more. Default = C<0>.

=head4 deps

Select if CVE's are also checked for direct dependencies. Default is true. If
false, just check the module or release itself.

=head4 perl

Select if CVE's on perl itself are included in the report. Default is true.

=head4 core

Replace unspecified versions of CORE modules with the version as shipped by
the required perl if known.

 require "ExtUtils::MakeMaker"; # no version specified

will set the required version to "6.66" when minimum perl is 5.18.1.

=head4 minimum

Report all CVE's regardless of what version is recommended in C<cpanfile> or
C<MYMETA.json>. By default only CVE's newer than the recommended version per
dependency are reported.

=head4 cpansa

Pass the URL of the CPANSA database. The alternative is to pass the filename
of a stored version of that database.

=head4 make_pl

Pass an alternative location of C<Makefile.PL>. Default is the one in the
current directory.

In version C<0.01> C<Build.PL> is not yet supported.

=head4 cpanfile

Pass an alternative location for C<cpanfile>. Very useful when testing.

=head4 want

A list of extra prereqs. When you know in advance, pass the list in this
attribute. You can also add them to the object with the method later. This
attribute does not support versions, the method does.

=head4 skip

An optional specification of CVE's to skip/ignore. See L</skip>.

=head3 require

 my $cve = Test::CVE->new ();
 $cve->require ("Foo::Bar");
 $cve->require ("Baz-Fumble", "4.321");

Add a dependency to the list. Only adds the dependency if known CVE's exist.

=head3 set_meta

 $cve->set_meta ("Fooble.pl");
 $cve->set_meta ("script.pl", "0.01");

Force set distribution information, preventing reading C<Makefile.PL> and/or
C<cpanfile>.

=head3 skip
X<skip>

 my @skip = $cve->skip;
 $cve->skip (undef);
 $cve->skip ("CVE.SKIP");
 $cve->skip ("CVE-2011-0123", "CVE-2022-1234");
 $cve->skip ([qw( CVE-2011-0123 CVE-2020-1234 )]);
 $cve->skip ({ "CVE-2013-2222" => "We do not use this" });

By default all CVE's listed in file C<CVE.SKIP> will be ignored in the reports.

When no argument is given, the current list of ignored CVE's is returned as
an array-ref.

When the only argument is the name of a readable file, the file is expected to
have one tag per line of a CVE to be ignored, optionally followed by space and
a reason:

  CVE-2011-0123   We are not using this feature
  CVE-2020-1234

When the only argument is an array-ref, all entries are ignored.

When the only argument is a hash-ref, all keys are ignored.

Otherwise, all arguments are ignored.

Future extensions might read L<VEX|https://github.com/openvex/spec>
specifications (too).

=head3 test

Execute the test. Files are read as needed.

=head3 report

Report the test-results in plain text. This method prints the CVE's. If you
want the results for further analysis, use C<cve>.

=head3 cve

Return a list of found CVE's per release. The format will be somewhat like

 [ { release => "Some-Module",
     vsn     => "0.45",
     cve     => [
       { av  => [ "<1.23" ],
         cid => "CPANSA-Some-Module-2023-01",
         cve => [ "CVE-2023-1234" ],
         dsc => "Removes all files in /tmp",
         dte => "2023-01-02",
         sev => "critical",
         },
       ...
       ],
     },
   ...
   ]

=head4 release

The name of the release

=head4 vsn

The version that was checked

=head4 cve

The list of found CVE's for this release that match the criteria

=over 2

=item av

All affected versions of the release

=item cid

The ID from the CPANSA database

=item cve

The list of CVE tags for this item. This list can be empty.

=item dsc

Description of the vulnerability

=item dte

Date for this CVE

=item sev

Severity. Most entries doe not have a severity

=back

=head3 has_no_cves

Note upfront: You most likely do B<NOT> want this in a test-suite, as
making the test suite C<FAIL> on something the end-user is incapable
of fixing might not be a friendly approach.

 use Test::More;
 use Test::CVE;

 has_no_cves ();
 done_testing;

Will return C<ok> is no open CVE's are detected for the current build
environment.

C<has_no_cves> will accept all arguments that C<new> accepts plus one
additional: C<author>. The C<perl> attribute defaults to C<0>.

 has_no_cves (@args);

is more or less the same as

 my @cve = Test::CVE->new (@args)->test->cve;
 ok (@cve == 0, "This release found no open CVEs");
 diag ("...") for map { ... } @cve;

By default, C<has_no_cves> will only run in a development environment,
but you can control that with the C<author> attribute. When not passed,
it will default to C<1> if either the test unit is run from the C<xt/>
folder or if filder C<.git> exists and the invoking perl has no version
extension in its name, or if C<AUTHOR_TESTING> has a true value.

=head1 TODO and IDEAS

=over 2

=item

Support L<SLSA|https://slsa.dev/spec/v0.1/> documents

=item

Support L<VEX|https://github.com/openvex/spec> documents

=back

=head1 AUTHOR

H.Merijn Brand F<E<lt>hmbrand@cpan.orgE<gt>>

=head1 SEE ALSO

L<Net::CVE>, L<Net::NVD>, L<Net::OSV>

=head1 COPYRIGHT AND LICENSE

 Copyright (C) 2023-2026 H.Merijn Brand.  All rights reserved.

This library is free software;  you can redistribute and/or modify it under
the same terms as Perl itself.

=cut

=for elvis
:ex:se gw=75|color guide #ff0000:

=cut
