use 5.008008;
use strict;
use warnings;

package MooX::Press::Keywords;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.048';

use Type::Library -base;
use Type::Utils ();

BEGIN {
	Type::Utils::extends(qw/
		Types::Standard
		Types::Common::Numeric
		Types::Common::String
	/);
};

our (%EXPORT_TAGS, @EXPORT_OK);

sub true  ()   { !!1 }
sub false ()   { !!0 }

$EXPORT_TAGS{ 'booleans' } = [qw/ true false /];

sub ro   ()    { 'ro'      }
sub rw   ()    { 'rw'      }
sub rwp  ()    { 'rwp'     }
sub lazy ()    { 'lazy'    }
sub bare ()    { 'bare'    }
sub private () { 'private' }

$EXPORT_TAGS{ 'privacy' } = [qw/ ro rw rwp lazy bare private /];

use Scalar::Util qw( blessed );
sub confess {
	@_ = sprintf(shift, @_) if @_ > 1;
	require Carp;
	goto \&Carp::confess;
}

$EXPORT_TAGS{ 'util' } = [qw/ blessed confess /];

push @EXPORT_OK, map @{$EXPORT_TAGS{$_}}, keys(%EXPORT_TAGS);

my $orig = 'Type::Library'->can('import');
sub import {
	'strict'->import;
	'warnings'->import;
	push @_, -all if @_ == 1;
	goto $orig;
}

1;

__END__

