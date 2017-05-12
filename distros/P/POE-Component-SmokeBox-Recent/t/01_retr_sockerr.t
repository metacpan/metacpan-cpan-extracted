use strict;
use warnings;
use Test::More tests => 2;
use POE qw(Component::SmokeBox::Recent::FTP);

my $site = 'bogus.gumbybrain.com';
my $path = '/pub/CPAN/RECENT';

POE::Session->create(
  package_states => [
	main => [qw(_start _stop ftp_sockerr)],
  ]
);

$poe_kernel->run();
exit 0;

sub _start {
  POE::Component::SmokeBox::Recent::FTP->spawn(
	address => $site,
	path    => $path,
  );
}

sub ftp_sockerr {
  pass($_[STATE]);
  return;
}

sub _stop {
  pass('Everything stopped');
}

 sub _default {
     my ($event, $args) = @_[ARG0 .. $#_];
     return 0 if $event eq '_child';
     my @output = ( "$event: " );

     for my $arg (@$args) {
         if ( ref $arg eq 'ARRAY' ) {
             push( @output, '[' . join(' ,', @$arg ) . ']' );
         }
         else {
             push ( @output, "'$arg'" );
         }
     }
     diag( join ' ', @output, "\n" );
     return 0;
 }
