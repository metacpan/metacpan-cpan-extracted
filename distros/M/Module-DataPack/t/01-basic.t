#!perl

use strict;
use warnings;
use Test::More 0.98;

use File::Temp qw(tempdir tempfile);
use Module::DataPack qw(datapack_modules);

my $dir = tempdir(CLEANUP => !$ENV{DEBUG});

sub test_datapack {
    my %args = @_;
    subtest $args{name} => sub {
        my $res = datapack_modules(@{ $args{input_args} });
        my $result_status = $args{result_status} // 200;
        is($res->[0], $result_status, "status");

        return unless $res->[0] == 200;

        my ($tempfh, $tempfilename) = tempfile();
        print $tempfh $res->[2];
        close $tempfh;

        system $^X, "-c", $tempfilename;
        ok($? == 0, "code compiles");

        if ($args{posttest}) {
            ok($args{posttest}->($res), "posttest succeeds");
        }
    };
}

test_datapack(
    name => "sanity",
    input_args => [module_names => ["strict", "warnings"]],
    posttest => sub {
        my $res = shift;
        print $res->[2];
        $res->[2] =~ m!^### strict\.pm ###!m or die "strict.pm not included";
        $res->[2] =~ m!^### warnings\.pm ###!m or die "warnings.pm not included";
        1;
    },
);

done_testing;
