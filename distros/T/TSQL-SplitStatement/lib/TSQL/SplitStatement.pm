package TSQL::SplitStatement;

use 5.010;
use strict;
use warnings;

use English ;

use List::Util      qw(first max maxstr min minstr reduce shuffle sum);
use List::MoreUtils qw(indexes all any);
#use Data::Dumper;
#use Data::Dump 'pp';
use autodie qw(:all);
use Clone;
use base qw(Clone) ;

use TSQL::Common::Regexp;

## TODO :- 1 stop this warning Variable "$NestedBracketsRE" will not stay shared at (re_eval 215) line 2.

=head1 NAME

TSQL::SplitStatement - Implements similar functionality to SQL::SplitStatement, but for TSQL.  

=head1 VERSION

Version 0.15

=cut

our $VERSION = '0.15';



# -- **********************************************************

sub new {
    local $_             = undef ;
    my $invocant         = shift ;
    my $class            = ref($invocant) || $invocant ;
    my $self             = bless {}, $class ;

    return $self ;
}


sub splitSQL {

local $_             = undef ;

my $invocant         = shift ;
my $class            = ref($invocant) || $invocant ;

my $input            = shift ;


    
my $CommentIndex            = -1 ;

my $QIndex                  = -1 ;
my $SIndex                  = -1 ;
my $UnionIndex              = -1 ;
my $SubqueryIndex           = -1 ;
my $BracketsIndex           = -1 ;
my $CaseEndIndex            = -1 ;
my $InsertsIndex            = -1 ;
my $UpdatesIndex            = -1 ;

my $GrantOptionsIndex       = -1 ;
my $GrantsIndex             = -1 ;
my $DenysIndex              = -1 ;
my $RevokesIndex            = -1 ;

my $CursorSelectsIndex      = -1 ;
my $CursorForUpdatesIndex   = -1 ;

my $TerminatorIndex         = -1 ;


my $CommentRepl           = '____COMMENT_';

my $QRepl                 = '____QUOTEDID_';
my $SRepl                 = '____STRING_';
my $UnionRepl             = '____UNION_';
my $SubqueryRepl          = '____SUBQUERY_';
my $BracketsRepl          = '____BRACKETS_';
my $CaseEndRepl           = '____CASE_END_';
my $InsertsRepl           = '____INSERTS_SELECT_';
my $UpdatesRepl           = '____UPDATES_SET_';

my $GrantOptionsRepl      = '____GRANT_OPTION_';
my $GrantsRepl            = '____GRANT_SET_';
my $DenysRepl             = '____DENY_SET_';
my $RevokesRepl           = '____REVOKE_SET_';

my $CursorSelectsRepl     = '____CURSOR_FOR_SELECT_';
my $CursorForUpdatesRepl  = '____CURSOR_FOR_UPDATES_';


my $TerminatorRepl        = '____SEPARATOR_TOKEN_';


my @Comment_positions     = ();
my @Comment_replaces      = ();

my @Q_replaces            = ();
my @S_replaces            = ();
my @Union_replaces        = ();
my @Subquery_replaces     = ();
my @Brackets_replaces     = ();
my @CaseEnd_replaces      = ();
my @Inserts_replaces      = ();
my @Updates_replaces      = ();

my @GrantOptions_replaces = ();
my @Grants_replaces       = ();
my @Denys_replaces        = ();
my @Revokes_replaces      = ();

my @CursorSelects_replaces      = ();
my @CursorForUpdates_replaces   = ();
my @Terminator_replaces         = ();



#my $qr_Id = qr{[#_\w$@][#$:_.\w]*}x ;
my $qr_Id = TSQL::Common::Regexp->qr_id();

my $s = $input ;

# replace comments only .............

## Beware this is a valid name [abc[]]def]

$s =~ s!(?<string> [N]?'(?:(?:[^']) | (?:''))*' )
           |
         (?<doublequoted>"(?:(?:[^"])     | (?:""))*" )
           |
         (?<bracketquoted>\[  .*? \]  )
           |
         (?<comment>(?:(?:--.*?$)
           |
         (?:/[*].*?[*]/)\s*)+
        )
 ! if (defined($+{string})) {"$+{string}"} elsif (defined($+{doublequoted})) {"$+{doublequoted}"} elsif (defined($+{bracketquoted})) {"$+{bracketquoted}"}   elsif (defined($+{comment})) {${CommentIndex}++; $Comment_replaces[${CommentIndex}] = $+{comment} ; " ${CommentRepl}${CommentIndex} "} else {'z'} 
 !xigems ;

#print $s ; 
#exit;
# '


$CommentIndex         = -1 ;
$QIndex               = -1 ;
$SIndex               = -1 ;

