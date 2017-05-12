package PDTest;
use 5.0.12;
use Config;
use POSIX qw(setlocale LC_ALL); setlocale(LC_ALL, 'en_US.UTF-8');

use Panda::Time qw/
    tzset tzget tzname tzdir gmtime localtime timegm timegmn timelocal timelocaln systimelocal
    available_zones use_embed_zones use_system_zones
/;

use_embed_zones();
tzset('Europe/Moscow');

sub import {
    my $stash = \%{PDTest::};
    my $caller = caller();
    *{"${caller}::$_"} = *{"PDTest::$_"} for keys %$stash;
}

sub get_dates {
    my $file = 't/data/'.shift().'.txt';
    open my $fh, '<', $file or die "Cannot open test data file '$file': $!";
    <$fh>; # skip stat line
    local $/ = undef;
    my $content = <$fh>;
    return eval $content;
}

sub get_row_tl {
    my $row = shift;
    return lt2tl(@{$row->[1]});
}

sub lt2tl { return @_[0..5,8]; }

sub epoch_from {
    die "cant parse date" unless $_[0] =~ /^(-?\d+)-(\d+)-(\d+) (\d+):(\d+):(\d+)$/;
    return &timegm($6, $5, $4, $3, $2-1, $1);
}

sub leap_zones_dir { return tzdir().'/right' }

1;
