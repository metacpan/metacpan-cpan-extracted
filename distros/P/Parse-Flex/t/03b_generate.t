use Test::More (no_plan);
use Parse::Flex::Generate;

#plan tests => 3;

my $dir       =  ( $0 =~ m!^t/!) ? 't' : '.';
$dir eq 't' and chdir 't' ;

my $grammar   =  "default.l";
my $makelexer =  "../script/makelexer.pl";


-f $grammar   or die "$grammar $!";
-e $makelexer or die "$makelexer $!";


eval 'use Test::Exception';  

SKIP: {
	skip 'no Test::Exception', 2  if  $@;

	lives_ok( sub{check_argv   qq( Flex5  $grammar ) },  'check_argv');
	dies_ok(  sub{ check_argv  qw( Flex5  none     ) }, '');
}
is   undef, check_argv  qw( Flex5  ) ;

