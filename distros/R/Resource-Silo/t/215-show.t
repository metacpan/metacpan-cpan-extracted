#!/usr/bin/env perl

=head1 DESCRIPTION

Test inspecting the container metadata.

=cut

use strict;
use warnings;
use Test::More;
use Test::Exception;

use Resource::Silo;

my $file = quotemeta __FILE__;
my @line;

resource config_path => sub {};
push @line, __LINE__ - 1;

resource config_name => literal => 'foo.yaml';
push @line, __LINE__ - 1;

resource config =>
    dependencies    => ['config_path', 'config_name'],
    require         => 'YAML::XS',
    init            => sub {};
push @line, __LINE__ - 1;

resource dbh    =>
    require         => 'DBI',
    dependencies    => ['config'],
    init            => sub {};
push @line, __LINE__ - 1;

my $meta = silo->ctl->meta;

is_deeply   [sort $meta->list ],
            [sort qw[config_path config_name config dbh]],
            "resource list as expected";

throws_ok {
    $meta->show( "noexist" );
} qr(^Unknown resource 'noexist'), "unknown resource = no go";

subtest "config_path" => sub {
    my $entry = $meta->show("config_path");
    # note explain $entry;
    is_deeply $entry->{dependencies}, undef, "no deps specified";
    like $entry->{origin}, qr($file line $line[0]), "known where it's defined";

};

subtest "config_name" => sub {
    my $entry = $meta->show("config_name");
    # note explain $entry;
    is_deeply $entry->{dependencies}, [], "literal = no deps";
    like $entry->{origin}, qr($file line $line[1]), "known where it's defined";
    ok $entry->{derived}, "literal = auto-set derived";
    is $entry->{cleanup_order}, 9**9**9, "cleanup_order preserved";
};

subtest "config" => sub {
    my $entry = $meta->show("config");
    # note explain $entry;
    like $entry->{origin}, qr($file line $line[2]), "known where it's defined";
    is_deeply [ sort @{ $entry->{dependencies} } ]
        , [sort qw[config_path config_name]]
        , "has dependencies";
    is_deeply $entry->{require}, [qw[YAML::XS]], "required module retained";
    is $entry->{cleanup_order}, 0, "auto cleanup order = 0";
};

done_testing;
