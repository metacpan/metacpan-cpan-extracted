#!perl -T
use strict;
use warnings FATAL => 'all';
use Test::More tests => 1;

use Template;
use Template::Plugin::Calendar::Simple;

my $table = Template->new;
my $out = '';
$table->process( \*DATA, { year => 1970, month  => 1 }, \$out ) or die $table->error, $/;

is $out, '
<table border="1">
  <caption>1 1970</caption>
  <tr>
    <th>Sun</th><th>Mon</th><th>Tue</th><th>Wed</th><th>Thu</th><th>Fri</th><th>Sat</th>
  </tr>
  <tr>
    <td>&nbsp;</td><td>&nbsp;</td><td>&nbsp;</td><td>&nbsp;</td><td>1</td><td>2</td><td>3</td>
  </tr>
  <tr>
    <td>4</td><td>5</td><td>6</td><td>7</td><td>8</td><td>9</td><td>10</td>
  </tr>
  <tr>
    <td>11</td><td>12</td><td>13</td><td>14</td><td>15</td><td>16</td><td>17</td>
  </tr>
  <tr>
    <td>18</td><td>19</td><td>20</td><td>21</td><td>22</td><td>23</td><td>24</td>
  </tr>
  <tr>
    <td>25</td><td>26</td><td>27</td><td>28</td><td>29</td><td>30</td><td>31</td>
  </tr>
</table>
', "correct output for Jan 1970";

__DATA__
[% USE cal = Calendar.Simple( month, year, 0 ) %]
<table border="1">
  <caption>[% month %] [% year %]</caption>
  <tr>
    [% FOREACH day = cal.days %]<th>[% day %]</th>[% END %]
  </tr>
  [%- FOREACH row = cal.rows %]
  <tr>
    [% FOREACH col = row %]<td>[% col || '&nbsp;' %]</td>[% END %]
  </tr>
[%- END %]
</table>
