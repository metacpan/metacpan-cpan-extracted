use strict;
use Template::Test;

my $vars = {
    employee_info => [
	{ name => 'Sam', job => 'programmer' },
	{ name => 'Steve', job => 'soda jerk' },
    ],
};

test_expect(\*DATA, undef, $vars);

__END__
--test--
[% USE HTML.Template -%]
[% FILTER html_template -%]
<TMPL_LOOP NAME=EMPLOYEE_INFO>  Name: <TMPL_VAR NAME=NAME> <br>
  Job:  <TMPL_VAR NAME=JOB>  <p>
</TMPL_LOOP>
[%- END %]
--expect--
  Name: Sam <br>
  Job:  programmer  <p>
  Name: Steve <br>
  Job:  soda jerk  <p>

--test--
[% USE ht = HTML.Template(loop_context_vars = 1) -%]
[% FILTER $ht -%]
<TMPL_LOOP NAME=EMPLOYEE_INFO><TMPL_IF name=__FIRST__>First</TMPL_IF>
  Name: <TMPL_VAR NAME=NAME> <br>
  Job:  <TMPL_VAR NAME=JOB>  <p>
</TMPL_LOOP>
[%- END %]
--expect--
First
  Name: Sam <br>
  Job:  programmer  <p>

  Name: Steve <br>
  Job:  soda jerk  <p>

