use Win32::OLE;
use Test::Most tests => 5;
use Test::Moose;
use lib 't';
use Test::COM;

require_ok('Siebel::COM');
my $siebel_app = 'SiebelDataControl.SiebelDataControl.1';
my $return = Win32::OLE->new($siebel_app);
my $generic_msg = 'although this might not be a failure of this distribution itself, you MUST check this or nothing will work if you try to get a object instance in this computer';

SKIP: {
    note(Win32::OLE->LastError());
    skip "$siebel_app seems not be registered, $generic_msg", 2, unless ($return);
    ok( $return, "it is possible to instantiate a $siebel_app object" );
    my $foo = Test::COM->new( Win32::OLE->new($siebel_app) );
    has_attribute_ok( $foo, '_ole' );

}

$siebel_app = 'SiebelDataServer.ApplicationObject';
$return = Win32::OLE->new($siebel_app);

SKIP: {

    note(Win32::OLE->LastError());
    skip "$siebel_app seems not be registered, $generic_msg", 2, unless ($return);
    ok( $return, "it is possible to instantiate a $siebel_app object" );
    my $foo = Test::COM->new( Win32::OLE->new($siebel_app) );
    has_attribute_ok( $foo, '_ole' );

}

