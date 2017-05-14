use MooseX::Declare;
use warnings;

class TSQL::AST::SQLTryCatchBlock extends TSQL::AST::SQLStatement {

use feature "switch";
use TSQL::AST::Factory;

use TSQL::AST::SQLFragment ;
use TSQL::AST::SQLStatement ;
use TSQL::AST::SQLStatementBlock ;
use TSQL::AST::SQLTryCatchBlock ;

use TSQL::AST::SQLConditionalExpression;
use TSQL::AST::SQLIfStatement;
use TSQL::AST::SQLWhileStatement;

use Data::Dumper;

=head1 NAME

TSQL::AST::SQLTryCatchBlock - Represents a TSQL Try Catch block.

=head1 VERSION

Version 0.02 

=cut

#our \$VERSION  = '0.02';

has 'tryBlock' => (
      is  => 'rw',
      isa => 'ArrayRef[TSQL::AST::SQLStatement]',
  );


has 'catchBlock' => (
      is  => 'rw',
      isa => 'ArrayRef[TSQL::AST::SQLStatement]',
  );


override parse ( ScalarRef[Int] $index, ArrayRef[Str] $input) {

    my $try     = 1 ;
    my $catch   = 0;
    while ( $$index <= $#{$input} ) {
        my $ln = $$input[$$index];
        my $t = TSQL::AST::Factory->makeToken($ln);
        
#warn Dumper 'PARSETRYCATCH',$ln;
#warn Dumper 'PARSETRYCATCH',$t;

        
        given ($t) {
            when ( defined $_ && $_->isa('TSQL::AST::Token::BeginCatch') ) {
                $$index++;
                $catch  = 1;      
            } #end begincatch
            when ( defined $_ && $_->isa('TSQL::AST::Token::EndTry') ) {
                $$index++;
                $try    = 0;      
            } #end endtry
            when ( defined $_ && $_->isa('TSQL::AST::Token::EndCatch') ) {
                $$index++;
                last ;
            } #end endcatch
            when ( defined $_ && $_->isa('TSQL::AST::Token::Begin') ) {
                $$index++;
                my $block = TSQL::AST::SQLStatementBlock->new( statements => [] ) ;
                $block->parse($index,$input);
                if ( $try ) {
                    push @{$self->tryBlock()}, $block;
                }
                else {
                    push @{$self->catchBlock()}, $block;
                }
            } #end begin
            when ( defined $_ && $_->isa('TSQL::AST::Token::BeginTry') ) {
                $$index++;
                my $block = TSQL::AST::SQLTryCatchBlock->new( tryBlock => [],catchBlock => [] ) ;
                $block->parse($index,$input);
                if ( $try ) {
                    push @{$self->tryBlock()}, $block;
                }
                else {
                    push @{$self->catchBlock()}, $block;
                }
            } #end begintry
            when ( defined $_ && $_->isa('TSQL::AST::Token::If') ) {
                $$index++;
                my $block = TSQL::AST::Factory->makeIfStatement($ln);
                $block->parse($index,$input);
                if ( $try ) {
                    push @{$self->tryBlock()}, $block;
                }
                else {
                    push @{$self->catchBlock()}, $block;
                }
            } #end if
            when ( defined $_ && $_->isa('TSQL::AST::Token::While') ) {
                $$index++;
                my $block = TSQL::AST::Factory->makeWhileStatement($ln);
                $block->parse($index,$input);
                if ( $try ) {
                    push @{$self->tryBlock()}, $block;
                }
                else {
                    push @{$self->catchBlock()}, $block;
                }
            } # end while
            default { 
                my $statement = TSQL::AST::Factory->makeStatement($ln);
#warn Dumper $statement;                  
                if ($try ) {
                    push @{$self->tryBlock()}, $statement;
                }
                else {
                    push @{$self->catchBlock()}, $statement;
                }
                $$index++;
            } # end default
    } # end given
} # end while
return $self ;
} #end parse

} #end class

1;


__DATA__

=head1 SYNOPSIS

Represents the parsed version/AST of a BEGIN TRY/END CATCH block of TSQL statements.

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

=item * C<< TSQL::AST::SQLTryCatchBlock->new() >>

=back

It creates and returns a new TSQL::AST::SQLTryCatchBlock object. 

=head2 C<parse>

=over 4

=item * C<< $trycatchblock->parse( integer index into array, array of sqlfragments ) >>

This is the method which parses the split up SQL code.
    
=back    


=head2 C<tryBlock>

=over 4

=item * C<< $trycatchblock->tryBlock() >>

Array of TSQL::AST::SQLStatement for the try section of the block just parsed.
    
=back    



=head2 C<catchBlock>

=over 4

=item * C<< $trycatchblock->catchBlock() >>

Array of TSQL::AST::SQLStatement for the catch section of the block just parsed.
    
=back    

=head1 LIMITATIONS

No limitations are currently known, as far as the intended usage is concerned.  
You *are* bound to uncover a large number of problems.

Please report any problematic cases.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc TSQL::AST::SQLTryCatchBlock


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

1; # End of TSQL::AST::SQLTryCatchBlock



