package Module::Build::SubClass;

use strict;
use vars qw($VERSION @ISA);

$VERSION = '0.01';

use Module::Build;
@ISA = qw(Module::Build);


__PACKAGE__->add_property('custom_flag' => 'flag_value');
__PACKAGE__->add_property('custom_array' => []);
__PACKAGE__->add_property('custom_hash' => {});


sub ACTION_custom {
    print "custom action called";
}


1;
