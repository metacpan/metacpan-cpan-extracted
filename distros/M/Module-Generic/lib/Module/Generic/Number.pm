##----------------------------------------------------------------------------
## Module Generic - ~/lib/Module/Generic/Number.pm
## Version v1.2.0
## Copyright(c) 2022 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2021/03/20
## Modified 2022/07/18
## All rights reserved
## 
## This program is free software; you can redistribute  it  and/or  modify  it
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
package Module::Generic::Number;
BEGIN
{
    use v5.26.1;
    use strict;
    use warnings;
    use parent qw( Module::Generic );
    use warnings::register;
    use vars qw( $SUPPORTED_LOCALES $DEFAULT );
    # use Devel::Confess;
    use Number::Format;
    use Nice::Try;
    use POSIX qw( Inf NaN );
    use Regexp::Common qw( number );
    use Scalar::Util ();
    use overload (
        # I know there is the nomethod feature, but I need to provide return_object set to true or false
        # And I do not necessarily want to catch all the operation.
        '""' => sub { return( shift->{_number} ); },
        '-' => sub { return( shift->compute( @_, { op => '-', return_object => 1 }) ); },
        '+' => sub { return( shift->compute( @_, { op => '+', return_object => 1 }) ); },
        '*' => sub { return( shift->compute( @_, { op => '*', return_object => 1 }) ); },
        '/' => sub { return( shift->compute( @_, { op => '/', return_object => 1 }) ); },
        '%' => sub { return( shift->compute( @_, { op => '%', return_object => 1 }) ); },
        # Exponent
        '**' => sub { return( shift->compute( @_, { op => '**', return_object => 1 }) ); },
        # Bitwise AND
        '&' => sub { return( shift->compute( @_, { op => '&', return_object => 1 }) ); },
        # Bitwise OR
        '|' => sub { return( shift->compute( @_, { op => '|', return_object => 1 }) ); },
        # Bitwise XOR
        '^' => sub { return( shift->compute( @_, { op => '^', return_object => 1 }) ); },
        # Bitwise shift left
        '<<' => sub { return( shift->compute( @_, { op => '<<', return_object => 1 }) ); },
        # Bitwise shift right
        '>>' => sub { return( shift->compute( @_, { op => '>>', return_object => 1 }) ); },
        'x' => sub { return( shift->compute( @_, { op => 'x', return_object => 1, type => 'scalar' }) ); },
        '+=' => sub { return( shift->compute( @_, { op => '+=', return_object => 1 }) ); },
        '-=' => sub { return( shift->compute( @_, { op => '-=', return_object => 1 }) ); },
        '*=' => sub { return( shift->compute( @_, { op => '*=', return_object => 1 }) ); },
        '/=' => sub { return( shift->compute( @_, { op => '/=', return_object => 1 }) ); },
        '%=' => sub { return( shift->compute( @_, { op => '%=', return_object => 1 }) ); },
        '**=' => sub { return( shift->compute( @_, { op => '**=', return_object => 1 }) ); },
        '<<=' => sub { return( shift->compute( @_, { op => '<<=', return_object => 1 }) ); },
        '>>=' => sub { return( shift->compute( @_, { op => '>>=', return_object => 1 }) ); },
        'x=' => sub { return( shift->compute( @_, { op => 'x=', return_object => 1 }) ); },
        # '.=' => sub { return( shift->compute( @_, { op => '.=', return_object => 1 }) ); },
        '.=' => sub
        {
            my( $self, $other, $swap ) = @_;
            my $op = '.=';
            no strict;
            my $operation = $swap ? "${other} ${op} \$self->{_number}" : "\$self->{_number} ${op} ${other}";
            my $res = eval( $operation );
            warn( "Error with formula \"$operation\": $@" ) if( $@ && $self->_warnings_is_enabled );
            return if( $@ );
            # Concatenated something. If it still look like a number, we return it as an object
            if( $res =~ /^$RE{num}{real}$/ )
            {
                return( $self->clone( $res ) );
            }
            # Otherwise we pass it to the scalar module
            else
            {
                return( Module::Generic::Scalar->new( "$res" ) );
            }
        },
        '<' => sub { return( shift->compute( @_, { op => '<', boolean => 1 }) ); },
        '<=' => sub { return( shift->compute( @_, { op => '<=', boolean => 1 }) ); },
        '>' => sub { return( shift->compute( @_, { op => '>', boolean => 1 }) ); },
        '>=' => sub { return( shift->compute( @_, { op => '>=', boolean => 1 }) ); },
        '<=>' => sub { return( shift->compute( @_, { op => '<=>', return_object => 0 }) ); },
        '==' => sub { return( shift->compute( @_, { op => '==', boolean => 1 }) ); },
        '!=' => sub { return( shift->compute( @_, { op => '!=', boolean => 1 }) ); },
        'eq' => sub { return( shift->compute( @_, { op => 'eq', boolean => 1 }) ); },
        'ne' => sub { return( shift->compute( @_, { op => 'ne', boolean => 1 }) ); },
        '++' => sub
        {
            my( $self ) = @_;
            return( ++$self->{_number} );
        },
        '--' => sub
        {
            my( $self ) = @_;
            return( --$self->{_number} );
        },
        'fallback' => 1,
    );
    our( $VERSION ) = 'v1.2.0';
};

# use strict;
no warnings 'redefine';
# require Module::Generic::Array;
# require Module::Generic::Boolean;
# require Module::Generic::Scalar;

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

