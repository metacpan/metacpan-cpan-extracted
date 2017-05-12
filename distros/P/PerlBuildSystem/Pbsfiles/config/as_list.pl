
=head1 PBSFILE USER HELP

=head2 Top rules

=over 2 

=item * parent

=back

=cut

AddConfig
	(
	  LIST            => [ 'A', 'B']
	, LIST_WITH_UNDEF => [ 'C', undef, 'E']
	, SCALAR          => 'scalar'
	, UNDEF_SCALAR    => undef
	, HASH            => { key => 'value'}
	) ;
	
	
my @values ;

# call with a non existing config
@values = GetConfigAsList('LIST', 'NON_EXISTING', 'SCALAR') ;

# call with an undef scalar 
@values = GetConfigAsList('LIST', 'UNDEF_SCALAR', 'SCALAR') ;

# call with an undef in a list
@values = GetConfigAsList('LIST', 'LIST_WITH_UNDEF', 'SCALAR') ;
	

print "------------------------\n" ;
print "GetConfigAsList('LIST', 'NON_EXISTING', 'LIST_WITH_UNDEF', 'UNDEF_SCALAR', 'SCALAR') ;\n" ;

@values = GetConfigAsList('LIST', 'NON_EXISTING', 'LIST_WITH_UNDEF', 'UNDEF_SCALAR', 'SCALAR') ;

use Data::TreeDumper ;
print DumpTree(\@values) ;
print "------------------------\n" ;

eval
{
# call without arguments
my @data = GetConfigAsList() ;
} ;
print $@ ;


eval
{
# call in non list context
GetConfigAsList() ;
} ;
print $@ ;


eval
{
# call in non list context
my $scalar = GetConfigAsList() ;
} ;
print $@ ;


eval
{
#call with non scalar/hash element
@values = GetConfigAsList('LIST', 'HASH', 'SCALAR') ;
} ;
print $@ ;












