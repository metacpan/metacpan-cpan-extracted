#!/usr/bin/env perl
use strict;
use warnings;

use Test::More;

my %tests = (
    KJV => {
        description => 'King James Version (1769) with Strongs Numbers and Morphology',
        type => 'Biblical Texts',
        keys => {
            'John 3:16' => "\nFor God so loved the world, that he gave his only begotten Son, that whosoever believeth in him should not perish, but have everlasting life.\n",
        },
    },
    ESV => {
        description => 'English Standard Version',
        type => 'Biblical Texts',
        keys => {
            'John 3:16' => "\nFor  (Rom. 5:8; Eph. 2:4; 2 Thess. 2:16; 1 John 3:1; 4:9, 10)God so loved  (See ch. 1:29)the world,  (Rom. 8:32)that he gave his only Son, that whoever believes in him should not  (ch. 10:28)perish but have eternal life.",
        },
    },
    WebstersDict => {
        description => q[Webster's Revised Unabridged Dictionary of the English Language 1913],
        type => 'Lexicons / Dictionaries',
        keys => {
            'test' => q{Test /Test/ (?), n. [OE. test test, or cupel, potsherd, F. têt, from L. testum an earthen vessel; akin to testa a piece of burned clay, an earthen pot, a potsherd, perhaps for tersta, and akin to torrere to patch, terra earth (cf. Thirst, and Terrace), but cf. Zend tasta cup. Cf. Test a shell, Testaceous, Tester a covering, a coin, Testy, Tête-à- tête.] 1. (Metal.) A cupel or cupelling hearth in which precious metals are melted for trial and refinement. Our ingots, tests, and many mo. Chaucer. 2. Examination or trial by the cupel; hence, any critical examination or decisive trial; as, to put a man's assertions to a test. "Bring me to the test." Shak. 3. Means of trial; as, absence is a test of love. Each test every light her muse will bear. Dryden. 4. That with which anything is compared for proof of its genuineness; a touchstone; a standard. Life, force, and beauty must to all impart, At once the source, and end, and test of art. Pope. 5. Discriminative characteristic; standard of judgment; ground of admission or exclusion. Our test excludes your tribe from benefit. Dryden. 6. Judgment; distinction; discrimination. Who would excel, when few can make a test Betwixt indifferent writing and the best? Dryden. 7. (Chem.) A reaction employed to recognize or distinguish any particular substance or constituent of a compound, as the production of some characteristic precipitate; also, the reagent employed to produce such reaction; thus, the ordinary test for sulphuric acid is the production of a white insoluble precipitate of barium sulphate by means of some soluble barium salt. Test act (Eng. Law), an act of the English Parliament prescribing a form of oath and declaration against transubstantiation, which all officers, civil and military, were formerly obliged to take within six months after their admission to office. They were obliged also to receive the sacrament according to the usage of the Church of England. Blackstone. -- Test object (Optics), an object which tests the power or quality of a microscope or telescope, by requiring a certain degree of excellence in the instrument to determine its existence or its peculiar texture or markings. -- Test paper. (a) (Chem.) Paper prepared for use in testing for certain substances by being saturated with a reagent which changes color in some specific way when acted upon by those substances; thus, litmus paper is turned red by acids, and blue by alkalies, turmeric paper is turned brown by alkalies, etc. (b) (Law) An instrument admitted as a standard or comparison of handwriting in those jurisdictions in which comparison of hands is permitted as a mode of proving handwriting. -- Test tube. (Chem.) (a) A simple tube of thin glass, closed at one end, for heating solutions and for performing ordinary reactions. (b) A graduated tube. Syn. -- Criterion; standard; experience; proof; experiment; trial. -- Test, Trial. Trial is the wider term; test is a searching and decisive trial. It is derived from the Latin testa (earthen pot), which term was early applied to the fining pot, or crucible, in which metals are melted for trial and refinement. Hence the peculiar force of the word, as indicating a trial or criterion of the most decisive kind. I leave him to your gracious acceptance, whose trial shall better publish his commediation. Shak. Thy virtue, prince, has stood the test of fortune, Like purest gold, that tortured in the furnace, Comes out more bright, and brings forth all its weight. Addison. Test /Test/, v. t. [imp. & p. p. Tested; p. pr. & vb. n. Testing.] 1. (Metal.) To refine, as gold or silver, in a test, or cupel; to subject to cupellation. 2. To put to the proof; to prove the truth, genuineness, or quality of by experiment, or by some principle or standard; to try; as, to test the soundness of a principle; to test the validity of an argument. Experience is the surest standard by which to test the real tendency of the existing constitution. Washington. 3. (Chem.) To examine or try, as by the use of some reagent; as, to test a solution by litmus paper. Test /Test/ (?), n. [L. testis. Cf. Testament, Testify.] A witness. [Obs.] Prelates and great lords of England, who were for the more surety tests of that deed. Ld. Berners. Test /Test/, v. i. [L. testari. See Testament.] To make a testament, or will. [Obs.] { Test /Test/ (?), Testa /‖Tes´ta/ (?), } n. ; pl. E. Tests (#), L. Testæ (#). [L. testa a piece of burned clay, a broken piece of earthenware, a shell. See Test a cupel.] 1. (Zoöl.) The external hard or firm covering of many invertebrate animals. ☞ The test of crustaceans and insects is composed largely of chitin; in mollusks it is composed chiefly of calcium carbonate, and is called the shell. 2. (Bot.) The outer integument of a seed; the episperm, or spermoderm. },
        },
    },
);

# This is very non-Perlish... I am ashamed... :-/
my $total_tests = 0;
my %subtotal_tests;
for my $module (keys %tests) {
    $subtotal_tests{$module} = 3;

    for my $key (keys %{ $tests{$module}{keys} }) {
        $subtotal_tests{$module} += 2;
    }

    $total_tests += $subtotal_tests{$module};
}
plan tests => 2 + $total_tests;

use_ok('Sword::Manager');
use_ok('Sword::Module');

my $library = Sword::Manager->new;
#diag explain $library;

my $modules = $library->modules;
#diag explain $modules;

for my $name (keys %tests) {
    SKIP: {
        skip "$name is not in your Sword library", $subtotal_tests{$name}
            unless grep { $_->name eq $name } @$modules;

        my $module = $library->get_module($name);
        #diag explain $module;

        my $description = $tests{$name}{description};
        my $type        = $tests{$name}{type};

        #diag "NAME = ", $module->name;
        #diag "DESCRIPTION = ", $module->description;
        #diag "TYPE = ", $module->type;

        is($module->name, $name, "name of $name checks out");
        is($module->description, $description, "description of $name checks out");
        is($module->type, $type, "name of $name checks out");

        for my $key (keys %{ $tests{$name}{keys} }) {
            $module->set_key($key);
            my $text = $module->render_text;

            #diag $text;

            is($text, $tests{$name}{keys}{$key}, 
                "lookup $key in $name checks out");

            my $plain_text = $module->strip_text;
            is ($text, $tests{$name}{keys}{$key},
                "lookup $key in $name checks out stripped");
        }
    }
}
