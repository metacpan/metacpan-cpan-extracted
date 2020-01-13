#!/usr/bin/env perl 
#===============================================================================
#
#         FILE: synopsis.pl
#
#        USAGE: ./synopsis.pl  
#
#  DESCRIPTION: 
#
#      OPTIONS: ---
# REQUIREMENTS: ---
#         BUGS: ---
#        NOTES: ---
#       AUTHOR: Pete Houston (pete), cpan@openstrike.co.uk
# ORGANIZATION: Openstrike
#      VERSION: 1.0
#      CREATED: 06/01/20 15:06:23
#     REVISION: ---
#===============================================================================

use strict;
use warnings;
use Template;

my $tsrc = <<'EOT';
[% USE infl = Lingua.EN.Inflexion; -%]
[% FOR obj IN objects; -%]
[% FOR n IN [0, 1, 2]; -%]
[% FILTER inflect; -%]
  <#d:$n>There <V:was> <#n:$n> <N:$obj.name>.
[% IF n > 0 %]  <A:This> <N:$obj.name> <V:was> ${obj.colour}.
[% END; END; END %]
[% END; -%]
EOT

my $data = {
	objects => [
		{ name => 'dog', colour => 'brown' },
		{ name => 'goose', colour => 'white' },
		{ name => 'fish', colour => 'gold' }
	]
};

my $template = Template->new ({INTERPOLATE => 1});
$template->process (\$tsrc, $data);