$DEFAULT =
{
## The local currency symbol.
currency_symbol     => '€',
## The decimal point character, except for currency values, cannot be an empty string
decimal_point       => '.',
## The number of digits after the decimal point in the local style for currency values.
frac_digits         => 2,
## The sizes of the groups of digits, except for currency values. unpack( "C*", $grouping ) will give the number
grouping            => (CORE::chr(3) x 2),
## The standardized international currency symbol.
int_curr_symbol     => '€',
## The number of digits after the decimal point in an international-style currency value.
int_frac_digits     => 2,
## Same as n_cs_precedes, but for internationally formatted monetary quantities.
int_n_cs_precedes   => '',
## Same as n_sep_by_space, but for internationally formatted monetary quantities.
int_n_sep_by_space  => '',
## Same as n_sign_posn, but for internationally formatted monetary quantities.
int_n_sign_posn     => 1,
## Same as p_cs_precedes, but for internationally formatted monetary quantities.
int_p_cs_precedes   => 1,
## Same as p_sep_by_space, but for internationally formatted monetary quantities.
int_p_sep_by_space  => 0,
## Same as p_sign_posn, but for internationally formatted monetary quantities.
int_p_sign_posn     => 1,
## The decimal point character for currency values.
mon_decimal_point   => '.',
## Like grouping but for currency values.
mon_grouping        => (CORE::chr(3) x 2),
## The separator for digit groups in currency values.
mon_thousands_sep   => ',',
## Like p_cs_precedes but for negative values.
n_cs_precedes       => 1,
## Like p_sep_by_space but for negative values.
n_sep_by_space      => 0,
## Like p_sign_posn but for negative currency values.
n_sign_posn         => 1,
## The character used to denote negative currency values, usually a minus sign.
negative_sign       => '-',
## 1 if the currency symbol precedes the currency value for nonnegative values, 0 if it follows.
p_cs_precedes       => 1,
## 1 if a space is inserted between the currency symbol and the currency value for nonnegative values, 0 otherwise.
p_sep_by_space      => 0,
## The location of the positive_sign with respect to a nonnegative quantity and the currency_symbol, coded as follows:
## 0    Parentheses around the entire string.
## 1    Before the string.
## 2    After the string.
## 3    Just before currency_symbol.
## 4    Just after currency_symbol.
p_sign_posn         => 1,
## The character used to denote nonnegative currency values, usually the empty string.
positive_sign       => '',
## The separator between groups of digits before the decimal point, except for currency values
thousands_sep       => ',',
};

