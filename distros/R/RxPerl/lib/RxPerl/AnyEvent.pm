package RxPerl::AnyEvent;
use strict;
use warnings;

use RxPerl ':all';
use RxPerl::Utils 'immortalize', 'decapitate';

use AnyEvent;
use Sub::Util 'set_subname';

use Exporter 'import';
our @EXPORT_OK = @RxPerl::EXPORT_OK;
our %EXPORT_TAGS = %RxPerl::EXPORT_TAGS;

foreach my $func_name (@EXPORT_OK) {
    set_subname __PACKAGE__."::$func_name", \&{$func_name};
}

sub _timer {
    my ($after, $sub) = @_;

    my $w; $w = AnyEvent->timer(
        after => $after,
        cb    => $sub,
    );

    immortalize($w);

    return $w;
}

sub _cancel_timer {
    my ($w) = @_;

    defined $w or return;

    decapitate($w);
}

sub _interval {
    my ($after, $sub) = @_;

    my $w; $w = AnyEvent->timer(
        after    => $after,
        interval => $after,
        cb       => $sub,
    );

    immortalize($w);

    return $w;
}

sub _cancel_interval {
    my ($w) = @_;

    defined $w or return;

    decapitate($w);
}

1;
