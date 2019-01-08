package MySQL::Util::Lite::Roles::NewColumn;

our $VERSION = '0.01';

use Modern::Perl;
use Moose::Role;
use Method::Signatures;
use Data::Printer alias => 'pdump';

method new_column (HashRef $column_descript) {

	my $col = $column_descript;
	
	return MySQL::Util::Lite::Column->new(
		name        => $col->{FIELD},
		key         => $col->{KEY},
		default     => $col->{DEFAULT},
		type        => $col->{TYPE},
		is_null     => $col->{NULL} =~ /^yes$/i ? 1 : 0,
		is_autoinc  => $col->{EXTRA} =~ /auto_increment/i ? 1 : 0,
	);
}

1;
