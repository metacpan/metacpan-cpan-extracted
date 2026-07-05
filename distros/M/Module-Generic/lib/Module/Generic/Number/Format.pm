##----------------------------------------------------------------------------
## Module Generic - ~/lib/Module/Generic/Number/Format.pm
## Version v0.1.1
## Copyright(c) 2026 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2026/07/01
## Modified 2026/07/05
## All rights reserved
## 
## This program is free software; you can redistribute  it  and/or  modify  it
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
package Module::Generic::Number::Format;
BEGIN
{
    use v5.16.0;
    use strict;
    use warnings;
    warnings::register_categories( 'Module::Generic' );
    use parent qw( Module::Generic );
    use vars qw( $SUPPORTED_LOCALES $DEFAULT $NUMBER_RE $LOCALE_LOCK );
    use Config;
    require POSIX;
    if( $] >= 5.022 )
    {
        POSIX->import( qw( isinf isnan ) );
    }
    else
    {
        my $POS_INF = 9**9**9;
        my $NEG_INF = -$POS_INF;
        *isinf = sub
        {
            return(0) if( !defined( $_[0] ) );
            no warnings 'numeric';
            return( $_[0] == $POS_INF || $_[0] == $NEG_INF );
        };
        *isnan = sub
        {
            return(0) if( !defined( $_[0] ) );
            no warnings 'numeric';
            return( $_[0] != $_[0] );
        };
    }
    # 2026-05-17: Regexp::Common does not install under perl v5.10.1 because of an error in its test t/test_comments.t
    # use Regexp::Common qw( number );
    # $NUMBER_RE = $RE{num}{real};
    $NUMBER_RE = qr/(?:(?i)(?:[-+]?)(?:(?=[.]?[0123456789])(?:[0123456789]*)(?:(?:[.])(?:[0123456789]{0,}))?)(?:(?:[E])(?:(?:[-+]?)(?:[0123456789]+))|))/;
    use Scalar::Util ();
    # Largest integer a 32-bit Perl can handle is based on the mantissa
    # size of a double float, which is up to 53 bits.  While we may be
    # able to support larger values on 64-bit systems, some Perl integer
    # operations on 64-bit integer systems still use the 53-bit-mantissa
    # double floats.  To be safe, we cap at 2**53; use Math::BigFloat
    # instead for larger numbers.
    use constant MAX_INT => 2**53;
    use constant HAS_THREADS => $Config{useithreads};
    if( HAS_THREADS )
    {
        require threads;
        require threads::shared;
        threads->import();
        threads::shared->import();
        our $LOCALE_LOCK :shared;
    }
    our( $VERSION ) = 'v0.1.1';
};

# use strict;
no warnings 'redefine';
use utf8;

