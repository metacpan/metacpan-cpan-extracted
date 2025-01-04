## File: PDL::CCS::Nd.pm
## Author: Bryan Jurish <moocow@cpan.org>
## Description: N-dimensional CCS-encoded pseudo-PDL

package PDL::CCS::Nd;
use PDL::Lite qw();
use PDL::VectorValued;
use PDL::CCS::Config qw(ccs_indx);
use PDL::CCS::Functions qw(ccs_decode ccs_qsort);
use PDL::CCS::Utils     qw(ccs_encode_pointers ccs_decode_pointer);
use PDL::CCS::Ufunc;
use PDL::CCS::Ops;
use PDL::CCS::MatrixOps;
use Carp;
use strict;

BEGIN {
  *isa = \&UNIVERSAL::isa;
  *can = \&UNIVERSAL::can;
}

our $VERSION = '1.24.1'; ##-- update with perl-reversion from Perl::Version module
our @ISA = qw();
our %EXPORT_TAGS =
  (
   ##-- respect PDL conventions (hopefully)
   Func  => [
             ##-- Encoding/Decoding
             qw(toccs todense),
            ],
   vars  => [
             qw($PDIMS $VDIMS $WHICH $VALS $PTRS $FLAGS $USER),
             qw($BINOP_BLOCKSIZE_MIN $BINOP_BLOCKSIZE_MAX),
            ],
   flags => [
             qw($CCSND_BAD_IS_MISSING $CCSND_NAN_IS_MISSING $CCSND_INPLACE $CCSND_FLAGS_DEFAULT),
            ],
  );
$EXPORT_TAGS{all} = [map {@$_} values(%EXPORT_TAGS)];
our @EXPORT    = @{$EXPORT_TAGS{Func}};
our @EXPORT_OK = @{$EXPORT_TAGS{all}};

##--------------------------------------------------------------
## Global variables for block-wise computation of binary operations

##-- some (hopefully sensible) defaults
#our $BINOP_BLOCKSIZE_MIN =    64;
#our $BINOP_BLOCKSIZE_MAX = undef; ##-- undef or zero: no maximum

##-- debug/devel defaults
our $BINOP_BLOCKSIZE_MIN  =      1;
our $BINOP_BLOCKSIZE_MAX  =      0;

##======================================================================
## Globals

our $PDIMS   = 0;
our $VDIMS   = 1;
our $WHICH   = 2;
our $VALS    = 3;
our $PTRS    = 4;
our $FLAGS   = 5;
our $USER    = 6;

##-- flags
our $CCSND_BAD_IS_MISSING = 1;
our $CCSND_NAN_IS_MISSING = 2;
our $CCSND_INPLACE        = 4;
our $CCSND_FLAGS_DEFAULT  = 0; ##-- default flags

##-- pdl constants
our $P_BYTE = PDL::byte();
our $P_LONG = PDL::long();
our $P_INDX = ccs_indx();

sub _min2 ($$) { $_[0]<$_[1] ? $_[0] : $_[1]; }
sub _max2 ($$) { $_[0]>$_[1] ? $_[0] : $_[1]; }

##======================================================================
## Constructors etc.

## $obj = $class_or_obj->newFromDense($denseND);
## $obj = $class_or_obj->newFromDense($denseND,$missing);
## $obj = $class_or_obj->newFromDense($denseND,$missing,$flags);
##  + object structure: ARRAY
##     $PDIMS   => $pdims,     ##-- pdl(indx,$NPdims)     : physical dimension sizes : $pdim_i => $dimSize_i
##     $VDIMS   => $vdims,     ##-- pdl(indx,$NVdims)     : virtual dimension sizes
##                             ##     + $vdim_i => / -$vdimSize_i   if $vdim_i is dummy
##                             ##                  \  $pdim_i       otherwise
##                             ##     + s.t. $whichND_logical_physical = $whichND->dice_axis(0,$vdims->where($vdims>=0));
##     $WHICH   => $whichND,   ##-- pdl(indx,$NPdims,$Nnz) ~ $dense_orig->whichND
##                             ##   + guaranteed to be sorted as for qsortvec() specs
##                             ##   + NOT changed by dimension-shuffling transformations
##     $VALS    => $vals,      ##-- pdl( ?  ,$Nnz+1)      ~ $dense->where($dense)->append($missing)
##     $PTRS    => \@PTRS,     ##-- array of ccsutils-pointers by physical dimension number
##     $FLAGS   => $flags,     ##-- integer holding some flags
##
##  + each element of @PTRS is itself an array:
##     $PTRS[$i] => [ $PTR, $NZI ]
##
sub newFromDense :lvalue {
  my $that = shift;
  return my $tmp=(bless [], ref($that)||$that)->fromDense(@_);
}

## $obj = $obj->fromDense($denseND,$missing,$flags)
sub fromDense :lvalue {
  my ($obj,$p,$missing,$flags) = @_;
  $p = PDL->topdl($p);
  $p = $p->slice("*1") if (!$p->dims);
  $missing     = (defined($missing)
                  ? PDL->pdl($p->type,$missing)
                  : ($p->badflag
                     ? PDL->pdl($p->type,0)->setvaltobad(0)
                     : PDL->pdl($p->type,0)));
  $flags = $CCSND_FLAGS_DEFAULT if (!defined($flags));
  my $pwhichND = ($missing->isbad ? $p->isgood() : ($p != $missing))->whichND->vv_qsortvec;
  my $pnz  = $p->indexND($pwhichND)->append($missing);
  $pnz->sever;                       ##-- always sever nzvals ?
  my $pdims = PDL->pdl($P_INDX,[$p->dims]);
  $obj->[$PDIMS]   = $pdims;
  $obj->[$VDIMS]   = $pdims->isempty ? $pdims->pdl : $pdims->sequence;
  $obj->[$WHICH]   = $pwhichND;
  $obj->[$VALS]    = $pnz;
  $obj->[$PTRS]    = [];            ##-- do we really need this ... yes
  $obj->[$FLAGS]   = $flags;
  return $obj;
}

## $obj = $class_or_obj->newFromWhich($whichND,$nzvals,%options);
## $obj = $class_or_obj->newFromWhich($whichND,$nzvals);
##  + %options: see $obj->fromWhich()
sub newFromWhich :lvalue {
  my $that = shift;
  return my $tmp=bless([],ref($that)||$that)->fromWhich(@_);
}

## $obj = $obj->fromWhich($whichND,$nzvals,%options);
## $obj = $obj->fromWhich($whichND,$nzvals);
##  + %options:
##     sorted  => $bool,    ##-- if true, $whichND is assumed to be pre-sorted
##     steal   => $bool,    ##-- if true, $whichND and $nzvals are used literally (formerly implied 'sorted')
##                          ##    + in this case, $nzvals should really be: $nzvals->append($missing)
##     pdims   => $pdims,   ##-- physical dimension list; default guessed from $whichND (alias: 'dims')
##     missing => $missing, ##-- default: BAD if $nzvals->badflag, 0 otherwise
##     vdims   => $vdims,   ##-- virtual dims (default: sequence($nPhysDims)); alias: 'xdims'
##     flags   => $flags,   ##-- flags
sub fromWhich :lvalue {
  my ($obj,$wnd,$nzvals,%opts) = @_;
  my $missing = (defined($opts{missing})
                 ? PDL->pdl($nzvals->type,$opts{missing})
                 : ($nzvals->badflag
                    ? PDL->pdl($nzvals->type,0)->setvaltobad(0)
                    : PDL->pdl($nzvals->type,0)));

  ##-- get dims
  my $pdims = $opts{pdims} // $opts{dims} // PDL->pdl($P_INDX, [($wnd->xchg(0,1)->maximum+1)->list]);
  $pdims    = PDL->pdl($P_INDX, $pdims) if (!UNIVERSAL::isa($pdims,'PDL'));

  my $vdims = $opts{vdims} // $opts{xdims} // $pdims->sequence;
  $vdims    = PDL->pdl($P_INDX, $vdims) if (!UNIVERSAL::isa($vdims,'PDL'));

  ##-- maybe sort & copy
  if (!$opts{steal}) {
    ##-- not stolen: copy or sever
    if (!$opts{sorted}) {
      my $wi   = $wnd->qsortveci;
      $wnd     = $wnd->dice_axis(1,$wi);
      $nzvals  = $nzvals->index($wi);
    }
    $wnd->sever;                         ##-- sever (~ copy)
    $nzvals = $nzvals->append($missing); ##-- copy (b/c append)
  }
  elsif (!$opts{sorted}) {
    ##-- "stolen" but un-sorted: we have "missing" value in $vals
    my $wi = PDL->zeroes(ccs_indx, $wnd->dim(1)+1);
    $wnd->vv_qsortveci($wi->slice("0:-2"));
    $wi->set($wnd->dim(1) => $nzvals->nelem-1);
    $wnd    = $wnd->dice_axis(1,$wi->slice("0:-2"));
    $nzvals = $nzvals->index($wi);
  }

  ##-- setup and return
  $obj->[$PDIMS]   = $pdims;
  $obj->[$VDIMS]   = $vdims;
  $obj->[$WHICH]   = $wnd;
  $obj->[$VALS]    = $nzvals;
  $obj->[$PTRS]    = [];
  $obj->[$FLAGS]   = defined($opts{flags}) ? $opts{flags} : $CCSND_FLAGS_DEFAULT;
  return $obj;
}


## DESTROY : avoid PDL inheritance
sub DESTROY { ; }

## $ccs = $ccs->insertWhich($whichND,$whichVals)
##  + set or insert $whichND=>$whichVals
##  + implicitly calls make_physically_indexed
sub insertWhich :lvalue {
  my ($ccs,$which,$vals) = @_;
  $ccs->make_physically_indexed();

  ##-- sanity check
  if ($which->dim(0) != $ccs->[$WHICH]->dim(0)) {
    PDL::Lite::barf(ref($ccs)."::insertWhich(): wrong number of index dimensions in whichND argument:",
         " is ", $which->dim(0), ", should be ", $ccs->[$WHICH]->dim(0));
  }

  ##-- check for existing indices (potentially slow)
  my $nzi                = $ccs->indexNDi($which);
  my ($nzi_new,$nzi_old) = ($nzi==$ccs->[$WHICH]->dim(1))->which_both;

  ##-- just set values for existing indices
  $ccs->[$VALS]->index($nzi->index($nzi_old)) .= $vals->index($nzi_old);

  ##-- delegate insertion of new values to appendWhich()
  my ($tmp);
  return $tmp=$ccs->sortwhich if ($nzi_new->isempty);
  return $tmp=$ccs->appendWhich($which->dice_axis(1,$nzi_new), $vals->index($nzi_new));
}

## $ccs = $ccs->appendWhich($whichND,$whichVals)
##  + inserts $whichND=>$whichVals into $ccs which are assumed NOT to be already present
##  + implicitly calls make_physically_indexed
sub appendWhich :lvalue {
  my ($ccs,$which,$vals) = @_;
  $ccs->make_physically_indexed();

  ##-- sanity check
  #if ($which->dim(0) != $ccs->[$WHICH]->dim(0))
  if ($which->dim(0) != $ccs->[$PDIMS]->nelem)
    {
      PDL::Lite::barf(ref($ccs)."::appendWhich(): wrong number of index dimensions in whichND argument:",
           " is ", $which->dim(0), ", should be ", $ccs->[$PDIMS]->nelem);
    }

  ##-- append: which
  if (!$which->isempty) {
    $ccs->[$WHICH] = $ccs->[$WHICH]->reshape($which->dim(0), $ccs->[$WHICH]->dim(1)+$which->dim(1));
    $ccs->[$WHICH]->slice(",-".$which->dim(1).":-1") .= $which;
  }

  ##-- append: vals
  if (!$vals->isempty) {
    my $missing    = $ccs->missing;
    $ccs->[$VALS]  = $ccs->[$VALS]->reshape($ccs->[$VALS]->dim(0) + $vals->dim(0));
    $ccs->[$VALS]->slice("-".($vals->dim(0)+1).":-2") .= $vals;
    $ccs->[$VALS]->slice("-1") .= $missing;
  }

  return $ccs->sortwhich();
}

## $ccs = $pdl->toccs()
## $ccs = $pdl->toccs($missing)
## $ccs = $pdl->toccs($missing,$flags)
*PDL::toccs = \&toccs;
sub toccs :lvalue {
  return $_[0] if (isa($_[0],__PACKAGE__));
  return my $tmp=__PACKAGE__->newFromDense(@_);
}

## $ccs = $ccs->copy()
BEGIN { *clone = \&copy; }
sub copy :lvalue {
  my $ccs1 = shift;
  my $ccs2 = bless [], ref($ccs1);
  $ccs2->[$PDIMS] = $ccs1->[$PDIMS]->pdl;
  $ccs2->[$VDIMS] = $ccs1->[$VDIMS]->pdl;
  $ccs2->[$WHICH] = $ccs1->[$WHICH]->pdl;
  $ccs2->[$VALS]  = $ccs1->[$VALS]->pdl;
  $ccs2->[$PTRS]  = [ map {defined($_) ? [map {$_->pdl} @$_] : undef} @{$ccs1->[$PTRS]} ]; ##-- copy pointers?
  $ccs2->[$FLAGS] = $ccs1->[$FLAGS];
  return $ccs2;
}

## $ccs2 = $ccs->copyShallow()
##  + a very shallow version of copy()
##  + Copied    : $PDIMS, @$PTRS, @{$PTRS->[*]}, $FLAGS
##  + Referenced: $VDIMS, $WHICH, $VALS,  $PTRS->[*][*]
sub copyShallow  :lvalue {
  my $ccs = bless [@{$_[0]}], ref($_[0]);
  ##
  ##-- do copy some of it
  $ccs->[$PDIMS]  = $ccs->[$PDIMS]->pdl;
  #$ccs->[$VDIMS] = $ccs->[$VDIMS]->pdl;
  $ccs->[$PTRS]  = [ map {defined($_) ? [@$_] : undef} @{$ccs->[$PTRS]} ];
  $ccs;
}

## $ccs2 = $ccs->shadow(%args)
##  + args:
##     to    => $ccs2,    ##-- default: new
##     pdims => $pdims2,  ##-- default: $pdims1->pdl  (alias: 'dims')
##     vdims => $vdims2,  ##-- default: $vdims1->pdl  (alias: 'xdims')
##     ptrs  => \@ptrs2,  ##-- default: []
##     which => $which2,  ##-- default: undef
##     vals  => $vals2,   ##-- default: undef ; if specified, should include final 'missing' element
##     flags => $flags,   ##-- default: $flags1
sub shadow  :lvalue {
  my ($ccs,%args) = @_;
  my $ccs2        = defined($args{to}) ? $args{to} : bless([], ref($ccs)||$ccs);
  $ccs2->[$PDIMS] = (defined($args{pdims}) ? $args{pdims} : (defined($args{dims})  ? $args{dims}  : $ccs->[$PDIMS]->pdl));
  $ccs2->[$VDIMS] = (defined($args{vdims}) ? $args{vdims} : (defined($args{xdims}) ? $args{xdims} : $ccs->[$VDIMS]->pdl));
  $ccs2->[$PTRS]  = $args{ptrs}  ? $args{ptrs} : [];
  $ccs2->[$WHICH] = $args{which};
  $ccs2->[$VALS]  = $args{vals};
  $ccs2->[$FLAGS] = defined($args{flags}) ? $args{flags} : $ccs->[$FLAGS];
  return $ccs2;
}


##--------------------------------------------------------------
## Maintenance

## $ccs = $ccs->recode()
##  + recodes object, removing any missing values from $nzvals
sub recode  :lvalue {
  my $ccs = shift;
  my $nz = $ccs->_nzvals;
  my $z  = $ccs->[$VALS]->slice("-1");

  ##-- get mask of "real" non-zero values
  my ($nzmask, $nzmask1);
  if ($z->isbad) {
    $nzmask = $nz->isgood;
  }
  else {
    $nzmask = $nz != $z;
    if ($ccs->[$FLAGS] & $CCSND_BAD_IS_MISSING) {
      $nzmask1 = $nz->isgood;
      $nzmask &= $nzmask1;
    }
  }
  if ($ccs->[$FLAGS] & $CCSND_NAN_IS_MISSING) {
    $nzmask1 = $nzmask->pdl if (!defined($nzmask1));
    $nz->isfinite($nzmask1);
    $nzmask &= $nzmask1;
  }

  ##-- maybe recode
  if (!$nzmask->all) {
    my $nzi = $nzmask->which;
    $ccs->[$WHICH]   = $ccs->[$WHICH]->dice_axis(1,$nzi);
    $ccs->[$VALS]    = $ccs->[$VALS]->index($nzi)->append($z);
    @{$ccs->[$PTRS]} = qw(); ##-- clear pointers
  }

  return $ccs;
}

