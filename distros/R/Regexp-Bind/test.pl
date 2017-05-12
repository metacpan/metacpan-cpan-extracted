#use Test::More qw(no_plan);
use Test::More tests => 36;
use ExtUtils::testlib;
use Data::Dumper;
use Regexp::Bind qw(
		    bind global_bind
		    bind_array global_bind_array
		    );


$quotes =<<'.';
"Anyone can escape into sleep, we are all geniuses when we dream, the butcher's the poet's equal there."
-E. M. Cioran, The Tempation to Exist
"We all dream; we do not understand our dreams, yet we act as if nothing strange goes on in our sleep minds, strange at least by comparison with the logical, purposeful doings of our minds when we are awake."
-Erich Fromm, The Forgotten Language
"One of the most adventurous things left us is to go to bed. For no one can lay a hand on our dreams."
-E. V. Lucas, 365 Days and One More
.


$cnt = 0;
@fields = (
	   [ qw(quote author from) ],
	   );
foreach $template (qr'"(.+?)"\n-(.+?), (.+?)\n's,
		   qr'"(?#<quote>.+?)"\n-(?#<author>.+?), (?#<from>.+?)\n's,
		   ){

######################################################################
# Array binding
######################################################################

if($cnt==0){
    like((bind_array($quotes, $template))->[1], qr'M. Cior');
    like((global_bind_array($quotes, $template))[2]->[2], qr'365');
    like((bind_array(\$quotes, $template))->[1], qr'M. Cior');
    like((global_bind_array(\$quotes, $template))[2]->[2], qr'365');
}

######################################################################
# Use anonymous hash
######################################################################		   
$Regexp::Bind::USE_NAMED_VAR = 0;

$record = bind($quotes, $template, @{$fields[$cnt]});
is($record->{author}, 'E. M. Cioran');

$record = bind(\$quotes, $template, @{$fields[$cnt]});
is($record->{author}, 'E. M. Cioran');

@record = global_bind($quotes, $template, @{$fields[$cnt]});
is($record[0]->{from}, 'The Tempation to Exist');
is($record[1]->{author}, 'Erich Fromm');
like($record[2]->{quote}, qr'adventurous');

@record = global_bind(\$quotes, $template, @{$fields[$cnt]});
is($record[0]->{from}, 'The Tempation to Exist');
is($record[1]->{author}, 'Erich Fromm');
like($record[2]->{quote}, qr'adventurous');


######################################################################
# Use named variables
######################################################################
$Regexp::Bind::USE_NAMED_VAR = 1;
bind($quotes, $template, @{$fields[$cnt]});
like($quote, qr'dream');
like($author, qr'Cioran');
like($from, qr'Tempation');

bind(\$quotes, $template, @{$fields[$cnt]});
like($quote, qr'dream');
like($author, qr'Cioran');
like($from, qr'Tempation');

$cnt++;
}


$Regexp::Bind::USE_NAMED_VAR = 0;
$template = qr'"(?#<quote>{ s/\s//g, $_ }.+?)"\n-(?#<author>{s/.+/\L$&/,$_}.+?), (?#<from>.+?)\n's;

unlike(bind($quotes, $template)->{quote}, qr'\s');
like((global_bind($quotes, $template))[2]->{author}, qr'e. v. lucas');

unlike(bind(\$quotes, $template)->{quote}, qr'\s');
like((global_bind(\$quotes, $template))[2]->{author}, qr'e. v. lucas');


