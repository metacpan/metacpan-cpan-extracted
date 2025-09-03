# xt/101-examine-all-commits.t
use 5.014;
use warnings;
use Perl5::TestEachCommit;
use Carp;
use File::Temp qw(tempfile tempdir);
use File::Spec::Functions;
use String::PerlIdentifier qw(make_varname);
use Data::Dump qw(dd pp);
use Capture::Tiny qw(capture_stdout);

use Test::More;
if( (! defined $ENV{SECONDARY_CHECKOUT_DIR}) or
    (! -d $ENV{SECONDARY_CHECKOUT_DIR} )
){
    plan skip_all => 'Could not locate git checkout of Perl core distribution';
}
elsif (! $ENV{PERL_AUTHOR_TESTING}) {
    plan skip_all => 'Lengthy test; set PERL_AUTHOR_TESTING to run';
}
else {
    #plan tests => 13;
    plan 'no_plan';
}

# NOTE:  The tests in this file depend on having a git checkout of the Perl
# core distribution on disk.  We'll skip all if that is not the case.  If that
# is the case, then set the path to that checkout in the envvar
# SECONDARY_CHECKOUT_DIR; example:
#
#   export SECONDARY_CHECKOUT_DIR=/home/username/gitwork/perl2
#
# Perl5::TestEachCommit will detect that and default to it for 'workdir' --
# which is why we'll be able to omit it from calls to new() in this file.

my $opts = {
    #workdir => "/tmp",
    branch  => "blead",
    start   => "6d9606cf5cade91df0996344403ffa16e1a28a37",
    #end     => "b83d816f227db2e54e52dec41b1a3dc6bd421b59", # last code-change
    end     => "4bb3572f7a1c1f3944b7f58b22b6e7a9ef5faba6", # merge commit
    configure_command => "sh ./Configure -des -Dusedevel 1>/dev/null",
    make_test_prep_command => "make test_prep 1>/dev/null",
    make_test_harness_command => "make test_harness 1>/dev/null",
    skip_test_harness => 1,
    verbose => 1,
};

