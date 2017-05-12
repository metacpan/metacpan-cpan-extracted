use Test::More tests => 5;

BEGIN { use_ok('Template::Like') };

{
  package Test::Filters;
  use strict;
  sub new {
    return bless {}, $_[0];
  }
  sub ucfirst {
    my $self = shift;
    my $str = shift;
    return ucfirst($str);
  }
  sub lcfirst {
    my $self = shift;
    my $str = shift;
    return lcfirst($str);
  }
  sub uc {
    my $self = shift;
    my $str = shift;
    return uc($str);
  }
  sub lc {
    my $self = shift;
    my $str = shift;
    return lc($str);
  }
}

#-----------------------------
# Filter
#-----------------------------
{
  my $t = Template::Like->new({ LOAD_FILTERS => [ Test::Filters->new ] });
  my $output;
  my $input1  = q{[% var | ucfirst %]};
  my $input2  = q{[% var | lcfirst %]};
  my $input3  = q{[% var | uc %]};
  my $input4  = q{[% var | lc %]};
  
  my $result1 = q{Abcdeft};
  my $result2 = q{aBCDEFT};
  my $result3 = q{ABCDEFT};
  my $result4 = q{abcdeft};
  
  $output = '';
  $t->process(\$input1, { var => 'abcdeft' }, \$output);
  is($result1, $output, "");
  
  $output = '';
  $t->process(\$input2, { var => "ABCDEFT" }, \$output);
  is($result2, $output, "");
  
  $output = '';
  $t->process(\$input3, { var => "abcdeft" }, \$output);
  is($result3, $output, "");
  
  $output = '';
  $t->process(\$input4, { var => "ABCDEFT" }, \$output);
  is($result4, $output, "");
  
}