# NOTE: $SUPPORTED_LOCALES
$SUPPORTED_LOCALES =
{
    aa_DJ   => [qw( aa_DJ.UTF-8 aa_DJ.ISO-8859-1 aa_DJ.ISO8859-1 )],
    aa_ER   => [qw( aa_ER.UTF-8 )],
    aa_ET   => [qw( aa_ET.UTF-8 )],
    af_ZA   => [qw( af_ZA.UTF-8 af_ZA.ISO-8859-1 af_ZA.ISO8859-1 )],
    ak_GH   => [qw( ak_GH.UTF-8 )],
    am_ET   => [qw( am_ET.UTF-8 )],
    an_ES   => [qw( an_ES.UTF-8 an_ES.ISO-8859-15 an_ES.ISO8859-15 )],
    anp_IN  => [qw( anp_IN.UTF-8 )],
    ar_AE   => [qw( ar_AE.UTF-8 ar_AE.ISO-8859-6 ar_AE.ISO8859-6 )],
    ar_BH   => [qw( ar_BH.UTF-8 ar_BH.ISO-8859-6 ar_BH.ISO8859-6 )],
    ar_DZ   => [qw( ar_DZ.UTF-8 ar_DZ.ISO-8859-6 ar_DZ.ISO8859-6 )],
    ar_EG   => [qw( ar_EG.UTF-8 ar_EG.ISO-8859-6 ar_EG.ISO8859-6 )],
    ar_IN   => [qw( ar_IN.UTF-8 )],
    ar_IQ   => [qw( ar_IQ.UTF-8 ar_IQ.ISO-8859-6 ar_IQ.ISO8859-6 )],
    ar_JO   => [qw( ar_JO.UTF-8 ar_JO.ISO-8859-6 ar_JO.ISO8859-6 )],
    ar_KW   => [qw( ar_KW.UTF-8 ar_KW.ISO-8859-6 ar_KW.ISO8859-6 )],
    ar_LB   => [qw( ar_LB.UTF-8 ar_LB.ISO-8859-6 ar_LB.ISO8859-6 )],
    ar_LY   => [qw( ar_LY.UTF-8 ar_LY.ISO-8859-6 ar_LY.ISO8859-6 )],
    ar_MA   => [qw( ar_MA.UTF-8 ar_MA.ISO-8859-6 ar_MA.ISO8859-6 )],
    ar_OM   => [qw( ar_OM.UTF-8 ar_OM.ISO-8859-6 ar_OM.ISO8859-6 )],
    ar_QA   => [qw( ar_QA.UTF-8 ar_QA.ISO-8859-6 ar_QA.ISO8859-6 )],
    ar_SA   => [qw( ar_SA.UTF-8 ar_SA.ISO-8859-6 ar_SA.ISO8859-6 )],
    ar_SD   => [qw( ar_SD.UTF-8 ar_SD.ISO-8859-6 ar_SD.ISO8859-6 )],
    ar_SS   => [qw( ar_SS.UTF-8 )],
    ar_SY   => [qw( ar_SY.UTF-8 ar_SY.ISO-8859-6 ar_SY.ISO8859-6 )],
    ar_TN   => [qw( ar_TN.UTF-8 ar_TN.ISO-8859-6 ar_TN.ISO8859-6 )],
    ar_YE   => [qw( ar_YE.UTF-8 ar_YE.ISO-8859-6 ar_YE.ISO8859-6 )],
    as_IN   => [qw( as_IN.UTF-8 )],
    ast_ES  => [qw( ast_ES.UTF-8 ast_ES.ISO-8859-15 ast_ES.ISO8859-15 )],
    ayc_PE  => [qw( ayc_PE.UTF-8 )],
    az_AZ   => [qw( az_AZ.UTF-8 )],
    be_BY   => [qw( be_BY.UTF-8 be_BY.CP1251 )],
    bem_ZM  => [qw( bem_ZM.UTF-8 )],
    ber_DZ  => [qw( ber_DZ.UTF-8 )],
    ber_MA  => [qw( ber_MA.UTF-8 )],
    bg_BG   => [qw( bg_BG.UTF-8 bg_BG.CP1251 )],
    bhb_IN  => [qw( bhb_IN.UTF-8 )],
    bho_IN  => [qw( bho_IN.UTF-8 )],
    bn_BD   => [qw( bn_BD.UTF-8 )],
    bn_IN   => [qw( bn_IN.UTF-8 )],
    bo_CN   => [qw( bo_CN.UTF-8 )],
    bo_IN   => [qw( bo_IN.UTF-8 )],
    br_FR   => [qw( br_FR.UTF-8 br_FR.ISO-8859-1 br_FR.ISO8859-1 br_FR.ISO-8859-15 br_FR.ISO8859-15 )],
    brx_IN  => [qw( brx_IN.UTF-8 )],
    bs_BA   => [qw( bs_BA.UTF-8 bs_BA.ISO-8859-2 bs_BA.ISO8859-2 )],
    byn_ER  => [qw( byn_ER.UTF-8 )],
    ca_AD   => [qw( ca_AD.UTF-8 ca_AD.ISO-8859-15 ca_AD.ISO8859-15 )],
    ca_ES   => [qw( ca_ES.UTF-8 ca_ES.ISO-8859-1 ca_ES.ISO8859-1 ca_ES.ISO-8859-15 ca_ES.ISO8859-15 )],
    ca_FR   => [qw( ca_FR.UTF-8 ca_FR.ISO-8859-15 ca_FR.ISO8859-15 )],
    ca_IT   => [qw( ca_IT.UTF-8 ca_IT.ISO-8859-15 ca_IT.ISO8859-15 )],
    ce_RU   => [qw( ce_RU.UTF-8 )],
    ckb_IQ  => [qw( ckb_IQ.UTF-8 )],
    cmn_TW  => [qw( cmn_TW.UTF-8 )],
    crh_UA  => [qw( crh_UA.UTF-8 )],
    cs_CZ   => [qw( cs_CZ.UTF-8 cs_CZ.ISO-8859-2 cs_CZ.ISO8859-2 )],
    csb_PL  => [qw( csb_PL.UTF-8 )],
    cv_RU   => [qw( cv_RU.UTF-8 )],
    cy_GB   => [qw( cy_GB.UTF-8 cy_GB.ISO-8859-14 cy_GB.ISO8859-14 )],
    da_DK   => [qw( da_DK.UTF-8 da_DK.ISO-8859-1 da_DK.ISO8859-1 )],
    de_AT   => [qw( de_AT.UTF-8 de_AT.ISO-8859-1 de_AT.ISO8859-1 de_AT.ISO-8859-15 de_AT.ISO8859-15 )],
    de_BE   => [qw( de_BE.UTF-8 de_BE.ISO-8859-1 de_BE.ISO8859-1 de_BE.ISO-8859-15 de_BE.ISO8859-15 )],
    de_CH   => [qw( de_CH.UTF-8 de_CH.ISO-8859-1 de_CH.ISO8859-1 )],
    de_DE   => [qw( de_DE.UTF-8 de_DE.ISO-8859-1 de_DE.ISO8859-1 de_DE.ISO-8859-15 de_DE.ISO8859-15 )],
    de_LI   => [qw( de_LI.UTF-8 )],
    de_LU   => [qw( de_LU.UTF-8 de_LU.ISO-8859-1 de_LU.ISO8859-1 de_LU.ISO-8859-15 de_LU.ISO8859-15 )],
    doi_IN  => [qw( doi_IN.UTF-8 )],
    dv_MV   => [qw( dv_MV.UTF-8 )],
    dz_BT   => [qw( dz_BT.UTF-8 )],
    el_CY   => [qw( el_CY.UTF-8 el_CY.ISO-8859-7 el_CY.ISO8859-7 )],
    el_GR   => [qw( el_GR.UTF-8 el_GR.ISO-8859-7 el_GR.ISO8859-7 )],
    en_AG   => [qw( en_AG.UTF-8 )],
    en_AU   => [qw( en_AU.UTF-8 en_AU.ISO-8859-1 en_AU.ISO8859-1 )],
    en_BW   => [qw( en_BW.UTF-8 en_BW.ISO-8859-1 en_BW.ISO8859-1 )],
    en_CA   => [qw( en_CA.UTF-8 en_CA.ISO-8859-1 en_CA.ISO8859-1 )],
    en_DK   => [qw( en_DK.UTF-8 en_DK.ISO-8859-15 en_DK.ISO8859-15 )],
    en_GB   => [qw( en_GB.UTF-8 en_GB.ISO-8859-1 en_GB.ISO8859-1 en_GB.ISO-8859-15 en_GB.ISO8859-15 )],
    en_HK   => [qw( en_HK.UTF-8 en_HK.ISO-8859-1 en_HK.ISO8859-1 )],
    en_IE   => [qw( en_IE.UTF-8 en_IE.ISO-8859-1 en_IE.ISO8859-1 en_IE.ISO-8859-15 en_IE.ISO8859-15 )],
    en_IN   => [qw( en_IN.UTF-8 )],
    en_NG   => [qw( en_NG.UTF-8 )],
    en_NZ   => [qw( en_NZ.UTF-8 en_NZ.ISO-8859-1 en_NZ.ISO8859-1 )],
    en_PH   => [qw( en_PH.UTF-8 en_PH.ISO-8859-1 en_PH.ISO8859-1 )],
    en_SG   => [qw( en_SG.UTF-8 en_SG.ISO-8859-1 en_SG.ISO8859-1 )],
    en_US   => [qw( en_US.UTF-8 en_US.ISO-8859-1 en_US.ISO8859-1 en_US.ISO-8859-15 en_US.ISO8859-15 )],
    en_ZA   => [qw( en_ZA.UTF-8 en_ZA.ISO-8859-1 en_ZA.ISO8859-1 )],
    en_ZM   => [qw( en_ZM.UTF-8 )],
    en_ZW   => [qw( en_ZW.UTF-8 en_ZW.ISO-8859-1 en_ZW.ISO8859-1 )],
    eo      => [qw( eo.UTF-8 eo.ISO-8859-3 eo.ISO8859-3 )],
    eo_US   => [qw( eo_US.UTF-8 )],
    es_AR   => [qw( es_AR.UTF-8 es_AR.ISO-8859-1 es_AR.ISO8859-1 )],
    es_BO   => [qw( es_BO.UTF-8 es_BO.ISO-8859-1 es_BO.ISO8859-1 )],
    es_CL   => [qw( es_CL.UTF-8 es_CL.ISO-8859-1 es_CL.ISO8859-1 )],
    es_CO   => [qw( es_CO.UTF-8 es_CO.ISO-8859-1 es_CO.ISO8859-1 )],
    es_CR   => [qw( es_CR.UTF-8 es_CR.ISO-8859-1 es_CR.ISO8859-1 )],
    es_CU   => [qw( es_CU.UTF-8 )],
    es_DO   => [qw( es_DO.UTF-8 es_DO.ISO-8859-1 es_DO.ISO8859-1 )],
    es_EC   => [qw( es_EC.UTF-8 es_EC.ISO-8859-1 es_EC.ISO8859-1 )],
    es_ES   => [qw( es_ES.UTF-8 es_ES.ISO-8859-1 es_ES.ISO8859-1 es_ES.ISO-8859-15 es_ES.ISO8859-15 )],
    es_GT   => [qw( es_GT.UTF-8 es_GT.ISO-8859-1 es_GT.ISO8859-1 )],
    es_HN   => [qw( es_HN.UTF-8 es_HN.ISO-8859-1 es_HN.ISO8859-1 )],
    es_MX   => [qw( es_MX.UTF-8 es_MX.ISO-8859-1 es_MX.ISO8859-1 )],
    es_NI   => [qw( es_NI.UTF-8 es_NI.ISO-8859-1 es_NI.ISO8859-1 )],
    es_PA   => [qw( es_PA.UTF-8 es_PA.ISO-8859-1 es_PA.ISO8859-1 )],
    es_PE   => [qw( es_PE.UTF-8 es_PE.ISO-8859-1 es_PE.ISO8859-1 )],
    es_PR   => [qw( es_PR.UTF-8 es_PR.ISO-8859-1 es_PR.ISO8859-1 )],
    es_PY   => [qw( es_PY.UTF-8 es_PY.ISO-8859-1 es_PY.ISO8859-1 )],
    es_SV   => [qw( es_SV.UTF-8 es_SV.ISO-8859-1 es_SV.ISO8859-1 )],
    es_US   => [qw( es_US.UTF-8 es_US.ISO-8859-1 es_US.ISO8859-1 )],
    es_UY   => [qw( es_UY.UTF-8 es_UY.ISO-8859-1 es_UY.ISO8859-1 )],
    es_VE   => [qw( es_VE.UTF-8 es_VE.ISO-8859-1 es_VE.ISO8859-1 )],
    et_EE   => [qw( et_EE.UTF-8 et_EE.ISO-8859-1 et_EE.ISO8859-1 et_EE.ISO-8859-15 et_EE.ISO8859-15 )],
    eu_ES   => [qw( eu_ES.UTF-8 eu_ES.ISO-8859-1 eu_ES.ISO8859-1 eu_ES.ISO-8859-15 eu_ES.ISO8859-15 )],
    eu_FR   => [qw( eu_FR.UTF-8 eu_FR.ISO-8859-1 eu_FR.ISO8859-1 eu_FR.ISO-8859-15 eu_FR.ISO8859-15 )],
    fa_IR   => [qw( fa_IR.UTF-8 )],
    ff_SN   => [qw( ff_SN.UTF-8 )],
    fi_FI   => [qw( fi_FI.UTF-8 fi_FI.ISO-8859-1 fi_FI.ISO8859-1 fi_FI.ISO-8859-15 fi_FI.ISO8859-15 )],
    fil_PH  => [qw( fil_PH.UTF-8 )],
    fo_FO   => [qw( fo_FO.UTF-8 fo_FO.ISO-8859-1 fo_FO.ISO8859-1 )],
    fr_BE   => [qw( fr_BE.UTF-8 fr_BE.ISO-8859-1 fr_BE.ISO8859-1 fr_BE.ISO-8859-15 fr_BE.ISO8859-15 )],
    fr_CA   => [qw( fr_CA.UTF-8 fr_CA.ISO-8859-1 fr_CA.ISO8859-1 )],
    fr_CH   => [qw( fr_CH.UTF-8 fr_CH.ISO-8859-1 fr_CH.ISO8859-1 )],
    fr_FR   => [qw( fr_FR.UTF-8 fr_FR.ISO-8859-1 fr_FR.ISO8859-1 fr_FR.ISO-8859-15 fr_FR.ISO8859-15 )],
    fr_LU   => [qw( fr_LU.UTF-8 fr_LU.ISO-8859-1 fr_LU.ISO8859-1 fr_LU.ISO-8859-15 fr_LU.ISO8859-15 )],
    fur_IT  => [qw( fur_IT.UTF-8 )],
    fy_DE   => [qw( fy_DE.UTF-8 )],
    fy_NL   => [qw( fy_NL.UTF-8 )],
    ga_IE   => [qw( ga_IE.UTF-8 ga_IE.ISO-8859-1 ga_IE.ISO8859-1 ga_IE.ISO-8859-15 ga_IE.ISO8859-15 )],
    gd_GB   => [qw( gd_GB.UTF-8 gd_GB.ISO-8859-15 gd_GB.ISO8859-15 )],
    gez_ER  => [qw( gez_ER.UTF-8 )],
    gez_ET  => [qw( gez_ET.UTF-8 )],
    gl_ES   => [qw( gl_ES.UTF-8 gl_ES.ISO-8859-1 gl_ES.ISO8859-1 gl_ES.ISO-8859-15 gl_ES.ISO8859-15 )],
    gu_IN   => [qw( gu_IN.UTF-8 )],
    gv_GB   => [qw( gv_GB.UTF-8 gv_GB.ISO-8859-1 gv_GB.ISO8859-1 )],
    ha_NG   => [qw( ha_NG.UTF-8 )],
    hak_TW  => [qw( hak_TW.UTF-8 )],
    he_IL   => [qw( he_IL.UTF-8 he_IL.ISO-8859-8 he_IL.ISO8859-8 )],
    hi_IN   => [qw( hi_IN.UTF-8 )],
    hne_IN  => [qw( hne_IN.UTF-8 )],
    hr_HR   => [qw( hr_HR.UTF-8 hr_HR.ISO-8859-2 hr_HR.ISO8859-2 )],
    hsb_DE  => [qw( hsb_DE.UTF-8 hsb_DE.ISO-8859-2 hsb_DE.ISO8859-2 )],
    ht_HT   => [qw( ht_HT.UTF-8 )],
    hu_HU   => [qw( hu_HU.UTF-8 hu_HU.ISO-8859-2 hu_HU.ISO8859-2 )],
    hy_AM   => [qw( hy_AM.UTF-8 hy_AM.ARMSCII-8 hy_AM.ARMSCII8 )],
    ia_FR   => [qw( ia_FR.UTF-8 )],
    id_ID   => [qw( id_ID.UTF-8 id_ID.ISO-8859-1 id_ID.ISO8859-1 )],
    ig_NG   => [qw( ig_NG.UTF-8 )],
    ik_CA   => [qw( ik_CA.UTF-8 )],
    is_IS   => [qw( is_IS.UTF-8 is_IS.ISO-8859-1 is_IS.ISO8859-1 )],
    it_CH   => [qw( it_CH.UTF-8 it_CH.ISO-8859-1 it_CH.ISO8859-1 )],
    it_IT   => [qw( it_IT.UTF-8 it_IT.ISO-8859-1 it_IT.ISO8859-1 it_IT.ISO-8859-15 it_IT.ISO8859-15 )],
    iu_CA   => [qw( iu_CA.UTF-8 )],
    iw_IL   => [qw( iw_IL.UTF-8 iw_IL.ISO-8859-8 iw_IL.ISO8859-8 )],
    ja_JP   => [qw( ja_JP.UTF-8 ja_JP.EUC-JP ja_JP.EUCJP )],
    ka_GE   => [qw( ka_GE.UTF-8 ka_GE.GEORGIAN-PS ka_GE.GEORGIANPS )],
    kk_KZ   => [qw( kk_KZ.UTF-8 kk_KZ.PT154 kk_KZ.RK1048 )],
    kl_GL   => [qw( kl_GL.UTF-8 kl_GL.ISO-8859-1 kl_GL.ISO8859-1 )],
    km_KH   => [qw( km_KH.UTF-8 )],
    kn_IN   => [qw( kn_IN.UTF-8 )],
    ko_KR   => [qw( ko_KR.UTF-8 ko_KR.EUC-KR ko_KR.EUCKR )],
    kok_IN  => [qw( kok_IN.UTF-8 )],
    ks_IN   => [qw( ks_IN.UTF-8 )],
    ku_TR   => [qw( ku_TR.UTF-8 ku_TR.ISO-8859-9 ku_TR.ISO8859-9 )],
    kw_GB   => [qw( kw_GB.UTF-8 kw_GB.ISO-8859-1 kw_GB.ISO8859-1 )],
    ky_KG   => [qw( ky_KG.UTF-8 )],
    lb_LU   => [qw( lb_LU.UTF-8 )],
    lg_UG   => [qw( lg_UG.UTF-8 lg_UG.ISO-8859-10 lg_UG.ISO8859-10 )],
    li_BE   => [qw( li_BE.UTF-8 )],
    li_NL   => [qw( li_NL.UTF-8 )],
    lij_IT  => [qw( lij_IT.UTF-8 )],
    ln_CD   => [qw( ln_CD.UTF-8 )],
    lo_LA   => [qw( lo_LA.UTF-8 )],
    lt_LT   => [qw( lt_LT.UTF-8 lt_LT.ISO-8859-13 lt_LT.ISO8859-13 )],
    lv_LV   => [qw( lv_LV.UTF-8 lv_LV.ISO-8859-13 lv_LV.ISO8859-13 )],
    lzh_TW  => [qw( lzh_TW.UTF-8 )],
    mag_IN  => [qw( mag_IN.UTF-8 )],
    mai_IN  => [qw( mai_IN.UTF-8 )],
    mg_MG   => [qw( mg_MG.UTF-8 mg_MG.ISO-8859-15 mg_MG.ISO8859-15 )],
    mhr_RU  => [qw( mhr_RU.UTF-8 )],
    mi_NZ   => [qw( mi_NZ.UTF-8 mi_NZ.ISO-8859-13 mi_NZ.ISO8859-13 )],
    mk_MK   => [qw( mk_MK.UTF-8 mk_MK.ISO-8859-5 mk_MK.ISO8859-5 )],
    ml_IN   => [qw( ml_IN.UTF-8 )],
    mn_MN   => [qw( mn_MN.UTF-8 )],
    mni_IN  => [qw( mni_IN.UTF-8 )],
    mr_IN   => [qw( mr_IN.UTF-8 )],
    ms_MY   => [qw( ms_MY.UTF-8 ms_MY.ISO-8859-1 ms_MY.ISO8859-1 )],
    mt_MT   => [qw( mt_MT.UTF-8 mt_MT.ISO-8859-3 mt_MT.ISO8859-3 )],
    my_MM   => [qw( my_MM.UTF-8 )],
    nan_TW  => [qw( nan_TW.UTF-8 )],
    nb_NO   => [qw( nb_NO.UTF-8 nb_NO.ISO-8859-1 nb_NO.ISO8859-1 )],
    nds_DE  => [qw( nds_DE.UTF-8 )],
    nds_NL  => [qw( nds_NL.UTF-8 )],
    ne_NP   => [qw( ne_NP.UTF-8 )],
    nhn_MX  => [qw( nhn_MX.UTF-8 )],
    niu_NU  => [qw( niu_NU.UTF-8 )],
    niu_NZ  => [qw( niu_NZ.UTF-8 )],
    nl_AW   => [qw( nl_AW.UTF-8 )],
    nl_BE   => [qw( nl_BE.UTF-8 nl_BE.ISO-8859-1 nl_BE.ISO8859-1 nl_BE.ISO-8859-15 nl_BE.ISO8859-15 )],
    nl_NL   => [qw( nl_NL.UTF-8 nl_NL.ISO-8859-1 nl_NL.ISO8859-1 nl_NL.ISO-8859-15 nl_NL.ISO8859-15 )],
    nn_NO   => [qw( nn_NO.UTF-8 nn_NO.ISO-8859-1 nn_NO.ISO8859-1 )],
    nr_ZA   => [qw( nr_ZA.UTF-8 )],
    nso_ZA  => [qw( nso_ZA.UTF-8 )],
    oc_FR   => [qw( oc_FR.UTF-8 oc_FR.ISO-8859-1 oc_FR.ISO8859-1 )],
    om_ET   => [qw( om_ET.UTF-8 )],
    om_KE   => [qw( om_KE.UTF-8 om_KE.ISO-8859-1 om_KE.ISO8859-1 )],
    or_IN   => [qw( or_IN.UTF-8 )],
    os_RU   => [qw( os_RU.UTF-8 )],
    pa_IN   => [qw( pa_IN.UTF-8 )],
    pa_PK   => [qw( pa_PK.UTF-8 )],
    pap_AN  => [qw( pap_AN.UTF-8 )],
    pap_AW  => [qw( pap_AW.UTF-8 )],
    pap_CW  => [qw( pap_CW.UTF-8 )],
    pl_PL   => [qw( pl_PL.UTF-8 pl_PL.ISO-8859-2 pl_PL.ISO8859-2 )],
    ps_AF   => [qw( ps_AF.UTF-8 )],
    pt_BR   => [qw( pt_BR.UTF-8 pt_BR.ISO-8859-1 pt_BR.ISO8859-1 )],
    pt_PT   => [qw( pt_PT.UTF-8 pt_PT.ISO-8859-1 pt_PT.ISO8859-1 pt_PT.ISO-8859-15 pt_PT.ISO8859-15 )],
    quz_PE  => [qw( quz_PE.UTF-8 )],
    raj_IN  => [qw( raj_IN.UTF-8 )],
    ro_RO   => [qw( ro_RO.UTF-8 ro_RO.ISO-8859-2 ro_RO.ISO8859-2 )],
    ru_RU   => [qw( ru_RU.UTF-8 ru_RU.KOI8-R ru_RU.KOI8R ru_RU.ISO-8859-5 ru_RU.ISO8859-5 ru_RU.CP1251 )],
    ru_UA   => [qw( ru_UA.UTF-8 ru_UA.KOI8-U ru_UA.KOI8U )],
    rw_RW   => [qw( rw_RW.UTF-8 )],
    sa_IN   => [qw( sa_IN.UTF-8 )],
    sat_IN  => [qw( sat_IN.UTF-8 )],
    sc_IT   => [qw( sc_IT.UTF-8 )],
    sd_IN   => [qw( sd_IN.UTF-8 )],
    sd_PK   => [qw( sd_PK.UTF-8 )],
    se_NO   => [qw( se_NO.UTF-8 )],
    shs_CA  => [qw( shs_CA.UTF-8 )],
    si_LK   => [qw( si_LK.UTF-8 )],
    sid_ET  => [qw( sid_ET.UTF-8 )],
    sk_SK   => [qw( sk_SK.UTF-8 sk_SK.ISO-8859-2 sk_SK.ISO8859-2 )],
    sl_SI   => [qw( sl_SI.UTF-8 sl_SI.ISO-8859-2 sl_SI.ISO8859-2 )],
    so_DJ   => [qw( so_DJ.UTF-8 so_DJ.ISO-8859-1 so_DJ.ISO8859-1 )],
    so_ET   => [qw( so_ET.UTF-8 )],
    so_KE   => [qw( so_KE.UTF-8 so_KE.ISO-8859-1 so_KE.ISO8859-1 )],
    so_SO   => [qw( so_SO.UTF-8 so_SO.ISO-8859-1 so_SO.ISO8859-1 )],
    sq_AL   => [qw( sq_AL.UTF-8 sq_AL.ISO-8859-1 sq_AL.ISO8859-1 )],
    sq_MK   => [qw( sq_MK.UTF-8 )],
    sr_ME   => [qw( sr_ME.UTF-8 )],
    sr_RS   => [qw( sr_RS.UTF-8 )],
    ss_ZA   => [qw( ss_ZA.UTF-8 )],
    st_ZA   => [qw( st_ZA.UTF-8 st_ZA.ISO-8859-1 st_ZA.ISO8859-1 )],
    sv_FI   => [qw( sv_FI.UTF-8 sv_FI.ISO-8859-1 sv_FI.ISO8859-1 sv_FI.ISO-8859-15 sv_FI.ISO8859-15 )],
    sv_SE   => [qw( sv_SE.UTF-8 sv_SE.ISO-8859-1 sv_SE.ISO8859-1 sv_SE.ISO-8859-15 sv_SE.ISO8859-15 )],
    sw_KE   => [qw( sw_KE.UTF-8 )],
    sw_TZ   => [qw( sw_TZ.UTF-8 )],
    szl_PL  => [qw( szl_PL.UTF-8 )],
    ta_IN   => [qw( ta_IN.UTF-8 )],
    ta_LK   => [qw( ta_LK.UTF-8 )],
    tcy_IN  => [qw( tcy_IN.UTF-8 )],
    te_IN   => [qw( te_IN.UTF-8 )],
    tg_TJ   => [qw( tg_TJ.UTF-8 tg_TJ.KOI8-T tg_TJ.KOI8T )],
    th_TH   => [qw( th_TH.UTF-8 th_TH.TIS-620 th_TH.TIS620 )],
    the_NP  => [qw( the_NP.UTF-8 )],
    ti_ER   => [qw( ti_ER.UTF-8 )],
    ti_ET   => [qw( ti_ET.UTF-8 )],
    tig_ER  => [qw( tig_ER.UTF-8 )],
    tk_TM   => [qw( tk_TM.UTF-8 )],
    tl_PH   => [qw( tl_PH.UTF-8 tl_PH.ISO-8859-1 tl_PH.ISO8859-1 )],
    tn_ZA   => [qw( tn_ZA.UTF-8 )],
    tr_CY   => [qw( tr_CY.UTF-8 tr_CY.ISO-8859-9 tr_CY.ISO8859-9 )],
    tr_TR   => [qw( tr_TR.UTF-8 tr_TR.ISO-8859-9 tr_TR.ISO8859-9 )],
    ts_ZA   => [qw( ts_ZA.UTF-8 )],
    tt_RU   => [qw( tt_RU.UTF-8 )],
    ug_CN   => [qw( ug_CN.UTF-8 )],
    uk_UA   => [qw( uk_UA.UTF-8 uk_UA.KOI8-U uk_UA.KOI8U )],
    unm_US  => [qw( unm_US.UTF-8 )],
    ur_IN   => [qw( ur_IN.UTF-8 )],
    ur_PK   => [qw( ur_PK.UTF-8 )],
    uz_UZ   => [qw( uz_UZ.UTF-8 uz_UZ.ISO-8859-1 uz_UZ.ISO8859-1 )],
    ve_ZA   => [qw( ve_ZA.UTF-8 )],
    vi_VN   => [qw( vi_VN.UTF-8 )],
    wa_BE   => [qw( wa_BE.UTF-8 wa_BE.ISO-8859-1 wa_BE.ISO8859-1 wa_BE.ISO-8859-15 wa_BE.ISO8859-15 )],
    wae_CH  => [qw( wae_CH.UTF-8 )],
    wal_ET  => [qw( wal_ET.UTF-8 )],
    wo_SN   => [qw( wo_SN.UTF-8 )],
    xh_ZA   => [qw( xh_ZA.UTF-8 xh_ZA.ISO-8859-1 xh_ZA.ISO8859-1 )],
    yi_US   => [qw( yi_US.UTF-8 yi_US.CP1255 )],
    yo_NG   => [qw( yo_NG.UTF-8 )],
    yue_HK  => [qw( yue_HK.UTF-8 )],
    zh_CN   => [qw( zh_CN.UTF-8 zh_CN.GB18030 zh_CN.GBK zh_CN.GB2312 )],
    zh_HK   => [qw( zh_HK.UTF-8 zh_HK.BIG5-HKSCS zh_HK.BIG5HKSCS )],
    zh_SG   => [qw( zh_SG.UTF-8 zh_SG.GBK zh_SG.GB2312 )],
    zh_TW   => [qw( zh_TW.UTF-8 zh_TW.EUC-TW zh_TW.EUCTW zh_TW.BIG5 )],
    zu_ZA   => [qw( zu_ZA.UTF-8 zu_ZA.ISO-8859-1 zu_ZA.ISO8859-1 )],
};

