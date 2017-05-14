use Test::More tests => 4;
use Test::Deep;
use TSQL::SplitStatement;
use TSQL::AST;
use Data::Dumper;

use 5.010 ;
use warnings;
use strict;



subtest 'parse2Batches', sub {

my $SQL = "begin try -- try
select case when 1=1 then 3 else 3 end
end try
begin catch
begin
end
end catch
go

begin
begin try
        select 1
end try
begin catch
        select 2
end catch
end
go";

my $DumpedAST = bless( {
                 'script' => bless( {
                                      'batches' => [
                                                     bless( {
                                                              'statements' => [
                                                                                bless( {
                                                                                         'catchBlock' => [
                                                                                                           bless( {
                                                                                                                    'statements' => []
                                                                                                                  }, 'TSQL::AST::SQLStatementBlock' )
                                                                                                         ],
                                                                                         'tryBlock' => [
                                                                                                         bless( {
                                                                                                                  'tokenString' => 'select case when 1=1 then 3 else 3 end'
                                                                                                                }, 'TSQL::AST::SQLStatement' )
                                                                                                       ]
                                                                                       }, 'TSQL::AST::SQLTryCatchBlock' )
                                                                              ]
                                                            }, 'TSQL::AST::SQLBatch' ),
                                                     bless( {
                                                              'statements' => [
                                                                                bless( {
                                                                                         'statements' => [
                                                                                                           bless( {
                                                                                                                    'catchBlock' => [
                                                                                                                                      bless( {
                                                                                                                                               'tokenString' => 'select 2'
                                                                                                                                             }, 'TSQL::AST::SQLStatement' )
                                                                                                                                    ],
                                                                                                                    'tryBlock' => [
                                                                                                                                    bless( {
                                                                                                                                             'tokenString' => 'select 1'
                                                                                                                                           }, 'TSQL::AST::SQLStatement' )
                                                                                                                                  ]
                                                                                                                  }, 'TSQL::AST::SQLTryCatchBlock' )
                                                                                                         ]
                                                                                       }, 'TSQL::AST::SQLStatementBlock' )
                                                                              ]
                                                            }, 'TSQL::AST::SQLBatch' )
                                                   ]
                                    }, 'TSQL::AST::SQLScript' )
               }, 'TSQL::AST' );

	my $parser = TSQL::SplitStatement->new();
	my @parsedInput = $parser->splitSQL($SQL);
	my $parser2 = TSQL::AST->new();
	my $parsedOutput= $parser2->parse(\@parsedInput);
	my $DumpedOutput = Dumper $parsedOutput;
#warn $DumpedAST;
#warn $DumpedOutput;

	cmp_deeply($parsedOutput, $DumpedAST, "Simple 2 batch script parses ok");
};



subtest 'parse2BatchesNoGo', sub {

my $SQL = "begin try -- try
select case when 1=1 then 3 else 3 end
end try
begin catch
begin
end
end catch
go

begin
begin try
        select 1
end try
begin catch
        select 2
end catch
end
";

my $DumpedAST = bless( {
                 'script' => bless( {
                                      'batches' => [
                                                     bless( {
                                                              'statements' => [
                                                                                bless( {
                                                                                         'catchBlock' => [
                                                                                                           bless( {
                                                                                                                    'statements' => []
                                                                                                                  }, 'TSQL::AST::SQLStatementBlock' )
                                                                                                         ],
                                                                                         'tryBlock' => [
                                                                                                         bless( {
                                                                                                                  'tokenString' => 'select case when 1=1 then 3 else 3 end'
                                                                                                                }, 'TSQL::AST::SQLStatement' )
                                                                                                       ]
                                                                                       }, 'TSQL::AST::SQLTryCatchBlock' )
                                                                              ]
                                                            }, 'TSQL::AST::SQLBatch' ),
                                                     bless( {
                                                              'statements' => [
                                                                                bless( {
                                                                                         'statements' => [
                                                                                                           bless( {
                                                                                                                    'catchBlock' => [
                                                                                                                                      bless( {
                                                                                                                                               'tokenString' => 'select 2'
                                                                                                                                             }, 'TSQL::AST::SQLStatement' )
                                                                                                                                    ],
                                                                                                                    'tryBlock' => [
                                                                                                                                    bless( {
                                                                                                                                             'tokenString' => 'select 1'
                                                                                                                                           }, 'TSQL::AST::SQLStatement' )
                                                                                                                                  ]
                                                                                                                  }, 'TSQL::AST::SQLTryCatchBlock' )
                                                                                                         ]
                                                                                       }, 'TSQL::AST::SQLStatementBlock' )
                                                                              ]
                                                            }, 'TSQL::AST::SQLBatch' )
                                                   ]
                                    }, 'TSQL::AST::SQLScript' )
               }, 'TSQL::AST' );

	my $parser = TSQL::SplitStatement->new();
	my @parsedInput = $parser->splitSQL($SQL);
	my $parser2 = TSQL::AST->new();
	my $parsedOutput= $parser2->parse(\@parsedInput);
	my $DumpedOutput = Dumper $parsedOutput;
#warn $DumpedAST;
#warn $DumpedOutput;

	cmp_deeply($parsedOutput, $DumpedAST, "Simple 2 batch script w/o final GO parses ok");

};

