package SQL::Bibliosoph::Dummy; {
	use Moose;
	use Carp;

    our $VERSION = "2.00";

    sub fetchall_arrayref { return undef };
    sub fetchrow_arrayref { return undef };
    sub fetchrow_hashref { return undef };
    sub rows { return undef };
}
