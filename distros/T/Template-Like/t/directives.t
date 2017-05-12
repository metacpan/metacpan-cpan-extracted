#use Test::More 'no_plan';
use Test::More tests => 9;

use strict;
use warnings;
use lib qw(./t ./lib);

my $tt_args = {
    INCLUDE_PATH => './t',
    PLUGIN_BASE  => 'Plugin::Test',
    INTERPOLATE  => 1, 
    POST_CHOMP   => 1, 
    DEBUG        => 0,
    #PLUGINS => {
    #    OurPlugin => 'Plugin::Test',
    #    #bar => 'My::Plugin::Bar',
    #},

};

BEGIN { use_ok('Template::Like') };
#BEGIN { use_ok('Template') };
BEGIN { use_ok('Plugin::Test::OurPlugin') };
use Carp qw/ confess /;
use Data::Dumper;

my $t = Template::Like->new( $tt_args );
#my $t = Template->new( $tt_args );

# prove basic functionality
{
  my $output;
  my $input  = q{enie menie minie [% var %]};
  my $replace_with = { var => 'moe' };
  my $desired_result = q{enie menie minie moe};
  $t->process(\$input, $replace_with, \$output);
  is($output, $desired_result, 'basic template expansion');
}

## prove Plugin Functionality with directive 'USE'
{
  my $output;
  my $input        =  q{[% USE OurPlugin %][% OurPlugin.return_foo() %]};
  my $replace_with = {};
  my $desired_result = q{foo};
  $t->process(\$input, $replace_with, \$output);
  is($output, $desired_result, q{basic test 'USE' directive});
}

{
  my $output;
  my $input        =  q{[% USE OurPlugin %][% OurPlugin.substitute_with_raz( var ) %]};
  my $replace_with = { var => ' baz' };
  my $desired_result = q{raz};
  $t->process(\$input, $replace_with, \$output);
  is($output, $desired_result, q{test 'USE' directive with 1 param as arg});
}

{
  my $output;
  my $input        =  q{[% USE OurPlugin %][% OurPlugin.substitute_arg1_with_arg2( var, 'foo') %]};
  my $replace_with = { var => 'glue' };
  my $desired_result = q{foo};
  $t->process(\$input, $replace_with, \$output);
  is($output, $desired_result, q{test 'USE' directive with 2 param args});
}

{
  my $output;
  my $input        =  q{[% USE OurPlugin; OurPlugin.return_foo();  var %]};
  my $replace_with = { var => ' baz' };
  my $desired_result = q{foo baz};
  $t->process(\$input, $replace_with, \$output);
  is($desired_result, $output, q{test USE directive with code delimiter of ';' });
}


{
  my $output;
  my $input        =  q{[% USE OurPlugin %][% OurPlugin.substitute_arg1_with_arg2_repeat_N_times( var, 'foo', 5) %]};
  my $replace_with = { var => 'baz' };
  my $desired_result = q{foofoofoofoofoo};
  $t->process(\$input, $replace_with, \$output);
  is($output, $desired_result, q{test 'USE' directive with 3 param args});
}

{
  my $output;
  my $input        =  q{[% USE OurPlugin %][% OurPlugin.return_foo() %] bar [% var %]};
  my $replace_with = {};
  my $desired_result = q{foo bar };
  $t->process(\$input, $replace_with, \$output);
  is($output, $desired_result, 'test USE directive with simple templating and an empty variable');
}
