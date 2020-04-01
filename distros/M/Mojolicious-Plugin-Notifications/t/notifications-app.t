use Test::Mojo;
use Test::More;
use File::Basename 'dirname';
use File::Spec::Functions qw/catdir/;

BEGIN {
  push @INC, catdir(dirname(__FILE__), 'lib');
};

my $t = Test::Mojo->new('ExampleApp');

$t->get_ok('/error')
  ->text_is('p','')
  ->text_is('div.notify','Example')
  ;

$t->get_ok('/error?format=json')
  ->json_is('/notifications/0/1','Example')
  ;

done_testing;
__END__
