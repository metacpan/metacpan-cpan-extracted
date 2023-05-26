# -*- CPerl -*-

use Test::More qw(no_plan);
use strict;
use warnings;

use POSIX;
setlocale(&LC_ALL, 'C');

BEGIN { use_ok('Number::Format') }

my $usd = Number::Format->new(
                              -int_curr_symbol   => 'USD',
                              -currency_symbol   => '$',
                              -decimal_point     => '.',
                              -frac_digits       => 2,
                              -int_frac_digits   => 2,
                              -n_cs_precedes     => 1,
                              -n_sep_by_space    => 1,
                              -n_sign_posn       => 1,
                              -negative_sign     => '-',
                              -p_cs_precedes     => 1,
                              -p_sep_by_space    => 1,
                              -p_sign_posn       => 1,
                              -positive_sign     => '',
                              -thousands_sep     => ',',
                              -mon_thousands_sep => ',',
                              -decimal_fill      => 1,
                              -decimal_digits    => 2,
                              -mon_decimal_point => '.',
                             );

is($usd->format_price(123456.51),   'USD 123,456.51',     'thou');
is($usd->format_price(1234567.509), 'USD 1,234,567.51',   'mill');
is($usd->format_price(1234.51, 3),  'USD 1,234.510',      'three dec');
is($usd->format_price(123456789.1), 'USD 123,456,789.10', 'zero in dec');
is($usd->format_price(100, '0'),    'USD 100',            'no dec');

$usd->{p_cs_precedes}  = 1;
$usd->{p_sep_by_space} = 0;
$usd->{n_cs_precedes}  = 1;
$usd->{n_sep_by_space} = 0;
$usd->{p_sign_posn}    = 1;
$usd->{n_sign_posn}    = 1;

is($usd->format_price(19.95, undef, 'currency_symbol'),
   '$19.95', 'domestic');

$usd->{int_frac_digits} = 4;
$usd->{frac_digits} = 3;

is($usd->format_price(19.95, undef, 'currency_symbol'),
   '$19.950', 'frac_digits');
is($usd->format_price(19.95), 'USD19.9500', 'int frac digits');

$usd->{n_sign_posn} = 0;
is($usd->format_price(-9.95), '(USD9.9500)', 'n_sign_posn=0');

$usd->{n_sign_posn} = 1;
is($usd->format_price(-9.95), '-USD9.9500', 'n_sign_posn=1');

$usd->{n_sign_posn} = 2;
is($usd->format_price(-9.95), 'USD9.9500-', 'n_sign_posn=2');

$usd->{n_sign_posn} = 3;
is($usd->format_price(-9.95), '-USD9.9500', 'n_sign_posn=3');

$usd->{n_sign_posn} = 4;
is($usd->format_price(-9.95), 'USD-9.9500', 'n_sign_posn=4');

$usd->{n_cs_precedes} = 1;
$usd->{n_sign_posn} = 3;
$usd->{n_sep_by_space} = 0;
is($usd->format_price(-9.95), '-USD9.9500', 'cs_precedes=1,sep_by_space=0');

$usd->{n_sep_by_space} = 1;
is($usd->format_price(-9.95), '-USD 9.9500', 'cs_precedes=1,sep_by_space=1');

$usd->{n_sep_by_space} = 2;
is($usd->format_price(-9.95), '- USD9.9500', 'cs_precedes=1,sep_by_space=2');

$usd->{n_cs_precedes} = 0;
$usd->{n_sign_posn} = 3;
$usd->{n_sep_by_space} = 0;
is($usd->format_price(-9.95), '9.9500-USD', 'cs_precedes=0,sep_by_space=0');

$usd->{n_sep_by_space} = 1;
is($usd->format_price(-9.95), '9.9500 -USD', 'cs_precedes=0,sep_by_space=1');

