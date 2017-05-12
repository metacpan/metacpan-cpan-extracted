
package OI18nTest::Greeting;
use strict;
use warnings;

use Object::I18n;
__PACKAGE__->i18n->register('greeting');

sub new {
    my $class = shift;
    bless \shift, $class;
}

sub greeting {
    my $self = shift;
    @_ ? ($$self = shift) : $$self;
}

sub id { 1 }

1;
