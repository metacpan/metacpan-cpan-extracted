#!perl
use 5.006;
use strict;
use warnings;
use Test::More tests => 11;

#plan tests => 11;

BEGIN {
    use_ok( 'String::PictureFormat' ) || print "Bail out!\n";
}

diag( "Testing String::PictureFormat $String::PictureFormat::VERSION, Perl $], $^X" );

$SIG{__WARN__} = sub { };

sub foo {
	(my $data = shift) =~ tr/a-z/A-Z/;
	return $data;
}

$_ = fmt('@"...-..-...."', 123456789);
ok($_ eq '123-45-6789', "fmt() Int. => SSN. ('$_'=='123-45-6789')?");

$_ = unfmt('@"...-..-...."', '123-45-6789');
ok($_ == 123456789, "unfmt() SSN => Int. ($_==123456789)?");

$_ = fmt('@$,12.2>', 123456789);
ok($_ eq '    $123,456,789.00', "fmt() Int. to commatized w/floating dollar-sign ('$_'=='    $123,456,789.00')?");

$_ = fmtsiz('@$,12.2>');
ok($_ == 18, "fmtsiz() Size of commatized fmt. ($_==18)?");

$_ = fmt('@$,12.2> CR', -123456789);  
ok($_ eq '    $123,456,789.00 CR', "fmt() Neg. Int. => Accounting notation ('$_'=='    $123,456,789.00 CR')?");

$_ = fmt('@$(,12.2>)', -123456789);  
ok($_ eq '    $(123,456,789.00)', "fmt() Neg. Int. => Parenthesized ('$_'=='    $(123,456,789.00)')?");

$_ = fmt('=17<', 'Now is the time for all good men to come to the aid of their country');
ok(join('|',@{$_}) eq 'Now is the time   |for all good men  |to come to the aid|of their country  ', "fmt() Wrap by word to 16 chars. ('".join('|',@{$_})."'=='Now is the time   |for all good men  |to come to the aid|of their country  ')?");

$_ = fmt('@foo()', 'Now is the time for all');
ok($_ eq 'NOW IS THE TIME FOR ALL', "fmt() User-supplied function ('$_'=='NOW IS THE TIME FOR ALL')?");

$_ = fmt('@tr/aeiou/AEIOU/', 'Now is the time for all');
ok($_ eq 'NOw Is thE tImE fOr All', "fmt() Regular-expression ('$_'=='')?");
my $haveTime2fmtstr = 0;
eval 'use Date::Time2fmtstr; $haveTime2fmtstr = 1; 1'  unless ($haveTime2fmtstr);
$_ = fmt('@^yyyymmdd hh:mi:ss am (Day)^', '2015-01-07 11:23:45pm');
if ($haveTime2fmtstr) {
	diag "---------> Appears we have Date::Time2fmtstr installed, Awesome!";
	ok($_ eq '20150107 11:23:45 pm (Wed)', "fmt() UnixTime => Date string ('$_'=='20150107 11:23:45 pm (Wed)')?");
} else {
	diag "---------> Appears we do NOT have Date::Time2fmtstr installed, Bummer¡";
	ok($_ eq '20150107 23:23:45 am (Day)', "fmt() UnixTime => Date string ('$_'=='20150107 23:23:45 am (Day)')?");
}

#unless ($ENV{PERL_MM_USE_DEFAULT} || $ENV{AUTOMATED_TESTING}) {
#	is(&testitout(), 1, 'running Tk::JDialog sample program.');
#	diag( "Testing sample program useing String::PictureFormat." );
#}

__END__
