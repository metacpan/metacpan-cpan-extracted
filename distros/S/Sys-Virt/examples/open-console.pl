#!/usr/bin/perl

use Gtk3 -init;
use Sys::Virt;

Glib::Object::Introspection->setup(
    basename => 'GtkVnc',
    version => '2.0',
    package => 'GtkVnc');

Glib::Object::Introspection->setup(
    basename => 'GVnc',
    version => '1.0',
    package => 'GVnc');

GVnc::util_set_debug(true);

my $window = Gtk3::Window->new ('toplevel');
my $display = GtkVnc::Display->new();

my ($SOCK1, $SOCK2);
if (1) {
    use IO::Socket;

    ($SOCK1, $SOCK2) = IO::Socket->socketpair(AF_UNIX, SOCK_STREAM, PF_UNSPEC)
	or die "cannot create socketpair: $!";

    my $c = Sys::Virt->new(uri => "qemu:///session");
    my $d = $c->get_domain_by_name("vm-vnc");

    $d->open_graphics(0, $SOCK1->fileno);

    $display->open_fd($SOCK2->fileno);
} else {
    $display->open_host("localhost", "5900");
}
$window->add($display);
$window->show_all;
Gtk3::main;


