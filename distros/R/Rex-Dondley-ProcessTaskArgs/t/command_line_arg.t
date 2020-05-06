use strict;
use warnings;
use Rex::Dondley::ProcessTaskArgs;
use Rex::Args;
use Rex::RunList;
use Rex::Commands;
use Rex::Transaction;
use Rex::Args;
use Test::More;
use Test::Exception;
use Rex::Config;
timeout 1;

use Data::Dumper qw(Dumper);
Rex::Config->set_task_chaining_cmdline_args(1);


task 'test1' =>  sub { };

lives_ok { get_params() } 'runs';

is_deeply get_params( [ qw /--one=five/ ],
                      [ 'one' ]
                    ),
          { one => 'five' },
          'blah';

lives_ok {
  get_params( [ qw /--one=five/ ],
              [ 'one' ]
  );
};

lives_ok {
  get_params( [ qw /five/ ],
              [ 'one' ]
  );
};

throws_ok {
  get_params( [ qw /--two=five/ ],
              [ 'one' ]
  );
} qr/key/i, 'invalid key';

throws_ok {
  get_params( [ qw /five six/ ],
              [ 'one' ]
  );
} qr/too many/i, 'invalid key';

is_deeply get_params( [ qw /boo bah/ ],
                      [ qw /one 1 two 0/ ]
                    ),
          { one => 'boo', two => 'bah' },
          'blah';

is_deeply get_params( [ qw /bah --one=boo/ ],
                      [ qw /one 1 two 0/ ]
                    ),
          { one => 'boo', two => 'bah' },
          'blah';

is_deeply get_params( [ qw /bah boo/ ],
                      [ qw /one 0 two 0 three 0 four 0 five 0 six 0/ ]
                    ),
          { one => 'bah', two => 'boo', three => undef, four => undef, five => undef, six => undef },
          'test3';

done_testing();

sub get_params {
  my $args = shift;
  my $keys = shift;
  return process_task_args(get_args('test1', @$args), @$keys);
}

sub get_args {
  my $run_list = Rex::RunList->instance;
  $run_list->parse_opts(@_);
  my ($t) = $run_list->tasks;
  return [ { $t->get_opts }, [ $t->get_args ] ];
}


#is_deeply eval_rex('test3 bah boo'), { one => 'bah', two => 'boo', three => undef, four => undef, five => undef, six => undef  }, 'handles mix of arg types';
