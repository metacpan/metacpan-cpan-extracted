
package OI18nTest::Storage::Greeting;
use strict;
use warnings;
use base qw(Object::I18n::Storage::CDBI);
use OI18nTest::CDBI;

sub init {
    my $self = shift;
    $self->{cdbi_class} = 'OI18nTest::CDBI';
    return $self;
}


1;
