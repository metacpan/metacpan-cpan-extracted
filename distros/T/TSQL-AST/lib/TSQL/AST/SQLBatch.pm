use MooseX::Declare;
use warnings;

class TSQL::AST::SQLBatch extends TSQL::AST::SQLFragment {

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

TSQL::AST::SQLBatch - Represents a Batch of TSQL statements.

=head1 VERSION

Version 0.03 

=cut

#our \$VERSION  = '0.03';

has 'statements' => (
      is  => 'rw',
      isa => 'ArrayRef[TSQL::AST::SQLStatement]',
  );

override parse ( ScalarRef[Int] $index, ArrayRef[Str] $input ){ 

    while ( $$index <= $#{$input} ) {
        my $ln = $$input[$$index];
        my $t  = TSQL::AST::Factory->makeToken($ln) ;
        given ($t) {
            when ( defined $_ && $_->isa('TSQL::AST::Token::GO') ) { 
                #$$index++ ;            
                last ;
            }
            when ( defined $_ && $_->isa('TSQL::AST::Token::Begin') ) {
                $$index++;
                my $block = TSQL::AST::SQLStatementBlock->new( statements => [] ) ;
                $block->parse($index,$input);
                push @{$self->statements()}, $block;
            }
            when ( defined $_ && $_->isa('TSQL::AST::Token::BeginTry') ) {
                $$index++;
                my $block = TSQL::AST::SQLTryCatchBlock->new( tryBlock => [],catchBlock => [] ) ;
                $block->parse($index,$input);
                push @{$self->statements()}, $block;
            }
            when ( defined $_ && $_->isa('TSQL::AST::Token::If') ) {
                $$index++;
                my $block = TSQL::AST::Factory->makeIfStatement($ln);
                $block->parse($index,$input);
                push @{$self->statements()}, $block;
            }
            when ( defined $_ && $_->isa('TSQL::AST::Token::While') ) {
                $$index++;
                my $block = TSQL::AST::Factory->makeWhileStatement($ln);
                $block->parse($index,$input);
                push @{$self->statements()}, $block;
            }                
                
            default 
                {
#warn Dumper "hello", $ln;                
                    my $statement = TSQL::AST::Factory->makeStatement($ln);
                    push @{$self->statements()}, $statement;
                    $$index++;
                } 
        }

    }
    return $self ;
}

}



1;

__DATA__

=head1 SYNOPSIS

Represents the parsed version/AST of a TSQL batch.

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

=item * C<< TSQL::AST::SQLBatch->new() >>

=back

It creates and returns a new TSQL::AST::SQLBatch object. 

=head2 C<parse>

=over 4

=item * C<< $batch->parse( integer index into array, array of sqlfragments ) >>

This is the method which parses the split up SQL code from the original script.
    
=back    

=head2 C<statements>

=over 4

=item * C<< $batch->statements() >>

Array of TSQL::AST::SQLStatement for this batch in the script just parsed.
    
=back    

=head1 LIMITATIONS

No limitations are currently known, as far as the intended usage is concerned.  
You *are* bound to uncover a large number of problems.

Please report any problematic cases.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc TSQL::AST::SQLBatch


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

1; # End of TSQL::AST::SQLBatch


