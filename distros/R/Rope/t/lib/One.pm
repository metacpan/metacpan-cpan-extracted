package One;

use Rope;
use Rope::Autoload;

prototyped (
	one => sub {
		$_[1] ? $_[1] : $_[0]->{two}();	
	},
	two => sub {
		return 50;
	}
);

1;
