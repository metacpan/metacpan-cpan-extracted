#!/usr/bin/perl
use strict;
use warnings;

use Test::More tests => 35;
use Test::Warn;

use String::CaseProfile qw(get_profile set_profile copy_profile);
#use Encode;
use utf8;

my @strings = (
                'Entorno de tiempo de ejecución',
                'è un linguaggio dinamico',
                'langages dérivés du C',
                "sil·labaris, l'altre sistema d'escriptura japonès",
                'dir-se-ia que era bom',
                'Cadena de prueba KT31',
                'identificador some_ID',
                'AC/DC strikes back',
                'vacaciones en EE.UU.'
              );

# encode strings as utf-8 -changed the encoding of the file to utf-8; step skipped
# my @samples = map { decode('iso-8859-1', $_) } @strings;
my @samples = @strings;

my $new_string;


# EXAMPLE 1: Get the profile of a string
my %profile = get_profile($samples[0]);

is($profile{string_type}, '1st_uc', 'First letter of first word is uppercase');
is(@{$profile{words}}, 5, 'String contains 5 words');
is($profile{words}[2]->{word}, 'tiempo', 'Third word is tiempo');
is($profile{words}[2]->{type}, 'all_lc', 'The type of the 3rd word is all_lc');

# Test the token recognition regex
%profile = get_profile($samples[3]);
is(@{$profile{words}}, 5, 'String contains 5 words');
is($profile{words}[0]->{word}, 'sil·labaris', 'First word is sil·labaris');

%profile = get_profile($samples[4]);
is(@{$profile{words}}, 4, 'String contains 4 words');
is($profile{words}[0]->{word}, 'dir-se-ia', 'First word is dir-se-ia');

%profile = get_profile($samples[5]);
is($profile{words}[3]->{word}, 'KT31', 'Fourth word is KT31');
is($profile{words}[3]->{type}, 'other', 'Type of KT31 is other');

%profile = get_profile($samples[6]);
is(@{$profile{words}}, 2, 'String contains 2 words');
is($profile{words}[1]->{word}, 'some_ID', 'Second word is some_ID');
is($profile{words}[1]->{type}, 'other', 'Type of some_ID is other');

# EXAMPLE 2: Get the profile of a string and apply it to another string
my $ref_string1 = 'REFERENCE STRING';
my $ref_string2 = 'Another reference string';

$new_string = set_profile($samples[1], get_profile($ref_string1));
is($new_string, 'È UN LINGUAGGIO DINAMICO', 'È UN LINGUAGGIO DINAMICO');

$new_string = set_profile($samples[1], get_profile($ref_string2));
is($new_string, 'È un linguaggio dinamico', 'È un linguaggio dinamico');

# Using the copy_profile function
$new_string = copy_profile(from => $ref_string1, to => $samples[1]);
is($new_string, 'È UN LINGUAGGIO DINAMICO', 'È UN LINGUAGGIO DINAMICO');

$new_string = copy_profile(from => $ref_string2, to => $samples[1]);
is($new_string, 'È un linguaggio dinamico', 'È un linguaggio dinamico');


# EXAMPLE 3: Change a string using several custom profiles
my %profile1 = ( string_type  => 'all_uc');
my %profile2 = ( string_type => 'all_lc', force_change => 1);
my %profile3 = (
                custom  => {
                            default => 'all_lc',
                            index   => { '1'  => 'all_uc' }, # 2nd word
                           }
                );
my %profile4 = ( custom => { 'all_lc' => '1st_uc' } );

$new_string = set_profile($samples[2], %profile1);
is($new_string, 'LANGAGES DÉRIVÉS DU C', 'LANGAGES DÉRIVÉS DU C');
    
$new_string = set_profile($samples[2], %profile2);
is($new_string, 'langages dérivés du c', 'langages dérivés du c');
    
$new_string = set_profile($samples[2], %profile3);
is($new_string, 'langages DÉRIVÉS du C', 'langages DÉRIVÉS du C');

$new_string = set_profile($samples[2], %profile4);
is($new_string, 'Langages Dérivés Du C', 'Langages Dérivés Du C');

# Validation tests
my %bad_profile1 = get_profile(1);
#warning_is  {
               $new_string = set_profile($samples[0], %bad_profile1);
#            }  "Illegal value of string_type", "Bad string type";

is($new_string, $samples[0], 'Unchanged string');

my %bad_profile2 = ( string_type => 'bad' );
warning_like  {
               $new_string = set_profile($samples[0], %bad_profile2);
              }  qr/Illegal value/, "Bad string type";
is($new_string, $samples[0], 'Unchanged string');

my %bad_profile3 = ( custom => {
                                index => { '7' => 'all_uc' },
                                default => 'bogus',
                           }
               );
warning_like  {
               $new_string = set_profile($samples[0], %bad_profile3);
            }  qr/Illegal default value/, "Illegal default value in custom profile";
is($new_string, $samples[0], 'Unchanged string');


# Single-letter strings

my @single = qw(a Ñ 1);
my @results = qw(all_lc all_uc other);

for (my $i = 0; $i<=$#single; $i++) {
    my %profile = get_profile($single[$i]);
    is(
       $profile{string_type},
       $results[$i],
       "Expected $results[$i], but $single[$i] is $profile{string_type}"
      ); 
}

# Acronyms
%profile = get_profile($samples[7]);

is(@{$profile{words}}, 3, 'String contains 3 words');
is($profile{words}[0]->{word}, 'AC/DC', 'First word is AC/DC');
is($profile{words}[0]->{type}, 'other', 'The type of the first word is other');

%profile = get_profile($samples[8]);

is(@{$profile{words}}, 3, 'String contains 3 words');
is($profile{words}[2]->{word}, 'EE.UU.', 'Third word is EE.UU.');
is($profile{words}[2]->{type}, 'other', 'The type of the third word is other');