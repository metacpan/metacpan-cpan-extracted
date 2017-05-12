use strict;
use warnings;
use Test::More tests => 4;
BEGIN { use_ok('POE::Component::Win32::ChangeNotify') };

use POE;

my $self = POE::Component::Win32::ChangeNotify->spawn( alias => 'blah', options => { trace => 0 } );

isa_ok ( $self, 'POE::Component::Win32::ChangeNotify' );

POE::Session->create(
	inline_states => { _start => \&test_start, 
			   _touch => \&touch_file,
			   notification => \&file_was_touched },
	options => { trace => 0 },
);

$poe_kernel->run();
exit 0;

sub test_start {
  my ($kernel,$heap) = @_[KERNEL,HEAP];
  pass('blah');
  $kernel->post( 'blah' => monitor => 
     {
        'path' => '.',
        'event' => 'notification',
        'filter' => 'ATTRIBUTES DIR_NAME FILE_NAME LAST_WRITE SECURITY SIZE',
        'subtree' => 1,
     } );
  $kernel->delay( '_touch' => 2 );
  undef;
}

sub touch_file {
  my ($atime,$mtime);
  $atime = $mtime = time();
  utime $atime, $mtime, "./test_file";
  undef;
}

sub file_was_touched {
  my ($kernel,$hashref) = @_[KERNEL,ARG0];

  pass('File was touched') unless $hashref->{error};
  $kernel->post( 'blah' => 'shutdown' );
  undef;
}
