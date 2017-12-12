package _common;

# common parts for Struct::Path tests

use strict;
use warnings FATAL => 'all';
use parent qw(Exporter);

use Clone qw(clone);
use Data::Dumper qw();
use Struct::Diff qw(diff patch valid_diff);
use Test::More;

our @EXPORT = qw(
    run_batch_tests
    scmp
    sdump
);

my $EXP_KEYS;
if ($ENV{EXPORT_TESTS_DIR}) {

    $ENV{EXPORT_TESTS_DIR} =~ /(.*)/;
    $ENV{EXPORT_TESTS_DIR} = $1; # untaint

    $EXP_KEYS = { map { $_ => 1 } qw(a b diff opts) };

    require JSON;
}

sub run_batch_tests {
    local $Test::Builder::Level = $Test::Builder::Level + 1;

    for my $t (@_) {

        # export tests to JSON
        if ($EXP_KEYS and (!exists $t->{to_json} or $t->{to_json})) {
            die "Export dir doesn't exist" unless (-d $ENV{EXPORT_TESTS_DIR});

            my $data = clone($t);
            map { delete $data->{$_} unless ($EXP_KEYS->{$_}) } keys %{$data};

            my $file = "$ENV{EXPORT_TESTS_DIR}/$t->{name}.json";
            open(my $fh, '>', $file) or die "Failed to open file '$file' ($!)";
            print $fh JSON->new->pretty(1)->canonical(1)->encode($data);
            close($fh);
        }

        ### diff
        my $st = clone($t);
        my $diff = eval { diff($st->{a}, $st->{b}, %{$st->{opts}}) };
        if ($@) {
            fail("Diff: $@");
            fail("Patch: doesn't run");
            fail("Valid: doesn't run");
            next;
        }

        subtest "Diff " . $t->{name} => sub {
            is_deeply($diff, $st->{diff}, "Diff: $st->{name}") ||
                diag scmp($diff, $st->{diff});

            is_deeply($st->{a}, $t->{a}, "A mangled: $st->{name}") ||
                diag scmp($st->{a}, $t->{a});
            is_deeply($st->{b}, $t->{b}, "B mangled: $st->{name}") ||
                diag scmp($st->{b}, $t->{b});
        };

        ### patch
        if (
            !$t->{skip_patch}
            and not (
                $t->{opts}->{noA}
                or $t->{opts}->{noR}
                or $t->{opts}->{noN}
            )
        ) {
            my $st = clone($t);
            # diff contain parts of original structures and will be mangled if
            # it has refref,scalarrefs etc from a and a patched
            $st->{a} = clone($t->{a}); # get rid of common refs with diff

            patch($st->{a}, $st->{diff});

            subtest "Patch " . $st->{name} => sub {
                is_deeply($st->{a}, $st->{b}, "Patch: $st->{name}") ||
                    diag scmp($st->{a}, $st->{b});

                is_deeply($t->{diff}, $st->{diff}, "Patch: diff mangled: $st->{name}") ||
                    diag scmp($t->{diff}, $st->{diff});
            };
        } else {
            pass("patch skipped");
        }

        ### valid_diff
        $diff = clone($t->{diff});

        subtest "Valid " . $t->{name} => sub {
            ok(valid_diff($diff));

            is_deeply($diff, $t->{diff}, "Valid: diff mangled: $t->{name}") ||
                diag scmp($diff, $t->{diff});
        };
    }
}

sub scmp($$) {
    return "GOT: " . sdump(shift) . ";\nEXP: " . sdump(shift) . ";";
}

sub sdump($) {
    return Data::Dumper->new([shift])->Terse(1)->Sortkeys(1)->Quotekeys(0)->Indent(0)->Deepcopy(1)->Dump();
}

1;

