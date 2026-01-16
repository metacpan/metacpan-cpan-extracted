#
# GENERATED WITH PDL::PP from glpk.pd! Don't modify!
#
package PDL::Opt::GLPK;

our @EXPORT_OK = qw(GLP_MIN GLP_MAX GLP_CV GLP_IV GLP_BV GLP_FR GLP_LO GLP_UP GLP_DB GLP_FX GLP_MSG_OFF GLP_MSG_ERR GLP_MSG_ON GLP_MSG_ALL GLP_SF_GM GLP_SF_EQ GLP_SF_2N GLP_SF_SKIP GLP_SF_AUTO GLP_CV GLP_IV GLP_BV GLP_MSG_OFF GLP_MSG_ERR GLP_MSG_ON GLP_MSG_ALL GLP_MSG_DBG GLP_PRIMAL GLP_DUALP GLP_DUAL GLP_PT_STD GLP_PT_PSE GLP_BR_FFV GLP_BR_LFV GLP_BR_MFV GLP_BR_DTH GLP_BR_PCH GLP_BT_DFS GLP_BT_BFS GLP_BT_BLB GLP_BT_BPH GLP_RT_STD GLP_RT_HAR GLP_RT_FLIP GLP_UNDEF GLP_FEAS GLP_INFEAS GLP_NOFEAS GLP_OPT GLP_UNBND glpk );
our %EXPORT_TAGS = (Func=>\@EXPORT_OK);

use PDL::Core;
use PDL::Exporter;
use DynaLoader;


   our $VERSION = '0.08';
   our @ISA = ( 'PDL::Exporter','DynaLoader' );
   push @PDL::Core::PP, __PACKAGE__;
   bootstrap PDL::Opt::GLPK $VERSION;








#line 62 "glpk.pd"

use strict;
use warnings;

use constant GLP_MIN => 1;
use constant GLP_MAX => 2;

use constant GLP_CV => 1;
use constant GLP_IV => 2;
use constant GLP_BV => 3;

use constant GLP_FR => 1;
use constant GLP_LO => 2;
use constant GLP_UP => 3;
use constant GLP_DB => 4;
use constant GLP_FX => 5;

use constant GLP_MSG_OFF => 0;
use constant GLP_MSG_ERR => 1;
use constant GLP_MSG_ON => 2;
use constant GLP_MSG_ALL => 3;
use constant GLP_MSG_DBG => 4;

use constant GLP_SF_GM => 1;
use constant GLP_SF_EQ => 16;
use constant GLP_SF_2N => 32;
use constant GLP_SF_SKIP => 64;
use constant GLP_SF_AUTO => 128;

use constant GLP_CV => 1;
use constant GLP_IV => 2;
use constant GLP_BV => 3;

use constant GLP_MSG_OFF => 0;
use constant GLP_MSG_ERR => 1;
use constant GLP_MSG_ON => 2;
use constant GLP_MSG_ALL => 3;
use constant GLP_MSG_DBG => 4;

use constant GLP_PRIMAL => 1;
use constant GLP_DUALP => 2;
use constant GLP_DUAL => 3;

use constant GLP_PT_STD => 0x11;
use constant GLP_PT_PSE => 0x22;

use constant GLP_BR_FFV => 1;
use constant GLP_BR_LFV => 2;
use constant GLP_BR_MFV => 3;
use constant GLP_BR_DTH => 4;
use constant GLP_BR_PCH => 5;

use constant GLP_BT_DFS => 1;
use constant GLP_BT_BFS => 2;
use constant GLP_BT_BLB => 3;
use constant GLP_BT_BPH => 4;

use constant GLP_RT_STD => 0x11;
use constant GLP_RT_HAR => 0x22;
use constant GLP_RT_FLIP => 0x33;

use constant GLP_UNDEF => 1;
use constant GLP_FEAS => 2;
use constant GLP_INFEAS => 3;
use constant GLP_NOFEAS => 4;
use constant GLP_OPT => 5;
use constant GLP_UNBND => 6;

BEGIN {
	our $keys = join '|', qw(msglev dual price itlim outfrq branch
	btrack presol rtest tmlim outdly tolbnd toldj tolpiv objll objul
	tolint tolobj scale lpsolver save_pb save_fn);
}
#line 101 "GLPK.pm"

		sub PDL::Opt::GLPK::glpk {
			my $parms = ref($_[-1]) eq 'HASH' ? pop @_ : {};
			push @_, null if @_ == 11;
			push @_, null if @_ == 12;
			barf("param is not a hash ref") if @_ == 14;
			barf("argument(s) missing") if @_ < 13;
			push @_, $parms;
			our $keys;
			my @unknown = grep !/^(?:$keys)$/, keys %{$_[13]};
			barf("parameter invalid: @unknown") if @unknown;
			barf("cannot broadcast over 'a'") if $_[1]->ndims > 2;
			my $at = $_[1]->xchg(0, 1);
			my $a = pdl(0)->append($at->isa('PDL::CCS::Nd') ?
				$at->[$PDL::CCS::Nd::VALS]->slice('0:-2') :
				$at->where($at));
			my $nnz = $a->nelem;
			my $w = $at->whichND;
			my $rn = zeroes($nnz);
			my $cn = zeroes($nnz);
			$rn->slice('1:-1') .= $w->slice('(0)') + 1;
			$cn->slice('1:-1') .= $w->slice('(1)') + 1;

			PDL::Opt::GLPK::_glpk_int($_[0], $rn, $cn, $a, @_[2..$#_]);
		}
	


*glpk = \&PDL::Opt::GLPK::glpk;







# Exit with OK status

1;
