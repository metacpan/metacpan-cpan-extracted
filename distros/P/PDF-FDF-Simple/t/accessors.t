### -*- mode: perl; -*-

use strict;
use warnings;

use Test::More;
use PDF::FDF::Simple;

plan tests => 76;

################## tests ###################

# Test accessors before and after migration
# from Class::MethodMaker to Class::Accessor

############################################

# 'skip_undefined_fields',
# 'filename',
# 'content',
# 'errmsg',
# 'parser',
# 'attribute_file',
# 'attribute_ufile',
# 'attribute_id',

my $fdf = new PDF::FDF::Simple;

# direct set/get

my $value;

$value = 'lk436535lk24';
$fdf->skip_undefined_fields( $value );
is( $fdf->skip_undefined_fields,   $value, 'skip_undefined_fields - get');
is( $fdf->{skip_undefined_fields}, $value, 'skip_undefined_fields - hash elem');
$fdf->skip_undefined_fields( 0 );
is( $fdf->skip_undefined_fields,   0, 'skip_undefined_fields - get');
is( $fdf->{skip_undefined_fields}, 0, 'skip_undefined_fields - hash elem');
$fdf->skip_undefined_fields( 1 );
is( $fdf->skip_undefined_fields,   1, 'skip_undefined_fields - get');
is( $fdf->{skip_undefined_fields}, 1, 'skip_undefined_fields - hash elem');

$value = 'a43535hjg12321';
$fdf->filename( $value );
is( $fdf->filename, $value,   'filename - get');
is( $fdf->{filename}, $value, 'filename - hash elem');

$value = 'ze324j45kj87546324j';
$fdf->content( $value );
is( $fdf->content, $value,   'content - get');
is( $fdf->{content}, $value, 'content - hash elem');

my $values = {
              '0'                   => '0',
              'ze324j45kj87546324j' => 'hjjtzjtzjtr1231',
              'lkjhfew34lkjwelkjrh' => 'wqldkqwe2121321',
              'ohgp3242pj32r32rm23' => '21edewfewfewfew',
             };
$fdf->content( $values );
is_deeply( $fdf->content,   $values, 'content - get');
is_deeply( $fdf->{content}, $values, 'content - hash elem');

$value = 'asd324lk23j42';
$fdf->errmsg( $value );
is( $fdf->errmsg, $value,   'errmsg - get');
is( $fdf->{errmsg}, $value, 'errmsg - hash elem');

$value = 'l4kzttrz345lkj324';
$fdf->parser( $value );
is( $fdf->parser, $value,   'parser - get');
is( $fdf->{parser}, $value, 'parser - hash elem');

my $obj = new PDF::FDF::Simple();
$fdf->parser( $obj );
is_deeply( $fdf->parser, $obj,   'parser - get');
is_deeply( $fdf->{parser}, $obj, 'parser - hash elem');

$value = 'g827f8j0q8xynm8';
$fdf->attribute_file( $value );
is( $fdf->attribute_file, $value,   'attribute_file - get');
is( $fdf->{attribute_file}, $value, 'attribute_file - hash elem');

$value = 'lpqw3pl23mn632422';
$fdf->attribute_ufile( $value );
is( $fdf->attribute_ufile, $value,   'attribute_ufile - get');
is( $fdf->{attribute_ufile}, $value, 'attribute_ufile - hash elem');

$value = 'aqlp43mnyx6ekjhwqd2';
$fdf->attribute_id( $value );
is( $fdf->attribute_id, $value,   'attribute_id - get');
is( $fdf->{attribute_id}, $value, 'attribute_id - hash elem');


# at construction
my %initvalues = (
                  'skip_undefined_fields' => 'gregref2134',
                  'filename'              => 'khdsfsdfs764eq',
                  'content'               => 'qwnmeqwe1112wbd',
                  'errmsg'                => 'nmb1231mnb23mnb',
                  'parser'                => 'qyoijsd2131idop',
                  'attribute_file'        => 'po45po1p32o1',
                  'attribute_ufile'       => 'qewqdwqmdnwqdq12',
                  'attribute_id'          => 'qwqmnbyo211',
                 );
# new with hashref
$fdf = new PDF::FDF::Simple(\%initvalues);
is( $fdf->skip_undefined_fields, $initvalues{skip_undefined_fields}, 'skip_undefined_fields - constructor 1');
is( $fdf->content, $initvalues{content}, 'content - constructor 1');
is( $fdf->errmsg, $initvalues{errmsg}, 'errmsg - constructor 1');
is( $fdf->attribute_file, $initvalues{attribute_file}, 'attribute_file - constructor 1');
is( $fdf->attribute_ufile, $initvalues{attribute_ufile}, 'attribute_ufile - constructor 1');
is( $fdf->attribute_id, $initvalues{attribute_id}, 'attribute_id - constructor 1');