my $map =
{
decimal             => [qw( decimal_point mon_decimal_point )],
grouping            => [qw( grouping mon_grouping )],
position_neg        => [qw( n_sign_posn int_n_sign_posn )],
position_pos        => [qw( n_sign_posn int_p_sign_posn )],
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

# This serves 2 purposes:
# 1) to silence warnings issued from Number::Format when it uses an empty string when evaluating a number, e.g. '' == 1
# 2) to ensure that blank numerical values are not interpreted to anything else than equivalent of empty
#    For example, an empty frac_digits will default to 2 in Number::Format even if the user does not want any. Of course, said user could also have set it to 0
# So here we use this hash reference of numeric properties to ensure the option parameters are set to a numeric value (0) when they are empty.
my $numerics = 
{
grouping => 0,
frac_digits => 0,
int_frac_digits => 0,
int_n_cs_precedes => 0,
int_p_cs_precedes => 0,
int_n_sep_by_space => 0,
int_p_sep_by_space => 0,
int_n_sign_posn => 1,
int_p_sign_posn => 1,
mon_grouping => 0,
n_cs_precedes => 0,
n_sep_by_space => 0,
n_sign_posn => 1,
p_cs_precedes => 0,
p_sep_by_space => 0,
# Position of positive sign. 1 = before (0 = parentheses)
p_sign_posn => 1,
};

sub init
{
    my $self = shift( @_ );
    my $num  = shift( @_ );
    # Trigger overloading to string operation
    $num = "$num";
    return( $self->error( "No number was provided." ) ) if( !CORE::length( $num ) );
    return( Module::Generic::Infinity->new( $num ) ) if( POSIX::isinf( $num ) );
    return( Module::Generic::Nan->new( $num ) ) if( POSIX::isnan( $num ) );
    use utf8;
    my @k = keys( %$map );
    @$self{ @k } = ( '' x scalar( @k ) );
    $self->{lang} = '';
    $self->{default} = $DEFAULT;
    $self->{_init_strict_use_sub} = 1;
    $self->SUPER::init( @_ );
    $self->{_original} = $num;
    my $default = $self->default;
    # $self->message( 3, "Getting current locale" );
    my $curr_locale = POSIX::setlocale( &POSIX::LC_ALL );
    # perllocale: "If no second argument is provided and the category is LC_ALL, the result is implementation-dependent. It may be a string of concatenated locale names (separator also implementation-dependent) or a single locale name."
    # e.g.: 'LC_NUMERIC=en_GB.UTF-8;LC_CTYPE=de_AT.utf8;LC_COLLATE=en_GB.UTF-8;LC_TIME=en_GB.UTF-8;LC_MESSAGES=en_GB.UTF-8;LC_MONETARY=en_GB.UTF-8;LC_ADDRESS=en_GB.UTF-8;LC_IDENTIFICATION=en_GB.UTF-8;LC_MEASUREMENT=en_GB.UTF-8;LC_PAPER=en_GB.UTF-8;LC_TELEPHONE=en_GB.UTF-8;'
    if( defined( $curr_locale ) && 
        CORE::length( $curr_locale ) && 
        CORE::index( $curr_locale, ';' ) != -1 )
    {
        my @parts = CORE::split( /;/, $curr_locale );
        my $elems = {};
        for( @parts )
        {
            my( $n, $v ) = split( /=/, $_, 2 );
            $elems->{ $n } = $v;
        }
        $curr_locale = $elems->{LC_NUMERIC} || $elems->{LC_MESSAGES} || $elems->{LC_MONETARY};
    }
    # $self->message( 3, "Current locale is '$curr_locale'" );
    if( $self->{lang} )
    {
        # $self->message( 3, "Language requested '$self->{lang}'." );
        try
        {
            # $self->message( 3, "Current locale found is '$curr_locale'" );
            my $try_locale = sub
            {
                my $loc;
                # $self->message( 3, "Checking language '$_[0]'" );
                ## The user provided only a language code such as fr_FR. We try it, and also other known combination like fr_FR.UTF-8 and fr_FR.ISO-8859-1, fr_FR.ISO8859-1
                ## Try several possibilities
                ## RT https://rt.cpan.org/Public/Bug/Display.html?id=132664
                if( index( $_[0], '.' ) == -1 )
                {
                    # $self->message( 3, "Language '$_[0]' is a bareword, check if it works as is." );
                    $loc = POSIX::setlocale( &POSIX::LC_ALL, $_[0] );
                    # $self->message( 3, "Succeeded to set up locale for language '$_[0]'" ) if( $loc );
                    $_[0] =~ s/^(?<locale>[a-z]{2,3})_(?<country>[a-z]{2})$/$+{locale}_\U$+{country}\E/;
                    if( !$loc && CORE::exists( $SUPPORTED_LOCALES->{ $_[0] } ) )
                    {
                        # $self->message( 3, "Language '$_[0]' is supported, let's check for right variation" );
                        foreach my $supported ( @{$SUPPORTED_LOCALES->{ $_[0] }} )
                        {
                            if( ( $loc = POSIX::setlocale( &POSIX::LC_ALL, $supported ) ) )
                            {
                                $_[0] = $supported;
                                # $self->message( "-> Language variation '$supported' found." );
                                last;
                            }
                        }
                    }
                }
                ## We got something like fr_FR.ISO-8859
                ## The user is specific, so we try as is
                else
                {
                    # $self->message( 3, "Language '$_[0]' is specific enough, let's try it." );
                    $loc = POSIX::setlocale( &POSIX::LC_ALL, $_[0] );
                }
                return( $loc );
            };
            
            ## $self->message( 3, "Current locale is: '$curr_locale'" );
            if( my $loc = $try_locale->( $self->{lang} ) )
            {
                # $self->message( 3, "Succeeded in setting locale for language '$self->{lang}'" );
                ## $self->message( 3, "Succeeded in setting locale to '$self->{lang}'." );
                my $lconv = POSIX::localeconv();
                ## Set back the LC_ALL to what it was, because we do not want to disturb the user environment
                POSIX::setlocale( &POSIX::LC_ALL, $curr_locale );
                ## $self->messagef( 3, "POSIX::localeconv() returned %d items", scalar( keys( %$lconv ) ) );
                $default = $lconv if( $lconv && scalar( keys( %$lconv ) ) );
            }
            else
            {
                return( $self->error( "Language \"$self->{lang}\" is not supported by your system." ) );
            }
        }
        catch( $e )
        {
            return( $self->error( "An error occurred while getting the locale information for \"$self->{lang}\": $e" ) );
        }
    }
#     elsif( $curr_locale && 
#            $curr_locale ne 'C' && 
#            $curr_locale ne 'POSIX' && 
#            ( my $lconv = POSIX::localeconv() ) )
#     {
    elsif( $curr_locale && ( my $lconv = POSIX::localeconv() ) )
    {
        $default = $lconv if( scalar( keys( %$lconv ) ) );
        ## To simulate running on Windows
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
        ## $self->message( 3, "No language provided, but current locale '$curr_locale' found" );
        $self->{lang} = $curr_locale;
    }

    no warnings 'uninitialized';
    foreach my $prop ( keys( %$map ) )
    {
        my $ref = $map->{ $prop };
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
                $self->$prop( $default->{ $lconv_prop } );
                last;
            }
            else
            {
                $self->$prop( $default->{ $lconv_prop } );
            }
        }
    }
    
    try
    {
        if( $num !~ /^$RE{num}{real}$/ )
        {
            my $fmt = $self->_get_formatter;
            $self->{_number} = $fmt->unformat_number( $num );
        }
        else
        {
            $self->{_number} = $num;
        }
        ## $self->message( 3, "Unformatted number is: '$self->{_number}'" );
        return( $self->error( "Invalid number: $num" ) ) if( !defined( $self->{_number} ) );
    }
    catch( $e )
    {
        return( $self->error( "Invalid number: $num" ) );
    }
    return( $self );
}

sub abs { return( shift->_func( 'abs' ) ); }

# sub asin { return( shift->_func( 'asin', { posix => 1 } ) ); }

sub atan { return( shift->_func( 'atan', { posix => 1 } ) ); }

