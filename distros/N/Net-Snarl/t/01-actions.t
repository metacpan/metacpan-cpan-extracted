use Test::More skip_all => 'Requires human verification';
use Net::Snarl;

diag( "Testing Net::Snarl $Net::Snarl::VERSION, Perl $], $^X" );

# unfortunately there is no real way to test these as snarl has to be located 
# on the local machine and visual checking that the notifications are shown is
# required.

eval {
  my $app = Net::Snarl->register('Net::Snarl');
  $app->add_class('test', 'Test Class');
  $app->notify('test', 'Net::Snarl', 'This is only a test.', 10);
};

if ($@) {
  diag $@;
  fail;
} else {
  pass;
}

