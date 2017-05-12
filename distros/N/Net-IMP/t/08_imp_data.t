use strict;
use warnings;
use Test::More;

# check IMP_DATA function
plan tests => 4;

{
    package myInterface;
    use Net::IMP 'IMP_DATA';
    use Exporter 'import';
    our @EXPORT = IMP_DATA('smtp',
	'greeting' => +1,
	'command'  => +2,
	'response' => +3,
	'header'   => +4,
	'content'  => -5, # stream
    );
}

myInterface->import;

ok( IMP_DATA_SMTP() eq 'imp.data.smtp' );
ok( IMP_DATA_SMTP() == 25 << 16 );
ok( IMP_DATA_SMTP_CONTENT() eq 'imp.data.smtp.content' );
ok( IMP_DATA_SMTP_CONTENT() == -( ( 25 << 16 ) + 5 ) );
