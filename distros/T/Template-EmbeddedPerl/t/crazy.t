package Template::EmbeddedPerl::Test::Basic;
$INC{'Template/EmbeddedPerl/Test/Basic.pm'} = __FILE__;

use Template::EmbeddedPerl;
use Test::Most;

ok my $yat = Template::EmbeddedPerl->new(
  helpers=>+{
    ttt => sub { '<a>TTT</a>' },
  }, 
  auto_escape => 1, 
);

ok my $generator = $yat->from_data(__PACKAGE__);
ok my $out = $generator->render(qw/a b c/);

is $out, <<'EXPECTED', 'rendered template';
  <p>a&lt;hr&gt;</p>
  <p>b&lt;hr&gt;</p>
  <p>c&lt;hr&gt;</p>
\
  <span>One: &lt;a&gt;TTT&lt;/a&gt;</span>

    <div><%
      a 0 %&gt; 2
    </div>
    <div><%
      a 0 %&gt; 3
    </div>
    <div><%
      a 1 %&gt; 2
    </div>
    <div><%
      a 1 %&gt; 3
    </div>
    <p>A: 3</p><%
    <div><%
      b 0 %&gt; 2
    </div>
    <div><%
      b 0 %&gt; 3
    </div>
    <div><%
      b 1 %&gt; 2
    </div>
    <div><%
      b 1 %&gt; 3
    </div>
    <p>A: 3</p><%
    <div><%
      c 0 %&gt; 2
    </div>
    <div><%
      c 0 %&gt; 3
    </div>
    <div><%
      c 1 %&gt; 2
    </div>
    <div><%
      c 1 %&gt; 3
    </div>
    <p>A: 3</p><%

BB: ..<p>a</p>=%>
  <p>b</p>=%>
  <p>c</p>=%>
..
ddd
%%
%>
%=
<%
%>
<%=
dddd
EXPECTED

done_testing;

__DATA__
<% my @items = @_ %>\
<%= map { %>\
  <p><%= $_ %><%= "<hr>" %></p>
<% } @items %>\\
<% my $X=1; my $bb = safe_concat map { %>\
  <p><%= $_ %></p>\=%>
<% } @items %>\
% if(1) {
  <span>One: <%= ttt %></span>
% }
<% my $a=[1,2,3]; foreach my $item (sub { @items }->()) {
  foreach my $index (0..1) {
    foreach my $i2 (2..3) { =%>\
    <div>\<%
      <%= $item.' '.$index. ' \%> '.$i2 %>
    </div>
<% }} =%>\
<%=  sub { %>\
    <p><%= "A: @{[ $a->[2] ]}" %></p>\<%
<% }->() %>\
<% } %>
<%= raw "BB: ..@{[ trim $bb ]}.." %>
%= 'ddd'
\%%
\%>
\%=
\<%
\%>
\<%=
dddd