# NOTE: $DEFAULT
$DEFAULT =
{
    # The local currency symbol.
    currency_symbol     => '€',
    # The decimal point character, except for currency values, cannot be an empty string
    decimal_point       => '.',
    # The number of digits after the decimal point in the local style for currency values.
    frac_digits         => 2,
    # The sizes of the groups of digits, except for currency values. unpack( "C*", $grouping ) will give the number
    grouping            => (CORE::chr(3) x 2),
    # The standardized international currency symbol.
    int_curr_symbol     => '€',
    # The number of digits after the decimal point in an international-style currency value.
    int_frac_digits     => 2,
    # Same as n_cs_precedes, but for internationally formatted monetary quantities.
    int_n_cs_precedes   => '',
    # Same as n_sep_by_space, but for internationally formatted monetary quantities.
    int_n_sep_by_space  => '',
    # Same as n_sign_posn, but for internationally formatted monetary quantities.
    int_n_sign_posn     => 1,
    # Same as p_cs_precedes, but for internationally formatted monetary quantities.
    int_p_cs_precedes   => 1,
    # Same as p_sep_by_space, but for internationally formatted monetary quantities.
    int_p_sep_by_space  => 0,
    # Same as p_sign_posn, but for internationally formatted monetary quantities.
    int_p_sign_posn     => 1,
    # The decimal point character for currency values.
    mon_decimal_point   => '.',
    # Like grouping but for currency values.
    mon_grouping        => (CORE::chr(3) x 2),
    # The separator for digit groups in currency values.
    mon_thousands_sep   => ',',
    # Like p_cs_precedes but for negative values.
    n_cs_precedes       => 1,
    # Like p_sep_by_space but for negative values.
    n_sep_by_space      => 0,
    # Like p_sign_posn but for negative currency values.
    n_sign_posn         => 1,
    # The character used to denote negative currency values, usually a minus sign.
    negative_sign       => '-',
    # 1 if the currency symbol precedes the currency value for nonnegative values, 0 if it follows.
    p_cs_precedes       => 1,
    # 1 if a space is inserted between the currency symbol and the currency value for nonnegative values, 0 otherwise.
    p_sep_by_space      => 0,
    # The location of the positive_sign with respect to a nonnegative quantity and the currency_symbol, coded as follows:
    # 0    Parentheses around the entire string.
    # 1    Before the string.
    # 2    After the string.
    # 3    Just before currency_symbol.
    # 4    Just after currency_symbol.
    p_sign_posn         => 1,
    # The character used to denote nonnegative currency values, usually the empty string.
    positive_sign       => '',
    # The separator between groups of digits before the decimal point, except for currency values
    thousands_sep       => ',',
};

# NOTE: $map_flexible
my $map_flexible =
{
    decimal             => [qw( decimal_point mon_decimal_point )],
    grouping            => [qw( grouping mon_grouping )],
    mon_decimal         => [qw( mon_decimal_point decimal_point )],
    mon_grouping        => [qw( mon_grouping grouping )],
    mon_thousand        => [qw( mon_thousands_sep thousands_sep )],
    position_neg        => [qw( n_sign_posn int_n_sign_posn )],
    position_pos        => [qw( p_sign_posn int_p_sign_posn )],
    precede             => [qw( p_cs_precedes int_p_cs_precedes )],
    precede_neg         => [qw( n_cs_precedes int_n_cs_precedes )],
    precision           => [qw( frac_digits int_frac_digits )],
    sign_neg            => [qw( negative_sign )],
    sign_pos            => [qw( positive_sign )],
    space_pos           => [qw( p_sep_by_space int_p_sep_by_space )],
    space_neg           => [qw( n_sep_by_space int_n_sep_by_space )],
    symbol              => [qw( currency_symbol int_curr_symbol )],
    thousand            => [qw( thousands_sep mon_thousands_sep )],
};

# NOTE: $map_posix_strict
my $map_posix_strict =
{
    decimal             => [qw( decimal_point )],
    grouping            => [qw( grouping )],
    mon_decimal         => [qw( mon_decimal_point )],
    mon_grouping        => [qw( mon_grouping )],
    mon_thousand        => [qw( mon_thousands_sep )],
    position_neg        => [qw( n_sign_posn int_n_sign_posn )],
    position_pos        => [qw( p_sign_posn int_p_sign_posn )],
    precede             => [qw( p_cs_precedes int_p_cs_precedes )],
    precede_neg         => [qw( n_cs_precedes int_n_cs_precedes )],
    precision           => [qw( frac_digits int_frac_digits )],
    sign_neg            => [qw( negative_sign )],
    sign_pos            => [qw( positive_sign )],
    space_pos           => [qw( p_sep_by_space int_p_sep_by_space )],
    space_neg           => [qw( n_sep_by_space int_n_sep_by_space )],
    symbol              => [qw( currency_symbol int_curr_symbol )],
    thousand            => [qw( thousands_sep )],
};

my $map = $map_flexible;

# This serves 2 purposes:
# 1) to silence warnings issued from Number::Format when it uses an empty string when evaluating a number, e.g. '' == 1
# 2) to ensure that blank numerical values are not interpreted to anything else than equivalent of empty
#    For example, an empty frac_digits will default to 2 in Number::Format even if the user does not want any. Of course, said user could also have set it to 0
# So here we use this hash reference of numeric properties to ensure the option parameters are set to a numeric value (0) when they are empty.
# NOTE: $numerics
my $numerics = 
{
    grouping            => 0,
    frac_digits         => 0,
    int_frac_digits     => 0,
    int_n_cs_precedes   => 0,
    int_p_cs_precedes   => 0,
    int_n_sep_by_space  => 0,
    int_p_sep_by_space  => 0,
    int_n_sign_posn     => 1,
    int_p_sign_posn     => 1,
    mon_grouping        => 0,
    n_cs_precedes       => 0,
    n_sep_by_space      => 0,
    n_sign_posn         => 1,
    p_cs_precedes       => 0,
    p_sep_by_space      => 0,
    # Position of positive sign. 1 = before (0 = parentheses)
    p_sign_posn         => 1,
};

sub init
{
    my $self = shift( @_ );
    return( $self->error( "No number was provided." ) ) if( !scalar( @_ ) );
    my $num  = shift( @_ );
    if( isinf( $num ) || isnan( $num ) )
    {
        return( $self->error( "The number provided is an Infinite or NaN, and cannot be formatted." ) );
    }
    my $opts = $self->_get_args_as_hash( @_ );
    $self->debug( CORE::delete( $opts->{debug} ) ) if( CORE::exists( $opts->{debug} ) );
    use utf8;
    # NOTE: we set the default instance value
    my @k = keys( %$map );
    @$self{ @k } = ( '' ) x scalar( @k );
    $self->{locale}         = '';
    $self->{posix_strict}   = 1;
    $self->{default}        = $DEFAULT;
    $self->{decimal_fill}   = 0;
    $self->{encoding}       = 'utf-8';
    $self->{neg_format}     = '-x';
    $self->{kilo_suffix}    = 'K';
    $self->{mega_suffix}    = 'M';
    $self->{giga_suffix}    = 'G';
    $self->{kibi_suffix}    = 'KiB';
    $self->{mebi_suffix}    = 'MiB';
    $self->{gibi_suffix}    = 'GiB';

    # NOTE: we prepare the instance data based on:
    # 1) the POSIX lconv data for the specified locale, if any.
    # 2) the POSIX lconv data for the currently used system locale
    # Then, those basic values can be overriden by the options provided now upon instantiation
    my $default = $self->default;
    my $curr_locale = POSIX::setlocale( &POSIX::LC_ALL );
    if( defined( $curr_locale ) &&
        CORE::length( $curr_locale ) )
    {
        if( CORE::index( $curr_locale, ';' ) != -1 )
        {
            # GNU/Linux "LC_NAME=value;LC_NAME=value" composite format.
            my @parts = CORE::split( /;/, $curr_locale );
            my $elems = {};
            for( @parts )
            {
                my( $n, $v ) = CORE::split( /=/, $_, 2 );
                $elems->{ $n } = $v;
            }
            $curr_locale = $elems->{LC_NUMERIC} || $elems->{LC_MESSAGES} || $elems->{LC_MONETARY};
        }
        # OpenBSD/FreeBSD "C/fr_FR.UTF-8/C/C/C/C"
        # However the order LC_CTYPE/LC_COLLATE/LC_TIME/LC_NUMERIC/LC_MONETARY/LC_MESSAGES is not guaranteed across platforms.
        elsif( CORE::index( $curr_locale, '/' ) != -1 )
        {
            # BSD "val1/val2/..." composite format: the string does not carry category names,
            # so we query LC_NUMERIC directly — it is the category that drives localeconv()
            # for numeric formatting.
            $curr_locale = POSIX::setlocale( &POSIX::LC_NUMERIC ) // $curr_locale;
        }
    }
    my $already_propagated = 0;
    if( $opts->{locale} )
    {
        $self->set_locale( $opts->{locale} ) || return( $self->pass_error );
        $already_propagated++;
    }
    elsif( $curr_locale && ( my $lconv = POSIX::localeconv() ) )
    {
        # Encode and I18N::Langinfo are both core modules since before perl 5.26.1, which is our minimum requirement
        $self->_load_class( 'Encode' ) || return( $self->pass_error );
        $self->_load_class( 'I18N::Langinfo' ) || return( $self->pass_error );
        my $encoding = eval
        {
            Encode::resolve_alias( I18N::Langinfo::langinfo( I18N::Langinfo::CODESET() ) );
        } || 'utf-8';
        if( $@ )
        {
            warn( "Error trying to resolve alias for POSIX::localeconv codeset: $@" ) if( $self->_is_warnings_enabled( 'Module::Generic' ) );
        }
        $self->encoding( $encoding );
        if( scalar( keys( %$lconv ) ) )
        {
            $lconv->{grouping}     = $self->_normalise_lconv_grouping( $lconv->{grouping} );
            $lconv->{mon_grouping} = $self->_normalise_lconv_grouping( $lconv->{mon_grouping} );
            $default = $lconv;
            if( my $decoded = $self->decode_lconv( $default ) )
            {
                $default = $decoded;
            }
        }
        # To simulate running on Windows
#         my $fail = [qw(
# frac_digits
# int_frac_digits
# n_cs_precedes
# n_sep_by_space
# n_sign_posn
# p_cs_precedes
# p_sep_by_space
# p_sign_posn
#         )];
#         @$lconv{ @$fail } = ( -1 ) x scalar( @$fail );
        $self->{locale} = $curr_locale;
    }

    unless( $already_propagated )
    {
        $self->_propagate_values( $default ) || return( $self->pass_error );
    }

    # Convert Japanese double bytes numbers to regular digits.
    $num =~ tr/[\x{FF10}-\x{FF19}]＋ー/[0-9]+-/;
    if( $num !~ /^$NUMBER_RE$/ )
    {
        my $clean = $self->unformat( $num );
        return( $self->pass_error ) if( !defined( $clean ) && $self->error );
        $self->{_number} = $clean;
    }
    else
    {
        $self->{_number} = $num;
    }
    return( $self->error( "Invalid number: $num (", overload::StrVal( $num ), ")" ) ) if( !defined( $self->{_number} ) );

    $self->{_init_strict_use_sub} = 1;
    $self->SUPER::init( %$opts ) || return( $self->pass_error );
    $self->{_original} = $num;
    $self->{_fields} = [qw(
        locale posix_strict decimal_fill encoding neg_format kilo_suffix mega_suffix
        giga_suffix kibi_suffix mebi_suffix gibi_suffix _number
    )];
    return( $self );
}

