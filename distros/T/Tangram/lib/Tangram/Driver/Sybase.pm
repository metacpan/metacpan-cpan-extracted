

package Tangram::Driver::Sybase;
use strict;

use Tangram::Driver::Sybase::Storage;

use vars qw(@ISA);
 @ISA = qw( Tangram::Relational );

sub connect {
    my ($pkg, $schema, $cs, $user, $pw, $opts) = @_;
    ${$opts||={}}{driver} = $pkg->new();
    my $storage = Tangram::Driver::Sybase::Storage->connect
	( $schema, $cs, $user, $pw, $opts );
}

1;

