## Automatically generated, remove to re-configure!

package PDL::CCS::Config;
use strict;
use PDL qw();
our @ISA = qw(Exporter);
our (%ccsConfig);
our @EXPORT      = qw(ccs_indx);
our @EXPORT_OK   = ('%ccsConfig', 'ccs_indx');
our %EXPORT_TAGS = (config=>['%ccsConfig'], Func=>\@EXPORT, default=>\@EXPORT, all=>\@EXPORT_OK);

%ccsConfig = (
               'INDX_CTYPE' => 'PDL_Indx',
               'INDX_FUNC' => 'indx',
               'INDX_FUNCDEF' => '*ccs_indx = \\&PDL::indx; ##-- typecasting for CCS indices (deprecated)
',
               'INDX_SIG' => 'indx',
               'INDX_TYPEDEF' => 'typedef PDL_Indx CCS_Indx;  /**< typedef for CCS indices (deprecated) */
',
               'INT_TYPE_CHRS' => [
                                    'A',
                                    'B',
                                    'S',
                                    'U',
                                    'L',
                                    'K',
                                    'N',
                                    'P',
                                    'Q'
                                  ],
               'INT_TYPE_KEYS' => [
                                    'PDL_SB',
                                    'PDL_B',
                                    'PDL_S',
                                    'PDL_US',
                                    'PDL_L',
                                    'PDL_UL',
                                    'PDL_IND',
                                    'PDL_ULL',
                                    'PDL_LL'
                                  ],
               'INT_TYPE_MAX_IONAME' => 'longlong'
             );

*PDL::ccs_indx = *ccs_indx = \&PDL::indx; ##-- typecasting for CCS indices (deprecated)


1; ##-- be happy
