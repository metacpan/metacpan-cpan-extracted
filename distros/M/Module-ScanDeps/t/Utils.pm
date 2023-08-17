package Utils;

use strict;
use warnings;

require Exporter;
use Module::ScanDeps qw(path_to_inc_name);

use Test::More;
use Data::Dumper;

our @ISA = qw(Exporter);
our $VERSION   = '0.1';
our @EXPORT = qw( check_rv compare_rv generic_abs_path dump_rv );

# runs 1 (toplevel) test
sub check_rv {
    my ($rv, $input_keys, $known_deps, $name) = @_;
    $name ||= "Check rv";

    return subtest($name, sub {

        # sanity check input
        {
            my %i = map { ($_, 1) } @$input_keys;
            die "\@input_keys overlaps with \@known_deps\n" if grep { $i{$_} } @$known_deps;
        }

        isa_ok($rv, "HASH", "\$rv is a HASH") or return;

        # check all input files and known deps correspond to an entry in rv
        my @input_keys = map { path_to_inc_name($_, 1) } @$input_keys;
        my @known_deps = @$known_deps;      # make a copy 
        map {$_ =~ s:\\:/:g} (@input_keys, @known_deps);
        ok(exists $rv->{$_}, "$_ is in \$rv") foreach (@input_keys, @known_deps);

        # Check general properties of the keys
        foreach my $k (keys %$rv) {
            my $v = $rv->{$k};
            ok(exists($v->{key}) && $k eq $v->{key},
               qq[key $k matches field "key"]);
            ok(exists($v->{file}) && 
               $v->{file} =~ /(?:^|[\/\\])\Q$k\E$/ && 
               File::Spec->file_name_is_absolute($v->{file}),
               qq[key $k: field "file" has been verified]);
            ok(exists($v->{type}) && 
               $v->{type} =~ /^(?:module|autoload|data|shared)$/,
               qq[key $k: field "type" matches module|autoload|data|shared]);

            if (exists($v->{used_by})) {
                ok(@{$v->{used_by}} > 0, 
                   qq[key $k: field "used_by" isn't empty if it exists]);

                my %dup;
                ok(!(grep { ++$dup{$_} > 1 } @{$v->{used_by}}), 
                   qq[key $k: field "used by" has no duplicates]);

                ok(!(grep { !exists $rv->{$_} } @{$v->{used_by}}),
                   qq[key $k: all entries in field "used by" are themselves in \$rv]);

                foreach my $u (@{$v->{used_by}}) {
                    # check corresponding uses field
                    ok(exists($rv->{$u}{uses}),
                       qq[\$rv contains a matching "uses" field for the "used_by" entry $u for key $k])
                       or next;

                    ok(scalar(grep { $_ eq $k } @{$rv->{$u}{uses}}),
                       qq[\$rv contains a matching "uses" field for the "used_by" entry $u for key $k]);
                }
            } else {
                ok(scalar(grep { $_ eq $k} @input_keys), # XXX || $k =~ /Plugin/, 
                   qq[key $k: field "used by" doesn't exist so $k must be one of the input files])
            }

            if (exists($v->{uses})) {
                # check corresponding used_by field
                foreach my $u (@{$v->{uses}}) {
                    ok(exists($rv->{$u}{used_by}),
                       qq[\$rv contains a matching "used_by" field for the "uses" entry $u for key $k])
                       or next;
                    ok(scalar(grep { $_ eq $k } @{$rv->{$u}{used_by}}), 
                       qq[\$rv contains a matching "used_by" field for the "uses" entry $u for key $k]);
                }
             }
        }
    });
}

# runs 1 (toplevel) test
sub compare_rv {
    my ($rv_got, $rv_expected, $input_keys, $name) = @_;
    $name ||= "Compare rvs";

    return subtest($name, sub {

        check_rv($rv_expected, $input_keys, []); # validate test data

        isa_ok($rv_got, "HASH", "\$rv_got is a HASH") or return;

        if (( my @missing = grep { !exists $rv_got->{$_} } keys %$rv_expected ) ||
            ( my @surplus = grep { !exists $rv_expected->{$_} } keys %$rv_got )) {
            fail("missing keys in \$rv_got: @missing") if @missing;
            fail("surplus keys in \$rv_got: @surplus") if @surplus;
            return;
        }

        foreach my $k (keys %$rv_expected) {
            my $expected = $rv_expected->{$k};
            my $got = $rv_got->{$k};

            for (qw( key file type )) {
                ok((exists $got->{$_}) && $got->{$_} eq $expected->{$_},
                   qq[key $k: field "$_" matches]);
            }

            for (qw( used_by uses )) {
                if (exists $expected->{$_}) {
                    ok(exists($got->{$_}), qq[key $k: field "$_" exists]) or next;
                    is_deeply( [sort @{$got->{$_}}], [sort @{$expected->{$_}}],
                        qq[key $k: field "$_" matches]);
                }
            }
        }
    });
}

sub generic_abs_path {
    my ($file) = @_;

    $file = File::Spec->rel2abs($file);
    $file =~ s:\\:/:g;

    return $file;
}

sub dump_rv {
    my ($name, $rv) = @_;

    return Data::Dumper->Dump([$rv], [$name]);
}

1;
