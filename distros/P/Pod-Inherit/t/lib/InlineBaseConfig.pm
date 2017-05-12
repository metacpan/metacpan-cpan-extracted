package InlineBaseConfig;

use strict;
use warnings;

## Configure inline: claim docs for all methods in this class
## are in SimpleSubClass, also allow underscored methods

our %_pod_inherit_config = 
  (
   skip_underscored => 0,
   class_map => { 'InlineBaseConfig' => 'Something::Else' }
  );

sub _myunderscore {
    'show this despite underscore';
}

1;
