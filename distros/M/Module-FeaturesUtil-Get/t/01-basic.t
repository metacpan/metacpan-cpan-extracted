#!perl

use 5.010001;
use strict;
use warnings;
use FindBin '$Bin';
use lib "$Bin/lib";
use Test::More 0.98;

use Local::Declarer1;
use Module::Features::Local::Definer1;
use Module::FeaturesUtil::Get qw(
                                    get_feature_set_spec
                                    get_features_decl
                                    get_feature_val
                                    module_declares_feature
                            );

subtest get_feature_set_spec => sub {
    my $feature_set_spec = get_feature_set_spec('Local::Definer1');
    ok(ref $feature_set_spec eq 'HASH' && keys %$feature_set_spec)
        or diag explain $feature_set_spec;
};

subtest get_features_decl => sub {
    my $features_decl = get_features_decl('Local::Declarer1');
    ok(ref $features_decl eq 'HASH' && keys %$features_decl)
        or diag explain $features_decl;
};

subtest get_feature_val => sub {
    is_deeply(get_feature_val('Local::Declarer1', 'Dummy', 'feature1'), undef);
    is_deeply(get_feature_val('Local::Declarer1', 'Dummy', 'feature2'), 1);
    is_deeply(get_feature_val('Local::Declarer1', 'Dummy', 'feature3'), 'a');

    is_deeply(get_feature_val('Local::Declarer1', 'Foo', 'feature1'), undef);

    is_deeply(get_feature_val('Local::Declarer2', 'Dummy', 'feature1'), undef);
};

subtest module_declares_feature => sub {
    ok(!module_declares_feature('Local::Declarer1', 'Dummy', 'feature1'));
    ok( module_declares_feature('Local::Declarer1', 'Dummy', 'feature2'));
    ok( module_declares_feature('Local::Declarer1', 'Dummy', 'feature3'));

    ok(!module_declares_feature('Local::Declarer1', 'Foo'  , 'feature1'));

    ok(!module_declares_feature('Local::Declarer2', 'Dummy', 'feature1'));
};

done_testing;
