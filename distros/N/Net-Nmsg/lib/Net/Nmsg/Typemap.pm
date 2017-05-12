# Use of the Net-Silk library and related source code is subject to the
# terms of the following licenses:
# 
# GNU Public License (GPL) Rights pursuant to Version 2, June 1991
# Government Purpose License Rights (GPLR) pursuant to DFARS 252.227.7013
# 
# NO WARRANTY
# 
# ANY INFORMATION, MATERIALS, SERVICES, INTELLECTUAL PROPERTY OR OTHER 
# PROPERTY OR RIGHTS GRANTED OR PROVIDED BY CARNEGIE MELLON UNIVERSITY 
# PURSUANT TO THIS LICENSE (HEREINAFTER THE "DELIVERABLES") ARE ON AN 
# "AS-IS" BASIS. CARNEGIE MELLON UNIVERSITY MAKES NO WARRANTIES OF ANY 
# KIND, EITHER EXPRESS OR IMPLIED AS TO ANY MATTER INCLUDING, BUT NOT 
# LIMITED TO, WARRANTY OF FITNESS FOR A PARTICULAR PURPOSE, 
# MERCHANTABILITY, INFORMATIONAL CONTENT, NONINFRINGEMENT, OR ERROR-FREE 
# OPERATION. CARNEGIE MELLON UNIVERSITY SHALL NOT BE LIABLE FOR INDIRECT, 
# SPECIAL OR CONSEQUENTIAL DAMAGES, SUCH AS LOSS OF PROFITS OR INABILITY 
# TO USE SAID INTELLECTUAL PROPERTY, UNDER THIS LICENSE, REGARDLESS OF 
# WHETHER SUCH PARTY WAS AWARE OF THE POSSIBILITY OF SUCH DAMAGES. 
# LICENSEE AGREES THAT IT WILL NOT MAKE ANY WARRANTY ON BEHALF OF 
# CARNEGIE MELLON UNIVERSITY, EXPRESS OR IMPLIED, TO ANY PERSON 
# CONCERNING THE APPLICATION OF OR THE RESULTS TO BE OBTAINED WITH THE 
# DELIVERABLES UNDER THIS LICENSE.
# 
# Licensee hereby agrees to defend, indemnify, and hold harmless Carnegie 
# Mellon University, its trustees, officers, employees, and agents from 
# all claims or demands made against them (and any related losses, 
# expenses, or attorney's fees) arising out of, or relating to Licensee's 
# and/or its sub licensees' negligent use or willful misuse of or 
# negligent conduct or willful misconduct regarding the Software, 
# facilities, or other rights or assistance granted by Carnegie Mellon 
# University under this License, including, but not limited to, any 
# claims of product liability, personal injury, death, damage to 
# property, or violation of any laws or regulations.
# 
# Carnegie Mellon University Software Engineering Institute authored 
# documents are sponsored by the U.S. Department of Defense under 
# Contract FA8721-05-C-0003. Carnegie Mellon University retains 
# copyrights in all material produced under this contract. The U.S. 
# Government retains a non-exclusive, royalty-free license to publish or 
# reproduce these documents, or allow others to do so, for U.S. 
# Government purposes only pursuant to the copyright license under the 
# contract clause at 252.227.7013.

package Net::Nmsg::Typemap;

use strict;
use warnings;
use Carp;

sub make_mapper {
  my($class, $type, $idx) = @_;
  croak "type required"  unless defined $type;
  croak "index required" unless defined $idx;
  my $map_makers = $class->map_makers;
  $map_makers->[$type] ? $map_makers->[$type]->($idx, $type) : ();
}

###

package Net::Nmsg::Typemap::Input;

use strict;
use warnings;
use Carp;

use base qw( Net::Nmsg::Typemap );

use Net::Nmsg::Util qw( :field );

use NetAddr::IP::Util qw( inet_aton ipv6_aton );

my @From;

sub map_makers { \@From };

sub _from_ip { $_[0] =~ /:/ ? ipv6_aton($_[0]) : inet_aton($_[0]) }

$From[NMSG_FT_IP  ] = sub { \&_from_ip     };
$From[NMSG_FT_ENUM] = sub {
  my $idx = shift;
  sub {
    my($val, $class) = @_;
    if ($val !~ /^\d+$/) {
      my $name = $val;
      $val = $class->_class_msg->enum_name_to_value_by_idx($idx, $name);
      croak "unknown enum value '$name'" unless defined $val;
    }
    $val;
  };
};

#######

package Net::Nmsg::Typemap::Output;

use strict;
use warnings;
use Carp;

use base qw( Net::Nmsg::Typemap );

use Net::Nmsg::Util qw( :field );

use NetAddr::IP::Util qw( ipv6_n2x inet_ntoa );

my @To;

sub map_makers { \@To };

sub _to_ip { length $_[0] > 4 ? ipv6_n2x($_[0]) : inet_ntoa($_[0]) }

$To[NMSG_FT_IP  ] = sub { \&_to_ip     };
$To[NMSG_FT_ENUM] = sub {
  my $idx = shift;
  sub {
    my($val, $class) = @_;
    my $name = $class->_class_msg->enum_value_to_name_by_idx($idx, $val);
    croak "unknown enum value '$val'" unless defined $name;
    $name;
  };
};

###

1;
