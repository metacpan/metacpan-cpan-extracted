package RxPerl::Mojo;
use strict;
use warnings FATAL => 'all';

use RxPerl ':all';

use Mojo::IOLoop;
use Sub::Util 'set_subname';

use Exporter 'import';
our @EXPORT_OK = @RxPerl::EXPORT_OK;
our %EXPORT_TAGS = %RxPerl::EXPORT_TAGS;

foreach my $func_name (@EXPORT_OK) {
    set_subname __PACKAGE__."::$func_name", \&{$func_name};
}

sub _timer {
    my ($after, $sub) = @_;

    my $id;
    $id = Mojo::IOLoop->timer($after, sub {
        undef $id;
        $sub->();
    });

    return \$id;
}

sub _cancel_timer {
    my ($id_ref) = @_;

    defined $id_ref or return;

    Mojo::IOLoop->remove($$id_ref);
}

sub _interval {
    my ($after, $sub) = @_;

    my $id = Mojo::IOLoop->recurring($after, $sub);

    return $id;
}

sub _cancel_interval {
    my ($id) = @_;

    defined $id or return;

    Mojo::IOLoop->remove($id);
}

1;