sub atan2 { return( shift->_func( 'atan2', @_ ) ); }

# sub as_array { return( Module::Generic::Array->new( [ shift->{_number} ] ) ); }
sub as_array
{
    require Module::Generic::Array;
    return( Module::Generic::Array->new( [ shift->{_number} ] ) );
}

# sub as_boolean { return( Module::Generic::Boolean->new( shift->{_number} ? 1 : 0 ) ); }
sub as_boolean
{
    require Module::Generic::Boolean;
    return( Module::Generic::Boolean->new( shift->{_number} ? 1 : 0 ) );
}

# sub as_scalar { return( Module::Generic::Scalar->new( shift->{_number} ) ); }
sub as_scalar
{
    require Module::Generic::Scalar;
    return( Module::Generic::Scalar->new( shift->{_number} ) );
}

sub as_string { return( shift->{_number} ) }

sub cbrt { return( shift->_func( 'cbrt', { posix => 1 } ) ); }

sub ceil { return( shift->_func( 'ceil', { posix => 1 } ) ); }

# sub chr { return( Module::Generic::Scalar->new( CORE::chr( $_[0]->{_number} ) ) ); }
sub chr
{
    require Module::Generic::Scalar;
    return( Module::Generic::Scalar->new( CORE::chr( $_[0]->{_number} ) ) );
}

sub clone
{
    my $self = shift( @_ );
    my $num  = @_ ? shift( @_ ) : $self->{_number};
    return( Module::Generic::Infinity->new( $num ) ) if( POSIX::isinf( $num ) );
    return( Module::Generic::Nan->new( $num ) ) if( POSIX::isnan( $num ) );
    my $new = $self->SUPER::clone;
    $new->{_number} = $num;
    return( $new );
}

sub compute
{
    my( $self, $other, $swap, $opts ) = @_;
    my $other_val = Scalar::Util::blessed( $other ) ? $other : "\"$other\"";
    my $operation = $swap ? "${other_val} $opts->{op} \$self->{_number}" : "\$self->{_number} $opts->{op} ${other_val}";
    no warnings 'uninitialized';
    no strict;
    if( $opts->{return_object} )
    {
        my $res = eval( $operation );
        no overloading;
        warn( "Error with return formula \"$operation\" using object $self having number '$self->{_number}': $@" ) if( $@ && $self->_warnings_is_enabled );
        return if( $@ );
        require Module::Generic::Scalar;
        return( Module::Generic::Scalar->new( $res ) ) if( $opts->{type} eq 'scalar' );
        return( Module::Generic::Infinity->new( $res ) ) if( POSIX::isinf( $res ) );
        return( Module::Generic::Nan->new( $res ) ) if( POSIX::isnan( $res ) );
        # undef may be returned for example on platform supporting NaN when using <=>
        return( $self->clone( $res ) ) if( defined( $res ) );
        return;
    }
    elsif( $opts->{boolean} )
    {
        my $res = eval( $operation );
        no overloading;
        warn( "Error with boolean formula \"$operation\" using object $self having number '$self->{_number}': $@" ) if( $@ && $self->_warnings_is_enabled );
        return if( $@ );
        # return( $res ? $self->true : $self->false );
        return( $res );
    }
    else
    {
        # return( eval( $operation ) );
        my $res = eval( $operation );
        return( $res );
    }
}

sub cos { return( shift->_func( 'cos' ) ); }

sub currency { return( shift->_set_get_prop( 'symbol', @_ ) ); }

sub decimal { return( shift->_set_get_prop( 'decimal', @_ ) ); }

sub default { return( shift->_set_get_hash_as_mix_object( 'default', @_ ) ); }
# sub default { return( shift->_set_get_hash( 'default', @_ ) ); }
# sub default
# {
#     my $self = shift( @_ );
#     if( @_ )
#     {
#         my $v = shift( @_ );
#         return( $self->error( "Value provided is not an hash reference." ) ) if( ref( $v ) ne 'HASH' );
#         $self->{default} = $v;
#     }
#     return( $self->{default} );
# }

sub exp { return( shift->_func( 'exp' ) ); }

sub floor { return( shift->_func( 'floor', { posix => 1 } ) ); }

sub format
{
    my $self = shift( @_ );
    my $precision = ( @_ && $_[0] =~ /^\d+$/ ) ? shift( @_ ) : $self->precision;
    no overloading;
    my $num  = $self->{_number};
    ## If value provided was undefined, we leave it undefined, otherwise we would be at risk of returning 0, and 0 is very different from undefined
    return( $num ) if( !defined( $num ) );
    my $fmt = $self->_get_formatter;
    try
    {
        ## Amazingly enough, when a precision > 0 is provided, format_number will discard it if the number, before formatting, did not have decimals... Then, what is the point of formatting a number then?
        ## To circumvent this, we provide the precision along with the "add trailing zeros" parameter expected by Number::Format
        ## return( $fmt->format_number( $num, $precision, 1 ) );
        my $res = $fmt->format_number( "$num", $precision, 1 );
        return if( !defined( $res ) );
        require Module::Generic::Scalar;
        return( Module::Generic::Scalar->new( $res ) );
    }
    catch( $e )
    {
        return( $self->error( "Error formatting number \"$num\": $e" ) );
    }
}

# sub format_binary { return( Module::Generic::Scalar->new( CORE::sprintf( '%b', shift->{_number} ) ) ); }
sub format_binary
{
    require Module::Generic::Scalar;
    return( Module::Generic::Scalar->new( CORE::sprintf( '%b', shift->{_number} ) ) );
}

