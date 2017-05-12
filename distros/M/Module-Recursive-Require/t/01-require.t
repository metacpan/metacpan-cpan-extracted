use strict;
use Test::More qw(no_plan);;
use Module::Recursive::Require;

INIT {
    use lib 't/testlib';
}

test0();
test1();
test2();

sub test0 {
    my $r = Module::Recursive::Require->new();
    
    isa_ok($r, 'Module::Recursive::Require');
    can_ok($r, qw/add_filter require_by require_of/);
}

sub test1 {
    my $r = Module::Recursive::Require->new();
    
    ok( $r->add_filter(qr/^Base\.pm$/), 'add filter test' );
    
    my $modules = $r->require_of('MyApp');
    eq_set( $modules, [qw/MyApp::Foo MyApp::Test MyApp::Mail MyApp::Mail::LoveMail/]);
    
    my $love_mail = MyApp::Mail::LoveMail->new();
    isa_ok($love_mail, 'MyApp::Mail::LoveMail');
    
    ok( $love_mail->send(), 'MyApp::Mail::LoveMail->send Test!');
}

sub test2 {
    my $r = Module::Recursive::Require->new();
    
    ok( $r->first_loads(qw/MyApp::Mail/), 'first loads test' );
    ok( $r->add_filter(qr/^Base\.pm$/), 'add filter test' );
    
    my $modules = $r->require_of('MyApp');
    ok( $modules->[0] eq 'MyApp::Mail' , 'first loads test');
    eq_set( $modules, [qw/MyApp::Foo MyApp::Test MyApp::Mail MyApp::Mail::LoveMail/]);
    
    my $love_mail = MyApp::Mail::LoveMail->new();
    isa_ok($love_mail, 'MyApp::Mail::LoveMail');
    
    ok( $love_mail->send(), 'MyApp::Mail::LoveMail->send Test!');
}

