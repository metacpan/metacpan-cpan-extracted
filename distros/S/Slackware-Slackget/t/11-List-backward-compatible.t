use Test::More tests => 17;

BEGIN {
	use_ok( 'Slackware::Slackget::List' );
	use_ok( 'Slackware::Slackget::Package' );
}

my $list = Slackware::Slackget::List->new(list_type => 'Slackware::Slackget::Package', 'root-tag' => 'test') ;
ok($list);

ok($list->add( Slackware::Slackget::Package->new('package-1.0.0-noarch-1') ));
ok($list->add( Slackware::Slackget::Package->new('package-1.0.1-noarch-1') ));
ok($list->add( Slackware::Slackget::Package->new('package-1.0.2-noarch-1') ));
ok($list->add( Slackware::Slackget::Package->new('package-1.0.3-noarch-1') ));
ok($list->add( Slackware::Slackget::Package->new('package-1.0.4-noarch-1') ));
ok($list->add( Slackware::Slackget::Package->new('package-1.0.5-noarch-1') ));

ok($list->to_XML);
ok($list->to_HTML);

ok( $list->get(2)->get_id eq 'package-1.0.2-noarch-1' );
ok( $list->Length == 6);
ok( $list->Shift()->get_id eq 'package-1.0.0-noarch-1' );
ok( $list->Length == 5);
ok( $list->empty );
ok( $list->Length == 0);

