# -*- Mode: Perl; -*-

=head1 NAME

00_use.t - Test the use/import/can functionality of Template::Alloy

=cut

use strict;
use warnings;

use Test::More tests => 43;

###----------------------------------------------------------------###
### loading via can, use, and import

use_ok('Template::Alloy');

### autoload via can
ok(! $INC{'Template/Alloy/Parse.pm'},  "Parse role isn't loaded yet");
ok(Template::Alloy->can('parse_tree'), "But it can parse anyway");
ok($INC{'Template/Alloy/Parse.pm'},    "Parse role is now loaded");

ok(! eval "use Template::Alloy qw(garbage); 1", "Can't import invalid method");

### autoload via Role in use
ok(! $INC{'Template/Alloy/Play.pm'},       "Play role isn't loaded yet");
ok(eval "use Template::Alloy qw(Play); 1", "It can be imported ($@)");
ok($INC{'Template/Alloy/Play.pm'},         "Play role is now loaded");

### autoload via Role in use with sugar
ok(! $INC{'Template/Alloy/Compile.pm'},             "Compile role isn't loaded yet");
ok(eval "use Template::Alloy load => 'Compile'; 1", "It can be imported ($@)");
ok($INC{'Template/Alloy/Compile.pm'},               "Compile role is now loaded");
ok(eval "use Template::Alloy load => 'Compile'; 1", "It can be imported  twice ($@)");

### autoload via Role in use with sugar
ok(! $INC{'Template/Alloy/Velocity.pm'},        "Velocity role isn't loaded yet");
ok(eval "use Template::Alloy Velocity => 1; 1", "It can be imported ($@)");
ok($INC{'Template/Alloy/Velocity.pm'},          "Velocity role is now loaded");

### autoload via method in use with sugar
ok(! $INC{'Template/Alloy/Tmpl.pm'},                "Tmpl role isn't loaded yet");
ok(eval "use Template::Alloy parse_string => 1; 1", "It can be imported ($@)");
ok($INC{'Template/Alloy/Tmpl.pm'},                  "Tmpl role is now loaded");

### override module namespace that isn't yet loaded
ok(! $INC{'Text/Tmpl.pm'},                     "Text::Tmpl isn't loaded");
ok(eval "use Template::Alloy 'Text::Tmpl'; 1", "It can be imported ($@)");
ok($INC{'Text/Tmpl.pm'},                       "Text::Tmpl is now loaded");
ok(Text::Tmpl->isa('Template::Alloy'),         "Text::Tmpl is a Template::Alloy");
ok(eval "use Template::Alloy 'Text::Tmpl'; 1", "It can be imported twice");

### override module namespace that isn't yet loaded
ok(! $INC{'HTML/Template.pm'},                     "HTML::Template isn't loaded");
eval "{package HTML::Template; \$INC{'HTML/Template.pm'}=1}"; # simulate loading HTML::Template
ok(! eval "use Template::Alloy 'HTML::Template'; 1", "It can't be imported because another non-Alloy package already is using it");
ok(! HTML::Template->isa('Template::Alloy'),         "HTML::Template is not a Template::Alloy");

### override module namespace that isn't yet loaded
ok(! $INC{'HTML/Template/Expr.pm'},                       "HTML::Template::Expr isn't loaded");
ok(eval{Template::Alloy->import('HTML::Template::Expr')}, "It can be imported ($@)");
ok($INC{'HTML/Template/Expr.pm'},                         "HTML::Template::Expr is now loaded");
ok(HTML::Template::Expr->isa('Template::Alloy'),          "HTML::Template::Expr is a Template::Alloy");
ok(eval{Template::Alloy->import('HTML::Template::Expr')}, "It can be imported twice");

### autoload via "all"
ok(! $INC{'Template/Alloy/TT.pm'},              "TT role isn't loaded yet");
ok(eval "use Template::Alloy load => 'all'; 1", "It can be imported via all ($@)");
ok($INC{'Template/Alloy/TT.pm'},                "TT role is now loaded");
ok(eval "use Template::Alloy load => 'all'; 1", "It can be imported twice ($@)");

### override module namespace that isn't yet loaded
ok(! $INC{'Template.pm'},                    "Template isn't loaded");
ok(eval "use Template::Alloy 'Template'; 1", "It can be imported ($@)");
ok($INC{'Template.pm'},                       "Template is now loaded");
ok(Template->isa('Template::Alloy'),         "Template is a Template::Alloy");
ok(eval "use Template::Alloy 'Template'; 1", "It can be imported twice");

###----------------------------------------------------------------###

ok(! eval { Template::Alloy->flabbergast } && $@, "Got an error on invalid methods ($@)");
my $meth = '';
ok(! eval { Template::Alloy->$meth() } && $@, "Got an error on invalid methods ($@)");
$meth = 'foo&bar';
ok(! eval { Template::Alloy->$meth() } && $@, "Got an error on invalid methods ($@)");

###----------------------------------------------------------------###