## $ccs = $ccs->sortwhich()
##  + sorts on $ccs->[$WHICH]
##  + may be DANGEROUS to indexing methods, b/c it alters $VALS
##  + clears pointers
sub sortwhich  :lvalue {
  return $_[0] if ($_[0][$WHICH]->isempty);
  my $sorti     = $_[0][$WHICH]->vv_qsortveci;
  $_[0][$WHICH] = $_[0][$WHICH]->dice_axis(1,$sorti);
  $_[0][$VALS]  = $_[0][$VALS]->index($sorti->append($_[0][$WHICH]->dim(1)));
#
#-- DANGEROUS: pointer copy
#  foreach (grep {defined($_)} @{$_[0][$PTRS]}) {
#    $_->[1]->index($sorti) .= $_->[1];
#  }
#--/DANGEROUS: pointer copy
#
  @{$_[0][$PTRS]} = qw() if (! ($sorti==PDL->sequence($P_INDX,$sorti->dims))->all );
  return $_[0];
}


##--------------------------------------------------------------
## Decoding

## $dense = $ccs->decode()
## $dense = $ccs->decode($dense)
sub decode  :lvalue {
  ##-- decode physically stored index+value pairs
  my $dense = ccs_decode($_[0][$WHICH],
                         $_[0]->_nzvals,
                         $_[0]->missing,
                         [ $_[0][$PDIMS] ],
                        );

  ##-- map physical dims with reorder()
  my $porder = $_[0][$VDIMS]->where($_[0][$VDIMS]>=0);
  $dense = $dense->reorder($porder->list); #if (($porder!=$_[0][$PDIMS]->sequence)->any);

  ##-- map virtual dims with dummy()
  my @vdims = $_[0][$VDIMS]->list;
  foreach (grep {$vdims[$_]<0} (0..$#vdims)) {
    $dense = $dense->dummy($_, -$vdims[$_]);
  }

  ##-- assign if $dense was specified by the user
  if (defined($_[1])) {
    $_[1] .= $dense;
    return $_[1];
  }

  return $dense;
}

## $dense = $ccs_or_dense->todense()
*PDL::todense = \&todense;
sub todense  :lvalue { isa($_[0],__PACKAGE__) ? (my $tmp=$_[0]->decode(@_[1..$#_])) : $_[0]; }

##--------------------------------------------------------------
## PDL API: Basic Properties

## $type = $obj->type()
sub type { $_[0][$VALS]->type; }
sub info { $_[0][$VALS]->info; }

## $obj2 = $obj->convert($type)
##  + unlike PDL function, respects 'inplace' flag
sub convert  :lvalue {
  if ($_[0][$FLAGS] & $CCSND_INPLACE) {
    $_[0][$VALS]   = $_[0][$VALS]->convert($_[1]);
    $_[0][$FLAGS] &= ~$CCSND_INPLACE;
    return $_[0];
  }
  return my $tmp=$_[0]->shadow(which=>$_[0][$WHICH]->pdl, vals=>$_[0][$VALS]->convert($_[1]));
}

## byte,short,ushort,long,double,...
sub _pdltype_sub {
  my $pdltype = shift;
  return sub { return $pdltype if (!@_); convert(@_,$pdltype); };
}
foreach my $pdltype (map {$_->{convertfunc}} values %PDL::Types::typehash) {
  no strict 'refs';
  #qw(byte short ushort long longlong indx float double)
  *$pdltype = _pdltype_sub("PDL::${pdltype}"->());
}

## $dimpdl = $obj->dimpdl()
##  + values in $dimpdl are negative for virtual dimensions
sub dimpdl :lvalue {
  my $dims  = $_[0][$VDIMS]->pdl;
  my $physi = ($_[0][$VDIMS]>=0)->which;
  (my $tmp=$dims->index($physi)) .= $_[0][$PDIMS]->index($_[0][$VDIMS]->index($physi));
  return $dims;
}

## @dims = $obj->dims()
sub dims { $_[0]->dimpdl->abs->list; }

## $dim = $obj->dim($dimi)
sub dim { $_[0]->dimpdl->abs->at($_[1]); }
*getdim = \&dim;

## $ndims = $obj->ndims()
sub ndims { $_[0][$VDIMS]->nelem; }
*getndims = \&ndims;

## $nelem = $obj->nelem
sub nelem { $_[0]->dimpdl->abs->dprod; }

## $bool = $obj->isnull
sub isnull { $_[0][$VALS]->isnull; }

## $bool = $obj->isempty
sub isempty { $_[0]->nelem==0; }

##--------------------------------------------------------------
## Low-level CCS access

## $bool = $ccs->is_physically_indexed()
##  + returns true iff only physical dimensions are present
sub is_physically_indexed {
  (
   $_[0][$VDIMS]->ndims==$_[0][$PDIMS]->ndims
   &&
   ($_[0][$VDIMS]==$_[0][$VDIMS]->sequence)->all
  );
}

## $ccs2 = $ccs->to_physically_indexed()
##  + ensures that all non-missing elements are physically indexed
##  + just returns $ccs if all non-missing elements are already physically indexed
sub to_physically_indexed {
  return $_[0] if ($_[0]->is_physically_indexed);
  my $ccs   = shift;
  my $which = $ccs->whichND;
  my $vals  = $ccs->whichVals;
  my $sorti = $which->vv_qsortveci;
  return $ccs->shadow(
                      pdims=>$ccs->dimpdl->abs,
                      vdims=>$ccs->[$VDIMS]->sequence,
                      which=>$which->dice_axis(1,$sorti),
                      vals =>$vals->index($sorti)->append($ccs->missing),
                     )->sever;
}

## $ccs = $ccs->make_physically_indexed()
*make_physical = \&make_physically_indexed;
sub make_physically_indexed {
  return $_[0] if ($_[0]->is_physically_indexed);
  @{$_[0]} = @{$_[0]->to_physically_indexed};
  return $_[0];
}

## $pdims = $obj->pdims()
## $vdims = $obj->vdims()
sub pdims  :lvalue { $_[0][$PDIMS]; }
sub vdims  :lvalue { $_[0][$VDIMS]; }


## $nelem_p = $obj->nelem_p : maximum number of physically addressable elements
## $nelem_v = $obj->nelem_v : maximum number of virtually addressable elements
sub nelem_p { $_[0][$PDIMS]->dprod; }
*nelem_v = \&nelem;

## $v_per_p = $obj->_ccs_nvperp() : number of virtual elements per physical element
sub _ccs_nvperp { $_[0][$VDIMS]->where($_[0][$VDIMS]<0)->abs->dprod; }

## $nstored_p = $obj->nstored_p : actual number of physically stored elements
## $nstored_v = $obj->nstored_v : actual number of physically+virtually stored elements
sub nstored_p { $_[0][$WHICH]->dim(1); }
sub nstored_v { $_[0][$WHICH]->dim(1) * $_[0]->_ccs_nvperp; }
*nstored = \&nstored_v;


## $nnz = $obj->_nnz_p : returns actual  $obj->[$VALS]->dim(0)-1
## $nnz = $obj->_nnz_v : returns virtual $obj->[$VALS]->dim(0)-1
sub _nnz_p { $_[0][$VALS]->dim(0)-1; }
sub _nnz_v { ($_[0][$VALS]->dim(0)-1) * $_[0]->_ccs_nvperp; }
*_nnz = \&_nnz_v;

## $nmissing_p = $obj->nmissing_p()
## $nmissing_v = $obj->nmissing_v()
sub nmissing_p { $_[0]->nelem_p - $_[0]->nstored_p; }
sub nmissing_v { $_[0]->nelem_v - $_[0]->nstored_v; }
*nmissing = \&nmissing_v;

## $bool = $obj->allmissing
##  + true if no non-missing values are stored
sub allmissing { $_[0][$VALS]->nelem <= 1; }


## $missing = $obj->missing()
## $missing = $obj->missing($missing)
sub missing {
  $_[0][$VALS]->set(-1,$_[1]) if (@_>1);
  $_[0][$VALS]->slice("-1");
}

## $obj = $obj->_missing($missingVal)
sub _missing  :lvalue {
  $_[0][$VALS]->set(-1,$_[1]) if (@_>1);
  $_[0];
}

## $whichND_stored = $obj->_whichND()
## $whichND_stored = $obj->_whichND($whichND)
sub _whichND  :lvalue {
  $_[0][$WHICH] = $_[1] if (@_>1);
  $_[0][$WHICH];
}

## $_nzvals = $obj->_nzvals()
## $_nzvals = $obj->_nzvals($nzvals)
##  + physical storage only
BEGIN { *_whichVals = \&_nzvals; }
sub _nzvals :lvalue {
  my ($tmp);
  $_[0][$VALS]=$_[1]->append($_[0][$VALS]->slice("-1")) if (@_ > 1);
  return $tmp=$_[0][$VALS]->index(PDL->zeroes(ccs_indx(), 0)) if ($_[0][$VALS]->dim(0)<=1);
  return $tmp=$_[0][$VALS]->slice("0:-2");
}

## $vals = $obj->_vals()
## $vals = $obj->_vals($storedvals)
##  + physical storage only
sub _vals  :lvalue {
  $_[0][$VALS]=$_[1] if (@_ > 1);
  $_[0][$VALS];
}


## $ptr           = $obj->ptr($dim_p); ##-- scalar context
## ($ptr,$pi2nzi) = $obj->ptr($dim_p); ##-- list context
##   + returns cached value in $ccs->[$PTRS][$dim_p] if present
##   + caches value in $ccs->[$PTRS][$dim_p] otherwise
##   + $dim defaults to zero, for compatibility
##   + if $dim is zero, all($pi2nzi==sequence($obj->nstored))
##   + physical dimensions ONLY
sub ptr {
  my ($ccs,$dim) = @_;
  $dim = 0 if (!defined($dim));
  $ccs->[$PTRS][$dim] = [$ccs->getptr($dim)] if (!$ccs->hasptr($dim));
  return wantarray ? @{$ccs->[$PTRS][$dim]} : $ccs->[$PTRS][$dim][0];
}

## $bool = $obj->hasptr($dim_p)
##   + returns true iff $obj has a cached pointer for physical dim $dim_p
sub hasptr {
  my ($ccs,$dim) = @_;
  $dim = 0 if (!defined($dim));
  return defined($ccs->[$PTRS][$dim]) ? scalar(@{$ccs->[$PTRS][$dim]}) : 0;
}

## ($ptr,$pi2nzi) = $obj->getptr($dim_p);
##  + as for ptr(), but does NOT cache anything, and does NOT check the cache
##  + physical dimensions ONLY
sub getptr { ccs_encode_pointers($_[0][$WHICH]->slice("($_[1]),"), $_[0][$PDIMS]->index($_[1])); }

## ($ptr,$pi2nzi) = $obj->setptr($dim_p, $ptr,$pi2nzi );
##  + low-level: set pointer for $dim_p
sub setptr {
  if (UNIVERSAL::isa($_[2],'ARRAY')) {
    $_[0][$PTRS][$_[1]] = $_[2];
  } else {
    $_[0][$PTRS][$_[1]] = [$_[2],$_[3]];
  }
  return $_[0]->ptr($_[1]);
}

## $obj = $obj->clearptrs()
sub clearptrs :lvalue { @{$_[0][$PTRS]}=qw(); return $_[0]; }

## $obj = $obj->clearptr($dim_p)
##  + low-level: clear pointer(s) for $dim_p
sub clearptr :lvalue {
  my ($ccs,$dim) = @_;
  return $ccs->clearptrs() if (!defined($dim));
  $ccs->[$PTRS][$dim] = undef;
  return $ccs;
}

## $flags = $obj->flags()
## $flags = $obj->flags($flags)
##  + get local flags
sub flags { $_[0][$FLAGS] = $_[1] if (@_ > 1); $_[0][$FLAGS]; }

## $bool = $obj->bad_is_missing()
## $bool = $obj->bad_is_missing($bool)
sub bad_is_missing {
  if (@_ > 1) {
    if ($_[1]) { $_[0][$FLAGS] |=  $CCSND_BAD_IS_MISSING; }
    else       { $_[0][$FLAGS] &= ~$CCSND_BAD_IS_MISSING; }
  }
  $_[0][$FLAGS] & $CCSND_BAD_IS_MISSING;
}

## $obj = $obj->badmissing()
sub badmissing { $_[0][$FLAGS] |= $CCSND_BAD_IS_MISSING; $_[0]; }

## $bool = $obj->nan_is_missing()
## $bool = $obj->nan_is_missing($bool)
sub nan_is_missing {
  if (@_ > 1) {
    if ($_[1]) { $_[0][$FLAGS] |=  $CCSND_NAN_IS_MISSING; }
    else       { $_[0][$FLAGS] &= ~$CCSND_NAN_IS_MISSING; }
  }
  $_[0][$FLAGS] & $CCSND_NAN_IS_MISSING;
}

## $obj = $obj->nanmissing()
sub nanmissing { $_[0][$FLAGS] |= $CCSND_NAN_IS_MISSING; $_[0]; }


## undef = $obj->set_inplace($bool)
##   + sets local inplace flag
sub set_inplace ($$) {
  if ($_[1]) { $_[0][$FLAGS] |=  $CCSND_INPLACE; }
  else       { $_[0][$FLAGS] &= ~$CCSND_INPLACE; }
}

## $bool = $obj->is_inplace()
sub is_inplace ($) { ($_[0][$FLAGS] & $CCSND_INPLACE) ? 1 : 0; }

## $obj = $obj->inplace()
##   + sets local inplace flag
sub inplace ($) { $_[0][$FLAGS] |= $CCSND_INPLACE; $_[0]; }

## $bool = $obj->badflag()
## $bool = $obj->badflag($bool)
##  + wraps $obj->[$WHICH]->badflag, $obj->[$VALS]->badflag()
sub badflag {
  if (@_ > 1) {
    $_[0][$WHICH]->badflag($_[1]);
    $_[0][$VALS]->badflag($_[1]);
  }
  return $_[0][$WHICH]->badflag || $_[0][$VALS]->badflag;
}

## $obj = $obj->sever()
##  + severs all sub-pdls
sub sever {
  $_[0][$PDIMS]->sever;
  $_[0][$VDIMS]->sever;
  $_[0][$WHICH]->sever;
  $_[0][$VALS]->sever;
  foreach (grep {defined($_)} (@{$_[0][$PTRS]})) {
    $_->[0]->sever;
    $_->[1]->sever;
  }
  $_[0];
}

## \&code = _setbad_sub($pdlcode)
##  + returns a sub implementing setbadtoval(), setvaltobad(), etc.
sub _setbad_sub {
  my $pdlsub = shift;
  return sub {
    if ($_[0]->is_inplace) {
      $pdlsub->($_[0][$VALS]->inplace, @_[1..$#_]);
      $_[0]->set_inplace(0);
      return $_[0];
    }
    $_[0]->shadow(
                  which=>$_[0][$WHICH]->pdl,
                  vals=>$pdlsub->($_[0][$VALS],@_[1..$#_]),
                 );
  };
}

## $obj = $obj->setnantobad()
foreach my $badsub (qw(setnantobad setbadtonan setbadtoval setvaltobad)) {
  no strict 'refs';
  *$badsub = _setbad_sub(PDL->can($badsub));
}

##--------------------------------------------------------------
## Dimension Shuffling

## $ccs = $ccs->setdims_p(@dims)
##  + sets physical dimensions
*setdims = \&setdims_p;
sub setdims_p { $_[0][$PDIMS] = PDL->pdl($P_INDX,@_[1..$#_]); }

## $ccs2 = $ccs->dummy($vdim_index)
## $ccs2 = $ccs->dummy($vdim_index, $vdim_size)
sub dummy  :lvalue {
  my ($ccs,$vdimi,$vdimsize) = @_;
  my @vdims = $ccs->[$VDIMS]->list;
  $vdimsize = 1 if (!defined($vdimsize));
  $vdimi    = 0 if (!defined($vdimi));
  $vdimi    = @vdims + $vdimi + 1 if ($vdimi < 0);
  if ($vdimi < 0) {
    PDL::Lite::barf(ref($ccs). "::dummy(): negative dimension number ", ($vdimi+@vdims), " exceeds number of dims ", scalar(@vdims));
  }
  splice(@vdims,$vdimi,0,-$vdimsize);
  my $ccs2 = $ccs->copyShallow;
  $ccs2->[$VDIMS] = PDL->pdl($P_INDX,\@vdims);
  return $ccs2;
}

## $ccs2 = $ccs->reorder_pdl($vdim_index_pdl)
sub reorder_pdl  :lvalue {
  my $ccs2 = $_[0]->copyShallow;
  $ccs2->[$VDIMS] = $ccs2->[$VDIMS]->index($_[1]);
  $ccs2->[$VDIMS]->sever;
  $ccs2;
}

## $ccs2 = $ccs->reorder(@vdim_list)
sub reorder  :lvalue { $_[0]->reorder_pdl(PDL->pdl($P_INDX,@_[1..$#_])); }

## $ccs2 = $ccs->xchg($vdim1,$vdim2)
sub xchg  :lvalue {
  my $dimpdl = PDL->sequence($P_INDX,$_[0]->ndims);
  my $tmp    = $dimpdl->at($_[1]);
  $dimpdl->set($_[1], $dimpdl->at($_[2]));
  $dimpdl->set($_[2], $tmp);
  return $tmp=$_[0]->reorder_pdl($dimpdl);
}

## $ccs2 = $ccs->mv($vDimFrom,$vDimTo)
sub mv   :lvalue {
  my ($d1,$d2) = @_[1,2];
  my $ndims = $_[0]->ndims;
  $d1 = $ndims+$d1 if ($d1 < 0);
  $d2 = $ndims+$d2 if ($d2 < 0);
  return my $tmp=$_[0]->reorder($d1 < $d2
                                ? ((0..($d1-1)), (($d1+1)..$d2), $d1,            (($d2+1)..($ndims-1)))
                                : ((0..($d2-1)), $d1,            ($d2..($d1-1)), (($d1+1)..($ndims-1)))
                               );
}

## $ccs2 = $ccs->transpose()
##  + always copies
sub transpose  :lvalue {
  my ($tmp);
  if ($_[0]->ndims==1) {
    return $tmp=$_[0]->dummy(0,1)->copy;
  } else {
    return $tmp=$_[0]->xchg(0,1)->copy;
  }
}



##--------------------------------------------------------------
## PDL API: Indexing

sub slice {  #:lvalue
  PDL::Lite::barf(ref($_[0])."::slice() is not implemented yet (try dummy, dice_axis, indexND, etc.)");
}

## $nzi = $ccs->indexNDi($ndi)
##  + returns Nnz indices for virtual ND-index PDL $ndi
##  + index values in $ndi which are not present in $ccs are returned in $nzi as:
##      $ccs->[$WHICH]->dim(1) == $ccs->_nnz_p
sub indexNDi  :lvalue {
  my ($ccs,$ndi)   = @_;
  ##
  ##-- get physical dims
  my $dims      = $ccs->[$VDIMS];
  my $whichdimp = ($dims>=0)->which;
  my $pdimi     = $dims->index($whichdimp);
  ##
  #$ndi = $ndi->dice_axis(0,$whichdimp) ##-- BUG?!
  $ndi = $ndi->dice_axis(0,$pdimi)
    if ( $ndi->dim(0)!=$ccs->[$WHICH]->dim(0) || ($pdimi!=PDL->sequence($ccs->[$WHICH]->dim(0)))->any );
  ##
  my $foundi       = $ndi->vsearchvec($ccs->[$WHICH]);
  my $foundi_mask  = ($ndi==$ccs->[$WHICH]->dice_axis(1,$foundi))->andover;
  $foundi_mask->inplace->not;
  (my $tmp=$foundi->where($foundi_mask)) .= $ccs->[$WHICH]->dim(1);
  return $foundi;
}

## $vals = $ccs->indexND($ndi)
sub indexND  :lvalue { my $tmp=$_[0][$VALS]->index($_[0]->indexNDi($_[1])); }

## $vals = $ccs->index2d($xi,$yi)
sub index2d  :lvalue { my $tmp=$_[0]->indexND($_[1]->cat($_[2])->xchg(0,1)); }

## $nzi = $ccs->xindex1d($xi)
##  + nzi indices for dice_axis(0,$xi)
##  + physically indexed only
sub xindex1d :lvalue {
  my ($ccs,$xi) = @_;
  $ccs->make_physically_indexed;
  my $nzi = $ccs->[$WHICH]->ccs_xindex1d($xi);
  $nzi->sever;
  return $nzi;
}

## $subset = $ccs->xsubset1d($xi)
##  + subset object like dice_axis(0,$xi) without $xi-renumbering
##  + returned object should participate in dataflow
##  + physically indexed only
sub xsubset1d :lvalue {
  my ($ccs,$xi) = @_;
  my $nzi = $ccs->xindex1d($xi);
  return $ccs->shadow(which=>$ccs->[$WHICH]->dice_axis(1,$nzi),
                      vals =>$ccs->[$VALS]->index($nzi->append($ccs->_nnz)));
}

## $nzi = $ccs->pxindex1d($dimi,$xi)
##  + nzi indices for dice_axis($dimi,$xi), using ptr($dimi)
##  + physically indexed only
sub pxindex1d :lvalue {
  my ($ccs,$dimi,$xi) = @_;
  $ccs->make_physically_indexed();
  my ($ptr,$pix) = $ccs->ptr($dimi);
  my $xptr = $ptr->index($xi);
  my $xlen = $ptr->index($xi+1) - $xptr;
  my $nzi  = defined($pix) ? $pix->index($xlen->rldseq($xptr))->qsort : $xlen->rldseq($xptr);
  $nzi->sever;
  return $nzi;
}

## $subset = $ccs->pxsubset1d($dimi,$xi)
##  + subset object like dice_axis($dimi,$xi) without $xi-renumbering, using ptr($dimi)
##  + returned object should participate in dataflow
##  + physically indexed only
sub pxsubset1d {
  my ($ccs,$dimi,$xi) = @_;
  my $nzi = $ccs->pxindex1d($dimi,$xi);
  return $ccs->shadow(which=>$ccs->[$WHICH]->dice_axis(1,$nzi),
                      vals =>$ccs->[$VALS]->index($nzi->append($ccs->_nnz)));
}

## $nzi = $ccs->xindex2d($xi,$yi)
##  + returns nz-index piddle matching any index-pair in Cartesian product ($xi x $yi)
##  + caller object must be a ccs-encoded 2d matrix
##  + physically indexed only
sub xindex2d :lvalue {
  my ($ccs,$xi,$yi) = @_;
  $ccs->make_physically_indexed;
  my $nzi = $ccs->[$WHICH]->ccs_xindex2d($xi,$yi);
  $nzi->sever;
  return $nzi;
}

## $subset = $ccs->xsubset2d($xi,$yi)
##  + returns a subset CCS object for all index-pairs in $xi,$yi
##  + caller object must be a ccs-encoded 2d matrix
##  + returned object should participate in dataflow
##  + physically indexed only
sub xsubset2d :lvalue {
  my ($ccs,$xi,$yi) = @_;
  my $nzi = $ccs->xindex2d($xi,$yi);
  return $ccs->shadow(which=>$ccs->[$WHICH]->dice_axis(1,$nzi),
                      vals =>$ccs->[$VALS]->index($nzi->append($ccs->_nnz)));
}

## $vals = $ccs->index($flati)
sub index  :lvalue {
  my ($ccs,$i) = @_;
  my $dummy  = PDL->pdl(0)->slice(join(',', map {"*$_"} $ccs->dims));
  my @coords = $dummy->one2nd($i);
  my $ind = PDL->zeroes($P_INDX,$ccs->ndims,$i->dims);
  my ($tmp);
  ($tmp=$ind->slice("($_),")) .= $coords[$_] foreach (0..$#coords);
  return $tmp=$ccs->indexND($ind);
}

## $ccs2 = $ccs->dice_axis($axis_v, $axisi)
##  + returns a new ccs object, should participate in dataflow
sub dice_axis  :lvalue {
  my ($ccs,$axis_v,$axisi) = @_;
  ##
  ##-- get
  my $ndims = $ccs->ndims;
  $axis_v = $ndims + $axis_v if ($axis_v < 0);
  PDL::Lite::barf(ref($ccs)."::dice_axis(): axis ".($axis_v<0 ? ($axis_v+$ndims) : $axis_v)." out of range: should be 0<=dim<$ndims")
    if ($axis_v < 0 || $axis_v >= $ndims);
  my $axis  = $ccs->[$VDIMS]->at($axis_v);
  my $asize = $axis < 0 ? -$axis : $ccs->[$PDIMS]->at($axis);
  $axisi    = PDL->topdl($axisi);
  my ($aimin,$aimax) = $axisi->minmax;
  PDL::Lite::barf(ref($ccs)."::dice_axis(): invalid index $aimin (valid range 0..".($asize-1).")") if ($aimin < 0);
  PDL::Lite::barf(ref($ccs)."::dice_axis(): invalid index $aimax (valid range 0..".($asize-1).")") if ($aimax >= $asize);
  ##
  ##-- check for virtual
  if ($axis < 0) {
    ##-- we're dicing a virtual axis: ok, but why?
    my $naxisi = $axisi->nelem;
    my $ccs2   = $ccs->copyShallow();
    $ccs2->[$VDIMS] = $ccs->[$VDIMS]->pdl;
    $ccs2->[$VDIMS]->set($axis_v, -$naxisi);
    return $ccs2;
  }
  ##-- ok, we're dicing on a real axis
  my ($ptr,$pi2nzi)    = $ccs->ptr($axis);
  my ($ptrix,$pi2nzix) = $ptr->ccs_decode_pointer($axisi);
  my $nzix   = defined($pi2nzi) ? $pi2nzi->index($pi2nzix) : $pi2nzix;
  my $which  = $ccs->[$WHICH]->dice_axis(1,$nzix);
  $which->sever;
  (my $tmp=$which->slice("($axis),")) .= $ptrix if (!$which->isempty); ##-- isempty() fix: v1.12
  my $nzvals = $ccs->[$VALS]->index($nzix->append($ccs->[$WHICH]->dim(1)));
  ##
  ##-- construct output object
  my $ccs2 = $ccs->shadow();
  $ccs2->[$PDIMS]->set($axis, $axisi->nelem);
  $ccs2->[$WHICH] = $which;
  $ccs2->[$VALS]  = $nzvals;
  ##
  ##-- sort output object (if not dicing on 0th dimension)
  return $axis==0 ? $ccs2 : ($tmp=$ccs2->sortwhich());
}

## $onedi = $ccs->n2oned($ndi)
##  + returns a pseudo-index
sub n2oned  :lvalue {
  my $dimsizes = PDL->pdl($P_INDX,1)->append($_[0]->dimpdl->abs)->slice("0:-2")->cumuprodover;
  return my $tmp=($_[1] * $dimsizes)->sumover;
}

## $whichND = $obj->whichND
##  + just returns the literal index PDL if possible: beware of dataflow!
##  + indices are NOT guaranteed to be returned in any surface-logical order,
##    although physically indexed dimensions should be sorted in physical-lexicographic order
sub whichND  :lvalue {
  my $vpi = ($_[0][$VDIMS]>=0)->which;
  my ($wnd);
  if ( $_[0][$VDIMS]->nelem==$_[0][$PDIMS]->nelem ) {
    if (($_[0][$VDIMS]->index($vpi)==$_[0][$PDIMS]->sequence)->all) {
      ##-- all literal & physically ordered
      $wnd=$_[0][$WHICH];
    }
    else {
      ##-- all physical, but shuffled
      $wnd=$_[0][$WHICH]->dice_axis(0,$_[0][$VDIMS]->index($vpi));
    }
    return wantarray ? $wnd->xchg(0,1)->dog : $wnd;
  }
  ##-- virtual dims are in the game: construct output pdl
  my $ccs = shift;
  my $nvperp = $ccs->_ccs_nvperp;
  my $nv     = $ccs->nstored_v;
  $wnd = PDL->zeroes($P_INDX, $ccs->ndims, $nv);
  (my $tmp=$wnd->dice_axis(0,$vpi)->flat) .= $ccs->[$WHICH]->dummy(1,$nvperp)->flat;
  if (!$wnd->isempty) {
    my $nzi    = PDL->sequence($P_INDX,$nv);
    my @vdims  = $ccs->[$VDIMS]->list;
    my ($vdimi);
    foreach (grep {$vdims[$#vdims-$_]<0} (0..$#vdims)) {
      $vdimi = $#vdims-$_;
      $nzi->modulo(-$vdims[$vdimi], $wnd->slice("($vdimi),"), 0);
    }
  }
  return wantarray ? $wnd->xchg(0,1)->dog : $wnd;
}

## $whichVals = $ccs->whichVals()
##  + returns $VALS corresponding to whichND() indices
##  + beware of dataflow!
sub whichVals  :lvalue {
  my $vpi = ($_[0][$VDIMS]>=0)->which;
  my ($tmp);
  return $tmp=$_[0]->_nzvals() if ( $_[0][$VDIMS]->nelem==$_[0][$PDIMS]->nelem ); ##-- all physical
  ##
  ##-- virtual dims are in the game: construct output pdl
  return $tmp=$_[0]->_nzvals->slice("*".($_[0]->_ccs_nvperp))->flat;
}

## $which = $obj->which()
##  + not guaranteed to be returned in any meaningful order
sub which  :lvalue { my $tmp=$_[0]->n2oned(scalar $_[0]->whichND); }

## $val = $ccs->at(@index)
sub at { $_[0]->indexND(PDL->pdl($P_INDX,@_[1..$#_]))->sclr; }

## $val = $ccs->set(@index,$value)
sub set {
  my $foundi = $_[0]->indexNDi(PDL->pdl($P_INDX,@_[1..($#_-1)]));
  if ( ($foundi==$_[0][$WHICH]->dim(1))->any ) {
    carp(ref($_[0]).": cannot set() a missing value!")
  } else {
    (my $tmp=$_[0][$VALS]->index($foundi)) .= $_[$#_];
  }
  return $_[0];
}

##--------------------------------------------------------------
## Mask Utilities

## $missing_mask = $ccs->ismissing()
sub ismissing  :lvalue {
  $_[0]->shadow(which=>$_[0][$WHICH]->pdl, vals=>$_[0]->_nzvals->zeroes->ccs_indx->append(1));
}

## $nonmissing_mask = $ccs->ispresent()
sub ispresent  :lvalue {
  $_[0]->shadow(which=>$_[0][$WHICH]->pdl, vals=>$_[0]->_nzvals->ones->ccs_indx->append(0));
}

##--------------------------------------------------------------
## Ufuncs

## $ufunc_sub = _ufuncsub($subname, \&ccs_accum_sub, $allow_bad_missing)
sub _ufuncsub {
  my ($subname,$accumsub,$allow_bad_missing) = @_;
  PDL::Lite::barf(__PACKAGE__, "::_ufuncsub($subname): no underlying CCS accumulator func!") if (!defined($accumsub));
  return sub :lvalue {
    my $ccs = shift;
    ##
    ##-- preparation
    my $which   = $ccs->whichND;
    my $vals    = $ccs->whichVals;
    my $missing = $ccs->missing;
    my @dims    = $ccs->dims;
    my ($which1,$vals1);
    if ($which->dim(0) <= 1) {
      ##-- flat sum
      $which1 = PDL->zeroes($P_INDX,1,$which->dim(1)); ##-- dummy
      $vals1  = $vals;
    } else {
      $which1   = $which->slice("1:-1,");
      my $sorti = $which1->vv_qsortveci;
      $which1   = $which1->dice_axis(1,$sorti);
      $vals1    = $vals->index($sorti);
    }
    ##
    ##-- guts
    my ($which2,$nzvals2) = $accumsub->($which1,$vals1,
                                        ($allow_bad_missing || $missing->isgood
                                         ? ($missing, $dims[0])
                                         : (PDL->pdl($vals1->type, 0), 0))
                                       );
    ##
    ##-- get output pdl
    shift(@dims);
    my ($tmp);
    return $tmp=$nzvals2->squeeze if (!@dims); ##-- just a scalar: return a plain PDL
    ##
    my $newdims = PDL->pdl($P_INDX,\@dims);
    return $tmp=$ccs->shadow(
                             pdims =>$newdims,
                             vdims =>$newdims->sequence,
                             which =>$which2,
                             vals  =>$nzvals2->append($missing->convert($nzvals2->type)),
                            );
  };
}

foreach my $ufunc (
                   qw(prod dprod sum dsum),
                   qw(and or band bor),
                  )
  {
    no strict 'refs';
    *{"${ufunc}over"} = _ufuncsub("${ufunc}over", PDL::CCS::Ufunc->can("ccs_accum_${ufunc}"));
  }
foreach my $ufunc (qw(maximum minimum average))
  {
    no strict 'refs';
    *$ufunc = _ufuncsub($ufunc, PDL::CCS::Ufunc->can("ccs_accum_${ufunc}"));
  }

*nbadover  = _ufuncsub('nbadover',  PDL::CCS::Ufunc->can('ccs_accum_nbad'), 1);
*ngoodover = _ufuncsub('ngoodover', PDL::CCS::Ufunc->can('ccs_accum_ngood'), 1);
*nnz       = _ufuncsub('nnz', PDL::CCS::Ufunc->can('ccs_accum_nnz'), 1);

sub average_nz  :lvalue {
  my $ccs = shift;
  return my $tmp=($ccs->sumover / $ccs->nnz);
}
#sub average {
#  my $ccs = shift;
#  my $missing = $ccs->missing;
#  return $ccs->sumover / $ccs->dim(0) if ($missing==0);
#  return ($ccs->sumover + (-$ccs->nnz+$ccs->dim(0))*$missing) / $ccs->dim(0);
#}

sub sum   { my $z=$_[0]->missing; $_[0]->_nzvals->sum  + ($z->isgood ? ($z->sclr *  $_[0]->nmissing) : 0); }
sub dsum  { my $z=$_[0]->missing; $_[0]->_nzvals->dsum + ($z->isgood ? ($z->sclr *  $_[0]->nmissing) : 0); }
sub prod  { my $z=$_[0]->missing; $_[0]->_nzvals->prod  * ($z->isgood ? ($z->sclr ** $_[0]->nmissing) : 1); }
sub dprod { my $z=$_[0]->missing; $_[0]->_nzvals->dprod * ($z->isgood ? ($z->sclr ** $_[0]->nmissing) : 1); }
sub min   { $_[0][$VALS]->min; }
sub max   { $_[0][$VALS]->max; }
sub minmax { $_[0][$VALS]->minmax; }

sub nbad  { my $z=$_[0]->missing; $_[0]->_nzvals->nbad   + ($z->isbad  ? $_[0]->nmissing : 0); }
sub ngood { my $z=$_[0]->missing; $_[0]->_nzvals->ngood  + ($z->isgood ? $_[0]->nmissing : 0); }

sub any { $_[0][$VALS]->any; }
sub all { $_[0][$VALS]->all; }


sub avg   {
  my $z=$_[0]->missing;
  return ($_[0]->_nzvals->sum + ($_[0]->nelem-$_[0]->_nnz)*$z->sclr) / $_[0]->nelem;
}
sub avg_nz   { $_[0]->_nzvals->avg; }

sub isbad {
  my ($a,$out) = @_;
  return $a->shadow(which=>$a->[$WHICH]->pdl,vals=>$a->[$VALS]->isbad,to=>$out);
}
sub isgood {
  my ($a,$out) = @_;
  return $a->shadow(which=>$a->[$WHICH]->pdl,vals=>$a->[$VALS]->isgood,to=>$out);
}

##--------------------------------------------------------------
## Index-Ufuncs

sub _ufunc_ind_sub {
  my ($subname,$accumsub,$allow_bad_missing) = @_;
  PDL::Lite::barf(__PACKAGE__, "::_ufuncsub($subname): no underlying CCS accumulator func!") if (!defined($accumsub));
  return sub :lvalue {
    my $ccs = shift;
    ##
    ##-- preparation
    my $which   = $ccs->whichND;
    my $vals    = $ccs->whichVals;
    my $missing = $ccs->missing;
    my @dims    = $ccs->dims;
    my ($which0,$which1,$vals1);
    if ($which->dim(0) <= 1) {
      ##-- flat X_ind
      $which0 = $which->slice("(0),");
      $which1 = PDL->zeroes($P_INDX,1,$which->dim(1)); ##-- dummy
      $vals1  = $vals;
    } else {
      my $sorti = $which->dice_axis(0, PDL->sequence($P_INDX,$which->dim(0))->rotate(-1))->vv_qsortveci;
      $which1   = $which->slice("1:-1,")->dice_axis(1,$sorti);
      $which0   = $which->slice("(0),")->index($sorti);
      $vals1    = $vals->index($sorti);
    }
    ##
    ##-- guts
    my ($which2,$nzvals2) = $accumsub->($which1,$vals1,
                                        ($allow_bad_missing || $missing->isgood ? ($missing,$dims[0]) : (0,0))
                                       );
    ##
    ##-- get output pdl
    shift(@dims);
    my $nzi2    = $nzvals2;
    my $nzi2_ok = ($nzvals2>=0);
    my ($tmp);
    ($tmp=$nzi2->where($nzi2_ok)) .= $which0->index($nzi2->where($nzi2_ok));
    return $tmp=$nzi2->squeeze if (!@dims); ##-- just a scalar: return a plain PDL
    ##
    my $newdims = PDL->pdl($P_INDX,\@dims);
    return $tmp=$ccs->shadow(
                             pdims =>$newdims,
                             vdims =>$newdims->sequence,
                             which =>$which2,
                             vals  =>$nzi2->append(ccs_indx(-1)),
                            );
  };
}

*maximum_ind = _ufunc_ind_sub('maximum_ind', PDL::CCS::Ufunc->can('ccs_accum_maximum_nz_ind'),1);
*minimum_ind = _ufunc_ind_sub('minimum_ind', PDL::CCS::Ufunc->can('ccs_accum_minimum_nz_ind'),1);

##--------------------------------------------------------------
## Ufuncs: qsort (from CCS::Functions)

## ($which0,$nzVals0, $nzix,$nzenum, $whichOut) = $ccs->_qsort()
## ($which0,$nzVals0, $nzix,$nzenum, $whichOut) = $ccs->_qsort([o]nzix(NNz), [o]nzenum(Nnz))
sub _qsort {
  my $ccs = shift;
  my $which0  = $ccs->whichND;
  my $nzvals0 = $ccs->whichVals;
  return ($which0,$nzvals0, ccs_qsort($which0->slice("1:-1,"),$nzvals0, $ccs->missing,$ccs->dim(0), @_));
}

## $ccs_sorted = $ccs->qsort()
## $ccs_sorted = $ccs->qsort($ccs_sorted)
sub qsort :lvalue {
  my $ccs = shift;
  my ($which0,$nzvals0,$nzix,$nzenum) = $ccs->_qsort();
  my $newdims = PDL->pdl($P_INDX,[$ccs->dims]);
  return my $tmp=$ccs->shadow(
                              to    => $_[0],
                              pdims =>$newdims,
                              vdims =>$newdims->sequence,
                              which =>$nzenum->slice("*1,")->glue(0,$which0->slice("1:-1,")->dice_axis(1,$nzix)),
                              vals  =>$nzvals0->index($nzix)->append($ccs->missing),
                             );
}

## $ccs_sortedi = $ccs->qsorti()
## $ccs_sortedi = $ccs->qsorti($ccs_sortedi)
sub qsorti :lvalue {
  my $ccs = shift;
  my ($which0,$nzvals0,$nzix,$nzenum) = $ccs->_qsort();
  my $newdims = PDL->pdl($P_INDX,[$ccs->dims]);
  return my $tmp=$ccs->shadow(
                              to    => $_[0],
                              pdims =>$newdims,
                              vdims =>$newdims->sequence,
                              which =>$nzenum->slice("*1,")->glue(0,$which0->slice("1:-1,")->dice_axis(1,$nzix)),
                              vals  =>$which0->slice("(0),")->index($nzix)->append(ccs_indx(-1)),
                             );
}

##--------------------------------------------------------------
## Unary Operations

## $sub = _unary_op($opname,$pdlsub)
sub _unary_op {
  my ($opname,$pdlsub) = @_;
  return sub :lvalue {
    if ($_[0]->is_inplace) {
      $pdlsub->($_[0][$VALS]->inplace);
      $_[0]->set_inplace(0);
      return $_[0];
    }
    return my $tmp=$_[0]->shadow(which=>$_[0][$WHICH]->pdl, vals=>$pdlsub->($_[0][$VALS]));
  };
}

foreach my $unop (qw(bitnot sqrt abs sin cos not exp log log10))
  {
    no strict 'refs';
    *$unop = _unary_op($unop,PDL->can($unop));
  }

##--------------------------------------------------------------
## OLD (but still used): Binary Operations: missing-is-annihilator

## ($rdpdl,$pdimsc,$vdimsc,$apcp,$bpcp) = _ccsnd_binop_align_dims($pdimsa,$vdimsa, $pdimsb,$vdimsb, $opname)
#  + returns:
##     $rdpdl  : (indx,2,$nrdims) : [ [$vdimai,$vdimbi], ...] s.t. $vdimai should align with $vdimbi
##     $pdimsc : (indx,$ndimsc)   : physical dim-size pdl for CCS output $c()
##     $vdimsc : (indx,$ndimsc)   : virtual dim-size pdl for CCS output $c()
##     $apcp   : (indx,2,$nac)    : [ [$apdimi,$cpdimi], ... ] s.t. $cpdimi aligns 1-1 with $apdimi
##     $bpcp   : (indx,2,$nbc)    : [ [$bpdimi,$cpdimi], ... ] s.t. $cpdimi aligns 1-1 with $bpdimi
sub _ccsnd_binop_align_dims {
  my ($pdimsa,$vdimsa,$pdimsb,$vdimsb, $opname) = @_;
  $opname = '_ccsnd_binop_relevant_dims' if (!defined($opname));

  ##-- init
  my @pdimsa = $pdimsa->list;
  my @pdimsb = $pdimsb->list;
  my @vdimsa = $vdimsa->list;
  my @vdimsb = $vdimsb->list;

  ##-- get alignment-relevant dims
  my @rdims  = qw();
  my ($vdima,$vdimb, $dimsza,$dimszb);
  foreach (0..($#vdimsa < $#vdimsb ? $#vdimsa : $#vdimsb)) {
    $vdima = $vdimsa[$_];
    $vdimb = $vdimsb[$_];

    ##-- get (virtual) dimension sizes
    $dimsza = $vdima>=0 ? $pdimsa[$vdima] : -$vdima;
    $dimszb = $vdimb>=0 ? $pdimsb[$vdimb] : -$vdimb;

    ##-- check for (virtual) size mismatch
    next if ($dimsza==1 || $dimszb==1);   ##... ignoring (virtual) dims of size 1
    PDL::Lite::barf( __PACKAGE__ , "::$opname(): dimension size mismatch on dim($_): $dimsza != $dimszb")
      if ($dimsza != $dimszb);

    ##-- dims match: only align if both are physical
    push(@rdims, [$vdima,$vdimb]) if ($vdima>=0 && $vdimb>=0);
  }
  my $rdpdl = PDL->pdl($P_INDX,\@rdims);

  ##-- get output dimension sources
  my @_cdsrc = qw(); ##-- ( $a_or_b_for_dim0, ... )
  foreach (0..($#vdimsa > $#vdimsb ? $#vdimsa : $#vdimsb)) {
    push(@vdimsa, -1) if ($_ >= @vdimsa);
    push(@vdimsb, -1) if ($_ >= @vdimsb);
    $vdima  = $vdimsa[$_];
    $vdimb  = $vdimsb[$_];
    $dimsza = $vdima>=0 ? $pdimsa[$vdima] : -$vdima;
    $dimszb = $vdimb>=0 ? $pdimsb[$vdimb] : -$vdimb;
    if ($vdima>=0) {
      if ($vdimb>=0)  { push(@_cdsrc, $dimsza>=$dimszb ? 0 : 1); } ##-- a:p, b:p --> c:p[max2(sz(a),sz(b))]
      else            { push(@_cdsrc, 0); }                        ##-- a:p, b:v --> c:p[a]
    }
    elsif ($vdimb>=0) { push(@_cdsrc, 1); }                        ##-- a:v, b:p --> c:p[b]
    else              { push(@_cdsrc, $dimsza>=$dimszb ? 0 : 1); } ##-- a:v, b:v --> c:v[max2(sz(a),sz(b))]
  }
  my $_cdsrcp = PDL->pdl($P_INDX,@_cdsrc);

  ##-- get c() dimension pdls
  my @pdimsc = qw();
  my @vdimsc = qw();
  my @apcp  = qw(); ##-- ([$apdimi,$cpdimi], ...)
  my @bpcp  = qw(); ##-- ([$bpdimi,$bpdimi], ...)
  foreach (0..$#_cdsrc) {
    if ($_cdsrc[$_]==0) { ##-- source(dim=$_) == a
      if ($vdimsa[$_]<0) { $vdimsc[$_]=$vdimsa[$_]; }
      else {
        $vdimsc[$_] = @pdimsc;
        push(@apcp, [$vdimsa[$_],scalar(@pdimsc)]);
        push(@pdimsc, $pdimsa[$vdimsa[$_]]);
      }
    } else {              ##-- source(dim=$_) == b
      if ($vdimsb[$_]<0) { $vdimsc[$_]=$vdimsb[$_]; }
      else {
        $vdimsc[$_] = @pdimsc;
        push(@bpcp, [$vdimsb[$_],scalar(@pdimsc)]);
        push(@pdimsc, $pdimsb [$vdimsb[$_]]);
      }
    }
  }
  my $pdimsc = PDL->pdl($P_INDX,\@pdimsc);
  my $vdimsc = PDL->pdl($P_INDX,\@vdimsc);
  my $apcp   = PDL->pdl($P_INDX,\@apcp);
  my $bpcp   = PDL->pdl($P_INDX,\@bpcp);

  return ($rdpdl,$pdimsc,$vdimsc,$apcp,$bpcp);
}

##-- OLD (but still used)
## \&code = _ccsnd_binary_op_mia($opName, \&pdlSub, $defType, $noSwap)
##  + returns code for wrapping a builtin PDL binary operation \&pdlSub under the name "$opName"
##  + $opName is just used for error reporting
##  + $defType (if specified) is the default output type of the operation (e.g. PDL::long())
sub _ccsnd_binary_op_mia {
  my ($opname,$pdlsub,$deftype,$noSwap) = @_;

  return sub :lvalue {
    my ($a,$b,$swap) = @_;
    my ($tmp);
    $swap=0 if (!defined($swap));

    ##-- check for & dispatch scalar operations
    if (!ref($b) || $b->nelem==1) {
      if ($a->is_inplace) {
        $pdlsub->($a->[$VALS]->inplace, todense($b), ($noSwap ? qw() : $swap));
        $a->set_inplace(0);
        return $tmp=$a->recode;
      }
      return $tmp=$a->shadow(
                             which => $a->[$WHICH]->pdl,
                             vals  => $pdlsub->($a->[$VALS], todense($b), ($noSwap ? qw() : $swap))
                            )->recode;
    }

    ##-- convert b to CCS
    $b = toccs($b);

    ##-- align dimensions & determine output sources
    my ($rdpdl,$pdimsc,$vdimsc,$apcp,$bpcp) = _ccsnd_binop_align_dims(@$a[$PDIMS,$VDIMS],
                                                                      @$b[$PDIMS,$VDIMS],
                                                                      $opname);
    my $nrdims = $rdpdl->dim(1);

    ##-- get & sort relevant indices, vals
    my $ixa    = $a->[$WHICH];
    my $avals  = $a->[$VALS];
    my $nixa   = $ixa->dim(1);
    my $ra     = $rdpdl->slice("(0)");
    my ($ixar,$avalsr);
    if ( $rdpdl->isempty ) {
      ##-- a: no relevant dims: align all pairs using a pseudo-dimension
      $ixar   = PDL->zeroes($P_INDX, 1,$nixa);
      $avalsr = $avals;
    } elsif ( ($ra==PDL->sequence($P_INDX,$nrdims))->all ) {
      ##-- a: relevant dims are a prefix of physical dims, e.g. pre-sorted
      $ixar   = $nrdims==$ixa->dim(0) ? $ixa : $ixa->slice("0:".($nrdims-1));
      $avalsr = $avals;
    } else {
      $ixar          = $ixa->dice_axis(0,$ra);
      my $ixar_sorti = $ixar->qsortveci;
      $ixa           = $ixa->dice_axis(1,$ixar_sorti);
      $ixar          = $ixar->dice_axis(1,$ixar_sorti);
      $avalsr        = $avals->index($ixar_sorti);
    }
    ##
    my $ixb   = $b->[$WHICH];
    my $bvals = $b->[$VALS];
    my $nixb  = $ixb->dim(1);
    my $rb    = $rdpdl->slice("(1)");
    my ($ixbr,$bvalsr);
    if ( $rdpdl->isempty ) {
      ##-- b: no relevant dims: align all pairs using a pseudo-dimension
      $ixbr   = PDL->zeroes($P_INDX, 1,$nixb);
      $bvalsr = $bvals;
    } elsif ( ($rb==PDL->sequence($P_INDX,$nrdims))->all ) {
      ##-- b: relevant dims are a prefix of physical dims, e.g. pre-sorted
      $ixbr   = $nrdims==$ixb->dim(0) ? $ixb : $ixb->slice("0:".($nrdims-1));
      $bvalsr = $bvals;
    } else {
      $ixbr          = $ixb->dice_axis(0,$rb);
      my $ixbr_sorti = $ixbr->qsortveci;
      $ixb           = $ixb->dice_axis(1,$ixbr_sorti);
      $ixbr          = $ixbr->dice_axis(1,$ixbr_sorti);
      $bvalsr        = $bvals->index($ixbr_sorti);
    }


    ##-- initialize: state vars
    my $blksz  = $nixa > $nixb ? $nixa : $nixb;
    $blksz     = $BINOP_BLOCKSIZE_MIN if ($BINOP_BLOCKSIZE_MIN && $blksz < $BINOP_BLOCKSIZE_MIN);
    $blksz     = $BINOP_BLOCKSIZE_MAX if ($BINOP_BLOCKSIZE_MAX && $blksz > $BINOP_BLOCKSIZE_MAX);
    my $istate = PDL->zeroes($P_INDX,7); ##-- [ nnzai,nnzai_nxt, nnzbi,nnzbi_nxt, nnzci,nnzci_nxt, cmpval ]
    my $ostate = $istate->pdl;

    ##-- initialize: output vectors
    my $nzai   = PDL->zeroes($P_INDX,$blksz);
    my $nzbi   = PDL->zeroes($P_INDX,$blksz);
    my $nzc    = PDL->zeroes((defined($deftype)
                              ? $deftype
                              : ($avals->type > $bvals->type
                                 ? $avals->type
                                 : $bvals->type)),
                             $blksz);
    my $ixc    = PDL->zeroes($P_INDX, $pdimsc->nelem, $blksz);
    my $nnzc   = 0;
    my $zc     = $pdlsub->($avals->slice("-1"), $bvals->slice("-1"), ($noSwap ? qw() : $swap))->convert($nzc->type);
    my $nanismissing = ($a->[$FLAGS]&$CCSND_NAN_IS_MISSING);
    my $badismissing = ($a->[$FLAGS]&$CCSND_BAD_IS_MISSING);
    $zc              = $zc->setnantobad() if ($nanismissing && $badismissing);
    my $zc_isbad     = $zc->isbad ? 1 : 0;

    ##-- block-wise variables
    ##   + there are way too many of these...
    my ($nzai_prv,$nzai_pnx, $nzbi_prv,$nzbi_pnx, $nzci_prv,$nzci_pnx,$cmpval_prv);
    my ($nzai_cur,$nzai_nxt, $nzbi_cur,$nzbi_nxt, $nzci_cur,$nzci_nxt,$cmpval);
    my ($nzci_max, $blk_slice, $nnzc_blk,$nnzc_slice_blk);
    my ($nzai_blk,$nzbi_blk,$ixa_blk,$ixb_blk,$ixc_blk,$nzc_blk,$cimask_blk,$ciwhich_blk);
    my $nnzc_prev=0;
    do {
      ##-- align a block of data
      ccs_binop_align_block_mia($ixar,$ixbr,$istate, $nzai,$nzbi,$ostate);

      ##-- parse current alignment algorithm state
      ($nzai_prv,$nzai_pnx, $nzbi_prv,$nzbi_pnx, $nzci_prv,$nzci_pnx,$cmpval_prv) = $istate->list;
      ($nzai_cur,$nzai_nxt, $nzbi_cur,$nzbi_nxt, $nzci_cur,$nzci_nxt,$cmpval)     = $ostate->list;
      $nzci_max = $nzci_cur-1;

      if ($nzci_max >= 0) {
        ##-- construct block output pdls: nzvals
        $blk_slice = "${nzci_prv}:${nzci_max}";
        $nzai_blk  = $nzai->slice($blk_slice);
        $nzbi_blk  = $nzbi->slice($blk_slice);
        $nzc_blk   = $pdlsub->($avalsr->index($nzai_blk), $bvalsr->index($nzbi_blk), ($noSwap ? qw() : $swap));

        ##-- get indices of non-$missing c() values
        $cimask_blk   = $zc_isbad || $nzc_blk->badflag ? $nzc_blk->isgood : ($nzc_blk!=$zc);
        $cimask_blk  &= $nzc_blk->isgood   if (!$zc_isbad && $badismissing);
        $cimask_blk  &= $nzc_blk->isfinite if ($nanismissing);
        if ($cimask_blk->any) {
          $ciwhich_blk  = $cimask_blk->which;
          $nzc_blk      = $nzc_blk->index($ciwhich_blk);

          $nnzc_blk        = $nzc_blk->nelem;
          $nnzc           += $nnzc_blk;
          $nnzc_slice_blk  = "${nnzc_prev}:".($nnzc-1);

          ##-- construct block output pdls: ixc
          $ixc_blk = $ixc->slice(",$nnzc_slice_blk");
          if (!$apcp->isempty) {
            $ixa_blk = $ixa->dice_axis(1,$nzai_blk->index($ciwhich_blk));
            ($tmp=$ixc_blk->dice_axis(0,$apcp->slice("(1),"))) .= $ixa_blk->dice_axis(0,$apcp->slice("(0),"));
          }
          if (!$bpcp->isempty) {
            $ixb_blk = $ixb->dice_axis(1,$nzbi_blk->index($ciwhich_blk));
            ($tmp=$ixc_blk->dice_axis(0,$bpcp->slice("(1),"))) .= $ixb_blk->dice_axis(0,$bpcp->slice("(0),"));
          }

          ##-- construct block output pdls: nzc
          ($tmp=$nzc->slice($nnzc_slice_blk)) .= $nzc_blk;
        }
      }

      ##-- possibly allocate for another block
      if ($nzai_cur < $nixa || $nzbi_cur < $nixb) {
        $nzci_nxt -= $nzci_cur;
        $nzci_cur  = 0;

        if ($nzci_nxt+$blksz > $nzai->dim(0)) {
          $nzai = $nzai->reshape($nzci_nxt+$blksz);
          $nzbi = $nzbi->reshape($nzci_nxt+$blksz);
        }
        $ixc = $ixc->reshape($ixc->dim(0), $ixc->dim(1)+$nzai->dim(0));
        $nzc = $nzc->reshape($nzc->dim(0)+$nzai->dim(0));

        ($tmp=$istate) .= $ostate;
        $istate->set(4, $nzci_cur);
        $istate->set(5, $nzci_nxt);
      }
      $nnzc_prev = $nnzc;

    } while ($nzai_cur < $nixa || $nzbi_cur < $nixb);

    ##-- trim output pdls
    if ($nnzc > 0) {
      ##-- usual case: some values are non-missing
      $ixc = $ixc->slice(",0:".($nnzc-1));
      my $ixc_sorti = $ixc->vv_qsortveci;
      $nzc          = $nzc->index($ixc_sorti)->append($zc->convert($nzc->type));
      $nzc->sever;
      $ixc          = $ixc->dice_axis(1,$ixc_sorti);
      $ixc->sever;
    } else {
      ##-- pathological case: all values are "missing"
      $ixc = $ixc->dice_axis(1,PDL->pdl([]));
      $ixc->sever;
      $nzc = $zc->convert($zc->type);
    }

    ##-- set up final output object
    my $c = $a->shadow(
                       pdims => $pdimsc,
                       vdims => $vdimsc,
                       which => $ixc,
                       vals  => $nzc,
                      );
    if ($a->is_inplace) {
      @$a = @$c;
      $a->set_inplace(0);
      return $a;
    }
    return $c;
  };
}

##--------------------------------------------------------------
## NEW (but unused): Binary Operations: missing-is-annihilator: alignment

## \@parsed = _ccsnd_parse_signature($sig)
## \@parsed = _ccsnd_parse_signature($sig, $errorName)
##  + parses a PDL-style signature
##  + returned array has the form:
##      ( $parsed_arg1, $parsed_arg2, ..., $parsed_argN )
##  + where $parsed_arg$i =
##      { name=>$argName, type=>$type, flags=>$flags, dims=>\@argDimNames, ... }
##  + $flags is the string inside [] between type and arg name, if any
sub _ccsnd_parse_signature {
  my ($sig,$errname) = @_;
  if ($sig =~ /^\s*\(/) {
    ##-- remove leading and trailing parentheses from signature
    $sig =~ s/^\s*\(\s*//;
    $sig =~ s/\s*\)\s*//;
  }
  my @args = ($sig =~ /[\s;]*([^\;]+)/g);
  my $parsed = [];
  my ($argName,$dimStr,$type,$flags,@dims);
  foreach (@args) {
    ($type,$flags) = ('','');

    ##-- check for type
    if ($_ =~ s/^\s*(byte|short|ushort|int|long|longlong|indx|float|double)\s*//) {
      $type = $1;
    }

    ##-- check for []-flags
    if ($_ =~ s/^\s*\[([^\]]*)\]\s*//g) {
      $flags = $1;
    }

    ##-- create output list: $argNumber=>{name=>$argName, dims=>[$dimNumber=>$dimName]}
    if ($_ =~ /^\s*(\S+)\s*\(([^\)]*)\)\s*$/) {
      ($argName,$dimStr) = ($1,$2);
      @dims = grep {defined($_) && $_ ne ''} split(/\,\s*/, $dimStr);
      push(@$parsed,{type=>$type,flags=>$flags,name=>$argName,dims=>[@dims]});
    } else {
      $errname = __PACKAGE__ . "::_ccsnd_parse_signature()" if (!defined($errname));
      die("${errname}: could not parse argument string '$_' for signature '$sig'");
    }
  }
  return $parsed;
}

## \%dims = _ccsnd_align_dims(\@parsedSig, \@ccs_arg_pdls)
## \%dims = _ccsnd_align_dims(\@parsedSig, \@ccs_arg_pdls, $opName)
##  + returns an dimension-alignment structure for @parsedSig with args @ccs_arg_pdls
##  + returned %dims:
##     ( $dimName => {size=>$dimSize, phys=>\@physical }, ... )
##    - dim names "__thread_dim_${i}" are reserved
##    - \@physical = [ [$argi,$pdimi_in_argi], ... ]
sub _ccsnd_align_dims {
  my ($sig,$args,$opName) = @_;
  $opName = __PACKAGE__ . "::_ccsnd_align_dims()" if (!defined($opName));

  ##-- init: get virtual & physical dimension lists for arguments
  my @vdims = map { [$_->[$VDIMS]->list] } @$args;
  my @pdims = map { [$_->[$PDIMS]->list] } @$args;

  ##-- %dims = ($dimName => {size=>$dimSize, phys=>\@physical,... })
  ##  + dim names "__thread_dim_${i}" are reserved
  ##  + \@physical = [ [$argi,$pdimi], ... ]
  my %dims     = map {($_=>undef)} map {@{$_->{dims}}} @$sig;
  my $nthreads = 0; ##-- number of threaded dims

  ##-- iterate over signature arguments, getting & checking dimension sizes
  my ($threadi, $argi,$arg_sig,$arg_ccs, $maxdim,$dimi,$pdimi,$dim_sig,$dim_ccs,$dimName, $dimsize,$isvdim);
  foreach $argi (0..$#$sig) {
    $arg_sig = $sig->[$argi];
    $arg_ccs = $args->[$argi];

    ##-- check for unspecified args
    if (!defined($arg_ccs)) {
      next if ($arg_sig->{flags} =~ /[ot]/); ##-- ... but not output or temporaries
      croak("$opName: argument '$arg_sig->{name}' not specified!");
    }

    ##-- reset thread counter
    $threadi=0;

    ##-- check dimension sizes
    $maxdim = _max2($#{$arg_sig->{dims}}, $#{$vdims[$argi]});
    foreach $dimi (0..$maxdim) {
      if (defined($dim_sig = $arg_sig->{dims}[$dimi])) {
        ##-- explicit dimension: name it
        $dimName = $dim_sig;
      } else {
        $dimName = "__thread_dim_".($threadi++);
      }

      if ($#{$vdims[$argi]} >= $dimi) {
        $pdimi = $vdims[$argi][$dimi];
        if ($pdimi >= 0) {
          $dimsize = $pdims[$argi][$pdimi];
          $isvdim  = 0;
        } else {
          $dimsize = -$pdimi;
          $isvdim  = 1;
        }
      } else {
        $dimsize = 1;
        $isvdim  = 1;
      }

      if (!defined($dims{$dimName})) {
        ##-- new dimension
        $dims{$dimName} = { size=>$dimsize, phys=>[] };
      }
      elsif ($dims{$dimName}{size} != $dimsize) {
        if ($dims{$dimName}{size}==1) {
          ##-- ... we already had it, but as size=1 : override the stored size
          $dims{$dimName}{size} = $dimsize;
        }
        elsif ($dimsize != 1) {
          ##-- ... this is a non-trivial (size>1) dim which doesn't match: complain
          croak("$opName: size mismatch on dimension '$dimName' in argument '$arg_sig->{name}'",
                ": is $dimsize, should be $dims{$dimName}{size}");
        }
      }
      if (!$isvdim) {
        ##-- physical dim: add to alignment structure
        push(@{$dims{$dimName}{phys}}, [$argi,$pdimi]);
      }
    }
    $nthreads = $threadi if ($threadi > $nthreads);
  }

  ##-- check for undefined dims
  foreach (grep {!defined($dims{$_})} keys(%dims)) {
    #croak("$opName: cannot determine size for dimension '$_'");
    ##
    ##-- just set it to 1?
    $dims{$_} = {size=>1,phys=>[]};
  }

  return \%dims;
}

##--------------------------------------------------------------
## Binary Operations: missing-is-annihilator: wrappers

##-- arithmetical & comparison operations
foreach my $binop (
                   qw(plus minus mult divide modulo power),
                   qw(gt ge lt le eq ne spaceship),
                  )
  {
    no strict 'refs';
    *$binop = *{"${binop}_mia"} = _ccsnd_binary_op_mia($binop,PDL->can($binop));
    die(__PACKAGE__, ": could not define binary operation $binop: $@") if ($@);
  }

*pow = *pow_mia = _ccsnd_binary_op_mia('power',PDL->can('pow'),undef,1);

##-- integer-only operations
foreach my $intop (
                   qw(and2 or2 xor shiftleft shiftright),
                  )
  {
    my $deftype = PDL->can($intop)->(PDL->pdl(0),PDL->pdl(0),0)->type->ioname;
    no strict 'refs';
    *$intop = *{"${intop}_mia"} = _ccsnd_binary_op_mia($intop,PDL->can($intop),"PDL::${deftype}"->());
    die(__PACKAGE__, ": could not define integer operation $intop: $@") if ($@);
  }

## rassgn_mia($to,$from): binary assignment operation with missing-annihilator assumption
##  + argument order is REVERSE of PDL 'assgn()' argument order
*rassgn_mia = _ccsnd_binary_op_mia('rassgn', sub { PDL::assgn($_[1],$_[0]); $_[1]; });

## $to = $to->rassgn($from)
##  + calls newFromDense() with $to flags if $from is dense
##  + otherwise, copies $from to $to
##  + argument order is REVERSED wrt PDL::assgn()
sub rassgn  :lvalue {
  my ($to,$from) = @_;
  if (!ref($from) || $from->nelem==1) {
    ##-- assignment from a scalar: treat the Nd object as a mask of available values
    (my $tmp=$to->[$VALS]) .= todense($from);
    return $to;
  }
  if (isa($from,__PACKAGE__)) {
    ##-- assignment from a CCS object: copy on a full dim match or an empty "$to"
    my $fromdimp = $from->dimpdl;
    my $todimp   = $to->dimpdl;
    if ( $to->[$VALS]->dim(0)<=1 || $todimp->isempty || ($fromdimp==$todimp)->all ) {
      @$to = @{$from->copy};
      return $to;
    }
  }
  ##-- $from is something else: pass it on to 'rassgn_mia': effectively treat $to->[$WHICH] as a mask for $from
  $to->[$FLAGS] |= $CCSND_INPLACE;
  return my $tmp=$to->rassgn_mia($from);
}

## $to = $from->assgn($to)
##  + obeys PDL conventions
sub assgn  :lvalue { return my $tmp=$_[1]->rassgn($_[0]); }


##--------------------------------------------------------------
## CONTINUE HERE

## TODO:
##  + virtual dimensions: clump
##  + OPERATIONS:
##    - accumulators: (some still missing: statistical, extrema-indices, atan2, ...)

##--------------------------------------------------------------
## Matrix operations

## $c = $a->inner($b)
##  + inner product (may produce a large temporary)
sub inner  :lvalue { $_[0]->mult_mia($_[1],0)->sumover; }

## $c = $a->matmult($b)
##  + mostly ganked from PDL::Primitive::matmult
sub matmult :lvalue {
  PDL::Lite::barf("Invalid number of arguments for ", __PACKAGE__, "::matmult") if ($#_ < 1);
  my ($a,$b,$c) = @_; ##-- no $c!
  $c = undef if (!ref($c) && defined($c) && $c eq ''); ##-- strangeness: getting $c=''

  $b=toccs($b); ##-- ensure 2nd arg is a CCS object

  ##-- promote if necessary
  while ($a->getndims < 2) {$a = $a->dummy(-1)}
  while ($b->getndims < 2) {$b = $b->dummy(-1)}

  ##-- vector multiplication (easy)
  if ( ($a->dim(0)==1 && $a->dim(1)==1) || ($b->dim(0)==1 && $b->dim(1)==1) ) {
    if (defined($c)) { @$c = @{$a*$b}; return $c; }
    return $c=($a*$b);
  }

  if ($b->dim(1) != $a->dim(0)) {
    PDL::Lite::barf(sprintf("Dim mismatch in ", __PACKAGE__ , "::matmult of [%dx%d] x [%dx%d]: %d != %d",
                 $a->dim(0),$a->dim(1),$b->dim(0),$b->dim(1),$a->dim(0),$b->dim(1)));
  }

  my $_c = $a->dummy(1)->inner($b->xchg(0,1)->dummy(2)); ##-- ye olde guttes
  if (defined($c)) { @$c = @$_c; return $c; }

  return $_c;
}

## $c_dense = $a->matmult2d_sdd($b_dense)
## $c_dense = $a->matmult2d_sdd($b_dense, $zc)
##  + signature as for PDL::Primitive::matmult()
##  + should handle missing values correctly (except for BAD, inf, NaN, etc.)
##  + see PDL::CCS::MatrixOps(3pm) for details
sub matmult2d_sdd :lvalue {
  my ($a,$b,$c, $zc) = @_;
  $c  = undef if (!ref($c) && defined($c) && $c eq ''); ##-- strangeness: getting $c=''

  ##-- promote if necessary
  while ($a->getndims < 2) {$a = $a->dummy(-1)}
  while ($b->getndims < 2) {$b = $b->dummy(-1)}

  ##-- vector multiplication (easy)
  if ( ($a->dim(0)==1 && $a->dim(1)==1) || ($b->dim(0)==1 && $b->dim(1)==1) ) {
    if (defined($c)) { @$c = @{$a*$b}; return $c; }
    return $c=($a*$b);
  }

  ##-- check dim sizes
  if ($b->dim(1) != $a->dim(0)) {
    PDL::Lite::barf(sprintf("Dim mismatch in ", __PACKAGE__, "::matmult2d [%dx%d] x [%dx%d] : %d != %d",
                 $a->dims,$b->dims, $a->dim(0),$b->dim(1)));
  }

  ##-- ensure $b dense, $a physically indexed ccs
  $b = todense($b) if ($b->isa(__PACKAGE__));
  $a = $a->to_physically_indexed();
  $c //= PDL->null;

  ##-- compute $zc if required
  if (!defined($zc)) {
    $zc = (($a->missing + PDL->zeroes($a->type, $a->dim(0), 1)) x $b)->flat;
  }

  ccs_matmult2d_sdd($a->_whichND,$a->_nzvals,$a->missing->squeeze, $b, $zc, $c, $a->dim(1));

  return $c;
}

## $c_dense = $a->matmult2d_zdd($b_dense)
##  + signature as for PDL::Primitive::matmult()
##  + assumes $a->missing==0
sub matmult2d_zdd  :lvalue {
  my ($a,$b,$c) = @_;
  $c = undef if (!ref($c) && defined($c) && $c eq ''); ##-- strangeness: getting $c=''

  ##-- promote if necessary
  while ($a->getndims < 2) {$a = $a->dummy(-1)}
  while ($b->getndims < 2) {$b = $b->dummy(-1)}

  ##-- vector multiplication (easy)
  if ( ($a->dim(0)==1 && $a->dim(1)==1) || ($b->dim(0)==1 && $b->dim(1)==1) ) {
    if (defined($c)) { @$c = @{$a*$b}; return $c; }
    return $c=($a*$b);
  }

  ##-- check dim sizes
  if ($b->dim(1) != $a->dim(0)) {
    PDL::Lite::barf(sprintf("Dim mismatch in ", __PACKAGE__, "::matmult2d [%dx%d] x [%dx%d] : %d != %d",
                 $a->dims,$b->dims, $a->dim(0),$b->dim(1)));
  }

  ##-- ensure $b dense, $a physically indexed ccs
  $b = todense($b) if ($b->isa(__PACKAGE__));
  $a = $a->to_physically_indexed();
  $c //= PDL->null;

  ccs_matmult2d_zdd($a->_whichND,$a->_nzvals, $b, $c, $a->dim(1));

  return $c;
}

## $vnorm_dense = $a->vnorm($pdimi, ?$vnorm_dense)
##  + assumes $a->missing==0
sub vnorm {
  my ($a,$pdimi,$vnorm) = @_;
  $a = $a->to_physically_indexed();
  ccs_vnorm($a->_whichND->slice("($pdimi),"), $a->_nzvals, ($vnorm//=PDL->null), $a->dim($pdimi));
  return $vnorm;
}


## $vcos_dense = $a->vcos_zdd($b_dense, ?$vcos_dense, ?$norm_dense)
##  + assumes $a->missing==0
sub vcos_zdd {
  my $a = shift;
  my $b = shift;

  ##-- ensure $b dense, $a physically indexed ccs
  $b = todense($b) if (!UNIVERSAL::isa($b,__PACKAGE__));
  $a = $a->to_physically_indexed();

  ##-- guts
  return ccs_vcos_zdd($a->_whichND, $a->_nzvals, $b, $a->dim(0), @_);
}

## $vcos_dense = $a->vcos_pzd($b_sparse, ?$norm_dense, ?$vcos_dense)
##  + assumes $a->missing==0
##  + uses $a->ptr(1)
sub vcos_pzd {
  my $a = shift;
  my $b = shift;

  ##-- ensure $b dense, $a physically indexed ccs
  $b = toccs($b) if (!UNIVERSAL::isa($b,__PACKAGE__));
  $a = $a->to_physically_indexed();
  $b = $b->to_physically_indexed();

  ##-- get params
  my ($aptr,$aqsi) = $a->ptr(1);
  my $arows        = $a->[$WHICH]->slice("(0),")->index($aqsi);
  my $avals        = $a->[$VALS]->index($aqsi);
  my $anorm        = @_ ? shift : $a->vnorm(0);
  my $brows        = $b->[$WHICH]->slice("(0),");
  my $bvals        = $b->_nzvals;

  ##-- guts
  return ccs_vcos_pzd($aptr,$arows,$avals, $brows,$bvals, $anorm, @_);
}


##--------------------------------------------------------------
## Interpolation

## ($yi,$err) = $xi->interpolate($x,$y)
##  + Signature: (xi(); x(n); y(n); [o] yi(); int [o] err())
##  + routine for 1D linear interpolation
##  + Given a set of points "($x,$y)", use linear interpolation to find the values $yi at a set of points $xi.
##  + see PDL::Primitive::interpolate()
sub interpolate {
  my ($xi,$x,$y, $yi,$err) = @_;
  $yi  = $xi->clone if (!defined($yi));
  $err = $xi->clone if (!defined($err));
  $xi->[$VALS]->interpolate($x,$y, $yi->[$VALS], $err->[$VALS]);
  return wantarray ? ($yi,$err) : $yi;
}

## $yi = $xi->interpolate($x,$y)
##  + Signature: (xi(); x(n); y(n); [o] yi())
##  + routine for 1D linear interpolation
##  + see PDL::Primitive::interpol()
sub interpol  :lvalue {
  my ($xi,$x,$y, $yi) = @_;
  $yi = $xi->clone if (!defined($yi));
  $xi->[$VALS]->interpol($x,$y, $yi->[$VALS]);
  return $yi;
}


##--------------------------------------------------------------
## General Information

## $density = $ccs->density()
##  + returns PDL density as a scalar (lower is more sparse)
sub density { $_[0][$WHICH]->dim(1) / $_[0]->nelem; }

## $compressionRate = $ccs->compressionRate()
##  + higher is better
##  + negative value indicates that dense storage would be more memory-efficient
##  + pointers aren't included in the statistics: just which,nzvals,missing
sub compressionRate {
  my $ccs     = shift;
  my $dsize   = PDL->pdl($ccs->nelem) * PDL::howbig($ccs->type);
  my $ccssize = (0
                 + PDL->pdl($ccs->[$WHICH]->nelem) * PDL::howbig($ccs->[$WHICH]->type)
                 + PDL->pdl($ccs->[$VALS]->nelem)  * PDL::howbig($ccs->[$VALS]->type)
                 + PDL->pdl($ccs->[$PDIMS]->nelem) * PDL::howbig($ccs->[$PDIMS]->type)
                 + PDL->pdl($ccs->[$VDIMS]->nelem) * PDL::howbig($ccs->[$VDIMS]->type)
                );
  return (($dsize - $ccssize) / $dsize)->sclr;
}

##--------------------------------------------------------------
## Stringification & Viewing

## $dimstr = _dimstr($pdl)
sub _dimstr { return $_[0]->type.'('.join(',',$_[0]->dims).')'; }
sub _pdlstr { return _dimstr($_[0]).'='.$_[0]; }

## $str = $obj->string()
sub string {
  my ($pdims,$vdims,$which,$vals) = @{$_[0]}[$PDIMS,$VDIMS,$WHICH,$VALS];
  my $whichstr  = ''.($which->isempty ? "Empty" : $which->xchg(0,1));
  $whichstr =~ s/^([^A-Z])/   $1/mg;
  chomp($whichstr);
  return
    (
     ''
     .ref($_[0]) . ':' . _dimstr($_[0]) ."\n"
     ."  pdims:" . _pdlstr($pdims) ."\n"
     ."  vdims:" . _pdlstr($vdims) ."\n"
     ."  which:" . _dimstr($which)."^T=" . $whichstr . "\n"
     ."  vals:" . _pdlstr($vals)  ."\n"
     ."  missing:" . _pdlstr($_[0]->missing)  ."\n"
    );
}

## $pstr = $obj->lstring()
##  + literal perl-type string
sub lstring { return overload::StrVal($_[0]); }


##======================================================================
## AUTOLOAD: pass to nonzero-PDL
##  + doesn't seem to work well
##======================================================================

#our $AUTOLOAD;
#sub AUTOLOAD {
#  my $d = shift;
#  return undef if (!defined($d) || !defined($d->[$VALS]));
#  (my $name = $AUTOLOAD) =~ s/.*:://; ##-- strip qualification
#  my ($sub);
#  if (!($sub=UNIVERSAL::can($d->[$VALS],$name))) {
#    croak( ref($d) , "::$name() not defined for nzvals in ", __PACKAGE__ , "::AUTOLOAD.\n");
#  }
#  return $sub->($d->[$VALS],@_);
#}

##--------------------------------------------------------------
## Operator overloading

use overload (
              ##-- Binary ops: arithmetic
              "+" => \&plus_mia,
              "-" => \&minus_mia,
              "*" => \&mult_mia,
              "/" => \&divide_mia,
              "%" => \&modulo_mia,
              "**"  => \&power_mia,
              '+='  => sub { $_[0]->inplace->plus_mia(@_[1..$#_]); },
              '-='  => sub { $_[0]->inplace->minus_mia(@_[1..$#_]); },
              '*='  => sub { $_[0]->inplace->mult_mia(@_[1..$#_]); },
              '%='  => sub { $_[0]->inplace->divide_mia(@_[1..$#_]); },
              '**=' => sub { $_[0]->inplace->modulo_mia(@_[1..$#_]); },

              ##-- Binary ops: comparisons
              ">"  => \&gt_mia,
              "<"  => \&lt_mia,
              ">=" => \&ge_mia,
              "<=" => \&le_mia,
              "<=>" => \&spaceship_mia,
              "==" => \&eq_mia,
              "!=" => \&ne_mia,
              #"eq" => \&eq_mia

              ##-- Binary ops: bitwise & logic
              "|"  => \&or2_mia,
              "&"  => \&and2_mia,
              "^"  => \&xor_mia,
              "<<" => \&shiftleft_mia,
              ">>" => \&shiftright_mia,
              '|='  => sub { $_[0]->inplace->or2_mia(@_[1..$#_]); },
              '&='  => sub { $_[0]->inplace->and2_mia(@_[1..$#_]); },
              '^='  => sub { $_[0]->inplace->xor_mia(@_[1..$#_]); },
              '<<=' => sub { $_[0]->inplace->shiftleft_mia(@_[1..$#_]); },
              '>>=' => sub { $_[0]->inplace->shiftright_mia(@_[1..$#_]); },

              ##-- Unary operations
              "!"  => \&not,
              "~"  => \&bitnot,
              "sqrt" => \&sqrt,
              "abs"  => \&abs,
              "sin"  => \&sin,
              "cos"  => \&cos,
              "log"  => \&log,
              "exp"  => \&exp,

              ##-- assignment & assigning variants
              ".=" => \&rassgn,

              ##-- matrix operations
              'x' => \&matmult,

              ##-- Stringification & casts
              'bool' => sub {
                my $nelem = $_[0]->nelem;
                return 0 if ($nelem==0);
                croak("multielement ", __PACKAGE__, " pseudo-piddle in conditional expression") if ($nelem!=1);
                $_[0][$VALS]->at(0);
              },
              "\"\"" => \&string,
             );


1; ##-- make perl happy

##======================================================================
## PODS: Header Administrivia
##======================================================================
=pod

=head1 NAME

PDL::CCS::Nd - N-dimensional sparse pseudo-PDLs

=head1 SYNOPSIS

 use PDL;
 use PDL::CCS::Nd;

 ##---------------------------------------------------------------------
 ## Example data

 $missing = 0;                                   ##-- missing values
 $dense   = random(@dims);                       ##-- densely encoded pdl
 $dense->where(random(@dims)<=0.95) .= $missing; ##   ... made sparse

 $whichND = $dense->whichND;                     ##-- which values are present?
 $nzvals  = $dense->indexND($whichND);           ##-- ... and what are they?


 ##---------------------------------------------------------------------
 ## Constructors etc.

 $ccs = PDL::CCS:Nd->newFromDense($dense,%args);           ##-- construct from dense matrix
 $ccs = PDL::CCS:Nd->newFromWhich($whichND,$nzvals,%args); ##-- construct from index+value pairs

 $ccs = $dense->toccs();                ##-- ensure PDL::CCS::Nd-hood
 $ccs = $ccs->toccs();                  ##-- ... analogous to PDL::topdl()
 $ccs = $dense->toccs($missing,$flags); ##-- ... with optional arguments

 $ccs2 = $ccs->copy();                  ##-- copy constructor
 $ccs2 = $ccs->copyShallow();           ##-- shallow copy, mainly for internal use
 $ccs2 = $ccs->shadow(%args);           ##-- flexible copy method, for internal use

 ##---------------------------------------------------------------------
 ## Maintenance & Decoding

 $ccs = $ccs->recode();                 ##-- remove missing values from stored VALS
 $ccs = $ccs->sortwhich();              ##-- internal use only

 $dense2 = $ccs->decode();              ##-- extract to a (new) dense matrix

 $dense2 = $ccs->todense();             ##-- ensure dense storage
 $dense2 = $dense2->todense();          ##-- ... analogous to PDL::topdl()

 ##---------------------------------------------------------------------
 ## PDL API: Basic Properties

 ##---------------------------------------
 ## Type conversion & Checking
 $ccs2 = $ccs->convert($type);
 $ccs2 = $ccs->byte;
 $ccs2 = $ccs->short;
 $ccs2 = $ccs->ushort;
 $ccs2 = $ccs->long;
 $ccs2 = $ccs->longlong;
 $ccs2 = $ccs->float;
 $ccs2 = $ccs->double;

 ##---------------------------------------
 ## Dimensions
 @dims  = $ccs->dims();
 $ndims = $ccs->ndims();
 $dim   = $ccs->dim($dimi);
 $nelem = $ccs->nelem;
 $bool  = $ccs->isnull;
 $bool  = $ccs->isempty;

 ##---------------------------------------
 ## Inplace & Dataflow
 $ccs  = $ccs->inplace();
 $bool = $ccs->is_inplace;
 $bool = $ccs->set_inplace($bool);
 $ccs  = $ccs->sever;

 ##---------------------------------------
 ## Bad Value Handling

 $bool = $ccs->bad_is_missing();          ##-- treat BAD values as missing?
 $bool = $ccs->bad_is_missing($bool);
 $ccs  = $ccs->badmissing();              ##-- ... a la inplace()

 $bool = $ccs->nan_is_missing();          ##-- treat NaN values as missing?
 $bool = $ccs->nan_is_missing($bool);
 $ccs  = $ccs->nanmissing();              ##-- ... a la inplace()

 $ccs2 = $ccs->setnantobad();
 $ccs2 = $ccs->setbadtonan();
 $ccs2 = $ccs->setbadtoval($val);
 $ccs2 = $ccs->setvaltobad($val);

 ##---------------------------------------------------------------------
 ## PDL API: Dimension Shuffling

 $ccs2 = $ccs->dummy($vdimi,$size);
 $ccs2 = $ccs->reorder(@vdims);
 $ccs2 = $ccs->xchg($vdim1,$vdim2);
 $ccs2 = $ccs->mv($vdimFrom,$vdimTo);
 $ccs2 = $ccs->transpose();

 ##---------------------------------------------------------------------
 ## PDL API: Indexing

 $nzi   = $ccs->indexNDi($ndi);              ##-- guts for indexing methods
 $ndi   = $ccs->n2oned($ndi);                ##-- returns 1d pseudo-index for $ccs

 $ivals = $ccs->indexND($ndi);
 $ivals = $ccs->index2d($xi,$yi);
 $ivals = $ccs->index($flati);               ##-- buggy: no pseudo-threading!
 $ccs2  = $ccs->dice_axis($vaxis,$vaxis_ix);

 $nzi   = $ccs->xindex1d($xi);               ##-- nz-indices along 0th dimension
 $nzi   = $ccs->pxindex1d($dimi,$xi);        ##-- ... or any dimension, using ptr()
 $nzi   = $ccs->xindex2d($xi,$yi);           ##-- ... or for Cartesian product on 2d matrix

 $ccs2  = $ccs->xsubset1d($xi);              ##-- subset along 0th dimension
 $ccs2  = $ccs->pxsubset1d($dimi,$xi);       ##-- ... or any dimension, using ptr()
 $ccs2  = $ccs->xsubset2d($xi,$yi);          ##-- ... or for Cartesian product on 2d matrix

 $whichND = $ccs->whichND();
 $vals    = $ccs->whichVals();               ##-- like $ccs->indexND($ccs->whichND), but faster
 $which   = $ccs->which()

 $value = $ccs->at(@index);
 $ccs   = $ccs->set(@index,$value);

 ##---------------------------------------------------------------------
 ## PDL API: Ufuncs

 $ccs2 = $ccs->prodover;
 $ccs2 = $ccs->dprodover;
 $ccs2 = $ccs->sumover;
 $ccs2 = $ccs->dsumover;
 $ccs2 = $ccs->andover;
 $ccs2 = $ccs->orover;
 $ccs2 = $ccs->bandover;
 $ccs2 = $ccs->borover;
 $ccs2 = $ccs->maximum;
 $ccs2 = $ccs->minimum;
 $ccs2 = $ccs->maximum_ind; ##-- -1 indicates "missing" value is maximal
 $ccs2 = $ccs->minimum_ind; ##-- -1 indicates "missing" value is minimal
 $ccs2 = $ccs->nbadover;
 $ccs2 = $ccs->ngoodover;
 $ccs2 = $ccs->nnz;

 $sclr = $ccs->prod;
 $sclr = $ccs->dprod;
 $sclr = $ccs->sum;
 $sclr = $ccs->dsum;
 $sclr = $ccs->nbad;
 $sclr = $ccs->ngood;
 $sclr = $ccs->min;
 $sclr = $ccs->max;
 $bool = $ccs->any;
 $bool = $ccs->all;

 ##---------------------------------------------------------------------
 ## PDL API: Unary Operations         (Overloaded)

 $ccs2 = $ccs->bitnot;                $ccs2 = ~$ccs;
 $ccs2 = $ccs->not;                   $ccs2 = !$ccs;
 $ccs2 = $ccs->sqrt;
 $ccs2 = $ccs->abs;
 $ccs2 = $ccs->sin;
 $ccs2 = $ccs->cos;
 $ccs2 = $ccs->exp;
 $ccs2 = $ccs->log;
 $ccs2 = $ccs->log10;

 ##---------------------------------------------------------------------
 ## PDL API: Binary Operations (missing is annihilator)
 ##  + $b may be a perl scalar, a dense PDL, or a PDL::CCS::Nd object
 ##  + $c is always returned as a PDL::CCS::Nd ojbect

 ##---------------------------------------
 ## Arithmetic
 $c = $ccs->plus($b);         $c = $ccs1 +  $b;
 $c = $ccs->minus($b);        $c = $ccs1 -  $b;
 $c = $ccs->mult($b);         $c = $ccs1 *  $b;
 $c = $ccs->divide($b);       $c = $ccs1 /  $b;
 $c = $ccs->modulo($b);       $c = $ccs1 %  $b;
 $c = $ccs->power($b);        $c = $ccs1 ** $b;

 ##---------------------------------------
 ## Comparisons
 $c = $ccs->gt($b);           $c = ($ccs  >  $b);
 $c = $ccs->ge($b);           $c = ($ccs  >= $b);
 $c = $ccs->lt($b);           $c = ($ccs  <  $b);
 $c = $ccs->le($b);           $c = ($ccs  <= $b);
 $c = $ccs->eq($b);           $c = ($ccs  == $b);
 $c = $ccs->ne($b);           $c = ($ccs  != $b);
 $c = $ccs->spaceship($b);    $c = ($ccs <=> $b);

 ##---------------------------------------
 ## Bitwise Operations
 $c = $ccs->and2($b);          $c = ($ccs &  $b);
 $c = $ccs->or2($b);           $c = ($ccs |  $b);
 $c = $ccs->xor($b);           $c = ($ccs ^  $b);
 $c = $ccs->shiftleft($b);     $c = ($ccs << $b);
 $c = $ccs->shiftright($b);    $c = ($ccs >> $b);

 ##---------------------------------------
 ## Matrix Operations
 $c = $ccs->inner($b);
 $c = $ccs->matmult($b);       $c = $ccs x $b;
 $c_dense = $ccs->matmult2d_sdd($b_dense, $zc);
 $c_dense = $ccs->matmult2d_zdd($b_dense);
 
 $vnorm = $ccs->vnorm($pdimi);
 $vcos  = $ccs->vcos_zdd($b_dense);
 $vcos  = $ccs->vcos_pzd($b_ccs);

 ##---------------------------------------
 ## Other Operations
 $ccs->rassgn($b);             $ccs .= $b;
 $str = $ccs->string();        $str  = "$ccs";

 ##---------------------------------------------------------------------
 ## Indexing Utilities


 ##---------------------------------------------------------------------
 ## Low-Level Object Access

 $num_v_per_p = $ccs->_ccs_nvperp;                                  ##-- num virtual / num physical
 $pdims    = $ccs->pdims;            $vdims    = $ccs->vdims;       ##-- physical|virtual dim pdl
 $nelem    = $ccs->nelem_p;          $nelem    = $ccs->nelem_v;     ##-- physical|virtual nelem
 $nstored  = $ccs->nstored_p;        $nstored  = $ccs->nstored_v;   ##-- physical|virtual Nnz+1
 $nmissing = $ccs->nmissing_p;       $nmissing = $ccs->nmissing_v;  ##-- physical|virtual nelem-Nnz

 $ccs = $ccs->make_physically_indexed();        ##-- ensure all dimensions are physically indexed

 $bool = $ccs->allmissing();                    ##-- are all values missing?

 $missing_val = $ccs->missing;                  ##-- get missing value
 $missing_val = $ccs->missing($missing_val);    ##-- set missing value
 $ccs         = $ccs->_missing($missing_val);   ##-- ... returning the object

 $whichND_phys = $ccs->_whichND();              ##-- get/set physical indices
 $whichND_phys = $ccs->_whichND($whichND_phys);

 $nzvals_phys  = $ccs->_nzvals();               ##-- get/set physically indexed values
 $nzvals_phys  = $ccs->_nzvals($vals_phys);

 $vals_phys    = $ccs->_vals();                 ##-- get/set physically indexed values
 $vals_phys    = $ccs->_vals($vals_phys);

 $bool         = $ccs->hasptr($pdimi);          ##-- check for cached Harwell-Boeing pointer
 ($ptr,$ptrix) = $ccs->ptr($pdimi);             ##-- ... get one, caching for later use
 ($ptr,$ptrix) = $ccs->getptr($pdimi);          ##-- ... compute one, regardless of cache
 ($ptr,$ptrix) = $ccs->setptr($pdimi,$p,$pix);  ##-- ... set a cached pointer
 $ccs->clearptr($pdimi);                        ##-- ... clear a cached pointer
 $ccs->clearptrs();                             ##-- ... clear all cached pointers

 $flags = $ccs->flags();                        ##-- get/set object-local flags
 $flags = $ccs->flags($flags);

 $density = $ccs->density;                      ##-- get object density
 $crate   = $ccs->compressionRate;              ##-- get compression rate

=cut

##======================================================================
## Description
##======================================================================
=pod

=head1 DESCRIPTION

PDL::CCS::Nd provides an object-oriented implementation of
sparse N-dimensional vectors & matrices using a set of low-level
PDLs to encode non-missing values.
Currently, only a portion of the PDL API is implemented.

=cut

##======================================================================
## Globals
##======================================================================
=pod

=head1 GLOBALS

The following package-global variables are defined:

=cut

##--------------------------------------------------------------
## Globals: Block Sizes
=pod

=head2 Block Size Constants

 $BINOP_BLOCKSIZE_MIN = 1;
 $BINOP_BLOCKSIZE_MAX = 0;

Minimum (maximum) block size for block-wise incremental computation of binary operations.
Zero or undef indicates no minimum (maximum).

=cut

##--------------------------------------------------------------
## Globals: Object structure
=pod

=head2 Object Structure

PDL::CCS::Nd object are implemented as perl ARRAY-references.
For more intuitive access to object components, the following
package-global variables can be used as array indices to access
internal object structure:

=over 4

=item $PDIMS

Indexes a pdl(long,$NPdims) of physically indexed dimension sizes:

 $ccs->[$PDIMS]->at($pdim_i) == $dimSize_i

=item $VDIMS

Indexes a pdl(long,$NVdims) of "virtual" dimension sizes:

 $ccs->[$VDIMS]->at($vdim_i) == / -$vdimSize_i    if $vdim_i is a dummy dimension
                                \  $pdim_i        otherwise

The $VDIMS piddle is used for dimension-shuffling transformations such as xchg()
and reorder(), as well as for dummy().

=item $WHICH

Indexes a pdl(long,$NPdims,$Nnz) of the "physical indices" of all non-missing values
in the non-dummy dimensions of the corresponding dense matrix.
Vectors in $WHICH are guaranteed to be sorted in lexicographic order.
If your $missing value is zero, and if your qsortvec() function works,
it should be the case that:

 all( $ccs->[$WHICH] == $dense->whichND->qsortvec )

A "physically indexed dimension" is just a dimension
corresponding tp a single column of the $WHICH pdl, whereas a dummy dimension does
not correspond to any physically indexed dimension.

=item $VALS

Indexes a vector pdl($valType, $Nnz+1) of all values in the sparse matrix,
where $Nnz is the number of non-missing values in the sparse matrix.  Non-final
elements of the $VALS piddle are interpreted as the values of the corresponding
indices in the $WHICH piddle:

 all( $ccs->[$VALS]->slice("0:-2") == $dense->indexND($ccs->[$WHICH]) )

The final element of the $VALS piddle is referred to as "$missing", and
represents the value of all elements of the dense physical matrix whose
indices are not explicitly listed in the $WHICH piddle:

 all( $ccs->[$VALS]->slice("-1") == $dense->flat->index(which(!$dense)) )

=item $PTRS

Indexes an array of arrays containing Harwell-Boeing "pointer" piddle pairs
for the corresponding physically indexed dimension.
For a physically indexed dimension $d of size $N, $ccs-E<gt>[$PTRS][$d]
(if it exists) is a pair [$ptr,$ptrix] as returned by
PDL::CCS::Utils::ccs_encode_pointers($WHICH,$N), which are such that:

=over 4

=item $ptr

$ptr is a pdl(long,$N+1) containing the offsets in $ptrix corresponding
to the first non-missing value in the dimension $d.
For all $i, 0 E<lt>= $i E<lt> $N, $ptr($i) contains the
index of the first non-missing value (if any) from column $i of $dense(...,N,...)
encoded in the $WHICH piddle.  $ptr($N+1) contains the number of
physically indexed cells in the $WHICH piddle.

=item $ptrix

Is an index piddle into dim(1) of $WHICH rsp. dim(0) of $VALS whose key
positions correspond to the offsets listed in $ptr.  The point here is
that:

 $WHICH->dice_axis(1,$ptrix)

is guaranteed to be primarily sorted along the pointer dimension $d, and
stably sorted along all other dimensions, e.g. should be identical to:

 $WHICH->mv($d,0)->qsortvec->mv(0,$d)

=back


=item $FLAGS

Indexes a perl scalar containing some object-local flags.  See
L<"Object Flags"> for details.

=item $USER

Indexes the first unused position in the object array.
If you derive a class from PDL::CCS::Nd, you should use this
position to place any new object-local data.

=back

=cut


##--------------------------------------------------------------
## Globals: Object Flags
=pod

=head2 Object Flags

The following object-local constants are defined as bitmask flags:

=over 4

=item $CCSND_BAD_IS_MISSING

Bitmask of the "bad-is-missing" flag.  See the bad_is_missing() method.

=item $CCSND_NAN_IS_MISSING

Bitmask of the "NaN-is-missing" flag.  See the nan_is_missing() method.

=item $CCSND_INPLACE

Bitmask of the "inplace" flag.  See PDL::Core for details.

=item $CCSND_FLAGS_DEFAULT

Default flags for new objects.

=back

=cut

##======================================================================
## Methods
##======================================================================
=pod

=head1 METHODS

=cut

##======================================================================
## Methods: Constructors etc.
##======================================================================
=pod

=head2 Constructors, etc.

=over 4

=item $class_or_obj-E<gt>newFromDense($dense,$missing,$flags)

=for sig

  Signature ($class_or_obj; dense(N1,...,NNdims); missing(); int flags)

Class method. Create and return a new PDL::CCS::Nd object from a dense N-dimensional
PDL $dense.  If specified, $missing is used as the value for "missing" elements,
and $flags are used to initialize the object-local flags.

$missing defaults to BAD if the bad flag of $dense is set, otherwise
$missing defaults to zero.


=item $ccs-E<gt>fromDense($dense,$missing,$flags)

=for sig

  Signature ($ccs; dense(N1,...,NNdims); missing(); int flags)

Object method.  Populate a sparse matrix object from a dense piddle $dense.
See newFromDense().


=item $class_or_obj-E<gt>newFromWhich($whichND,$nzvals,%options)

=for sig

  Signature ($class_or_obj; int whichND(Ndims,Nnz); nzvals(Nnz+1); %options)

Class method. Create and return a new PDL::CCS::Nd object from a set
of indices $whichND of non-missing elements in a (hypothetical) dense piddle
and a vector $nzvals of the corresponding values.  Known %options:

  sorted  => $bool,    ##-- if true, $whichND is assumed to be pre-sorted
  steal   => $bool,    ##-- if true, $whichND and $nzvals are used literally (formerly implied 'sorted')
                       ##    + in this case, $nzvals should really be: $nzvals->append($missing)
  pdims   => $pdims,   ##-- physical dimension list; default guessed from $whichND (alias: 'dims')
  vdims   => $vdims,   ##-- virtual dims (default: sequence($nPhysDims)); alias: 'xdims'
  missing => $missing, ##-- default: BAD if $nzvals->badflag, 0 otherwise
  flags   => $flags    ##-- flags

=item $ccs-E<gt>fromWhich($whichND,$nzvals,%options)

Object method.  Guts for newFromWhich().


=item $a-E<gt>toccs($missing,$flags)

Wrapper for newFromDense().  Return a PDL::CCS::Nd object for any piddle or
perl scalar $a.
If $a is already a PDL::CCS::Nd object, just returns $a.
This method gets exported into the PDL namespace for ease of use.


=item $ccs = $ccs-E<gt>copy()

Full copy constructor.

=item $ccs2 = $ccs-E<gt>copyShallow()

Shallow copy constructor, used e.g. by dimension-shuffling transformations.
Copied components:

 $PDIMS, @$PTRS, @{$PTRS->[*]}, $FLAGS

Referenced components:

 $VDIMS, $WHICH, $VALS,  $PTRS->[*][*]


=item $ccs2 = $ccs1-E<gt>shadow(%args)

Flexible constructor for computed PDL::CCS::Nd objects.
Known %args:

  to    => $ccs2,    ##-- default: new
  pdims => $pdims2,  ##-- default: $pdims1->pdl  (alias: 'dims')
  vdims => $vdims2,  ##-- default: $vdims1->pdl  (alias: 'xdims')
  ptrs  => \@ptrs2,  ##-- default: []
  which => $which2,  ##-- default: undef
  vals  => $vals2,   ##-- default: undef
  flags => $flags,   ##-- default: $flags1

=back

=cut


##======================================================================
## Methods: Maintenance & Decoding
##======================================================================
=pod

=head2 Maintenance & Decoding

=over 4

=item $ccs = $ccs-E<gt>recode()

Recodes the PDL::CCS::Nd object, removing any missing values from its $VALS piddle.

=item $ccs = $ccs-E<gt>sortwhich()

Lexicographically sorts $ccs-E<gt>[$WHICH], altering $VALS accordingly.
Clears $PTRS.


=item $dense = $ccs-E<gt>decode()

=item $dense = $ccs-E<gt>decode($dense)

Decode a PDL::CCS::Nd object to a dense piddle.
Dummy dimensions in $ccs should be created as dummy dimensions in $dense.

=item $dense = $a-E<gt>todense()

Ensures that $a is not a PDL::CCS::Nd by wrapping decode().
For PDLs or perl scalars, just returns $a.

=back

=cut

##======================================================================
## Methods: PDL API: Basic Properties
##======================================================================
=pod

=head2 PDL API: Basic Properties

The following basic PDL API methods are implemented and/or wrapped
for PDL::CCS::Nd objects:

=over 4

=item Type Checking & Conversion

type, convert, byte, short, ushort, long, double

Type-checking and conversion routines are passed on to the $VALS sub-piddle.

=item Dimension Access

dims, dim, getdim, ndims, getndims, nelem, isnull, isempty

Note that nelem() returns the number of hypothetically addressable
cells -- the number of cells in the corresponding dense matrix, rather
than the number of non-missing elements actually stored.

=item Inplace Operations

set_inplace($bool), is_inplace(), inplace()

=item Dataflow

sever

=item Bad Value Handling

setnantobad, setbadtonan, setbadtoval, setvaltobad

See also the bad_is_missing() and nan_is_missing() methods, below.

=back

=cut

##======================================================================
## Methods: PDL API: Dimension Shuffling
##======================================================================
=pod

=head2 PDL API: Dimension Shuffling

The following dimension-shuffling methods are supported,
and should be compatible to their PDL counterparts:

=over 4

=item dummy($vdimi)

=item dummy($vdimi, $size)

Insert a "virtual" dummy dimension of size $size at dimension index $vdimi.


=item reorder(@vdim_list)

Reorder dimensions according to @vdim_list.

=item xchg($vdim1,$vdim2)

Exchange two dimensions.

=item mv($vdimFrom, $vdimTo)

Move a dimension to another position, shoving remaining
dimensions out of the way to make room.

=item transpose()

Always copies, unlike xchg().  Also unlike xchg(), works for 1d row-vectors.

=back

=cut

##======================================================================
## Methods: PDL API: Indexing
##======================================================================
=pod

=head2 PDL API: Indexing

=over 4

=item indexNDi($ndi)

=for sig

  Signature: ($ccs; int ndi(NVdims,Nind); int [o]nzi(Nind))

Guts for indexing methods.  Given an N-dimensional index piddle $ndi, return
a 1d index vector into $VALS for the corresponding values.
Missing values are returned in $nzi as $Nnz == $ccs-E<gt>_nnz_p;

Uses PDL::VectorValues::vsearchvec() internally, so expect O(Ndims * log(Nnz)) complexity.
Although the theoretical complexity is tough to beat, this method could be
made much faster in the usual (read "sparse") case by an intelligent use of $PTRS if
and when available.

=item indexND($ndi)

=item index2d($xi,$yi)

Should be mostly compatible to the PDL functions of the same names,
but without any boundary handling.

=item index($flati)

Implicitly flattens the source pdl.
This ought to be fixed.

=item dice_axis($axis_v, $axisi)

Should be compatible with the PDL function of the same name.
Returns a new PDL::CCS::Nd object which should participate
in dataflow.

=item xindex1d($xi)

Get non-missing indices for any element of $xi along 0th dimension;
$xi must be sorted in ascending order.

=item pxindex1d($dimi,$xi)

Get non-missing indices for any element of $xi along physically indexed dimension $dimi,
using L<ptr($dimi)/ptr>.
$xi must be sorted in ascending order.

=item xindex2d($xi,$yi)

Get non-missing indices for any element in Cartesian product ($xi x $yi) for 2d sparse
matrix.
$xi and $yi must be sorted in ascending order.

=item xsubset1d($xi)

Returns a subset object similar to L<dice_axis(0,$x)|PDL::Slices/dice_axis>,
but without renumbering of indices along the diced dimension;
$xi must be sorted in ascending order.

=item pxsubset1d($dimi,$xi)

Returns a subset object similar to L<dice_axis($dimi,$x)|PDL::Slices/dice_axis>,
but without renumbering of indices along the diced dimension;
$xi must be sorted in ascending order.

=item xsubset2d($xi,$yi)

Returns a subset object similar to
indexND( $xi-E<gt>slice("*1,")-E<gt>cat($yi)-E<gt>clump(2)-E<gt>xchg(0,1) ),
but without renumbering of indices;
$xi and $yi must be sorted in ascending order.


=item n2oned($ndi)

Returns a 1d pseudo-index, used for implementation of which(), etc.

=item whichND()

Should behave mostly like the PDL function of the same name.

Just returns the literal $WHICH piddle if possible: beware of dataflow!
Indices are NOT guaranteed to be returned in any surface-logical order,
although physically indexed dimensions should be sorted in physical-lexicographic
order.

=item whichVals()

Returns $VALS indexed to correspond to the indices returned by whichND().
The only reason to use whichND() and whichVals() rather than $WHICH and $VALS
would be a need for physical representations of dummy dimension indices: try
to avoid it if you can.

=item which()

As for the builtin PDL function.


=item at(@index)

Return a perl scalar corresponding to the Nd index @index.

=item set(@index, $value)

Set a non-missing value at index @index to $value.
barf()s if @index points to a missing value.

=back

=cut

##======================================================================
## Methods: Operations: Ufuncs
##======================================================================
=pod

=head2 Ufuncs

The following functions from PDL::Ufunc are implemented, and
ought to handle missing values correctly (i.e. as their dense
counterparts would):

 prodover
 prod
 dprodover
 dprod
 sumover
 sum
 dsumover
 dsum
 andover
 orover
 bandover
 borover
 maximum
 maximum_ind ##-- goofy if "missing" value is maximal
 max
 minimum
 minimum_ind ##-- goofy if "missing" value is minimal
 min
 nbadover
 nbad
 ngoodover
 ngood
 nnz
 any
 all

Some Ufuncs are still unimplemented. see PDL::CCS::Ufunc for details.

=cut

##======================================================================
## Methods: Operations: Unary
##======================================================================
=pod

=head2 Unary Operations

The following unary operations are supported:

 FUNCTION   OVERLOADS
 bitnot      ~
 not         !
 sqrt
 abs
 sin
 cos
 exp
 log
 log10

Note that any pointwise unary operation can be performed directly on
the $VALS piddle.  You can wrap such an operation MY_UNARY_OP on piddles
into a PDL::CCS::Nd method using the idiom:

 package PDL::CCS::Nd;
 *MY_UNARY_OP = _unary_op('MY_UNARY_OP', PDL->can('MY_UNARY_OP'));

Note also that unary operations may change the "missing" value associated
with the sparse matrix.  This is easily seen to be the Right Way To Do It
if you consider unary "not" over a very sparse (say 99% missing)
binary-valued matrix: is is much easier and more efficient to alter only
the 1% of physically stored (non-missing) values as well as the missing value
than to generate a new matrix with 99% non-missing values, assuming $missing==0.

=cut

##======================================================================
## Methods: Operations: Binary
##======================================================================
=pod

=head2 Binary Operations

A number of basic binary operations on PDL::CCS::Nd operations are supported,
which will produce correct results only under the assumption that "missing" values
C<$missing> are annihilators for the operation in question.  For example, if
we want to compute:

 $c = OP($a,$b)

for a binary operation OP on PDL::CCS::Nd objects C<$a> and C<$b>, the
current implementation will produce the correct result for $c only if
for all values C<$av> in C<$a> and C<$bv> in C<$b>:

 OP($av,$b->missing) == OP($a->missing,$b->missing) , and
 OP($a->missing,$bv) == OP($a->missing,$b->missing)

This is true in general for OP==\&mult and $missing==0,
but not e.g. for OP==\&plus and $missing==0.
It should always hold for $missing==BAD (except in the case of assignment,
which is a funny kind of operation anyways).

Currently, the only way to ensure that all values are computed correctly
in the general case is for $a and $b to contain exactly the same physically
indexed values, which rather defeats the purposes of sparse storage,
particularly if implicit pseudo-threading is involved (because then we would
likely wind up instantiating -- or at least inspecting -- the entire dense
matrix).  Future implementations may relax these restrictions somewhat.

The following binary operations are implemented:

=over 4

=item Arithmetic Operations

 FUNCTION     OVERLOADS
 plus          +
 minus         -
 mult          *
 divide        /
 modulo        %
 power         **

=item Comparisons

 FUNCTION     OVERLOADS
 gt            >
 ge            >=
 lt            <
 le            <=
 eq            ==
 ne            !=
 spaceship     <=>

=item Bitwise Operations

 FUNCTION     OVERLOADS
 and2          &
 or2           |
 xor           ^
 shiftleft     <<
 shiftright    >>

=item Matrix Operations

 FUNCTION     OVERLOADS
 inner        (none)
 matmult       x

=item Other Operations

 FUNCTION     OVERLOADS
 rassgn        .=
 string        ""

=back

All supported binary operation functions obey the PDL input calling conventions
(i.e. they all accept a third argument C<$swap>), and delegate computation
to the underlying PDL functions.  Note that the PDL::CCS::Nd methods currently
do B<NOT> support a third "output" argument.
To wrap a new binary operation MY_BINOP into
a PDL::CCS::Nd method, you can use the following idiom:

 package PDL::CCS::Nd;
 *MY_BINOP = _ccsnd_binary_op_mia('MY_BINOP', PDL->can('MY_BINOP'));

The low-level alignment of physically indexed values
for binary operations is performed by the
function PDL::CCS::ccs_binop_align_block_mia().
Computation is performed block-wise at the perl level to avoid
over- rsp. underflow of the space requirements for the output PDL.

=cut


##======================================================================
## Methods: Low-Level Object Access
##======================================================================
=pod

=head2 Low-Level Object Access

The following methods provide low-level access to
PDL::CCS::Nd object structure:

=over 4

=item insertWhich

=for sig

  Signature: ($ccs; int whichND(Ndims,Nnz1); vals(Nnz1))

Set or insert values in C<$ccs> for the indices in C<$whichND> to C<$vals>.
C<$whichND> need not be sorted.
Implicitly makes C<$ccs> physically indexed.
Returns the (destructively altered) C<$ccs>.


=item appendWhich

=for sig

  Signature: ($ccs; int whichND(Ndims,Nnz1); vals(Nnz1))

Like insertWhich(), but assumes that no values for any of the $whichND
indices are already present in C<$ccs>.  This is faster (because indexNDi
need not be called), but less safe.


=item is_physically_indexed()

Returns true iff only physical dimensions are present.

=item to_physically_indexed()

Just returns the calling object if all non-missing elements are already physically indexed.
Otherwise, returns a new PDL::CCS::Nd object identical to the caller
except that all non-missing elements are physically indexed.  This may gobble a large
amount of memory if the calling element has large dummy dimensions.
Also ensures that physical dimension order is identical to logical dimension order.

=item make_physically_indexed

Wrapper for to_physically_indexed() which eliminates dummy dimensions
destructively in the calling object.

Alias: make_physical().


=item pdims()

Returns the $PDIMS piddle.  See L<"Object Structure">, above.

=item vdims()

Returns the $VDIMS piddle.  See L<"Object Structure">, above.


=item setdims_p(@dims)

Sets $PDIMS piddle.   See L<"Object Structure">, above.
Returns the calling object.
Alias: setdims().

=item nelem_p()

Returns the number of physically addressable elements.

=item nelem_v()

Returns the number of virtually addressable elements.
Alias for nelem().


=item _ccs_nvperp()

Returns number of virtually addressable elements per physically
addressable element, which should be a positive integer.


=item nstored_p()

Returns actual number of physically addressed stored elements
(aka $Nnz aka $WHICH-E<gt>dim(1)).

=item nstored_v()

Returns actual number of physically+virtually addressed stored elements.


=item nmissing_p()

Returns number of physically addressable elements minus the number of
physically stored elements.

=item nmissing_v()

Returns number of physically+virtually addressable elements minus the number of
physically+virtually stored elements.


=item allmissing()

Returns true iff no non-missing values are stored.


=item missing()

=item missing($missing)

Get/set the value to use for missing elements.
Returns the (new) value for $missing.


=item _whichND()

=item _whichND($whichND)

Get/set the underlying $WHICH piddle.


=item _nzvals()

=item _nzvals($storedvals)

Get/set the slice of the underlying $VALS piddle corresponding for non-missing values only.
Alias: whichVals().


=item _vals()

=item _vals($storedvals)

Get/set the underlying $VALS piddle.

=item hasptr($pdimi)

Returns true iff a pointer for physical dim $pdimi is cached.

=item ptr($pdimi)

Get a pointer pair for a physically indexed dimension $pdimi.
Uses cached piddles in $PTRS if present, computes & caches otherwise.

$pdimi defaults to zero.  If $pdimi is zero, then it should hold that:

 all( $pi2nzi==sequence($ccs->nstored_p) )

=item getptr($pdimi)

Guts for ptr().  Does not check $PTRS and does not cache anything.

=item clearptr($pdimi)

Clears any cached Harwell-Boeing pointers for physically indexed dimension $pdimi.

=item clearptrs()

Clears any cached Harwell-Boeing pointers.

=item flags()

=item flags($flags)

Get/set object-local $FLAGS.


=item bad_is_missing()

=item bad_is_missing($bool)

Get/set the value of the object-local "bad-is-missing" flag.
If this flag is set, BAD values in $VALS are considered "missing",
regardless of the current value of $missing.

=item badmissing()

Sets the "bad-is-missing" flag and returns the calling object.

=item nan_is_missing()

=item nan_is_missing($bool)

Get/set the value of the object-local "NaN-is-missing" flag.
If this flag is set, NaN (and +inf, -inf) values in $VALS are considered "missing",
regardless of the current value of $missing.

=item nanmissing()

Sets the "nan-is-missing" flag and returns the calling object.

=back

=cut

##======================================================================
## Methods: General Information
##======================================================================
=pod

=head2 General Information

=over 4

=item density()

Returns the number of non-missing values divided by the number
of indexable values in the sparse object as a perl scalar.

=item compressionRate()

Returns the compression rate of the PDL::CCS::Nd object
compared to a dense piddle of the physically indexable dimensions.
Higher values indicate better compression (e.g. lower density).
Negative values indicate that dense storage would be more
memory-efficient.  Pointers are not included in the computation
of the compression rate.

=back

=cut

##======================================================================
## Footer Administrivia
##======================================================================

##---------------------------------------------------------------------
=pod

=head1 ACKNOWLEDGEMENTS

Perl by Larry Wall.

PDL by Karl Glazebrook, Tuomas J. Lukka, Christian Soeller, and others.

=cut

##----------------------------------------------------------------------
=pod

=head1 KNOWN BUGS

Many.

=cut


##---------------------------------------------------------------------
=pod

=head1 AUTHOR

Bryan Jurish E<lt>moocow@cpan.orgE<gt>

=head2 Copyright Policy

Copyright (C) 2007-2024, Bryan Jurish. All rights reserved.

This package is free software, and entirely without warranty.
You may redistribute it and/or modify it under the same terms
as Perl itself.

=head1 SEE ALSO

perl(1),
PDL(3perl),
PDL::SVDLIBC(3perl),
PDL::CCS::Nd(3perl),

SVDLIBC: http://tedlab.mit.edu/~dr/SVDLIBC/

SVDPACKC: http://www.netlib.org/svdpack/

=cut
