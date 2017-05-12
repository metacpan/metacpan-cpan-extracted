
package Paper::Specs::base::sheet;
use strict;

use vars qw($VERSION);
$VERSION=0.01;

sub new {
    my $class=shift;
    bless \$class, $class unless ref($class);
}

sub type { return 'sheet' }

sub sheet_width  { Paper::Specs::convert ($_[0]->specs->{'sheet_width'},  $_[0]->specs->{'units'}) }
sub sheet_height { Paper::Specs::convert ($_[0]->specs->{'sheet_height'}, $_[0]->specs->{'units'}) }
sub sheet_size   { return ($_[0]->sheet_width, $_[0]->sheet_height) }

sub specs {
    die "$_[0] does not have any specs defined!\n";
}

sub code        { $_[0]->specs->{'code'}        }
sub description { $_[0]->specs->{'description'} }

1;

