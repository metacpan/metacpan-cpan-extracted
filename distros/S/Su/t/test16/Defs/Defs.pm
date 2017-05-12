package Defs::Defs;

my $defs = {
  exec => {
    proc  => 'Templates::MainProc',
    model => [ 'Models::Model01', 'Models::Model02', 'Models::Model03' ],
  },
  exec_post_filter => {
    proc       => 'Templates::MainProc',
    model      => [ 'Models::Model01', 'Models::Model02', 'Models::Model03' ],
    map_filter => 'Templates::FilterProc'
  },
  exec_map_filter => {
    proc       => 'Templates::MainProc',
    model      => 'Models::Model01',
    map_filter => 'Templates::FilterProc',
  },

  exec_map_multi_filter => {
    proc       => 'Templates::ReturnArrayProc',
    model      => 'Models::Model01',
    map_filter => 'Templates::ReturnArrayProc',
  },

  exec_reduce_filter => {
    proc          => 'Templates::ReturnArrayProc',
    model         => 'Models::Model01',
    map_filter    => 'Templates::ReturnArrayProc',
    reduce_filter => 'Templates::ReturnArrayProc',
  },

  exec_scalar_filter => {
    proc          => 'Templates::ReturnArrayProc',
    model         => 'Models::Model01',
    map_filter    => 'Templates::ReturnArrayProc',
    reduce_filter => 'Templates::ReturnArrayProc',
    scalar_filter => 'Templates::ReturnArrayProc',
    }

};

sub defs {
  shift if ( $_[0] eq __PACKAGE__ );

  my $arg = shift;
  if ($arg) {
    $defs = $arg;
  } else {
    return $defs;
  }
} ## end sub defs

