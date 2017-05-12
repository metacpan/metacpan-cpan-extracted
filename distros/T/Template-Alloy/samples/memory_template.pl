#!/usr/bin/perl -w

my $swap = {
    one   => "ONE",
    two   => "TWO",
    three => "THREE",
    a_var => "a",
    hash  => {a => 1, b => 2},
    code  => sub {"($_[0])"},
};

my $txt  = "[% one %][% two %][% three %][% hash.keys.join %] [% code(one).length %] [% hash.\$a_var %]\n";
#$txt = hello2000();

###----------------------------------------------------------------###

my $module;
my $name;
if (! fork) {
    $module = 'Template::Alloy';
} elsif (! fork) {
    $module = 'Template::Alloy::XS';
} elsif (! fork) {
    $module = 'Template';
} elsif (! fork) {
    $module = 'Template';
    $name   = 'Template Stash::XS';
    require Template::Stash::XS;
} elsif (! fork) {
    $module = 'HTML::Template';
} elsif (! fork) {
    $module = 'HTML::Template::Expr';
} elsif (! fork) {
    $module = 'HTML::Template::Compiled';
} elsif (! fork) {
    $module = 'Text::Tmpl';
} elsif (! fork) {
    $module = 'Template::Alloy';
    $name   = 'Template::Alloy - bare';
} elsif (! fork) {
    $module = 'Template::Alloy::XS';
    $name   = 'Template::Alloy::XS - bare';
} elsif (! fork) {
    $module = 'Template';
    $name   = 'Template::Parser::CET';
    require Template::Parser::CET;
    Template::Parser::CET->activate;
}

if ($module) {
    $name ||= $module;
    $0 = "$0 - $name";

    my $pm = "$module.pm";
    $pm =~ s|::|/|g;
    require $pm;

    if ($module =~ /HTML::Template/) {
        my $t = eval { $module->new };
    } elsif ($module eq 'Text::Tmpl') {
        my $t = eval { $module->new->parse_string($txt) };
    } elsif ($name =~ /bare/) {
        my $t = eval { $module->new };
    } else {

        my $t = $module->new(ABSOLUTE => 1);
        my $out = '';
        $t->process(\$txt, $swap, \$out);
        print "$name $out";
        for (1..30) { my $out; $t->process(\$txt, $swap, \$out); };
    }

#    print "$name $_\n" foreach sort keys %INC;
    print "$name times: (@{[times]})\n";
    sleep 15;
    exit;
}

sleep 2;
print grep {/\Q$0\E/} `ps fauwx`;
#sleep 15; # go and check the 'ps fauwx|grep perl'
exit;

###----------------------------------------------------------------###

sub hello2000 {
    my $hello2000 = "<html><head><title>[% title %]</title></head><body>
[% array = [ \"Hello\", \"World\", \"2000\", \"Hello\", \"World\", \"2000\" ] %]
[% sorted = array.sort %]
[% multi = [ sorted, sorted, sorted, sorted, sorted ] %]
<table>
[% FOREACH row = multi %]
  <tr bgcolor=\"[% loop.count % 2 ? 'gray' : 'white' %]\">
  [% FOREACH col = row %]
    <td align=\"center\"><font size=\"+1\">[% col %]</font></td>
  [% END %]
  </tr>
[% END %]
</table>
[% param = integer %]
[% FOREACH i = [ 1 .. 10 ] %]
  [% var = i + param %]"
  .("\n  [%var%] Hello World Hello World Hello World Hello World Hello World Hello World Hello World Hello World Hello World Hello World <br/>"x20)."
[% END %]
</body></html>
";
}
