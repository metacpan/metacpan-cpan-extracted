use MooseX::Declare;
use warnings;

class TSQL::AST::SQLFragment {

use Data::Dumper;

=head1 NAME

TSQL::AST::SQLFragment - Base class for everything related to a SQL object.

=head1 VERSION

Version 0.01_001 

=cut

#our \$VERSION  = '0.01';


has 'tokenString' => (
      is  => 'rw',
      isa => 'Str',
  );


method parse ( ScalarRef[Int] $index, ArrayRef[Str] $input) {
    my $output = undef;
    return $output ;
}


}

__DATA__


=head1 SYNOPSIS

=head1 DESCRIPTION

Internal class.  Please report bugs etc with reference to parent namespace/class TSQL::AST.

=head1 DEPENDENCIES

TSQL::AST::SQLFragment depends on the following modules:

=over 4

=item * L<TSQL::AST>

=back


=head1 AUTHOR

Ded MedVed, C<< <dedmedved at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-tsql-ast at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=TSQL::AST>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 METHODS

=head2 C<new>

=over 4

=item * C<< TSQL::AST::SQLFragment->new() >>

=back

It creates and returns a new TSQL::AST::SQLFragment object. 

=head2 C<parse>

=over 4

=item * C<< $self->parse( int var ref, array of sqlfragments ) >>

=back

This is the method which parses the split up SQL code.

=head2 C<tokenString>

=over 4

=item * C<< $self->tokenString() >>

=back

This is the method that holds the raw input text corresponding to the parsed SQL fragment.
Derived classes representing compound objects do not populate this field, but delegate it to
their constituent parts.


=head1 LIMITATIONS

No limitations are currently known, as far as the intended usage is concerned.  
You *are* bound to uncover a large number of problems.

Please report any problematic cases.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc TSQL::AST::SQLFragment


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

=over 4

=item * L<TSQL::AST>

=back



=head1 LICENSE AND COPYRIGHT

Copyright 2012 Ded MedVed.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of TSQL::AST::SQLFragment