sub format_bytes
{
    my $self = shift( @_ );
    # no overloading;
    my $num  = $self->{_number};
    # See comment in format() method
    return( $num ) if( !defined( $num ) );
    my $fmt = $self->_get_formatter;
    try
    {
        ## return( $fmt->format_bytes( $num, @_ ) );
        my $res = $fmt->format_bytes( "$num", @_ );
        return if( !defined( $res ) );
        require Module::Generic::Scalar;
        return( Module::Generic::Scalar->new( $res ) );
    }
    catch( $e )
    {
        return( $self->error( "Error formatting number \"$num\": $e" ) );
    }
}

# sub format_hex { return( Module::Generic::Scalar->new( CORE::sprintf( '0x%X', shift->{_number} ) ) ); }
sub format_hex
{
    require Module::Generic::Scalar;
    return( Module::Generic::Scalar->new( CORE::sprintf( '0x%X', shift->{_number} ) ) );
}

sub format_money
{
    my $self = shift( @_ );
    my $precision = ( @_ && $_[0] =~ /^\d+$/ ) ? shift( @_ ) : $self->precision;
    my $currency_symbol = @_ ? shift( @_ ) : $self->currency;
    # no overloading;
    my $num  = $self->{_number};
    ## See comment in format() method
    return( $num ) if( !defined( $num ) );
    my $fmt = $self->_get_formatter;
    try
    {
        ## Even though the Number::Format instantiated is set with a currency symbol, 
        ## Number::Format will not respect it, and revert to USD if nothing was provided as argument
        ## This highlights that Number::Format is designed to be used more for exporting function rather than object methods
        ## $self->message( 3, "Passing Number = '$num', precision = '$precision', currency symbol = '$currency_symbol'." );
        ## return( $fmt->format_price( $num, $precision, $currency_symbol ) );
        my $res = $fmt->format_price( "$num", "$precision", "$currency_symbol" );
        return if( !defined( $res ) );
        require Module::Generic::Scalar;
        return( Module::Generic::Scalar->new( $res ) );
    }
    catch( $e )
    {
        return( $self->error( "Error formatting number \"$num\": $e" ) );
    }
}

sub format_negative
{
    my $self = shift( @_ );
    # no overloading;
    my $num  = $self->{_number};
    ## See comment in format() method
    return( $num ) if( !defined( $num ) );
    my $fmt = $self->_get_formatter;
    try
    {
        my $new = $self->format;
        ## $self->message( 3, "Formatted number '$self->{_number}' now is '$new'" );
        ## return( $fmt->format_negative( $new, @_ ) );
        my $res = $fmt->format_negative( "$new", @_ );
        ## $self->message( 3, "Result is '$res'" );
        return if( !defined( $res ) );
        require Module::Generic::Scalar;
        return( Module::Generic::Scalar->new( $res ) );
    }
    catch( $e )
    {
        return( $self->error( "Error formatting number \"$num\": $e" ) );
    }
}

sub format_picture
{
    my $self = shift( @_ );
    no overloading;
    my $num  = $self->{_number};
    ## See comment in format() method
    return( $num ) if( !defined( $num ) );
    my $fmt = $self->_get_formatter;
    try
    {
        ## return( $fmt->format_picture( $num, @_ ) );
        my $res = $fmt->format_picture( "$num", @_ );
        return if( !defined( $res ) );
        require Module::Generic::Scalar;
        return( Module::Generic::Scalar->new( $res ) );
    }
    catch( $e )
    {
        return( $self->error( "Error formatting number \"$num\": $e" ) );
    }
}

sub formatter { return( shift->_set_get_object_without_init( '_fmt', 'Number::Format', @_ ) ); }

# <https://stackoverflow.com/a/483708/4814971>
sub from_binary
{
    my $self = shift( @_ );
    my $binary = shift( @_ );
    return if( !defined( $binary ) || !CORE::length( $binary ) );
    try
    {
        ## Nice trick to convert from binary to decimal. See perlfunc -> oct
        my $res = CORE::oct( "0b${binary}" );
        return if( !defined( $res ) );
        return( $self->clone( $res ) );
    }
    catch( $e )
    {
        return( $self->error( "Error while getting number from binary value \"$binary\": $e" ) );
    }
}

sub from_hex
{
    my $self = shift( @_ );
    my $hex = shift( @_ );
    return if( !defined( $hex ) || !CORE::length( $hex ) );
    try
    {
        my $res = CORE::hex( $hex );
        return if( !defined( $res ) );
        return( $self->clone( $res ) );
    }
    catch( $e )
    {
        return( $self->error( "Error while getting number from hexadecimal value \"$hex\": $e" ) );
    }
}

sub grouping { return( shift->_set_get_prop( 'grouping', @_ ) ); }

sub int { return( shift->_func( 'int' ) ); }

{
    no warnings 'once';
    *is_decimal = \&is_float;
}

sub is_even { return( !( shift->{_number} % 2 ) ); }

sub is_finite { return( shift->_func( 'isfinite', { posix => 1 }) ); }

sub is_float { return( (POSIX::modf( shift->{_number} ))[0] != 0 ); }

# sub is_infinite { return( !(shift->is_finite) ); }
sub is_infinite { return( shift->_func( 'isinf', { posix => 1 }) ); }

