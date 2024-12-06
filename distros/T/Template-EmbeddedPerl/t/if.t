package Template::EmbeddedPerl::Test::Basic;
$INC{'Template/EmbeddedPerl/Test/Basic.pm'} = __FILE__;

use Template::EmbeddedPerl;
use Test::Most;

ok my $yat = Template::EmbeddedPerl->new(auto_escape => 1);
ok my $generator = $yat->from_data(__PACKAGE__);

{
  my $out = $generator->render(qw/1 0 0/);
  is $out, "  a";
}

{
  my $out = $generator->render(qw/0 1 0/);
  is $out, "  b";
}

{
  my $out = $generator->render(qw/0 0 1/);
  is $out, "  c";
}

{
  my $out = $generator->render(qw/0 0 0/);
  is $out, "  none";
}

done_testing;

__DATA__
% my ($a, $b, $c) = @_;\
% if($a) {\
  a\
% } elsif($b) {\
  b\
% } elsif($c) {\
  c\
% } else {\
  none\
% }\
