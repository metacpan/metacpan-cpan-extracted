use strict;
use warnings;
use Test::More tests => 1;

use PerlIO::via::UnPod;

BEGIN {
	{

		package KaputPrint;
		use strict;

		sub TIEHANDLE {
			my $class = shift;
			bless [], $class;
		}

		sub PRINT {
			my $self = shift;
			return 0;
		}

		sub PRINTF {
			my $self = shift;
			my $fmt  = shift;
			push @$self, sprintf $fmt, @_;
		}

		sub READLINE {
			my $self = shift;
			pop @$self;
		}
	}
}

tie *FH, "KaputPrint";
my $ahh =
  eval { return PerlIO::via::UnPod::WRITE( { insrc => 1 }, 'die', *FH ); };
is( $ahh, -1 );

done_testing();

