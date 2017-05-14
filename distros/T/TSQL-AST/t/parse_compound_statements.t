use Test::More tests => 21;
use Test::Deep;
use TSQL::SplitStatement;
use TSQL::AST;
use Data::Dumper;

use 5.010 ;
use warnings;
use strict;



subtest 'parseBatch', sub {

my $SQL = "begin try -- try
select case when 1=1 then 3 else 3 end
end try
begin catch
begin
end
end catch
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

	cmp_deeply($parsedOutput, $DumpedAST, "Simple batch with try/catch block parses ok");
};

subtest 'parseBlockIfElseFollowedByStatement', sub {

my $SQL = "begin
    if 1=1
        select 1
    else     
        select 2
    select 3    
end

go";

my $DumpedAST = bless( {
                 'script' => bless( {
                                      'batches' => [
                                                     bless( {
                                                              'statements' => [
                                                                                bless( {
                                                                                         'statements' => [
                                                                                                           bless( {
                                                                                                                    'ifBranch' => bless( {
                                                                                                                                           'tokenString' => 'select 1'
                                                                                                                                         }, 'TSQL::AST::SQLStatement' ),
                                                                                                                    'elseBranch' => bless( {
                                                                                                                                             'tokenString' => 'select 2'
                                                                                                                                           }, 'TSQL::AST::SQLStatement' ),
                                                                                                                    'condition' => bless( {
                                                                                                                                            'expression' => bless( {
                                                                                                                                                                     'tokenString' => ' 1=1'
                                                                                                                                                                   }, 'TSQL::AST::SQLFragment' )
                                                                                                                                          }, 'TSQL::AST::SQLConditionalExpression' )
                                                                                                                  }, 'TSQL::AST::SQLIfStatement' ),
                                                                                                           bless( {
                                                                                                                    'tokenString' => 'select 3'
                                                                                                                  }, 'TSQL::AST::SQLStatement' )
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

	cmp_deeply($parsedOutput, $DumpedAST, "Simple batch with block containing if statement else statement parses ok");
};

subtest 'parseBlockIfBlockElseFollowedByStatement', sub {

my $SQL = "begin
    if 1=1 begin
        select 1
    end        
    else     
        select 2
    select 3    
end
";

my $DumpedAST = bless( {
                 'script' => bless( {
                                      'batches' => [
                                                     bless( {
                                                              'statements' => [
                                                                                bless( {
                                                                                         'statements' => [
                                                                                                           bless( {
                                                                                                                    'ifBranch' => bless( {
                                                                                                                                           'statements' => [
                                                                                                                                                             bless( {
                                                                                                                                                                      'tokenString' => 'select 1'
                                                                                                                                                                    }, 'TSQL::AST::SQLStatement' )
                                                                                                                                                           ]
                                                                                                                                         }, 'TSQL::AST::SQLStatementBlock' ),
                                                                                                                    'elseBranch' => bless( {
                                                                                                                                             'tokenString' => 'select 2'
                                                                                                                                           }, 'TSQL::AST::SQLStatement' ),
                                                                                                                    'condition' => bless( {
                                                                                                                                            'expression' => bless( {
                                                                                                                                                                     'tokenString' => ' 1=1'
                                                                                                                                                                   }, 'TSQL::AST::SQLFragment' )
                                                                                                                                          }, 'TSQL::AST::SQLConditionalExpression' )
                                                                                                                  }, 'TSQL::AST::SQLIfStatement' ),
                                                                                                           bless( {
                                                                                                                    'tokenString' => 'select 3'
                                                                                                                  }, 'TSQL::AST::SQLStatement' )
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

	cmp_deeply($parsedOutput, $DumpedAST, "Simple batch with block containing if containing block with else containing statement parses ok");
};




subtest 'parseBlockIfBlockElseBlockFollowedByStatement', sub {

my $SQL = "begin
    if 1=1 begin
        select 1
    end        
    else begin
        select 2
    end
    select 3    
end
";

my $DumpedAST = bless( {
                 'script' => bless( {
                                      'batches' => [
                                                     bless( {
                                                              'statements' => [
                                                                                bless( {
                                                                                         'statements' => [
                                                                                                           bless( {
                                                                                                                    'ifBranch' => bless( {
                                                                                                                                           'statements' => [
                                                                                                                                                             bless( {
                                                                                                                                                                      'tokenString' => 'select 1'
                                                                                                                                                                    }, 'TSQL::AST::SQLStatement' )
                                                                                                                                                           ]
                                                                                                                                         }, 'TSQL::AST::SQLStatementBlock' ),
                                                                                                                    'elseBranch' => bless( {
                                                                                                                                             'statements' => [
                                                                                                                                                               bless( {
                                                                                                                                                                        'tokenString' => 'select 2'
                                                                                                                                                                      }, 'TSQL::AST::SQLStatement' )
                                                                                                                                                             ]
                                                                                                                                           }, 'TSQL::AST::SQLStatementBlock' ),
                                                                                                                    'condition' => bless( {
                                                                                                                                            'expression' => bless( {
                                                                                                                                                                     'tokenString' => ' 1=1'
                                                                                                                                                                   }, 'TSQL::AST::SQLFragment' )
                                                                                                                                          }, 'TSQL::AST::SQLConditionalExpression' )
                                                                                                                  }, 'TSQL::AST::SQLIfStatement' ),
                                                                                                           bless( {
                                                                                                                    'tokenString' => 'select 3'
                                                                                                                  }, 'TSQL::AST::SQLStatement' )
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

	cmp_deeply($parsedOutput, $DumpedAST, "Simple batch with block containing if containing block with else containing block parses ok");
};


subtest 'parseBlockIfBlockWithTryCatchElseBlockFollowedByStatement', sub {

my $SQL = "begin
    if 1=1 begin try
        select 1
    end try
    begin catch
        select 1.5
    end catch
    else begin
        select 2
    end
    select 3    
end
";

my $DumpedAST = bless( {
                 'script' => bless( {
                                      'batches' => [
                                                     bless( {
                                                              'statements' => [
                                                                                bless( {
                                                                                         'statements' => [
                                                                                                           bless( {
                                                                                                                    'ifBranch' => bless( {
                                                                                                                                           'catchBlock' => [
                                                                                                                                                             bless( {
                                                                                                                                                                      'tokenString' => 'select 1.5'
                                                                                                                                                                    }, 'TSQL::AST::SQLStatement' )
                                                                                                                                                           ],
                                                                                                                                           'tryBlock' => [
                                                                                                                                                           bless( {
                                                                                                                                                                    'tokenString' => 'select 1'
                                                                                                                                                                  }, 'TSQL::AST::SQLStatement' )
                                                                                                                                                         ]
                                                                                                                                         }, 'TSQL::AST::SQLTryCatchBlock' ),
                                                                                                                    'elseBranch' => bless( {
                                                                                                                                             'statements' => [
                                                                                                                                                               bless( {
                                                                                                                                                                        'tokenString' => 'select 2'
                                                                                                                                                                      }, 'TSQL::AST::SQLStatement' )
                                                                                                                                                             ]
                                                                                                                                           }, 'TSQL::AST::SQLStatementBlock' ),
                                                                                                                    'condition' => bless( {
                                                                                                                                            'expression' => bless( {
                                                                                                                                                                     'tokenString' => ' 1=1'
                                                                                                                                                                   }, 'TSQL::AST::SQLFragment' )
                                                                                                                                          }, 'TSQL::AST::SQLConditionalExpression' )
                                                                                                                  }, 'TSQL::AST::SQLIfStatement' ),
                                                                                                           bless( {
                                                                                                                    'tokenString' => 'select 3'
                                                                                                                  }, 'TSQL::AST::SQLStatement' )
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

	cmp_deeply($parsedOutput, $DumpedAST, "Simple batch with block containing if containing trycatch block with else containing block parses ok");
};



subtest 'parseBlockWithTryCatch', sub {

my $SQL = "begin
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

	cmp_deeply($parsedOutput, $DumpedAST, "Simple batch with trycatch block parses ok");
};


subtest 'parseTryWithWhileFollowedByStatementCatch', sub {

my $SQL = "begin try
    while 1=1 begin
        select 1
    end
    select 2    
end try
begin catch
    select 3
end catch

";

my $DumpedAST = bless( {
                 'script' => bless( {
                                      'batches' => [
                                                     bless( {
                                                              'statements' => [
                                                                                bless( {
                                                                                         'catchBlock' => [
                                                                                                           bless( {
                                                                                                                    'tokenString' => 'select 3'
                                                                                                                  }, 'TSQL::AST::SQLStatement' )
                                                                                                         ],
                                                                                         'tryBlock' => [
                                                                                                         bless( {
                                                                                                                  'body' => bless( {
                                                                                                                                     'statements' => [
                                                                                                                                                       bless( {
                                                                                                                                                                'tokenString' => 'select 1'
                                                                                                                                                              }, 'TSQL::AST::SQLStatement' )
                                                                                                                                                     ]
                                                                                                                                   }, 'TSQL::AST::SQLStatementBlock' ),
                                                                                                                  'condition' => bless( {
                                                                                                                                          'expression' => bless( {
                                                                                                                                                                   'tokenString' => ' 1=1'
                                                                                                                                                                 }, 'TSQL::AST::SQLFragment' )
                                                                                                                                        }, 'TSQL::AST::SQLConditionalExpression' )
                                                                                                                }, 'TSQL::AST::SQLWhileStatement' ),
                                                                                                         bless( {
                                                                                                                  'tokenString' => 'select 2'
                                                                                                                }, 'TSQL::AST::SQLStatement' )
                                                                                                       ]
                                                                                       }, 'TSQL::AST::SQLTryCatchBlock' )
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

	cmp_deeply($parsedOutput, $DumpedAST, "Simple batch with trycatch block containing while with block followed by statement parses ok");
};

subtest 'parseBlockWithWhilewithStatementFollowedByStatement', sub {

my $SQL = "begin
    while 1=1 
        select 1
    select 2    
end

";

my $DumpedAST = bless( {
                 'script' => bless( {
                                      'batches' => [
                                                     bless( {
                                                              'statements' => [
                                                                                bless( {
                                                                                         'statements' => [
                                                                                                           bless( {
                                                                                                                    'body' => bless( {
                                                                                                                                       'tokenString' => 'select 1'
                                                                                                                                     }, 'TSQL::AST::SQLStatement' ),
                                                                                                                    'condition' => bless( {
                                                                                                                                            'expression' => bless( {
                                                                                                                                                                     'tokenString' => ' 1=1'
                                                                                                                                                                   }, 'TSQL::AST::SQLFragment' )
                                                                                                                                          }, 'TSQL::AST::SQLConditionalExpression' )
                                                                                                                  }, 'TSQL::AST::SQLWhileStatement' ),
                                                                                                           bless( {
                                                                                                                    'tokenString' => 'select 2'
                                                                                                                  }, 'TSQL::AST::SQLStatement' )
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

	cmp_deeply($parsedOutput, $DumpedAST, "Simple batch containing while with statement followed by statement parses ok");
};

subtest 'parseBlockWithWhilewithBlockFollowedByStatement', sub {

my $SQL = "begin
    while 1=1 begin
        select 1
    end
    select 2    
end



";

my $DumpedAST = bless( {
                 'script' => bless( {
                                      'batches' => [
                                                     bless( {
                                                              'statements' => [
                                                                                bless( {
                                                                                         'statements' => [
                                                                                                           bless( {
                                                                                                                    'body' => bless( {
                                                                                                                                       'statements' => [
                                                                                                                                                         bless( {
                                                                                                                                                                  'tokenString' => 'select 1'
                                                                                                                                                                }, 'TSQL::AST::SQLStatement' )
                                                                                                                                                       ]
                                                                                                                                     }, 'TSQL::AST::SQLStatementBlock' ),
                                                                                                                    'condition' => bless( {
                                                                                                                                            'expression' => bless( {
                                                                                                                                                                     'tokenString' => ' 1=1'
                                                                                                                                                                   }, 'TSQL::AST::SQLFragment' )
                                                                                                                                          }, 'TSQL::AST::SQLConditionalExpression' )
                                                                                                                  }, 'TSQL::AST::SQLWhileStatement' ),
                                                                                                           bless( {
                                                                                                                    'tokenString' => 'select 2'
                                                                                                                  }, 'TSQL::AST::SQLStatement' )
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

	cmp_deeply($parsedOutput, $DumpedAST, "Simple batch with block containing while with block followed by statement parses ok");
};

subtest 'parseIfWithStatementFollowedByStatement', sub {

my $SQL = "if 1=1
    select 1
select 2
";

my $DumpedAST = bless( {
                 'script' => bless( {
                                      'batches' => [
                                                     bless( {
                                                              'statements' => [
                                                                                bless( {
                                                                                         'ifBranch' => bless( {
                                                                                                                'tokenString' => 'select 1'
                                                                                                              }, 'TSQL::AST::SQLStatement' ),
                                                                                         'condition' => bless( {
                                                                                                                 'expression' => bless( {
                                                                                                                                          'tokenString' => ' 1=1'
                                                                                                                                        }, 'TSQL::AST::SQLFragment' )
                                                                                                               }, 'TSQL::AST::SQLConditionalExpression' )
                                                                                       }, 'TSQL::AST::SQLIfStatement' ),
                                                                                bless( {
                                                                                         'tokenString' => 'select 2'
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

	cmp_deeply($parsedOutput, $DumpedAST, "Simple batch with If containing statement followed by statement parses ok");
};

subtest 'parseIfWithStatementElseWithStatementFollowedByStatement', sub {

my $SQL = "if 1=1
    select 1
else     
    select 2
select 3  
";

my $DumpedAST = bless( {
                 'script' => bless( {
                                      'batches' => [
                                                     bless( {
                                                              'statements' => [
                                                                                bless( {
                                                                                         'ifBranch' => bless( {
                                                                                                                'tokenString' => 'select 1'
                                                                                                              }, 'TSQL::AST::SQLStatement' ),
                                                                                         'elseBranch' => bless( {
                                                                                                                  'tokenString' => 'select 2'
                                                                                                                }, 'TSQL::AST::SQLStatement' ),
                                                                                         'condition' => bless( {
                                                                                                                 'expression' => bless( {
                                                                                                                                          'tokenString' => ' 1=1'
                                                                                                                                        }, 'TSQL::AST::SQLFragment' )
                                                                                                               }, 'TSQL::AST::SQLConditionalExpression' )
                                                                                       }, 'TSQL::AST::SQLIfStatement' ),
                                                                                bless( {
                                                                                         'tokenString' => 'select 3'
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

	cmp_deeply($parsedOutput, $DumpedAST, "Simple batch with If containing statement Else containing statement followed by statement parses ok");
};


subtest 'parseTryCatch', sub {

my $SQL = "begin try
        select 1
end try
begin catch
        select 2
end catch
";

my $DumpedAST = bless( {
                 'script' => bless( {
                                      'batches' => [
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
                                                            }, 'TSQL::AST::SQLBatch' )
                                                   ]
                                    }, 'TSQL::AST::SQLScript' )
               }, 'TSQL::AST' );


	my $parser = TSQL::SplitStatement->new();
	my @parsedInput = $parser->splitSQL($SQL);
	my $parser2 = TSQL::AST->new();
	my $parsedOutput= $parser2->parse(\@parsedInput);
	my $DumpedOutput = Dumper $parsedOutput;

	cmp_deeply($parsedOutput, $DumpedAST, "Simple try catch block parses ok");
};


subtest 'parseTryWithBlockCatch', sub {

my $SQL = "begin try
begin
        select 1
end        
end try
begin catch
        select 2
end catch

";

my $DumpedAST = bless( {
                 'script' => bless( {
                                      'batches' => [
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
                                                                                                                  'statements' => [
                                                                                                                                    bless( {
                                                                                                                                             'tokenString' => 'select 1'
                                                                                                                                           }, 'TSQL::AST::SQLStatement' )
                                                                                                                                  ]
                                                                                                                }, 'TSQL::AST::SQLStatementBlock' )
                                                                                                       ]
                                                                                       }, 'TSQL::AST::SQLTryCatchBlock' )
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

	cmp_deeply($parsedOutput, $DumpedAST, "Simple try containing block catch block parses ok");
};

subtest 'parseWhileStatementFollowedByStatement', sub {

my $SQL = "while 1=1
    select 1
select 2

";

my $DumpedAST = bless( {
                 'script' => bless( {
                                      'batches' => [
                                                     bless( {
                                                              'statements' => [
                                                                                bless( {
                                                                                         'body' => bless( {
                                                                                                            'tokenString' => 'select 1'
                                                                                                          }, 'TSQL::AST::SQLStatement' ),
                                                                                         'condition' => bless( {
                                                                                                                 'expression' => bless( {
                                                                                                                                          'tokenString' => ' 1=1'
                                                                                                                                        }, 'TSQL::AST::SQLFragment' )
                                                                                                               }, 'TSQL::AST::SQLConditionalExpression' )
                                                                                       }, 'TSQL::AST::SQLWhileStatement' ),
                                                                                bless( {
                                                                                         'tokenString' => 'select 2'
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

	cmp_deeply($parsedOutput, $DumpedAST, "Simple while containing statement followed by statement parses ok");
};


subtest 'parseWhileBlockFollowedByStatement', sub {

my $SQL = "while 1=1 begin
    select 1
    end
select 2
";

my $DumpedAST = bless( {
                 'script' => bless( {
                                      'batches' => [
                                                     bless( {
                                                              'statements' => [
                                                                                bless( {
                                                                                         'body' => bless( {
                                                                                                            'statements' => [
                                                                                                                              bless( {
                                                                                                                                       'tokenString' => 'select 1'
                                                                                                                                     }, 'TSQL::AST::SQLStatement' )
                                                                                                                            ]
                                                                                                          }, 'TSQL::AST::SQLStatementBlock' ),
                                                                                         'condition' => bless( {
                                                                                                                 'expression' => bless( {
                                                                                                                                          'tokenString' => ' 1=1'
                                                                                                                                        }, 'TSQL::AST::SQLFragment' )
                                                                                                               }, 'TSQL::AST::SQLConditionalExpression' )
                                                                                       }, 'TSQL::AST::SQLWhileStatement' ),
                                                                                bless( {
                                                                                         'tokenString' => 'select 2'
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

	cmp_deeply($parsedOutput, $DumpedAST, "Simple while containing block followed by statement parses ok");
};

subtest 'parseWhileBlockwithMultipleStatements', sub {

my $SQL = "while 1=1 begin
    select 1
    select 2    
end
";

my $DumpedAST =  bless( {
                 'script' => bless( {
                                      'batches' => [
                                                     bless( {
                                                              'statements' => [
                                                                                bless( {
                                                                                         'body' => bless( {
                                                                                                            'statements' => [
                                                                                                                              bless( {
                                                                                                                                       'tokenString' => 'select 1'
                                                                                                                                     }, 'TSQL::AST::SQLStatement' ),
                                                                                                                              bless( {
                                                                                                                                       'tokenString' => 'select 2'
                                                                                                                                     }, 'TSQL::AST::SQLStatement' )
                                                                                                                            ]
                                                                                                          }, 'TSQL::AST::SQLStatementBlock' ),
                                                                                         'condition' => bless( {
                                                                                                                 'expression' => bless( {
                                                                                                                                          'tokenString' => ' 1=1'
                                                                                                                                        }, 'TSQL::AST::SQLFragment' )
                                                                                                               }, 'TSQL::AST::SQLConditionalExpression' )
                                                                                       }, 'TSQL::AST::SQLWhileStatement' )
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

	cmp_deeply($parsedOutput, $DumpedAST, "Simple while containing multi statement block parses ok");
};

subtest 'parseIfWhile', sub {

my $SQL = "
if 1=1
    while 2=2
        select 1
select 2
";

my $DumpedAST =   bless( {
                 'script' => bless( {
                                      'batches' => [
                                                     bless( {
                                                              'statements' => [
                                                                                bless( {
                                                                                         'ifBranch' => bless( {
                                                                                                                'body' => bless( {
                                                                                                                                   'tokenString' => 'select 1'
                                                                                                                                 }, 'TSQL::AST::SQLStatement' ),
                                                                                                                'condition' => bless( {
                                                                                                                                        'expression' => bless( {
                                                                                                                                                                 'tokenString' => ' 2=2'
                                                                                                                                                               }, 'TSQL::AST::SQLFragment' )
                                                                                                                                      }, 'TSQL::AST::SQLConditionalExpression' )
                                                                                                              }, 'TSQL::AST::SQLWhileStatement' ),
                                                                                         'condition' => bless( {
                                                                                                                 'expression' => bless( {
                                                                                                                                          'tokenString' => ' 1=1'
                                                                                                                                        }, 'TSQL::AST::SQLFragment' )
                                                                                                               }, 'TSQL::AST::SQLConditionalExpression' )
                                                                                       }, 'TSQL::AST::SQLIfStatement' )
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

	cmp_deeply($parsedOutput, $DumpedAST, "Simple if statement containing while statement followed by statement parses ok");
};


subtest 'parseIfElseWhile', sub {

my $SQL = "
if 1=1
    select 1
else        
    while 2=2
        select 2
select 3
";

my $DumpedAST =   bless( {
                 'script' => bless( {
                                      'batches' => [
                                                     bless( {
                                                              'statements' => [
                                                                                bless( {
                                                                                         'ifBranch' => bless( {
                                                                                                                'tokenString' => 'select 1'
                                                                                                              }, 'TSQL::AST::SQLStatement' ),
                                                                                         'elseBranch' => bless( {
                                                                                                                  'body' => bless( {
                                                                                                                                     'tokenString' => 'select 2'
                                                                                                                                   }, 'TSQL::AST::SQLStatement' ),
                                                                                                                  'condition' => bless( {
                                                                                                                                          'expression' => bless( {
                                                                                                                                                                   'tokenString' => ' 2=2'
                                                                                                                                                                 }, 'TSQL::AST::SQLFragment' )
                                                                                                                                        }, 'TSQL::AST::SQLConditionalExpression' )
                                                                                                                }, 'TSQL::AST::SQLWhileStatement' ),
                                                                                         'condition' => bless( {
                                                                                                                 'expression' => bless( {
                                                                                                                                          'tokenString' => ' 1=1'
                                                                                                                                        }, 'TSQL::AST::SQLFragment' )
                                                                                                               }, 'TSQL::AST::SQLConditionalExpression' )
                                                                                       }, 'TSQL::AST::SQLIfStatement' ),
                                                                                bless( {
                                                                                         'tokenString' => 'select 3'
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

	cmp_deeply($parsedOutput, $DumpedAST, "Simple if statement containing while statement followed by statement parses ok");
};

subtest 'parseWhileIf', sub {

my $SQL = "
while 1=1
    if 2=2
        select 1
select 3
";

my $DumpedAST =     bless( {
                 'script' => bless( {
                                      'batches' => [
                                                     bless( {
                                                              'statements' => [
                                                                                bless( {
                                                                                         'body' => bless( {
                                                                                                            'ifBranch' => bless( {
                                                                                                                                   'tokenString' => 'select 1'
                                                                                                                                 }, 'TSQL::AST::SQLStatement' ),
                                                                                                            'condition' => bless( {
                                                                                                                                    'expression' => bless( {
                                                                                                                                                             'tokenString' => ' 2=2'
                                                                                                                                                           }, 'TSQL::AST::SQLFragment' )
                                                                                                                                  }, 'TSQL::AST::SQLConditionalExpression' )
                                                                                                          }, 'TSQL::AST::SQLIfStatement' ),
                                                                                         'condition' => bless( {
                                                                                                                 'expression' => bless( {
                                                                                                                                          'tokenString' => ' 1=1'
                                                                                                                                        }, 'TSQL::AST::SQLFragment' )
                                                                                                               }, 'TSQL::AST::SQLConditionalExpression' )
                                                                                       }, 'TSQL::AST::SQLWhileStatement' ),
                                                                                bless( {
                                                                                         'tokenString' => 'select 3'
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

	cmp_deeply($parsedOutput, $DumpedAST, "Simple while if statement containing if statement followed by statement parses ok");
};


subtest 'parseWhileIfElse', sub {

my $SQL = "
while 1=1
    if 2=2
        select 1
    else
        select 2
select 3
";

my $DumpedAST =    bless( {
                 'script' => bless( {
                                      'batches' => [
                                                     bless( {
                                                              'statements' => [
                                                                                bless( {
                                                                                         'body' => bless( {
                                                                                                            'ifBranch' => bless( {
                                                                                                                                   'tokenString' => 'select 1'
                                                                                                                                 }, 'TSQL::AST::SQLStatement' ),
                                                                                                            'elseBranch' => bless( {
                                                                                                                                     'tokenString' => 'select 2'
                                                                                                                                   }, 'TSQL::AST::SQLStatement' ),
                                                                                                            'condition' => bless( {
                                                                                                                                    'expression' => bless( {
                                                                                                                                                             'tokenString' => ' 2=2'
                                                                                                                                                           }, 'TSQL::AST::SQLFragment' )
                                                                                                                                  }, 'TSQL::AST::SQLConditionalExpression' )
                                                                                                          }, 'TSQL::AST::SQLIfStatement' ),
                                                                                         'condition' => bless( {
                                                                                                                 'expression' => bless( {
                                                                                                                                          'tokenString' => ' 1=1'
                                                                                                                                        }, 'TSQL::AST::SQLFragment' )
                                                                                                               }, 'TSQL::AST::SQLConditionalExpression' )
                                                                                       }, 'TSQL::AST::SQLWhileStatement' ),
                                                                                bless( {
                                                                                         'tokenString' => 'select 3'
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

	cmp_deeply($parsedOutput, $DumpedAST, "Simple while statement containing if statement with else followed by statement parses ok");
};

subtest 'parseWhileWhile', sub {

my $SQL = "
while 1=1
    while 2=2
        select 1
select 3
";

my $DumpedAST =   bless( {
                 'script' => bless( {
                                      'batches' => [
                                                     bless( {
                                                              'statements' => [
                                                                                bless( {
                                                                                         'body' => bless( {
                                                                                                            'body' => bless( {
                                                                                                                               'tokenString' => 'select 1'
                                                                                                                             }, 'TSQL::AST::SQLStatement' ),
                                                                                                            'condition' => bless( {
                                                                                                                                    'expression' => bless( {
                                                                                                                                                             'tokenString' => ' 2=2'
                                                                                                                                                           }, 'TSQL::AST::SQLFragment' )
                                                                                                                                  }, 'TSQL::AST::SQLConditionalExpression' )
                                                                                                          }, 'TSQL::AST::SQLWhileStatement' ),
                                                                                         'condition' => bless( {
                                                                                                                 'expression' => bless( {
                                                                                                                                          'tokenString' => ' 1=1'
                                                                                                                                        }, 'TSQL::AST::SQLFragment' )
                                                                                                               }, 'TSQL::AST::SQLConditionalExpression' )
                                                                                       }, 'TSQL::AST::SQLWhileStatement' ),
                                                                                bless( {
                                                                                         'tokenString' => 'select 3'
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

	cmp_deeply($parsedOutput, $DumpedAST, "Simple while statement containing while statement followed by statement parses ok");
};


