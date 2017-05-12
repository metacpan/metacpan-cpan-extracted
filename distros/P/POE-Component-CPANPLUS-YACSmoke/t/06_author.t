use Test::More;
use File::Spec;
use POE;

#if ( $^O eq 'MSWin32' ) {
#   eval "require CPANPLUS::YACSmoke";
#   unless ($@) {
#        plan skip_all => "MSWin32 and CPANPLUS::YACSmoke detected";
#   }
#}

plan tests => 11;

require_ok('POE::Component::CPANPLUS::YACSmoke');

my @path = qw(COMPLETELY MADE UP PATH TO PERL);
unshift @path, 'C:' if $^O eq 'MSWin32';
my $perl = File::Spec->catfile( @path );

my $module = 'F/FU/FUBAR/Fubar-1.00.tar.gz';

my $smoker = POE::Component::CPANPLUS::YACSmoke->spawn( alias => 'smoker',debug => 0, options => { trace => 0 } );

isa_ok( $smoker, 'POE::Component::CPANPLUS::YACSmoke' );

POE::Session->create(
	package_states => [
	   'main' => [ qw(_start _stop _results _timeout) ],
	],
);

$poe_kernel->run();
exit 0;

sub _start {
  my ($kernel,$heap) = @_[KERNEL,HEAP];
  $kernel->post( 'smoker', 'author', 
	{ debug => 1, event => '_results', perl => $perl, '_ArBiTrArY' => 12345, search => 'BINGOS' } 
  );
  $kernel->delay( '_time_out', 60 );
  undef;
}

sub _stop {
  pass("Hey the poco let go of our refcount");
  $poe_kernel->call( 'smoker', 'shutdown' );
  undef;
}

sub _timeout {
  die "F**k it all went pear-shaped";
  undef;
}

sub _results {
  my $job = $_[ARG0];
  ok( $job->{$_}, "There was a $_" ) for qw(results start_time end_time PID status submitted);
  ok( $job->{_ArBiTrArY} eq '12345', "The Arbitary value can through unchanged" );
  ok( $smoker->{debug} == 0, "Global debug setting was reset correctly" );
  $poe_kernel->delay( '_time_out' );
  undef;
}
