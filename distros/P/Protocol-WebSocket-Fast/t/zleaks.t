use 5.012;
use strict;
use warnings;
use Test::Builder;
use Test::More;

plan skip_all => 'set WITH_LEAKS=1 to enable leaks test' unless $ENV{WITH_LEAKS};
plan skip_all => 'BSD::Resource and Path::Tiny required to test for leaks' unless eval {
    require BSD::Resource;
    require Path::Tiny;
    Path::Tiny->import;
    1;
};

my %exclude = map {$_ => 1} qw/zleaks.t bug-SRV-1608.t/;
my @files;

if ($ENV{LEAK_FILE}) { push @files, $ENV{LEAK_FILE}; }
else { @files = grep { !$exclude{$_} } map { substr($_, 2) } <t/*.t>; }

test_leak(1, [@files], 200);

# $leak_threshold in Kb
sub test_leak {
    my ($time, $tests, $leak_threshold) = @_;
    $leak_threshold ||= 100;

    my @test_code = map {
        my $filename = $_;
        sub {
            my $content = path("t/$filename")->slurp;
            my $code = "return sub { $content; };";
            my $sub = eval $code;

        };
    } (@$tests);

    my $run_all = sub { $_->() for @$tests };

    my @a = 1..100; undef @a; # warmup perl
    my $tests_leaked = 0;
    {
        no warnings;
        local *ok = sub($;$) {};
        local *is = sub($$;$) {};
        local *isnt = sub($$;$) {};
        local *diag = sub {};
        local *like = sub($$;$) {};
        local *unlike = sub($$;$) {};
        local *cmp_ok = sub($$$;$) {};
        local *is_deeply = sub {};
        local *can_ok = sub($@) {};
        local *isa_ok = sub($$;$) {};
        local *pass = sub(;$) {};
        local *fail = sub(;$) {};
        local *plan = sub {};
        local *note = sub {};
        local *cmp_deeply = sub {};
        local *cmp_bag = sub {};
        local *cmp_set = sub {};
        local *cmp_methods = sub {};
        local *done_testing = sub {1};
        local *subtest = sub { my $name = shift; my $code = shift; $code->(@_) };
        local $main::leak_test = 1;
        use warnings;

        print "Warming up\n";
        for (0 .. 15) {
            for my $code (@test_code) {
                $code->();
            }
        }

        for my $idx (0 .. @test_code - 1) {
            my $run = $test_code[$idx];
            my $filename = $tests->[$idx];
            print("Checking $filename rss = ", BSD::Resource::getrusage()->{"maxrss"}, "\n");
            my $leak  = 0;

            my $measure = BSD::Resource::getrusage()->{"maxrss"};
            $run->() for (0 .. 2000);
            $leak = BSD::Resource::getrusage()->{"maxrss"} - $measure;

            my $leak_ok = $leak < $leak_threshold;
            print("LEAK DETECTED: ${leak}Kb in $filename\n") unless $leak_ok;
        }
    }

    is $tests_leaked, 0, "leak test";
}

done_testing;
