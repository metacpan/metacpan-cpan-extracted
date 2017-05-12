package P50Tools::SQLiScan;

use warnings;
use strict;
use Moose;
use HTTP::Request;
use LWP::UserAgent;

{
    no strict "vars";
    $VERSION = '0.1';
}

has 'target_list' => (is => 'rw', isa => 'Str');
has 'output' => (is => 'rw', isa => 'Str', default => 'output.txt');

sub scan{
	my $self = shift;
	
	open IN, $self->target_list or die "Cannot open data: $!";
	
	foreach (<IN>){
		
		
		$_ = "http://" . $_ if ($_ !~ /^http:/);
		$_ .= "'";
		my $req=HTTP::Request->new(GET=>$_);
		my $ua=LWP::UserAgent->new();
		$ua->timeout(20);
		my $response = $ua->request($req);
		if ($response->is_success){
			if($response->content =~ /You have an error in your SQL syntax/ ||
				$response->content =~ /MySQL server version/ ||
				$response->content =~ /Syntax error converting the nvarchar value/ ||
				$response->content =~ /Unclosed/ ||
				$response->content =~ /SQL Server error/ ||
				$response->content =~ /JET/) {
				open OUT,">". $self->output or die "Cannot create data: $!\n";
				print "Find a vulnerability\n";
				print OUT $_;
				close OUT;
				
			}
		}
		else {
			print "Cannot find a vulnerability\n";
		}
		return $_;
	}
	close IN;
	
}
no Moose;
1;

__END__

=head1 
For more information go to L<P50Tools>.
=cut
