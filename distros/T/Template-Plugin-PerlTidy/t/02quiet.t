#!/usr/bin/perl -w
use strict;
use Test;
use Template;

BEGIN { plan tests => 1 }

my $template = Template->new();

my $input = <<'_TEMPLATE_';
[% USE PerlTidy 'html' 'nnn' 'pre' -%]
 [%- FILTER $PerlTidy -%]
  #!/usr/bin/perl -w
  ue strict;
  my@foo=(1,2,'a',4);
       for(1,3,5)print" $_\n"}
 my     %hash = 1=>'foo',foo=>'bar',);
[% END %]
_TEMPLATE_

my $output;
$template->process(\$input,{}, \$output);
ok($output =~ m[<span class="c">#!/usr/bin/perl -w</span>] ); 

__END__

