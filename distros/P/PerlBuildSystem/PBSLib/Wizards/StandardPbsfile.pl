# WIZARD_GROUP PBS
# WIZARD_NAME  Pbsfile
# WIZARD_DESCRIPTION template for a standard Pbsfile
# WIZARD_ON

print "Please give a one line description of this Pbsfile: " ;
my $purpose = <STDIN> ;
chomp($purpose) ;

print <<EOP ;
=head1 PBSFILE USER HELP

=head2 I<Pbsfile.pl>

$purpose

=cut 

=head2 Top rules

=over 2 

=item * all

=back

=cut

PbsUse('Rules/...') ; 
PbsUse('Configs/...') ; 

#-------------------------------------------------------------------------------

AddRule [VIRTUAL], 'rule_name', ['dependent' => '', ''], \&BUILDER, [\&node_sub, \&node_sub] ;


=head2 Rule 'xxxx'

blah ...

blah ...

=cut

AddRule 'rule_name',['*\*.*' => '*.*'], \&BUILDER, [\&node_sub, \&node_sub] ;

=comment

Some  comments that won't apear if --uh is used.

=cut


AddRule 'rule_name',['*\*.*' => '*.*']
	, "command"
	, [\&node_sub, \&node_sub] ;

AddRule 'subpbs_name', {NODE_REGEX => '', PBSFILE => './Pbsfile.pl', PACKAGE => ''} ;

# Subpbs
for my \$subpbs_args
	(
	#  rule_name             node_regex                   Pbsfile              pbs_package
	[''     , qr!!, '', ''     ] ,
	[''     , qr!!, '', ''     ] ,
	[''     , qr!!, '', ''     ] 
	)
	{
	AddSubpbsRule(\@\$subpbs_args) ;
	}


EOP

