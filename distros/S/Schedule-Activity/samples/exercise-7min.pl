#!/usr/bin/perl

use strict;
use warnings;
use Schedule::Activity;

print "This is an entirely-linear 7-minute exercise list.\n";
print "Note that no messages are provided for rest periods in this example.\n\n";

my %schedule=Schedule::Activity::buildSchedule(
	activities=>[[7*60,'7min program']],
	configuration=>{node=>{
		'7min program'=>{
			message=>'Good luck!',
			tmmin=>0,tmavg=>0,tmmax=>0,
			next=>['jumping jacks'],
			finish=>'conclude',
		},
		'jumping jacks'=>{
			message=>'Jumping Jacks',
			tmmin=>20,tmavg=>30,tmmax=>40,
			next=>['wall sit'],
		},
		'wall sit'=>{
			message=>'Wall Sit',
			tmmin=>20,tmavg=>30,tmmax=>40,
			next=>['push-ups'],
		},
		'push-ups'=>{
			message=>'Push-ups',
			tmmin=>20,tmavg=>30,tmmax=>40,
			next=>['abdominal crunches'],
		},
		'abdominal crunches'=>{
			message=>'Abdominal Crunches',
			tmmin=>20,tmavg=>30,tmmax=>40,
			next=>['step-ups on a chair'],
		},
		'step-ups on a chair'=>{
			message=>'Step-ups on a Chair',
			tmmin=>20,tmavg=>30,tmmax=>40,
			next=>['squats'],
		},
		'squats'=>{
			message=>'Squats',
			tmmin=>20,tmavg=>30,tmmax=>40,
			next=>['triceps dips on a chair'],
		},
		'triceps dips on a chair'=>{
			message=>'Triceps Dips on a Chair',
			tmmin=>20,tmavg=>30,tmmax=>40,
			next=>['plank'],
		},
		'plank'=>{
			message=>'Plank',
			tmmin=>20,tmavg=>30,tmmax=>40,
			next=>['high knees running in place'],
		},
		'high knees running in place'=>{
			message=>'High Knees Running in Place',
			tmmin=>20,tmavg=>30,tmmax=>40,
			next=>['lunges'],
		},
		'lunges'=>{
			message=>'Lunges',
			tmmin=>20,tmavg=>30,tmmax=>40,
			next=>['push-up with rotation'],
		},
		'push-up with rotation'=>{
			message=>'Push-up with Rotation',
			tmmin=>20,tmavg=>30,tmmax=>40,
			next=>['side plank'],
		},
		'side plank'=>{
			message=>'Side Plank',
			tmmin=>20,tmavg=>30,tmmax=>40,
			next=>['conclude'],
		},
		conclude=>{
			message=>'You made it!',
			tmmin=>0,tmavg=>0,tmmax=>0,
		},
	}},
);

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

