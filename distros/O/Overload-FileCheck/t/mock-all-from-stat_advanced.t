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
use Test2::Plugin::NoWarnings;

use Overload::FileCheck q{:all};
use Carp;

{

    note "unmock everything...";
    unmock_all_file_checks();
    unmock_stat();

    my $save_lstats = {};
    my $save_stats  = {};
    my $save_checks = {};

    ### TODO create some fake files ourself...
    #   to provide a more stable testsuite
    my @candidates = qw{
      /
      /usr
      /usr/local
      /bin
      /bin/true
      /usr/bin/true
      /home
      /dev/tty1
      /dev/sda1
      /root/.bashrc
    };

    if ( $> == 0 ) {
        push @candidates, '/tmp';
    }

    my %forbidden = map { $_ => 1 } ( 'T-/dev/tty1', 'B-/dev/tty1' );

    foreach my $f (@candidates) {

        # use lstat otherwise we will read the target for symlink
        $save_lstats->{$f} = [ lstat($f) ];
        $save_stats->{$f}  = [ stat($f) ];    # we need both...
        $save_checks->{$f} = {};

        # let keys add some randomness
        foreach my $check ( keys %{ Overload::FileCheck::_get_filecheck_ops_map() } ) {
            next if $forbidden{"$check-$f"};

            # note "Unmocked -$check '$f'";
            if ( $check =~ qr{stat} ) {
                $save_checks->{$f}->{$check} = eval qq{ [ $check('$f') ] };
            }
            else {
                $save_checks->{$f}->{$check} = eval qq{scalar -$check '$f'};
            }

        }
    }

    ok mock_all_from_stat( \&mock_stat_from_sys ), "mock_again";

    sub mock_stat_from_sys {
        my ( $stat_or_lstat, $f ) = @_;

        # we are adding a FAKE/ prefix to be sure we are not
        #   using the system this time but our fake FileSystem...
        return FALLBACK_TO_REAL_OP() unless $f =~ s{^FAKE/}{};

        my $cache = $stat_or_lstat eq 'stat' ? $save_stats : $save_lstats;

        if ( defined $cache->{$f} ) {
            note "Returning Cached $stat_or_lstat for $f";    #, Carp::longmess();
            return $cache->{$f};
        }

        return FALLBACK_TO_REAL_OP();
    }

    #note explain $save_checks;

    my $last_check;
    my %todo = map { $_ => 1 } qw{ C-/bin M-/bin };
    my $all_clear;

    foreach my $f (@candidates) {
        $last_check = $f;

        # let keys add some randomness
        foreach my $check ( sort keys %{ Overload::FileCheck::_get_filecheck_ops_map() } ) {
            next if $check =~ qr{stat};    # TODO also check mocked stat maybe first

            next if $forbidden{"$check-$f"};
            note "Checking Mocked: -$check '$f' ";
            my $got = eval qq{scalar -$check 'FAKE/$f'};

            my $expect = $save_checks->{$f}->{$check};

            if ( $todo{"$check-$f"} || $check =~ qr{^[BT]$} ) {

                # -B and -T are using heuristic guess and need to open the file...
                todo "-$check '$f' known limitation" => sub {
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
        note "lstat for ", $last_check, explain $save_lstats->{$last_check};

        die "The previous test failed...";
    }

}

done_testing;

exit;
