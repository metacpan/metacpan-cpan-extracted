package Parse::STDF;
require 5.10.1;
#
#  See end for copyright and license

=pod 

=head1 NAME

Parse::STDF - Module for parsing files in Standard Test Data Format

=cut

use version; $VERSION = qv('0.2.5');

=pod

=head1 SYNOPSIS

   use Time::localtime;
   use Parse::STDF;

   my $s = Parse::STDF->new ( "file.stdf" );

   while ( $s->get_record() )
   {
     if ( $s->recname() eq "MIR" )
     {
       my $mir = $s->mir();
       printf ("Started At: %s\n", ctime($mir->{START_T}) );
       printf ("Station Number: %s\n", $mir->{STAT_NUM} );
       printf ("Station Mode: %s\n", $mir->{MODE_COD} );
       printf ("Retst Code: %s\n", $mir->{RTST_COD} );
       printf ("Lot: %s\n", $mir->{LOT_ID} );
       printf ("Part Type: %s\n", $mir->{PART_TYP} );
       printf ("Node Name: %s\n", $mir->{NODE_NAM} );
       printf ("Tester Type: %s\n", $mir->{TSTR_TYP} );
       printf ("Program: %s\n", $mir->{JOB_NAM} );
       printf ("Version: %s\n", $mir->{JOB_REV} );
       printf ("Sublot: %s\n", $mir->{SBLOT_ID} );
       printf ("Operator: %s\n", $mir->{OPER_NAM} );
       printf ("Executive: %s\n", $mir->{EXEC_TYP} );
       printf ("Test Code: %s\n", $mir->{TEST_COD} );
       printf ("Test Temprature: %s\n", $mir->{TST_TEMP} );
       printf ("Package Type: %s\n", $mir->{PKG_TYP} );
       printf ("Facility ID: %s\n", $mir->{FACIL_ID} );
       printf ("Design Revision: %s\n", $mir->{DSGN_REV} );
       last;
     }
   }

=cut

=pod

=head1 DESCRIPTION

Standard Test Data Format (STDF) is a widely used standard file format for semiconductor test information. 
It is a commonly used format produced by automatic test equipment (ATE) platforms from companies such as 
LTX-Credence, Roos Instruments, Teradyne, Advantest, and others.

A STDF file is compacted into a binary format according to a well defined specification originally designed by 
Teradyne. The record layouts, field definitions, and sizes are all described within the specification. Over the 
years, parser tools have been developed to decode this binary format in several scripting languages, but as 
of yet nothing has been released to CPAN for Perl.

