#! perl

use strict;
use warnings;

use Test::More tests => 8;
use Template::Flute;
use Data::Dumper;

my ($spec_xml, $template, @records, $flute, $output, @matches);

@records = ({name => 'Link', url => 'http://localhost/'},
            {name => 'No Link'},
            {name => 'Another Link', url => 'http://localhost/'},
            );

$spec_xml = <<'EOF';
<specification name="link">
<list name="links" class="linklist" iterator="links">
<param name="name"/>
<param name="url" target="href"/>
<param name="link" field="url" op="toggle" args="tree"/>
</list>
</specification>
EOF

$template =  qq{<html>
	<div class="linklist">
<span class="name">Name</span>
<div class="link">
<a href="#" class="url">Goto ...</a>
</div>
</div>
</html>};

$flute = Template::Flute->new(specification => $spec_xml,
							  template => $template,
							  values => {links => \@records});

$output = $flute->process();

@matches = $output =~ m%http://localhost/%g;
ok (@matches == 2, 'Number of matching links')
    || diag $output;

@matches = $output =~ m%<div class="link">%g;
ok (@matches == 2, 'Number of link divs')
    || diag $output;

$spec_xml = <<'EOF';
<specification name="link">
<list name="links" class="linklist" iterator="links">
<container name="link" class="link" value="url"/>
<param name="name"/>
<param name="url" target="href"/>
</list>
</specification>
EOF

$flute = Template::Flute->new(specification => $spec_xml,
							  template => $template,
							  values => {links => \@records});

$output = $flute->process();

@matches = $output =~ m%http://localhost/%g;
ok (@matches == 2, 'Number of matching links')
    || diag $output;

@matches = $output =~ m%<div class="link">%g;
ok (@matches == 2, 'Number of link divs')
    || diag $output;

$spec_xml = q{
<specification name="link">
<list name="field" iterator="fields">
<param name="name" class="input" target="name"/>
<param name="value" class="input" target="value"/>
<param name="disabled" class="input" target="disabled" op="toggle"/>
</list>
</specification>
};

$template = qq{<html>
<form>
<span class="field">
<input type="text" class="input" name="name" value="value"/>
</span>
</form>};

@records = ({name => 'color', value => 'blue'},
            {name => 'size', value => 'large'},
            {name => 'magic', value => 'none', disabled => 1},
        );

$flute = Template::Flute->new(specification => $spec_xml,
							  template => $template,
							  values => {fields => \@records});

$output = $flute->process();

@matches = $output =~ m%<input\s(.*?)\s/>%g;

ok(scalar(@matches) == 3, "Number of input fields")
    || diag "Output: $output.";

ok($matches[0] eq q{class="input" name="color" type="text" value="blue"},
   "Input color=blue")
    || diag "Match: $matches[0].";

ok($matches[1] eq q{class="input" name="size" type="text" value="large"},
   "Input size=large")
    || diag "Match: $matches[1].";

ok($matches[2] eq q{class="input" disabled="" name="magic" type="text" value="none"},
   "Input magic=none (disabled)")
    || diag "Match: $matches[2].";
