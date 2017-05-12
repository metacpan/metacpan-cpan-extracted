use Test::More tests => 1;

use strict;
use Template;

# ### Basic Textile ####

my $template_source = "
[%- USE Textile2 -%]
[%- FILTER textile2 -%]
This is *bold* and this is _italic_.
[%- END -%]
";

my $t = Template->new();

my $output;
$t->process(\$template_source, undef, \$output) or die "Can't process template";

ok( $output eq '<p>This is <strong>bold</strong> and this is <em>italic</em>.</p>' );

# ### No-HTML ###

#TODO

# ### Inline ####

#TODO

1;

