
=head1 CheckNodeName

Check node names before it is added to the dependency graph

=cut

#-------------------------------------------------------------------------------

sub CheckNodeName
{
my ($node_name, $rule) = @_ ;

if(# $dependency_name =~ /\s/ ||
   $node_name =~ /\\/)
	{
	my $rule_info =  $rule->{NAME} . $rule->{ORIGIN} ;
						
	PrintError
		(
		"Node '$node_name' contains spaces and/or backslashes. "
		. "rule $rule_info\n"
		) ;
		
	PbsDisplayErrorWithContext($rule->{FILE}, $rule->{LINE}) ;
		
	die ;
	}
}

#-------------------------------------------------------------------------------

1 ;

