use vars qw(@classes);

BEGIN
	{
	@classes = ('Palm', map { "Palm::$_" }
		qw( Address Datebook Mail Memo StdAppInfo ToDo ));
	}

use Test::More tests => scalar @classes;

foreach my $class ( @classes )
	{
	use_ok( $class );
	}

