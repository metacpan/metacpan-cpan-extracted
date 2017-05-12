#!/usr/bin/perl -w

use strict;
use Test::More tests => 18;

use constant jiffie => 0.1;
use constant fudge => jiffie / 10;
use Time::HiRes qw(gettimeofday tv_interval);

BEGIN { use_ok("Profile::Log") };

my $double_check_start = [gettimeofday];
my $profiler = Profile::Log->new;

isa_ok($profiler, "Profile::Log", "new profiler");

$profiler->did("nothing");

select(undef, undef, undef, jiffie);

$profiler->did("sleep");

$profiler->mark("start");

select(undef, undef, undef, jiffie);

$profiler->did("snooze", "start");

select(undef, undef, undef, jiffie);

$profiler->did("slumber", "start");

select(undef, undef, undef, jiffie);

$profiler->did("snore");

select(undef, undef, undef, jiffie);

$profiler->did("yawn", "start");

use Data::Dumper;
#diag Dumper $profiler;

# unallocated time at the end of profile log
select(undef, undef, undef, jiffie);

my $result = $profiler->logline;

like($result, qr/^0=\d{2}:\d{2}:\d{2}\.\d{3}; tot=\d+\.\d{3}(; \S+=\d+\.\d{3})*$/,
     "output has desired form");

#diag($result);

$result =~ s{^.*?tot=\d+\.\d+; }{};

my %values = split /=|; /, $result;

about_ok($values{nothing}, 0, "timing - nothing");
about_ok($values{sleep}, jiffie, "timing - simple");
about_ok($values{'m0:start'}, 0, "set mark");
about_ok($values{'m0:snooze'}, jiffie, "mark relative");
about_ok($values{'m0:slumber'}, 2*jiffie, "mark relative - second");
about_ok($values{snore}, jiffie, "simple - mid-mark");
about_ok($values{'m0:yawn'}, 4*jiffie, "mark relative - mixed");

$profiler->tag(type => "Test");
$profiler->tag(ID => "2,12345");

$result = $profiler->logline;

like ($result, qr/^ID=2,12345; type=Test; 0=.*/,
      "profiler can accept and display arbitrary extra tags");

is($profiler->tag("type"), "Test", "retrieve tags with ->tag(...)");

#diag($result);

my $profiler_copy = Profile::Log->new($result);

is($profiler_copy->logline, $result,
   "Can re-construct Profiler objects from logline");

my $start_zero = $profiler_copy->zero;
my $start_end = $profiler_copy->end;

about_ok($start_end - $start_zero, 6*jiffie, "->zero and ->end");

my $slack = ( ($start_end - $start_zero)
	      - ($values{nothing} + $values{sleep} + $values{"m0:start"})
	      - $values{"m0:yawn"} );

about_ok($slack, jiffie, "slack adds up - sanity test");

# test iterator methods

my $all_iter = $profiler_copy->iter;
my @did;
do {
    push @did, $all_iter->("name");
} while ( $all_iter->("next") );

is_deeply(\@did, [ 0, qw(nothing sleep m0:start m0:snooze m0:slumber
			 snore m0:yawn Z) ],
	  "->iter() - basic test only");

my $marks = $profiler_copy->marks;
is_deeply($marks, [ 0, "start" ], "->marks()");

my @data;
for my $mark ( @$marks ) {
    my $iter = $profiler_copy->mark_iter($mark);

    do {
	push @data, do {
	    my $x = {( mark => $mark,
		       name => $iter->("name"),
		       start => $iter->("start"),
		       length => $iter->("length"),
		     )};
	    #diag("Got: ".Dumper($x));
	    $x;
	}
    } until not $iter->("next");
}

#diag("values: ".Dumper(\%values));
#diag("l: ".Dumper($profiler_copy->{t}));

my $m_start = $values{nothing}+$values{sleep}+$values{"m0:start"};
is_deeply(\@data,
	  [ # unmarked...
	   { mark=>0,name=>0,start=>0,length=>0 },
	   { mark=>0,name=>"nothing",start=>0,length=>$values{nothing}+0 },
	   { mark=>0,name=>"sleep",start=>$values{nothing}+0,length=>$values{sleep}+0 },
	   { mark=>0,name=>"snore",start=>$values{nothing}+$values{sleep}+$values{"m0:start"}+$values{"m0:slumber"},length=>$values{snore}+0 },
	   { mark=>0,name=>"Z",start=>$values{nothing}+$values{sleep}+$values{"m0:start"}+$values{"m0:yawn"},length=>scalar Profile::Log::getInterval($slack) },
	   # relative marks
	   { mark=>"start",name=>"start",start=>$m_start,length=>0 },
	   { mark=>"start",name=>"snooze",start=>$m_start,length=>$values{"m0:snooze"}+0 },
	   { mark=>"start",name=>"slumber",start=>$m_start,length=>$values{"m0:slumber"}+0 },
	   { mark=>"start",name=>"yawn",start=>$m_start,length=>$values{"m0:yawn"}+0 },
	  ],
	  "->iter()");

sub about_ok {
    my $value = shift;
    my $wanted = shift;
    my $mess = shift;
    cmp_ok(abs($value - $wanted), "<=", fudge, $mess);
}