# parser is internally a P::RD instance
foreach (grep {$_ ne 'parser'} sort keys %initvalues) {
    is( $fdf->{$_}, $initvalues{$_}, "$_ - constructor hash elem 1");
}

my %initvalues2 = (
                   'skip_undefined_fields' => 'gregef213r421321',
                   'filename'              => 'kdsfsdfs76h214eq',
                   'content'               => 'qnmewqwe1121321wbd',
                   'errmsg'                => 'mb1231m213nnb23mnb',
                   'parser'                => 'yoiq123sjd213i1dop',
                   'attribute_file'        => 'o13245popp1231o',
                   'attribute_ufile'       => 'ewqdqwmqdnwdqgq12',
                   'attribute_id'          => 'wqmnqybewgtreo211',
                  );
# new with hash
$fdf = new PDF::FDF::Simple(%initvalues2);
is( $fdf->skip_undefined_fields, $initvalues2{skip_undefined_fields}, 'skip_undefined_fields - constructor 2');
is( $fdf->content, $initvalues2{content}, 'content - constructor 2');
is( $fdf->errmsg, $initvalues2{errmsg}, 'errmsg - constructor 2');
is( $fdf->attribute_file, $initvalues2{attribute_file}, 'attribute_file - constructor 2');
is( $fdf->attribute_ufile, $initvalues2{attribute_ufile}, 'attribute_ufile - constructor 2');
is( $fdf->attribute_id, $initvalues2{attribute_id}, 'attribute_id - constructor 2');

# parser is internally a P::RD instance
foreach (grep {$_ ne 'parser'} sort keys %initvalues2) {
    is( $fdf->{$_}, $initvalues2{$_}, "$_ - constructor hash elem 2");
}

# with inheritance

package PDF::FDF::Simple::Inherited;
use base 'PDF::FDF::Simple';

package main;

# new with hashref
my %initvalues3 = (
                   'skip_undefined_fields' => 'gregef213r421321',
                   'filename'              => 'kdsfsdfs76h214eq',
                   'content'               => 'qnmewqwe1121321wbd',
                   'errmsg'                => 'mb1231m213nnb23mnb',
                   'parser'                => 'yoiq123sjd213i1dop',
                   'attribute_file'        => 'o13245popp1231o',
                   'attribute_ufile'       => 'ewqdqwmqdnwdqgq12',
                   'attribute_id'          => 'wqmnqybewgtreo211',
                  );
$fdf = new PDF::FDF::Simple::Inherited(\%initvalues3);
is( $fdf->skip_undefined_fields, $initvalues3{skip_undefined_fields}, 'skip_undefined_fields - constructor inherited 3');
is( $fdf->content, $initvalues3{content}, 'content - constructor inherited 3');
is( $fdf->errmsg, $initvalues3{errmsg}, 'errmsg - constructor inherited 3');
is( $fdf->attribute_file, $initvalues3{attribute_file}, 'attribute_file - constructor inherited 3');
is( $fdf->attribute_ufile, $initvalues3{attribute_ufile}, 'attribute_ufile - constructor inherited 3');
is( $fdf->attribute_id, $initvalues3{attribute_id}, 'attribute_id - constructor inherited 3');

# parser is internally a P::RD instance
foreach (grep {$_ ne 'parser'} sort keys %initvalues3) {
    is( $fdf->{$_}, $initvalues3{$_}, "$_ - constructor hash elem inherited 3");
}

# new with hash
my %initvalues4 = (
                   'skip_undefined_fields' => 'ergregef213r421321',
                   'filename'              => 'kdewsfsdfs76h214eq',
                   'content'               => 'qnmeadswqwe1121321wbd',
                   'errmsg'                => 'mb1231mdfsad213nnb23mnb',
                   'parser'                => 'yoiq123asdsjd213i1dop',
                   'attribute_file'        => 'o13245popp45h1231o',
                   'attribute_ufile'       => 'ewqdqwmqdnwdaw4w2qgq12',
                   'attribute_id'          => 'g43gwqmnqybewgtreo211',
                  );
$fdf = new PDF::FDF::Simple::Inherited(%initvalues4);
is( $fdf->skip_undefined_fields, $initvalues4{skip_undefined_fields}, 'skip_undefined_fields - constructor inherited 4');
is( $fdf->content, $initvalues4{content}, 'content - constructor inherited 4');
is( $fdf->errmsg, $initvalues4{errmsg}, 'errmsg - constructor inherited 4');
is( $fdf->attribute_file, $initvalues4{attribute_file}, 'attribute_file - constructor inherited 4');
is( $fdf->attribute_ufile, $initvalues4{attribute_ufile}, 'attribute_ufile - constructor inherited 4');
is( $fdf->attribute_id, $initvalues4{attribute_id}, 'attribute_id - constructor inherited 4');

# parser is internally a P::RD instance
foreach (grep {$_ ne 'parser'} sort keys %initvalues4) {
    is( $fdf->{$_}, $initvalues4{$_}, "$_ - constructor hash elem inherited 4");
}

