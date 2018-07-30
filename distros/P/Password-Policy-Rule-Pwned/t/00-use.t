#
#===============================================================================
#
#         FILE: 00-use.t
#
#  DESCRIPTION: Can we use it
#
#       AUTHOR: Pete Houston (), cpan@openstrike.co.uk
# ORGANIZATION: Openstrike
#      VERSION: 0.0
#      CREATED: 29/05/18 15:34:18
#     REVISION: ---
#===============================================================================

use strict;
use warnings;

use Test::More tests => 6;

BEGIN {
	use_ok ('Password::Policy::Exception::Pwned');
	use_ok ('Password::Policy::Exception::PwnedError');
	use_ok ('Password::Policy::Rule::Pwned');
}

my $ver = '0.01';

is ($Password::Policy::Rule::Pwned::VERSION, $ver, 'Rule version');
is ($Password::Policy::Exception::Pwned::VERSION, $ver, 'Pwned version');
is ($Password::Policy::Exception::PwnedError::VERSION, $ver,
	'PwnedError version');
