# -*- perl -*-
use Test::More tests => 6;

use strict;
use warnings;

BEGIN {
    use_ok('Net::DBus');
    use_ok('Net::DBus::Error');
    use_ok('Net::DBus::Object');
};

package MyError;

use base qw(Net::DBus::Error);

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $self = $class->SUPER::new(name => "org.example.music.UnknownFormat",
				  message => "Unknown track encoding format");
}


package MyObject;

use base qw(Net::DBus::Object);
use Net::DBus::Exporter qw(org.example.MyObject);

dbus_method("play", ["string"], ["string"]);
sub play {
    my $self = shift;
    my $url = shift;
    
    if ($url =~ /\.(mp3|ogg)$/) {
	return $url;
    } else {
	die MyError->new();
    }
}

package main;

my $bus = Net::DBus->test;
my $service = $bus->export_service("org.cpan.Net.Bus.test");
my $object = MyObject->new($service, "/org/example/MyObject");

my $rservice = $bus->get_service("org.cpan.Net.Bus.test");
my $robject = $rservice->get_object("/org/example/MyObject");

eval {
    $robject->play("foo.flac");
};
my $error = $@;
isa_ok($error, "Net::DBus::Error");
is($error->name, "org.example.music.UnknownFormat", "error name is set");
is($error->message, "Unknown track encoding format", "error description is set");