sub is_int { return( (POSIX::modf( shift->{_number} ))[0] == 0 ); }

sub is_nan { return( shift->_func( 'isnan', { posix => 1}) ); }

{
    no warnings 'once';
    *is_neg = \&is_negative;
}

sub is_negative { return( shift->_func( 'signbit', { posix => 1 }) != 0 ); }

sub is_normal { return( shift->_func( 'isnormal', { posix => 1}) ); }

sub is_odd { return( shift->{_number} % 2 ); }

{
    no warnings 'once';
    *is_pos = \&is_positive;
}

sub is_positive { return( shift->_func( 'signbit', { posix => 1 }) == 0 ); }

sub lang { return( shift->_set_get_scalar_as_object( 'lang', @_ ) ); }

sub length { return( $_[0]->clone( CORE::length( $_[0]->{_number} ) ) ); }

sub locale { return( shift->_set_get_scalar_as_object( 'lang', @_ ) ); }

sub log { return( shift->_func( 'log' ) ); }

sub log2 { return( shift->_func( 'log2', { posix => 1 } ) ); }

sub log10 { return( shift->_func( 'log10', { posix => 1 } ) ); }

sub max { return( shift->_func( 'fmax', @_, { posix => 1 } ) ); }

sub min { return( shift->_func( 'fmin', @_, { posix => 1 } ) ); }

sub mod { return( shift->_func( 'fmod', @_, { posix => 1 } ) ); }

## This is used so that we can change formatter when the user changes thousand separator, decimal separator, precision or currency
sub new_formatter
{
    my $self = shift( @_ );
    my $hash = {};
    if( @_ )
    {
        if( @_ == 1 && $self->_is_hash( $_[0] ) )
        {
            $hash = shift( @_ );
        }
        elsif( !( @_ % 2 ) )
        {
            $hash = { @_ };
        }
        else
        {
            return( $self->error( "Invalid parameters provided: '", join( "', '", @_ ), "'." ) );
        }
    }
#     else
#     {
#         my @keys = keys( %$map );
#         # @$hash{ @keys } = @$self{ @keys };
#         for( @keys )
#         {
#             $hash->{ $_ } = $self->$_();
#         }
#     }
#     try
#     {
#         my $opts = {};
#         foreach my $prop ( keys( %$map ) )
#         {
#             $opts->{ $map->{ $prop }->[0] } = $hash->{ $prop } if( CORE::defined( $hash->{ $prop } ) );
#         }
#         return( Number::Format->new( %$opts ) );
#     }
#     catch( $e )
#     {
#         return( $self->error( "Error while trying to get a Number::Format object: $e" ) );
#     }
    
    # $Number::Format::DEFAULT_LOCALE->{int_curr_symbol} = 'EUR';
    try
    {
        ## Those are unsupported by Number::Format
        my $skip =
        {
        int_n_cs_precedes => 1,
        int_p_cs_precedes => 1,
        int_n_sep_by_space => 1,
        int_p_sep_by_space => 1,
        int_n_sign_posn => 1,
        int_p_sign_posn => 1,
        };
        my $opts = {};
        foreach my $prop ( CORE::keys( %$map ) )
        {
            ## $self->message( 3, "Checking property \"$prop\" value \"", overload::StrVal( $self->{ $prop } ), "\" (", $self->$prop->defined ? 'defined' : 'undefined', ")." );
            my $prop_val;
            if( CORE::exists( $hash->{ $prop } ) )
            {
                $prop_val = $hash->{ $prop };
            }
            elsif( $self->$prop->defined )
            {
                $prop_val = $self->$prop;
            }
            ## To prevent Number::Format from defaulting to property values not in sync with ours
            ## Because it seems the POSIX::setlocale only affect one module
            else
            {
                $prop_val = '';
            }
            ## $self->message( 3, "Using property \"$prop\" value \"$prop_val\" (", CORE::defined( $prop_val ) ? 'defined' : 'undefined', ") [ref=", ref( $prop_val ), "]." );
            ## Need to set all the localeconv properties for Number::Format, because it uses mon_thousand_sep intsead of just thousand_sep
            foreach my $lconv_prop ( @{$map->{ $prop }} )
            {
                CORE::next if( CORE::exists( $skip->{ $lconv_prop } ) );
                ## Cannot be undefined, but can be empty string
                $opts->{ $lconv_prop } = "$prop_val";
                if( !CORE::length( $opts->{ $lconv_prop } ) && CORE::exists( $numerics->{ $lconv_prop } ) )
                {
                    $opts->{ $lconv_prop } = $numerics->{ $lconv_prop };
                }
            }
        }
        # $self->message( 3, "Using following options for Number::Format: ", sub{ $self->SUPER::dump( $opts ) } );
        no warnings qw( uninitialized );
        my $fmt = Number::Format->new( %$opts );
        use warnings;
        return( $fmt );
    }
    catch( $e )
    {
        ## $self->message( 3, "Error trapped in creating a Number::Format object: '$e'" );
        return( $self->error( "Unable to create a Number::Format object: $e" ) );
    }
}

sub oct { return( shift->_func( 'oct' ) ); }

sub position_neg { return( shift->_set_get_prop( 'position_neg', @_ ) ); }

sub position_pos { return( shift->_set_get_prop( 'position_pos', @_ ) ); }

sub pow { return( shift->_func( 'pow', @_, { posix => 1 } ) ); }

