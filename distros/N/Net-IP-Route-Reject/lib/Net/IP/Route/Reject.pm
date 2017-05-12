package Net::IP::Route::Reject;
use strict;
use Carp;
use IPC::Cmd qw[can_run run];
use CLASS;
BEGIN {
	use Exporter ();
	use vars qw ($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);
	$VERSION     = 0.5;
	@ISA         = qw (Exporter);
	#Give a hoot don't pollute, do not export more than needed by default
	@EXPORT      = qw ();
	@EXPORT_OK   = qw ();
	%EXPORT_TAGS = ();
}


########################################### main pod documentation begin ##
# Below is the  documentation for your module. 

=head1 NAME

Net::IP::Route::Reject - Perl module for adding/removing reject routes

=head1 SYNOPSIS

  use Net::IP::Route::Reject


=head1 DESCRIPTION

Add/remove reject route from route table .


=head1 USAGE



=head1 BUGS



=head1 SUPPORT



=head1 AUTHOR

	Dana Hudes
	CPAN ID: DHUDES
	dhudes@hudes.org
	http://www.hudes.org

=head1 COPYRIGHT

This program is free software licensed under the...

	The Artistic License

The full text of the license can be found in the
LICENSE file included with this module.


=head1 SEE ALSO

perl(1),IPC::Cmd.

=cut

############################################# main pod documentation end ##


    my $_route_full_path = can_run('route') or die "cannot find the route command";
    my @_routecmd = ($_route_full_path, qw(add_del addr  reject));
my $ipv4octetregex = "([0-1]??(1,2)|2[0-4]|25[0-5])";
my $ipv4regex = "/^".$ipv4octetregex."\.".$ipv4octetregex."\.".$ipv4octetregex."\.".$ipv4octetregex."\$/o";

################################################ subroutine header begin ##

=head2 add

 Usage     : Net::IP::Route::Reject->add('192.168.1.1')
 Purpose   : adds a reject route for the given host from the route table of the host running this
 Returns   : nothing
 Argument  : takes one parameter, a numerical IPv4 address in dotted quad form
 Throws    : Confess on invalid IP address
 Comments  : 


See Also   : Net::IP::Route::Reject->del

=cut

################################################## subroutine header end ##
sub add {
    my ($self,$ip)=@_;
    CLASS->_reject('add',$ip);
}
################################################ subroutine header begin ##

=head2 del

 Usage     : Net::IP::Route::Reject->del('192.168.1.1')
 Purpose   : removes the reject route for the given host from the route table of the host running this
 Returns   : nothing
 Argument  : takes one parameter, a numerical IPv4 address in dotted quad form
 Throws    : Confess on invalid IP address
 Comments  : 


See Also   : Net::IP::Route::Reject->add

=cut

################################################## subroutine header end ##

sub del {
    my ($self,$ip)=@_;
    CLASS->_reject('del',$ip);
}
################################################ subroutine header begin ##

=head2 _reject

 Usage     : this is an internal method
 Purpose   : It executes the route command
 Returns   : What it returns
 Argument  : 2 positional parameters: 1st is operation, 2nd is ip address
 Throws    : 
 Comments  : This is a private function to avoid checking for bogus operation types

See Also   : IPC::Cmd

=cut

################################################## subroutine header end ##
sub _reject {
    my ($self,$operation, $ip) = @_;
    carp ("no ip address supplied") unless defined $ip;
    my @ipaddr = grep $ipv4regex, $ip; #strip out anything that doesn't belong in an ip addres
    carp ("unsupported operation") unless ($operation eq 'add' ) or ($operation eq 'del');
    $_routecmd[1]=$operation;
    $_routecmd[2]=$ipaddr[0];
    
    unless (run(command => \@_routecmd, verbose =>0))
    {
	my $errmesg = (scalar localtime)." failed to add reject route for $ip (maybe its already listed?)\n ";
	carp $errmesg;
    }
}



1; #this line is important and will help the module return a true value
__END__

