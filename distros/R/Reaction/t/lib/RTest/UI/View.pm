package RTest::UI::View;

use base qw/Reaction::Test/;
use Reaction::Class;
use Test::More ();
use Reaction::UI::View ;


#has 'view' => (isa => 'Reaction::UI::View', is => 'ro', lazy_build => 1);
#view doesn't yet have TCs for this so ican get away with it ...
#sub _build_view {
#  Reaction::UI::View->new(
#                         );
#}

sub test_layoutset_name_generation :Tests {
  my $self = shift;
  my %cases =
    (
     'MyApp::ViewPort::FooBar' => 'foo_bar',
     'Reaction::UI::ViewPort::Foo_Bar' => 'foo_bar',
     'MyApp::UI::ViewPort::FOOBar::fooBAR' => 'foo_bar/foo_bar',
     'Reaction::UI::ViewPort::FooBARBaz::FooBAR_' => 'foo_bar_baz/foo_bar_',
    );
  while(my($class,$layout) = each %cases ){
    my $res = Reaction::UI::View->layout_set_name_from_viewport($class);
    Test::More::is($res,$layout,"layoutset name for $class")
  }

}

1;
