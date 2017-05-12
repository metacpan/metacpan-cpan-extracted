## Automatically generated, remove to re-configure!

package PDL::CCS::Config;
use PDL qw();
our @ISA = qw(Exporter);
our (%ccsConfig);
our @EXPORT      = qw(ccs_indx);
our @EXPORT_OK   = ('%ccsConfig', 'ccs_indx');
our %EXPORT_TAGS = (config=>['%ccsConfig'], Func=>\@Export, default=>\@EXPORT, all=>\@EXPORT_OK);

%ccsConfig = (
               'INT_TYPE_KEYS' => [
                                    'PDL_B',
                                    'PDL_S',
                                    'PDL_US',
                                    'PDL_L',
                                    'PDL_IND',
                                    'PDL_LL'
                                  ],
               'INDX_CTYPE' => 'PDL_Indx',
               'USE_PDL_INDX' => 1,
               'INT_TYPE_CHRS' => [
                                    'B',
                                    'S',
                                    'U',
                                    'L',
                                    'N',
                                    'Q'
                                  ],
               'INDX_SIG' => 'indx',
               'INDX_FUNC' => 'indx',
               'INDX_FUNCDEF' => '*ccs_indx = \\&PDL::indx; ##-- typecasting for CCS indices
',
               'INDX_TYPEDEF' => 'typedef PDL_Indx CCS_Indx;  /**< typedef for CCS indices */
'
             );

*PDL::ccs_indx = *ccs_indx = \&PDL::indx; ##-- typecasting for CCS indices


1; ##-- be happy
