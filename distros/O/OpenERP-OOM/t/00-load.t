#!perl

use Test::Most '-Test::Deep';

bail_on_fail;

BEGIN {
    use_ok( 'OpenERP::OOM' ) || print "Bail out!
";
}
use_ok('OpenERP::OOM::Class');
use_ok('OpenERP::OOM::Class::Base');
use_ok('OpenERP::OOM::Link');
use_ok('OpenERP::OOM::Link::DBIC');
use_ok('OpenERP::OOM::Link::Provider');
use_ok('OpenERP::OOM::Meta::Class::Trait::HasLink');
use_ok('OpenERP::OOM::Meta::Class::Trait::HasRelationship');
use_ok('OpenERP::OOM::Object');
use_ok('OpenERP::OOM::Object::Base');
use_ok('OpenERP::OOM::Schema');

diag( "Testing OpenERP::OOM $OpenERP::OOM::VERSION, Perl $], $^X" );

done_testing;
