#!/usr/bin/perl
#Copyright 2007-8 Arthur S Goldstein
use Test::More tests => 3;
BEGIN { use_ok('Parse::Stallion::CSV') };

my $csv_stallion = new Parse::Stallion::CSV;
my $result;

my $file =<<EOL;
abc,add,eff
jff,slk,lwer
lkwer,fsjk,sdf
EOL

$result = $csv_stallion->parse_and_evaluate($file);

is_deeply($result,
{
header => ['abc','add','eff'],
records =>
 [
          [
            'jff',
            'slk',
            'lwer'
          ],
          [
            'lkwer',
            'fsjk',
            'sdf'
          ]
        ]
}
, 'parse and evaluate csv');

$file =<<EOL;
"abc sdf, sdf",add,eff
jff,"slk,lwer,sd
sdfkl,sdf,sdf,sdf",ke
lkwer,fsjk,sdf
EOL
$result = $csv_stallion->parse_and_evaluate($file);

is_deeply (
$result,
{
          'records' => [
                         [
                           'jff',
                           'slk,lwer,sd
sdfkl,sdf,sdf,sdf',
                           'ke'
                         ],
                         [
                           'lkwer',
                           'fsjk',
                           'sdf'
                         ]
                       ],
          'header' => [
                        'abc sdf, sdf',
                        'add',
                        'eff'
                      ]
        },
'split line record');




print "\nAll done\n";