{
    my $self = Perl5::TestEachCommit->new( $opts );
    ok($self, "new() returned true value");
    isa_ok($self, 'Perl5::TestEachCommit',
        "object is a Perl5::TestEachCommit object");

    note("Testing prepare_repository() ...");

    my $rv = $self->prepare_repository();
    ok($rv, "prepare_repository() returned true value");

    note("Testing get_commits() and display_commits() ...");

    my $expected_commits = [
        "6d9606cf5cade91df0996344403ffa16e1a28a37",
        "7919ad182e9f8e2ebc9192607743099a55e03494",
        "82c582d736e21b19b284c8dc0a1a979d8da6c8a4",
        "c32a4b2306f7f5f69c505a0a8f9be7647e3f9820",
        "243b0105c720ae7cc6731ebf6d494b0b2e07df39",
        "0a5b2f9e89b61a0d6b62b758eaab9ebdfc459554",
        "9ce1e262edae2573b2795d05363cff89dd4c9a31",
        "9df4e3cb2246486cd72f943959fcbc88fcf8cf06",
        "d01be31c11a8dc8c0c78dcef1c916eaf954ae1a2",
        "56217f63c0b747bbb2997c46d66dc38b83266e3e",
        "65e48665decb07b949cac8dcc46b18c9835d50c4",
        "bcc5c2605454a6bfd4db32769009279c07b8774c",
        "d28a346196170e1c4a003a9b0f71a68fff5c20ec",
        "404f22b25fb83c4e26c9d33f44e4bb1470be3483",
        "24736e0af0d62c9a318eb53b604c313faaed836e",
        "b8a7b5f5518efed859c3609ee53714844d709888",
        "7ab6f4b665bd86732817aec03c69402e7bf45002",
        "038b07830647f41ef13ad3139edc8046042feb08",
        "29812906458c57eb18a0852b8c3f1714ac5dbfd6",
        "1da5249c65f18140f23ac16eb271ef9299a2b74e",
        "9d2aa8819e45aad0955924b4c41108cbf4909079",
        "5c4ff6da9ece62555de684c3cd1fdda6698b6f86",
        "9114019b835a829ec2c986a3bdbd23ab9fa94741",
        "9e08ae35a0ee37d2dd015a9ebda1146baf768372",
        "162b9705323b94b2cde445daed7ea8d0b6a4ec44",
        "03875508c8ad610c97f370b1816540a1d43f65e5",
        "1176a99221d93e66c12ff61550a06f89bd6d100b",
        "e830b1872da0bd40479506297930fb0e82f26566",
        "54bfca47b2e7ea689708a1ce55cfceabeda8631f",
        "8decb8ab1aa0aa96ffbe39a21a2e85cf85ca074f",
        "ab82f76c886d163546dd213aa856a00e45445765",
        "8683dc71d65133274921dc10c9e043745a10e9dd",
        "b5c8ae42ab1606d6fad79493f2a0249f32262965",
        "c98aea033fcb1b10b634f48754f96de2e79fa06e",
        "7e6a9a61286b6d87d110918f0d83a3442a582595",
        "593796fa96d3e5caf189c126e7df1a0bd698fbea",
        "8e102f9ac37d0822e421b3ab22fffd5bfd7333b6",
        "8bdb0ad55c8cda750a93e5c3b41ddc48b2a4bd46",
        "5bda2037dea66b5b5ae2bb8f6be78b6f73e57f85",
        "68aa463e1f27969910b15e3ec41a53525946ad72",
        "d6909d9413acaf96a85e76c052bfa5b3a971ab26",
        "309431c01c315bbbfa21871fb72161b7fa879827",
        "f5f6a1be9e909baeb14de0cc8ae285c93ae89d17",
        "f79fa08ae1d254700b28275912f1392442e49ba2",
        "a2f5678d13c1b294c38914f85a19e1826e319e3d",
        "8efe6a1425edb4855a684bb8d8b56486e64c5d25",
        "81e1cbe3703c362b4ef4918defc0ed7deac64fa6",
        "eb3ee9300b057b2f674a0246887e34bdf0312d81",
        "9f11f6a0387e45f7e3b5a4ade4d87a2aa04009b5",
        "ffc38ee7619e08ecabc73dfda96e6e60733e0496",
        "8b91a7e5f4bf15aa4f471956b37f91326b211a23",
        "8de60a95d1df7c031611de5596e678f6babcadc0",
        "d8012228a9a8e4a24da40e34734b624d8f96efe2",
        "3036e19d2e031c72cca24fbf1b6a8a1e16bf960f",
        "0941b0bfd8de7775036b127c7be86ce808cf6f69",
        "ecb84c67427f7937724c09eb15ebc9a7c46bda07",
        "56cd1525804c9a10680a9c3b77d11586cc8cca93",
        "6f3004a19f421536eb373b17dd7eb2863e3f9f68",
        "6110375a5c9c28eba9fb19160f3bed960be26313",
        "c29bd9dba8e814f1c8e655beb8aa46a174c926fa",
        "bbff8b0451726b8d5c345ffb34d5db008a08243c",
        "5d431c16150e37845e2573db29bcd18dcdfa9ce0",
        "f4b54a726efb04f9e18c7c881b9ef2dc5ce89cdc",
        "a4914f4332a429ddebaf08ab2b32f4468c41930d",
        "010f51859d15884b0eacf47125534931417879a1",
        "8d89da23f0c8a971342b7e6f21532c4ec92e52eb",
        "1e16a460aa928cf42fd0e1ad2c51a4ae57a73671",
        "94c6f2fa8fd65fd916def0b0daf2369e61574c94",
        "1acc01625cbf7b2670924a963ae24b05b69db2ed",
        "4ece6ca0100919e76d7039881a424e480ca550d9",
        "cfb8d7473c7e00ca63418610873f286dba57f318",
        "c38aee12c4ac671ca6437d2e4f1f8b936c74f648",
        "da6d27d677059c2e958bcc50895181f90cf7135d",
        "50db88c496cdd20222e3fc0b2e4abf08f61f00d6",
        "f62d33ab1b0557660ec974e2bc8d6d40e694b4bd",
        "865fc0687b0cdc343d521e44ae623f7697ba3fe0",
        "4b3bbd2f03d7eadb8a857fd2308d27c69150c784",
        "fd80f1018126ba8398201d9b948a4fc4ee0c5689",
        "a7af307ab1c26cc067f88febcc3d5f9daac49a91",
        "78b45d7a4b8ce7d552659243fdb221c536c3ebe8",
        "e2571e7ecb626f557ba38647af63bab728e3e677",
        "515c3f68c7c0bfea2b0b05a40b27883b13135b47",
        "10d0ff9b217d5270737e6d06045175bb15cb7243",
        "eab042fc555e477baaafa5a6fe562416312e2e39",
        "6d87775486e9dcde1377c56351ae3149042c504a",
        "b55f1e9325bd6f00c4a9e29a235586e51cc50d39",
        "b83d816f227db2e54e52dec41b1a3dc6bd421b59",
        "4bb3572f7a1c1f3944b7f58b22b6e7a9ef5faba6",
    ];

    my $commits = $self->get_commits();
    is_deeply($commits, $expected_commits,
        "Got expected list of SHAs");

    my $stdout = capture_stdout {
        $rv = $self->display_commits();
    };
    ok($rv, "display_commits() returned true value");
    my @lines = split /\n/, $stdout;
    my @got_lines = ();
    for my $l (@lines) {
        push @got_lines, $l;
    }
    is_deeply([@got_lines], $expected_commits,
        "Displayed list of commits as expected");

    $self->examine_all_commits();
    my $results_ref = $self->get_results();
    pp $results_ref;
#    is(ref($results_ref), 'ARRAY', "get_results() returned array ref");
#    is_deeply($results_ref, $expected_results,
#        "examine_all_commits() gave expected results");
#
#    $stdout = capture_stdout {
#        $rv = $self->display_results();
#    };
#    ok($rv, "display_results() returned true value");
#    my @theselines = split /\n/, $stdout;
#    like($theselines[0], qr/^.*? commit .*? score/x,
#        "Got expected header from display_results");
#    for my $datum (@theselines[2..$#theselines]) {
#        like($datum, qr/^[a-f0-9]{40}\s\|\s{3}[0-3]/,
#            "Got expected data from display_results");
#    }
}

