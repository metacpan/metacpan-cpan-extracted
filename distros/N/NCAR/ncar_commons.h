#ifndef NCAR_COMMONS_H
#define NCAR_COMMONS_H
typedef enum {
  COMMON_NAME_ELLPDP,
  COMMON_NAME_STR01,
  COMMON_NAME_STR02,
  COMMON_NAME_CFFLAG,
  COMMON_NAME_STR03,
  COMMON_NAME_PWRC0,
  COMMON_NAME_SLCLRS,
  COMMON_NAME_STR04,
  COMMON_NAME_PWRC1,
  COMMON_NAME_HAFTO1,
  COMMON_NAME_PWRC2,
  COMMON_NAME_HAFTO2,
  COMMON_NAME_HAFTO3,
  COMMON_NAME_HAFTO4,
  COMMON_NAME_MAPSAT,
  COMMON_NAME_CPCOM1,
  COMMON_NAME_CPCOM2,
  COMMON_NAME_STPLCH,
  COMMON_NAME_DCFLAG,
  COMMON_NAME_PC17SP,
  COMMON_NAME_AGCONP,
  COMMON_NAME_PC17DP,
  COMMON_NAME_PC09SP,
  COMMON_NAME_TDCOM1,
  COMMON_NAME_PC09DP,
  COMMON_NAME_TDCOM2,
  COMMON_NAME_TDCOM3,
  COMMON_NAME_PRM31,
  COMMON_NAME_TDCOM4,
  COMMON_NAME_TDCOM5,
  COMMON_NAME_TDCOM6,
  COMMON_NAME_PC20SP,
  COMMON_NAME_PC20DP,
  COMMON_NAME_PC12SP,
  COMMON_NAME_PC12DP,
  COMMON_NAME_PC04SP,
  COMMON_NAME_IDPT,
  COMMON_NAME_RAQINT,
  COMMON_NAME_PC04DP,
  COMMON_NAME_PCSTCM,
  COMMON_NAME_STTXP,
  COMMON_NAME_PRINZ0,
  COMMON_NAME_STTRAN,
  COMMON_NAME_SRFBLK,
  COMMON_NAME_TEMPRT,
  COMMON_NAME_SRFINT,
  COMMON_NAME_STPLDP,
  COMMON_NAME_TEMPRX,
  COMMON_NAME_PCSVEM,
  COMMON_NAME_MAPWNC,
  COMMON_NAME_SMFLAG,
  COMMON_NAME_VCTSEQ,
  COMMON_NAME_PUSER,
  COMMON_NAME_DASHD1,
  COMMON_NAME_DASHD2,
  COMMON_NAME_MAPCM0,
  COMMON_NAME_PC23SP,
  COMMON_NAME_NORMSP,
  COMMON_NAME_CONRE1,
  COMMON_NAME_MAPCM1,
  COMMON_NAME_CONRE2,
  COMMON_NAME_PC23DP,
  COMMON_NAME_NORMDP,
  COMMON_NAME_PC15SP,
  COMMON_NAME_CONRE3,
  COMMON_NAME_MAPCM2,
  COMMON_NAME_CONRE4,
  COMMON_NAME_MAPCM3,
  COMMON_NAME_PC15DP,
  COMMON_NAME_PC07SP,
  COMMON_NAME_USGSC1,
  COMMON_NAME_GFLASH,
  COMMON_NAME_CONRE5,
  COMMON_NAME_MAPCM4,
  COMMON_NAME_MAPCM5,
  COMMON_NAME_PC07DP,
  COMMON_NAME_IDCOMN,
  COMMON_NAME_MAPCM6,
  COMMON_NAME_MAPCM7,
  COMMON_NAME_MAPCM8,
  COMMON_NAME_STCHAR,
  COMMON_NAME_SPHRSP,
  COMMON_NAME_SRFIP1,
  COMMON_NAME_DDFLAG,
  COMMON_NAME_SPHRDP,
  COMMON_NAME_UNITS,
  COMMON_NAME_MAPCMA,
  COMMON_NAME_ISCOMN,
  COMMON_NAME_PC10SP,
  COMMON_NAME_MAPCMC,
  COMMON_NAME_PC10DP,
  COMMON_NAME_MAPRGD,
  COMMON_NAME_VVARO,
  COMMON_NAME_PCFNNM,
  COMMON_NAME_PCFNNO,
  COMMON_NAME_MAPCMP,
  COMMON_NAME_PCMP04,
  COMMON_NAME_MAPCMQ,
  COMMON_NAME_GACHAR,
  COMMON_NAME_STMAP,
  COMMON_NAME_IUTLCM,
  COMMON_NAME_PLTCM,
  COMMON_NAME_MAPCMX,
  COMMON_NAME_MAPCMY,
  COMMON_NAME_PC18SP,
  COMMON_NAME_DSTDDT,
  COMMON_NAME_SLCOMN,
  COMMON_NAME_MAPCMZ,
  COMMON_NAME_STSTRM,
  COMMON_NAME_PC18DP,
  COMMON_NAME_PCPRMS,
  COMMON_NAME_LBCOMN,
  COMMON_NAME_RECINT,
  COMMON_NAME_PC21SP,
  COMMON_NAME_SECOMC,
  COMMON_NAME_PC13SP,
  COMMON_NAME_PC21DP,
  COMMON_NAME_VVTXP,
  COMMON_NAME_PC05SP,
  COMMON_NAME_PC13DP,
  COMMON_NAME_PC05DP,
  COMMON_NAME_IDLC,
  COMMON_NAME_SECOMI,
  COMMON_NAME_VVCHAR,
  COMMON_NAME_HOLTAB,
  COMMON_NAME_STPAR,
  COMMON_NAME_THRINT,
  COMMON_NAME_VEC1,
  COMMON_NAME_VEC2,
  COMMON_NAME_CONR10,
  COMMON_NAME_WMSLOC,
  COMMON_NAME_CONR12,
  COMMON_NAME_CONR13,
  COMMON_NAME_GKERR1,
  COMMON_NAME_CONR14,
  COMMON_NAME_GKERR2,
  COMMON_NAME_CONR15,
  COMMON_NAME_CONR16,
  COMMON_NAME_CONR17,
  COMMON_NAME_SET31,
  COMMON_NAME_PINIT,
  COMMON_NAME_CONR18,
  COMMON_NAME_CONR19,
  COMMON_NAME_RASINT,
  COMMON_NAME_PC16SP,
  COMMON_NAME_PCPFLQ,
  COMMON_NAME_PC08SP,
  COMMON_NAME_PC16DP,
  COMMON_NAME_PC08DP,
  COMMON_NAME_PWRZ1I,
  COMMON_NAME_VVCOM,
  COMMON_NAME_CAPFNT,
  COMMON_NAME_PC11SP,
  COMMON_NAME_PC03SP,
  COMMON_NAME_PC11DP,
  COMMON_NAME_AGORIP,
  COMMON_NAME_CONRA1,
  COMMON_NAME_CONR20,
  COMMON_NAME_VVMAP,
  COMMON_NAME_AGORIQ,
  COMMON_NAME_CONRA2,
  COMMON_NAME_PWRZ1S,
  COMMON_NAME_PC03DP,
  COMMON_NAME_CONRA3,
  COMMON_NAME_PWRZ1T,
  COMMON_NAME_AGCHR1,
  COMMON_NAME_CONRA4,
  COMMON_NAME_AGCHR2,
  COMMON_NAME_CONRA5,
  COMMON_NAME_CONRA6,
  COMMON_NAME_ARCOM1,
  COMMON_NAME_WMLGCM,
  COMMON_NAME_CONRA9,
  COMMON_NAME_GAREIN,
  COMMON_NAME_ERRMZ0,
  COMMON_NAME_AGOCHP,
  COMMON_NAME_CPWCMN,
  COMMON_NAME_PWRCOM,
  COMMON_NAME_INTPR,
  COMMON_NAME_PWRSV1,
  COMMON_NAME_SFCOMN,
  COMMON_NAME_PC19SP,
  COMMON_NAME_RANINT,
  COMMON_NAME_PC19DP,
  COMMON_NAME_PWRZ2I,
  COMMON_NAME_DSAVE1,
  COMMON_NAME_PINIT1,
  COMMON_NAME_DSAVE3,
  COMMON_NAME_PSAV1,
  COMMON_NAME_PSAV3,
  COMMON_NAME_DSAVE6,
  COMMON_NAME_STPLIR,
  COMMON_NAME_PWRZ2S,
  COMMON_NAME_ARCOMN,
  COMMON_NAME_PC22SP,
  COMMON_NAME_PWRZ2T,
  COMMON_NAME_PC14SP,
  COMMON_NAME_PC22DP,
  COMMON_NAME_TCK31,
  COMMON_NAME_PC06SP,
  COMMON_NAME_PC14DP,
  COMMON_NAME_DPCMRI,
  COMMON_NAME_PC06DP,
  COMMON_NAME_DPCMCH,
  COMMON_NAME_HSTGC1,
  COMMON_NAME_HSTGC2,
  COMMON_NAME_ELLPSP,
  COMMON_TOTAL_COUNT
} COMMON_NAME;

