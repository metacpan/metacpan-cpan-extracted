#
# $Id: Translate.pm 14 2008-04-30 09:32:59Z esobchenko $

package REST::Google::Translate;

use strict;
use warnings;

use version; our $VERSION = qv('1.0.8');

require Exporter;
require REST::Google;
use base qw/Exporter REST::Google/;

__PACKAGE__->service('http://ajax.googleapis.com/ajax/services/language/translate');

sub responseData {
	my $self = shift;
	return bless $self->{responseData}, 'REST::Google::Translate::Data';
}

package # hide from CPAN
	REST::Google::Translate::Data;

require Class::Accessor;
use base qw/Class::Accessor/;

__PACKAGE__->mk_ro_accessors( qw/translatedText/ );

1;
