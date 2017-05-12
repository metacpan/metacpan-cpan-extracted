#!/usr/bin/env perl
#  Copyright (C) 2014 Erick Jordan <ejordan@cpan.org>
#
#  This program is free software: you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation, either version 3 of the License, or
#  (at your option) any later version.
#
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#
#  You should have received a copy of the GNU General Public License
#  along with this program.  If not, see <http://www.gnu.org/licenses/>.

# Program takes an input a STDF file and dumps records to ASCII

package main;

BEGIN {
  chdir 'example' if -d 'example';
  use lib '../lib';
  eval "use blib";
}

use strict;
use warnings;
use Time::localtime;
use Parse::STDF qw ( xU1_array_ref xU2_array_ref xN1_array_ref xR4_array_ref xCn_array_ref xVn_array_ref );

( $#ARGV == 0 ) || die "Usage: $0 stdf\n";
my $stdf = $ARGV[0];

my $s = Parse::STDF->new ( $stdf );


while ( $s->get_record() )
{
  my $unk = $s->unknown();

  if ( not defined($s->recname()) or $s->recname() eq "???" )
  {
    my $err;
    $err .= sprintf ("\tBytes: %i\n", $unk->{header}->{REC_LEN} );
    $err .= sprintf ("\tTYP: 0x%X [%i]\n", $unk->{header}->{REC_TYP}, $unk->{header}->{REC_TYP} );
    $err .= sprintf ("\tSUB: 0x%X [%i]\n", $unk->{header}->{REC_SUB}, $unk->{header}->{REC_SUB} );
	die "\nERROR: unrecognized rec: \n$err\n";
  }

  printf ("Record %s ( %d, %d ) %d bytes:\n", $s->recname(), $unk->{header}->{REC_TYP}, $unk->{header}->{REC_SUB}, $unk->{header}->{REC_LEN} );

  if ( $s->recname() eq "FAR" )
  { 
	my $far = $s->far();
	printf ("\tCPU_TYPE: %s\n", $far->{CPU_TYPE});
	printf ("\tSTDF_VER: %s\n", $far->{STDF_VER});
  }

  if ( $s->recname() eq "MIR" ) 
  {
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
  }

  if ( $s->recname() eq "SDR" )	
  {
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
  }

  if ( $s->recname() eq "PCR" )
  {
	my $pcr = $s->pcr();
	printf("\tHEAD_NUM: %s\n", $pcr->{HEAD_NUM});
	printf("\tSITE_NUM: %s\n", $pcr->{SITE_NUM});
	printf("\tPART_CNT: %s\n", $pcr->{PART_CNT});
	printf("\tRTST_CNT: %s\n", $pcr->{RTST_CNT});
	printf("\tABRT_CNT: %s\n", $pcr->{ABRT_CNT});
	printf("\tGOOD_CNT: %s\n", $pcr->{GOOD_CNT});
	printf("\tFUNC_CNT: %s\n", $pcr->{FUNC_CNT});
  }

  if ( $s->recname() eq "MRR" )
  {
	my $mrr = $s->mrr();
    printf("\tFINISH_T: %s\n", ctime($mrr->{FINISH_T}));
	printf("\tDISP_COD: %s\n", $mrr->{DISP_COD});
	printf("\tUSR_DESC: %s\n", $mrr->{USR_DESC});
	printf("\tEXC_DESC: %s\n", $mrr->{EXC_DESC});
  }

  if ( $s->recname() eq "WIR" )
  {
	my $wir = $s->wir();
	printf("\tHEAD_NUM: %s\n", $wir->{HEAD_NUM});
	printf("\tSITE_GRP: %s\n", $wir->{SITE_GRP});
	printf("\tSTART_T: %s\n", ctime($wir->{START_T}));
	printf("\tWAFER_ID: %s\n", $wir->{WAFER_ID});
  }

  if ( $s->recname() eq "PIR" )
  {
	my $pir = $s->pir();
	printf("\tHEAD_NUM: %s\n", $pir->{HEAD_NUM});
	printf("\tSITE_NUM: %s\n", $pir->{SITE_NUM});
  }

  if ( $s->recname() eq "PRR" )
  {
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
  }

  if ( $s->recname() eq "PTR" )
  {
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
  }

  if ( $s->recname() eq "DTR" )
  {
	my $dtr = $s->dtr();
	printf("\tTEXT_DAT: %s\n", $dtr->{TEXT_DAT});
  }

  if ( $s->recname() eq "ATR" )
  {
	my $atr = $s->atr();
	printf ("\tMID_TIM: %s\n", ctime($atr->{MOD_TIM}) );
	printf ("\tCMD_LINE: %s\n", $atr->{CMD_LINE} );
  }

  if ( $s->recname() eq "HBR" )
  {
	my $hbr = $s->hbr();
    printf("\tHEAD_NUM: %s\n", $hbr->{HEAD_NUM});
    printf("\tSITE_NUM: %s\n", $hbr->{SITE_NUM});
    printf("\tHBIN_NUM: %s\n", $hbr->{HBIN_NUM});
    printf("\tHBIN_CNT: %s\n", $hbr->{HBIN_CNT});
    printf("\tHBIN_PF: %s\n", $hbr->{HBIN_PF});
    printf("\tHBIN_NAM: %s\n", $hbr->{HBIN_NAM});
  }

  if ( $s->recname() eq "SBR" )
  {
	my $sbr = $s->sbr();
    printf("\tHEAD_NUM: %s\n", $sbr->{HEAD_NUM});
    printf("\tSITE_NUM: %s\n", $sbr->{SITE_NUM});
    printf("\tSBIN_NUM: %s\n", $sbr->{SBIN_NUM});
    printf("\tSBIN_CNT: %s\n", $sbr->{SBIN_CNT});
    printf("\tSBIN_PF: %s\n", $sbr->{SBIN_PF});
    printf("\tSBIN_NAM: %s\n", $sbr->{SBIN_NAM});
  }

  if ( $s->recname() eq "PMR" )
  {
	my $pmr = $s->pmr();
    printf("\tPMR_INDX: %s\n", $pmr->{PMR_INDX});
    printf("\tCHAN_TYP: %s\n", $pmr->{CHAN_TYP});
    printf("\tCHAN_NAM: %s\n", $pmr->{CHAN_NAM});
    printf("\tPHY_NAM: %s\n", $pmr->{PHY_NAM});
    printf("\tLOG_NAM: %s\n", $pmr->{LOG_NAM});
    printf("\tHEAD_NUM: %s\n", $pmr->{HEAD_NUM});
    printf("\tSITE_NUM: %s\n", $pmr->{SITE_NUM});
  }

  if ( $s->recname() eq "PGR" )
  {
	my $pgr = $s->pgr();
    printf("\tGRP_INDX: %s\n", $pgr->{GRP_INDX});
    printf("\tGRP_NAM: %s\n", $pgr->{GRP_NAM});
    printf("\tINDX_CNT: %s\n", $pgr->{INDX_CNT});
    print "\tPMR_INDX: ", join(", ",@{xU2_array_ref($pgr->{PMR_INDX}, $pgr->{INDX_CNT})}), "\n";
  }

  if ( $s->recname() eq "PLR" )
  {
	my $plr = $s->plr();
    printf("\tGRP_CNT: %s\n", $plr->{GRP_CNT});
    print "\tGRP_INDX: ", join(", ",@{xU2_array_ref($plr->{GRP_INDX}, $plr->{GRP_CNT})}), "\n";
    print "\tGRP_MODE: ", join(", ",@{xU2_array_ref($plr->{GRP_MODE}, $plr->{GRP_CNT})}), "\n";
    print "\tGRP_RADX: ", join(", ",@{xU1_array_ref($plr->{GRP_RADX}, $plr->{GRP_CNT})}), "\n";
    print "\tPGM_CHAR: ", join(", ",@{xCn_array_ref($plr->{PGM_CHAR}, $plr->{GRP_CNT})}), "\n";
    print "\tRTN_CHAR: ", join(", ",@{xCn_array_ref($plr->{RTN_CHAR}, $plr->{GRP_CNT})}), "\n";
    print "\tPGM_CHAL: ", join(", ",@{xCn_array_ref($plr->{PGM_CHAL}, $plr->{GRP_CNT})}), "\n";
    print "\tRTN_CHAL: ", join(", ",@{xCn_array_ref($plr->{RTN_CHAL}, $plr->{GRP_CNT})}), "\n";
  }

  if ( $s->recname() eq "RDR" )
  {
	my $rdr = $s->rdr();
    printf("\tNUM_BINS: %s\n", $rdr->{NUM_BINS});
    print "\tRTST_BIN: ", join(", ",@{xU2_array_ref($rdr->{RTST_BIN}, $rdr->{NUM_BINS})}), "\n";
  }

  if ( $s->recname() eq  "WRR" )
  {
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
  }

  if ( $s->recname() eq "WCR" )
  {
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
  }

  if ( $s->recname() eq "TSR" )
  {
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
  }

  if ( $s->recname() eq "MPR" )
  {
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
  }

  if ( $s->recname() eq "FTR" )
  {
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
  }

  if ( $s->recname() eq "BPS" )
  {
	my $bps = $s->bps();
	printf("\tSEQ_NAME: %s\n", $bps->{SEQ_NAME});
  }

  if ( $s->recname() eq "EPS" )
  {
	my $eps = $s->eps();
	# TODO
  }

  if ( $s->recname() eq "GDR" )
  {
	my $gdr = $s->gdr();
    printf("\tFLD_CNT: %s\n", $gdr->{FLD_CNT});
	print "\tGEN_DATA: ", join(", ",@{xVn_array_ref($gdr->{GEN_DATA}, $gdr->{FLD_CNT})}), "\n";
  }

}

exit;