Parse::STDF is a first attempt. It is an object oriented module containing methods which invoke APIs of
an underlying C library called C<libstdf> (see L<http://freestdf.sourceforge.net/>).  C<libstdf> performs 
the grunt work of reading and parsing binary data into STDF records represented as C-structs.  These 
structs are in turn referenced as Perl objects.

=cut

use strict;
use warnings;
use version; 
use libstdf;

use vars qw($VERSION @EXPORT_OK @EXPORT @ISA);
require Exporter;
@ISA = qw(Exporter);
@EXPORT_OK = qw( xU1_array_ref xU2_array_ref xN1_array_ref xR4_array_ref xCn_array_ref xVn_array_ref );

=pod

=head1 METHODS

=cut

=pod

=head2 new

   my $s1 = Parse::STDF->new ( "file.stdf" );
   my $s2 = Parse::STDF->new ( "file.stdf.gz" );

Creates a new C<stdf> object.  The object represents a single file which may be in compressed gzip format.

=cut

sub new # ( $stdf )
{
  my $class = shift;
  my $self = {};

  $self->{stdf} = shift;

  ( -e $self->{stdf} ) || die "$self->{stdf} does not exist\n";

  # open file with default options
  $self->{f} = libstdf::stdf_open ($self->{stdf}); 

  # if not open then try opening with custom options
  if ( !defined($self->{f}) ) 
  {
    $self->{f} = libstdf::stdf_open_ex($self->{stdf}, $libstdf::STDF_OPTS_READ | $libstdf::STDF_OPTS_ZIP ); 
  }

  ( defined($self->{f}) ) || die "Could not open $self->{stdf}\n";

  return bless $self, $class;
}

=pod

=head2 get_record 

   my $s = Parse::STDF->new ( "file.stdf" );
   while ( $s->get_record() ) { ... };

Reads the next record using the underlying C<libstdf> library.  Returns a true/false status.

=cut

sub get_record # ()
{
  my $self = shift;
  # Free previous record if defined
  libstdf::free_record ( $self->{rec} ) if ( defined($self->{rec}) ); 
  $self->{rec} = libstdf::read_record($self->{f});
  if ( defined ($self->{rec}) )
  {
    $self->{recname} = libstdf::get_rec_name ( $self->{rec} );
	return (1);
  }
  else
  {
    $self->{recname} = undef;
    return(0);
  }
}

=pod

=head2 recname 

   if ( $s->recname() eq "MIR" ) { ... } 
 
Returns currently active record name (e.g. "MIR", "FAR", "PCR" etc). 

=cut

sub recname # ()
{
  my $self = shift;
  return ( $self->{recname} );
}

=pod

=head2 mir 

   my $mir = $s->mir();
   printf("\tSETUP_T: %s\n", ctime($mir->{SETUP_T}));
   printf("\tSTART_T: %s\n", ctime($mir->{START_T}));
   printf("\tSTAT_NUM: %s\n", $mir->{STAT_NUM});
   printf("\tMODE_COD: %s\n", $mir->{MODE_COD});
   printf("\tRTST_COD: %s\n", $mir->{RTST_COD});
   printf("\tPROT_COD: %s\n", $mir->{PROT_COD});
   printf("\tBURN_TIM: %s\n", $mir->{BURN_TIM});
   printf("\tCMOD_COD: %s\n", $mir->{CMOD_COD});
   printf("\tLOT_ID: %s\n", $mir->{LOT_ID});
   printf("\tPART_TYP: %s\n", $mir->{PART_TYP});
   printf("\tNODE_NAM: %s\n", $mir->{NODE_NAM});
   printf("\tTSTR_TYP: %s\n", $mir->{TSTR_TYP});
   printf("\tJOB_NAM: %s\n", $mir->{JOB_NAM});
   printf("\tJOB_REV: %s\n", $mir->{JOB_REV});
   printf("\tSBLOT_ID: %s\n", $mir->{SBLOT_ID});
   printf("\tOPER_NAM: %s\n", $mir->{OPER_NAM});
   printf("\tEXEC_TYP: %s\n", $mir->{EXEC_TYP});
   printf("\tEXEC_VER: %s\n", $mir->{EXEC_VER});
   printf("\tTEST_COD: %s\n", $mir->{TEST_COD});
   printf("\tTST_TEMP: %s\n", $mir->{TST_TEMP});
   printf("\tUSER_TXT: %s\n", $mir->{USER_TXT});
   printf("\tAUX_FILE: %s\n", $mir->{AUX_FILE});
   printf("\tPKG_TYP: %s\n", $mir->{PKG_TYP});
   printf("\tFAMILY_ID: %s\n", $mir->{FAMILY_ID});
   printf("\tDATE_COD: %s\n", $mir->{DATE_COD});
   printf("\tFACIL_ID: %s\n", $mir->{FACIL_ID});
   printf("\tFLOOR_ID: %s\n", $mir->{FLOOR_ID});
   printf("\tPROC_ID: %s\n", $mir->{PROC_ID});
   printf("\tOPER_FRQ: %s\n", $mir->{OPER_FRQ});
   printf("\tSPEC_NAM: %s\n", $mir->{SPEC_NAM});
   printf("\tSPEC_VER: %s\n", $mir->{SPEC_VER});
   printf("\tFLOW_ID: %s\n", $mir->{FLOW_ID});
   printf("\tSETUP_ID: %s\n", $mir->{SETUP_ID});
   printf("\tDSGN_REV: %s\n", $mir->{DSGN_REV});
   printf("\tENG_ID: %s\n", $mir->{ENG_ID});
   printf("\tROM_COD: %s\n", $mir->{ROM_COD});
   printf("\tSERL_NUM: %s\n", $mir->{SERL_NUM});
   printf("\tSUPR_NAM: %s\n", $mir->{SUPR_NAM});

Returns a hash reference to a MIR record object. 

=cut

sub mir # ()
{
  my $self = shift;
  return ( ($self->{recname} eq "MIR") ? libstdf::rec_to_mir ($self->{rec}) : undef );
}

=pod

=head2 sdr 

   my $sdr = $s->sdr();
   printf("\tHEAD_NUM: %s\n", $sdr->{HEAD_NUM});
   printf("\tSITE_GRP: %s\n", $sdr->{SITE_GRP});
   printf("\tSITE_CNT: %s\n", $sdr->{SITE_CNT});
   print "\tSITE_NUM: ", join(", ",@{xU1_array_ref($sdr->{SITE_NUM}, $sdr->{SITE_CNT})}), "\n";
   printf("\tHAND_TYP: %s\n", $sdr->{HAND_TYP});
   printf("\tHAND_ID: %s\n", $sdr->{HAND_ID});
   printf("\tCARD_TYP: %s\n", $sdr->{CARD_TYP});
   printf("\tCARD_ID: %s\n", $sdr->{CARD_ID});
   printf("\tLOAD_TYP: %s\n", $sdr->{LOAD_TYP});
   printf("\tLOAD_ID: %s\n", $sdr->{LOAD_ID});
   printf("\tDIB_TYP: %s\n", $sdr->{DIB_TYP});
   printf("\tDIB_ID: %s\n", $sdr->{DIB_ID});
   printf("\tCABL_TYP: %s\n", $sdr->{CABL_TYP});
   printf("\tCABL_ID: %s\n", $sdr->{CABL_ID});
   printf("\tCONT_TYP: %s\n", $sdr->{CONT_TYP});
   printf("\tCONT_ID: %s\n", $sdr->{CONT_ID});
   printf("\tLASR_TYP: %s\n", $sdr->{LASR_TYP});
   printf("\tLASR_ID: %s\n", $sdr->{LASR_ID});
   printf("\tEXTR_TYP: %s\n", $sdr->{EXTR_TYP});
   printf("\tEXTR_ID: %s\n", $sdr->{EXTR_ID});

Returns a hash reference to a SDR record object. 

=cut

sub sdr # ()
{
  my $self = shift;
  return ( ($self->{recname} eq "SDR") ? libstdf::rec_to_sdr ($self->{rec}) : undef );
}

=pod

=head2 pcr 

   my $pcr = $s->pcr();
   printf("\tHEAD_NUM: %s\n", $pcr->{HEAD_NUM});
   printf("\tSITE_NUM: %s\n", $pcr->{SITE_NUM});
   printf("\tPART_CNT: %s\n", $pcr->{PART_CNT});
   printf("\tRTST_CNT: %s\n", $pcr->{RTST_CNT});
   printf("\tABRT_CNT: %s\n", $pcr->{ABRT_CNT});
   printf("\tGOOD_CNT: %s\n", $pcr->{GOOD_CNT});
   printf("\tFUNC_CNT: %s\n", $pcr->{FUNC_CNT});

Returns a hash reference to a PCR record object. 

=cut

sub pcr # ()
{
  my $self = shift;
  return ( ($self->{recname} eq "PCR") ? libstdf::rec_to_pcr ($self->{rec}) : undef );
}

=pod

=head2 mrr 

   my $mrr = $s->mrr();
   printf("\tFINISH_T: %s\n", ctime($mrr->{FINISH_T}));
   printf("\tDISP_COD: %s\n", $mrr->{DISP_COD});
   printf("\tUSR_DESC: %s\n", $mrr->{USR_DESC});
   printf("\tEXC_DESC: %s\n", $mrr->{EXC_DESC});

Returns a hash reference to a MRR record object. 

=cut

sub mrr # ()
{
  my $self = shift;
  return ( ($self->{recname} eq "MRR") ? libstdf::rec_to_mrr ($self->{rec}) : undef );
}

=pod

=head2 wir 

   my $wir = $s->wir();
   printf("\tHEAD_NUM: %s\n", $wir->{HEAD_NUM});
   printf("\tSITE_GRP: %s\n", $wir->{SITE_GRP});
   printf("\tSTART_T: %s\n", ctime($wir->{START_T}));
   printf("\tWAFER_ID: %s\n", $wir->{WAFER_ID});

Returns a hash reference to a WIR record object. 

=cut

sub wir # ()
{
  my $self = shift;
  return ( ($self->{recname} eq "WIR") ? libstdf::rec_to_wir ($self->{rec}) : undef );
}

=pod

=head2 pir 

   my $pir = $s->pir();
   printf("\tHEAD_NUM: %s\n", $pir->{HEAD_NUM});
   printf("\tSITE_NUM: %s\n", $pir->{SITE_NUM});

Returns a hash reference to a PIR record object. 

=cut

sub pir # ()
{
  my $self = shift;
  return ( ($self->{recname} eq "PIR") ? libstdf::rec_to_pir ($self->{rec}) : undef );
}

=pod

=head2 prr 

   my $prr = $s->prr();
   printf("\tHEAD_NUM: %s\n", $prr->{HEAD_NUM});
   printf("\tSITE_NUM: %s\n", $prr->{SITE_NUM});
   printf("\tPART_FLG: %s\n", $prr->{PART_FLG});
   printf("\tNUM_TEST: %s\n", $prr->{NUM_TEST});
   printf("\tHARD_BIN: %s\n", $prr->{HARD_BIN});
   printf("\tSOFT_BIN: %s\n", $prr->{SOFT_BIN});
   printf("\tX_COORD: %s\n", $prr->{X_COORD});
   printf("\tY_COORD: %s\n", $prr->{Y_COORD});
   printf("\tTEST_T: %s\n", ctime($prr->{TEST_T}));
   printf("\tPART_ID: %s\n", $prr->{PART_ID});
   printf("\tPART_TXT: %s\n", $prr->{PART_TXT});
   printf("\tPART_FIX: %s\n", $prr->{PART_FIX});

Returns a hash reference to a PRR record object. 

=cut

sub prr # ()
{
  my $self = shift;
  return ( ($self->{recname} eq "PRR") ? libstdf::rec_to_prr ($self->{rec}) : undef );
}

=pod

=head2 ptr 

   my $ptr = $s->ptr();
   printf("\tTEST_NUM: %s\n", $ptr->{TEST_NUM});
   printf("\tHEAD_NUM: %s\n", $ptr->{HEAD_NUM});
   printf("\tSITE_NUM: %s\n", $ptr->{SITE_NUM});
   printf("\tTEST_FLG: %X\n", $ptr->{TEST_FLG});
   printf("\tPARM_FLG: %X\n", $ptr->{PARM_FLG});
   printf("\tRESULT: %s\n", $ptr->{RESULT});
   printf("\tTEST_TXT: %s\n", $ptr->{TEST_TXT});
   printf("\tALARM_ID: %s\n", $ptr->{ALARM_ID});
   printf("\tOPT_FLAG: %X\n", $ptr->{OPT_FLAG});
   printf("\tRES_SCAL: %s\n", $ptr->{RES_SCAL});
   printf("\tLLM_SCAL: %s\n", $ptr->{LLM_SCAL});
   printf("\tHLM_SCAL: %s\n", $ptr->{HLM_SCAL});
   printf("\tLO_LIMIT: %s\n", $ptr->{LO_LIMIT});
   printf("\tUNITS: %s\n", $ptr->{UNITS});
   printf("\tC_RESFMT: %s\n", $ptr->{C_RESFMT});
   printf("\tC_LLMFMT: %s\n", $ptr->{C_LLMFMT});
   printf("\tLO_SPEC: %s\n", $ptr->{LO_SPEC});
   printf("\tHI_SPEC: %s\n", $ptr->{HI_SPEC});

Returns a hash reference to a PTR record object. 

=cut

sub ptr # ()
{
  my $self = shift;
  return ( ($self->{recname} eq "PTR") ? libstdf::rec_to_ptr ($self->{rec}) : undef );
}

=pod

=head2 dtr 

   my $dtr = $s->dtr();
   printf("\tTEXT_DAT: %s\n", $dtr->{TEXT_DAT});

Returns a hash reference to a DTR record object. 

=cut

sub dtr # ()
{
  my $self = shift;
  return ( ($self->{recname} eq "DTR") ? libstdf::rec_to_dtr ($self->{rec}) : undef );
}

=pod

=head2 atr 

   my $atr = $s->atr();
   printf ("\tMID_TIM: %s\n", ctime($atr->{MOD_TIM}) );
   printf ("\tCMD_LINE: %s\n", $atr->{CMD_LINE} );

Returns a hash reference to a ATR record object. 

=cut

sub atr # ()
{
  my $self = shift;
  return ( ($self->{recname} eq "ATR") ? libstdf::rec_to_atr ($self->{rec}) : undef );
}

=pod

=head2 far 

   my $far = $s->far();
   printf ("\tCPU_TYPE: %s\n", $far->{CPU_TYPE});
   printf ("\tSTDF_VER: %s\n", $far->{STDF_VER});

Returns a hash reference to a FAR record object. 

=cut

sub far # ()
{
  my $self = shift;
  return ( ($self->{recname} eq "FAR") ? libstdf::rec_to_far ($self->{rec}) : undef );
}

=pod

=head2 hbr 

   my $hbr = $s->hbr();
   printf("\tHEAD_NUM: %s\n", $hbr->{HEAD_NUM});
   printf("\tSITE_NUM: %s\n", $hbr->{SITE_NUM});
   printf("\tHBIN_NUM: %s\n", $hbr->{HBIN_NUM});
   printf("\tHBIN_CNT: %s\n", $hbr->{HBIN_CNT});
   printf("\tHBIN_PF: %s\n", $hbr->{HBIN_PF});
   printf("\tHBIN_NAM: %s\n", $hbr->{HBIN_NAM});

Returns a hash reference to a HBR record object. 

=cut

sub hbr # ()
{
  my $self = shift;
  return ( ($self->{recname} eq "HBR") ? libstdf::rec_to_hbr ($self->{rec}) : undef );
}

=pod

=head2 sbr 

   my $sbr = $s->sbr();
   printf("\tHEAD_NUM: %s\n", $sbr->{HEAD_NUM});
   printf("\tSITE_NUM: %s\n", $sbr->{SITE_NUM});
   printf("\tSBIN_NUM: %s\n", $sbr->{SBIN_NUM});
   printf("\tSBIN_CNT: %s\n", $sbr->{SBIN_CNT});
   printf("\tSBIN_PF: %s\n", $sbr->{SBIN_PF});
   printf("\tSBIN_NAM: %s\n", $sbr->{SBIN_NAM});

Returns a hash reference to a SBR record object. 

=cut

sub sbr # ()
{
  my $self = shift;
  return ( ($self->{recname} eq "SBR") ? libstdf::rec_to_sbr ($self->{rec}) : undef );
}

=pod

=head2 pmr 

   my $pmr = $s->pmr();
   printf("\tPMR_INDX: %s\n", $pmr->{PMR_INDX});
   printf("\tCHAN_TYP: %s\n", $pmr->{CHAN_TYP});
   printf("\tCHAN_NAM: %s\n", $pmr->{CHAN_NAM});
   printf("\tPHY_NAM: %s\n", $pmr->{PHY_NAM});
   printf("\tLOG_NAM: %s\n", $pmr->{LOG_NAM});
   printf("\tHEAD_NUM: %s\n", $pmr->{HEAD_NUM});
   printf("\tSITE_NUM: %s\n", $pmr->{SITE_NUM});

Returns a hash reference to a PMR record object. 

=cut

sub pmr # ()
{
  my $self = shift;
  return ( ($self->{recname} eq "PMR") ? libstdf::rec_to_pmr ($self->{rec}) : undef );
}

=pod

=head2 pgr 

   my $pgr = $s->pgr();
   printf("\tGRP_INDX: %s\n", $pgr->{GRP_INDX});
   printf("\tGRP_NAM: %s\n", $pgr->{GRP_NAM});
   printf("\tINDX_CNT: %s\n", $pgr->{INDX_CNT});
   print "\tPMR_INDX: ", join(", ",@{xU2_array_ref($pgr->{PMR_INDX}, $pgr->{INDX_CNT})}), "\n";

Returns a hash reference to a PGR record object. 

=cut

sub pgr # ()
{
  my $self = shift;
  return ( ($self->{recname} eq "PGR") ? libstdf::rec_to_pgr ($self->{rec}) : undef );
}

=pod

=head2 plr 

   my $plr = $s->plr();
   printf("\tGRP_CNT: %s\n", $plr->{GRP_CNT});
   print "\tGRP_INDX: ", join(", ",@{xU2_array_ref($plr->{GRP_INDX}, $plr->{GRP_CNT})}), "\n";
   print "\tGRP_MODE: ", join(", ",@{xU2_array_ref($plr->{GRP_MODE}, $plr->{GRP_CNT})}), "\n";
   print "\tGRP_RADX: ", join(", ",@{xU1_array_ref($plr->{GRP_RADX}, $plr->{GRP_CNT})}), "\n";
   print "\tPGM_CHAR: ", join(", ",@{xCn_array_ref($plr->{PGM_CHAR}, $plr->{GRP_CNT})}), "\n";
   print "\tRTN_CHAR: ", join(", ",@{xCn_array_ref($plr->{RTN_CHAR}, $plr->{GRP_CNT})}), "\n";
   print "\tPGM_CHAL: ", join(", ",@{xCn_array_ref($plr->{PGM_CHAL}, $plr->{GRP_CNT})}), "\n";
   print "\tRTN_CHAL: ", join(", ",@{xCn_array_ref($plr->{RTN_CHAL}, $plr->{GRP_CNT})}), "\n";

Returns a hash reference to a PLR record object. 

=cut

sub plr # ()
{
  my $self = shift;
  return ( ($self->{recname} eq "PLR") ? libstdf::rec_to_plr ($self->{rec}) : undef );
}

=pod

=head2 rdr 

   my $rdr = $s->rdr();
   printf("\tNUM_BINS: %s\n", $rdr->{NUM_BINS});
   print "\tRTST_BIN: ", join(", ",@{xU2_array_ref($rdr->{RTST_BIN}, $rdr->{NUM_BINS})}), "\n";

Returns a hash reference to a RDR record object. 

=cut

sub rdr # ()
{
  my $self = shift;
  return ( ($self->{recname} eq "RDR") ? libstdf::rec_to_rdr ($self->{rec}) : undef );
}

=pod

=head2 wrr 

   my $wrr = $s->wrr();
   printf("\tHEAD_NUM: %s\n", $wrr->{HEAD_NUM});
   printf("\tSITE_GRP: %s\n", $wrr->{SITE_GRP});
   printf("\tFINISH_T: %s\n", ctime($wrr->{FINISH_T}));
   printf("\tPART_CNT: %s\n", $wrr->{PART_CNT});
   printf("\tRTST_CNT: %s\n", $wrr->{RTST_CNT});
   printf("\tABRT_CNT: %s\n", $wrr->{ABRT_CNT});
   printf("\tGOOD_CNT: %s\n", $wrr->{GOOD_CNT});
   printf("\tFUNC_CNT: %s\n", $wrr->{FUNC_CNT});
   printf("\tWAFER_ID: %s\n", $wrr->{WAFER_ID});
   printf("\tFABWF_ID: %s\n", $wrr->{FABWF_ID});
   printf("\tFRAME_ID: %s\n", $wrr->{FRAME_ID});
   printf("\tMASK_ID: %s\n", $wrr->{MASK_ID});
   printf("\tUSR_DESC: %s\n", $wrr->{USR_DESC});
   printf("\tEXC_DESC: %s\n", $wrr->{EXC_DESC});

Returns a hash reference to a WRR record object. 

=cut

sub wrr # ()
{
  my $self = shift;
  return ( ($self->{recname} eq "WRR") ? libstdf::rec_to_wrr ($self->{rec}) : undef );
}

=pod

=head2 wcr 

   my $wcr = $s->wcr();
   printf("\tWAFR_SIZ: %s\n", $wcr->{WAFR_SIZ});
   printf("\tDIE_HT: %s\n", $wcr->{DIE_HT});
   printf("\tDIE_WID: %s\n", $wcr->{DIE_WID});
   printf("\tWF_UNITS: %s\n", $wcr->{WF_UNITS});
   printf("\tWF_FLAT: %s\n", $wcr->{WF_FLAT});
   printf("\tCENTER_X: %s\n", $wcr->{CENTER_X});
   printf("\tCENTER_Y: %s\n", $wcr->{CENTER_Y});
   printf("\tPOS_X: %s\n", $wcr->{POS_X});
   printf("\tPOS_Y: %s\n", $wcr->{POS_Y});

Returns a hash reference to a WCR record object. 

=cut

sub wcr # ()
{
  my $self = shift;
  return ( ($self->{recname} eq "WCR") ? libstdf::rec_to_wcr ($self->{rec}) : undef );
}

=pod

=head2 tsr 

   my $tsr = $s->tsr();
   printf("\tHEAD_NUM: %s\n", $tsr->{HEAD_NUM});
   printf("\tSITE_NUM: %s\n", $tsr->{SITE_NUM});
   printf("\tTEST_TYP: %s\n", $tsr->{TEST_TYP});
   printf("\tTEST_NUM: %s\n", $tsr->{TEST_NUM});
   printf("\tEXEC_CNT: %s\n", $tsr->{EXEC_CNT});
   printf("\tFAIL_CNT: %s\n", $tsr->{FAIL_CNT});
   printf("\tALRM_CNT: %s\n", $tsr->{ALRM_CNT});
   printf("\tTEST_NAM: %s\n", $tsr->{TEST_NAM});
   printf("\tSEQ_NAME: %s\n", $tsr->{SEQ_NAME});
   printf("\tTEST_LBL: %s\n", $tsr->{TEST_LBL});
   printf("\tOPT_FLAG: %X\n", $tsr->{OPT_FLAG});
   printf("\tTEST_TIM: %s\n", $tsr->{TEST_TIM});
   printf("\tTEST_MIN: %s\n", $tsr->{TEST_MIN});
   printf("\tTEST_MAX: %s\n", $tsr->{TEST_MAX});
   printf("\tTST_SUMS: %s\n", $tsr->{TST_SUMS});
   printf("\tTST_SQRS: %s\n", $tsr->{TST_SQRS});

Returns a hash reference to a TSR record object. 

=cut

sub tsr # ()
{
  my $self = shift;
  return ( ($self->{recname} eq "TSR") ? libstdf::rec_to_tsr ($self->{rec}) : undef );
}

=pod

=head2 mpr 

   my $mpr = $s->mpr();
   printf("\tTEST_NUM: %s\n", $mpr->{TEST_NUM});
   printf("\tHEAD_NUM: %s\n", $mpr->{HEAD_NUM});
   printf("\tSITE_NUM: %s\n", $mpr->{SITE_NUM});
   printf("\tTEST_FLG: %X\n", $mpr->{TEST_FLG});
   printf("\tPARM_FLG: %X\n", $mpr->{PARM_FLG});
   printf("\tRTN_ICNT: %s\n", $mpr->{RTN_ICNT});
   printf("\tRSLT_CNT: %s\n", $mpr->{RSLT_CNT});
   print "\tRTN_STAT: ", join(", ", @{xN1_array_ref($mpr->{RTN_STAT}, $mpr->{RTN_ICNT})} ), "\n";
   print "\tRTN_RSLT: ", join(", ", @{xR4_array_ref($mpr->{RTN_RSLT}, $mpr->{RSLT_CNT})} ), "\n";
   printf("\tTEST_TXT: %s\n", $mpr->{TEST_TXT});
   printf("\tALARM_ID: %s\n", $mpr->{ALARM_ID});
   printf("\tOPT_FLAG: %X\n", $mpr->{OPT_FLAG});
   printf("\tRES_SCAL: %s\n", $mpr->{RES_SCAL});
   printf("\tLLM_SCAL: %s\n", $mpr->{LLM_SCAL});
   printf("\tHLM_SCAL: %s\n", $mpr->{HLM_SCAL});
   printf("\tLO_LIMIT: %s\n", $mpr->{LO_LIMIT});
   printf("\tHI_LIMIT: %s\n", $mpr->{HI_LIMIT});
   printf("\tSTART_IN: %s\n", $mpr->{START_IN});
   printf("\tINCR_IN: %s\n", $mpr->{INCR_IN});
   print "\tRTN_INDX: ", join(", ", @{xU2_array_ref($mpr->{RTN_INDX}, $mpr->{RTN_ICNT})} ), "\n";
   printf("\tUNITS: %s\n", $mpr->{UNITS});
   printf("\tUNITS_IN: %s\n", $mpr->{UNITS_IN});
   printf("\tC_RESFMT: %s\n", $mpr->{C_RESFMT});
   printf("\tC_LLMFMT: %s\n", $mpr->{C_LLMFMT});
   printf("\tC_HLMFMT: %s\n", $mpr->{C_HLMFMT});
   printf("\tLO_SPEC: %s\n", $mpr->{LO_SPEC});
   printf("\tHI_SPEC: %s\n", $mpr->{HI_SPEC});

Returns a hash reference to a MPR record object. 

=cut

sub mpr # ()
{
  my $self = shift;
  return ( ($self->{recname} eq "MPR") ? libstdf::rec_to_mpr ($self->{rec}) : undef );
}

=pod

=head2 ftr 

   my $ftr = $s->ftr();
   printf("\tTEST_NUM: %s\n", $ftr->{TEST_NUM});
   printf("\tHEAD_NUM: %s\n", $ftr->{HEAD_NUM});
   printf("\tSITE_NUM: %s\n", $ftr->{SITE_NUM});
   printf("\tTEST_FLG: %X\n", $ftr->{TEST_FLG});
   printf("\tOPT_FLAG: %X\n", $ftr->{OPT_FLAG});
   printf("\tCYCL_CNT: %s\n", $ftr->{CYCL_CNT});
   printf("\tREL_VADR: %s\n", $ftr->{REL_VADR});
   printf("\tREPT_CNT: %s\n", $ftr->{REPT_CNT});
   printf("\tNUM_FAIL: %s\n", $ftr->{NUM_FAIL});
   printf("\tXFAIL_AD: %s\n", $ftr->{XFAIL_AD});
   printf("\tYFAIL_AD: %s\n", $ftr->{YFAIL_AD});
   printf("\tVECT_OFF: %s\n", $ftr->{VECT_OFF});
   printf("\tRTN_ICNT: %s\n", $ftr->{RTN_ICNT});
   printf("\tPGM_ICNT: %s\n", $ftr->{PGM_ICNT});
   print "\tRTN_INDX: ", join(", ", @{xU2_array_ref($ftr->{RTN_INDX}, $ftr->{RTN_ICNT})} ), "\n";
   print "\tRTN_STAT: ", join(", ", @{xN1_array_ref($ftr->{RTN_STAT}, $ftr->{RTN_ICNT})} ), "\n";
   print "\tPGM_INDX: ", join(", ", @{xU2_array_ref($ftr->{PGM_INDX}, $ftr->{PGM_ICNT})} ), "\n";
   print "\tPGM_STAT: ", join(", ", @{xN1_array_ref($ftr->{PGM_STAT}, $ftr->{PGM_ICNT})} ), "\n";
   print "\tFAIL_PIN: ", join(", ", @{$ftr->{FAIL_PIN}} ), "\n";
   printf("\tVECT_NAM: %s\n", $ftr->{VECT_NAM});
   printf("\tTIME_SET: %s\n", $ftr->{TIME_SET});
   printf("\tOP_CODE: %s\n", $ftr->{OP_CODE});
   printf("\tTEST_TXT: %s\n", $ftr->{TEST_TXT});
   printf("\tALARM_ID: %s\n", $ftr->{ALARM_ID});
   printf("\tPROG_TXT: %s\n", $ftr->{PROG_TXT});
   printf("\tRSLT_TXT: %s\n", $ftr->{RSLT_TXT});
   printf("\tPATG_NUM: %s\n", $ftr->{PATG_NUM});
   print "\tSPIN_MAP: ", join(", ", @{$ftr->{SPIN_MAP}} ), "\n";

Returns a hash reference to a FTR record object. 

=cut

sub ftr # ()
{
  my $self = shift;
  return ( ($self->{recname} eq "FTR") ? libstdf::rec_to_ftr ($self->{rec}) : undef );
}

=pod

=head2 bps 

   my $bps = $s->bps();
   printf("\tSEQ_NAME: %s\n", $bps->{SEQ_NAME});

Returns a hash reference to a BPS record object. 

=cut

sub bps # ()
{
  my $self = shift;
  return ( ($self->{recname} eq "BPS") ? libstdf::rec_to_bps ($self->{rec}) : undef );
}

=pod

=head2 eps 

   my $eps = $s->eps();

Returns a hash reference to a EPS record object. 

=cut

sub eps # ()
{
  my $self = shift;
  return ( ($self->{recname} eq "EPS") ? libstdf::rec_to_eps ($self->{rec}) : undef );
}

=pod

=head2 gds 

   my $gds = $s->gds();

Returns a hash reference to a GDS record object. 

=cut

sub gds # ()
{
  my $self = shift;
  return ( ($self->{recname} eq "GDS") ? libstdf::rec_to_gds ($self->{rec}) : undef );
}

=pod

=head2 gdr 

   my $gdr = $s->gdr();
   printf("\tFLD_CNT: %s\n", $gdr->{FLD_CNT});
   print "\tGEN_DATA: ", join(", ",@{xVn_array_ref($gdr->{GEN_DATA}, $gdr->{FLD_CNT})}), "\n";

Returns a hash reference to a GDR record object. 

=cut

sub gdr # ()
{
  my $self = shift;
  return ( ($self->{recname} eq "GDR") ? libstdf::rec_to_gdr ($self->{rec}) : undef );
}


=pod

=head2 unknown

   my $unk = $s->unknown();

Unknown record is not part of the STDF specification.  It is primarily used for debugging
purposes.

=cut

sub unknown # ()
{
  my $self = shift;
  return ( defined($self->{rec}) ? libstdf::rec_to_unknown ($self->{rec}) : undef );
}

=pod

=head2 version

   my $ver = $s->version();

Returns the STDF version number which identifies the STDF specification. 

=cut

sub version # ()
{
  my $self = shift;
  return ( defined($self->{f}) ? libstdf::stdf_version($self->{f}) : undef );
}

=pod

=head1 UTILITY FUNCTIONS

Utility functions for converting C<libstdf> data types C<[xU1, xU2, xN1, xR4, xCn]> into Perl array reference objects.

=over 4

=item xU1_array_ref(xU1,len)

  my $plr = $s->plr();
  print "\tGRP_RADX: ", join(", ",@{xU1_array_ref($plr->{GRP_RADX}, $plr->{GRP_CNT})}), "\n";

=item xU2_array_ref(xU2,len)
 
  my $ftr = $s->ftr();
  print "\tPGM_INDX: ", join(", ", @{xU2_array_ref($ftr->{PGM_INDX}, $ftr->{PGM_ICNT})} ), "\n";

=item xN1_array_ref(xN1,len)

  my $mpr = $s->mpr();
  print "\tRTN_STAT: ", join(", ", @{xN1_array_ref($mpr->{RTN_STAT}, $mpr->{RTN_ICNT})} ), "\n";

=item xR4_array_ref(xR4,len)

  my $mpr = $s->mpr();
  print "\tRTN_RSLT: ", join(", ", @{xR4_array_ref($mpr->{RTN_RSLT}, $mpr->{RSLT_CNT})} ), "\n";

=item xCn_array_ref(xCn,len)

  my $plr = $s->plr();
  print "\tPGM_CHAR: ", join(", ",@{xCn_array_ref($plr->{PGM_CHAR}, $plr->{GRP_CNT})}), "\n";

=item xVn_array_ref(xVn,len)

  my $gdr = $s->gdr();
  print "\tGEN_DATA: ", join(", ",@{xVn_array_ref($gdr->{GEN_DATA}, $gdr->{FLD_CNT})}), "\n";

=back

=cut


sub xU1_array_ref # ( $xU1 , $len )
{
  my $xU1 = shift;
  my $len = shift;
  return ( libstdf::xU1_to_RV($xU1, $len) );
}

sub xU2_array_ref # ( $xU2 , $len )
{
  my $xU2 = shift;
  my $len = shift;
  return ( libstdf::xU2_to_RV($xU2, $len) );
}

sub xN1_array_ref # ( $xN1 , $len )
{
  my $xN1 = shift;
  my $len = shift;
  return ( libstdf::xN1_to_RV($xN1, $len) );
}

sub xR4_array_ref # ( $xR4 , $len )
{
  my $xR4 = shift;
  my $len = shift;
  return ( libstdf::xR4_to_RV($xR4, $len) );
}

sub xCn_array_ref # ( $xCn , $len )
{
  my $xCn = shift;
  my $len = shift;
  return ( libstdf::xCn_to_RV($xCn, $len) );
}

sub xVn_array_ref # ( $xVn , $len )
{
  my $xVn = shift;
  my $len = shift;
  return ( libstdf::xVn_to_RV($xVn, $len) );
}

sub DESTROY #()
{
  my $self = shift;
  libstdf::stdf_close($self->{f}) if ( defined ($self->{f}) );
}

1; # Magic true value required at the end of a moudle

__END__

=pod

=head1 SEE ALSO

An interface module called C<libstdf.pm> was generated automatically by I<swig> (see L<http://swig.org>) 
using C<libstdf's> header files as input.  This module is the glue between Parse::STDF and C<libstdf>.

For an intro to the Standard Test Data Format (along with references to detailed documentation) 
see L<http://en.wikipedia.org/wiki/Standard_Test_Data_Format>.

=head1 AUTHOR

Erick Jordan <ejordan@cpan.org>

=head1 COPYRIGHT

Copyright (C) 2014 Erick Jordan <ejordan@cpan.org>

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.

=cut
