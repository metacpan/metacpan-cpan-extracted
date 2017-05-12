package Pgtools::Connection;
use strict;
use warnings;

use parent qw(Class::Accessor);
__PACKAGE__->mk_accessors(qw(dbh host port user password database));

sub set_args {
    my $self = shift;
    my ($option) = @_;
    my @tmp = split(/,/, $option, -1);
    if($#tmp != 4) {
        die "Invalid arguments.\nPlease check pg_config_diff -help\n";
    }
    $self->set("host", $tmp[0]) if $tmp[0] ne '';
    $self->set("port", $tmp[1]) if $tmp[1] ne '';
    $self->set("user", $tmp[2]) if $tmp[2] ne '';
    $self->set("password", $tmp[3]) if $tmp[3] ne '';
    $self->set("database", $tmp[4]) if $tmp[4] ne '';
}

sub create_connection {
    my $self = shift;

    $self->set("dbh", DBI->connect(
        "dbi:Pg:dbname=".$self->database.";host=".$self->host.";port=".$self->port,
        $self->user,
        $self->password
    )) or die "$!\n Error: failed to connect to DB.\n";
}



1;
