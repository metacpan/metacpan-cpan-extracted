#!/usr/bin/perl
use strict;
use warnings;
use Net::Amazon::MechanicalTurk;
use Net::Amazon::MechanicalTurk::Constants qw{ %QUALIFICATION_TYPE_IDS };
use Net::Amazon::MechanicalTurk::IOUtil;

#
# This sample creates a hit with a locale qualification.
#

my $mturk = Net::Amazon::MechanicalTurk->new;

my $question = Net::Amazon::MechanicalTurk::IOUtil->readContents(
    "simple_survey.question"
);

# Creates a HIT with a qualification that
# the user must be in the US.

my $hit = $mturk->CreateHIT(
    Title => "What is your political preference?",
    Description => "This is a simple survey HIT created by MTurk SDK.",
    Question => $question,
    Reward => { Amount => 0, CurrencyCode => 'USD' },
    AssignmentDurationInSeconds => 60 * 60,
    AutoApprovalDelayInSeconds => 60 * 60,
    LifetimeInSeconds => 60 * 60,
    MaxAssignments => 1,
    RequesterAnnotation => "sample#survey",
    QualificationRequirement => {
        QualificationTypeId => $QUALIFICATION_TYPE_IDS{'Worker_Locale'},
        Comparator => 'EqualTo',
        LocaleValue => { Country => 'US' }
    }
);

# Retrieve the hit again just to show how its done.
my $hitId = $hit->{HITId}[0];
my $hit2 = $mturk->GetHIT( HITId => $hitId );

# Dump the hit
print $hit2->toString, "\n";

