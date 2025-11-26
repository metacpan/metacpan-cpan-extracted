#!perl
use strict;
use warnings;
use 5.010;

our $VERSION = '0.001';

use Test2::V0;

use Software::Policies;

subtest 'Test list' => sub {

    # We cannot test all because there could be other classes installed by user.
    # my $wanted_policies = {
    #     'Contributing' => {
    #         classes => {
    #             'PerlDistZilla' => {
    #                 versions => {
    #                     '1' => 1
    #                 },
    #                 formats => {
    #                     'markdown' => 1,
    #                     'text' => 1,
    #                 },
    #             },
    #         },
    #     },
    # };

    my $p        = Software::Policies->new;
    my $policies = $p->list();

    is( $policies->{'Contributing'}->{'classes'}->{'PerlDistZilla'}->{'versions'}->{'1'},       1 );
    is( $policies->{'Contributing'}->{'classes'}->{'PerlDistZilla'}->{'formats'}->{'markdown'}, 1 );
    is( $policies->{'Contributing'}->{'classes'}->{'PerlDistZilla'}->{'formats'}->{'text'},     1 );

    done_testing;
};
done_testing;
