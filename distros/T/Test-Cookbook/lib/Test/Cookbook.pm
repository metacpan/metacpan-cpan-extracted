
package Test::Cookbook ;

use strict;
use warnings ;

BEGIN 
{
use vars qw ($VERSION @ISA @EXPORT_OK %EXPORT_TAGS);
$VERSION = '0.05' ;
}

#-------------------------------------------------------------------------------

#~ use Data::TreeDumper ;

use English qw( -no_match_vars ) ;

#~ use Readonly ;
#~ Readonly my $EMPTY_STRING => q{} ;

use Carp qw(carp croak confess) ;

use Filter::Simple ;
use POD::Tested ;
use IO::String ;

my @setup ;

#-------------------------------------------------------------------------------

=head1 NAME

 Test::Cookbook - Write your tests as cookbooks

=head1 SYNOPSIS

With your test formatted as a cookbook in B<t/005_cookbook.t>

	$> ./Build test
	
	$> ./Build test --test_files t/005_cookbook.t
	
	$> prove t/005_cookbook.t
	
	$> runtests t/005_cookbook.t
	
	$> pod_tested.pl -i t/005_cookbook.t -o cookbook.pod


=head1 DESCRIPTION

This module is wrapper around L<POD::Tested>. L<POD::Tested> let's you write POD containing tests.
I use it mainly to write cookbooks with the ability to check the cookbook and generate part of it.

I started by writing tests, then I copied the tests into the cookbook. Then it hit me that both could be the same.
That I could write my tests as cookbooks.

These are the advantages when writing your tests as cookbooks:

=over 2

=item * single file to manipulate, no copy/paste and the errors associated with it

=item * your tests become much easier to read because they must be documented

=item * you can manually generate cookbooks from your tests

=item * you can generate cookbooks when your tests are run (not yet implemented)

=item * design and document your modules in the tests

=back

=head1 DOCUMENTATION


=head1 SUBROUTINES/METHODS

=cut


#-------------------------------------------------------------------------------

 sub import
{
	
=head2 import

This is automatically called for you by Perl

=cut
	
#~ (my $my_name, @setup) = @_ ;

return(1) ;
}

#-------------------------------------------------------------------------------

FILTER 
{
=head2 FILTER

This is automatically called for you by Perl

=cut

my $parser = POD::Tested->new(INPUT => $PROGRAM_NAME, @setup, STRING => $_) ;

return(1) ;
} ;

#-------------------------------------------------------------------------------

1 ;

=head1 BUGS AND LIMITATIONS

None so far.

=head1 AUTHOR

	Khemir Nadim ibn Hamouda
	CPAN ID: NKH
	mailto:nadim@khemir.net

=head1 LICENSE AND COPYRIGHT

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Test::Cookbook

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Test-Cookbook>

=item * RT: CPAN's request tracker

Please report any bugs or feature requests to  L <bug-test-cookbook@rt.cpan.org>.

We will be notified, and then you'll automatically be notified of progress on
your bug as we make changes.

=item * Search CPAN

L<http://search.cpan.org/dist/Test-Cookbook>

=back

=head1 SEE ALSO

L<POD::Tested>

=cut
