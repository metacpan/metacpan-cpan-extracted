use strict;
use Test::More;

eval 'use Test::Exception';

if ($@) {
	plan (skip_all => 'Test::Exception not installed') ;
}


use Statistics::Multtest qw(:all);
# test check_prototype
eval q` lives_ok { bonferroni([0.01, 0.02, 0.5]) } `;
eval q` lives_ok { bonferroni({a => 0.01, b => 0.02, c => 0.5]) } `;
eval q` dies_ok { bonferroni(0.01, 0.02, 0.5) } `;
eval q` lives_ok { holm([0.01, 0.02, 0.5]) } `;
eval q` lives_ok { holm({a => 0.01, b => 0.02, c => 0.5]) } `;
eval q` dies_ok { holm(0.01, 0.02, 0.5) } `;
eval q` lives_ok { hommel([0.01, 0.02, 0.5]) } `;
eval q` lives_ok { hommel({a => 0.01, b => 0.02, c => 0.5]) } `;
eval q` dies_ok { hommel(0.01, 0.02, 0.5) } `;
eval q` lives_ok { hochberg([0.01, 0.02, 0.5]) } `;
eval q` lives_ok { hochberg({a => 0.01, b => 0.02, c => 0.5]) } `;
eval q` dies_ok { hochberg(0.01, 0.02, 0.5) } `;
eval q` lives_ok { BH([0.01, 0.02, 0.5]) } `;
eval q` lives_ok { BH({a => 0.01, b => 0.02, c => 0.5]) } `;
eval q` dies_ok { BH(0.01, 0.02, 0.5) } `;
eval q` lives_ok { BY([0.01, 0.02, 0.5]) } `;
eval q` lives_ok { BY({a => 0.01, b => 0.02, c => 0.5]) } `;
eval q` dies_ok { BY(0.01, 0.02, 0.5) } `;

eval q` dies_ok { bonferroni([0.01, 0.02, 1.5]) } `;
eval q` dies_ok { bonferroni([0.01, -0.02, 0.5]) } `;
eval q` dies_ok { bonferroni(0.01, 0.02, 0.5) } `;

done_testing();
