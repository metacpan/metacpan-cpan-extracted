#! perl

use strict;
use warnings;

use Test::More tests => 3;
use Template::Flute;

my ($spec_xml, $template, @records, $flute, $output, @matches);

@records = ({name => 'Link', url => 'http://localhost/'},
            {name => 'No Link', url => ''},
            {name => 'Another Link', url => 'http://localhost/'},
            );

$spec_xml = <<'EOF';
<specification name="link">
<list name="links" class="linklist" iterator="links">
<param name="url" target="href"/>
<param name="link" class="url" field="name" op="append"/>
</list>
</specification>
EOF

$template =  qq{
<html>
	<div class="linklist">
		<div class="link">
			<a href="#" class="url">Goto </a>
		</div>
	</div>
</html>};

$flute = Template::Flute->new(specification => $spec_xml,
							  template => $template,
							  values => {links => \@records});

$output = $flute->process();

for my $rec (@records) {
    @matches = $output =~ m%<a class="url" href="$rec->{url}">Goto $rec->{name}</a>%g;
    ok (@matches == 1, "Checking for $rec->{name}.")
    || diag $output;
}


