use MooseX::Declare;

class TSQL::AST {

use 5.014;
use warnings;
use strict;

use feature "switch";

use TSQL::AST::SQLScript;

use Data::Dumper;

=head1 NAME

TSQL::AST - 'Abstract Syntax Tree' for TSQL.

=head1 VERSION

Version 0.04

=cut

our $VERSION  = '0.04';

has 'script' => (
      is  => 'rw',
      isa => 'TSQL::AST::SQLScript',
  );


method parse (ArrayRef[Str] $input) {
    $self->script(TSQL::AST::SQLScript->new( batches => [] )) ;
    my $index = 0; 
    my $output = $self->script()->parse(\$index,$input);
    return $self ;
}

  
}


1;

__DATA__


=head1 SYNOPSIS

Parses Microsoft's Transact SQL dialect of SQL.

=head1 DESCRIPTION

This only provides a very 'broad brush' parse of TSQL.  
It aims to be accurate in what it does parse, but not to provide any great detail.
Currently it recursively recognises the major block structure elements of TSQL.

This is still *ALPHA* quality software.  It should still be a developer-only release, but I'm getting tired of those.
If you've come looking for a full-blown TSQL parser, you're going to leave here very disappointed.
Even when finished, this is going to leave most of your SQL unparsed.  
It's intended to support another piece of work, which is currently only in the planning stage, and will have its
development driven from those requirements as they materialise.

Note TSQL::AST is only intended to parse syntactically valid TSQL.  


=head1 DEPENDENCIES

TSQL::AST depends on the following modules:

=over 4

=item * L<TSQL::SplitStatement>

=item * L<TSQL::Common::Regexp>

=item * L<Data::Dumper>

=item * L<List::MoreUtils>

=item * L<List::Util>

=item * L<MooseX::Declare>

=item * L<autodie>

=item * L<indirect>

=item * L<version>

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

=item * C<< TSQL::AST->new() >>

=back

It creates and returns a new TSQL::AST object. 

=head2 C<parse>

=over 4

=item * C<< $ast->parse( array of sqlfragments ) >>

This is the method which parses the split up SQL code from the original script.

    my $sql_splitter = TSQL::SplitStatement->new();
    
    my @statements = $sql_splitter->splitSQL( 'SELECT 1;SELECT 2;' );

    my $sql_parser = TSQL::AST->new();
    
    my $ast = $sql_parser->parse( \@statements );
    
=back    

=head2 C<script>

=over 4

=item * C<< $ast->script() >>

This is the method which retrieves the AST for the script just parsed.

    my $sql_splitter = TSQL::SplitStatement->new();
    
    my @statements = $sql_splitter->splitSQL( 'SELECT 1;SELECT 2;' );

    my $sql_parser = TSQL::AST->new();
    
    my $ast = $sql_parser->parse( \@statements );

    my $script = $ast->script();
    
=back    

=head1 LIMITATIONS

No limitations are currently known, as far as the intended usage is concerned.  
You *are* bound to uncover a large number of problems.

Please report any problematic cases.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc TSQL::AST


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

=item * L<TSQL::SplitStatement>

=back



=head1 LICENSE AND COPYRIGHT

Copyright 2012 Ded MedVed.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of TSQL::AST


