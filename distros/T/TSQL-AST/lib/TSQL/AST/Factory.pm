package TSQL::AST::Factory;
use warnings;

use feature "switch";
use 5.014;

use TSQL::AST::Token::Begin;
use TSQL::AST::Token::BeginCatch;
use TSQL::AST::Token::BeginTry;
use TSQL::AST::Token::Else;
use TSQL::AST::Token::End;
use TSQL::AST::Token::EndCatch;
use TSQL::AST::Token::EndTry;
use TSQL::AST::Token::GO;
use TSQL::AST::Token::If;
use TSQL::AST::Token::While;

use TSQL::AST::SQLFragment;
use TSQL::AST::SQLConditionalExpression;
use TSQL::AST::SQLIfStatement;
use TSQL::AST::SQLTryCatchBlock;
use TSQL::AST::SQLWhileStatement;
use TSQL::AST::SQLStatement;

use TSQL::AST::Token::CreateOrAlterFunction;
use TSQL::AST::Token::CreateOrAlterProcedure;
use TSQL::AST::Token::CreateOrAlterTrigger;
use TSQL::AST::Token::CreateOrAlterView;


use TSQL::Common::Regexp;

use Data::Dumper;
use Carp;

=head1 NAME

TSQL::AST::Factory - Builds various parsing objects.

=head1 VERSION

Version 0.03

=cut


#our \$VERSION  = '0.03';

my $qr_begintoken            //= TSQL::Common::Regexp->qr_begintoken();
my $qr_endtoken              //= TSQL::Common::Regexp->qr_endtoken();
my $qr_begintrytoken         //= TSQL::Common::Regexp->qr_begintrytoken();
my $qr_endtrytoken           //= TSQL::Common::Regexp->qr_endtrytoken();
my $qr_begincatchtoken       //= TSQL::Common::Regexp->qr_begincatchtoken();
my $qr_endcatchtoken         //= TSQL::Common::Regexp->qr_endcatchtoken();
my $qr_iftoken               //= TSQL::Common::Regexp->qr_iftoken();
my $qr_elsetoken             //= TSQL::Common::Regexp->qr_elsetoken();
my $qr_whiletoken            //= TSQL::Common::Regexp->qr_whiletoken();
my $qr_GOtoken               //= TSQL::Common::Regexp->qr_GOtoken();


my $qr_createproceduretoken  //= TSQL::Common::Regexp->qr_createproceduretoken();  
my $qr_alterproceduretoken   //= TSQL::Common::Regexp->qr_alterproceduretoken();  
my $qr_createtriggertoken    //= TSQL::Common::Regexp->qr_createtriggertoken();  
my $qr_altertriggertoken     //= TSQL::Common::Regexp->qr_altertriggertoken();  
my $qr_createviewtoken       //= TSQL::Common::Regexp->qr_createviewtoken();  
my $qr_alterviewtoken        //= TSQL::Common::Regexp->qr_alterviewtoken();  
my $qr_createfunctiontoken   //= TSQL::Common::Regexp->qr_createfunctiontoken();  
my $qr_alterfunctiontoken    //= TSQL::Common::Regexp->qr_alterfunctiontoken();  

