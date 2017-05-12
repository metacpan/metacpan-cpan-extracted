use lib 'lib';

use Test::More qw( no_plan );

use Data::Dumper;
use strict;
use English;

use Statistics::Test::WilcoxonRankSum;

my $wilcox_test = Statistics::Test::WilcoxonRankSum->new();

my $expected_exception = q(Please set/load datasets before computing ranks);
eval {
  $wilcox_test->compute_ranks();
};

ok ($EVAL_ERROR =~ m{$expected_exception}ms, "Exception when trying to compute ranks wo datasets");

my @dataset_1 = qw(12 15 18 24 88);
my @dataset_2 = qw(3 3 13 27 33);

$wilcox_test->load_data(\@dataset_1, \@dataset_2);

my $ranks = $wilcox_test->compute_ranks();

my $expected_ranks = {
                      '27' => {
                               'tied' => 1,
                               'in_dataset' => {
                                                'ds2' => 1
                                               },
                               'rank' => '8'
                              },
                      '33' => {
                               'tied' => 1,
                               'in_dataset' => {
                                                'ds2' => 1
                                               },
                               'rank' => '9'
                              },
                      '88' => {
                               'tied' => 1,
                               'in_dataset' => {
                                                'ds1' => 1
                                               },
                               'rank' => '10'
                              },
                      '18' => {
                               'tied' => 1,
                               'in_dataset' => {
                                                'ds1' => 1
                                               },
                               'rank' => '6'
                              },
                      '3' => {
                              'tied' => 2,
                              'in_dataset' => {
                                               'ds2' => 2
                                              },
                              'rank' => '1.5'
                             },
                      '24' => {
                               'tied' => 1,
                               'in_dataset' => {
                                                'ds1' => 1
                                               },
                               'rank' => '7'
                              },
                      '13' => {
                               'tied' => 1,
                               'in_dataset' => {
                                                'ds2' => 1
                                               },
                               'rank' => '4'
                              },
                      '12' => {
                               'tied' => 1,
                               'in_dataset' => {
                                                'ds1' => 1
                                               },
                               'rank' => '3'
                              },
                      '15' => {
                               'tied' => 1,
                               'in_dataset' => {
                                                'ds1' => 1
                                               },
                               'rank' => '5'
                              }
                     };

is_deeply($ranks, $expected_ranks, "Ranks hash");


my $expected_ranks_array = [
                      [
                       '1.5',
                       'ds2'
                      ],
                      [
                       '1.5',
                       'ds2'
                      ],
                      [
                       '3',
                       'ds1'
                      ],
                      [
                       '4',
                       'ds2'
                      ],
                      [
                       '5',
                       'ds1'
                      ],
                      [
                       '6',
                       'ds1'
                      ],
                      [
                       '7',
                       'ds1'
                      ],
                      [
                       '8',
                       'ds2'
                      ],
                      [
                       '9',
                       'ds2'
                      ],
                      [
                       '10',
                       'ds1'
                      ]
                     ];

my @ranks = $wilcox_test->compute_rank_array();

is_deeply(\@ranks, $expected_ranks_array, "Ranks array");

my $expected_obs_nbr = 10;
my $number_of_obs = $wilcox_test->compute_rank_array();

ok($number_of_obs==$expected_obs_nbr, "Overall number of observations");


@dataset_1 = qw(45 50 61 63 75 85 93);
@dataset_2 = qw(44 45 52 53 56 58 58 65 79);

$wilcox_test->load_data(\@dataset_1, \@dataset_2);

$ranks = $wilcox_test->compute_ranks();

$expected_ranks = {
          '50' => {
                    'tied' => 1,
                    'in_dataset' => {
                                      'ds1' => 1
                                    },
                    'rank' => '4'
                  },
          '53' => {
                    'tied' => 1,
                    'in_dataset' => {
                                      'ds2' => 1
                                    },
                    'rank' => '6'
                  },
          '85' => {
                    'tied' => 1,
                    'in_dataset' => {
                                      'ds1' => 1
                                    },
                    'rank' => '15'
                  },
          '63' => {
                    'tied' => 1,
                    'in_dataset' => {
                                      'ds1' => 1
                                    },
                    'rank' => '11'
                  },
          '75' => {
                    'tied' => 1,
                    'in_dataset' => {
                                      'ds1' => 1
                                    },
                    'rank' => '13'
                  },
          '61' => {
                    'tied' => 1,
                    'in_dataset' => {
                                      'ds1' => 1
                                    },
                    'rank' => '10'
                  },
          '58' => {
                    'tied' => 2,
                    'in_dataset' => {
                                      'ds2' => 2
                                    },
                    'rank' => '8.5'
                  },
          '79' => {
                    'tied' => 1,
                    'in_dataset' => {
                                      'ds2' => 1
                                    },
                    'rank' => '14'
                  },
          '52' => {
                    'tied' => 1,
                    'in_dataset' => {
                                      'ds2' => 1
                                    },
                    'rank' => '5'
                  },
          '93' => {
                    'tied' => 1,
                    'in_dataset' => {
                                      'ds1' => 1
                                    },
                    'rank' => '16'
                  },
          '56' => {
                    'tied' => 1,
                    'in_dataset' => {
                                      'ds2' => 1
                                    },
                    'rank' => '7'
                  },
          '45' => {
                    'tied' => 2,
                    'in_dataset' => {
                                      'ds2' => 1,
                                      'ds1' => 1
                                    },
                    'rank' => '2.5'
                  },
          '65' => {
                    'tied' => 1,
                    'in_dataset' => {
                                      'ds2' => 1
                                    },
                    'rank' => '12'
                  },
          '44' => {
                    'tied' => 1,
                    'in_dataset' => {
                                      'ds2' => 1
                                    },
                    'rank' => '1'
                  }
                   };


is_deeply($ranks, $expected_ranks, "Ranks hash");

@ranks = $wilcox_test->compute_rank_array();

$expected_ranks_array = [
          [
            '1',
            'ds2'
          ],
          [
            '2.5',
            'ds2'
          ],
          [
            '2.5',
            'ds1'
          ],
          [
            '4',
            'ds1'
          ],
          [
            '5',
            'ds2'
          ],
          [
            '6',
            'ds2'
          ],
          [
            '7',
            'ds2'
          ],
          [
            '8.5',
            'ds2'
          ],
          [
            '8.5',
            'ds2'
          ],
          [
            '10',
            'ds1'
          ],
          [
            '11',
            'ds1'
          ],
          [
            '12',
            'ds2'
          ],
          [
            '13',
            'ds1'
          ],
          [
            '14',
            'ds2'
          ],
          [
            '15',
            'ds1'
          ],
          [
            '16',
            'ds1'
          ]
                        ];

is_deeply(\@ranks, $expected_ranks_array, "Ranks array");

@dataset_1 = qw(0.45 0.50 0.61 0.63 0.75 0.85 0.93);
@dataset_2 = qw(0.44 0.45 0.52 0.53 0.56 0.58 0.58 0.65 0.79);

$wilcox_test->load_data(\@dataset_1, \@dataset_2);

@ranks = $wilcox_test->compute_rank_array();

is_deeply(\@ranks, $expected_ranks_array, "Ranks array - data divised by 100");

1;

