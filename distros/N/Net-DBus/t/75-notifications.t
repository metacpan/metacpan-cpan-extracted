# -*- perl -*-
use Test::More tests => 10;

# This test case is primarily about variants - but
# in particular the signature of org.freedesktop.Notifications.Notify

use strict;
use warnings;

BEGIN { 
    use_ok('Net::DBus') or die;
    use_ok('Net::DBus::Object') or die;
};


package MyObject;

use base qw(Net::DBus::Object);
use Net::DBus::Exporter qw(org.cpan.Net.DBus.Test.Notify);

sub new {
    my $class = shift;
    my $service = shift;
    my $self = $class->SUPER::new($service, "/org/cpan/Net/DBus/Test/Notify");
    
    bless $self, $class;

    $self->{data} = {};

    return $self;
}

dbus_method("Notify", ["string", "uint32", "string", "string", "string", ["array", "string"], [ "dict", "string", ["variant"]], "int32"],["uint32"]);
sub Notify {
    my $self = shift;

    $self->{data} = \@_;

    return 0;
}

package main;

my $bus = Net::DBus->test;

my $svc = $bus->export_service("org.cpan.Net.DBus.Test.Notify");
my $obj = MyObject->new($svc);

my $rsvc = $bus->get_service("org.cpan.Net.DBus.Test.Notify");
my $robj = $rsvc->get_object("/org/cpan/Net/DBus/Test/Notify");

my $res = $robj->Notify(
			"dbus-test", # Application name
			7, # replaces_id (0 -> nothing)
			'someicon', #app_icon ("" -> no icon)
			'Test event', # summary
			"This is a test to see if DBUS works nicely in Perl.\nI hope that this works.", # body
			["frob", "wibble"], # actions
			{"ooh" => "eek", "bar" => "wizz"}, # hints
			2_000 # expire_timeout in milliseconds
			);

is($obj->{data}->[0], "dbus-test", "name is correct");
is($obj->{data}->[1], 7, "replacesid is correct");
is($obj->{data}->[2], "someicon", "icon is correct");
is($obj->{data}->[3], "Test event", "summary is correct");
is($obj->{data}->[4], "This is a test to see if DBUS works nicely in Perl.\nI hope that this works.", "name is correct");
is_deeply($obj->{data}->[5], ["frob", "wibble"], "actions is correct");
is_deeply($obj->{data}->[6], {"ooh" => "eek", "bar" => "wizz"}, "hints is correct");
is($obj->{data}->[7], 2_000, "timeout is correct");

