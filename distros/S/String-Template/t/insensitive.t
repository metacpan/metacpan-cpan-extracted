use strict;
use warnings;
use Test::More tests => 9;
use String::Template;
use Time::Piece 1.17;

$ENV{TZ} = 'EST5EDT'; # override so test in local TZ will succeed

if($^O eq 'MSWin32') {
  # it would be nice to use POSIX for this
  # instead since that is a public interface
  # but of course Strawberry has borked it.
  Time::Piece::_tzset();
}

#########################

my %fields = ( num => 2, str => 'this', date => 'Feb 27, 2008' );

my $template = "...<num%04d>...<str>...<date:%Y/%m/%d>...\n";

my $correct = "...0002...this...2008/02/27...\n";

is( expand_stringi("<this> and <that> and <theother>", { this => 1, that => 2, theother => 3 }),"1 and 2 and 3");
is( expand_stringi("<This> and <that> and <TheotHer>", { this => 1, tHAT => 2, theother => 3 }),"1 and 2 and 3");
is( expand_stringi("<tHis> and <that> and <theother>", { this => 1, that => 2, theother => 3 }),"1 and 2 and 3");
is( expand_stringi("<THIS> and <THAT> and <TheOther>", { this => 1, That => 2, theother => 3 }),"1 and 2 and 3");
is( expand_stringi("<this> and <that> and <theother>", { this => 1, that => 2, TheOther => 3 }),"1 and 2 and 3");

is( expand_stringi('hi <date:%Y-%m-%d>', { date => 'May 17, 2008' } ), 'hi 2008-05-17' );


is (expand_stringi( 'local: <date:%Y-%m-%d %H:%M> utc: <date!%Y-%m-%d %H:%M>',
    { date => '2008-02-27T17:57:00Z' } ),
    'local: 2008-02-27 12:57 utc: 2008-02-27 17:57' );

is (expand_stringi( 'local: <date:%Y-%m-%d %H:%M> utc: <date!%Y-%m-%d %H:%M>',
    { Date => '2008-02-27T17:57:00Z' } ),
    'local: 2008-02-27 12:57 utc: 2008-02-27 17:57' );

is (expand_stringi( 'local: <dAte:%Y-%m-%d %H:%M> utc: <DATE!%Y-%m-%d %H:%M>',
    { daTE => '2008-02-27T17:57:00Z' } ),
    'local: 2008-02-27 12:57 utc: 2008-02-27 17:57' );
