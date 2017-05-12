use Test::More tests => 9;
use IO::CaptureOutput qw(capture);

BEGIN { use_ok( 'Module::Install::CheckOptional' ); }

my ($stdout, $stderr);

#------------------------------------------------------------------------------

capture {
  my $co = new Module::Install::CheckOptional();
  $co->check_optional( Carp => 99 );
} \$stdout, \$stderr;

like($stdout, qr/Carp.*99.*is not installed\.\n/, 'Wrong module version, no message');
is($stderr, "", 'Wrong module version, no message');

#------------------------------------------------------------------------------

capture {
  my $co = new Module::Install::CheckOptional();
  $co->check_optional( Carp => 99, "Carp is cool.\n" );
} \$stdout, \$stderr;

like($stdout, qr/Carp.*99.*is not installed\.\n\nCarp is cool\.\n$/,
  'Wrong module version, with message');
is($stderr, "", 'Wrong module version, with message');

#------------------------------------------------------------------------------

capture {
  my $co = new Module::Install::CheckOptional();
  $co->check_optional( COPPIT => 0 );
} \$stdout, \$stderr;

like($stdout, qr/COPPIT.*0.*is not installed\.\n/, 'Missing module');
is($stderr, "", 'Missing module');

#------------------------------------------------------------------------------

capture {
  my $co = new Module::Install::CheckOptional();
  $co->check_optional( Config => 0 );
} \$stdout, \$stderr;

is($stdout, '', 'Present module');
is($stderr, '', 'Present module');

#------------------------------------------------------------------------------

END {
	print "\nTEST FAILED\nSTDOUT is:\n$stdout\nSTDERR is:\n$stderr\n" if $stdout ne '' || $stderr ne '';
}
