use strict;
use warnings;
use lib qw[../../lib ../../blib/lib];
use Test::More;    # Requires 0.94 as noted in Build.PL
use Template::Liquid;
#
my $template = Template::Liquid->parse(<<'END');
{% case arg -%}
    {%- when 'int' or 'double' or 'Fl_Cursor' -%}
	Number
    {%- when 'char **' or 'const char **' or 'AV *' -%}
	Pointer array
    {%- when 'const char *'    -%}
    Pointer
    {%- when 'HV *' -%}
	Hash
    {%- else -%}
    No idea
{%- endcase -%}
END
is $template->render(arg => 'int'),       'Number', 'int is a Number';
is $template->render(arg => 'double'),    'Number', 'double is a Number';
is $template->render(arg => 'Fl_Cursor'), 'Number', 'Fl_Cursor is a Number';
#
is $template->render(arg => 'char **'), 'Pointer array',
    'char ** is a Pointer array';
is $template->render(arg => 'const char *'), 'Pointer',
    'const char * is a Pointer';
is $template->render(arg => 'AV *'), 'Pointer array',
    'AV * is a Pointer array';
done_testing();
