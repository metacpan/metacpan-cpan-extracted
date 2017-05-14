use MooseX::Declare;
use warnings;

class TSQL::AST::SQLScript extends TSQL::AST::SQLFragment {

use TSQL::AST::SQLBatch;
use Data::Dumper;

=head1 NAME

TSQL::AST::SQLScript - Represents a TSQL Script.

=head1 VERSION

Version 0.02 

=cut

#our \$VERSION  = '0.02';

has 'batches' => (
      is  => 'rw',
      isa => 'ArrayRef[TSQL::AST::SQLBatch]',
  );

override parse ( ScalarRef[Int] $index, ArrayRef[Str] $input ) {
    while ( $$index <= $#{$input} ) {
        my $batch   = TSQL::AST::SQLBatch->new(statements => [])->parse( $index, $input )  ;
        push @{$self->batches()}, $batch;
        $$index++;
    }
    return ;
}

}


1;


__DATA__

=head1 SYNOPSIS

Represents the parsed version/AST of a TSQL script.

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

=item * C<< TSQL::AST::SQLScript->new() >>

=back

It creates and returns a new TSQL::AST::SQLScript object. 

=head2 C<parse>

=over 4

=item * C<< $ast->parse( integer index into array, array of sqlfragments ) >>

This is the method which parses the split up SQL code from the original script.
    
=back    

=head2 C<batches>

=over 4

=item * C<< $ast->batches() >>

Array of TSQL::AST::SQLBatch for the script just parsed.
    
=back    

=head1 LIMITATIONS

No limitations are currently known, as far as the intended usage is concerned.  
You *are* bound to uncover a large number of problems.

Please report any problematic cases.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc TSQL::AST::SQLScript


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

1; # End of TSQL::AST::SQLScript