sub precede { return( shift->_set_get_prop( 'precede', @_ ) ); }

sub precede_neg { return( shift->_set_get_prop( 'precede_neg', @_ ) ); }

sub precede_pos { return( shift->_set_get_prop( 'precede', @_ ) ); }

sub precision { return( shift->_set_get_prop( 'precision', @_ ) ); }

sub rand { return( shift->_func( 'rand' ) ); }

sub round { return( $_[0]->clone( CORE::sprintf( '%.*f', CORE::int( CORE::length( $_[1] ) ? $_[1] : 0 ), $_[0]->{_number} ) ) ); }

sub round_zero { return( shift->_func( 'round', @_, { posix => 1 } ) ); }

sub round2
{
    my $self = shift( @_ );
    no overloading;
    my $num  = $self->{_number};
    # See comment in format() method
    return( $num ) if( !defined( $num ) );
    my $fmt = $self->_get_formatter;
    try
    {
        ## return( $fmt->round( $num, @_ ) );
        my $res = $fmt->round( $num, @_ );
        return if( !defined( $res ) );
        my $clone = $self->clone;
        $clone->{_number} = $res;
        return( $clone );
    }
    catch( $e )
    {
        return( $self->error( "Error rounding number \"$num\": $e" ) );
    }
}

sub scalar { return( shift->as_string ); }

sub sign_neg { return( shift->_set_get_prop( 'sign_neg', @_ ) ); }

sub sign_pos { return( shift->_set_get_prop( 'sign_pos', @_ ) ); }

sub sin { return( shift->_func( 'sin' ) ); }

{
    no warnings 'once';
    *space = \&space_pos;
}

sub space_neg { return( shift->_set_get_prop( 'space_neg', @_ ) ); }

sub space_pos { return( shift->_set_get_prop( 'space_pos', @_ ) ); }

sub sqrt { return( shift->_func( 'sqrt' ) ); }

sub symbol { return( shift->_set_get_prop( 'symbol', @_ ) ); }

sub tan { return( shift->_func( 'tan', { posix => 1 } ) ); }

sub thousand { return( shift->_set_get_prop( 'thousand', @_ ) ); }

sub unformat
{
    my $self = shift( @_ );
    my $num = shift( @_ );
    return if( !defined( $num ) );
    try
    {
        my $num2 = $self->_get_formatter->unformat_number( $num );
        my $clone = $self->clone;
        $clone->{_original} = $num;
        $clone->{_number} = $num2;
        $clone->debug( $self->debug );
        return( $clone );
    }
    catch( $e )
    {
        return( $self->error( "Unable to unformat the number \"$num\": $e" ) );
    }
}

sub _func
{
    my $self = shift( @_ );
    my $func = shift( @_ ) || return( $self->error( "No function was provided." ) );
    # $self->message( 3, "Arguments received are: '", join( "', '", @_ ), "'." );
    my $opts = {};
    no strict;
    $opts = pop( @_ ) if( ref( $_[-1] ) eq 'HASH' );
    my $namespace = $opts->{posix} ? 'POSIX' : 'CORE';
    my $val  = @_ ? shift( @_ ) : undef;
    my $expr = defined( $val ) ? "${namespace}::${func}( \$self->{_number}, $val )" : "${namespace}::${func}( \$self->{_number} )";
    # $self->message( 3, "Evaluating '$expr'" );
    my $res = eval( $expr );
    ## $self->message( 3, "Result for number '$self->{_number}' is '$res'" );
    $self->message( 3, "Error: $@" ) if( $@ );
    return( $self->pass_error( $@ ) ) if( $@ );
    return if( !defined( $res ) );
    return( Module::Generic::Infinity->new( $res ) ) if( POSIX::isinf( $res ) );
    return( Module::Generic::Nan->new( $res ) ) if( POSIX::isnan( $res ) );
    return( $self->clone( $res ) );
}

sub _get_formatter
{
    my $self = shift( @_ );
    $self->message( 4, "Returning Number::Format object cached -> '$self->{_fmt}'" ) if( $self->{_fmt} );
    return( $self->{_fmt} ) if( $self->{_fmt} );
    my $fmt = $self->new_formatter || return( $self->pass_error );
    $self->{_fmt} = $fmt;
    return( $self->{_fmt} );
}

sub _set_get_prop
{
    my $self = shift( @_ );
    my $prop = shift( @_ );
    if( @_ )
    {
        my $val = shift( @_ );
        # $val = $val->scalar if( $self->_is_object( $val ) && $val->isa( 'Module::Generic::Scalar' ) );
        $val = "$val" if( CORE::defined( $val ) );
        ## $self->message( 3, "Setting value \"$val\" (", defined( $val ) ? 'defined' : 'undefined', ") for property \"$prop\"." );
        ## I do not want to set a default value of '' to $self->{ $prop } because if its value is undef, it should remain so
        no warnings 'uninitialized';
        if( !CORE::defined( $val ) || ( CORE::defined( $val ) && $val ne $self->{ $prop } ) )
        {
            $self->_set_get_scalar_as_object( $prop, $val );
            # If an error was set, we return nothing
            # $self->formatter( $self->new_formatter ) || return;
        }
    }
    return( $self->_set_get_scalar_as_object( $prop ) );
}

