#/usr/bin/perl

use Net::DBus::GLib;

my $bus = Net::DBus::GLib->session();

my $service = $bus->get_service("org.designfu.SampleService");
my $object = $service->get_object("/SomeObject");

my $list = $object->HelloWorld("Hello from example-client.pl!");

print "[", join(", ", map { "'$_'" } @{$list}), "]\n";

my $tuple = $object->GetTuple();

print "(", join(", ", map { "'$_'" } @{$tuple}), ")\n";

my $dict = $object->GetDict();

print "{", join(", ", map { "'$_': '" . $dict->{$_} . "'"} keys %{$dict}), "}\n";