# This class does not convert to an HASH, but the TO_JSON method will convert to a string
sub as_hash { return( $_[0] ); }

sub as_string { return( shift->{_number} ) }

sub clone
{
    my $self = shift( @_ );
    return( $self->error( 'clone() can only be called on an instance of ', __PACKAGE__ ) ) unless( $self->_is_object( $self ) );
    my $new;
    # Called as a class function
    if( !$self->_is_object( $self ) )
    {
        my $num = shift( @_ ) // 0;
        $new = $self->new( $num );
        return( $self->pass_error ) if( !defined( $new ) );
    }
    else
    {
        my $num = @_ ? shift( @_ ) : $self->{_number};
        my $actual_num = $self->_is_a( $num => 'Module::Generic::Number' ) ? $num->{_number} : $num;
        if( isinf( $actual_num ) || isnan( $actual_num ) )
        {
            return( $self->error( "The number provided is an Infinite or NaN, and cannot be formatted." ) );
        }
        $new = $self->SUPER::clone;
        return( $self->pass_error ) if( !defined( $new ) );
        $new->{_number} = $actual_num;
        $new->clear_error;
    }
    return( $new );
}

sub currency { return( shift->_set_get_prop( 'symbol', @_ ) ); }

sub decimal { return( shift->_set_get_prop( 'decimal', @_ ) ); }

sub decimal_fill { return( shift->_set_get_prop( 'decimal_fill', @_ ) ); }

sub decode_lconv
{
    my $self = shift( @_ );
    my $ref = shift( @_ );
    return( $self->error( "Value provided is not an hash reference." ) ) if( !$self->_is_hash( $ref => 'strict' ) );
    my $encoding = $self->encoding || 'utf-8';

    foreach my $prop ( keys( %$ref ) )
    {
        next if( $prop eq 'grouping' || $prop eq 'mon_grouping' );
        my $v = $ref->{ $prop };
        next if( utf8::is_utf8( $v ) || $self->_is_empty( $v ) );
        my $rv = eval
        {
            return( Encode::decode(
                $encoding,
                $v,
                Encode::FB_CROAK()
            ) );
        };
        if( $@ )
        {
            warn( "Error trying to decode POSIX::localeconv property ${prop} and language $self->{locale}: $@" ) if( $self->_is_warnings_enabled( 'Module::Generic' ) );
            next;
        }
        $ref->{ $prop } = $rv;
    }
    return( $ref );
};

# sub default { return( shift->_set_get_hash_as_mix_object( 'default', @_ ) ); }
sub default { return( shift->_set_get_hash( 'default', @_ ) ); }

sub encoding { return( shift->_set_get_scalar( 'encoding', @_ ) ); }

sub format
{
    my $self = shift( @_ );
    my $precision;
    $precision = shift( @_ ) if( scalar( @_ ) && $_[0] =~ /^\d+$/ );
    my $opts = $self->_get_args_as_hash( @_ );
    return( $self->error( 'format() can only be called on an instance of ', __PACKAGE__ ) ) unless( $self->_is_object( $self ) );
    no overloading;
    my $number  = $self->{_number};
    # If value provided was undefined, we leave it undefined, otherwise we would be at risk of returning 0, and 0 is very different from undefined
    return( $number ) if( !defined( $number ) );
    $precision        //= $opts->{precision}    // $self->precision;
    my $thousands_sep   = $opts->{thousand}     // $self->thousand;
    my $decimal_point   = $opts->{decimal}      // $self->decimal;
    my $trailing_zeroes = $opts->{decimal_fill} // $self->decimal_fill // 1;
    my $grouping        = $opts->{grouping}     // $self->grouping     // 3;
    for( $precision, $thousands_sep, $decimal_point, $trailing_zeroes, $grouping )
    {
        $_ = $_->scalar if( $self->_can( $_ => 'scalar' ) );
    }
    $grouping = 3 unless( $self->_is_integer( $grouping ) );

    # Taken from Number::Format. Credit to William R. Ward
    # Handle negative numbers
    my $sign = $number <=> 0;
    $number = CORE::abs( $number ) if( $sign < 0 );

    # detect scientific notation
    my $exponent = 0;
    # if( $number =~ /^(-?[\d.]+)e([+-]\d+)$/ )
    # {
    #     # Don't attempt to format numbers that require scientific notation.
    #     return( $number );
    # }
    # Detect scientific notation and preserve it exactly
    # 1.23e+45
    if( "$number" =~ /^(-?\d+(?:\.\d+)?)[eE]([+-]?\d+)+$/i )
    {
        my $mantissa = $1;
        my $exponent = $2;
        # Preserve the exact string representation without formatting
        my $result = "$mantissa" . "e" . "$exponent";
        $self->_load_class( 'Module::Generic::Scalar' ) || return( $self->pass_error );
        return( Module::Generic::Scalar->new( $result ) );
    }

    # round off $number
    $number = $self->_round( $number => $precision );

    # Split integer and decimal parts of the number and add commas
    my $integer = CORE::int( $number );
    my $decimal;

    # Note: In perl 5.6 and up, string representation of a number
    # automagically includes the locale decimal point. This way we
    # will detect the decimal part correctly as long as the decimal
    # point is 1 character.
    if( CORE::length( $integer ) < CORE::length( $number ) )
    {
        $decimal = CORE::substr( $number, CORE::length( $integer ) + 1 );
    }
    $decimal = '' unless( defined( $decimal ) );

    # Add trailing 0's if $trailing_zeroes is set.
    if( $trailing_zeroes && $precision > CORE::length( $decimal ) )
    {
        $decimal .= '0' x ( $precision - CORE::length( $decimal ) );
    }

    # Add the commas (or whatever is in thousands_sep). If thousands_sep is the empty 
    # string, do nothing.
    if( $thousands_sep && $grouping > 0 )
    {
        # Add leading 0's so length($integer) is divisible by 3
        $integer = '0' x ( $grouping - ( CORE::length( $integer ) % $grouping ) ) . $integer;

        # Split $integer into groups of 3 characters and insert commas
        # $integer = CORE::join( $thousands_sep, CORE::grep{ $_ ne '' } CORE::split( /(...)/, $integer ) );
        $integer = CORE::join( $thousands_sep, CORE::grep{ $_ ne '' } CORE::split( /(.{$grouping})/, $integer ) );
        # Taken from perllocale:
        # Grouping goes from right to left (low to high digits).
        # 1 while $integer =~ s/(\d)(\d{$grouping}($|$thousands_sep))/$1$thousands_sep$2/;

        # Strip off leading zeroes and optional thousands separator
        $integer =~ s/^0+(?:\Q$thousands_sep\E)?//;
    }
    $integer = '0' if( $integer eq '' );

    # Combine integer and decimal parts and return the result.
    my $result = ( CORE::defined( $decimal ) && CORE::length( $decimal ) )
        ? CORE::join( $decimal_point, $integer, $decimal )
        : $integer;

    my $res = ( $sign < 0 ) ? $self->_format_negative( $result ) : $result;
    return( $self->pass_error ) if( !defined( $res ) && $self->error );
    $self->_load_class( 'Module::Generic::Scalar' ) || return( $self->pass_error );
    $self->clear_error;
    return( Module::Generic::Scalar->new( $res ) );
}

# sub format_binary { return( Module::Generic::Scalar->new( CORE::sprintf( '%b', shift->{_number} ) ) ); }
sub format_binary
{
    my $self = shift( @_ );
    return( $self->error( 'format_binary() can only be called on an instance of ', __PACKAGE__ ) ) unless( $self->_is_object( $self ) );
    $self->_load_class( 'Module::Generic::Scalar' ) || return( $self->pass_error );
    $self->clear_error;
    return( Module::Generic::Scalar->new( CORE::sprintf( '%b', $self->{_number} ) ) );
}

sub format_bytes
{
    my $self = shift( @_ );
    return( $self->error( 'format_bytes() can only be called on an instance of ', __PACKAGE__ ) ) unless( $self->_is_object( $self ) );
    # no overloading;
    my $number  = $self->{_number};
    # See comment in format() method
    return( $number ) if( !defined( $number ) );
    my $opts = $self->_get_args_as_hash( @_ );
    return( $self->error( "Negative number not allowed in format_bytes()" ) ) if( $number < 0 );

    # Taken from Number::Format. Credit to William R. Ward
    # Set default for precision.  Test using defined because it may be 0.
    $opts->{precision} //= $self->precision->scalar // 2;
    $opts->{mode} ||= 'traditional';
    my( $ksuff, $msuff, $gsuff );
    if( $opts->{mode} =~ /^iec(60027)?$/i )
    {
        ( $ksuff, $msuff, $gsuff ) = @$self{ qw( kibi_suffix mebi_suffix gibi_suffix ) };
        return( $self->error( "'base' option not allowed in iec60027 mode" ) ) if( CORE::exists( $opts->{base} ) );
    }
    elsif( $opts->{mode} =~ /^trad(itional)?$/i )
    {
        ( $ksuff, $msuff, $gsuff ) = @$self{ qw( kilo_suffix mega_suffix giga_suffix ) };
    }
    else
    {
        return( $self->error( "Unsupported mode '$opts->{mode}'" ) );
    }

    # Set default for "base" option.  Calculate threshold values for
    # kilo, mega, and giga values.  On 32-bit systems tera would cause
    # overflows so it is not supported.  Useful values of "base" are
    # 1024 or 1000, but any number can be used.  Larger numbers may
    # cause overflows for giga or even mega, however.
    my $mult = $self->_get_multipliers( $opts->{base} ) ||
        return( $self->pass_error );

    # Process "unit" option.  Set default, then take first character
    # and convert to upper case.
    $opts->{unit} = 'auto' unless( defined( $opts->{unit} ) );
    my $unit = CORE::uc( CORE::substr( $opts->{unit}, 0, 1 ) );

    # Process "auto" first (default).  Based on size of number,
    # automatically determine which unit to use.
    if( $unit eq 'A' )
    {
        if( $number >= $mult->{giga} )
        {
            $unit = 'G';
        }
        elsif( $number >= $mult->{mega} )
        {
            $unit = 'M';
        }
        elsif( $number >= $mult->{kilo} )
        {
            $unit = 'K';
        }
        else
        {
            $unit = 'N';
        }
    }

    # Based on unit, whether specified or determined above, divide the
    # number and determine what suffix to use.
    my $suffix = '';
    if( $unit eq 'G' )
    {
        $number /= $mult->{giga};
        $suffix = $gsuff;
    }
    elsif( $unit eq 'M' )
    {
        $number /= $mult->{mega};
        $suffix = $msuff;
    }
    elsif( $unit eq 'K' )
    {
        $number /= $mult->{kilo};
        $suffix = $ksuff;
    }
    elsif( $unit ne 'N' )
    {
        return( $self->error( "Invalid 'unit' option value \"$unit\"" ) );
    }

    # Format the number and add the suffix.
    my $clone = $self->clone( $number );
    return( $self->pass_error ) if( !defined( $clone ) );

    my $formatted = $clone->format( $opts->{precision} );
    return( $self->pass_error ) if( !defined( $formatted ) && $clone->error );

    my $result = "${formatted}${suffix}";

    return( $self->pass_error ) if( !defined( $result ) );
    $self->_load_class( 'Module::Generic::Scalar' ) || return( $self->pass_error );
    $self->clear_error;
    return( Module::Generic::Scalar->new( $result ) );
}

sub format_hex
{
    my $self = shift( @_ );
    return( $self->error( 'format_hex() can only be called on an instance of ', __PACKAGE__ ) ) unless( $self->_is_object( $self ) );
    $self->_load_class( 'Module::Generic::Scalar' ) || return( $self->pass_error );
    $self->clear_error;
    return( Module::Generic::Scalar->new( CORE::sprintf( '0x%X', $self->{_number} ) ) );
}

sub format_money
{
    my $self = shift( @_ );
    my( $precision, $curr_symbol ) = @_;
    return( $self->error( 'format_money() can only be called on an instance of ', __PACKAGE__ ) ) unless( $self->_is_object( $self ) );
    $precision = $self->precision->scalar if( !defined( $precision ) || !CORE::length( "$precision" ) || $precision !~ /^\d+$/ );
    $curr_symbol = $self->currency->scalar if( !defined( $curr_symbol ) || !CORE::length( "$curr_symbol" ) );
    # no overloading;
    my $number = $self->{_number};
    # See comment in format() method
    return( $number ) if( !defined( $number ) );

    # NOTE: Money follows the LC_MONETARY category through the dedicated monetary trio
    # resolved in init() (mon_decimal, mon_thousand, mon_grouping). We fall back to the
    # numeric trio only when a monetary value was not resolved at all, so that a locale
    # missing monetary data still produces a sensible result.
    my $mon_decimal_point = $self->mon_decimal->scalar;
    my $mon_thousands_sep = $self->mon_thousand->scalar;
    my $mon_grouping      = $self->mon_grouping->scalar;
    $mon_decimal_point    = $self->decimal->scalar  if( !defined( $mon_decimal_point ) || !CORE::length( $mon_decimal_point ) );
    $mon_thousands_sep    = $self->thousand->scalar if( !defined( $mon_thousands_sep ) || !CORE::length( $mon_thousands_sep ) );
    $mon_grouping         = $self->grouping->scalar if( !defined( $mon_grouping )      || !CORE::length( $mon_grouping ) );

    my $frac_digits = $self->precision->scalar;

    # Determine precision for decimal portion
    $precision = $frac_digits unless( defined( $precision ) );
    # fallback
    # $precision = $self->decimal_digits unless( defined( $precision ) );
    # default
    $precision = 2 unless( defined( $precision ) );

    # Determine sign and absolute value
    my $sign = $number <=> 0;
    $number = CORE::abs( $number ) if( $sign < 0 );

    # format it first
    $number = $self->format(
        precision => $precision,
        decimal   => $mon_decimal_point,
        thousand  => $mon_thousands_sep,
        grouping  => $mon_grouping,
    );
    return( $self->pass_error ) if( !defined( $number ) );

    # Now we make sure the decimal part has enough zeroes
    my $decimal_point = $mon_decimal_point;
    my( $integer, $decimal ) = CORE::split( /\Q$decimal_point\E/, "$number", 2 );
    $decimal //= '';
    # $decimal = '0' x $precision if( !$decimal && $precision );
    $decimal = '0' x $precision unless( $decimal );
    $decimal .= '0' x ( $precision - CORE::length( $decimal ) );

    # Extract positive or negative values
    my( $sep_by_space, $cs_precedes, $sign_posn, $sign_symbol );
    if( $sign < 0 )
    {
        $sep_by_space = $self->space_neg;
        $cs_precedes  = $self->precede_neg;
        $sign_posn    = $self->position_neg;
        $sign_symbol  = $self->sign_neg // '';
    }
    else
    {
        $sep_by_space = $self->space_pos;
        $cs_precedes  = $self->precede_pos;
        $sign_posn    = $self->position_pos;
        $sign_symbol  = $self->sign_pos // '';
    }

    # Combine it all back together.
    my $result = $precision
        ? CORE::join( $mon_decimal_point, $integer, $decimal )
        : $integer;

    # Determine where spaces go, if any
    my( $sign_sep, $curr_sep );
    if( $sep_by_space == 0 )
    {
        $sign_sep = $curr_sep = '';
    }
    elsif( $sep_by_space == 1 )
    {
        $sign_sep = '';
        $curr_sep = ' ';
    }
    elsif( $sep_by_space == 2 )
    {
        $sign_sep = ' ';
        $curr_sep = '';
    }
    else
    {
        return( $self->error( "Invalid space (space_neg or space_pos) value provided." ) );
    }

    my $rv;
    # Add sign, if any
    if( $sign_posn >= 0 && $sign_posn <= 2 )
    {
        # Combine with currency symbol and return
        if( $curr_symbol ne '' )
        {
            if( $cs_precedes )
            {
                $result = $curr_symbol . $curr_sep . $result;
            }
            else
            {
                $result = $result . $curr_sep . $curr_symbol;
            }
        }

        if( $sign_posn == 0 )
        {
            $rv = "($result)";
        }
        elsif( $sign_posn == 1 )
        {
            $rv = $sign_symbol . $sign_sep . $result;
        }
        # $sign_posn == 2
        else
        {
            $rv = $result . $sign_sep . $sign_symbol;
        }
    }
    elsif( $sign_posn == 3 || $sign_posn == 4 )
    {
        if( $sign_posn == 3 )
        {
            $curr_symbol = $sign_symbol . $sign_sep . $curr_symbol;
        }
        # $sign_posn == 4
        else
        {
            $curr_symbol = $curr_symbol . $sign_sep . $sign_symbol;
        }

        # Combine with currency symbol and return
        if( $cs_precedes )
        {
            $rv = $curr_symbol. $curr_sep . $result;
        }
        else
        {
            $rv = $result . $curr_sep . $curr_symbol;
        }
    }
    else
    {
        return( $self->error( "Invalid *_sign_posn value" ) );
    }

    return if( !defined( $rv ) );
    $self->_load_class( 'Module::Generic::Scalar' ) || return( $self->pass_error );
    $self->clear_error;
    return( Module::Generic::Scalar->new( $rv ) );
}

