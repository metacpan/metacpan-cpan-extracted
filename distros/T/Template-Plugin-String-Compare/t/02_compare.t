use strict;
use Template::Test;

test_expect(\*DATA);

__END__
--test--
[% USE String.Compare('0123ef') -%]
[% String.Compare.compare('0123df') %]
[% String.Compare.compare('0123ef') %]
[% String.Compare.compare('0123ff') %]
--expect--
1
0
-1
--test--
[% USE String.Compare -%]
[% IF String.Compare.new('2005-03-01') <  '2005-03-02' %]1[% END %]
[% IF String.Compare.new('2005-03-01') <= '2005-03-02' %]2[% END %]
[% IF String.Compare.new('2005-03-02') <= '2005-03-02' %]3[% END %]
[% IF String.Compare.new('2005-04-01') >  '2005-03-01' %]4[% END %]
[% IF String.Compare.new('2005-04-01') >= '2005-03-01' %]5[% END %]
[% IF String.Compare.new('2005-04-01') >= '2005-04-01' %]6[% END %]
[% IF String.Compare.new('2005-04-01') == '2005-04-01' %]7[% END %]
[% IF String.Compare.new('2005-04-01') != '2005-04-02' %]8[% END %]
--expect--
1
2
3
4
5
6
7
8
--test--
[% USE String.Compare -%]
[% IF '2005-03-01' <  String.Compare.new('2005-03-02') %]1[% END %]
[% IF '2005-03-01' <= String.Compare.new('2005-03-02') %]2[% END %]
[% IF '2005-03-02' <= String.Compare.new('2005-03-02') %]3[% END %]
[% IF '2005-04-01' >  String.Compare.new('2005-03-01') %]4[% END %]
[% IF '2005-04-01' >= String.Compare.new('2005-03-01') %]5[% END %]
[% IF '2005-04-01' >= String.Compare.new('2005-04-01') %]6[% END %]
[% IF '2005-04-01' == String.Compare.new('2005-04-01') %]7[% END %]
[% IF '2005-04-01' != String.Compare.new('2005-04-02') %]8[% END %]
--expect--
1
2
3
4
5
6
7
8
--test--
[% USE String.Compare -%]
[% IF String.Compare.new('2005-03-01') <  String.Compare.new('2005-03-02') %]1[% END %]
[% IF String.Compare.new('2005-03-01') <= String.Compare.new('2005-03-02') %]2[% END %]
[% IF String.Compare.new('2005-03-02') <= String.Compare.new('2005-03-02') %]3[% END %]
[% IF String.Compare.new('2005-04-01') >  String.Compare.new('2005-03-01') %]4[% END %]
[% IF String.Compare.new('2005-04-01') >= String.Compare.new('2005-03-01') %]5[% END %]
[% IF String.Compare.new('2005-04-01') >= String.Compare.new('2005-04-01') %]6[% END %]
[% IF String.Compare.new('2005-04-01') == String.Compare.new('2005-04-01') %]7[% END %]
[% IF String.Compare.new('2005-04-01') != String.Compare.new('2005-04-02') %]8[% END %]
--expect--
1
2
3
4
5
6
7
8
--test--
[% IF '2005-03-01' <  '2006-03-02' %]0[% END %]
[% IF '2005-03-01' <  '2005-03-02' %]1[% END %]
[% IF '2005-03-01' <= '2005-03-02' %]2[% END %]
[% IF '2005-03-02' <= '2005-03-02' %]3[% END %]
[% IF '2005-04-01' >  '2005-03-01' %]4[% END %]
[% IF '2005-04-01' >= '2005-03-01' %]5[% END %]
[% IF '2005-04-01' >= '2005-04-01' %]6[% END %]
[% IF '2005-04-01' == '2005-04-01' %]7[% END %]
[% IF '2005-04-01' != '2005-04-02' %]8[% END %]
--expect--
0

2
3

5
6
7
8
