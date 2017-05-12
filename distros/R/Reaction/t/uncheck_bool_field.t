use strict;
use warnings;
use Test::More qw(no_plan);
BEGIN { $ENV{DBIC_OVERWRITE_HELPER_METHODS_OK} = 1; }

use Test::WWW::Mechanize::Catalyst 'ComponentUI';

my $mech = Test::WWW::Mechanize::Catalyst->new;
$mech->get_ok('http://localhost/testmodel/baz/id/1/update');
# print $mech->content, "\n";
$mech->tick('r-vp-1-field-bool_field:value_string', 1);
$mech->submit_form(button => 'r-vp-1:apply');
$mech->content_like(qr{checked="checked"}, 'checked');
$mech->untick('r-vp-1-field-bool_field:value_string', 1);
$mech->submit_form(button => 'r-vp-1:apply');
$mech->content_unlike(qr{checked="checked"}, 'should not be checked');
