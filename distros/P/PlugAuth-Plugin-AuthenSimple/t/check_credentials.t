use Test2::Plugin::FauxHomeDir;
use Test2::V0;
use File::Spec;
use YAML::XS ();
use File::Glob qw( bsd_glob );
use PlugAuth;

delete $ENV{HARNESS_ACTIVE};
$ENV{LOG_LEVEL} = "ERROR";

my $x = 0;
my $y = 0;

my $home = bsd_glob('~');
mkdir(File::Spec->catdir($home, 'etc'));
YAML::XS::DumpFile(File::Spec->catfile($home, 'etc', 'PlugAuth.conf'), {
  plugins => { 
    'PlugAuth::Plugin::AuthenSimple' => [ 
      { 'Authen::Simple::Test1' => { x => 1 } },
      { 'Authen::Simple::Test2' => { y => 2 } },
    ]
  },
});

my $app = PlugAuth->new;
isa_ok $app, 'PlugAuth';
isa_ok $app->auth, 'PlugAuth::Plugin::AuthenSimple';

is $app->auth->check_credentials('primus', 'matrix'), 1, 'user = primus pass = matrix ok';
is $app->auth->check_credentials('grimlock', 'me'  ), 1, 'user = grimlock pass = me   ok';
is $app->auth->check_credentials('invalid', 'bogus'), 0, 'user = invalid pass = bogus not ok';

is $x, 1, "x = 1";
is $y, 2, "y = 2";

done_testing;

package Authen::Simple::Test1;

use Params::Validate ();
use base 'Authen::Simple::Adapter';
BEGIN { $INC{'Authen/Simple/Test1.pm'} = __FILE__ }

BEGIN { __PACKAGE__->options({ x =>  { type => Params::Validate::SCALAR, optional => 0 } }) }

sub check {
  my ( $self, $username, $password ) = @_;
  $x = $self->x;
  return 1 if $username eq 'primus' && $password eq 'matrix';
  return 0;
}

package Authen::Simple::Test2;

use Params::Validate ();
use base 'Authen::Simple::Adapter';
BEGIN { $INC{'Authen/Simple/Test2.pm'} = __FILE__ }

BEGIN { __PACKAGE__->options({ y =>  { type => Params::Validate::SCALAR, optional => 0 } }) }

sub check {
  my ( $self, $username, $password ) = @_;
  $y = $self->y;
  return 1 if $username eq 'grimlock' && $password eq 'me';
  return 0;
}
