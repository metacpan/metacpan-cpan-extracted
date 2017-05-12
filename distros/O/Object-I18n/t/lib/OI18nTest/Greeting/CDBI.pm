
package OI18nTest::Greeting::CDBI;
use strict;
use warnings;

use Object::I18n (storage_class => 'OI18nTest::Storage::Greeting');
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
