package Utils;

use strict;
use warnings;
use vars qw( $VERSION @ISA @EXPORT );
require Exporter;
use Module::ScanDeps qw(path_to_inc_name);

use Test::More;

@ISA=qw(Exporter);
$VERSION   = '0.1';
@EXPORT = qw( generic_scandeps_rv_test compare_scandeps_rvs generic_abs_path );

my $test = Test::More->builder;

sub import {
    my($self) = shift;
    my $pack = caller;

    $test->exported_to($pack);
    $self->export_to_level(1, $self, @EXPORT);
}

sub generic_scandeps_rv_test {
    my $rv = shift;
    my $array_ref = shift;
    my @input_keys = sort @$array_ref;
       $array_ref = shift;
    my @known_deps = sort @$array_ref;
    my @used_by;
    my ($used_by_ok, $i);

    # sanity check input
    foreach my $input (@input_keys) {
      !(grep {$_ eq $input} @known_deps) or die "\@input_keys overlaps with \@known_deps\n";
    }

    $test->ok(ref($rv) eq "HASH", "\$rv is a ref") or return;

    # check all input files and known deps correspond to an entry in rv
    map {$_ = path_to_inc_name($_, 1)} @input_keys;
    map {$_ =~ s|\\|\/|go} (@input_keys, @known_deps);
    $test->ok(exists $rv->{$_}, "$_ is in rv") foreach (@input_keys, @known_deps);

    # Check general properties of the keys
    foreach my $key (keys %$rv) {
        $test->ok(exists($rv->{$key}{key})  && $key eq $rv->{$key}{key}, "For $key: the sub-key matches");
        $test->ok(exists($rv->{$key}{file}) && $rv->{$key}{file} =~ /(?:^|[\/\\])\Q$key\E$/
                                            && File::Spec->file_name_is_absolute($rv->{$key}{file}), "For $key: the file has been verified");
        $test->ok(exists($rv->{$key}{type}) && $rv->{$key}{type} =~ /^(?:module|autoload|data|shared)$/, "For $key: the type matches module|autoload|data|shared");

        if (exists($rv->{$key}{used_by})) {
            @used_by = sort @{$rv->{$key}{used_by}};
            if (scalar @used_by > 0) {
                $used_by_ok = 1;
                if (scalar @used_by > 1) {
                    for ($i=0; $i<$#used_by; $i++) {
                        if ($used_by[$i] eq $used_by[$i+1]) { # relies on @used_by being sorted earlier
                             $used_by_ok = 0;
                             last;
                        }
                    }
                }
                $test->ok($used_by_ok, "$key\'s used_by has no duplicates");

                $used_by_ok = 1;
                foreach my $used_by (@used_by) {
                    $used_by_ok &= exists($rv->{$used_by});
                }
                $test->ok($used_by_ok, "All entries in $key\'s used_by are themselves described in \$rv");

                # check corresponding uses field
                foreach my $used_by (@used_by) {
                    if (exists($rv->{$used_by}{uses})) {
                        $test->ok(scalar(grep { $_ eq $key } @{$rv->{$used_by}{uses}}), "\$rv contains a matching uses field for the used_by entry $used_by for key $key");
                    } else {
                        $test->ok(0, "\$rv contains a matching uses field for the used_by entry $used_by for key $key");
                    }
                }
            } else {
                $test->ok(0, "$key\'s used_by exists and isn't empty");
            }
        } else {
            $test->ok((grep {$_ eq $key} @input_keys) | ($key =~ m/Plugin/o), "used-by not defined so $key must be one of the input files or is a plugin");
        }

        if (exists($rv->{$key}{uses})) {
            # check corresponding used_by field
            foreach my $uses (@{$rv->{$key}{uses}}) {
                if (exists($rv->{$uses}{used_by})) {
                    $test->ok(scalar(grep { $_ eq $key } @{$rv->{$uses}{used_by}}), "\$rv contains a matching used_by field for the uses entry $uses for key $key");
                } else {
                    $test->ok(0, "\$rv contains a matching used_by field for the uses entry $uses for key $key");
                }
            }
         }
    }
}