extern char ellpdp_;
extern char str01_;
extern char str02_;
extern char cfflag_;
extern char str03_;
extern char pwrc0_;
extern char slclrs_;
extern char str04_;
extern char pwrc1_;
extern char hafto1_;
extern char pwrc2_;
extern char hafto2_;
extern char hafto3_;
extern char hafto4_;
extern char mapsat_;
extern char cpcom1_;
extern char cpcom2_;
extern char stplch_;
extern char dcflag_;
extern char pc17sp_;
extern char agconp_;
extern char pc17dp_;
extern char pc09sp_;
extern char tdcom1_;
extern char pc09dp_;
extern char tdcom2_;
extern char tdcom3_;
extern char prm31_;
extern char tdcom4_;
extern char tdcom5_;
extern char tdcom6_;
extern char pc20sp_;
extern char pc20dp_;
extern char pc12sp_;
extern char pc12dp_;
extern char pc04sp_;
extern char idpt_;
extern char raqint_;
extern char pc04dp_;
extern char pcstcm_;
extern char sttxp_;
extern char prinz0_;
extern char sttran_;
extern char srfblk_;
extern char temprt_;
extern char srfint_;
extern char stpldp_;
extern char temprx_;
extern char pcsvem_;
extern char mapwnc_;
extern char smflag_;
extern char vctseq_;
extern char puser_;
extern char dashd1_;
extern char dashd2_;
extern char mapcm0_;
extern char pc23sp_;
extern char normsp_;
extern char conre1_;
extern char mapcm1_;
extern char conre2_;
extern char pc23dp_;
extern char normdp_;
extern char pc15sp_;
extern char conre3_;
extern char mapcm2_;
extern char conre4_;
extern char mapcm3_;
extern char pc15dp_;
extern char pc07sp_;
extern char usgsc1_;
extern char gflash_;
extern char conre5_;
extern char mapcm4_;
extern char mapcm5_;
extern char pc07dp_;
extern char idcomn_;
extern char mapcm6_;
extern char mapcm7_;
extern char mapcm8_;
extern char stchar_;
extern char sphrsp_;
extern char srfip1_;
extern char ddflag_;
extern char sphrdp_;
extern char units_;
extern char mapcma_;
extern char iscomn_;
extern char pc10sp_;
extern char mapcmc_;
extern char pc10dp_;
extern char maprgd_;
extern char vvaro_;
extern char pcfnnm_;
extern char pcfnno_;
extern char mapcmp_;
extern char pcmp04_;
extern char mapcmq_;
extern char gachar_;
extern char stmap_;
extern char iutlcm_;
extern char pltcm_;
extern char mapcmx_;
extern char mapcmy_;
extern char pc18sp_;
extern char dstddt_;
extern char slcomn_;
extern char mapcmz_;
extern char ststrm_;
extern char pc18dp_;
extern char pcprms_;
extern char lbcomn_;
extern char recint_;
extern char pc21sp_;
extern char secomc_;
extern char pc13sp_;
extern char pc21dp_;
extern char vvtxp_;
extern char pc05sp_;
extern char pc13dp_;
extern char pc05dp_;
extern char idlc_;
extern char secomi_;
extern char vvchar_;
extern char holtab_;
extern char stpar_;
extern char thrint_;
extern char vec1_;
extern char vec2_;
extern char conr10_;
extern char wmsloc_;
extern char conr12_;
extern char conr13_;
extern char gkerr1_;
extern char conr14_;
extern char gkerr2_;
extern char conr15_;
extern char conr16_;
extern char conr17_;
extern char set31_;
extern char pinit_;
extern char conr18_;
extern char conr19_;
extern char rasint_;
extern char pc16sp_;
extern char pcpflq_;
extern char pc08sp_;
extern char pc16dp_;
extern char pc08dp_;
extern char pwrz1i_;
extern char vvcom_;
extern char capfnt_;
extern char pc11sp_;
extern char pc03sp_;
extern char pc11dp_;
extern char agorip_;
extern char conra1_;
extern char conr20_;
extern char vvmap_;
extern char agoriq_;
extern char conra2_;
extern char pwrz1s_;
extern char pc03dp_;
extern char conra3_;
extern char pwrz1t_;
extern char agchr1_;
extern char conra4_;
extern char agchr2_;
extern char conra5_;
extern char conra6_;
extern char arcom1_;
extern char wmlgcm_;
extern char conra9_;
extern char garein_;
extern char errmz0_;
extern char agochp_;
extern char cpwcmn_;
extern char pwrcom_;
extern char intpr_;
extern char pwrsv1_;
extern char sfcomn_;
extern char pc19sp_;
extern char ranint_;
extern char pc19dp_;
extern char pwrz2i_;
extern char dsave1_;
extern char pinit1_;
extern char dsave3_;
extern char psav1_;
extern char psav3_;
extern char dsave6_;
extern char stplir_;
extern char pwrz2s_;
extern char arcomn_;
extern char pc22sp_;
extern char pwrz2t_;
extern char pc14sp_;
extern char pc22dp_;
extern char tck31_;
extern char pc06sp_;
extern char pc14dp_;
extern char dpcmri_;
extern char pc06dp_;
extern char dpcmch_;
extern char hstgc1_;
extern char hstgc2_;
extern char ellpsp_;

