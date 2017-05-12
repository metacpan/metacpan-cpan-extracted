package MPA_Test;

use 5.010001;
use Exporter 'import';

use Time::Local qw(timegm);

our @EXPORT_OK = qw(log2unixtime);

sub log2unixtime ($) {
    state $month2number = {map {
        state $i = 0;
        $_ => $i++;
    } qw(Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec)};
    my ($mday, $mon, $year, $hour, $min, $sec, $zs, $zh, $zm) = shift =~ m,
        ^\[
            (\d{2}) / (\w{3}) / (\d{4})
            :
            (\d{2}) : (\d{2}) : (\d{2})
            \s+
            ([\+\-])(\d{2})(\d{2})
        \]$
    ,x
        or return undef;

    my $t = timegm($sec, $min, $hour, $mday, $month2number->{$mon}, $year)
        or return;
    my $offset = ($zh * 60 + $zm) * 60;

    return $zs eq '+' ? $t - $offset : $t + $offset;
}

1;
