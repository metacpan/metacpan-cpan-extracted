use Test2::V1
  -pragmas,
  -target => { CLASS => 'Mojo::Log', ROLE => 'Mojo::Log::Role::Formattable' },
  qw( is isa_ok ok plan ref_is subtest );

plan 2;

sub history_is {
  my ( $log, $expected ) = @_;
  # each log message stored in the history is an array ref with three
  # elements: time, level, text
  my @history = map { [ @$_[ 1, 2 ] ] } @{ $log->history };
  is \@history, $expected, 'Check history of logged messages'
}

subtest 'Apply role to class' => sub {
  plan 5;

  # with_roles() applied to a class (for example Mojo::Log) creates a
  # new semi-anonymous class that consumes the given role
  my $class = CLASS->with_roles( '+Formattable' );
  ok $class->does( ROLE ), 'Class consumes role';
  isa_ok $class, CLASS;

  isa_ok my $log = $class->new( handle => undef, level => 'debug' ), CLASS;
  ok $log->does( ROLE ), 'Object consumes role';
  $log->debugf( 'prefix %s', 'foo' );
  $log->warnf( '%s suffix', 'bar' );
  $log->errorf( 'format %s %.3f', 'cool', 42.1234567 );
  history_is( $log, [ [ debug => 'prefix foo' ], [ warn => 'bar suffix' ], [ error => 'format cool 42.123' ] ] )
};

subtest 'Apply role to object' => sub {
  plan 4;

  my $log  = CLASS->new( handle => undef, level => 'debug' );
  my $logf = $log->with_roles( '+Formattable' );
  ref_is $log, $logf, 'Same log object reference';
  isa_ok $logf, CLASS;
  ok $logf->does( ROLE ), 'Object consumes role';
  $logf->debugf( 'prefix %s', 'foo' );
  $logf->warnf( '%s suffix', 'bar' );
  $logf->errorf( 'format %s %.3f', 'cool', 42.1234567 );
  history_is( $logf, [ [ debug => 'prefix foo' ], [ warn => 'bar suffix' ], [ error => 'format cool 42.123' ] ] )
}
