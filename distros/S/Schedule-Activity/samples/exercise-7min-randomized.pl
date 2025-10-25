#!/usr/bin/perl

use strict;
use warnings;
use Schedule::Activity;

print "This is a randomized 7-minute exercise schedule grouped by muscle group.\n";

my $scheduler=Schedule::Activity->new(
	unsafe=>1,
	configuration=>{node=>{

		'7min program'=>{
			message=>'Good luck!',
			tmmin=>0,tmavg=>0,tmmax=>0,
			next=>['cardio'],
			finish=>'conclude',
		},

		'arms'  =>{tmmin=>0,tmavg=>0,tmmax=>0, next=>['triceps dips on a chair']},
		'cardio'=>{tmmin=>0,tmavg=>0,tmmax=>0, next=>['jumping jacks','high knees running in place']},
		'chest' =>{tmmin=>0,tmavg=>0,tmmax=>0, next=>['push-ups','push-up with rotation']},
		'core'  =>{tmmin=>0,tmavg=>0,tmmax=>0, next=>['wall sit','abdominal crunches','plank','side plank']},
		'legs'  =>{tmmin=>0,tmavg=>0,tmmax=>0, next=>['step-ups on a chair','squats','lunges']},

		'arms done'  =>{tmmin=>4,tmavg=>5,tmmax=>6, message=>'5sec break',              next=>['core']},
		'cardio done'=>{tmmin=>4,tmavg=>5,tmmax=>6, message=>'Breath for five seconds', next=>['core','legs']},
		'chest done' =>{tmmin=>4,tmavg=>5,tmmax=>6, message=>'5sec break',              next=>['core']},
		'core done'  =>{tmmin=>4,tmavg=>5,tmmax=>6, message=>'Breath for five seconds', next=>['chest','legs','cardio','conclude']},
		'legs done'  =>{tmmin=>4,tmavg=>5,tmmax=>6, message=>'5sec break',              next=>['legs','arms','chest']},

		'triceps dips on a chair'    =>{tmmin=>25,tmavg=>30,tmmax=>40, next=>['arms done'],   message=>'Triceps Dips on a Chair'},
		'jumping jacks'              =>{tmmin=>25,tmavg=>30,tmmax=>40, next=>['cardio done'], message=>'Jumping Jacks'},
		'high knees running in place'=>{tmmin=>25,tmavg=>30,tmmax=>40, next=>['cardio done'], message=>'High Knees Running in Place'},
		'push-ups'                   =>{tmmin=>25,tmavg=>30,tmmax=>40, next=>['chest done'],  message=>'Push-ups'},
		'push-up with rotation'      =>{tmmin=>25,tmavg=>30,tmmax=>40, next=>['chest done'],  message=>'Push-up with Rotation'},
		'wall sit'                   =>{tmmin=>25,tmavg=>30,tmmax=>40, next=>['core done'],   message=>'Wall Sit'},
		'abdominal crunches'         =>{tmmin=>25,tmavg=>30,tmmax=>40, next=>['core done'],   message=>'Abdominal Crunches'},
		'plank'                      =>{tmmin=>25,tmavg=>30,tmmax=>40, next=>['core done'],   message=>'Plank'},
		'side plank'                 =>{tmmin=>25,tmavg=>30,tmmax=>40, next=>['core done'],   message=>'Side Plank'},
		'step-ups on a chair'        =>{tmmin=>25,tmavg=>30,tmmax=>40, next=>['legs done'],   message=>'Step-ups on a Chair'},
		'squats'                     =>{tmmin=>25,tmavg=>30,tmmax=>40, next=>['legs done'],   message=>'Squats'},
		'lunges'                     =>{tmmin=>25,tmavg=>30,tmmax=>40, next=>['legs done'],   message=>'Lunges'},

		conclude=>{
			message=>'You made it!',
			tmmin=>0,tmavg=>0,tmmax=>0,
		},
	}},
);

my %schedule=$scheduler->schedule(activities=>[[7*60,'7min program']]);

my @materialized;
foreach my $entry (@{$schedule{activities}}) {
	my $tm=int(0.5+$$entry[0]);
	if($$entry[1]{message}) {
		push @materialized,[
			sprintf('%02d:%02d:%02d'
				,int($tm/3600)
				,int(($tm%3600)/60)
				,($tm%60))
			,$$entry[1]{message}
		];
	}
}
foreach my $entry (@materialized) { print join(' ',@$entry),"\n" }

# Sample output

# This is a randomized 7-minute exercise schedule grouped by muscle group.
# 
# 00:00:00 Good luck!
# 00:00:00 Jumping Jacks
# 00:00:30 Breath for five seconds
# 00:00:35 Plank
# 00:01:05 Breath for five seconds
# 00:01:10 Push-up with Rotation
# 00:01:40 5sec break
# 00:01:45 Wall Sit
# 00:02:15 Breath for five seconds
# 00:02:20 Push-ups
# 00:02:50 5sec break
# 00:02:55 Side Plank
# 00:03:25 Breath for five seconds
# 00:03:30 Push-ups
# 00:04:00 5sec break
# 00:04:05 Wall Sit
# 00:04:35 Breath for five seconds
# 00:04:40 Push-up with Rotation
# 00:05:10 5sec break
# 00:05:15 Abdominal Crunches
# 00:05:45 Breath for five seconds
# 00:05:50 Push-up with Rotation
# 00:06:20 5sec break
# 00:06:25 Plank
# 00:06:55 Breath for five seconds
# 00:07:00 You made it!