subtest 'parse3Batches', sub {

my $SQL = "begin try -- try
select case when 1=1 then 3 else 3 end
end try
begin catch
begin
end
end catch
go

begin
begin try
        select 1
end try
begin catch
        select 2
end catch
end

go

select 1


go
";

my $DumpedAST =  bless( {
                 'script' => bless( {
                                      'batches' => [
                                                     bless( {
                                                              'statements' => [
                                                                                bless( {
                                                                                         'catchBlock' => [
                                                                                                           bless( {
                                                                                                                    'statements' => []
                                                                                                                  }, 'TSQL::AST::SQLStatementBlock' )
                                                                                                         ],
                                                                                         'tryBlock' => [
                                                                                                         bless( {
                                                                                                                  'tokenString' => 'select case when 1=1 then 3 else 3 end'
                                                                                                                }, 'TSQL::AST::SQLStatement' )
                                                                                                       ]
                                                                                       }, 'TSQL::AST::SQLTryCatchBlock' )
                                                                              ]
                                                            }, 'TSQL::AST::SQLBatch' ),
                                                     bless( {
                                                              'statements' => [
                                                                                bless( {
                                                                                         'statements' => [
                                                                                                           bless( {
                                                                                                                    'catchBlock' => [
                                                                                                                                      bless( {
                                                                                                                                               'tokenString' => 'select 2'
                                                                                                                                             }, 'TSQL::AST::SQLStatement' )
                                                                                                                                    ],
                                                                                                                    'tryBlock' => [
                                                                                                                                    bless( {
                                                                                                                                             'tokenString' => 'select 1'
                                                                                                                                           }, 'TSQL::AST::SQLStatement' )
                                                                                                                                  ]
                                                                                                                  }, 'TSQL::AST::SQLTryCatchBlock' )
                                                                                                         ]
                                                                                       }, 'TSQL::AST::SQLStatementBlock' )
                                                                              ]
                                                            }, 'TSQL::AST::SQLBatch' ),
                                                     bless( {
                                                              'statements' => [
                                                                                bless( {
                                                                                         'tokenString' => 'select 1'
                                                                                       }, 'TSQL::AST::SQLStatement' )
                                                                              ]
                                                            }, 'TSQL::AST::SQLBatch' )
                                                   ]
                                    }, 'TSQL::AST::SQLScript' )
               }, 'TSQL::AST' );


	my $parser = TSQL::SplitStatement->new();
	my @parsedInput = $parser->splitSQL($SQL);
	my $parser2 = TSQL::AST->new();
	my $parsedOutput= $parser2->parse(\@parsedInput);
	my $DumpedOutput = Dumper $parsedOutput;
#warn $DumpedAST;
#warn $DumpedOutput;

	cmp_deeply($parsedOutput, $DumpedAST, "Simple 2 batch script parses ok");

};

subtest 'parse3BatchesNoGO', sub {

my $SQL = "begin try -- try
select case when 1=1 then 3 else 3 end
end try
begin catch
begin
end
end catch
go

begin
begin try
        select 1
end try
begin catch
        select 2
end catch
end

go

select 1


";

my $DumpedAST =  bless( {
                 'script' => bless( {
                                      'batches' => [
                                                     bless( {
                                                              'statements' => [
                                                                                bless( {
                                                                                         'catchBlock' => [
                                                                                                           bless( {
                                                                                                                    'statements' => []
                                                                                                                  }, 'TSQL::AST::SQLStatementBlock' )
                                                                                                         ],
                                                                                         'tryBlock' => [
                                                                                                         bless( {
                                                                                                                  'tokenString' => 'select case when 1=1 then 3 else 3 end'
                                                                                                                }, 'TSQL::AST::SQLStatement' )
                                                                                                       ]
                                                                                       }, 'TSQL::AST::SQLTryCatchBlock' )
                                                                              ]
                                                            }, 'TSQL::AST::SQLBatch' ),
                                                     bless( {
                                                              'statements' => [
                                                                                bless( {
                                                                                         'statements' => [
                                                                                                           bless( {
                                                                                                                    'catchBlock' => [
                                                                                                                                      bless( {
                                                                                                                                               'tokenString' => 'select 2'
                                                                                                                                             }, 'TSQL::AST::SQLStatement' )
                                                                                                                                    ],
                                                                                                                    'tryBlock' => [
                                                                                                                                    bless( {
                                                                                                                                             'tokenString' => 'select 1'
                                                                                                                                           }, 'TSQL::AST::SQLStatement' )
                                                                                                                                  ]
                                                                                                                  }, 'TSQL::AST::SQLTryCatchBlock' )
                                                                                                         ]
                                                                                       }, 'TSQL::AST::SQLStatementBlock' )
                                                                              ]
                                                            }, 'TSQL::AST::SQLBatch' ),
                                                     bless( {
                                                              'statements' => [
                                                                                bless( {
                                                                                         'tokenString' => 'select 1'
                                                                                       }, 'TSQL::AST::SQLStatement' )
                                                                              ]
                                                            }, 'TSQL::AST::SQLBatch' )
                                                   ]
                                    }, 'TSQL::AST::SQLScript' )
               }, 'TSQL::AST' );


	my $parser = TSQL::SplitStatement->new();
	my @parsedInput = $parser->splitSQL($SQL);
	my $parser2 = TSQL::AST->new();
	my $parsedOutput= $parser2->parse(\@parsedInput);
	my $DumpedOutput = Dumper $parsedOutput;
#warn $DumpedAST;
#warn $DumpedOutput;

	cmp_deeply($parsedOutput, $DumpedAST, "Simple 3 batch script w/o final GO parses ok");

};