sub makeToken  {

    local $_             = undef ;    
    
    my $invocant         = shift ;    
    my $class            = ref($invocant) || $invocant ;    
    
    my $input            = shift ;
    carp "Missing token input" if ! defined $input;

    my $o ;

    given ($input) {

        when ( m{$qr_begintoken}ix    )
                { $o = TSQL::AST::Token::Begin->new( tokenString => $input ) ; }

        when ( m{$qr_endtoken}ix      )
                { $o = TSQL::AST::Token::End->new( tokenString => $input ) ; }

        when ( m{$qr_begintrytoken}ix    )
                { $o = TSQL::AST::Token::BeginTry->new( tokenString => $input ) ; }

        when ( m{$qr_endtrytoken}ix      )
                { $o = TSQL::AST::Token::EndTry->new( tokenString => $input ) ; }

        when ( m{$qr_begincatchtoken}ix    )
                { $o = TSQL::AST::Token::BeginCatch->new( tokenString => $input ) ; }

        when ( m{$qr_endcatchtoken}ix      )
                { $o = TSQL::AST::Token::EndCatch->new( tokenString => $input ) ; }

        when ( m{$qr_elsetoken}ix      )
                { $o = TSQL::AST::Token::Else->new( tokenString => $input ) ; }

        when ( m{$qr_iftoken}ix  )
                { $o = TSQL::AST::Token::If->new( tokenString => $input ) ; }

        when ( m{$qr_GOtoken}ix  )
                { $o = TSQL::AST::Token::GO->new( tokenString => $input ) ; }

        when ( m{$qr_whiletoken}ix  )
                { $o = TSQL::AST::Token::While->new( tokenString => $input ) ; }


        when ( m{$qr_createproceduretoken}ix  )
                { $o = TSQL::AST::Token::CreateOrAlterProcedure->new( tokenString => $input ) ; }

        when ( m{$qr_alterproceduretoken}ix  )
                { $o = TSQL::AST::Token::CreateOrAlterProcedure->new( tokenString => $input ) ; }

        when ( m{$qr_createtriggertoken}ix  )
                { $o = TSQL::AST::Token::CreateOrAlterTrigger->new( tokenString => $input ) ; }

        when ( m{$qr_altertriggertoken}ix  )
                { $o = TSQL::AST::Token::CreateOrAlterTrigger->new( tokenString => $input ) ; }

        when ( m{$qr_createviewtoken}ix  )
                { $o = TSQL::AST::Token::CreateOrAlterView->new( tokenString => $input ) ; }

        when ( m{$qr_alterviewtoken}ix  )
                { $o = TSQL::AST::Token::CreateOrAlterView->new( tokenString => $input ) ; }

        when ( m{$qr_createfunctiontoken}ix  )
                { $o = TSQL::AST::Token::CreateOrAlterFunction->new( tokenString => $input ) ; }

        when ( m{$qr_alterfunctiontoken}ix  )
                { $o = TSQL::AST::Token::CreateOrAlterFunction->new( tokenString => $input ) ; }

    }

    return $o;  
}

sub makeStatement {

    local $_             = undef ;    
    
    my $invocant         = shift ;    
    my $class            = ref($invocant) || $invocant ;    

    my $input            = shift ;
    carp "Missing statement input" if ! defined $input;

    my $o ;
    
    given ($input) {
#        when ( m{\A \s* (?:\b if \b) \s* }xi    )
#                { $o = TSQL::AST::SQLIfStatement->new( tokenString => $input ) ; }
#        when ( m{\A \s* (?:\b begin \b \s* \b try \b ) \s* \z }xi    )
#                { $o = TSQL::AST::SQLTryCatchBlock->new( tokenString => $input ) ; 
#                }
#        when ( m{\A \s* (?:\b while \b)}xi  )
#                { $o = TSQL::AST::SQLWhileStatement->new( tokenString => $input ) ; }
        default { $o = TSQL::AST::SQLStatement->new( tokenString => $input ) ;
                }

    return $o;  
    }
}

sub makeIfStatement {

    local $_             = undef ;    
    
    my $invocant         = shift ;    
    my $class            = ref($invocant) || $invocant ;    

    my $condition        = shift ;
    carp "Missing statement input" if ! defined $condition;

    $condition =~ s{$qr_iftoken}{}xmis; 
    my $fr = TSQL::AST::SQLFragment->new( tokenString => $condition ) ; 
    my $co = TSQL::AST::SQLConditionalExpression->new( expression => $fr ) ; 
    return TSQL::AST::SQLIfStatement->new( condition => $co ) ;            

}

sub makeWhileStatement {

    local $_             = undef ;    
    
    my $invocant         = shift ;    
    my $class            = ref($invocant) || $invocant ;    

    my $condition        = shift ;
    carp "Missing statement input" if ! defined $condition;

    $condition =~ s{$qr_whiletoken}{}xmis; 
    my $fr = TSQL::AST::SQLFragment->new( tokenString => $condition ) ; 
    my $co = TSQL::AST::SQLConditionalExpression->new( expression => $fr ) ; 
    return TSQL::AST::SQLWhileStatement->new( condition => $co ) ;            

}

1;

__DATA__

