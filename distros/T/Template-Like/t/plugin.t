use Test::More tests => 6;

BEGIN { use_ok('Template::Like') };

use Data::Dumper;
use Template::Like::Filters;

#-----------------------------
# Filter
#-----------------------------
{
  my $t = Template::Like->new();
  my $output;
  my $input1  = q{[% USE Dumper %][% Dumper.dump(var) %]};
  my $input2  = q{[% USE dump = Dumper %][% dump.dump(var) %]};
  my $input3  = q{[% USE Dumper(indent = 4) %][% Dumper.dump(var, 'hoge') %]};
  my $input4  = q{[% USE dump = Dumper(Varname='FOO') %][% dump.dump(var, 'hoge') %]};
  my $input5  = q{[% USE dump = Dumper %][% dump.dump_html(var, 'hoge') %]};
  my $var = 'abcdefg';
  my $result1 = Dumper($var);
  my $result2 = Dumper($var);
  my $result3 = eval { local $Data::Dumper::Indent = '4'; return Dumper($var, 'hoge'); };
  my $result4 = eval { local $Data::Dumper::Varname = 'FOO'; return Dumper($var, 'hoge') };
  my $result5_tmp = Dumper($var, 'hoge');
  my $result5 = Template::Like::Filters->html_line_break(
                  Template::Like::Filters->html($result5_tmp));
  
  
  
  {
    $output = '';
    $t->process(\$input1, { var => $var }, \$output);
    is($result1, $output, "");
  }
  
  {
    $output = '';
    $t->process(\$input2, { var => $var }, \$output);
    is($result2, $output, "");
  }
  
  {
    $output = '';
    $t->process(\$input3, { var => $var }, \$output);
    is($result3, $output, "");
  }
  
  {
    $output = '';
    $t->process(\$input4, { var => $var }, \$output);
    is($result4, $output, "");
  }
  
  {
    $output = '';
    $t->process(\$input5, { var => $var }, \$output);
    is($result5, $output, "");
  }
  
}


