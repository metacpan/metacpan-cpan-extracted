# COPYRIGHT:
#
# Copyright 2009 REN-ISAC[1] and The Trustees of Indiana University[2]
#
# LICENSE:
#
# This work is made available to you under the terms of Version 2 of
# the GNU General Public License.
#
# This work is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA
# 02110-1301 or visit their web page on the internet at
# http://www.gnu.org/licenses/old-licenses/gpl-2.0.html.
#
# Author saxjazman@cpan.org (with the help of BestPractical.com)
#
# [1] http://www.ren-isac.net
# [2] http://www.indiana.edu

package RT::Condition::IODEF;

use strict;
use warnings;

use base 'RT::Condition::Generic';

use XML::IODEF;

sub IsIODEF {
        my $self = shift;
        my $content = shift;
        unless($content){
                $content = $self->TransactionObj->Content();
        }
        return(undef) unless($content);

        $RT::Logger->debug('Checking to see if its an IODEF Document');

        $RT::Logger->debug($content);
        return unless($content =~/^(<\?xml version="1.0" encoding="UTF-8"\?>\n)?<IODEF-Document.*/);

        my $iodef = XML::IODEF->new();
        $iodef->in($content);

        unless($iodef->out()){
                $RT::Logger->error('This is not a properly formatted IODEF doc');
                return(undef);
        }
        $RT::Logger->debug('Properly formatted IODEF doc');
        return($iodef);
}

1;
