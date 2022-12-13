##----------------------------------------------------------------------------
## Module Generic - ~/lib/Module/Generic/Number.pm
## Version v2.0.1
## Copyright(c) 2022 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2021/03/20
## Modified 2022/12/11
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
    use vars qw( $SUPPORTED_LOCALES $DEFAULT $NUMBER_RE );
    use Nice::Try;
    use POSIX qw( Inf NaN );
    use Regexp::Common qw( number );
    $NUMBER_RE = $RE{num}{real};
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
            if( $res =~ /^$NUMBER_RE$/ )
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
    # Largest integer a 32-bit Perl can handle is based on the mantissa
    # size of a double float, which is up to 53 bits.  While we may be
    # able to support larger values on 64-bit systems, some Perl integer
    # operations on 64-bit integer systems still use the 53-bit-mantissa
    # double floats.  To be safe, we cap at 2**53; use Math::BigFloat
    # instead for larger numbers.
    use constant MAX_INT => 2**53;
    our( $VERSION ) = 'v2.0.1';
};

# use strict;
no warnings 'redefine';
use utf8;

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
    return( $self->error( "No number was provided." ) ) if( !scalar( @_ ) );
    my $num  = shift( @_ );
    return( $self->error( "Number provided is undefined" ) ) if( !defined( $num ) );
    # Trigger overloading to string operation
    $num = "$num";
    return( $self->error( "Number value provided is empty" ) ) if( !CORE::length( $num ) );
    return( Module::Generic::Infinity->new( $num ) ) if( POSIX::isinf( $num ) );
    return( Module::Generic::Nan->new( $num ) ) if( POSIX::isnan( $num ) );
    use utf8;
    my @k = keys( %$map );
    @$self{ @k } = ( '' x scalar( @k ) );
    $self->{lang} = '';
    $self->{default} = $DEFAULT;
    $self->{decimal_fill}   = 0;
    $self->{neg_format}     = '-x';
    $self->{kilo_suffix}    = 'K';
    $self->{mega_suffix}    = 'M';
    $self->{giga_suffix}    = 'G';
    $self->{kibi_suffix}    = 'KiB';
    $self->{mebi_suffix}    = 'MiB';
    $self->{gibi_suffix}    = 'GiB';
    $self->{_init_strict_use_sub} = 1;
    $self->SUPER::init( @_ );
    $self->{_original} = $num;
    my $default = $self->default;
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
    if( $self->{lang} )
    {
        try
        {
            my $try_locale = sub
            {
                my $loc;
                # The user provided only a language code such as fr_FR. We try it, and also other known combination like fr_FR.UTF-8 and fr_FR.ISO-8859-1, fr_FR.ISO8859-1
                # Try several possibilities
                # RT https://rt.cpan.org/Public/Bug/Display.html?id=132664
                if( index( $_[0], '.' ) == -1 )
                {
                    $loc = POSIX::setlocale( &POSIX::LC_ALL, $_[0] );
                    $_[0] =~ s/^(?<locale>[a-z]{2,3})_(?<country>[a-z]{2})$/$+{locale}_\U$+{country}\E/;
                    if( !$loc && CORE::exists( $SUPPORTED_LOCALES->{ $_[0] } ) )
                    {
                        foreach my $supported ( @{$SUPPORTED_LOCALES->{ $_[0] }} )
                        {
                            if( ( $loc = POSIX::setlocale( &POSIX::LC_ALL, $supported ) ) )
                            {
                                $_[0] = $supported;
                                last;
                            }
                        }
                    }
                }
                # We got something like fr_FR.ISO-8859
                # The user is specific, so we try as is
                else
                {
                    $loc = POSIX::setlocale( &POSIX::LC_ALL, $_[0] );
                }
                return( $loc );
            };
            
            if( my $loc = $try_locale->( $self->{lang} ) )
            {
                my $lconv = POSIX::localeconv();
                # Set back the LC_ALL to what it was, because we do not want to disturb the user environment
                POSIX::setlocale( &POSIX::LC_ALL, $curr_locale );
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
    
    # Convert Japanese double bytes numbers to regular digits.
    $num =~ tr/[\x{FF10}-\x{FF19}]＋ー/[0-9]+-/;
    if( $num !~ /^$NUMBER_RE$/ )
    {
        $self->{_number} = $self->unformat( $num );
    }
    else
    {
        $self->{_number} = $num;
    }
    return( $self->error( "Invalid number: $num (", overload::StrVal( $num ), ")" ) ) if( !defined( $self->{_number} ) );
    return( $self );
}

sub abs { return( shift->_func( 'abs' ) ); }

# sub asin { return( shift->_func( 'asin', { posix => 1 } ) ); }

sub atan { return( shift->_func( 'atan', { posix => 1 } ) ); }

sub atan2 { return( shift->_func( 'atan2', @_ ) ); }

sub as_array
{
    require Module::Generic::Array;
    return( Module::Generic::Array->new( [ shift->{_number} ] ) );
}

sub as_boolean
{
    require Module::Generic::Boolean;
    return( Module::Generic::Boolean->new( shift->{_number} ? 1 : 0 ) );
}

sub as_scalar
{
    require Module::Generic::Scalar;
    return( Module::Generic::Scalar->new( shift->{_number} ) );
}

sub as_string { return( shift->{_number} ) }

sub cbrt { return( shift->_func( 'cbrt', { posix => 1 } ) ); }

sub ceil { return( shift->_func( 'ceil', { posix => 1 } ) ); }

sub chr
{
    require Module::Generic::Scalar;
    return( Module::Generic::Scalar->new( CORE::chr( $_[0]->{_number} ) ) );
}

sub clone
{
    my $self = shift( @_ );
    my $new;
    if( !$self->_is_object( $self ) )
    {
        my $num = shift( @_ ) // 0;
        $new = $self->new( $new );
        return( $self->pass_error ) if( !defined( $new ) );
    }
    else
    {
        my $num = @_ ? shift( @_ ) : $self->{_number};
        return( Module::Generic::Infinity->new( $num ) ) if( POSIX::isinf( $num ) );
        return( Module::Generic::Nan->new( $num ) ) if( POSIX::isnan( $num ) );
        $new = $self->SUPER::clone;
        return( $self->pass_error ) if( !defined( $new ) );
        $new->{_number} = ( CORE::exists( $num->{_number} ) ? $num->{_number} : $num );
    }
    return( $new );
}

sub compute
{
    my $self = shift( @_ );
    my $opts = pop( @_ );
    my( $other, $swap, $nomethod, $bitwise ) = @_;
    if( !defined( $opts ) || 
        ref( $opts ) ne 'HASH' || 
        !exists( $opts->{op} ) || 
        !defined( $opts->{op} ) || 
        !length( $opts->{op} ) )
    {
        die( "No argument 'op' provided" );
    }
    my $op = $opts->{op};
    my $other_val = Scalar::Util::blessed( $other ) ? $other : "\"$other\"";
    my $operation = $swap ? ( defined( $other_val ) ? $other_val : 'undef' ) . " ${op} \$self->{_number}" : "\$self->{_number} ${op} " . ( defined( $other_val ) ? $other_val : 'undef' );
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

# sub decimal_digits { return( shift->_set_get_prop( 'decimal_digits', @_ ) ); }

sub decimal_fill { return( shift->_set_get_prop( 'decimal_fill', @_ ) ); }

sub default { return( shift->_set_get_hash_as_mix_object( 'default', @_ ) ); }

sub exp { return( shift->_func( 'exp' ) ); }

sub floor { return( shift->_func( 'floor', { posix => 1 } ) ); }

sub format
{
    my $self = shift( @_ );
    my $precision;
    $precision = shift( @_ ) if( scalar( @_ ) && $_[0] =~ /^\d+$/ );
    my $opts = $self->_get_args_as_hash( @_ );
    no overloading;
    my $number  = $self->{_number};
    # If value provided was undefined, we leave it undefined, otherwise we would be at risk of returning 0, and 0 is very different from undefined
    return( $number ) if( !defined( $number ) );
#     my $fmt = $self->_get_formatter;
#     try
#     {
#         # Amazingly enough, when a precision > 0 is provided, format_number will discard it if the number, before formatting, did not have decimals... Then, what is the point of formatting a number then?
#         # To circumvent this, we provide the precision along with the "add trailing zeros" parameter expected by Number::Format
#         # return( $fmt->format_number( $num, $precision, 1 ) );
#         my $res = $fmt->format_number( "$num", $precision, 1 );
#         return if( !defined( $res ) );
#         require Module::Generic::Scalar;
#         return( Module::Generic::Scalar->new( $res ) );
#     }
#     catch( $e )
#     {
#         return( $self->error( "Error formatting number \"$num\": $e" ) );
#     }
    $precision //= $opts->{precision} // $self->precision;
    my $thousands_sep = $opts->{thousand} // $self->thousand;
    my $decimal_point = $opts->{decimal} // $self->decimal;
    my $trailing_zeroes = $opts->{decimal_fill} // $self->decimal_fill // 1;
    for( $precision, $thousands_sep, $decimal_point, $trailing_zeroes )
    {
        $_ = $_->scalar if( $self->_can( $_ => 'scalar' ) );
    }

    # Taken from Number::Format. Credit to William R. Ward
    # Handle negative numbers
    my $sign = $number <=> 0;
    $number = CORE::abs( $number ) if( $sign < 0 );
    # round off $number
    $number = $self->_round( $number => $precision );
#     no overloading;

    # detect scientific notation
    my $exponent = 0;
    if( $number =~ /^(-?[\d.]+)e([+-]\d+)$/ )
    {
        # Don't attempt to format numbers that require scientific notation.
        return( $number );
    }

    # Split integer and decimal parts of the number and add commas
    my $integer = CORE::int( $number );
    my $decimal;

    # Note: In perl 5.6 and up, string representation of a number
    # automagically includes the locale decimal point.  This way we
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
    if( $thousands_sep )
    {
        # Add leading 0's so length($integer) is divisible by 3
        $integer = '0' x ( 3 - ( CORE::length( $integer ) % 3 ) ) . $integer;

        # Split $integer into groups of 3 characters and insert commas
        $integer = CORE::join( $thousands_sep, CORE::grep{ $_ ne '' } CORE::split( /(...)/, $integer ) );

        # Strip off leading zeroes and optional thousands separator
        $integer =~ s/^0+(?:\Q$thousands_sep\E)?//;
    }
    $integer = '0' if( $integer eq '' );

    # Combine integer and decimal parts and return the result.
    my $result = ( CORE::defined( $decimal ) && CORE::length( $decimal ) )
        ? CORE::join( $decimal_point, $integer, $decimal )
        : $integer;

    my $res = ( $sign < 0 ) ? $self->_format_negative( $result ) : $result;
    return( $self->pass_error ) if( !defined( $res ) );
    require Module::Generic::Scalar;
    return( Module::Generic::Scalar->new( $res ) );
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
    my $number  = $self->{_number};
    # See comment in format() method
    return( $number ) if( !defined( $number ) );
    my $opts = $self->_get_args_as_hash( @_ );
    return( $self->error( "Negative number not allowed in format_bytes()" ) ) if( $number < 0 );

    # Taken from Number::Format. Credit to William R. Ward
    # Set default for precision.  Test using defined because it may be 0.
    $opts->{precision} //= $self->precision // 2;
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
    my $result = $self->new( $number )->format( $opts->{precision} ) . $suffix;

    return( $self->pass_error ) if( !defined( $result ) );
    require Module::Generic::Scalar;
    return( Module::Generic::Scalar->new( $result ) );
}

sub format_hex
{
    require Module::Generic::Scalar;
    return( Module::Generic::Scalar->new( CORE::sprintf( '0x%X', shift->{_number} ) ) );
}

sub format_money
{
    my $self = shift( @_ );
    my( $precision, $curr_symbol ) = @_;
    $precision = $self->precision if( !defined( $precision ) || !CORE::length( "$precision" ) || $precision !~ /^\d+$/ );
    $curr_symbol = $self->currency if( !defined( $curr_symbol ) || !CORE::length( "$curr_symbol" ) );
    # no overloading;
    my $number = $self->{_number};
    # See comment in format() method
    return( $number ) if( !defined( $number ) );
#     my $fmt = $self->_get_formatter;
#     try
#     {
#         # Even though the Number::Format instantiated is set with a currency symbol, 
#         # Number::Format will not respect it, and revert to USD if nothing was provided as argument
#         # This highlights that Number::Format is designed to be used more for exporting function rather than object methods
#         # $self->message( 3, "Passing Number = '$num', precision = '$precision', currency symbol = '$currency_symbol'." );
#         my $res = $fmt->format_price( "$num", "$precision", "$currency_symbol" );
#         return if( !defined( $res ) );
#         require Module::Generic::Scalar;
#         return( Module::Generic::Scalar->new( $res ) );
#     }
#     catch( $e )
#     {
#         return( $self->error( "Error formatting number \"$num\": $e" ) );
#     }
    # Determine what the monetary symbol should be
#     $curr_symbol = $self->{int_curr_symbol}
#         if (!defined($curr_symbol) || lc($curr_symbol) eq "int_curr_symbol");
#     $curr_symbol = $self->{currency_symbol}
#         if (!defined($curr_symbol) || lc($curr_symbol) eq "currency_symbol");
#     $curr_symbol = "" unless defined($curr_symbol);

    # Determine which value to use for frac digits
#     my $frac_digits = ( $curr_symbol eq $self->{int_curr_symbol} ?
#                        $self->{int_frac_digits} : $self->{frac_digits});

    # Taken from Number::Format. Credit to William R. Ward
    my $frac_digits = $self->precision;

    # Determine precision for decimal portion
    $precision = $frac_digits          unless( defined( $precision ) );
    # $precision = $self->decimal_digits unless( defined( $precision ) ); # fallback
    $precision = 2                     unless( defined( $precision ) ); # default

    # Determine sign and absolute value
    my $sign = $number <=> 0;
    $number = CORE::abs( $number ) if( $sign < 0 );

    # format it first
    $number = $self->format(
        precision => $precision,
    );
    return( $self->pass_error ) if( !defined( $number ) );

    # Now we make sure the decimal part has enough zeroes
    my $decimal_point = $self->decimal;
    my( $integer, $decimal ) = CORE::split( /\Q$decimal_point\E/, $number, 2 );
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
        ? CORE::join( $self->decimal, $integer, $decimal )
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
    require Module::Generic::Scalar;
    return( Module::Generic::Scalar->new( $rv ) );
}

sub format_negative
{
    my $self = shift( @_ );
    # no overloading;
    # my $number  = $self->{_number};
    # See comment in format() method
    # return( $number ) if( !defined( $number ) );
    my $format = shift( @_ ) // $self->neg_format;
    my $new = $self->format || return( $self->pass_error );
    $number = "$new";
    if( CORE::index( $format, 'x' ) == -1 )
    {
        return( $self->error( "Letter x must be present in picture in format_negative()" ) );
    }
    $number =~ s/^-//;
    $format =~ s/x/$number/;
    return if( !defined( $number ) );
    $self->_load_class( 'Module::Generic::Scalar' ) || return( $self->pass_error );
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
    no overloading;
    my $number  = $self->{_number};
    # See comment in format() method
    return( $num ) if( !defined( $number ) );
#     my $fmt = $self->_get_formatter;
#     try
#     {
#         my $res = $fmt->format_picture( "$num", @_ );
#         return if( !defined( $res ) );
#         require Module::Generic::Scalar;
#         return( Module::Generic::Scalar->new( $res ) );
#     }
#     catch( $e )
#     {
#         return( $self->error( "Error formatting number \"$num\": $e" ) );
#     }

    # Taken from Number::Format. Credit to William R. Ward
    $picture //= $opts->{picture};
    return( $self->error( "No picture was provided to format number." ) ) if( !CORE::defined( $picture ) || !CORE::length( "$picture" ) );
    
    # Handle negative numbers
    my( $neg_prefix ) = $self->neg_format =~ /^([^x]+)/;
    my( $pic_prefix ) = $picture =~ /^([^\#]+)/;
    my $neg_pic = $self->neg_format;
    ( my $pos_pic = $self->neg_format ) =~ s/[^x\s]/ /g;
    ( my $pos_prefix = $neg_prefix ) =~ s/[^x\s]/ /g;
    $neg_pic =~ s/x/$picture/;
    $pos_pic =~ s/x/$picture/;
    my $sign = $number <=> 0;
    $number = CORE::abs( $number ) if( $sign < 0 );
    $picture = $sign < 0 ? $neg_pic : $pos_pic;
    my $sign_prefix = $sign < 0 ? $neg_prefix : $pos_prefix;
    
    # Split up the picture and return error if there is more than one $decimal_point
    my $decimal_point = $self->decimal;
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
    while( $char = CORE::pop( @pic_int ) )
    {
        $char = CORE::pop( @num_int ) if( $char eq '#' );
        if( !defined( $char ) ||
            $char eq $self->thousands && 
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
    require Module::Generic::Scalar;
    return( Module::Generic::Scalar->new( $result ) );
}

# <https://stackoverflow.com/a/483708/4814971>
sub from_binary
{
    my $self = shift( @_ );
    my $binary = shift( @_ );
    return( $self->error( "No binary value was provided to instantiate a new number object." ) ) if( !defined( $binary ) || !CORE::length( $binary ) );
    try
    {
        # Nice trick to convert from binary to decimal. See perlfunc -> oct
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
    return( $self->error( "No hex value was provided to instantiate a new number object." ) ) if( !defined( $hex ) || !CORE::length( $hex ) );
    my $res = CORE::hex( $hex );
    # hex() actually does not return undef
    return( $self->error( "Error while getting number from hexadecimal value \"$hex\": $!" ) ) if( !defined( $res ) );
    return( $self->clone( $res ) );
}

sub gibi_suffix { return( shift->_set_get_prop( 'gibi_suffix', @_ ) ); }

sub giga_suffix { return( shift->_set_get_prop( 'giga_suffix', @_ ) ); }

sub grouping { return( shift->_set_get_prop( 'grouping', @_ ) ); }

sub int { return( shift->_func( 'int' ) ); }

{
    no warnings 'once';
    *is_decimal = \&is_float;
}

sub is_decimal { return( ( shift->{_number} % 1 ) != 0 ); }

sub is_empty { return( CORE::length( shift->{_number} ) == 0 ); }

sub is_even { return( !( shift->{_number} % 2 ) ); }

sub is_finite { return( shift->_func( 'isfinite', { posix => 1 }) ); }

sub is_float { return( (POSIX::modf( shift->{_number} ))[0] != 0 ); }

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

sub kibi_suffix { return( shift->_set_get_prop( 'kibi_suffix', @_ ) ); }

sub kilo_suffix { return( shift->_set_get_prop( 'kilo_suffix', @_ ) ); }

sub lang { return( shift->_set_get_scalar_as_object( 'lang', @_ ) ); }

sub length { return( $_[0]->clone( CORE::length( $_[0]->{_number} ) ) ); }

sub locale { return( shift->_set_get_scalar_as_object( 'lang', @_ ) ); }

sub log { return( shift->_func( 'log' ) ); }

sub log2 { return( shift->_func( 'log2', { posix => 1 } ) ); }

sub log10 { return( shift->_func( 'log10', { posix => 1 } ) ); }

sub max { return( shift->_func( 'fmax', @_, { posix => 1 } ) ); }

sub mebi_suffix { return( shift->_set_get_prop( 'mebi_suffix', @_ ) ); }

sub mega_suffix { return( shift->_set_get_prop( 'mega_suffix', @_ ) ); }

sub min { return( shift->_func( 'fmin', @_, { posix => 1 } ) ); }

sub mod { return( shift->_func( 'fmod', @_, { posix => 1 } ) ); }

sub neg_format { return( shift->_set_get_prop( 'neg_format', @_ ) ); }

sub oct { return( shift->_func( 'oct' ) ); }

sub position_neg { return( shift->_set_get_prop( 'position_neg', @_ ) ); }

sub position_pos { return( shift->_set_get_prop( 'position_pos', @_ ) ); }

sub pow { return( shift->_func( 'pow', @_, { posix => 1 } ) ); }

sub precede { return( shift->_set_get_prop( 'precede', @_ ) ); }

sub precede_neg { return( shift->_set_get_prop( 'precede_neg', @_ ) ); }

sub precede_pos { return( shift->_set_get_prop( 'precede', @_ ) ); }

sub precision { return( shift->_set_get_prop( 'precision', @_ ) ); }

sub rand { return( shift->_func( 'rand' ) ); }

# sub round { return( $_[0]->clone( CORE::sprintf( '%.*f', CORE::int( CORE::length( $_[1] ) ? $_[1] : 0 ), $_[0]->{_number} ) ) ); }
sub round
{
    my $self = shift( @_ );
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
            return( $self->error( "precision provided '$precision' is negatie. It must be positive." ) );
        }
    }
    else
    {
        return( $self->error( 'Usage: my $n2 = $n->round( $precision );' ) );
    }
    my $new = CORE::sprintf( '%.*f', $precision, $self->{_number} );
    return( $self->clone( $new ) );
}

sub round_zero { return( shift->_func( 'round', @_, { posix => 1 } ) ); }

sub round2
{
    my $self = shift( @_ );
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
            return( $self->error( "precision provided '$precision' is negatie. It must be positive." ) );
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

    if (CORE::ref( $number ) && $number->isa( 'Math::BigFloat' ) )
    {
        my $rounded = $number->copy;
        $rounded->precision( -$precision );
        return if( !defined( $rounded ) );
        my $clone = $self->clone;
        $clone->{_number} = $rounded;
        return( $clone );
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
    return if( !defined( $result ) );
    my $clone = $self->clone;
    $clone->{_number} = $result;
    return( $clone );
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
    my $formatted = shift( @_ );
    return( $self->error( "No value to unformat was provided." ) ) if( !defined( $formatted ) );
    my $opts = $self->_get_args_as_hash( @_ );
    # require at least one digit
    unless( $formatted =~ /\d/ )
    {
        return( $self->error( "No digit found in number to unformat" ) );
    }

    # Regular expression for detecting decimal point
    my $decimal_point = $self->decimal;
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
    my $neg_format = $self->neg_format;
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

    my $clone = $self->clone;
    $clone->{_original} = $num;
    $clone->{_number} = $num2;
    $clone->debug( $self->debug );
    return( $clone );
}

# Shared with format() and format_negative()
sub _format_negative
{
    my( $self, $number, $format ) = @_;
    $format //= $self->neg_format;
    if( CORE::index( $format, 'x' ) == -1 )
    {
        return( $self->error( "Letter x must be present in picture in format_negative()" ) );
    }
    $number =~ s/^-//;
    $format =~ s/x/$number/;
    return( $format );
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
    my $expr = defined( $val ) ? "${namespace}::${func}( \$self->{_number}, $val )" : "${namespace}::${func}( \$self->{_number} )";
    my $res = eval( $expr );
    return( $self->pass_error( $@ ) ) if( $@ );
    return if( !defined( $res ) );
    return( Module::Generic::Infinity->new( $res ) ) if( POSIX::isinf( $res ) );
    return( Module::Generic::Nan->new( $res ) ) if( POSIX::isnan( $res ) );
    return( $self->clone( $res ) );
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

sub _round
{
    my( $self, $num, $precision ) = @_;
    return( CORE::sprintf( '%.*f', $precision, $num ) );
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
        # I do not want to set a default value of '' to $self->{ $prop } because if its value is undef, it should remain so
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

sub FREEZE
{
    my $self = CORE::shift( @_ );
    my $serialiser = CORE::shift( @_ ) // '';
    my $class = CORE::ref( $self );
    my %hash  = %$self;
    # Return an array reference rather than a list so this works with Sereal and CBOR
    # On or before Sereal version 4.023, Sereal did not support multiple values returned
    CORE::return( [$class, \%hash] ) if( $serialiser eq 'Sereal' && Sereal::Encoder->VERSION <= version->parse( '4.023' ) );
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
