use Test::More tests => 50;

BEGIN { use_ok('Template::Like') };

my $t = Template::Like->new( DEBUG => 0 );

#-----------------------------
# VAR
#-----------------------------
{
  my $output;
  my $input  = q{[% var %]};
  my $result = q{var};
  $t->process(\$input, { var => "var" }, \$output);
  is($result, $output, "var");
}

#-----------------------------
# CALL
#-----------------------------
{
  my $output;
  my $input  = q{[% CALL var.exec %]};
  my $result = q{};
  my $testobj_call = TESTOBJ_CALL->new;
  $t->process(\$input, { var => $testobj_call }, \$output);
  is($result, $output, "call1a");
  is(1, $testobj_call->{'cnt'}, "call1b");
  $t->process(\$input, { var => $testobj_call }, \$output);
  is($result, $output, "call2a");
  is(2, $testobj_call->{'cnt'}, "call2b");
  {package TESTOBJ_CALL;sub new { bless { cnt => 0 } };sub exec { $_[0]->{'cnt'}++ };};
}

#-----------------------------
# IF
#-----------------------------
{
  my $output;
  my $input   = q{[% IF bool %]abc[% END %]};
  my $input2  = q{[% IF bool == "a" %]abc[% END %]};
  my $input3  = q{[% IF bool != "a" %]abc[% END %]};
  my $input4  = q{[% IF bool < 0 %]abc[% END %]};
  my $input5  = q{[% IF bool == '"' %]abc[% END %]};
  my $input6  = q{[% IF bool == bool2 %]abc[% END %]};
  my $result1 = q{abc};
  my $result2 = q{};
  
  $t->process(\$input, { bool => "a" },   \$output);
  is($result1, $output, "string");
  $output = '';
  
  $t->process(\$input, { bool => 1 },     \$output);
  is($result1, $output, "one");
  $output = '';
  
  $t->process(\$input, { bool => "" },    \$output);
  is($result2, $output, "nostring");
  $output = '';
  
  $t->process(\$input, { bool => undef }, \$output);
  is($result2, $output, "undef");
  $output = '';
  
  $t->process(\$input, { bool => 0 },     \$output);
  is($result2, $output, "zero");
  $output = '';
  
  $t->process(\$input, { },               \$output);
  is($result2, $output, "nothing");
  $output = '';
  
  $t->process(\$input2, { bool => "a" },  \$output);
  is($result1, $output, "comp_eq");
  $output = '';
  
  $t->process(\$input2, { bool => "b" },  \$output);
  is($result2, $output, "comp_eq");
  $output = '';
  
  $t->process(\$input3, { bool => "a" },  \$output);
  is($result2, $output, "comp_ne");
  $output = '';
  
  $t->process(\$input3, { bool => "b" },  \$output);
  is($result1, $output, "comp_ne");
  $output = '';
  
  $t->process(\$input4, { bool => -1 },   \$output);
  is($result1, $output, "comp_ne");
  $output = '';
  
  $t->process(\$input4, { bool => 1 },    \$output);
  is($result2, $output, "comp_ne");
  $output = '';
  
  $t->process(\$input5, { bool => '"' },    \$output);
  is($result1, $output, "comp_eq");
  $output = '';
  
  $t->process(\$input6, { bool => '"', bool2 => '"' }, \$output);
  is($result1, $output, "comp_eq");
  $output = '';
  
  $t->process(\$input6, { bool => '"', bool2 => '0' }, \$output);
  is($result2, $output, "comp_eq");
  $output = '';
}
#-----------------------------
# IF/ELSIF/ELSE
#-----------------------------
{
  my $output;
  my $input   = q{[% IF bool %][% ELSIF bool2 %]123[% ELSE %]abc[% END %]};
  my $result1 = q{abc};
  my $result2 = q{};
  my $result3 = q{123};
  $t->process(\$input, { bool => "a" },   \$output);
  is($result2, $output, "string");
  $output = '';
  $t->process(\$input, { bool => 1 },     \$output);
  is($result2, $output, "one");
  $output = '';
  $t->process(\$input, { bool => "" },    \$output);
  is($result1, $output, "nostring");
  $output = '';
  $t->process(\$input, { bool => undef }, \$output);
  is($result1, $output, "undef");
  $output = '';
  $t->process(\$input, { bool => 0 },     \$output);
  is($result1, $output, "zero");
  $output = '';
  $t->process(\$input, { },               \$output);
  is($result1, $output, "nothing");
  $output = '';
  $t->process(\$input, { bool2 => 1 },   \$output);
  is($result3, $output, "elsif one");
}
#-----------------------------
# UNLESS
#-----------------------------
{
  my $output;
  my $input   = q{[% UNLESS bool %]abc[% END %]};
  my $result1 = q{abc};
  my $result2 = q{};
  $t->process(\$input, { bool => "a" },   \$output);
  is($result2, $output, "string");
  $output = '';
  $t->process(\$input, { bool => 1 },     \$output);
  is($result2, $output, "one");
  $output = '';
  $t->process(\$input, { bool => "" },    \$output);
  is($result1, $output, "nostring");
  $output = '';
  $t->process(\$input, { bool => undef }, \$output);
  is($result1, $output, "undef");
  $output = '';
  $t->process(\$input, { bool => 0 },     \$output);
  is($result1, $output, "zero");
  $output = '';
  $t->process(\$input, { },               \$output);
  is($result1, $output, "nothing");
}
#-----------------------------
# UNLESS/ELSE
#-----------------------------
{
  my $output;
  my $input   = q{[% UNLESS bool %][% ELSE %]abc[% END %]};
  my $result1 = q{abc};
  my $result2 = q{};
  $t->process(\$input, { bool => "a" },   \$output);
  is($result1, $output, "string");
  $output = '';
  $t->process(\$input, { bool => 1 },     \$output);
  is($result1, $output, "one");
  $output = '';
  $t->process(\$input, { bool => "" },    \$output);
  is($result2, $output, "nostring");
  $output = '';
  $t->process(\$input, { bool => undef }, \$output);
  is($result2, $output, "undef");
  $output = '';
  $t->process(\$input, { bool => 0 },     \$output);
  is($result2, $output, "zero");
  $output = '';
  $t->process(\$input, { },               \$output);
  is($result2, $output, "nothing");
}
#-----------------------------
# Method
#-----------------------------
{
  my $output;
  my $input1 = q{[% test.nothing || test.getHoge %]};
  my $input2 = q{[% test.hoge %]};
  my $result = q{foo};
  $t->process(\$input1, { test => TESTOBJ->new({ hoge => "foo" }) }, \$output);
  is($result, $output, "obj's method");
  $output = '';
  $t->process(\$input2, { test => TESTOBJ->new({ hoge => "foo" }) }, \$output);
  is($result, $output, "obj's hashref");
  $output = '';
  $t->process(\$input2, { test => { hoge => "foo" } },               \$output);
  is($result, $output, "hashref");
  $output = '';
  {package TESTOBJ;sub new { bless $_[1] };sub getHoge { $_[0]->{'hoge'} };};
}
#-----------------------------
# Filter
#-----------------------------
{
  my $output;
  my $input1  = q{[% var | html %]};
  my $input2  = q{[% var | html_line_break %]};
  my $input3  = q{hoge[% FILTER html_line_break %][% var %][% END %]bar};
  my $result1 = q{&lt;b&gt;&quot;&amp;&quot;&lt;/b&gt;};
  my $result2 = qq{<br />\r\n<br />\n\r};
  my $result3 = qq{hoge<br />\r\n<br />\n\rbar};
  $t->process(\$input1, { var => '<b>"&"</b>' }, \$output);
  is($result1, $output, "html filter");
  $output = '';
  
  $t->process(\$input2, { var => "\r\n\n\r" },   \$output);
  
  $output=~s/\r/\\r/g;
  $output=~s/\n/\\n/g;
  $result2=~s/\r/\\r/g;
  $result2=~s/\n/\\n/g;
  
  is($result2, $output, "html_line_break filter");
  $output = '';
  
  $t->process(\$input3, { var => "\r\n\n\r" },   \$output);
  $output=~s/\r/\\r/g;
  $output=~s/\n/\\n/g;
  $result3=~s/\r/\\r/g;
  $result3=~s/\n/\\n/g;
  is($result3, $output, "html_line_break filter block");
  $output = '';
}
#-----------------------------
# FilterOption
#-----------------------------
{
  my $t = Template::Like->new({ FILTERS => { lc => sub { lc($_[0]) }, uc => sub { uc($_[0]) } } });
  my $output;
  my $input1  = q{[% var | uc %]};
  my $input2  = q{[% var | lc %]};
  my $result1 = q{ABCDEF};
  my $result2 = q{abcdef};
  $t->process(\$input1, { var => 'abcDEF' }, \$output);
  is($result1, $output, "html filter");
  $output = '';
  $t->process(\$input2, { var => 'abcDEF' }, \$output);
  is($result2, $output, "html_line_break filter");
  $output = '';
  
}

#-----------------------------
# WHILE
#-----------------------------
{
  my $output;
  my $input  = q{[% WHILE count < 3 %][% SET count = count + 1 %][% var %][% END %]};
  my $result = q{varvarvar};
  $t->process(\$input, { var => "var", count => 0 }, \$output);
  is($result, $output, "var");
}
{
  my $output;
  my $input  = q{[% WHILE (var = vars.shift) %][% var %][% END %]};
  my $result = q{var1var2var3};
  $t->process(\$input, { vars => ["var1", "var2", "var3"], count => 0 }, \$output, { DEBUG => 0 }) || die $t->error();
  is($result, $output, "var");
}


