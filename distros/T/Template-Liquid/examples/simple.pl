use strict;
use warnings;
use lib '../lib';
use lib 'lib';
use Template::Liquid;
$|++;
my $template = Template::Liquid->parse(<<'END');
{%for i in array%}
    Test. {{i}}
{%endfor%}
END
warn $template->render(condition => 1, array => [qw[one two three four]]);
print Template::Liquid->parse(
        <<'INPUT')->render(hash => {key => 'value'}, list => [qw[key value]]);
{% if hash == list %}Yep.{% endif %}
INPUT
warn Template::Liquid->parse(<<'END')->render();
{% assign grp_one = 'group 1' %}

{% cycle grp_one: 'one', 'two', 'three' %}
{% cycle 'group 1': 'one', 'two', 'three' %}
{% cycle 'group 2': 'one', 'two', 'three' %}
{% cycle 'group 2': 'one', 'two', 'three' %}
END