__END__

# 88 commits, each of which configured and built correctly (score => 2)
# skip_test_harness ON so make_test_harness not executed

my $results_ref = $self->get_results();

[
  { commit => "6d9606cf5cade91df0996344403ffa16e1a28a37", score => 2 },
  { commit => "7919ad182e9f8e2ebc9192607743099a55e03494", score => 2 },
  { commit => "82c582d736e21b19b284c8dc0a1a979d8da6c8a4", score => 2 },
  { commit => "c32a4b2306f7f5f69c505a0a8f9be7647e3f9820", score => 2 },
  { commit => "243b0105c720ae7cc6731ebf6d494b0b2e07df39", score => 2 },
  { commit => "0a5b2f9e89b61a0d6b62b758eaab9ebdfc459554", score => 2 },
  { commit => "9ce1e262edae2573b2795d05363cff89dd4c9a31", score => 2 },
  { commit => "9df4e3cb2246486cd72f943959fcbc88fcf8cf06", score => 2 },
  { commit => "d01be31c11a8dc8c0c78dcef1c916eaf954ae1a2", score => 2 },
  { commit => "56217f63c0b747bbb2997c46d66dc38b83266e3e", score => 2 },
  { commit => "65e48665decb07b949cac8dcc46b18c9835d50c4", score => 2 },
  { commit => "bcc5c2605454a6bfd4db32769009279c07b8774c", score => 2 },
  { commit => "d28a346196170e1c4a003a9b0f71a68fff5c20ec", score => 2 },
  { commit => "404f22b25fb83c4e26c9d33f44e4bb1470be3483", score => 2 },
  { commit => "24736e0af0d62c9a318eb53b604c313faaed836e", score => 2 },
  { commit => "b8a7b5f5518efed859c3609ee53714844d709888", score => 2 },
  { commit => "7ab6f4b665bd86732817aec03c69402e7bf45002", score => 2 },
  { commit => "038b07830647f41ef13ad3139edc8046042feb08", score => 2 },
  { commit => "29812906458c57eb18a0852b8c3f1714ac5dbfd6", score => 2 },
  { commit => "1da5249c65f18140f23ac16eb271ef9299a2b74e", score => 2 },
  { commit => "9d2aa8819e45aad0955924b4c41108cbf4909079", score => 2 },
  { commit => "5c4ff6da9ece62555de684c3cd1fdda6698b6f86", score => 2 },
  { commit => "9114019b835a829ec2c986a3bdbd23ab9fa94741", score => 2 },
  { commit => "9e08ae35a0ee37d2dd015a9ebda1146baf768372", score => 2 },
  { commit => "162b9705323b94b2cde445daed7ea8d0b6a4ec44", score => 2 },
  { commit => "03875508c8ad610c97f370b1816540a1d43f65e5", score => 2 },
  { commit => "1176a99221d93e66c12ff61550a06f89bd6d100b", score => 2 },
  { commit => "e830b1872da0bd40479506297930fb0e82f26566", score => 2 },
  { commit => "54bfca47b2e7ea689708a1ce55cfceabeda8631f", score => 2 },
  { commit => "8decb8ab1aa0aa96ffbe39a21a2e85cf85ca074f", score => 2 },
  { commit => "ab82f76c886d163546dd213aa856a00e45445765", score => 2 },
  { commit => "8683dc71d65133274921dc10c9e043745a10e9dd", score => 2 },
  { commit => "b5c8ae42ab1606d6fad79493f2a0249f32262965", score => 2 },
  { commit => "c98aea033fcb1b10b634f48754f96de2e79fa06e", score => 2 },
  { commit => "7e6a9a61286b6d87d110918f0d83a3442a582595", score => 2 },
  { commit => "593796fa96d3e5caf189c126e7df1a0bd698fbea", score => 2 },
  { commit => "8e102f9ac37d0822e421b3ab22fffd5bfd7333b6", score => 2 },
  { commit => "8bdb0ad55c8cda750a93e5c3b41ddc48b2a4bd46", score => 2 },
  { commit => "5bda2037dea66b5b5ae2bb8f6be78b6f73e57f85", score => 2 },
  { commit => "68aa463e1f27969910b15e3ec41a53525946ad72", score => 2 },
  { commit => "d6909d9413acaf96a85e76c052bfa5b3a971ab26", score => 2 },
  { commit => "309431c01c315bbbfa21871fb72161b7fa879827", score => 2 },
  { commit => "f5f6a1be9e909baeb14de0cc8ae285c93ae89d17", score => 2 },
  { commit => "f79fa08ae1d254700b28275912f1392442e49ba2", score => 2 },
  { commit => "a2f5678d13c1b294c38914f85a19e1826e319e3d", score => 2 },
  { commit => "8efe6a1425edb4855a684bb8d8b56486e64c5d25", score => 2 },
  { commit => "81e1cbe3703c362b4ef4918defc0ed7deac64fa6", score => 2 },
  { commit => "eb3ee9300b057b2f674a0246887e34bdf0312d81", score => 2 },
  { commit => "9f11f6a0387e45f7e3b5a4ade4d87a2aa04009b5", score => 2 },
  { commit => "ffc38ee7619e08ecabc73dfda96e6e60733e0496", score => 2 },
  { commit => "8b91a7e5f4bf15aa4f471956b37f91326b211a23", score => 2 },
  { commit => "8de60a95d1df7c031611de5596e678f6babcadc0", score => 2 },
  { commit => "d8012228a9a8e4a24da40e34734b624d8f96efe2", score => 2 },
  { commit => "3036e19d2e031c72cca24fbf1b6a8a1e16bf960f", score => 2 },
  { commit => "0941b0bfd8de7775036b127c7be86ce808cf6f69", score => 2 },
  { commit => "ecb84c67427f7937724c09eb15ebc9a7c46bda07", score => 2 },
  { commit => "56cd1525804c9a10680a9c3b77d11586cc8cca93", score => 2 },
  { commit => "6f3004a19f421536eb373b17dd7eb2863e3f9f68", score => 2 },
  { commit => "6110375a5c9c28eba9fb19160f3bed960be26313", score => 2 },
  { commit => "c29bd9dba8e814f1c8e655beb8aa46a174c926fa", score => 2 },
  { commit => "bbff8b0451726b8d5c345ffb34d5db008a08243c", score => 2 },
  { commit => "5d431c16150e37845e2573db29bcd18dcdfa9ce0", score => 2 },
  { commit => "f4b54a726efb04f9e18c7c881b9ef2dc5ce89cdc", score => 2 },
  { commit => "a4914f4332a429ddebaf08ab2b32f4468c41930d", score => 2 },
  { commit => "010f51859d15884b0eacf47125534931417879a1", score => 2 },
  { commit => "8d89da23f0c8a971342b7e6f21532c4ec92e52eb", score => 2 },
  { commit => "1e16a460aa928cf42fd0e1ad2c51a4ae57a73671", score => 2 },
  { commit => "94c6f2fa8fd65fd916def0b0daf2369e61574c94", score => 2 },
  { commit => "1acc01625cbf7b2670924a963ae24b05b69db2ed", score => 2 },
  { commit => "4ece6ca0100919e76d7039881a424e480ca550d9", score => 2 },
  { commit => "cfb8d7473c7e00ca63418610873f286dba57f318", score => 2 },
  { commit => "c38aee12c4ac671ca6437d2e4f1f8b936c74f648", score => 2 },
  { commit => "da6d27d677059c2e958bcc50895181f90cf7135d", score => 2 },
  { commit => "50db88c496cdd20222e3fc0b2e4abf08f61f00d6", score => 2 },
  { commit => "f62d33ab1b0557660ec974e2bc8d6d40e694b4bd", score => 2 },
  { commit => "865fc0687b0cdc343d521e44ae623f7697ba3fe0", score => 2 },
  { commit => "4b3bbd2f03d7eadb8a857fd2308d27c69150c784", score => 2 },
  { commit => "fd80f1018126ba8398201d9b948a4fc4ee0c5689", score => 2 },
  { commit => "a7af307ab1c26cc067f88febcc3d5f9daac49a91", score => 2 },
  { commit => "78b45d7a4b8ce7d552659243fdb221c536c3ebe8", score => 2 },
  { commit => "e2571e7ecb626f557ba38647af63bab728e3e677", score => 2 },
  { commit => "515c3f68c7c0bfea2b0b05a40b27883b13135b47", score => 2 },
  { commit => "10d0ff9b217d5270737e6d06045175bb15cb7243", score => 2 },
  { commit => "eab042fc555e477baaafa5a6fe562416312e2e39", score => 2 },
  { commit => "6d87775486e9dcde1377c56351ae3149042c504a", score => 2 },
  { commit => "b55f1e9325bd6f00c4a9e29a235586e51cc50d39", score => 2 },
  { commit => "b83d816f227db2e54e52dec41b1a3dc6bd421b59", score => 2 },
  { commit => "4bb3572f7a1c1f3944b7f58b22b6e7a9ef5faba6", score => 2 },
]
