package Test::Siebel::Srvrmgr::Daemon::Action::ListComps;

use base qw(Test::Siebel::Srvrmgr::Daemon::Action);
use utf8;

1;

__DATA__
srvrmgr> list comp

SV_NAME     CC_ALIAS              CC_NAME                               CT_ALIAS  CG_ALIAS      CC_RUNMODE   CP_DISP_RUN_STATE  CP_NUM_RUN_TASKS  CP_MAX_TASKS  CP_ACTV_MTS_PROCS  CP_MAX_MTS_PROCS  CP_START_TIME        CP_END_TIME          CP_STATUS  CC_INCARN_NO  CC_DESC_TEXT  
----------  --------------------  ------------------------------------  --------  ------------  -----------  -----------------  ----------------  ------------  -----------------  ----------------  -------------------  -------------------  ---------  ------------  ------------  
sieb__crm01  ClientAdmin           Client Administration                           System        Background   Ativado            0                 1                                                  2012-02-18 17:11:56                                                              
sieb__crm01  CommConfigMgr         Communications Configuration Manager            CommMgmt      Batch        Ativado            0                 20            1                  1                 2012-02-18 17:11:56                                                              
sieb__crm01  CommInboundMgr        Communications Inbound Manager                  CommMgmt      Batch        Ativado            0                 20            1                  1                 2012-02-18 17:11:56                                                              
sieb__crm01  CommOutboundMgr       Communications Outbound Manager                 CommMgmt      Batch        Ativado            0                 50            1                  1                 2012-02-18 17:11:56                                                              
sieb__crm01  CommSessionMgr        Communications Session Manager                  CommMgmt      Batch        Ativado            0                 20            1                  1                 2012-02-18 17:11:56                                                              
sieb__crm01  DbXtract              Database Extract                                Remote        Batch        Ativado            0                 10                                                 2012-02-18 17:11:56                                                              
sieb__crm01  EAIObjMgr_ptb         EAI Object Manager (PTB)                        EAI           Interactive  Ativado            0                 20            1                  1                 2012-02-18 17:11:56                                                              
sieb__crm01  MailMgr               Email Manager                                   CommMgmt      Background   Ativado            0                 20                                                 2012-02-18 17:11:56                                                              
sieb__crm01  EIM                   Enterprise Integration Mgr                      EAI           Batch        Ativado            0                 10                                                 2012-02-18 17:11:56                                                              
sieb__crm01  FSMSrvr               File System Manager                             System        Batch        Ativado            0                 20            1                  1                 2012-02-18 17:11:56                                                              
sieb__crm01  GenNewDb              Generate New Database                           Remote        Batch        Ativado            0                 1                                                  2012-02-18 17:11:56                                                              
sieb__crm01  GenTrig               Generate Triggers                               Workflow      Batch        Ativado            0                 1                                                  2012-02-18 17:11:56                                                              
sieb__crm01  PageMgr               Page Manager                                    CommMgmt      Background   Ativado            0                 20                                                 2012-02-18 17:11:56                                                              
sieb__crm01  PDbXtract             Parallel Database Extract                       Remote        Batch        Em execução        4                 10            1                  1                 2012-02-18 17:11:56                                                              
sieb__crm01  ServerMgr             Server Manager                                  System        Interactive  Em execução        1                 20                                                 2012-02-18 17:11:56                                                              
sieb__crm01  SRBroker              Server Request Broker                           System        Interactive  Em execução        10                100           1                  1                 2012-02-18 17:11:56                                                              
sieb__crm01  SRProc                Server Request Processor                        System        Interactive  Em execução        2                 20            1                  1                 2012-02-18 17:11:56                                                              
sieb__crm01  SynchMgr              Synchronization Manager                         Remote        Interactive  Ativado            0                 100           1                  1                 2012-02-18 17:11:56                                                              
sieb__crm01  TxnMerge              Transaction Merger                              Remote        Background   Em execução        1                 10                                                 2012-02-18 17:11:56                                                              
sieb__crm01  TxnProc               Transaction Processor                           Remote        Background   Em execução        1                 1                                                  2012-02-18 17:11:56                                                              
sieb__crm01  TxnRoute              Transaction Router                              Remote        Background   Em execução        3                 10                                                 2012-02-18 17:11:56                                                              
sieb__crm01  UpgKitBldr            Upgrade Kit Builder                             SiebAnywhere  Batch        Ativado            0                 1             1                  1                 2012-02-18 17:11:56                                                              
sieb__crm01  WorkActn              Workflow Action Agent                           Workflow      Background   Ativado            0                 5                                                  2012-02-18 17:11:56                                                              
sieb__crm01  WorkMon               Workflow Monitor Agent                          Workflow      Background   Em execução        1                 1                                                  2012-02-18 17:11:56                                                              
sieb__crm01  WfProcBatchMgr        Workflow Process Batch Manager                  Workflow      Batch        Ativado            0                 20            1                  1                 2012-02-18 17:11:56                                                              
sieb__crm01  WfProcMgr             Workflow Process Manager                        Workflow      Batch        Ativado            0                 20            1                  1                 2012-02-18 17:11:56                                                              
sieb__crm01  ePharmaObjMgr_ptb     ePharma Object Manager (PTB)                    LifeSciences  Interactive  Em execução        3                 60            1                  2                 2012-02-18 17:11:56                                                              

51 rows returned.

