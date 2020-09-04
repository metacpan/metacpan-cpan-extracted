package RxPerl::Utils;
use strict;
use warnings FATAL => 'all';

use Scalar::Util 'weaken';

use Exporter 'import';
our @EXPORT_OK = qw/
    get_subscription_from_subscriber immortalize decapitate
    get_timer_subs get_interval_subs
/;

our $VERSION = "v0.16.0";

sub get_subscription_from_subscriber { $_[0]->{_subscription} }

my %KEEP_ALIVE;

sub immortalize {
    my ($var) = @_;

    $KEEP_ALIVE{$var} = $var;
}

sub decapitate {
    my ($var) = @_;

    delete $KEEP_ALIVE{$var};
}

sub get_timer_subs {
    my $package = ((caller(1))[3] =~ /^(.+)\:\:/)[0];
    my ($fn1, $fn2) = map "${package}::$_", '_timer', '_cancel_timer';
    no strict 'refs';
    return map \&{ $_ }, $fn1, $fn2;
}

sub get_interval_subs {
    my $package = ((caller(1))[3] =~ /^(.+)\:\:/)[0];
    my ($fn1, $fn2) = map "${package}::$_", '_interval', '_cancel_interval';
    no strict 'refs';
    return map \&{ $_ }, $fn1, $fn2;
}

1;
