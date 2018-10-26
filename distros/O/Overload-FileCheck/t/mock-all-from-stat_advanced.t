#!/usr/bin/perl -w

# Copyright (c) 2018, cPanel, LLC.
# All rights reserved.
# http://cpanel.net
#
# This is free software; you can redistribute it and/or modify it under the
# same terms as Perl itself. See L<perlartistic>.

use strict;
use warnings;

use Test2::Bundle::Extended;
use Test2::Tools::Explain;

#use Test2::Plugin::NoWarnings;

use File::Temp qw/ tempdir /;
use Overload::FileCheck q{:all};
use Carp;

{
    my $save_lstats = {};
    my $save_stats  = {};
    my $save_checks = {};

    my $fixtures;
    eval { $fixtures = create_fixtures(); 1 } or skip_all "Fail to create fixtures files: $@";

    my %forbidden = map { $_ => 1 } (
        'T-/dev/tty1',             # .
        'B-/dev/tty1',             # .
        'T-./my-sample.socket',    # .
        'B-./my-sample.socket',    # .
        'T-/dev/random',           # .
        'B-/dev/random',           # .
    );

    foreach my $f (@$fixtures) {

        # use lstat otherwise we will read the target for symlink
        $save_lstats->{$f} = [ lstat($f) ];
        $save_stats->{$f}  = [ stat($f) ];    # we need both...
        $save_checks->{$f} = {};

        # let keys add some randomness
        foreach my $check ( keys %{ Overload::FileCheck::_get_filecheck_ops_map() } ) {
            next if $forbidden{"$check-$f"};

            #note "Unmocked -$check '$f'";
            local $SIG{ALRM} = sub { die "Alarm from Unmocked -$check '$f'" };
            alarm(60);                        # just avoid to run forever, should be large enough for slow systems...

            if ( $check =~ qr{stat} ) {
                $save_checks->{$f}->{$check} = eval qq{ [ $check('$f') ] };
            }
            else {
                $save_checks->{$f}->{$check} = eval qq{scalar -$check '$f'};
            }

            alarm(0);
        }
    }

    ok mock_all_from_stat( \&mock_stat_from_sys ), "mock_again";

    my $last_cache_for;

    sub mock_stat_from_sys {
        my ( $stat_or_lstat, $f ) = @_;

        # we are adding a FAKE/ prefix to be sure we are not
        #   using the system this time but our fake FileSystem...
        return FALLBACK_TO_REAL_OP() unless $f =~ s{^FAKE/}{};

        my $cache = $stat_or_lstat eq 'stat' ? $save_stats : $save_lstats;

        if ( defined $cache->{$f} ) {

            #note "Returning Cached $stat_or_lstat for $f";    #, Carp::longmess();
            $last_cache_for = $f;
            return $cache->{$f};
        }

        return FALLBACK_TO_REAL_OP();
    }

    # Testing the mock stat
    ok -e $fixtures->[0], "-e $fixtures->[0]";
    is $last_cache_for, undef, "fallback... when not using FAKE/ prefix" or die;
    ok -e "FAKE/" . $fixtures->[0], "-e FAKE/$fixtures->[0]" or die;
    is $last_cache_for, $fixtures->[0], "last_cache_for set when using FAKE/ prefix";

    # ok ! -X 'FAKE/./link-to-textfile', "-X ./link-to-textfile";
    # ok -X 'FAKE//bin/true', "-X /bin/true";
    # done_testing; exit;

    #note explain $save_checks;

    my ( $last_file, $last_check );
    my %todo = map { $_ => 1 } qw{ C-/bin M-/bin };
    my $all_clear;

    foreach my $f (@$fixtures) {
        $last_file = $f;

        # let keys add some randomness
        foreach my $check ( sort keys %{ Overload::FileCheck::_get_filecheck_ops_map() } ) {
            next if $check =~ qr{stat};        # TODO also check mocked stat maybe first
            next if $forbidden{"$check-$f"};

            $last_check = "-$check $f";

            note "Checking Mocked: -$check '$f' ";
            my $got = eval qq{scalar -$check 'FAKE/$f'};

            my $expect = $save_checks->{$f}->{$check};

            if ( $todo{"$check-$f"} || $check =~ qr{^[BT]$} ) {

                # -B and -T are using heuristic guess and need to open the file...
                todo "-$check '$f' known limitation (using heuristic guess)" => sub {
                    is $got, $expect, "-$check '$f'";
                };
                next;
            }

            if ( !defined $expect && defined $got && ( $got eq '' || $got eq '0' ) ) {
                todo "-$check '$f' returns '' instead of undef..." => sub {
                    is $got, $expect, "-$check '$f'";
                };
                next;
            }

            if ( !defined $got && defined $expect && $expect eq '' ) {
                todo "-$check '$f' returns undef instead of ''..." => sub {
                    is $got, $expect, "-$check '$f'";
                };
                next;
            }

            if ( $check =~ qr{^[AC]$} && defined $expect ) {

                # Script X time minus file modification time, in days.
                # add a small tolerance
                # A is for 'access time'

                if ( !defined $got ) {
                    todo "got undef..." => sub {
                        is $got, $expect, "-$check '$f'";
                    };
                    next;
                }

                if ( !( ( $expect - $got ) < 0.1 ) ) {
                    todo "-A tolerance not enough..." => sub {
                        is $got, $expect, "-$check '$f'";
                    };
                    next;
                }

                ok( ( $expect - $got ) < 0.1, "small tolerance for -A '$f': $got vs $expect" )
                  or diag "-A access time; got: ", $got, " expect ", $expect;
                next;
            }

            is $got, $expect, "-$check '$f'" or goto DEBUG;
        }

        #last;
    }

    $all_clear = 1;

  DEBUG: if ( !$all_clear ) {

        diag "Last check was ", $last_check, " ; lstat: ", explain $save_lstats->{$last_file};

        die "The previous test failed...";
    }

}

done_testing;

exit;

my $TMP;

sub create_fixtures {

    $TMP = tempdir( CLEANUP => 1 );

    chdir $TMP or die;

    mkdir("dir1") or die;
    mkdir( "dir2", 0600 ) or die;

    if ( open( my $fh, '>', "dir2/file" ) ) {
        print {$fh} "some content\n";
        close $fh;
    }

    if ( open( my $fh, '>', "empty-file" ) ) {
        close $fh;
    }

    if ( open( my $fh, '>', "text-file" ) ) {
        print {$fh} "this is a text file\n" x 10;
        close $fh;
    }

    symlink( "dir1", "link-to-dir1" ) or die;
    symlink( "dir2", "link-to-dir2" ) or die;

    symlink( "text-file",  "link-to-textfile" )  or die;
    symlink( "empty-file", "link-to-emptyfile" ) or die;
    symlink( "not-there",  "link-to-void" )      or die;

    # create a socket ?
    qx{mkfifo my-sample.socket};

    # auto populate fixtures
    my @fixtures = qx[ find . ];    # improve use File::Find there
    die "find fails" if $?;
    chomp @fixtures;
    die "no fixtures..." unless scalar @fixtures;
    push( @fixtures, "missing-file", "missing-dir/missing-file" );

    # try to add /bin/true and /bin/false
    my @extra = qw{
      /bin/true
      /bin/false
      /dev/random
      /dev/tty1
      /dev/vda1
      /dev/sda1
      /
      /home
      /usr
      /usr/local
      /tmp
    };

    foreach my $f (@extra) {
        push @fixtures, $f if -e $f;
    }

    # my @ls = qx[ls -l];
    # chomp @ls;
    # note explain [ @ls ];

    note explain \@fixtures;

    return \@fixtures;
}