sub format_negative
{
    my $self = shift( @_ );
    # no overloading;
    # my $number  = $self->{_number};
    # See comment in format() method
    # return( $number ) if( !defined( $number ) );
    my $format = shift( @_ ) // $self->neg_format->scalar;
    return( $self->error( 'format_negative() can only be called on an instance of ', __PACKAGE__ ) ) unless( $self->_is_object( $self ) );
    my $new = $self->format || return( $self->pass_error );
    my $number = "$new";
    if( CORE::index( $format, 'x' ) == -1 )
    {
        return( $self->error( "Letter x must be present in picture in format_negative()" ) );
    }
    $number =~ s/^-//;
    $format =~ s/x/$number/;
    return if( !defined( $number ) );
    $self->_load_class( 'Module::Generic::Scalar' ) || return( $self->pass_error );
    $self->clear_error;
    return( Module::Generic::Scalar->new( $format ) );
}

sub format_picture
{
    my $self = shift( @_ );
    my $picture;
    if( ( scalar( @_ ) == 1 && !$self->_is_hash( $_[0] ) ) || 
        ( ( @_ % 2 ) && !$self->_is_hash( $_[0] ) ) )
    {
        $picture = shift( @_ );
    }
    my $opts = $self->_get_args_as_hash( @_ );
    return( $self->error( 'format_picture() can only be called on an instance of ', __PACKAGE__ ) ) unless( $self->_is_object( $self ) );
    no overloading;
    my $number  = $self->{_number};
    # See comment in format() method
    return if( !defined( $number ) );

    # Taken from Number::Format. Credit to William R. Ward
    $picture //= $opts->{picture};
    return( $self->error( "No picture was provided to format number." ) ) if( !CORE::defined( $picture ) || !CORE::length( "$picture" ) );

    # Handle negative numbers
    my $neg_format = $self->neg_format->scalar;
    my( $neg_prefix ) = $neg_format =~ /^([^x]+)/;
    my( $pic_prefix ) = $picture =~ /^([^\#]+)/;
    my $neg_pic = $neg_format;
    ( my $pos_pic = $neg_format ) =~ s/[^x\s]/ /g;
    ( my $pos_prefix = $neg_prefix ) =~ s/[^x\s]/ /g;
    $neg_pic =~ s/x/$picture/;
    $pos_pic =~ s/x/$picture/;
    my $sign = $number <=> 0;
    $number = CORE::abs( $number ) if( $sign < 0 );
    $picture = $sign < 0 ? $neg_pic : $pos_pic;
    my $sign_prefix = $sign < 0 ? $neg_prefix : $pos_prefix;

    # Split up the picture and return error if there is more than one $decimal_point
    my $decimal_point = $self->decimal->scalar;
    my( $pic_int, $pic_dec, @cruft ) = CORE::split( /\Q$decimal_point\E/, $picture );
    $pic_int = '' unless( defined( $pic_int ) );
    $pic_dec = '' unless( defined( $pic_dec ) );

    return( $self->error( "Only one decimal separator permitted in picture" ) ) if( @cruft );

    # Obtain precision from the length of the decimal part...
    # start with copying it
    my $precision = $pic_dec;
    # eliminate all non-# characters
    $precision =~ s/[^\#]//g;
    # take the length of the result
    $precision = CORE::length( $precision );

    # Format the number
    $number = $self->_round( $number => $precision );

    # Obtain the length of the integer portion just like we did for $precision
    # start with copying it
    my $intsize = $pic_int;
    # eliminate all non-# characters
    $intsize =~ s/[^\#]//g;
    # take the length of the result
    $intsize = CORE::length( $intsize );

    # Split up $number same as we did for $picture earlier
    my( $num_int, $num_dec ) = CORE::split( /\./, $number, 2 );
    $num_int = '' unless( defined( $num_int ) );
    $num_dec = '' unless( defined( $num_dec ) );

    # Check if the integer part will fit in the picture
    if( CORE::length( $num_int ) > $intsize )
    {
        # convert # to * and return it
        $picture =~ s/\#/\*/g;
        $pic_prefix = '' unless( defined( $pic_prefix ) );
        $picture =~ s/^(\Q$sign_prefix\E)(\Q$pic_prefix\E)([[:blank:]\h]*)/$2$3$1/;
        return( Module::Generic::Scalar->new( $picture ) );
    }

    # Split each portion of number and picture into arrays of characters
    my @num_int = CORE::split( //, $num_int );
    my @num_dec = CORE::split( //, $num_dec );
    my @pic_int = CORE::split( //, $pic_int );
    my @pic_dec = CORE::split( //, $pic_dec );

    # Now we copy those characters into @result.
    my @result;
    if( $picture =~ /\Q$decimal_point\E/ )
    {
        @result = ( $decimal_point )
    }
    # For each characture in the decimal part of the picture, replace '#'
    # signs with digits from the number.
    my $char;
    foreach $char ( @pic_dec )
    {
        $char = ( shift( @num_dec ) || 0 ) if( $char eq '#' );
        CORE::push( @result, $char );
    }

    # For each character in the integer part of the picture (moving right
    # to left this time), replace '#' signs with digits from the number,
    # or spaces if we've run out of numbers.
    my $thousand = $self->thousand->scalar;
    while( $char = CORE::pop( @pic_int ) )
    {
        $char = CORE::pop( @num_int ) if( $char eq '#' );
        if( !defined( $char ) ||
            $char eq $thousand && 
            $#num_int < 0 )
        {
            $char = ' ';
        }
        CORE::unshift( @result, $char );
    }

    # Combine @result into a string and return it.
    my $result = CORE::join( '', @result );
    $sign_prefix = '' unless( defined( $sign_prefix ) );
    $pic_prefix  = '' unless( defined( $pic_prefix ) );
    $result =~ s/^(\Q$sign_prefix\E)(\Q$pic_prefix\E)(\s*)/$2$3$1/;

    return if( !defined( $result ) );
    $self->_load_class( 'Module::Generic::Scalar' ) || return( $self->pass_error );
    $self->clear_error;
    return( Module::Generic::Scalar->new( $result ) );
}

sub gibi_suffix { return( shift->_set_get_prop( 'gibi_suffix', @_ ) ); }

sub giga_suffix { return( shift->_set_get_prop( 'giga_suffix', @_ ) ); }

sub grouping { return( shift->_set_get_prop( 'grouping', @_ ) ); }

sub kibi_suffix { return( shift->_set_get_prop( 'kibi_suffix', @_ ) ); }

sub kilo_suffix { return( shift->_set_get_prop( 'kilo_suffix', @_ ) ); }

sub lang { return( shift->_set_get_scalar_as_object( 'locale', @_ ) ); }

sub locale { return( shift->_set_get_scalar_as_object( 'locale', @_ ) ); }

sub mebi_suffix { return( shift->_set_get_prop( 'mebi_suffix', @_ ) ); }

sub mega_suffix { return( shift->_set_get_prop( 'mega_suffix', @_ ) ); }

sub mon_decimal { return( shift->_set_get_prop( 'mon_decimal', @_ ) ); }

sub mon_grouping { return( shift->_set_get_prop( 'mon_grouping', @_ ) ); }

sub mon_thousand { return( shift->_set_get_prop( 'mon_thousand', @_ ) ); }

sub neg_format { return( shift->_set_get_prop( 'neg_format', @_ ) ); }

sub posix_strict { return( shift->_set_get_boolean( 'posix_strict', @_ ) ); }

sub position_neg { return( shift->_set_get_prop( 'position_neg', @_ ) ); }

sub position_pos { return( shift->_set_get_prop( 'position_pos', @_ ) ); }

sub precede { return( shift->_set_get_prop( 'precede', @_ ) ); }

sub precede_neg { return( shift->_set_get_prop( 'precede_neg', @_ ) ); }

sub precede_pos { return( shift->_set_get_prop( 'precede', @_ ) ); }

sub precision { return( shift->_set_get_prop( 'precision', @_ ) ); }

# sub round { return( $_[0]->clone( CORE::sprintf( '%.*f', CORE::int( CORE::length( $_[1] ) ? $_[1] : 0 ), $_[0]->{_number} ) ) ); }
sub round
{
    my $self = shift( @_ );
    return( $self->error( 'round() can only be called on an instance of ', __PACKAGE__ ) ) unless( $self->_is_object( $self ) );
    my $precision;
    if( scalar( @_ ) == 1 )
    {
        $precision = shift( @_ );
        if( !$self->_is_integer( $precision ) )
        {
            return( $self->error( "round() precision value provided '", ( $precision // '' ), "' is not an integer." ) );
        }
        elsif( $precision < 0 )
        {
            return( $self->error( "round() precision provided '$precision' is negative. It must be positive." ) );
        }
    }
    else
    {
        return( $self->error( 'Usage: my $n2 = $n->round( $precision );' ) );
    }
    my $new = CORE::sprintf( '%.*f', $precision, $self->{_number} );
    $self->clear_error;
    return( $new );
}

sub round_zero
{
    my $self = shift( @_ );
    my @args = @_;
    return( $self->error( 'round_zero() can only be called on an instance of ', __PACKAGE__ ) ) unless( $self->_is_object( $self ) );
    if( $] >= 5.022 )
    {
        my $val  = @args ? shift( @args ) : undef;
        local $@;
        my $res = eval
        {
            defined( $val ) ? POSIX::round( $self->{_number}, $val ) : POSIX::round( $self->{_number} )
        };
        CORE::warn( $@ ) if( $@ );
        $self->clear_error;
        return( $res );
    }
    else
    {
        my $n = $self->{_number};
        # round to nearest, ties away from zero (same semantics as C99 round())
        my $res;
        if( $n >= 0 )
        {
            $res = CORE::int( $n + 0.5 );
        }
        else
        {
            $res = -CORE::int( -$n + 0.5 );
        }
        $self->clear_error;
        return if( !defined( $res ) );
        return( $res );
    }
}

sub round2
{
    my $self = shift( @_ );
    return( $self->error( 'round2() can only be called on an instance of ', __PACKAGE__ ) ) unless( $self->_is_object( $self ) );
    no overloading;
    my $precision;
    if( scalar( @_ ) == 1 )
    {
        $precision = shift( @_ );
        if( !$self->_is_integer( $precision ) )
        {
            return( $self->error( "precision value provided '", ( $precision // '' ), "' is not an integer." ) );
        }
        elsif( $precision < 0 )
        {
            return( $self->error( "precision provided '$precision' is negative. It must be positive." ) );
        }
    }
    else
    {
        return( $self->error( 'Usage: my $n2 = $n->round2( $precision );' ) );
    }
    my $number  = $self->{_number};
    # See comment in format() method
    return( $number ) if( !defined( $number ) );

    unless( CORE::int( $precision ) == $precision )
    {
        return( $self->error( "precision option value must be integer" ) );
    }

    if( CORE::ref( $number ) && $number->isa( 'Math::BigFloat' ) )
    {
        my $rounded = $number->copy;
        $rounded->precision( -$precision );
        $self->clear_error;
        return if( !defined( $rounded ) );
        return( $rounded );
    }

    my $sign       = $number <=> 0;
    my $multiplier = ( 10 ** $precision );
    my $result     = CORE::abs( $number );
    my $product    = $result * $multiplier;

    if( $product > MAX_INT )
    {
        return( $self->error( "round2() overflow. Try smaller precision or use Math::BigFloat" ) )
    }

    # We need to add 1e-14 to avoid some rounding errors due to the
    # way floating point numbers work - see string-eq test in t/round.t
    $result = CORE::int( $product + .5 + 1e-14 ) / $multiplier;
    $result = -$result if( $sign < 0 );
    $self->clear_error;
    return if( !defined( $result ) );
    return( $result );
}

sub set_locale
{
    my $self = shift( @_ );
    my $locale = shift( @_ ) ||
        return( $self->error( "No locale was provided to set." ) );
    return( $self->error( 'set_locale() can only be called on an instance of ', __PACKAGE__ ) ) unless( $self->_is_object( $self ) );
    my( $locale, $locale_enc ) = split( /\./, $locale, 2 );
    $locale =~ tr/-/_/;
    $locale = join( '.', $locale, $locale_enc ) if( defined( $locale_enc ) );
    # Lock the threads while we change the locale to check if it is available, and get its definition.
    my $default;
    lock( $LOCALE_LOCK ) if( HAS_THREADS );
    # try-catch
    local $@;
    # We wrap our checks for locale in an anonymous subroutine to catch any fatal exception.
    my $try_locale = sub
    {
        my $accepted = shift( @_ );
        my $saved_locale = POSIX::setlocale( &POSIX::LC_ALL );
        my $restore_locale = sub
        {
            # Set back the LC_ALL to what it was, because we do not want to disturb the user environment
            POSIX::setlocale( &POSIX::LC_ALL, $saved_locale ) if( defined( $saved_locale ) );
        };
        my( $loc, $lconv, $encoding );
        # The user provided only a language code such as fr_FR. We try it, and also other known combination like fr_FR.UTF-8 and fr_FR.ISO-8859-1, fr_FR.ISO8859-1
        # Try several possibilities
        # RT https://rt.cpan.org/Public/Bug/Display.html?id=132664
        if( index( $accepted, '.' ) == -1 )
        {
            $loc = POSIX::setlocale( &POSIX::LC_ALL, $accepted );
            $accepted =~ s/^(?<locale>[a-z]{2,3})_(?<country>[a-z]{2})$/$+{locale}_\U$+{country}\E/;
            if( !$loc && CORE::exists( $SUPPORTED_LOCALES->{ $accepted } ) )
            {
                foreach my $supported ( @{$SUPPORTED_LOCALES->{ $accepted }} )
                {
                    if( ( $loc = POSIX::setlocale( &POSIX::LC_ALL, $supported ) ) )
                    {
                        $accepted = $supported;
                        last;
                    }
                }
            }
        }
        # We got something like fr_FR.ISO-8859
        # The user is specific, so we try as is
        else
        {
            $loc = POSIX::setlocale( &POSIX::LC_ALL, $accepted );
        }

        if( $loc )
        {
            # Encode and I18N::Langinfo are both core modules since before perl 5.26.1, which is our minimum requirement
            if( !$self->_load_class( 'Encode' ) )
            {
                $restore_locale->();
                die( $self->error );
            }
            if( !$self->_load_class( 'I18N::Langinfo' ) )
            {
                $restore_locale->();
                die( $self->error );
            }
            $lconv = POSIX::localeconv();
            # We do not want to pollute our local $@ at the beginning of 'set_locale'
            local $@;
            $encoding = eval
            {
                Encode::resolve_alias( I18N::Langinfo::langinfo( I18N::Langinfo::CODESET() ) );
            } || 'utf-8';
            if( $@ )
            {
                warn( "Error trying to resolve alias for POSIX::localeconv codeset: $@" ) if( $self->_is_warnings_enabled( 'Module::Generic' ) );
            }
        }
        $restore_locale->();
        return( $loc, $lconv, $encoding, $accepted );
    };
    
    my( $loc, $lconv, $encoding, $accepted ) = eval{ $try_locale->( $locale ) };
    if( $loc )
    {
        $self->encoding( $encoding );  # could be undef
        if( $lconv && scalar( keys( %$lconv ) ) )
        {
            $lconv->{grouping}     = $self->_normalise_lconv_grouping( $lconv->{grouping} );
            $lconv->{mon_grouping} = $self->_normalise_lconv_grouping( $lconv->{mon_grouping} );
            $default = $lconv;
            if( my $decoded = $self->decode_lconv( $default ) )
            {
                $self->_propagate_values( $decoded ) || return( $self->pass_error );
            }
        }
    }
    elsif( $@ )
    {
        return( $self->error( "An error occurred while getting the locale information for \"$locale\": $@" ) );
    }
    else
    {
        return( $self->error( "Language \"$locale\" is not supported by your system." ) );
    }

    unless( defined( $accepted ) )
    {
        return( $self->error( "An unexpected error occurred while setting the locale \"$locale\": the accepted locale was not returned." ) );
    }
    $self->{locale} = $accepted;
    $self->clear_error;
    return( $self->{locale} );
}

sub sign_neg { return( shift->_set_get_prop( 'sign_neg', @_ ) ); }

sub sign_pos { return( shift->_set_get_prop( 'sign_pos', @_ ) ); }

sub space_neg { return( shift->_set_get_prop( 'space_neg', @_ ) ); }

sub space_pos { return( shift->_set_get_prop( 'space_pos', @_ ) ); }

sub symbol { return( shift->_set_get_prop( 'symbol', @_ ) ); }

sub thousand { return( shift->_set_get_prop( 'thousand', @_ ) ); }

sub unformat
{
    my $self = shift( @_ );
    my $formatted = shift( @_ );
    return( $self->error( 'unformat() can only be called on an instance of ', __PACKAGE__ ) ) unless( $self->_is_object( $self ) );
    return( $self->error( "No value to unformat was provided." ) ) if( !defined( $formatted ) );
    my $opts = $self->_get_args_as_hash( @_ );
    # require at least one digit
    unless( $formatted =~ /\d/ )
    {
        return( $self->error( "Invalid number ${formatted} (", $self->_str_val( $formatted ), ")" ) );
    }
    my $num = $formatted;

    # Regular expression for detecting decimal point
    my $decimal_point = $self->decimal->scalar;
    my $pt = qr/\Q$decimal_point\E/;

    # Detect if it ends with one of the kilo / mega / giga suffixes.
    my( $kilo, $mega, $giga, $kibi, $mebi, $gibi ) = @$self{qw( kilo_suffix mega_suffix giga_suffix kibi_suffix mebi_suffix gibi_suffix )};
    my $kp = ( $formatted =~ s/[[:blank:]\h]*($kilo|$kibi)[[:blank:]\h]*$// );
    my $mp = ( $formatted =~ s/[[:blank:]\h]*($mega|$mebi)[[:blank:]\h]*$// );
    my $gp = ( $formatted =~ s/[[:blank:]\h]*($giga|$gibi)[[:blank:]\h]*$// );
    my $mult = $self->_get_multipliers( $opts->{base} );

    # Split number into integer and decimal parts
    my( $integer, $decimal, @cruft ) = CORE::split( $pt, $formatted );
    return( $self->error( "Only one decimal separator permitted" ) ) if( @cruft );

    # It's negative if the first non-digit character is a -
    my $sign = $formatted =~ /^\D*-/ ? -1 : 1;
    my $neg_format = $self->neg_format->scalar;
    my( $before_re, $after_re ) = CORE::split( /x/, $neg_format, 2 );
    $sign = -1 if( $formatted =~ /\Q$before_re\E(.+)\Q$after_re\E/ );

    # Strip out all non-digits from integer and decimal parts
    $integer = '' unless( defined( $integer ) );
    $decimal = '' unless( defined( $decimal ) );
    $integer =~ s/\D//g;
    $decimal =~ s/\D//g;

    # Join back up, using period, and add 0 to make Perl think it's a number
    my $num2 = CORE::join( '.', $integer, $decimal ) + 0;
    $num2 = -$num2 if( $sign < 0 );

    # Scale the number if it ended in kilo or mega suffix.
    $num2 *= $mult->{kilo} if( $kp );
    $num2 *= $mult->{mega} if( $mp );
    $num2 *= $mult->{giga} if( $gp );
    $self->clear_error;
    return( $num2 );
}

# Shared with format() and format_negative()
sub _format_negative
{
    my( $self, $number, $format ) = @_;
    return( $self->error( '_format_negative() can only be called on an instance of ', __PACKAGE__ ) ) unless( $self->_is_object( $self ) );
    $format //= $self->neg_format->scalar;
    if( CORE::index( $format, 'x' ) == -1 )
    {
        return( $self->error( "Letter x must be present in picture in format_negative()" ) );
    }
    $number =~ s/^-//;
    $format =~ s/x/$number/;
    $self->clear_error;
    return( $format );
}

# _get_multipliers returns the multipliers to be used for kilo, mega,
# and giga (un-)formatting.  Used in format_bytes and unformat_number.
# For internal use only.
sub _get_multipliers
{
    my $self = shift( @_ );
    my $base = shift( @_ );
    if( !defined( $base ) || $base == 1024 )
    {
        return({
            kilo => 0x00000400,
            mega => 0x00100000,
            giga => 0x40000000
        });
    }
    elsif( $base == 1000 )
    {
        return({
            kilo => 1_000,
            mega => 1_000_000,
            giga => 1_000_000_000
        });
    }
    else
    {
        return( $self->error( "base overflow" ) ) if( $base **3 > MAX_INT );
        unless( $base > 0 && $base == CORE::int( $base ) )
        {
            return( $self->error( "base must be a positive integer" ) );
        }
        return({
            kilo => $base,
            mega => $base ** 2,
            giga => $base ** 3
        });
    }
}

# NOTE: POSIX::localeconv()->{grouping} and {mon_grouping} are not simple scalar
# integers. Per POSIX, they are byte strings where each byte indicates the size of one
# digit group, applied from the lowest order to the highest.
# Two byte values have special meaning:
#   0        repeat the previous element for the rest of the digits.
#   CHAR_MAX no further grouping is to be performed.
# CHAR_MAX is platform-dependent: on systems where char is signed it is 127 (SCHAR_MAX),
# on systems where char is unsigned it is 255 (UCHAR_MAX). We treat any value >= 127 as
# "stop grouping", which covers both cases since a legitimate group size never exceeds
# a handful of units.
# An empty string, undef, or a leading 0 byte all mean "no grouping".
sub _normalise_lconv_grouping
{
    my $self = shift( @_ );
    my $value = shift( @_ );
    return(0) if( !defined( $value ) || !CORE::length( $value ) );
    my @grouping = unpack( 'C*', $value );
    return(0) if( !scalar( @grouping ) );
    my $first = $grouping[0];
    return(0) if( !defined( $first ) || $first == 0 || $first >= 127 );
    return( $first );
}

sub _propagate_values
{
    my $self = shift( @_ );
    my $default = shift( @_ ) || return( $self->error( "No data was provided." ) );
    no warnings 'uninitialized';
    my $active_map = $self->{posix_strict} ? $map_posix_strict : $map_flexible;
    foreach my $prop ( keys( %$active_map ) )
    {
        my $ref = $active_map->{ $prop };
        # Already set by user
        next if( CORE::length( $self->{ $prop } ) );
        foreach my $lconv_prop ( @$ref )
        {
            if( CORE::defined( $default->{ $lconv_prop } ) )
            {
                # Number::Format bug RT #71044 when running on Windows
                # https://rt.cpan.org/Ticket/Display.html?id=71044
                # This is a workaround when values are lower than 0 (i.e. -1)
                if( CORE::exists( $numerics->{ $lconv_prop } ) && 
                    CORE::length( $default->{ $lconv_prop } ) && 
                    # It may be a non-numeric value which would wreak the following condition
                    $default->{ $lconv_prop } =~ /\d+/ &&
                    $default->{ $lconv_prop } < 0 )
                {
                    $default->{ $lconv_prop } = $numerics->{ $lconv_prop };
                }
                # POSIX::localeconv returned an incomplete hash and we need certain default values
                # For example a locale C.UTF-8 would only have the property decimal_point set to '.' and nothing else
                elsif( !CORE::length( $default->{ $lconv_prop } ) &&
                       CORE::exists( $numerics->{ $lconv_prop } ) )
                {
                    $default->{ $lconv_prop } = $numerics->{ $lconv_prop };
                }
                $self->$prop( $default->{ $lconv_prop } );
                last;
            }
            # Set it to undef then
            else
            {
                if( CORE::exists( $numerics->{ $lconv_prop } ) )
                {
                    $default->{ $lconv_prop } = $numerics->{ $lconv_prop };
                }
                $self->$prop( $default->{ $lconv_prop } );
            }
        }
    }
    return( $self );
}

sub _round
{
    my( $self, $num, $precision ) = @_;
    $self->clear_error;
    return( CORE::sprintf( '%.*f', $precision, $num ) );
}

sub _set_get_prop
{
    my $self = shift( @_ );
    my $prop = shift( @_ );
    return( $self->error( "${prop}() can only be called on an instance of ", __PACKAGE__ ) ) unless( $self->_is_object( $self ) );
    if( @_ )
    {
        my $val = shift( @_ );
        # $val = $val->scalar if( $self->_is_object( $val ) && $val->isa( 'Module::Generic::Scalar' ) );
        $val = "$val" if( CORE::defined( $val ) );
        # I do not want to set a default value of '' to $self->{ $prop } because if its value is undef, it should remain so
        no warnings 'uninitialized';
        if( !CORE::defined( $val ) || ( CORE::defined( $val ) && $val ne $self->{ $prop } ) )
        {
            $self->_set_get_scalar_as_object( $prop, $val );
            # If an error was set, we return nothing
            # $self->formatter( $self->new_formatter ) || return;
        }
    }
    $self->clear_error;
    return( $self->_set_get_scalar_as_object( $prop ) );
}

sub FREEZE
{
    my $self       = CORE::shift( @_ );
    my $serialiser = CORE::shift( @_ ) // '';
    my $class      = CORE::ref( $self );

    # We keep a strict allow-list to avoid accidentally freezing DBI handles or other
    # process-local state.
    my @props = ( @{$self->{_fields}}, keys( %$map ) );

    my $hash = {};
    foreach my $prop ( @props )
    {
        if( CORE::exists( $self->{ $prop } ) &&
            defined( $self->{ $prop } ) &&
            CORE::ref( $self->{ $prop } ) ne 'CODE' )
        {
            $hash->{ $prop } = $self->{ $prop };
        }
    }

    # Return an array reference rather than a list so this works with Sereal and CBOR.
    # On or before Sereal version 4.023, Sereal did not support multiple values returned.
    if( $serialiser eq 'Sereal' )
    {
        require Sereal::Encoder;
        require version;

        if( version->parse( Sereal::Encoder->VERSION ) <= version->parse( '4.023' ) )
        {
            CORE::return( [$class, $hash] );
        }
    }

    # But Storable wants a list with the first element being the serialised element
    CORE::return( $class, $hash );
}

sub STORABLE_freeze { CORE::return( CORE::shift->FREEZE( @_ ) ); }

sub STORABLE_thaw { CORE::return( CORE::shift->THAW( @_ ) ); }

# NOTE: CBOR will call the THAW method with the stored classname as first argument, the constant string CBOR as second argument, and all values returned by FREEZE as remaining arguments.
# NOTE: Storable calls it with a blessed object it created followed with $cloning and any other arguments initially provided by STORABLE_freeze
sub THAW
{
    my( $self, undef, @args ) = @_;
    my $ref = ( CORE::scalar( @args ) == 1 && CORE::ref( $args[0] ) eq 'ARRAY' ) ? CORE::shift( @args ) : \@args;
    my $class = ( CORE::defined( $ref ) && CORE::ref( $ref ) eq 'ARRAY' && CORE::scalar( @$ref ) > 1 ) ? CORE::shift( @$ref ) : ( CORE::ref( $self ) || $self );
    my $hash = CORE::ref( $ref ) eq 'ARRAY' ? CORE::shift( @$ref ) : {};
    my $new;
    # Storable pattern requires to modify the object it created rather than returning a new one
    if( CORE::ref( $self ) )
    {
        foreach( CORE::keys( %$hash ) )
        {
            $self->{ $_ } = CORE::delete( $hash->{ $_ } );
        }
        $new = $self;
    }
    else
    {
        $new = CORE::bless( $hash => $class );
    }
    CORE::return( $new );
}

sub TO_JSON { return( shift->as_number ); }


1;
# NOTE: POD
__END__

=encoding utf-8

=head1 NAME

Module::Generic::Number::Format - Locale-aware number formatting for Module::Generic::Number

=head1 SYNOPSIS

    use Module::Generic::Number::Format;

    # Direct instantiation
    my $fmt = Module::Generic::Number::Format->new( 1234567.89 ) ||
        die( Module::Generic::Number::Format->error );
    # or
    my $n = Module::Generic::Number::Format->new( 10, 
    {
        thousand => ',',
        decimal => '.',
        precision => 2,
        # Currency symbol
        symbol => '€',
        # Display currency symbol before or after the number
        precede => 1,
    });
    # Even accepts numbers in Japanese double bytes
    # Will be converted automatically to regular digits.
    my $n = Moule::Generic::Number::Format->new( "−１２３４５６７" ); # becomes -1234567
    # or, to get all the defaults based on language code
    my $n = Module::Generic::Number::Format->new( 1234567.89, 
    {
        lang => 'fr_FR',
        # or
        # locale => 'fr_FR',
    });
    # this would set the decimal separator to ',', the thousand separator to ' ', and precede to 0 (false).
    print( "Number is: $n\n" );
    # prints: 1 234 567,89

    my $n_neg = Module::Generic::Number::Format->new(-10);
    $n_neg->abs # 10
    $n->clone # Cloning the number object
    $n->currency # €
    $n->decimal # .
    $n->format # 1,000.00
    $n->format(0) # 1,000
    $n->format(
        precision => 0,
        # Boolean value
        decimal_fill => 0,
        thousand => ',',
        decimal => '.',
    );
    $n->format_binary # 1111101000
    my $n2 = $n->clone;
    $n2->format_bytes # 1K
    $n2->format_hex # 0x400
    $n2->format_money # € 1,024.00
    $n2->format_money( '$' ) # $1,024.00

    # General formatting
    say $fmt->format(2);      # "1,234,567.89"
    say $fmt->format_money;   # "€1,234,567.89" (locale-dependent)
    say $fmt->format_bytes;   # "1.18 GiB" (auto-scaled)
    say $fmt->format_binary;  # "100101101110000011010001011"
    say $fmt->format_hex;     # "0x12D687"

    # format_money() follows the monetary category (LC_MONETARY), independently from
    # format() which follows the numeric category (LC_NUMERIC). Under posix_strict
    # (true by default), the two can therefore be grouped differently:
    my $m = Module::Generic::Number::Format->new( 1281284,
    {
        precision    => 2,
        grouping     => 0,     # numeric: no grouping
        mon_grouping => 3,     # monetary: grouped by 3
        mon_thousand => ',',
        mon_decimal  => '.',
        symbol       => '€',
        precede      => 0,
        space_pos    => 0,
    });
    $m->format       # 1281284.00
    $m->format_money # 1,281,284.00€

    # Set posix_strict to false to fill a value absent from one category from the
    # sibling category (the previous, more tolerant resolution).
    my $loose = Module::Generic::Number::Format->new( 1000, { posix_strict => 0 } );

    $n2->format_negative # -1,024.00
    $n2->format_picture( '(x)' ) # (1,024.00)
    $n->from_binary( "1111101000" ) # 1000
    $n->from_hex( "0x400" ) # 1000

    # Change position of the currency sign
    $n->precede(1) # Set it to precede the number
    # Change precision
    $n->precision(0)

    $n->symbol # €

    $n->thousand # ,
    $n->unformat( "€ 1,024.00" ) # 1024

    # Rounding
    say $fmt->round(1);       # formatter with 1234567.9
    say $fmt->round2(2);      # formatter with 1234567.89 (high-precision)
    say $fmt->round_zero;     # formatter with 1234568 (ties away from zero)

    # Reverse: strip formatting back to a raw number
    my $raw = $fmt->unformat( '€ 1.234.567,89' );

    # Changing locale at any time
    $fmt->set_locale( 'ja_JP' );

    # Accessed indirectly via Module::Generic::Number (lazy-loaded)
    use Module::Generic::Number;
    my $n = Module::Generic::Number->new(42);
    say $n->format(0);  # "42", triggers lazy load of this module

=head1 VERSION

    v0.1.1

=head1 DESCRIPTION

C<Module::Generic::Number::Format> is the formatting companion to L<Module::Generic::Number>. It is never loaded unless a formatting operation is actually requested, so that plain numeric objects such as line-number or offset counters remain lightweight. See L<Module::Generic::Number/format> for details of the lazy-loading mechanism.

This class inherits from L<Module::Generic> and holds all state related to locale, monetary symbols, decimal separators, digit grouping, suffix strings for byte formatting, and the corresponding formatting algorithms.

=head2 Design

The class is instantiated internally by L<Module::Generic::Number> via its C<_get_formatter> and C<_instantiate_format> private methods. It can also be used directly when formatting is the primary concern and the overhead of the full numeric object is not needed.

On construction, C<init()> queries C<POSIX::setlocale(LC_ALL)> and C<POSIX::localeconv()> to populate all formatting properties from the active system locale. An explicit C<locale> (or C<lang>) option overrides this. All sixteen formatting properties can subsequently be overridden individually via their accessor methods, or reset in one call via L</set_locale>.

=head2 Thread Safety

When Perl is built with thread support (C<$Config{useithreads}>), calls that temporarily alter C<LC_ALL> to probe a requested locale are guarded by a shared lock (C<$LOCALE_LOCK>). The lock is always released before the method returns, so the system locale is never left in a modified state.

=head1 CONSTRUCTOR

=head2 new

    my $fmt = Module::Generic::Number::Format->new( $number ) ||
        die( Module::Generic::Number::Format->error );

    my $fmt = Module::Generic::Number::Format->new( $number, %options ) ||
        die( Module::Generic::Number::Format->error );

Creates a new formatter for C<$number>. C<$number> must be a defined, non-empty scalar that represents a finite numeric value. Infinity and NaN values are rejected.

Any key-value pairs after C<$number> are forwarded to C<init()>. The most useful option is C<locale> (or its alias C<lang>), which selects the locale to use for formatting properties. Without it, the active system locale is used.

On success, returns the formatter object. On failure, it sets the class-level error, and returns C<undef> in scalar context, or an empty list in list context.

=head1 METHODS

=head2 as_hash

    my $self = $fmt->as_hash;

Returns the object itself. C<Module::Generic::Number::Format> does not serialise to a plain hash; this method satisfies the C<Module::Generic> API contract.

=head2 as_number

Inherited from L<Module::Generic>. Returns the underlying numeric value as a plain Perl number (equivalent to C<< $fmt->{_number} + 0 >>).

=head2 as_string

    my $str = $fmt->as_string;

Returns the internal C<_number> value as a plain string without any formatting applied.

=head2 clone

    my $fmt2 = $fmt->clone;
    my $fmt2 = $fmt->clone( $other_number );

Returns a deep copy of the formatter. If C<$other_number> is supplied, the clone's C<_number> is set to that value instead of the original's. Infinity and NaN are rejected.

=head2 currency

    my $symbol = $fmt->currency;
    $fmt->currency( '¥' );

Alias for L</symbol>. Gets or sets the currency symbol used by L</format_money>.

=head2 decimal

    my $sep = $fmt->decimal;
    $fmt->decimal( ',' );

Gets or sets the decimal point character for non-monetary formatting.

Returns a L<Module::Generic::Scalar> object.

=head2 decimal_fill

    my $bool = $fmt->decimal_fill;
    $fmt->decimal_fill(1);

Gets or sets the boolean flag that controls whether trailing zeroes are added to the decimal part to pad it to the requested precision. Defaults to C<0>.

When set to C<1>, C<format(2)> on the value C<3.1> produces C<"3.10"> instead of C<"3.1">.

=head2 decode_lconv

    my $decoded = $fmt->decode_lconv( $lconv_hashref );

Decodes byte strings inside a hash reference returned by C<POSIX::localeconv()> from the locale-native byte encoding (as reported by C<I18N::Langinfo::CODESET>) to Perl's internal UTF-8. The C<grouping> and C<mon_grouping> keys, which are packed byte strings rather than text, are skipped.

Returns the hash reference with the decoded values in place, or C<undef> on error.

=head2 default

    my $href = $fmt->default;
    $fmt->default( \%new_lconv );

Gets or sets the hash reference used as the source of locale data when populating formatting properties. By default this is the built-in C<$DEFAULT> hash, which provides conservative, POSIX-compatible values. It is replaced by C<POSIX::localeconv()>'s output during C<init()> or C<set_locale()>.

=head2 encoding

    my $enc = $fmt->encoding;
    $fmt->encoding( 'ISO-8859-1' );

Gets or sets the character encoding used by L</decode_lconv> when converting byte strings from C<POSIX::localeconv()>. Defaults to C<utf-8>.

=head2 format

    my $str = $fmt->format;
    my $str = $fmt->format( $precision );
    my $str = $fmt->format( precision => 2, thousand => ',', decimal => '.' );
    my $str = $fmt->format( precision => 2, decimal_fill => 1, grouping => 3 );
    $n->format(
        precision    => 2,
        # Override object value
        thousand     => ',',
        decimal      => '.',
        # Boolean
        decimal_fill => 1,
    );

Formats the stored number with digit grouping (thousands separators) and decimal rounding.

If the number is too large or great to work with as a regular number, but instead must be shown in scientific notation (such as C<"1.23e+45">), returns that number in scientific notation without further formatting.

    Module::Generic::Number->new("0.000020000E+00")->format(7); # 2e-05

It returns a L<scalar object|Module::Generic::Scalar> upon success, or sets an L<error|Module::Generic/error> and returns C<undef> in scalar context or an empty list in list context if an error occurred.

C<$precision> (integer) controls the number of decimal places. If omitted, the value of L</precision> is used.

Named options override the corresponding instance properties for this call only:

=over 4

=item C<precision>

Number of decimal digits. Defaults to L</precision>.

=item C<thousand>

Thousands separator. Defaults to L</thousand>.

=item C<decimal>

Decimal point character. Defaults to L</decimal>.

=item C<decimal_fill>

Boolean. When true, the decimal part is padded with trailing zeroes to C<$precision> digits. Defaults to L</decimal_fill>.

=item C<grouping>

Digit group size (typically C<3>). Defaults to L</grouping>, or C<3> if that is not set.

=back

=head2 format_binary

    # Assuming the number object is 1000
    $n->format_binary # 1111101000

Returns a L<Module::Generic::Scalar> containing the stored number expressed in binary (base 2) notation, using C<sprintf '%b'>. No locale formatting is applied.

=head2 format_bytes

    # Assuming the number object is 1,234,567
    $n->format_bytes # 1.18M

    my $str = $fmt->format_bytes( precision => 2, mode => 'iec60027' );
    my $str = $fmt->format_bytes( unit => 'M', base => 1000 );

Provided with an hash or hash reference of options, and the stored number as a human-readable byte count with an appropriate SI or IEC suffix, such as K, M or G depending if it exceeds gigabytes, megabytes or kilobytes; or the IEC
standard 60027 C<KiB>, C<MiB>, or C<GiB> depending on the option C<mode>

It returns a L<scalar object|Module::Generic::Scalar> upon success or an L<error|Module::Generic/error> if an error occurred.

The number must be non-negative.

Named options:

=over 4

=item C<base>

The multiplier base. Defaults to C<1024>. Use C<1000> for SI-decimal sizes.
Any positive integer is accepted, provided C<$base ** 3> does not overflow a 53-bit mantissa.

If the mode (see below) is set to C<iec> or C<iec60027> then setting the C<base> option returns an error.

=item C<mode>

Either C<traditional> (the default) or C<iec60027> (or the abbreviation C<iec>). Traditional mode uses the L</kilo_suffix>, L</mega_suffix>, and L</giga_suffix> strings (default: C<K>, C<M>, C<G>). IEC 60027 mode uses L</kibi_suffix>, L</mebi_suffix>, and L</gibi_suffix> (default: C<KiB>, C<MiB>, C<GiB>). The C<base> option is not permitted in IEC mode.

=item C<precision>

Number of decimal places in the result. Defaults to L</precision>, or C<2>.

=item C<unit>

By default, this is guessed based on the value of the number, but can be explicitly specified here.

In other words, numbers greater than or equal to 1024 (or other number given by the C<base> option) will be divided by 1024 and suffix set with L</kilo_suffix> or L</kibi_suffix> added; if greater than or equal to 1048576 (1024*1024), it will be divided by 1048576 and suffix set with L</mega_suffix> or L</mebi_suffix> appended to the end; etc.

Possible values are: C<auto> (default), C<kilo>, C<mega>, C<giga>

If a value other than C<auto> is specified, that value will be used instead no matter the number. For example:

    Module::Generic::Number->new( 1048576 )->format_bytes( unit => 'k' );
    # Produces 1,024K and not 1M

=back

=head2 format_hex

    # Assuming the number object is 1000
    $n->format_hex # 0x3E8

Returns a L<Module::Generic::Scalar> containing the stored number expressed in uppercase hexadecimal with a C<0x> prefix (C<sprintf '0x%X'>). No locale formatting is applied.

=head2 format_money

Provided with an optional precision, and an optional currency symbol and this format the number accordingly.
It uses the object initial value set with L</precision> and L</currency> if not explicitly specified.
object, using the inital format parameters specified during object instantiation.

    # Assuming the number object is 1000
    $n->format_money # € 1,000.00
    $n->format_money(3) # € 1,000.000

The digit grouping, thousand separator and decimal separator are taken from the monetary trio (L</mon_grouping>, L</mon_thousand>, L</mon_decimal>), which follows the C<LC_MONETARY> category of the locale. Under L</posix_strict> (the default), this is independent from the plain number formatting used by L</format>, so on a mixed locale such as C<LC_NUMERIC=C> with C<LC_MONETARY=en_US.UTF-8>, money is grouped even though a plain number is not. The currency symbol and sign placement always follow the monetary category.

The sign and symbol placement (before or after the value, with or without a space) follow the POSIX locale properties accessed via L</position_pos>, L</position_neg>, L</precede>, L</precede_neg>, L</space_pos>, L</space_neg>, L</sign_pos>, and L</sign_neg>.

It returns a L<scalar object|Module::Generic::Scalar> upon success or an L<error|Module::Generic/error> if an error occurred.

=head2 format_negative

    my $str = $fmt->format_negative;
    my $str = $fmt->format_negative( '(x)' );
    $n->format_negative( '(x)' ); # (1,000)

Formats the stored number (formatted with default precision) using a negative format picture. The picture must contain the letter C<x>, which is replaced by the absolute formatted value. For example, a picture of C<-x> produces C<-1,234.56>, while C<(x)> produces C<(1,234.56)>. If no picture is supplied, the value of L</neg_format> is used.

It returns a L<scalar object|Module::Generic::Scalar> upon success or an L<error|Module::Generic/error> if an error occurred.

=head2 format_picture

    $n->format_picture( '##,###.##' ); # 1,000.00
    my $str = $fmt->format_picture( picture => '#,###.##' );

Formats the stored number against a picture template. Returns a L<Module::Generic::Scalar>. The picture uses C<#> as a digit placeholder; any other character in the picture is kept as-is. The decimal point in the picture must match L</decimal>.

If the integer part of the number is too large to fit in the available C<#> positions, all C<#> characters are replaced with C<*> and the overflow picture is returned.

For examples:

    # Assuming 100023
    $n->format_picture( 'EUR ##,###.##' ); # EUR **,***.**
    # Assuming 1.00023
    $n->format_picture( 'EUR #.###,###' ); # EUR 1.002,300

Leading zeroes in the integer part are stripped. The sign prefix, if any, is repositioned to the left of any non-digit prefix character.

The comma C<,> and period C<.> used in the example above are taken from the value set with L</thousand> and L</decimal> respectively.
However, the C<thousand> characters in the C<picture> provided, does not need to occur every three digits; the
I<only> use of that variable by this function is to remove leading commas (see the first example above).

There may not be more than one instance of C<decimal> in the C<picture> provided though, or an error will be returned.

It returns a L<scalar object|Module::Generic::Scalar> upon success or an L<error|Module::Generic/error> if an error occurred.

=head2 gibi_suffix

    my $s = $fmt->gibi_suffix;
    $fmt->gibi_suffix( 'GiB' );

Gets or sets the IEC gibibyte suffix used by L</format_bytes> in C<iec60027> mode. Defaults to C<GiB>.

=head2 giga_suffix

    my $s = $fmt->giga_suffix;
    $fmt->giga_suffix( 'G' );

Gets or sets the gigabyte suffix used by L</format_bytes> in C<traditional> mode. Defaults to C<G>.

=head2 grouping

    my $n = $fmt->grouping;
    $fmt->grouping(3);

Gets or sets the digit group size (the number of digits between thousands separators). Sourced from C<< POSIX::localeconv()->{grouping} >>. Defaults to C<3>. Returns a L<Module::Generic::Scalar> object.

=head2 kibi_suffix

    my $s = $fmt->kibi_suffix;
    $fmt->kibi_suffix( 'KiB' );

Gets or sets the IEC kibibyte suffix used by L</format_bytes> in C<iec60027> mode. Defaults to C<KiB>.

=head2 kilo_suffix

    my $s = $fmt->kilo_suffix;
    $fmt->kilo_suffix( 'K' );

Gets or sets the kilobyte suffix used by L</format_bytes> in C<traditional> mode. Defaults to C<K>.

=head2 lang

    my $loc = $fmt->lang;
    $fmt->lang( 'fr_FR' );

Gets or sets the locale string. This is an alias of L</locale>; they both access the same underlying C<lang> field. Setting this value does B<not> automatically re-read C<POSIX::localeconv()>; use L</set_locale> for that.

Returns a L<Module::Generic::Scalar> object.

=head2 locale

Alias of L</lang>.

=head2 mebi_suffix

    my $s = $fmt->mebi_suffix;
    $fmt->mebi_suffix( 'MiB' );

Gets or sets the IEC mebibyte suffix used by L</format_bytes> in C<iec60027> mode. Defaults to C<MiB>.

=head2 mega_suffix

    my $s = $fmt->mega_suffix;
    $fmt->mega_suffix( 'M' );

Gets or sets the megabyte suffix used by L</format_bytes> in C<traditional> mode. Defaults to C<M>.

=head2 mon_decimal

    my $sep = $fmt->mon_decimal;
    $fmt->mon_decimal( ',' );

Gets or sets the decimal point character specifically for monetary formatting (sourced from C<< POSIX::localeconv()->{mon_decimal_point} >>). Falls back to L</decimal> when empty.

Returns a L<Module::Generic::Scalar> object.

=head2 mon_grouping

    my $n = $fmt->mon_grouping;
    $fmt->mon_grouping(3);

Gets or sets the digit group size for monetary formatting (sourced from C<< POSIX::localeconv()->{mon_grouping} >>). Falls back to L</grouping> when empty.

Returns a L<Module::Generic::Scalar> object.

=head2 mon_thousand

    my $sep = $fmt->mon_thousand;
    $fmt->mon_thousand( '.' );

Gets or sets the thousands separator for monetary formatting (sourced from C<< POSIX::localeconv()->{mon_thousands_sep} >>). Falls back to L</thousand> when empty.

Returns a L<Module::Generic::Scalar> object.

=head2 neg_format

    my $fmt_str = $fmt->neg_format;
    $fmt->neg_format( '(x)' );

Gets or sets the picture string used by L</format_negative> and L</unformat> to represent negative numbers. The picture must contain exactly one C<x>, which stands for the absolute formatted value. Common values are C<-x> (the default) and C<(x)>.

Returns a L<Module::Generic::Scalar> object.

=head2 posix_strict

    my $bool = $fmt->posix_strict;
    $fmt->posix_strict(1);

Gets or sets the boolean that controls which locale property map is used when populating formatting properties from C<POSIX::localeconv()>. When true (the default), the strict POSIX map is used, which does not fall back across numeric and monetary properties. When false, a flexible map is used that allows cross-category fallbacks (for example, C<decimal_point> falling back to C<mon_decimal_point> when the numeric value is empty).

=head2 position_neg

    my $n = $fmt->position_neg;
    $fmt->position_neg(1);

Gets or sets the position of the sign symbol (typically "-") relative to the currency symbol and value for negative monetary amounts. Corresponds to C<< POSIX::localeconv()->{n_sign_posn} >>. Accepted values:

=over 4

=item C<0>

Parentheses surround the entire string.

=item C<1>

Sign appears before the string.

=item C<2>

Sign appears after the string.

=item C<3>

Sign appears immediately before the currency symbol.

=item C<4>

Sign appears immediately after the currency symbol.

=back

Returns a L<Module::Generic::Scalar> object.

=head2 position_pos

    my $n = $fmt->position_pos;
    $fmt->position_pos(1);

Gets or sets the sign (typically "", i.e. empty, but could be set to "+") position for non-negative monetary values. Corresponds to C<< POSIX::localeconv()->{p_sign_posn} >>. See L</position_neg> for the accepted values. Returns a L<Module::Generic::Scalar> object.

=head2 precede

    my $bool = $fmt->precede;
    $fmt->precede(1);

Gets or sets whether the currency symbol precedes (C<1>) or follows (C<0>) the value for non-negative monetary amounts. Corresponds to C<<POSIX::localeconv()->{p_cs_precedes} >>. Returns a L<Module::Generic::Scalar> object.

=head2 precede_neg

    my $bool = $fmt->precede_neg;
    $fmt->precede_neg(1);

Gets or sets whether the currency symbol precedes or follows the value for negative monetary amounts. Corresponds to C<< POSIX::localeconv()->{n_cs_precedes} >>. Returns a L<Module::Generic::Scalar> object.

=head2 precede_pos

Alias for L</precede>.

=head2 precision

    # Assuming $n is an object for 3.14159265358979323846
    $n->precision(4);
    $n->format # 3.1416

    my $n = $fmt->precision;
    $fmt->precision(2);

Gets or sets the number of decimal digits used by L</format> and L</format_money> when no explicit precision argument is supplied. Sourced from C<< POSIX::localeconv()->{frac_digits} >>. Returns a L<Module::Generic::Scalar> object.

=head2 round

    my $fmt2 = $fmt->round( $precision );

Returns a new C<Module::Generic::Number::Format> with the stored number rounded to C<$precision> decimal places using C<sprintf '%.*f'>. C<$precision> must be a non-negative integer. On success, returns the new formatter. On failure, returns C<undef> and sets the error.

=head2 round_zero

    my $fmt2 = $fmt->round_zero;

This will round the number using L<POSIX/round>, which will return "the integer (but still as floating point) nearest to the argument"

Returns a new formatter with the stored number as an "integer (but still as floating point) nearest to the argument", with ties rounded away from zero (C<POSIX::round()> semantics). On Perl 5.22 and later, delegates to C<POSIX::round()>. On earlier versions, the result is computed as C<int( abs($n) + 0.5 )> with the original sign reapplied.

=head2 round2

    my $fmt2 = $fmt->round2( $precision );

Returns a new formatter with the stored number rounded to C<$precision> decimal places using a multiplier-based algorithm that avoids the floating-point artefacts common with C<sprintf>. C<$precision> must be a non-negative integer. Supports C<Math::BigFloat> values. Returns C<undef> and sets the error if the intermediate product would overflow a 53-bit mantissa; in that case, use a smaller precision or switch to C<Math::BigFloat>.

=head2 set_locale

    my $locale_str = $fmt->set_locale( 'fr_FR' );
    my $locale_str = $fmt->set_locale( 'ja_JP.UTF-8' );

Changes the formatter's locale and updates all formatting properties to match the new locale. Returns the canonical locale string that was accepted by C<POSIX::setlocale()>, or C<undef> on error.

The method temporarily changes C<LC_ALL> to the requested locale in order to call C<POSIX::localeconv()>, then restores C<LC_ALL> to its original value before returning, so the process locale is never left in a modified state.

If a bare language code such as C<fr_FR> is supplied (no encoding suffix), the method tries it as-is first, then iterates over the known encoding variants in C<$SUPPORTED_LOCALES> (such as C<fr_FR.UTF-8>, C<fr_FR.ISO-8859-1>, etc.) until one is accepted by the system.

On failure, the method returns C<undef> and sets the error to a descriptive message. It does not partially update formatting properties; the call either succeeds completely or leaves the formatter unchanged.

=head2 sign_neg

    my $s = $fmt->sign_neg;
    $fmt->sign_neg( '-' );

Gets or sets the sign character used to denote negative currency values, usually a minus sign.
Corresponds to C<< POSIX::localeconv()->{negative_sign} >>.

Returns a L<Module::Generic::Scalar> object.

=head2 sign_pos

    my $s = $fmt->sign_pos;
    $fmt->sign_pos( '+' );

Gets or sets the sign character used to denote non-negative currency values, usually the empty string.
Corresponds to C<< POSIX::localeconv()->{positive_sign} >>. Typically the empty string.

Returns a L<Module::Generic::Scalar> object.

=head2 space_neg

    my $n = $fmt->space_neg;
    $fmt->space_neg(0);

Gets or sets the spacing rule between the sign or currency symbol and the value for negative monetary amounts. Corresponds to C<< POSIX::localeconv()->{n_sep_by_space} >>. Accepted values:

=over 4

=item C<0>

No space between symbol and value.

=item C<1>

Space between symbol and value, no space between sign and symbol.

=item C<2>

Space between sign and symbol, no space between symbol and value.

=back

Returns a L<Module::Generic::Scalar> object.

=head2 space_pos

    my $n = $fmt->space_pos;
    $fmt->space_pos(0);

Gets or sets the spacing rule for non-negative monetary amounts. Corresponds to C<< POSIX::localeconv()->{p_sep_by_space} >>. See L</space_neg> for the accepted values.

Returns a L<Module::Generic::Scalar> object.

=head2 symbol

    my $sym = $fmt->symbol;
    $fmt->symbol( '¥' );

Gets or sets the currency symbol used by L</format_money>. Sourced from C<< POSIX::localeconv()->{currency_symbol} >>. The method C<currency> is an alias. Returns a L<Module::Generic::Scalar> object.

=head2 thousand

    my $sep = $fmt->thousand;
    $fmt->thousand( '.' );

Gets or sets the thousands separator for non-monetary formatting. Sourced from C<< POSIX::localeconv()->{thousands_sep} >>. Returns a L<Module::Generic::Scalar> object.

=head2 unformat

    my $fmt2 = $fmt->unformat( '1.234.567,89' );
    my $fmt2 = $fmt->unformat( '1.2 M', base => 1000 );

    my $n = Module::Generic::Number::Format->unformat('USD 12.95'); # 12.95
    # Same
    my $n = $n1->unformat('USD 12.95'); # 12.95
    my $n = Module::Generic::Number::Format->unformat('USD 12.00'); # 12
    my $n = Module::Generic::Number::Format->unformat('foobar'); # return error (undef)
    my $n = Module::Generic::Number::Format->unformat('1234-567@.8'); # 1234567.8

Strips locale-specific formatting from a number string and returns a new formatter whose C<_number> is set to the resulting raw numeric value.

The method recognises the current L</decimal>, L</neg_format>, and the kilo, mega, and giga suffix strings (both traditional and IEC variants). Numbers that end with a suffix are multiplied by the corresponding multiplier (see L</format_bytes> for the C<base> option). Only one decimal separator is permitted; the presence of more than one is an error.

It returns an L<error|Module::Generic/error> if the string provided does not contain any number.

=head1 SERIALISATION

=for Pod::Coverage FREEZE

=for Pod::Coverage STORABLE_freeze

=for Pod::Coverage STORABLE_thaw

=for Pod::Coverage THAW

The class implements C<FREEZE> / C<THAW> for L<Sereal> and L<CBOR::XS>, and C<STORABLE_freeze> / C<STORABLE_thaw> for L<Storable>. Only the fields listed in C<_fields> plus the formatting property keys are preserved; code references, DBI handles, and other process-local state are excluded. The C<TO_JSON> method returns the raw number so that JSON serialisers produce a numeric value rather than a stringified object.

=head1 SUPPORTED LOCALES

The package variable C<$Module::Generic::Number::Format::SUPPORTED_LOCALES> is a hash reference mapping bare locale codes (such as C<fr_FR>) to an array of known encoding variants in decreasing order of preference (such as C<fr_FR.UTF-8>, C<fr_FR.ISO-8859-1>, C<fr_FR.ISO8859-1>). It covers several hundred locales commonly found on Linux and macOS systems.

This table is used only when a bare code without an encoding suffix is supplied to L</set_locale> and the code is not accepted as-is by C<POSIX::setlocale()>.

=head1 DEPENDENCIES

L<Module::Generic>, L<POSIX> (core), L<Scalar::Util> (core), L<Encode> (core), L<I18N::Langinfo> (core).

Optional: L<threads> and L<threads::shared> (used automatically when the Perl interpreter was built with thread support).

=head1 SEE ALSO

L<Module::Generic::Number>: the lightweight numeric object that uses this module for formatting via lazy loading.

L<Module::Generic>: the base class providing error handling, accessor helpers, and object infrastructure.

L<POSIX>: C<setlocale()> and C<localeconv()> for locale data.

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 COPYRIGHT & LICENCE

Copyright (c) 2026 DEGUEST Pte. Ltd.

You can use, copy, modify and redistribute this package and associated files under the same terms as Perl itself.

=cut
