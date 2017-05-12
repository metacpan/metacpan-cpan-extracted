use strict;
use warnings;

use Test::More;

use Module::Build::CleanInstall;

# some CPANtesters use a fresh and not installed version of all dependent modules
if (grep { m#List-MoreUtils.*?blib# } @INC) {
  plan skip_all => "Test irrelevant when not using an installed version of List::MoreUtils";
}

my $packlist = Module::Build::CleanInstall->_get_packlist('List::MoreUtils');
ok ($packlist, 'Found packlist for List::MoreUtils');

ok( 
  ! Module::Build::CleanInstall->_get_packlist('SoMe::ThiNg::NOT::insTalled'), 
  'Returns false on not installed'
);

# ExtUtils::Install::uninstall prints its actions, so create a handle which
# tests from the printed actions

my $unlink_attempted = 0;

{
  package My::Test::Handle;
  use parent 'Tie::Handle';

  sub TIEHANDLE { return bless {}, shift };

  sub PRINT {
    my $self = shift;
    my ($print) = @_;

    $unlink_attempted++ if $print =~ /unlink (.*)/;

    print STDOUT $print;
  }
}

tie *TESTHANDLE, 'My::Test::Handle';
my $stdout = select *TESTHANDLE;
Module::Build::CleanInstall->_uninstall( $packlist, 1 );  # 1 prevents actual removal
select $stdout;

ok( $unlink_attempted, 'At least one simulated unlink attempt was detected' );

done_testing();

