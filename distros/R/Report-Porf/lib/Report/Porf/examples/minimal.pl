# perl
#
# minimal example for PORF

use warnings;
use strict;

use lib '../../..';

use Report::Porf qw(:all);
auto_report(get_data(), shift); # second call arg could be file

# ----------------------------------------------------- 

sub get_data {
	return [{
		prename => 'Ralf',
		surname => 'Peine',
		age     => 48
	}];
}

# ----------------------------------------------------- 

__END__

prints out:

*=====+=========+=========*
| age | prename | surname |
*-----+---------+---------*
| 48  | Ralf    | Peine   |
*=====+=========+=========*


