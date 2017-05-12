#!/usr/bin/perl
use strict;
use warnings;

use Test::More tests => 11;

use String::CaseProfile qw(get_profile set_profile copy_profile);
use utf8;

binmode Test::More->builder->output, ":utf8";

my @samples = (
               'Ծրագրի հեղինակների ցանկը', # Armenian
               'Λίστα των συγγραφέων του προγράμματος', # Greek
               'Список авторов программы', # Russian
              );

my $new_string;


# EXAMPLE 1: Get the profile of a string
my %profile = get_profile($samples[0]);

is($profile{string_type}, '1st_uc', 'First letter of first word is uppercase');
is(@{$profile{words}}, 3, 'String contains 3 words');
is($profile{words}[2]->{word}, 'ցանկը', 'Third word is ցանկը');
is($profile{words}[2]->{type}, 'all_lc', 'The type of the 3rd word is all_lc');


# EXAMPLE 2: Get the profile of a string and apply it to another string
my $ref_string1 = 'REFERENCE STRING';
my $ref_string2 = 'another reference string';

$new_string = set_profile($samples[1], get_profile($ref_string1));
is($new_string, 'ΛΊΣΤΑ ΤΩΝ ΣΥΓΓΡΑΦΈΩΝ ΤΟΥ ΠΡΟΓΡΆΜΜΑΤΟΣ', 'all_uc');

$new_string = set_profile($samples[1], get_profile($ref_string2));
is($new_string, 'λίστα των συγγραφέων του προγράμματος', 'all_lc');

# Using the copy_profile function
$new_string = copy_profile(from => $ref_string1, to => $samples[1]);
is($new_string, 'ΛΊΣΤΑ ΤΩΝ ΣΥΓΓΡΑΦΈΩΝ ΤΟΥ ΠΡΟΓΡΆΜΜΑΤΟΣ', 'all_uc');

$new_string = copy_profile(from => $ref_string2, to => $samples[1]);
is($new_string, 'λίστα των συγγραφέων του προγράμματος', 'all_lc');


# EXAMPLE 3: Change a string using several custom profiles
my %profile1 = ( string_type  => 'all_uc');
my %profile2 = (
                custom  => {
                            default => 'all_lc',
                            index   => { '1'  => 'all_uc' }, # 2nd word
                           }
                );
my %profile3 = ( custom => { 'all_lc' => '1st_uc' } );

$new_string = set_profile($samples[2], %profile1);

is($new_string, 'СПИСОК АВТОРОВ ПРОГРАММЫ', 'all_uc');
    
$new_string = set_profile($samples[2], %profile2);
is($new_string, 'список АВТОРОВ программы', '2nd word => all_uc');
    
$new_string = set_profile($samples[2], %profile3);
is($new_string, 'Список Авторов Программы', 'all_lc => 1st_uc');
