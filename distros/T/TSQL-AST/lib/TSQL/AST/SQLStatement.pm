use MooseX::Declare;
use warnings;

class TSQL::AST::SQLStatement extends TSQL::AST::SQLFragment {

=head1 NAME

TSQL::AST::SQLStatement - Represents a TSQL Statement.

=head1 VERSION

Version 0.01 

=cut

#our \$VERSION  = '0.01';

}


1;


=head1 SYNOPSIS

Represents the parsed version/AST of a TSQL statement.

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

=item * C<< TSQL::AST::SQLStatement->new() >>

=back

It creates and returns a new TSQL::AST::SQLStatement object. 


=head1 LIMITATIONS

No limitations are currently known, as far as the intended usage is concerned.  
You *are* bound to uncover a large number of problems.

Please report any problematic cases.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc TSQL::AST::SQLStatement


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

1; # End of TSQL::AST::SQLStatement



