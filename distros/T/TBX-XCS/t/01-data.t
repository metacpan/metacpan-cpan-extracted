#Check that XCS.pm creates proper structure from an XCS file
use strict;
use warnings;
use Test::More 0.88;
plan tests => 11;
use Test::NoWarnings;
use TBX::XCS;
use Path::Tiny;
use FindBin qw($Bin);
use File::Slurp;

my $corpus_dir = path($Bin, 'corpus');
my $xcs_file = path($corpus_dir, 'small.xcs');
my $xcs_contents = read_file($xcs_file);

my $xcs = TBX::XCS->new();

test_xcs_data('file',$xcs_file);
test_xcs_data('string',\$xcs_contents);

#test languages, ref objects, and data categories
sub test_xcs_data {
    my ($type, $data) = @_;
    $xcs->parse($type=>$data);

    is_deeply(
        $xcs->get_languages(),
        {en => 'English', fr => 'French', 'de' => 'German'},
        "Languages extracted from $type"
    ) or note explain $xcs->get_languages();

    is_deeply(
        $xcs->get_ref_objects(),
        { Foo => ['data'] },
        "Ref objects extracted from $type"
    ) or note explain $xcs->get_ref_objects();

    is_deeply(
        $xcs->get_data_cats(),
        get_expected_data_cat(),
        "Data categories extracted from $type"
    ) or note explain $xcs->get_data_cats();

    is($xcs->get_title, 'Example XCS file',
        "Title extracted from $type");

    is($xcs->get_name, 'Small',
        "Name extracted from $type");
}

sub get_expected_data_cat {
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
      'forTermComp' => 'yes',
      'name' => 'termElement'
    }
  ],
      'termNote' => [{
          'choices' => ['animate', 'inanimate', 'otherAnimacy'],
          'datatype' => 'picklist',
          'datCatId' => 'ISO12620A-020204',
          'forTermComp' => 'yes',
          'name' => 'animacy'
        }],
      'xref' => [{
          'datatype' => 'plainText',
          'name' => 'xrefFoo',
          'targetType' => 'external'
        }]
    };
}

#TODO: test termCompList warnings; test datatype warnings