$usd->{n_sep_by_space} = 2;
is($usd->format_price(-9.95), '9.9500- USD', 'cs_precedes=0,sep_by_space=2');
my %results = ('sep=0 posn=0 prec=0'    => '(9.9500USD)',
               'sep=0 posn=0 prec=1'    => '(USD9.9500)',
               'sep=0 posn=1 prec=0'    => '-9.9500USD',
               'sep=0 posn=1 prec=1'    => '-USD9.9500',
               'sep=0 posn=2 prec=0'    => '9.9500USD-',
               'sep=0 posn=2 prec=1'    => 'USD9.9500-',
               'sep=0 posn=3 prec=0'    => '9.9500-USD',
               'sep=0 posn=3 prec=1'    => '-USD9.9500',
               'sep=0 posn=4 prec=0'    => '9.9500USD-',
               'sep=0 posn=4 prec=1'    => 'USD-9.9500',
               'sep=1 posn=0 prec=0'    => '(9.9500 USD)',
               'sep=1 posn=0 prec=1'    => '(USD 9.9500)',
               'sep=1 posn=1 prec=0'    => '-9.9500 USD',
               'sep=1 posn=1 prec=1'    => '-USD 9.9500',
               'sep=1 posn=2 prec=0'    => '9.9500 USD-',
               'sep=1 posn=2 prec=1'    => 'USD 9.9500-',
               'sep=1 posn=3 prec=0'    => '9.9500 -USD',
               'sep=1 posn=3 prec=1'    => '-USD 9.9500',
               'sep=1 posn=4 prec=0'    => '9.9500 USD-',
               'sep=1 posn=4 prec=1'    => 'USD- 9.9500',
               'sep=2 posn=0 prec=0'    => '(9.9500USD)',
               'sep=2 posn=0 prec=1'    => '(USD9.9500)',
               'sep=2 posn=1 prec=0'    => '- 9.9500USD',
               'sep=2 posn=1 prec=1'    => '- USD9.9500',
               'sep=2 posn=2 prec=0'    => '9.9500USD -',
               'sep=2 posn=2 prec=1'    => 'USD9.9500 -',
               'sep=2 posn=3 prec=0'    => '9.9500- USD',
               'sep=2 posn=3 prec=1'    => '- USD9.9500',
               'sep=2 posn=4 prec=0'    => '9.9500USD -',
               'sep=2 posn=4 prec=1'    => 'USD -9.9500'
              );

foreach my $sep (0..2)
{
    foreach my $posn (0..4)
    {
        foreach my $prec (0..1)
        {
            my $key = "sep=$sep posn=$posn prec=$prec";
            my $want = $results{$key};
            $usd->{n_cs_precedes} = $prec;
            $usd->{n_sign_posn} = $posn;
            $usd->{n_sep_by_space} = $sep;
            is($usd->format_price(-9.95), $want, "$key -> $want");
        }
    }
}


my %prices = ( 1234    => "EUR 1.234,00",
               56      => "EUR 56,00",
               75.2345 => "EUR 75,23",
               12578.5 => "EUR 12.578,50" );

my $nf = Number::Format->new(
                             -int_curr_symbol   => 'EUR',
                             -currency_symbol   => '$',
                             -decimal_point     => ',',
                             -frac_digits       => 2,
                             -int_frac_digits   => 2,
                             -n_cs_precedes     => 1,
                             -n_sep_by_space    => 1,
                             -n_sign_posn       => 1,
                             -negative_sign     => '-',
                             -p_cs_precedes     => 1,
                             -p_sep_by_space    => 1,
                             -p_sign_posn       => 1,
                             -positive_sign     => '',
                             -thousands_sep     => '.',
                             -mon_thousands_sep => '.',
                             -decimal_fill      => 1,
                             -decimal_digits    => 2,
                             -mon_decimal_point => ',',
                            );

for my $price ( sort keys %prices )
{
    my $want = $prices{$price};
    is($nf->format_price($price, 2), $want, "$price -> $want");
}

{
    my @warnings;
    local $SIG{__WARN__} = sub { @warnings = @_ };
    is($nf->format_price(undef), "EUR 0,00");
    my $file = __FILE__;
    like("@warnings",
         qr{Use of uninitialized value in call to Number::Format::format_price at \Q$file\E line \d+[.]?\n});
}
