use Test::More tests => 9;

BEGIN { use_ok('Template::Like') };

my $t = Template::Like->new;

#-----------------------------
# Filter
#-----------------------------
{
  my $output;
  my $input1  = q{[% var | html %]};
  my $input2  = q{[% var | html_line_break %]};
  my $input3  = q{[% var | format('<!-- %s -->') | html %]};
  my $input4  = q{[% var | uri %]};
  my $input5  = q{[% var | truncate('10') %]};
  my $input6  = q{[% var | repeat('3') %]};
  my $input7  = q{[% var | remove('\d') %]};
  my $input8  = q{[% var | replace('\d', 'x') %]};
  
  my $result1 = q{&lt;b&gt;&quot;&amp;&quot;&lt;/b&gt;};
  my $result2 =qq{<br />\r\n<br />\n\r};
  my $result3 = q{&lt;!-- hoge --&gt;};
  my $result4 = q{foo%2ecgi%3fhoge%3d%a4%a2%a4%a4%a4%a6%a4%a8%a4%aa};
  my $result5 = q{1234567...};
  my $result6 = q{123123123};
  my $result7 = q{az};
  my $result8 = q{xxx};
  
  $output = '';
  $t->process(\$input1, { var => '<b>"&"</b>' }, \$output);
  is($result1, $output, "html filter");
  
  $output = '';
  $t->process(\$input2, { var => "\r\n\n\r" },   \$output);
  is($result2, $output, "html_line_break filter");
  
  $output = '';
  $t->process(\$input3, { var => "hoge" },   \$output);
  is($result3, $output, "format");
  
  $output = '';
  $t->process(\$input4, { var => "foo.cgi?hoge=あいうえお" },   \$output);
  is($result4, $output, "uri");
  
  $output = '';
  $t->process(\$input5, { var => "12345678901" },   \$output);
  is($result5, $output, "truncate");
  
  $output = '';
  $t->process(\$input6, { var => "123" },   \$output);
  is($result6, $output, "repeat");
  
  $output = '';
  $t->process(\$input7, { var => "a1234567890z" },   \$output);
  is($result7, $output, "remove");
  
  $output = '';
  $t->process(\$input8, { var => "123" },   \$output);
  is($result8, $output, "replace");
  
}