sub compare_scandeps_rvs {
    my $rv_to_test = shift;
    my $rv_to_match = shift;
    my $array_ref = shift;
    my @input_keys = @$array_ref;

    my (@used_by_test, @used_by_match);
    my (@uses_test, @uses_match);
    my ($used_by_ok, $uses_ok);
    my ($compare_ok, $i);

    generic_scandeps_rv_test($rv_to_match, \@input_keys, []); # validate test data

    $test->ok(ref($rv_to_test) eq "HASH", "\$rv_to_test is a ref") or return;

    my @rv_to_match_keys = sort keys %{$rv_to_match};
    my @rv_to_test_keys  = sort keys %{$rv_to_test};
    $test->cmp_ok(scalar @rv_to_test_keys, '==', scalar @rv_to_match_keys, "Number of keys in \$rv_to_test == Number of keys in \$rv_to_match") or return;
    $compare_ok = 1;
    for ($i=0; $i<=$#rv_to_match_keys; $i++) {
        $compare_ok &= ($rv_to_match_keys[$i] eq $rv_to_test_keys[$i]);
    }
    $test->ok($compare_ok, "Keys in \$rv_to_test all eq keys in \$rv_to_match");

    foreach my $key (@rv_to_match_keys) {
        $test->ok(exists($rv_to_test->{$key}{key})  && $rv_to_test->{$key}{key}  eq $rv_to_match->{$key}{key}, "For $key: sub-key matches the expected");
        $test->ok(exists($rv_to_test->{$key}{file}) && $rv_to_test->{$key}{file} eq $rv_to_match->{$key}{file}, "For $key: file matches the expected");
        $test->ok(exists($rv_to_test->{$key}{type}) && $rv_to_test->{$key}{type} eq $rv_to_match->{$key}{type}, "For $key: type matches the expected");

        if (exists($rv_to_match->{$key}{used_by})) {
            $test->ok(exists($rv_to_test->{$key}{used_by}), "For $key: used_by exists as expected") or next;

            @used_by_test  = sort @{$rv_to_test->{$key}{used_by}}; # order isn't important
            @used_by_match = sort @{$rv_to_match->{$key}{used_by}}; # order isn't important   
            $test->cmp_ok(scalar @used_by_test, '==', scalar @used_by_match, "For $key: number of used_by in \$rv_to_test == Number of used_by in \$rv_to_match") or next;

            $used_by_ok = 1;
            for ($i=0; $i < scalar @used_by_match; $i++) {
                $used_by_ok &= ($used_by_match[$i] eq $used_by_test[$i]);
            }
            $test->ok($used_by_ok, "For $key: used_by in \$rv_to_test all eq used_by in \$rv_to_match");
        }

        if (exists($rv_to_match->{$key}{uses})) {
            $test->ok(exists($rv_to_test->{$key}{uses}), "For $key: uses exists as expected") or next;

            @uses_test  = sort @{$rv_to_test->{$key}{uses}}; # order isn't important
            @uses_match = sort @{$rv_to_match->{$key}{uses}}; # order isn't important
            $test->cmp_ok(scalar @uses_test, '==', scalar @uses_match, "For $key: number of uses in \$rv_to_test == Number of uses in \$rv_to_match") or next;

            $uses_ok = 1;
            for ($i=0; $i < scalar @uses_match; $i++) {
                $uses_ok &= ($uses_match[$i] eq $uses_test[$i]);
            }
            $test->ok($uses_ok, "For $key: uses in \$rv_to_test all eq uses in \$rv_to_match");
        }
    }
}

sub generic_abs_path {
  my $file = shift @_;
  $file = File::Spec->rel2abs($file);
  $file =~ s|\\|\/|go;
  return $file;
}


1;
# Marks the end of any code. Any symbols after this are ignored. Use for documentation
__END__