# replace everything else ..............
#'
# hack around broken ? ^PREMATCH handling in 5.17
# and fixed $` handling
if ( $PERL_VERSION >= v5.17.0 ) {
    $s =~ s!(?<string>(?p) [N]?'(?:(?:[^']) | (?:''))*' )
               |
             (?<doublequoted>"(?:(?:[^"])     | (?:""))*" )
               |
             (?<bracketquoted>\[  .*? \]  )
               |
             (?<comment> \s____COMMENT_(?:\d)+\s
             )
     ! if (defined($+{string})) {${SIndex}++; $S_replaces[${SIndex}] = $+{string} ; " ${SRepl}${SIndex} "} elsif (defined($+{doublequoted})) {${QIndex}++; $Q_replaces[${QIndex}] = $+{doublequoted}; " ${QRepl}${QIndex} "} elsif (defined($+{bracketquoted})) {${QIndex}++; $Q_replaces[${QIndex}] = $+{bracketquoted}; " ${QRepl}${QIndex} "}  elsif (defined($+{comment})) {$CommentIndex++; $Comment_positions[$CommentIndex]=length($`); ' ';} else {'z'} 
     !xigems ;
}
else {
    $s =~ s!(?<string>(?p) [N]?'(?:(?:[^']) | (?:''))*' )
               |
             (?<doublequoted>"(?:(?:[^"])     | (?:""))*" )
               |
             (?<bracketquoted>\[  .*? \]  )
               |
             (?<comment> \s____COMMENT_(?:\d)+\s
             )
     ! if (defined($+{string})) {${SIndex}++; $S_replaces[${SIndex}] = $+{string} ; " ${SRepl}${SIndex} "} elsif (defined($+{doublequoted})) {${QIndex}++; $Q_replaces[${QIndex}] = $+{doublequoted}; " ${QRepl}${QIndex} "} elsif (defined($+{bracketquoted})) {${QIndex}++; $Q_replaces[${QIndex}] = $+{bracketquoted}; " ${QRepl}${QIndex} "}  elsif (defined($+{comment})) {$CommentIndex++; $Comment_positions[$CommentIndex]=length(${^PREMATCH}); ' ';} else {'z'} 
     !xigems ;
}

# ! if (defined($1)) {${SIndex}++; $S_replaces[${SIndex}] = $1 ; " ${SRepl}${SIndex} "} elsif (defined($2)) {${QIndex}++; $Q_replaces[${QIndex}] = $2; " ${QRepl}${QIndex} "} elsif (defined($3)) {${QIndex}++; $Q_replaces[${QIndex}] = $3; " ${QRepl}${QIndex} "}  elsif (defined($4)) {$CommentIndex++; $Comment_positions[$CommentIndex]=length(${^PREMATCH}); ' ';} else {'z'} 
# '
 
#$s =~ s!([N]?'(?:(?:[^'])|(?:''))*')
# ! if (defined($1)) {'a'} else {'z'} 
# !xgei ;

#pp @Comment_replaces ;
 
#print $s ; 
#exit;


$s =~ s!(\b(?:union|intersect|minus)(?:\s+all)?\s+select\b)
 ! ${UnionIndex}++; $Union_replaces[${UnionIndex}] = $1 ; " ${UnionRepl}${UnionIndex} "; 
 !xigems ;

#warn Dumper @Union_replaces ;

no warnings ;
my $NestedBracketsRE = qr{
                            (                       # start of capture buffer 1
                                \(                  # match an opening bracket
                                    (?:               
                                        [^()]++     # one or more non brackets, non back+tracking
                                      |                  
                                        (?1)        # found ( or ), so recurse to capture buffer 1
                                    )*                 
                                \)                  # match a closing bracket
                             )                      # end of capture buffer 1
                         }ixms;
my $OuterSubQueryRE = qr{
                            (?:                     # start of capture buffer 1
                                \(                  # match an opening bracket
                                \s*select\b         # match select
                                    (?:               
                                        [^()]++     # one or more non brackets, non back+tracking
                                      |                  
                                        (??{$NestedBracketsRE})        # found ( or ), so recurse to $NestedBracketsRE
                                    )*                 
                                \)                  # match a closing bracket
                             )                      # end of capture buffer 1
                        }ixms;

use warnings ;

$s =~ s!(${OuterSubQueryRE})
 ! ${SubqueryIndex}++; $Subquery_replaces[${SubqueryIndex}] = $1 ; " ${SubqueryRepl}${SubqueryIndex} "; 
 !xigems ;

$s =~ s!(${NestedBracketsRE})
 ! ${BracketsIndex}++; $Brackets_replaces[${BracketsIndex}] = $1 ; " ${BracketsRepl}${BracketsIndex} "; 
 !xigems ;

my $CaseEndRE = qr{
                     (                      # start of capture buffer 1
                        (?: \b case \b)     # match an opening case
                            (?:               
                                .*? (?= \b (?:case|end) \b )     # minimal match up to case or end
                              |                  
                                (?1)        # found case or end, so recurse to capture buffer 1
                            )*                 
                        (?: \b end \b)      # match a closing end
                     )                      # end of capture buffer 1
                  }ixms;

$s =~ s!(${CaseEndRE})
 ! ${CaseEndIndex}++; $CaseEnd_replaces[${CaseEndIndex}] = $1 ; " ${CaseEndRepl}${CaseEndIndex} "; 
 !xigems ;

$s =~ s!\b
           ( DECLARE\s+ (?:${qr_Id}) (?:\s+ (?: (?:(?:INSENSITIVE|SCROLL) \s+ CURSOR)
                                       |
                                       (?:CURSOR \s+ (?: (?:LOCAL|GLOBAL) \s+)? ) 
                                         (?:\w+)
                                       )
                                )
           )
        \s+(for\s+select)
        \b
 ! ${CursorSelectsIndex}++; $CursorSelects_replaces[${CursorSelectsIndex}] = $2 ; "${1} ${CursorSelectsRepl}${CursorSelectsIndex} "; 
 !xigems ;

$s =~ s!\b(FOR\s+UPDATE(?:\s+OF\b)?)
 ! ${CursorForUpdatesIndex}++; $CursorForUpdates_replaces[${CursorForUpdatesIndex}] = $1 ; " ${CursorForUpdatesRepl}${CursorForUpdatesIndex} "; 
 !xigems ;

$s =~ s!  \b( insert (?:\s+into)? \s+ \S+ \s* (?: with \s* ____BRACKETS_\d+ )? \s* (?: ____BRACKETS_\d+ )? \s* )
          (
            (?:select)
               |
            (?:values)
               |
            (?:exec(?:ute)?)
          )
 ! ${InsertsIndex}++; $Inserts_replaces[${InsertsIndex}] = $2 ; "${1} ${InsertsRepl}${InsertsIndex} "; 
 !xigems ;

$s =~ s!(\bupdate\b.*?)\b(set)\b
 ! ${UpdatesIndex}++; $Updates_replaces[${UpdatesIndex}] = $2 ; "${1} ${UpdatesRepl}${UpdatesIndex} "; 
 !xigems ;

# do grant option first as it contains the word grant then ..............
$s =~ s!\b((?:(?:WITH\s+GRANT\s+OPTION)|(?:GRANT\s+OPTION\s+FOR)))\b
 ! ${GrantOptionsIndex}++; $GrantOptions_replaces[${GrantOptionsIndex}] = $2 ; "${1} ${GrantOptionsRepl}${GrantOptionsIndex} "; 
 !xigems ;
# do revoke next as it contains the word grant
$s =~ s!(\brevoke\b)( .*? \b (?:to|from) \b)
 ! ${RevokesIndex}++; $Revokes_replaces[${RevokesIndex}] = $2 ; "${1} ${RevokesRepl}${RevokesIndex} "; 
 !xigems ;

$s =~ s!(\bdeny\b)( .*? \b on \b)
 ! ${DenysIndex}++; $Denys_replaces[${DenysIndex}] = $2 ; "${1} ${DenysRepl}${DenysIndex} "; 
 !xigems ;

$s =~ s!(\bgrant\b)( .*? \b to \b)
 ! ${GrantsIndex}++; $Grants_replaces[${GrantsIndex}] = $2 ; "${1} ${GrantsRepl}${GrantsIndex} "; 
 !xigems ;

#print $s ; 

#print "!!\n";

#warn Dumper @S_replaces ;
#warn Dumper @Q_replaces ;
#warn Dumper @Subquery_replaces ;
#warn Dumper @Brackets_replaces ;
#warn Dumper @Inserts_replaces ;
#warn Dumper @Updates_replaces ;
#warn Dumper @CursorForUpdates_replaces ;
#warn Dumper @CursorSelects_replaces ;
#warn Dumper @GrantOptions_replaces ;
#warn Dumper @Revokes_replaces ;
#warn Dumper @Denys_replaces ;
#warn Dumper @Grants_replaces ;

#my ($TokeniserPos,$TokeniserNext) = TSQL::SplitStatement->tokeniser() ;
# cache this variable for efficiency
state $TokeniserPos ;
if ( ! defined $TokeniserPos ) { $TokeniserPos = TSQL::SplitStatement->tokeniser() ; }

my @TokenPositions = () ;
#$s =~ s!( ${Tokeniser} )
# ! ${TerminatorIndex}++; $Terminator_replaces[${TerminatorIndex}] = $2 ; "${1} ${TerminatorRepl}${TerminatorIndex} \n"; 
# !xigems ;

#need to  find places, in sweep 1 and replace backwards in sweep2
#$s =~ s! ( ${Tokeniser} )
# ! " ____SEPARATOR_TOKEN\n $1 "
# !xigems ;

# hack around broken ? ^PREMATCH handling in 5.17
# and fixed $` handling
if ( $PERL_VERSION >= v5.17.0 ) {
    while ( $s =~ m{${TokeniserPos}}xigms ) {
        push @TokenPositions, length($`) ;
    }
    foreach my $tokPos ( reverse @TokenPositions ) {
        substr($s, $tokPos, 0) = " ____SEPARATOR_TOKEN\n " ;
    }
}
else {
    while ( $s =~ m{${TokeniserPos}}xigms ) {
        push @TokenPositions, length(${^PREMATCH}) ;
    }
    foreach my $tokPos ( reverse @TokenPositions ) {
        substr($s, $tokPos, 0) = " ____SEPARATOR_TOKEN\n " ;
    }
}

#print $s ;


$s =~ s!\s____GRANT_SET_([\d]+)\s!$Grants_replaces[$1]!gx ;
$s =~ s!\s____DENY_SET_([\d]+)\s!$Denys_replaces[$1]!gx ;
$s =~ s!\s____REVOKE_SET_([\d]+)\s!$Revokes_replaces[$1]!gx ;
$s =~ s!\s____GRANT_OPTION_([\d]+)\s!$GrantOptions_replaces[$1]!gx ;

$s =~ s!\s____UPDATES_SET_([\d]+)\s!$Updates_replaces[$1]!gx ;
$s =~ s!\s____INSERTS_SELECT_([\d]+)\s!$Inserts_replaces[$1]!gx ;

$s =~ s!\s____CURSOR_FOR_UPDATES_([\d]+)\s!$CursorForUpdates_replaces[$1]!gx ;
$s =~ s!\s____CURSOR_FOR_SELECT_([\d]+)\s!$CursorSelects_replaces[$1]!gx ;

$s =~ s!\s____CASE_END_([\d]+)\s!$CaseEnd_replaces[$1]!gx ;

$s =~ s!\s____BRACKETS_([\d]+)\s!$Brackets_replaces[$1]!gx ;
$s =~ s!\s____SUBQUERY_([\d]+)\s!$Subquery_replaces[$1]!gx ;
$s =~ s!\s____UNION_([\d]+)\s!$Union_replaces[$1]!gx ;
$s =~ s!\s____STRING_([\d]+)\s!$S_replaces[$1]!gx ; 
$s =~ s!\s____QUOTEDID_([\d]+)\s!$Q_replaces[$1]!gx ;

 
#print $s;

#my $idx = 0 ; 
#for my $comment_pos ( @Comment_positions ) {
#    substr($s, $comment_pos, 1," ____COMMENT_${idx} ")  ;
#    $idx++;
#} 
#
#$s =~ s!\s____COMMENT_([\d]+)\s!$Comment_replaces[$1]!gx ;
 
#print $s;

my @parsedInput = grep { $_ !~ /\A\s*\z/msx } split /\s*____SEPARATOR_TOKEN\s*/x,$s;

#pp @parsedInput ;
#
#my @tryblocks   = () ;
#my @blocks      = () ;
#my @ifs         = () ;
#my @whiles      = () ;
#
#
#my @begintryblocks          = indexes {/\Abegin\s+try\z/ims}    @parsedInput ;
#my @endtryblocks            = indexes {/\Aend\s+try\z/ims}      @parsedInput ;
#
#my @beginblocks             = indexes {/\Abegin\z/ims}    @parsedInput ;
#my @endblocks               = indexes {/\Aend\z/ims}      @parsedInput ;
#my @begincatchblocks        = indexes {/\Abegin\s+catch\z/ims}  @parsedInput ;
#my @endcatchblocks          = indexes {/\Aend\s+catch\z/ims}    @parsedInput ;
#my @ifstatements            = indexes {/\Aif\b/ims}  @parsedInput ;
#my @elsestatements          = indexes {/\Aelse\z/ims}  @parsedInput ;
#my @whilestatements         = indexes {/\Awhile\b/ims}    @parsedInput ;
#
#pp 'begin', @beginblocks ;
#pp 'end', @endblocks ;
#pp 'begin try', @begintryblocks ;
#pp 'end try', @endtryblocks ;
#pp 'begin catch', @begincatchblocks ;
#pp 'end catch', @endcatchblocks ;
#
#pp 'ifstatements',@ifstatements ;
#pp 'elsestatements',@elsestatements ;
#pp 'whilestatements',@whilestatements ;

my @cp_parsedInput = @parsedInput;

#my $blockCount = scalar @beginblocks ;
#my @bl = () ;
#while ( $blockCount > 0 ) {
#     foreach my $i (@beginblocks) {
#     }
#}
#my $done = 0 ;
##while (! $done ) {
#    my @blocks  = grep { my $b = $_; #my $e = first { my $e = $_ ; $e > $b and none { my $b2 = $_; $b2 > $b and $b2 < $e 
#                                    #                                      } @beginblocks 
#                                    #      } @endblocks 
#                      ; [$b] ; #,$e]                                           
#                      } @beginblocks ;
#    $done = 1;                      
##}
#
#pp @blocks;

return @parsedInput ;
} 


sub tokeniser {
#
#my $qr_Id = q{(?:[#_\w$@][#$:_.\w]*)} ;
my $qr_Id = TSQL::Common::Regexp->qr_id();
#my $qr_label = q{(?:[#_\w$@][#$:_.\w]*[:])};
my $qr_label = TSQL::Common::Regexp->qr_label();

## add a backup create/drop/alter generic statement
## to cater for create xml index ???

my @Phrases = 
(       [q{(?:\b(?<![#@])ENABLE\s+TRIGGER\b)}                            , q{ENABLE_TRIGGER}                         ]
,       [q{(?:\b(?<![#@])DISABLE\s+TRIGGER\b)}                           , q{DISABLE_TRIGGER}                        ]
,       [q{(?:\b(?<![#@])WAITFOR\b)}                                     , q{WAITFOR}                                ]
,       [qq{(?:\\b(?<![#\@])DECLARE\\s+(?:[@]${qr_Id}))}                 , q{DECLARE}                                ]
,       [q{(?:\b(?<![#@])READTEXT\b)}                                    , q{READTEXT}                               ]
,       [q{(?:\b(?<![#@])UPDATETEXT\b)}                                  , q{UPDATETEXT}                             ]
,       [q{(?:\b(?<![#@])WRITETEXT\b)}                                   , q{WRITETEXT}                              ]
,       [q{(?:\b(?<![#@])ADD\s+SIGNATURE\b)}                             , q{ADD_SIGNATURE}                          ]
,       [q{(?:\b(?<![#@])ALTER\s+APPLICATION\s+ROLE\b)}                  , q{ALTER_APPLICATION_ROLE}                 ]
,       [q{(?:\b(?<![#@])ALTER\s+ASSEMBLY\b)}                            , q{ALTER_ASSEMBLY}                         ]
,       [q{(?:\b(?<![#@])ALTER\s+ASYMMETRIC\s+KEY\b)}                    , q{ALTER_ASYMMETRIC_KEY}                   ]                    
,       [q{(?:\b(?<![#@])ALTER\s+AUTHORIZATION\b)}                       , q{ALTER_AUTHORIZATION}                    ]                       
,       [q{(?:\b(?<![#@])ALTER\s+CERTIFICATE\b)}                         , q{ALTER_CERTIFICATE}                      ]                         
,       [q{(?:\b(?<![#@])ALTER\s+CREDENTIAL\b)}                          , q{ALTER_CREDENTIAL}                       ]                          
,       [q{(?:\b(?<![#@])ALTER\s+DATABASE\b)}                            , q{ALTER_DATABASE}                         ]                            
,       [q{(?:\b(?<![#@])ALTER\s+ENDPOINT\b)}                            , q{ALTER_ENDPOINT}                         ]                            
,       [q{(?:\b(?<![#@])ALTER\s+FULLTEXT\s+CATALOG\b)}                  , q{ALTER_FULLTEXT_CATALOG}                 ]                  
,       [q{(?:\b(?<![#@])ALTER\s+FULLTEXT\s+INDEX\b)}                    , q{ALTER_FULLTEXT_INDEX}                   ]                    
,       [q{(?:\b(?<![#@])ALTER\s+FUNCTION\b (:?.*?) \bRETURNS\b )}       , q{ALTER_FUNCTION}                         ]                               
,       [q{(?:\b(?<![#@])ALTER\s+INDEX\b)}                               , q{ALTER_INDEX}                            ]                               
,       [q{(?:\b(?<![#@])ALTER\s+LOGIN\b)}                               , q{ALTER_LOGIN}                            ]                               
,       [q{(?:\b(?<![#@])ALTER\s+MASTER\s+KEY\b)}                        , q{ALTER_MASTER_KEY}                       ]                        
,       [q{(?:\b(?<![#@])ALTER\s+MESSAGE\s+TYPE\b)}                      , q{ALTER_MESSAGE_TYPE}                     ]                      
,       [q{(?:\b(?<![#@])ALTER\s+PARTITION\s+FUNCTION\b)}                , q{ALTER_PARTITION_FUNCTION}               ]                
,       [q{(?:\b(?<![#@])ALTER\s+PARTITION\s+SCHEME\b)}                  , q{ALTER_PARTITION_SCHEME}                 ]                  
,       [q{(?:\b(?<![#@])ALTER\s+PROC(?:EDURE)?\b)(:?.*?) \bAS\b }       , q{ALTER_PROCEDURE}                        ]       
,       [q{(?:\b(?<![#@])ALTER\s+QUEUE\b)}                               , q{ALTER_QUEUE}                            ]                               
,       [q{(?:\b(?<![#@])ALTER\s+REMOTE\s+SERVICE\s+BINDING\b)}          , q{ALTER_REMOTE_SERVICE_BINDING}           ]          
,       [q{(?:\b(?<![#@])ALTER\s+ROLE\b)}                                , q{ALTER_ROLE}                             ]                                
,       [q{(?:\b(?<![#@])ALTER\s+ROUTE\b)}                               , q{ALTER_ROUTE}                            ]                               
,       [q{(?:\b(?<![#@])ALTER\s+SCHEMA\b)}                              , q{ALTER_SCHEMA}                           ]                              
,       [q{(?:\b(?<![#@])ALTER\s+SERVICE\b)}                             , q{ALTER_SERVICE}                          ]                             
,       [q{(?:\b(?<![#@])ALTER\s+SERVICE\s+MASTER\s+KEY\b)}              , q{ALTER_SERVICE_MASTER_KEY}               ]              
,       [q{(?:\b(?<![#@])ALTER\s+SYMMETRIC\s+KEY\b)}                     , q{ALTER_SYMMETRIC_KEY}                    ]                     
,       [q{(?:\b(?<![#@])ALTER\s+TABLE\b)}                               , q{ALTER_TABLE}                            ]                               
,       [q{(?:\b(?<![#@])ALTER\s+TRIGGER\b (:?.*?) \bAS\b)}              , q{ALTER_TRIGGER}                          ]                             
,       [q{(?:\b(?<![#@])ALTER\s+USER\b)}                                , q{ALTER_USER}                             ]                                
,       [q{(?:\b(?<![#@])ALTER\s+VIEW\b)}                                , q{ALTER_VIEW}                             ]                                
,       [q{(?:\b(?<![#@])ALTER\s+XML\s+SCHEMA\s+COLLECTION\b)}           , q{ALTER_XML_SCHEMA_COLLECTION}            ]           
,       [q{(?:\b(?<![#@])BACKUP\s+(?:TRANSACTION|LOG)\b)}                , q{BACKUP_TRANSACTION_LOG}                 ]
,       [q{(?:\b(?<![#@])BACKUP\s+CERTIFICATE\b)}                        , q{BACKUP_CERTIFICATE}                     ]                        
,       [q{(?:\b(?<![#@])BACKUP\s+MASTER\s+KEY\b)}                       , q{BACKUP_MASTER_KEY}                      ]                       
,       [q{(?:\b(?<![#@])BACKUP\s+SERVICE\s+MASTER\s+KEY\b)}             , q{BACKUP_SERVICE_MASTER_KEY}              ]             
,       [q{(?:\b(?<![#@])BEGIN\b)}                                       , q{BEGIN}                                  ]                                       
,       [q{(?:\b(?<![#@])BEGIN\s+TRAN(?:SACTION)?\b)}                    , q{BEGIN_TRANSACTION}                      ]                    
,       [q{(?:\b(?<![#@])BEGIN\s+CATCH\b)}                               , q{BEGIN_CATCH}                            ]        
,       [q{(?:\b(?<![#@])BEGIN\s+CONVERSATION\s+TIMER\b)}                , q{BEGIN_CONVERSATION_TIMER}               ]      
,       [q{(?:\b(?<![#@])BEGIN\s+DIALOG\s+CONVERSATION\b)}               , q{BEGIN_DIALOG_CONVERSATION}              ]      
,       [q{(?:\b(?<![#@])BEGIN\s+DISTRIBUTED\s+TRAN(?:SACTION)?\b)}      , q{BEGIN_DISTRIBUTED_TRANSACTION}          ]
,       [q{(?:\b(?<![#@])BEGIN\s+TRY\b)}                                 , q{BEGIN_TRY}                              ]        
,       [q{(?:\b(?<![#@])BREAK\b)}                                       , q{BREAK}                                  ]           
,       [q{(?:\b(?<![#@])BULK\s+INSERT\b)}                               , q{BULK_INSERT}                            ]       
,       [q{(?:\b(?<![#@])CHECKPOINT\b)}                                  , q{CHECKPOINT}                             ]         
,       [q{(?:\b(?<![#@])CLOSE\b)}                                       , q{CLOSE}                                  ]           
,       [q{(?:\b(?<![#@])CLOSE\s+MASTER\s+KEY\b)}                        , q{CLOSE_MASTER_KEY}                       ]      
,       [q{(?:\b(?<![#@])CLOSE\s+SYMMETRIC\s+KEY\b)}                     , q{CLOSE_SYMMETRIC_KEY}                    ]     
,       [q{(?:\b(?<![#@])COMMIT\b)}                                      , q{COMMIT}                                 ]
,       [q{(?:\b(?<![#@])COMMIT\s+TRAN(?:SACTION)?\b)}                   , q{COMMIT}                                 ]
,       [q{(?:\b(?<![#@])COMMIT\s+WORK\b)}                               , q{COMMIT}                                 ]
,       [q{(?:\b(?<![#@])CONTINUE\b)}                                    , q{CONTINUE}                               ]          
,       [q{(?:\b(?<![#@])CREATE\s+AGGREGATE\b)}                          , q{CREATE_AGGREGATE}                       ]       
,       [q{(?:\b(?<![#@])CREATE\s+APPLICATION\s+ROLE\b)}                 , q{CREATE_APPLICATION_ROLE}                ]      
,       [q{(?:\b(?<![#@])CREATE\s+ASSEMBLY\b)}                           , q{CREATE_ASSEMBLY}                        ]       
,       [q{(?:\b(?<![#@])CREATE\s+ASYMMETRIC\s+KEY\b)}                   , q{CREATE_ASYMMETRIC_KEY}                  ]    
,       [q{(?:\b(?<![#@])CREATE\s+CERTIFICATE\b)}                        , q{CREATE_CERTIFICATE}                     ]         
,       [q{(?:\b(?<![#@])CREATE\s+CONTRACT\b)}                           , q{CREATE_CONTRACT}                        ]        
,       [q{(?:\b(?<![#@])CREATE\s+CREDENTIAL\b)}                         , q{CREATE_CREDENTIAL}                      ]         
,       [q{(?:\b(?<![#@])CREATE\s+DATABASE\b)}                           , q{CREATE_DATABASE}                        ]       
,       [q{(?:\b(?<![#@])CREATE\s+DEFAULT\b)}                            , q{CREATE_DEFAULT}                         ]       
,       [q{(?:\b(?<![#@])CREATE\s+ENDPOINT\b)}                           , q{CREATE_ENDPOINT}                        ]       
,       [q{(?:\b(?<![#@])CREATE\s+EVENT\s+NOTIFICATION\b)}               , q{CREATE_EVENT_NOTIFICATION}              ]      
,       [q{(?:\b(?<![#@])CREATE\s+FULLTEXT\s+CATALOG\b)}                 , q{CREATE_FULLTEXT_CATALOG}                ]       
,       [q{(?:\b(?<![#@])CREATE\s+FULLTEXT\s+INDEX\b)}                   , q{CREATE_FULLTEXT_INDEX}                  ]       
,       [q{(?:\b(?<![#@])CREATE\s+FUNCTION\b (:?.*?) \bRETURNS\b )}      , q{CREATE_FUNCTION}                        ]       
,       [q{(?:\b(?<![#@])CREATE\s+INDEX\b)}                              , q{CREATE_INDEX}                           ]       
,       [q{(?:\b(?<![#@])CREATE\s+UNIQUE\s+INDEX\b)}                     , q{CREATE_INDEX}                           ]
,       [q{(?:\b(?<![#@])CREATE\s+UNIQUE\s+CLUSTERED\s+INDEX\b)}         , q{CREATE_INDEX}                           ]
,       [q{(?:\b(?<![#@])CREATE\s+UNIQUE\s+NONCLUSTERED\s+INDEX\b)}      , q{CREATE_INDEX}                           ]
,       [q{(?:\b(?<![#@])CREATE\s+CLUSTERED\s+INDEX\b)}                  , q{CREATE_INDEX}                           ]
,       [q{(?:\b(?<![#@])CREATE\s+NONCLUSTERED\s+INDEX\b)}               , q{CREATE_INDEX}                           ]
,       [q{(?:\b(?<![#@])CREATE\s+XML\s+INDEX\b)}                        , q{CREATE_XML_INDEX}                       ]     
,       [q{(?:\b(?<![#@])CREATE\s+PRIMARY\s+XML\s+INDEX\b)}              , q{CREATE_XML_INDEX}                       ]
,       [q{(?:\b(?<![#@])CREATE\s+LOGIN\b)}                              , q{CREATE_LOGIN}                           ]       
,       [q{(?:\b(?<![#@])CREATE\s+MASTER\s+KEY\b)}                       , q{CREATE_MASTER_KEY}                      ]     
,       [q{(?:\b(?<![#@])CREATE\s+MESSAGE\s+TYPE\b)}                     , q{CREATE_MESSAGE_TYPE}                    ]     
,       [q{(?:\b(?<![#@])CREATE\s+PARTITION\s+FUNCTION\b)}               , q{CREATE_PARTITION_FUNCTION}              ]      
,       [q{(?:\b(?<![#@])CREATE\s+PARTITION\s+SCHEME\b)}                 , q{CREATE_PARTITION_SCHEME}                ]       
,       [q{(?:\b(?<![#@])CREATE\s+PROC(?:EDURE)?\b)(:?.*?) \bAS\b }      , q{CREATE_PROCEDURE}                       ]       
,       [q{(?:\b(?<![#@])CREATE\s+QUEUE\b)}                              , q{CREATE_QUEUE}                           ]        
,       [q{(?:\b(?<![#@])CREATE\s+REMOTE\s+SERVICE\s+BINDING\b)}         , q{CREATE_REMOTE_SERVICE_BINDING}          ]   
,       [q{(?:\b(?<![#@])CREATE\s+ROLE\b)}                               , q{CREATE_ROLE}                            ]        
,       [q{(?:\b(?<![#@])CREATE\s+ROUTE\b)}                              , q{CREATE_ROUTE}                           ]        
,       [q{(?:\b(?<![#@])CREATE\s+RULE\b)}                               , q{CREATE_RULE}                            ]        
,       [q{(?:\b(?<![#@])CREATE\s+SCHEMA\b)}                             , q{CREATE_SCHEMA}                          ]        
,       [q{(?:\b(?<![#@])CREATE\s+SERVICE\b)}                            , q{CREATE_SERVICE}                         ]      
,       [q{(?:\b(?<![#@])CREATE\s+STATISTICS\b)}                         , q{CREATE_STATISTICS}                      ]      
,       [q{(?:\b(?<![#@])CREATE\s+SYMMETRIC\s+KEY\b)}                    , q{CREATE_SYMMETRIC_KEY}                   ]    
,       [q{(?:\b(?<![#@])CREATE\s+SYNONYM\b)}                            , q{CREATE_SYNONYM}                         ]        
,       [q{(?:\b(?<![#@])CREATE\s+TABLE\b)}                              , q{CREATE_TABLE}                           ]       

,       [q{(?:\b(?<![#@])CREATE\s+TRIGGER\b(?:.*?) \bAS\b )}             , q{CREATE_TRIGGER}                         ]      

,       [q{(?:\b(?<![#@])CREATE\s+TYPE\b)}                               , q{CREATE_TYPE}                            ]        
,       [q{(?:\b(?<![#@])CREATE\s+USER\b)}                               , q{CREATE_USER}                            ]        
,       [q{(?:\b(?<![#@])CREATE\s+VIEW\b)}                               , q{CREATE_VIEW}                            ]        
,       [q{(?:\b(?<![#@])CREATE\s+XML\s+SCHEMA\s+COLLECTION\b)}          , q{CREATE_XML_SCHEMA_COLLECTION}           ]     

,       [q{(?:\b(?<![#@])DBCC\b)}                                        , q{DBCC}                                   ]
,       [q{(?:\b(?<![#@])DEALLOCATE\b)}                                  , q{DEALLOCATE}                             ]
,       [qq{(?:\\b(?<![#\@])DECLARE\\s+(?:${qr_Id})(?:\\s+(?:(?:(?:INSENSITIVE|SCROLL)\\s+CURSOR)|(?:CURSOR\\s+(?:(?:LOCAL|GLOBAL)\\s+)?)(?:\\w+))))}                          
                                                                      , q{DECLARE_CURSOR}                         ]

,       [q{(?:\b(?<![#@])DELETE\b)}                                      , q{DELETE}                                 ]
,       [q{(?:\b(?<![#@])DENY\b)}                                        , q{DENY}                                   ]           
,       [q{(?:\b(?<![#@])DROP\s+AGGREGATE\b)}                            , q{DROP_AGGREGATE}                         ]               
,       [q{(?:\b(?<![#@])DROP\s+APPLICATION\s+ROLE\b)}                   , q{DROP_APPLICATION_ROLE}                  ]              
,       [q{(?:\b(?<![#@])DROP\s+ASSEMBLY\b)}                             , q{DROP_ASSEMBLY}                          ]                
,       [q{(?:\b(?<![#@])DROP\s+ASYMMETRIC\s+KEY\b)}                     , q{DROP_ASYMMETRIC_KEY}                    ]        
,       [q{(?:\b(?<![#@])DROP\s+CERTIFICATE\b)}                          , q{DROP_CERTIFICATE}                       ]             
,       [q{(?:\b(?<![#@])DROP\s+CONTRACT\b)}                             , q{DROP_CONTRACT}                          ]                
,       [q{(?:\b(?<![#@])DROP\s+CREDENTIAL\b)}                           , q{DROP_CREDENTIAL}                        ]              
,       [q{(?:\b(?<![#@])DROP\s+DATABASE\b)}                             , q{DROP_DATABASE}                          ]                
,       [q{(?:\b(?<![#@])DROP\s+DEFAULT\b)}                              , q{DROP_DEFAULT}                           ]         
,       [q{(?:\b(?<![#@])DROP\s+ENDPOINT\b)}                             , q{DROP_ENDPOINT}                          ]                
,       [q{(?:\b(?<![#@])DROP\s+EVENT\s+NOTIFICATION\b)}                 , q{DROP_EVENT_NOTIFICATION}                ]            
,       [q{(?:\b(?<![#@])DROP\s+FULLTEXT\s+CATALOG\b)}                   , q{DROP_FULLTEXT_CATALOG}                  ]              
,       [q{(?:\b(?<![#@])DROP\s+FULLTEXT\s+INDEX\b)}                     , q{DROP_FULLTEXT_INDEX}                    ]        
,       [q{(?:\b(?<![#@])DROP\s+FUNCTION\b)}                             , q{DROP_FUNCTION}                          ]                
,       [q{(?:\b(?<![#@])DROP\s+INDEX\b)}                                , q{DROP_INDEX}                             ]           
,       [q{(?:\b(?<![#@])DROP\s+LOGIN\b)}                                , q{DROP_LOGIN}                             ]           
,       [q{(?:\b(?<![#@])DROP\s+MASTER\s+KEY\b)}                         , q{DROP_MASTER_KEY}                        ]            
,       [q{(?:\b(?<![#@])DROP\s+MESSAGE\s+TYPE\b)}                       , q{DROP_MESSAGE_TYPE}                      ]          
,       [q{(?:\b(?<![#@])DROP\s+PARTITION\s+FUNCTION\b)}                 , q{DROP_PARTITION_FUNCTION}                ]            
,       [q{(?:\b(?<![#@])DROP\s+PARTITION\s+SCHEME\b)}                   , q{DROP_PARTITION_SCHEME}                  ]              
,       [q{(?:\b(?<![#@])DROP\s+PROC\b)}                                 , q{DROP_PROC}                              ]            
,       [q{(?:\b(?<![#@])DROP\s+PROCEDURE\b)}                            , q{DROP_PROCEDURE}                         ]               
,       [q{(?:\b(?<![#@])DROP\s+QUEUE\b)}                                , q{DROP_QUEUE}                             ]           
,       [q{(?:\b(?<![#@])DROP\s+REMOTE\s+SERVICE\s+BINDING\b)}           , q{DROP_REMOTE_SERVICE_BINDING}            ]      
,       [q{(?:\b(?<![#@])DROP\s+ROLE\b)}                                 , q{DROP_ROLE}                              ]            
,       [q{(?:\b(?<![#@])DROP\s+ROUTE\b)}                                , q{DROP_ROUTE}                             ]           
,       [q{(?:\b(?<![#@])DROP\s+RULE\b)}                                 , q{DROP_RULE}                              ]            
,       [q{(?:\b(?<![#@])DROP\s+SCHEMA\b)}                               , q{DROP_SCHEMA}                            ]          
,       [q{(?:\b(?<![#@])DROP\s+SERVICE\b)}                              , q{DROP_SERVICE}                           ]         
,       [q{(?:\b(?<![#@])DROP\s+SIGNATURE\b)}                            , q{DROP_SIGNATURE}                         ]               
,       [q{(?:\b(?<![#@])DROP\s+STATISTICS\b)}                           , q{DROP_STATISTICS}                        ]              
,       [q{(?:\b(?<![#@])DROP\s+SYMMETRIC\s+KEY\b)}                      , q{DROP_SYMMETRIC_KEY}                     ]         
,       [q{(?:\b(?<![#@])DROP\s+SYNONYM\b)}                              , q{DROP_SYNONYM}                           ]         
,       [q{(?:\b(?<![#@])DROP\s+TABLE\b)}                                , q{DROP_TABLE}                             ]           
,       [q{(?:\b(?<![#@])DROP\s+TRIGGER\b)}                              , q{DROP_TRIGGER}                           ]         
,       [q{(?:\b(?<![#@])DROP\s+TYPE\b)}                                 , q{DROP_TYPE}                              ]            
,       [q{(?:\b(?<![#@])DROP\s+USER\b)}                                 , q{DROP_USER}                              ]            
,       [q{(?:\b(?<![#@])DROP\s+VIEW\b)}                                 , q{DROP_VIEW}                              ]            
,       [q{(?:\b(?<![#@])DROP\s+XML\s+SCHEMA\s+COLLECTION\b)}            , q{DROP_XML_SCHEMA_COLLECTION}             ]       
,       [q{(?:\b(?<![#@])DUMP\s+(?:TRANSACTION|LOG)\b)}                  , q{DUMP}                                   ]
,       [q{(?:\b(?<![#@])ELSE\b)}                                        , q{ELSE}                                   ]           
,       [q{(?:\b(?<![#@])END\b)}                                         , q{END}                                    ]            
,       [q{(?:\b(?<![#@])END\s+CONVERSATION\b)}                          , q{END_CONVERSATION}                       ]             
,       [q{(?:\b(?<![#@])END\s+CATCH\b)}                                 , q{END_CATCH}                              ]            
,       [q{(?:\b(?<![#@])END\s+TRY\b)}                                   , q{END_TRY}                                ]              
,       [q{(?:\b(?<![#@])EXEC(?:UTE)?\b)}                                , q{EXECUTE}                                ]           
,       [q{(?:\b(?<![#@])EXEC(?:UTE)?\s+AS\b)}                           , q{EXECUTE_AS}                             ]      
,       [q{(?:\b(?<![#@])FETCH\b)}                                       , q{FETCH}                                  ]                  
,       [q{(?:\b(?<![#@])GET\s+CONVERSATION\s+GROUP\b)}                  , q{GET_CONVERSATION_GROUP}                 ]             
,       [q{(?:\b(?<![#@])GOTO\b)}                                        , q{GOTO}                                   ]           
,       [q{(?:\b(?<![#@])GO\b)}                                          , q{GO}                                     ]             
,       [q{(?:\b(?<![#@])GRANT\b)}                                       , q{GRANT}                                  ]                  
,       [q{(?:\b(?<![#@])IF\b)}                                          , q{IF}                                     ]             
,       [q{(?:\b(?<![#@])INSERT\b)}                                      , q{INSERT}                                 ]                 
,       [q{(?:\b(?<![#@])KILL\b)}                                        , q{KILL}                                   ]           
,       [q{(?:\b(?<![#@])KILL\s+QUERY\s+NOTIFICATION\s+SUBSCRIPTION\b)}  , q{KILL_QUERY_NOTIFICATION_SUBSCRIPTION}   ]  
,       [q{(?:\b(?<![#@])KILL\s+STATS\s+JOB\b)}                          , q{KILL_STATS_JOB}                         ]             
,       [q{(?:\b(?<![#@])LOAD\s+(?:TRANSACTION|LOG|HEADERONLY)\b)}       , q{LOAD}                                   ]
,       [q{(?:\b(?<![#@])MERGE\b)}                                       , q{MERGE}                                 ]                      
,       [q{(?:\b(?<![#@])MOVE\s+CONVERSATION\b)}                         , q{MOVE_CONVERSATION}                      ]            
,       [q{(?:\b(?<![#@])OPEN\b)}                                        , q{OPEN}                                   ]           
,       [q{(?:\b(?<![#@])PRINT\b)}                                       , q{PRINT}                                  ]                  
,       [q{(?:\b(?<![#@])RAISERROR\b)}                                   , q{RAISERROR}                              ]              
,       [q{(?:\b(?<![#@])RECEIVE\b)}                                     , q{RECEIVE}                                ]
,       [q{(?:\b(?<![#@])RESTORE\s+(?:SERVICE\s+)?MASTER\s+KEY\b)}       , q{RESTORE_SERVICE_MASTER_KEY}             ]          
,       [q{(?:\b(?<![#@])RESTORE\s+(?:TRANSACTION|LOG)\b)}               , q{RESTORE}                                ]
,       [q{(?:\b(?<![#@])RETURN\b)}                                      , q{RETURN}                                 ]                      
,       [q{(?:\b(?<![#@])REVERT\b)}                                      , q{REVERT}                                 ]                      
,       [q{(?:\b(?<![#@])REVOKE\b)}                                      , q{REVOKE}                                 ]                      
,       [q{(?:\b(?<![#@])ROLLBACK\b)}                                    , q{ROLLBACK}                               ]                            
,       [q{(?:\b(?<![#@])ROLLBACK\s+WORK\b)}                             , q{ROLLBACK}                               ]
,       [q{(?:\b(?<![#@])ROLLBACK\s+TRAN(?:SACTION)?\b)}                 , q{ROLLBACK}                               ]
,       [q{(?:\b(?<![#@])SAVE\s+TRAN(?:SACTION)?\b)}                     , q{SAVE_TRANSACTION}                       ]              
,       [q{(?:\b(?<![#@])SELECT\b)}                                      , q{SELECT}                                 ]
,       [qq{(?:\\b(?<![#\@])SELECT\\s+(?:[@]${qr_Id}))}                  , q{SELECT_VAR}                             ]
,       [q{(?:\b(?<![#@])SEND\s+ON\s+CONVERSATION\b)}                    , q{SEND_ON_CONVERSATION}                   ]                    
,       [q{(?:\b(?<![#@])SETUSER\b)}                                     , q{SETUSER}                                ]
,       [qq{(?:\\b(?<![#\@])SET\\s+(?:[@]${qr_Id}))}                     , q{SET_VAR}                                ]
,       [q{(?:\b(?<![#@])SET\s+TRANSACTION\s+ISOLATION\s+LEVEL\s+(?:READ\s+UNCOMMITTED|READ\s+COMMITTED|REPEATABLE\s+READ|SNAPSHOT|SERIALIZABLE))}
                                ,                                     , q{SET_TRANSACTION_ISOLATION_LEVEL}        ]
,       [q{(?:\b(?<![#@])SET\s+\w+(?:\s+(?:ON|OFF)\b)?)}                 , q{SET_OPTION}                             ]
,       [q{(?:\b(?<![#@])SHUTDOWN\b(?:\s+WITH\s+NOWAIT\b)?)}             , q{SHUTDOWN}                               ]
,       [q{(?:\b(?<![#@])TRUNCATE\s+TABLE\b)}                            , q{TRUNCATE_TABLE}                         ]                    
,       [q{(?:\b(?<![#@])UPDATE\b)}                                      , q{UPDATE}                                 ]                      
,       [q{(?:\b(?<![#@])UPDATE\b\s+STATISTICS\b)}                       , q{UPDATE_STATISTICS}                      ]                         
,       [q{(?:\b(?<![#@])USE\b)}                                         , q{USE}                                    ]                         
,       [q{(?:\b(?<![#@])WHILE\b)}                                       , q{WHILE}                                  ]                       

#,       [qq{(?:\\b(?<![#\@])WITH\\s+(?:${qr_Id})(?:\\s*____BRACKETS_\\d+)?\\s+\\bAS\\b)(?:\\s*____SUBQUERY_\\d+)(?:\\s*,\\s*____SUBQUERY_\\d+)*(?:\\s*(?:SELECT|INSERT|UPDATE|DELETE))}                            
#                                                                      , q{WITH} ]

,       [qq{(?:\\b(?<![#\@])WITH\\s+(?:${qr_Id})(?:\\s*____BRACKETS_\\d+)?\\s+\\bAS\\b)(?:\\s*____SUBQUERY_\\d+)(?:(?:\\s*,\\s*(?:${qr_Id})(?:\\s*____BRACKETS_\\d+)?\\s+\\bAS\\b)(?:\\s*____SUBQUERY_\\d+))*(?:\\s*(?:SELECT|INSERT|UPDATE|DELETE|MERGE))}                            
                                                                      , q{WITH} ]

,       [q{(?:\b(?<![#@])WITH\s+XMLNAMESPACES\s*____BRACKETS_\\d+\s+\bAS\b)(?:\s*____SUBQUERY_\d+)(?:\s*,\s*____SUBQUERY_\d+)*?(?:\s*(?:SELECT|INSERT|UPDATE|DELETE|MERGE))}                             
                                                                      , q{WITH_XMLNAMESPACES} ]
,       [q{(?:\b(?<![#@])OPEN\s+MASTER\s+KEY\s+DECRYPTION\s+BY\s+PASSWORD\b)}                             
                                                                      , q{OPEN__KEY} ]
,       [q{(?:\b(?<![#@])OPEN\s+SYMMETRIC\s+KEY\s+.*?\s+DECRYPTION\s+BY\s+(?:\b(?:CERTIFICATE|ASYMMETRIC\s+KEY|SYMMETRIC\s+KEY|PASSWORD)\b))}                             
                                                                      , q{OPEN_SYMMETRIC_KEY} ]
,       [q{(?:\b(?<![#@])RECONFIGURE\b(?:\s+WITH\s+OVERRIDE\b)?)}        , q{RECONFIGURE} ]
,       [q{\z}                                                        , q{} ]
)   ;

my %TERM_RE     = () ;
%TERM_RE        = map { my $key = $_->[0]; 
                        my $val = $_->[0] ; 
                        $key =~ s{^[^A-Z]*}{}x; 
                        ($key => $val); 
                      } @Phrases ;

#my $TERM_RE     = join '|', map { qr{$TERM_RE{$_}}xmsi} reverse sort keys %TERM_RE ;
my $TERM_RE     = qr{${qr_label}}xmsi . '|' . join '|', map { qr{$TERM_RE{$_}}xmsi} reverse sort keys %TERM_RE ;



#patch these in first - nasty hack on top of a hack
#with .......... infect everything, is there any other DDL it can find its way into ?
#also need to patch trigger creation so as not let the main parser incorrectly parse things before the AS 

$TERM_RE = qr{(?: \b(?:ALTER|CREATE)\b \s+ \bVIEW\b  \s+ \b(?:${qr_Id})\b (?:\s*____BRACKETS_\\d+)? (?: \s*  \bAS\b \s+(?: \bSELECT\b | (?: \bWITH\b .*? \bSELECT\b )))) }xmsi . "|" .
           qr{(?: \b(?:ALTER|CREATE)\b \s+ \bTRIGGER\b (?:.*?) \bAS\b ) }xmsi . "|" .
           qr{(?: \b(?:ALTER|CREATE)\b \s+ \bPROC(?:EDURE)?\b (?:.*?) \bAS\b ) }xmsi . "|" .
          "${TERM_RE}" ;



my $LBL_TERM_RE         = qr{ (?: (?: ${TERM_RE} ) .*?) (?= (?: (?: \b ${qr_label} \s+ )? (?: ${TERM_RE} ) ) ) }xmsi;

my $LBL_TERM_RE_OTHER   = qr{ \G (?: (?: \b ${qr_label} \s+ )? (?: ${TERM_RE} ) ) }xmsi;

#warn $LBL_TERM_RE  ;

   #return ($LBL_TERM_RE,$LBL_TERM_RE_OTHER) ;
   return $LBL_TERM_RE ;   

}

1;

__DATA__



=head1 SYNOPSIS

This is a simple module which tries to split TSQL code into simple, recognisable code elements.
It implements similar functionality to SQL::SplitStatement, but does so for TSQL. 
TSQL notoriously doesn't bother with statement separators or teminators.
There is no overlap with or dependency on SQL::SplitStatement.  
But being lazy, I've loosely based the documentation on that for SQL::SplitStatement.

=head1 DESCRIPTION

The module splits TSQL code into recognisable units..

It removes comments, distinguishes strings and quoted names from code, and then returns a list of TSQL statements and/or 'tokens'.

It splits the code by attempting to recognise the start of the statement
following the current one.  It uses a mix of Regular Expressions and Parse::RecDescent.

It's purely an adhoc, heuristic approach, and was written to suit my own immediate requirements.
The futher reaches of TSQL, including the less commonly used DDL statements are not covered.
There is some attempt to cover elements of TSQL introduced in SQL Server 2008, but there is nothing to cover SQL Server 2012.
It is a work in progress.  Bug reports are welcomed, but may not necessarily be acted upon.
Contributors are more than welcome.

=head1 DEPENDENCIES

TSQL::SplitStatement depends on the following modules:

=over 4

=item * L<List::Util>

=item * L<List::MoreUtils>

=item * L<Clone>

=item * L<autodie>

=back


=head1 AUTHOR

Ded MedVed, C<< <dedmedved at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-tsql-splitstatment at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=TSQL::SplitStatement>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 METHODS

=head2 C<new>

=over 4

=item * C<< TSQL::SplitStatement->new() >>

=back

It creates and returns a new TSQL::SplitStatement object. 

=head2 C<splitSQL>

=over 4

=item * C<< $sql_splitter->splitSQL( $sql_string ) >>

=back

This is the method which actually splits the SQL code into its atomic
components.

It returns a list containing the atomic statements, in the same order they
appear in the original SQL code. 

    my $sql_splitter = TSQL::SplitStatement->new();
    
    my @statements = $sql_splitter->splitSQL( 'SELECT 1;SELECT 2; );
    
    print 'The SQL code contains ' . scalar(@statements) . ' statements.';
    # The SQL code contains 2 statements.

=head2 C<tokeniser>

=over 4

=item * C<< TSQL::SplitStatement->tokeniser() >>

=back

This is the method which builds the regular expression that recognises the start of a TSQL statement.
Internal only.


=head1 LIMITATIONS

No limitations are currently known, as far as the intended usage is concerned.  
You *are* bound to uncover a large number of problems.
The handling of create procedure/trigger/function statements is problematic.

Please report any problematic cases.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc TSQL::SplitStatement


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=TSQL::SplitStatement>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/TSQL::SplitStatement>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/TSQL::SplitStatement>

=item * Search CPAN

L<http://search.cpan.org/dist/TSQL::SplitStatement/>

=back


=head1 ACKNOWLEDGEMENTS

=over 4

None yet.

=back


=head1 SEE ALSO

=over 4

=item * L<SQL::SplitStatement>

=back



=head1 LICENSE AND COPYRIGHT

Copyright 2012 Ded MedVed.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of TSQL::SplitStatement
