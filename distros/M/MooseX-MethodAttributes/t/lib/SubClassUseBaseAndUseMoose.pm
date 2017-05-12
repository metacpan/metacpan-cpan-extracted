use strict;
use warnings;

package SubClassUseBaseAndUseMoose;

use base qw/BaseClass/;

use Moose;

sub bar : Bar {}

before affe => sub {};
no Moose;

1;
