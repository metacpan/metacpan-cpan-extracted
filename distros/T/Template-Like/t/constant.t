use Test::More tests => 3;

BEGIN { use_ok('Template::Like') };


#-----------------------------
# constatn
#-----------------------------
{
  my $input  = q{[% constants.title %]};
  my $result = q{hoge};
  my $output;
  my $tl = Template::Like->new( CONSTANTS => { title => "hoge" } );
  $tl->process(\$input, {  }, \$output);
  is($result, $output, "constants");
}

{
  my $input  = q{[% const.title %]};
  my $result = q{hoge};
  my $output;
  my $tl = Template::Like->new( CONSTANTS => { title => "hoge" }, CONSTANT_NAMESPACE => "const" );
  $tl->process(\$input, {  }, \$output);
  is($result, $output, "constant_namespace");
}


