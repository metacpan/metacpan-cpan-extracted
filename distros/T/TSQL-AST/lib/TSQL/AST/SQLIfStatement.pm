use MooseX::Declare;
use warnings;

class TSQL::AST::SQLIfStatement extends TSQL::AST::SQLStatement {

use TSQL::AST::Factory;
use TSQL::AST::SQLConditionalExpression;
#use TSQL::AST::SQLFragment;
#use TSQL::AST::SQLStatement;
use TSQL::AST::SQLStatementBlock;
use TSQL::AST::SQLTryCatchBlock;

use TSQL::AST::SQLWhileStatement;


=head1 NAME

TSQL::AST::SQLIfStatement - Represents a TSQL If Statement.

=head1 VERSION

Version 0.02 

=cut

#our \$VERSION  = '0.02';

use feature "switch";

use Data::Dumper;

has 'condition' => (
      is  => 'rw',
      isa => 'TSQL::AST::SQLConditionalExpression',
  );


has 'ifBranch' => (
      is  => 'rw',
      isa => 'TSQL::AST::SQLStatement',
  );


has 'elseBranch' => (
      is  => 'rw',
      isa => 'TSQL::AST::SQLStatement',
  );


method _HandleElse ( ScalarRef[TSQL::AST::SQLStatement] $block, ScalarRef[Int] $index, ArrayRef[Str] $input, ScalarRef[Bool] $if, ScalarRef[Bool] $else, Bool $advanceIndex) {

    my $end = 0 ;
    if ( $$if ) {
        $self->ifBranch($$block);
        $$if     = 0 ;
        $$index++ if $advanceIndex ;
        if ($$index <= $#{$input}) {
            my $ln = $$input[$$index];
            my $t = TSQL::AST::Factory->makeToken($ln);
            if ( defined $t && $t->isa('TSQL::AST::Token::Else')) {
                $$index++ unless $advanceIndex ;;
                $$else = 1 ;
            }
            else {
                $end = 1 ;
            }
        }   
    }
    else {
        $self->elseBranch($$block);
        $$else   = 0 ;      
    }
    return scalar $end ;
}



override parse ( ScalarRef[Int] $index, ArrayRef[Str] $input) {

    my $if     = 1 ;
    my $else   = 0;
    
    while ( $$index <= $#{$input} ) {
    
        if ($if==0 && $else==0) { 
            last ; 
        } 
        
        my $ln = $$input[$$index];
        my $t = TSQL::AST::Factory->makeToken($ln);

#warn Dumper 'PARSEIF', $ln, $$index;
#warn Dumper 'PARSEIF', $t;

        given ($t) {
            when ( defined $_ && $_->isa('TSQL::AST::Token::Begin') ) {
                $$index++;
                my $block = TSQL::AST::SQLStatementBlock->new( statements => [] ) ;
                $block->parse($index,$input);
                my $stop = $self->_HandleElse(\$block, $index, $input, \$if, \$else, 0);
                last if $stop;
            }
            when ( defined $_ && $_->isa('TSQL::AST::Token::BeginTry') ) {
                $$index++;
                my $block = TSQL::AST::SQLTryCatchBlock->new( tryBlock => [],catchBlock => [] ) ;
                $block->parse($index,$input);
                my $stop = $self->_HandleElse(\$block, $index, $input, \$if, \$else, 0);
                last if $stop;
            }
            when ( defined $_ && $_->isa('TSQL::AST::Token::If') ) {
                my $block = TSQL::AST::Factory->makeIfStatement($ln);
                $block->parse($index,$input);
                my $stop = $self->_HandleElse(\$block, $index, $input, \$if, \$else, 1);
                last if $stop;
            }                
            when ( defined $_ && $_->isa('TSQL::AST::Token::While') ) {
                $$index++;
                my $block = TSQL::AST::Factory->makeWhileStatement($ln);
                $block->parse($index,$input);
                my $stop = $self->_HandleElse(\$block, $index, $input, \$if, \$else, 1);
                last if $stop;
            }

            default { 
                my $statement = TSQL::AST::Factory->makeStatement($ln);
                my $stop = $self->_HandleElse(\$statement, $index, $input, \$if, \$else, 1);
                last if $stop;

                $$index++;
            } 
        }
    }
#warn Dumper "IF end", $$index;    
    return $self ;}

}


1;




=head1 SYNOPSIS

Represents the parsed version/AST of a TSQL If Statement.

=head1 DESCRIPTION

See TSQL::AST.

=head1 DEPENDENCIES

See TSQL::AST.

=head1 AUTHOR

Ded MedVed, C<< <dedmedved at cpan.org> >>

=head1 BUGS

See TSQL::AST.

=head1 METHODS

=head2 C<new>

=over 4

=item * C<< TSQL::AST::SQLIfStatement->new() >>

=back

It creates and returns a new TSQL::AST::SQLIfStatement object. 


=head2 C<parse>

=over 4

=item * C<< $if->parse( integer index into array, array of sqlfragments ) >>

This is the method which parses the split up SQL code.
    
=back    


=head2 C<condition>

=over 4

=item * C<< $if->condition() >>

TSQL::AST::SQLConditionalExpression representing the condition clause of the While statement.
    
=back    


=head2 C<ifBranch>

=over 4

=item * C<< $if->ifBranch() >>

TSQL::AST::SQLStatement representing the body of the If statement if-branch.
    
=back    


=head2 C<elseBranch>

=over 4

=item * C<< $if->elseBranch() >>

Optional TSQL::AST::SQLStatement representing the body of the If statement optional else-branch.
    
=back    


=head1 LIMITATIONS

No limitations are currently known, as far as the intended usage is concerned.  
You *are* bound to uncover a large number of problems.

Please report any problematic cases.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc TSQL::AST::SQLIfStatement


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=TSQL::AST>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/TSQL::AST>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/TSQL::AST>

=item * Search CPAN

L<http://search.cpan.org/dist/TSQL::AST/>

=back


=head1 ACKNOWLEDGEMENTS

=over 4

None yet.

=back


=head1 SEE ALSO


=head1 LICENSE AND COPYRIGHT

Copyright 2012 Ded MedVed.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of TSQL::AST::SQLIfStatement