char* ncar_commons[] = {
  &ellpdp_,
  &str01_,
  &str02_,
  &cfflag_,
  &str03_,
  &pwrc0_,
  &slclrs_,
  &str04_,
  &pwrc1_,
  &hafto1_,
  &pwrc2_,
  &hafto2_,
  &hafto3_,
  &hafto4_,
  &mapsat_,
  &cpcom1_,
  &cpcom2_,
  &stplch_,
  &dcflag_,
  &pc17sp_,
  &agconp_,
  &pc17dp_,
  &pc09sp_,
  &tdcom1_,
  &pc09dp_,
  &tdcom2_,
  &tdcom3_,
  &prm31_,
  &tdcom4_,
  &tdcom5_,
  &tdcom6_,
  &pc20sp_,
  &pc20dp_,
  &pc12sp_,
  &pc12dp_,
  &pc04sp_,
  &idpt_,
  &raqint_,
  &pc04dp_,
  &pcstcm_,
  &sttxp_,
  &prinz0_,
  &sttran_,
  &srfblk_,
  &temprt_,
  &srfint_,
  &stpldp_,
  &temprx_,
  &pcsvem_,
  &mapwnc_,
  &smflag_,
  &vctseq_,
  &puser_,
  &dashd1_,
  &dashd2_,
  &mapcm0_,
  &pc23sp_,
  &normsp_,
  &conre1_,
  &mapcm1_,
  &conre2_,
  &pc23dp_,
  &normdp_,
  &pc15sp_,
  &conre3_,
  &mapcm2_,
  &conre4_,
  &mapcm3_,
  &pc15dp_,
  &pc07sp_,
  &usgsc1_,
  &gflash_,
  &conre5_,
  &mapcm4_,
  &mapcm5_,
  &pc07dp_,
  &idcomn_,
  &mapcm6_,
  &mapcm7_,
  &mapcm8_,
  &stchar_,
  &sphrsp_,
  &srfip1_,
  &ddflag_,
  &sphrdp_,
  &units_,
  &mapcma_,
  &iscomn_,
  &pc10sp_,
  &mapcmc_,
  &pc10dp_,
  &maprgd_,
  &vvaro_,
  &pcfnnm_,
  &pcfnno_,
  &mapcmp_,
  &pcmp04_,
  &mapcmq_,
  &gachar_,
  &stmap_,
  &iutlcm_,
  &pltcm_,
  &mapcmx_,
  &mapcmy_,
  &pc18sp_,
  &dstddt_,
  &slcomn_,
  &mapcmz_,
  &ststrm_,
  &pc18dp_,
  &pcprms_,
  &lbcomn_,
  &recint_,
  &pc21sp_,
  &secomc_,
  &pc13sp_,
  &pc21dp_,
  &vvtxp_,
  &pc05sp_,
  &pc13dp_,
  &pc05dp_,
  &idlc_,
  &secomi_,
  &vvchar_,
  &holtab_,
  &stpar_,
  &thrint_,
  &vec1_,
  &vec2_,
  &conr10_,
  &wmsloc_,
  &conr12_,
  &conr13_,
  &gkerr1_,
  &conr14_,
  &gkerr2_,
  &conr15_,
  &conr16_,
  &conr17_,
  &set31_,
  &pinit_,
  &conr18_,
  &conr19_,
  &rasint_,
  &pc16sp_,
  &pcpflq_,
  &pc08sp_,
  &pc16dp_,
  &pc08dp_,
  &pwrz1i_,
  &vvcom_,
  &capfnt_,
  &pc11sp_,
  &pc03sp_,
  &pc11dp_,
  &agorip_,
  &conra1_,
  &conr20_,
  &vvmap_,
  &agoriq_,
  &conra2_,
  &pwrz1s_,
  &pc03dp_,
  &conra3_,
  &pwrz1t_,
  &agchr1_,
  &conra4_,
  &agchr2_,
  &conra5_,
  &conra6_,
  &arcom1_,
  &wmlgcm_,
  &conra9_,
  &garein_,
  &errmz0_,
  &agochp_,
  &cpwcmn_,
  &pwrcom_,
  &intpr_,
  &pwrsv1_,
  &sfcomn_,
  &pc19sp_,
  &ranint_,
  &pc19dp_,
  &pwrz2i_,
  &dsave1_,
  &pinit1_,
  &dsave3_,
  &psav1_,
  &psav3_,
  &dsave6_,
  &stplir_,
  &pwrz2s_,
  &arcomn_,
  &pc22sp_,
  &pwrz2t_,
  &pc14sp_,
  &pc22dp_,
  &tck31_,
  &pc06sp_,
  &pc14dp_,
  &dpcmri_,
  &pc06dp_,
  &dpcmch_,
  &hstgc1_,
  &hstgc2_,
  &ellpsp_,
};

#endif
