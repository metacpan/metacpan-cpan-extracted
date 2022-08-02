use strict;
use warnings;
use Test::More;
use Template::LiquidX::Tidy;
use Template::Liquid;
use vars qw($t1_expected $t2_expected);
require "./t/results.pl";

plan tests => 2;

my $source = <<'LIQUID';
<wbr>
<a href="{% if site.github %}{{ site.github.tar_url | replace_first: '/tarball/', '/tree/' }}{% else %}file://{{ site.source }}{% endif
%}/{% if page.relative_path %}{{ page.relative_path }}{% elsif paginator and paginator.page > 1
%}{% assign temp0 = "/" | append: paginator.page | append: "/"
%}{{ page.path | replace_first: temp0, "/" }}{% else %}{{ page.path }}{% endif
%}">Source file</a>.
LIQUID

my $sol = Template::Liquid->parse($source);
my $t1 = $sol->{document}->tidy();
my $t2 = $sol->{document}->tidy({force_nl => 1});

is($t1, $t1_expected, "indent T1");
is($t2, $t2_expected, "indent T2");

1;