AUTOLOAD
{
    my( $method ) = our $AUTOLOAD =~ /([^:]+)$/;
    my $self = shift( @_ ) || return;
    my $fmt_obj = $self->_get_formatter || return;
    my $code = $fmt_obj->can( $method );
    if( $code )
    {
        try
        {
            return( $code->( $fmt_obj, @_ ) );
        }
        catch( $e )
        {
            CORE::warn( $e );
            return;
        }
    }
    return;
};

sub FREEZE
{
    my $self = CORE::shift( @_ );
    my $serialiser = CORE::shift( @_ ) // '';
    my $class = CORE::ref( $self );
    my %hash  = %$self;
    # Return an array reference rather than a list so this works with Sereal and CBOR
    CORE::return( [$class, \%hash] ) if( $serialiser eq 'Sereal' || $serialiser eq 'CBOR' );
    # But Storable want a list with the first element being the serialised element
    CORE::return( $class, \%hash );
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

sub TO_JSON { return( shift->as_string ); }

# NOTE: package Module::Generic::NumberSpecial
package Module::Generic::NumberSpecial;
BEGIN
{
    use strict;
    use warnings;
    use parent -norequire, qw( Module::Generic::Number );
    use overload ('""'      => sub{ $_[0]->{_number} },
                  '+='      => sub{ &_catchall( @_[0..2], '+' ) },
                  '-='      => sub{ &_catchall( @_[0..2], '-' ) },
                  '*='      => sub{ &_catchall( @_[0..2], '*' ) },
                  '/='      => sub{ &_catchall( @_[0..2], '/' ) },
                  '%='      => sub{ &_catchall( @_[0..2], '%' ) },
                  '**='      => sub{ &_catchall( @_[0..2], '**' ) },
                  '<<='      => sub{ &_catchall( @_[0..2], '<<' ) },
                  '>>='      => sub{ &_catchall( @_[0..2], '>>' ) },
                  'x='      => sub{ &_catchall( @_[0..2], 'x' ) },
                  '.='      => sub{ &_catchall( @_[0..2], '.' ) },
                  nomethod  => \&_catchall,
                  fallback  => 1,
                 );
    use Want;
    use POSIX qw( Inf NaN );
    our( $VERSION ) = '0.1.0';
};

sub new
{
    my $this = shift( @_ );
    return( bless( { _number => CORE::shift( @_ ) } => ( ref( $this ) || $this ) ) );
}

sub clone { return( shift->new( @_ ) ); }

sub is_finite { return( 0 ); }

sub is_float { return( 0 ); }

sub is_infinite { return( 0 ); }

sub is_int { return( 0 ); }

sub is_nan { return( 0 ); }

sub is_normal { return( 0 ); }

sub length { return( CORE::length( shift->{_number} ) ); }

sub _catchall
{
    my( $self, $other, $swap, $op ) = @_;
    no strict;
    my $expr = $swap ? "$other $op $self->{_number}" : "$self->{_number} $op $other";
    my $res = eval( $expr );
    CORE::warn( "Error evaluating expression \"$expr\": $@" ) if( $@ );
    return if( $@ );
    return( Module::Generic::Number->new( $res ) ) if( POSIX::isnormal( $res ) );
    return( Module::Generic::Infinity->new( $res ) ) if( POSIX::isinf( $res ) );
    return( Module::Generic::Nan->new( $res ) ) if( POSIX::isnan( $res ) );
    return( $res );
}

sub _func
{
    my $self = shift( @_ );
    my $func = shift( @_ ) || return( $self->error( "No function was provided." ) );
    my $opts = {};
    no strict;
    $opts = pop( @_ ) if( ref( $_[-1] ) eq 'HASH' );
    my $namespace = $opts->{posix} ? 'POSIX' : 'CORE';
    my $val  = @_ ? shift( @_ ) : undef;
    my $expr = defined( $val ) ? "${namespace}::${func}( $self->{_number}, $val )" : "${namespace}::${func}( $self->{_number} )";
    my $res = eval( $expr );
    CORE::warn( $@ ) if( $@ );
    return if( !defined( $res ) );
    return( Module::Generic::Number->new( $res ) ) if( POSIX::isnormal( $res ) );
    return( Module::Generic::Infinity->new( $res ) ) if( POSIX::isinf( $res ) );
    return( Module::Generic::Nan->new( $res ) ) if( POSIX::isnan( $res ) );
    return( $res );
}

AUTOLOAD
{
    my( $method ) = our $AUTOLOAD =~ /([^:]+)$/;
    # If we are chained, return our null object, so the chain continues to work
    if( want( 'OBJECT' ) )
    {
        # No, this is NOT a typo. rreturn() is a function of module Want
        rreturn( $_[0] );
    }
    # Otherwise, we return infinity, whether positive or negative or NaN depending on what was set
    return( $_[0]->{_number} );
};

DESTROY {};

# NOTE: package Module::Generic::Infinity
# Purpose is to allow chaining of methods when infinity is returned
# At the end of the chain, Inf or -Inf is returned
package Module::Generic::Infinity;
BEGIN
{
    use strict;
    use warnings;
    use parent -norequire, qw( Module::Generic::NumberSpecial );
    our( $VERSION ) = '0.1.0';
};

sub is_infinite { return( 1 ); }

# NOTE: package Module::Generic::Nan
package Module::Generic::Nan;
BEGIN
{
    use strict;
    use warnings;
    use parent -norequire, qw( Module::Generic::NumberSpecial );
    our( $VERSION ) = '0.1.0';
};

sub is_nan { return( 1 ); }

1;

__END__
