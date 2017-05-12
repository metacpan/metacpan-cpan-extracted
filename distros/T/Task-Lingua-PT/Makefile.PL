use inc::Module::Install;

name     'Task-Lingua-PT';
all_from 'lib/Task/Lingua/PT.pm';
author   q{Alberto Simoes <ambs@perl.pt>};
license  'perl';

build_requires 'Test::More';


requires 'Text::Ngram'             => '0.13';
requires 'Text::WordGrams'         => '0.04';
requires 'Text::Affixes'           => '0.07';
requires 'Lingua::Identify'        => '0.27';
requires 'Lingua::PT::Abbrev'      => '0.07';
requires 'Lingua::PT::Conjugate'   => '1.17';
requires 'Lingua::PT::Hyphenate'   => '1.05';
requires 'Lingua::PT::Inflect'     => '0.06';
requires 'Lingua::PT::Nums2Ords'   => '0.07';
requires 'Lingua::PT::Nums2Words'  => '1.06';
requires 'Lingua::PT::Ords2Nums'   => '0.07';
requires 'Lingua::PT::PLNbase'     => '0.21';
requires 'Lingua::PT::PLN'         => '0.17';
requires 'Lingua::PT::ProperNames' => '0.09';
requires 'Lingua::PT::Words2Nums'  => '1.04';
requires 'Lingua::PT::Speaker'     => '0.10';
requires 'Lingua::Jspell'          => '1.69';

WriteAll;

