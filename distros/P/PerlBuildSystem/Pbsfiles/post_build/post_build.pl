=head1 PBSFILE USER HELP

=head2 Top rules

=over 2 

=item * all

=back

=cut

PbsUse('Configs/gcc') ;
ExcludeFromDigestGeneration( 'aa_file' => qr/^.*\/aa$/) ;

AddRule [VIRTUAL], 'all',  ['all' => 'a'], BuildOk("done") ;

AddRule 'a builder', ['a' => 'aa'], BuildOk('fake builder') ;
AddRule 'aa builder', ['aa' => undef], BuildOk('fake builder') ;
AddPostBuildCommand 'post build', ['all', 'a', 'b'], \&PostBuildCommandTest, 'hi' ;

sub PostBuildCommandTest
{
my ($config, $name, $dependencies, $triggered_dependencies, $argument, $node) = @_ ;

my $dp = [$config, $name, $dependencies, $triggered_dependencies, $argument] ;

use Data::Dumper ;
#~ print 'PostBuildCommand arguments ' . Dumper($dp) . "\n" ;

return(1, "PostBuildCommandTest OK.") ;
}
