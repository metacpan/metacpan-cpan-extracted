use Data::Dumper;		#  -*- perl -*-
use strict;
use Test::More tests => 10;
BEGIN { use_ok('Net::ThirtySevenSignals::Highrise') };

eval { Net::ThirtySevenSignals::Highrise->new };
ok($@);


SKIP: {
    skip 'HIGHRISE_TOKEN and HIGHRISE_USER must be set', 8
	unless $ENV{HIGHRISE_TOKEN} && $ENV{HIGHRISE_USER};


    eval { Net::ThirtySevenSignals::Highrise->new(user => $ENV{HIGHRISE_USER}) };
    ok($@);

    eval { Net::ThirtySevenSignals::Highrise->new(token => $ENV{HIGHRISE_TOKEN}) };
    ok($@);

    my $hr = Net::ThirtySevenSignals::Highrise->new(
	user  => $ENV{HIGHRISE_USER},
	token => $ENV{HIGHRISE_TOKEN},
	ssl => 1,
	);
    ok($hr);
    ok(ref $hr eq 'Net::ThirtySevenSignals::Highrise');
    my $res = $hr->people_list_all();
    note(" received ".scalar(@{$res})." people");
    # 7
    ok( @{ $res } > 1 );
    
    my $firstPerson = $res->[0];
    my $personID = $firstPerson->{id}[0]{content};
    
    my $taggyPersonID = '44406487';
    $personID = $taggyPersonID;
    
    my $tags4Person = $hr->tags_list_for_subject(subjectType=>'people',subjectID => $personID);
    # 8
    ok( @{$tags4Person} > 0);

    

    my $personRec = $hr->person_create(
	'firstName' => 'Joe',
	'lastName' => 'Tester',
	'emailAddress' =>'joe@example.com',
	'companyName' =>'Example Company',
	);
    my $newPersonID = $personRec->{id}[0]{content};
    
    my $newPerson = $hr->person_get(id=> $newPersonID);
    #9
    ok( $newPersonID && $newPerson, 'created personID with email');
    
    $hr->person_destroy(id => $newPersonID , xml=>1);

    $newPerson =undef;
    eval{
	$newPerson = $hr->person_get(id=> $newPersonID);
    };
    #10
    ok(!defined $newPerson, 'destroyed');


    # create with just phone
    $personRec = $hr->person_create(
	'firstName' => 'Joe',
	'lastName' => 'Tester',
	'companyName' =>'Example Company',
	'workPhone' =>'555-1212',
	);
    $newPersonID = $personRec->{id}[0]{content};
    $newPerson = $hr->person_get(id=> $newPersonID);
    #11
    ok( $newPersonID && $newPerson, 'created personID with phone');
    

    $hr->tag_add($newPerson, 'people', 'testing');
    my $tags = $hr->tags_list_for_subject(subjectType=> 'people',subjectID=>$newPersonID);
    ok ($tags, 'tags returned');
    ok (@$tags == 1, 'one tag');
    my $actualtag = $tags->[0]{name}[0];
    ok ($actualtag eq 'testing', "tag name incorrect : $actualtag");

    $hr->person_destroy(id => $newPersonID );
    
    skip ("no HIGHRISE_EMAIL set", 1)
	unless $ENV{HIGHRISE_EMAIL};
    if( $ENV{HIGHRISE_EMAIL} ){
	my $criteriaResults = $hr->people_list_by_criteria(email=> $ENV{HIGHRISE_EMAIL});
	# 12
	ok(('ARRAY' eq ref( $criteriaResults))&&  ( 1== @{$criteriaResults} ), "criteria fetch");
    }
    note("HI");

}
