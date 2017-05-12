
#
# Package Meta:  Meta Data.  It's the data about the data.
#

package Shell::Meta;
use strict;

use Exporter ();
use vars qw(@ISA $VERSION);
$VERSION = $VERSION = q{1.0};
@ISA=('Exporter');

# DBI does all the hard work on this one.
sub all_tables {
	my ($self, $parent) = @_;

	$parent->{dbiwd}->Busy;
	my $sth = $parent->{dbh}->table_info;
	if ($parent->{dbh}->err) {
		warn qq{Table information is not available: } . 
			$parent->{dbh}->errstr;
	} else {
   $parent->sth_go( $sth, 1 );
	 $parent->display_results( $sth );
	}
	$parent->{dbiwd}->Unbusy;
}

1;
