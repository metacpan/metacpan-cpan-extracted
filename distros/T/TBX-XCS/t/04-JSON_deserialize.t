#Check that XCS.pm creates proper structure from an XCS file
use strict;
use warnings;
use Test::More 0.88;
plan tests => 6;
use Test::NoWarnings;
use TBX::XCS::JSON qw(xcs_from_json);
use JSON;
my $json = '{
   "constraints" : {
      "refObjects" : {
         "Foo" : [
            "data"
         ]
      },
      "languages" : {
         "en" : "English",
         "fr" : "French",
         "de" : "German"
      },
      "datCatSet" : {
         "xref" : [
            {
               "name" : "xrefFoo",
               "targetType" : "external"
            }
         ],
         "termCompList" : [
            {
               "datCatId" : "ISO12620A-020802",
               "name" : "termElement",
               "forTermComp" : true
            }
         ],
         "descrip" : [
            {
               "levels" : [
                  "term"
               ],
               "datCatId" : "ISO12620A-0503",
               "name" : "context",
               "datatype" : "noteText"
            },
            {
               "levels" : [
                  "langSet",
                  "termEntry",
                  "term"
               ],
               "name" : "descripFoo",
               "datatype" : "noteText"
            }
         ],
         "termNote" : [
            {
               "forTermComp" : false,
               "datCatId" : "ISO12620A-020204",
               "name" : "animacy",
               "choices" : [
                  "animate",
                  "inanimate",
                  "otherAnimacy"
               ],
               "datatype" : "picklist"
            }
         ]
      }
   },
   "name" : "Small",
   "title" : "Example XCS file"
}';

my $xcs = xcs_from_json($json);

is_deeply(
    $xcs->get_languages(),
    {en => 'English', fr => 'French', 'de' => 'German'},
    'Languages'
) or note explain $xcs->get_languages();

is_deeply(
    $xcs->get_ref_objects(),
    { Foo => ['data'] },
    'Ref objects'
) or note explain $xcs->get_ref_objects();

is_deeply(
    $xcs->get_data_cats(),
    get_expected_data_cats(),
    'Data categories'
) or note explain $xcs->get_data_cats();

is($xcs->get_title, 'Example XCS file', 'Title');

is($xcs->get_name, 'Small', 'Name');

sub get_expected_data_cats {
    return
    {
      'descrip' =>
      [
        {
          'datatype' => 'noteText',
          'datCatId' => 'ISO12620A-0503',
          'levels' => ['term'],
          'name' => 'context'
        },
        {
          'datatype' => 'noteText',
          'levels' => ['langSet', 'termEntry', 'term'],
          'name' => 'descripFoo'
        }
      ],
  'termCompList' => [
    {
      'datCatId' => 'ISO12620A-020802',
      'name' => 'termElement',
      'forTermComp' => 'yes',
    }
  ],
      'termNote' => [{
          'choices' => ['animate', 'inanimate', 'otherAnimacy'],
          'datatype' => 'picklist',
          'datCatId' => 'ISO12620A-020204',
          'forTermComp' => 'no',
          'name' => 'animacy'
        }],
      'xref' => [{
          'datatype' => 'plainText',
          'name' => 'xrefFoo',
          'targetType' => 'external'
        }]
    };
}