package dummy;
use strict;
use warnings;
use Sub::Stubber;

our @EXPORT = qw(expensive_function);

#use base qw(Sub::Stubber Exporter);
our @ISA = qw(Sub::Stubber Exporter);

Sub::Stubber->regstubs('expensive_function');
Sub::Stubber->regstubs({
        replaced_function => sub { 1 }
    });

Sub::Stubber->add_trigger(env => 'DOUBLE_FACED_DUMMIES');

sub expensive_function ($$$) {
    'expensive calculation';
}

sub replaced_function {
    0;
}

package dummy_trigger;
use strict;
use warnings;
use Sub::Stubber;
use parent qw(Sub::Stubber Exporter);
Sub::Stubber->regstubs('expensive2');
Sub::Stubber->add_trigger(import => 'BE_A_DUMMY');

our @EXPORT = qw(expensive2);

$INC{'dummy_trigger.pm'} =1;

sub expensive2 {
    'anothe expensive function';
}

package dummy_ext;
use strict;
use warnings;
use Sub::Stubber;
use parent qw(Exporter);

our @EXPORT = qw(cheapo returns_a_value);

Sub::Stubber->regstubs('cheapo', { returns_a_value => 42 });

$INC{'dummy_ext.pm'} = 1;

sub import {
    if(grep $_ eq 'cheapo', @_) {
        Sub::Stubber->mkstubs();
    }
    goto &Exporter::import;
}

sub cheapo { 'cheap_function' }
sub returns_a_value { 0xdeadbeef }

package dummy_notrigger;
use strict;
use warnings;
use Sub::Stubber;
use parent qw(Sub::Stubber Exporter);
our @EXPORT = qw(foofunc);

Sub::Stubber->regstubs({
        foofunc => sub { 0 }
    });
Sub::Stubber->add_trigger(import => 'dont_use_this');

sub foofunc {
    1;
}
BEGIN {
    $INC{'dummy_notrigger.pm'} = 1;
}

1;
