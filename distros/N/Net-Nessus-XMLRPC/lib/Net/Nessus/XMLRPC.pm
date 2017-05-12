package Net::Nessus::XMLRPC;

use XML::Simple;
use LWP::UserAgent;
use HTTP::Request::Common;

use warnings;
use strict;

=head1 NAME

Net::Nessus::XMLRPC - Communicate with Nessus scanner(v4.2+) via XMLRPC

=head1 VERSION

Version 0.30

=cut

our $VERSION = '0.30';


=head1 SYNOPSIS

This is Perl interface for communication with Nessus scanner over XMLRPC.
You can start, stop, pause and resume scan. Watch progress and status of 
scan, download report, etc.

	use Net::Nessus::XMLRPC;

	# '' is same as https://localhost:8834/
	my $n = Net::Nessus::XMLRPC->new ('','user','pass');

	die "Cannot login to: ".$n->nurl."\n" unless ($n->logged_in);

	print "Logged in\n";
	my $polid=$n->policy_get_first;
	print "Using policy ID: $polid ";
	my $polname=$n->policy_get_name($polid);
	print "with name: $polname\n";
	my $scanid=$n->scan_new($polid,"perl-test","127.0.0.1");

	while (not $n->scan_finished($scanid)) {
		print "$scanid: ".$n->scan_status($scanid)."\n";	
		sleep 15;
	}
	print "$scanid: ".$n->scan_status($scanid)."\n";	
	my $reportcont=$n->report_file_download($scanid);
	my $reportfile="report.xml";
	open (FILE,">$reportfile") or die "Cannot open file $reportfile: $!";
	print FILE $reportcont;
	close (FILE);

=head1 NOTICE

This CPAN module uses LWP for communicating with Nessus over XMLRPC via https.
Therefore, make sure that you have Net::SSL (provided by Crypt::SSLeay):
http://search.cpan.org/perldoc?Crypt::SSLeay
or IO::Socket::SSL:
http://search.cpan.org/perldoc?IO::Socket::SSL

If you think you have login problems, check this first!

=head1 METHODS

=head2 new ([$nessus_url], [$user], [$pass])

creates new object Net::Nessus::XMLRPC
=cut
sub new {
	my $class = shift;

	my $self; 

	$self->{_nurl} = shift;
	if ($self->{_nurl} eq '') {
		$self->{_nurl}='https://localhost:8834/';
	} elsif (substr($self->{_nurl},-1,1) ne '/') {
		$self->{_nurl}= $self->{_nurl}.'/';	
	} 
	my $user = shift;
	my $password = shift;
	$self->{_token} = undef;
	$self->{_name} = undef;
	$self->{_admin} = undef;
	$self->{_ua} = LWP::UserAgent->new;
	bless $self, $class;
	if ($user and $password) {
		$self->login($user,$password);
	}
	return $self;
}

=head2 DESTROY 

destructor, calls logout method on destruction
=cut
sub DESTROY {
	my ($self) = @_;
	$self->logout();
}

=head2 nurl ( [$nessus_url] )

get/set Nessus base URL
=cut
sub nurl {
	my ( $self, $nurl ) = @_;
	$self->{_nurl} = $nurl if defined($nurl);
	return ( $self->{_nurl} );
}

=head2 token ( [$nessus_token] )

get/set Nessus login token
=cut
sub token {
	my ( $self, $token ) = @_;
	$self->{_token} = $token if defined($token);
	return ( $self->{_token} );
}

=head2 nessus_http_request ( $uri, $post_data )

low-level function, makes HTTP request to Nessus URL	
=cut
sub nessus_http_request {
	my ( $self, $uri, $post_data ) = @_;
	my $ua = $self->{_ua};
	# my $ua = LWP::UserAgent->new;
	my $furl = $self->nurl.$uri;
	my $r = POST $furl, $post_data;
	my $result = $ua->request($r);
	# my $filename="n-".time; open (FILE,">$filename"); 
	# print FILE $result->as_string; close (FILE);
	if ($result->is_success) {
		return $result->content;
	} else {
		return '';
	}
}

=head2 nessus_request ($uri, $post_data) 

low-level function, makes XMLRPC request to Nessus URL and returns XML
=cut
sub nessus_request {
	my ( $self, $uri, $post_data ) = @_;
	my $cont=$self->nessus_http_request($uri,$post_data);
	if ($cont eq '') {
		return ''	
	}
	my $xmls;
	eval {
	$xmls=XMLin($cont, ForceArray => 1, KeyAttr => '', SuppressEmpty => '' );
	} or return '';
	if ($xmls->{'status'}->[0] eq "OK") {
		return $xmls; 
	} else { 
		return ''
	}
}

=head2 login ( $user, $password )

login to Nessus server via $user and $password	
=cut
sub login {
	my ( $self, $user, $password ) = @_;

	my $post=[ login => $user, password => $password ];
	my $xmls = $self->nessus_request("login",$post);

	if ($xmls eq '' or not defined($xmls->{'contents'}->[0]->{'token'}->[0])) {
		$self->token('');
	} else {
		$self->token ($xmls->{'contents'}->[0]->{'token'}->[0]);
	}
	return $self->token;
}

=head2 logout 

logout from Nessus server
=cut
sub logout {
	my ($self) = @_;
	my $post=[ "token" => $self->token ];
	my $xmls = $self->nessus_request("logout",$post);
	$self->token('');
}

=head2 logged_in

returns true if we're logged in
=cut
sub logged_in {
	my ($self) = @_;
	return $self->token;
}

=head2 scan_new ( $policy_id, $scan_name, $targets )

initiates new scan 
=cut
sub scan_new {
	my ( $self, $policy_id, $scan_name, $target ) = @_;

	my $post=[ 
		"token" => $self->token, 
		"policy_id" => $policy_id,
		"scan_name" => $scan_name,
		"target" => $target
		 ];

	my $xmls = $self->nessus_request("scan/new",$post);
	if ($xmls) {
		return ($xmls->{'contents'}->[0]->{'scan'}->[0]->{'uuid'}->[0]);
	} else {
		return $xmls
	}
}	

=head2 scan_new_file ( $policy_id, $scan_name, $targets, $filename )

initiates new scan with hosts from file named $filename
=cut
sub scan_new_file {
	my ( $self, $policy_id, $scan_name, $target, $filename ) = @_;

	my $post={ 
		"token" => $self->token, 
		"policy_id" => $policy_id,
		"scan_name" => $scan_name,
		"target" => $target
		 };
	$post->{"target_file_name"} = $self->file_upload($filename);
	my $xmls = $self->nessus_request("scan/new",$post);
	if ($xmls) {
		return ($xmls->{'contents'}->[0]->{'scan'}->[0]->{'uuid'}->[0]);
	} else {
		return $xmls
	}
}	

=head2 scan_stop ( $scan_id )

stops the scan identified by $scan_id
=cut
sub scan_stop {
	my ( $self, $scan_uuid ) = @_;

	my $post=[ 
		"token" => $self->token, 
		"scan_uuid" => $scan_uuid,
		 ];

	my $xmls = $self->nessus_request("scan/stop",$post);
	return $xmls;
}

=head2 scan_stop_all 

stops all scans
=cut
sub scan_stop_all {
	my ( $self ) = @_;

	my $list = $self->scan_list_uids;

	foreach my $uuid (@$list) {
		$self->scan_stop($uuid);
	}
	return $list;
}

=head2 scan_pause ( $scan_id )

pauses the scan identified by $scan_id
=cut
sub scan_pause {
	my ( $self, $scan_uuid ) = @_;

	my $post=[ 
		"token" => $self->token, 
		"scan_uuid" => $scan_uuid,
		 ];

	my $xmls = $self->nessus_request("scan/pause",$post);
	return $xmls;
}

=head2 scan_pause_all 

pauses all scans
=cut
sub scan_pause_all {
	my ( $self ) = @_;

	my $list = $self->scan_list_uids;

	foreach my $uuid (@$list) {
		$self->scan_pause($uuid);
	}
	return $list;
}

=head2 scan_resume ( $scan_id )

resumes the scan identified by $scan_id
=cut
sub scan_resume {
	my ( $self, $scan_uuid ) = @_;

	my $post=[ 
		"token" => $self->token, 
		"scan_uuid" => $scan_uuid,
		 ];

	my $xmls = $self->nessus_request("scan/resume",$post);
	return $xmls;
}

=head2 scan_resume_all 

resumes all scans
=cut
sub scan_resume_all {
	my ( $self ) = @_;

	my $list = $self->scan_list_uids;

	foreach my $uuid (@$list) {
		$self->scan_resume($uuid);
	}
	return $list;
}

=head2 scan_list_uids 

returns array of IDs of (active) scans
=cut
sub scan_list_uids {
	my ( $self ) = @_;

	my $post=[ 
		"token" => $self->token
	];

	my $xmls = $self->nessus_request("scan/list",$post);
	my @list;
	if ($xmls->{'contents'}->[0]->{'scans'}->[0]->{'scanList'}->[0]->{'scan'}) {
	foreach my $scan (@{$xmls->{'contents'}->[0]->{'scans'}->[0]->{'scanList'}->[0]->{'scan'}}) {
		push @list, $scan->{'uuid'}->[0];
	} # foreach
	return \@list;
	} # if
}

=head2 scan_get_name ( $uuid ) 

returns name of the scan identified by $uuid 
=cut
sub scan_get_name {
	my ( $self, $uuid ) = @_;

	my $post=[ 
		"token" => $self->token
	];

	my $xmls = $self->nessus_request("scan/list",$post);
	if ($xmls->{'contents'}->[0]->{'scans'}->[0]->{'scanList'}->[0]->{'scan'}) {
	foreach my $scan (@{$xmls->{'contents'}->[0]->{'scans'}->[0]->{'scanList'}->[0]->{'scan'}}) {
		if ($scan->{'uuid'}->[0] eq $uuid) {
			return $scan->{'readableName'}->[0];
		}
	} # foreach
	} # if
}

=head2 scan_status ( $uuid ) 

returns status of the scan identified by $uuid 
=cut
sub scan_status {
	my ( $self, $uuid ) = @_;

	my $post=[ 
		"token" => $self->token, 
		"report" => $uuid,
		 ];

	my $xmls = $self->nessus_request("report/list",$post);
	if ($xmls->{'contents'}->[0]->{'reports'}->[0]->{'report'}) {
	foreach my $report (@{$xmls->{'contents'}->[0]->{'reports'}->[0]->{'report'}}) {
		if ($report->{'name'}->[0] eq $uuid) {
			return $report->{'status'}->[0];
		}
	} # foreach
	} # if
	return ''; # nothing found
}

=head2 scan_finished ( $uuid ) 

returns true if scan is finished/completed (identified by $uuid)
=cut
sub scan_finished {
	my ( $self, $uuid ) = @_;
	my $status = $self->scan_status($uuid);
	if ( $status eq "completed" ) {
		return $status;
	} else {
		return '';
	}
}	

=head2 nessus_http_upload_request ( $uri, $post_data )

low-level function, makes HTTP upload request to URI specified
=cut
sub nessus_http_upload_request {
	my ( $self, $uri, $post_data ) = @_;
	my $ua = $self->{_ua};
	# my $ua = LWP::UserAgent->new;
	my $furl = $self->nurl.$uri;
	my $r = POST $furl, Content_Type => 'form-data', Content => $post_data;
	my $result = $ua->request($r);
	# my $filename="u-".time; open (FILE,">$filename"); 
	# print FILE $result->as_string; close (FILE);
	if ($result->is_success) {
		return $result->content;
	} else {
		return '';
	}
}

=head2 file_upload ( $filename )

uploads $filename to nessus server, returns filename of file uploaded
or '' if failed

Note that uploaded file is per session (i.e. it will be there until logout/attack.) 
So, don't logout or login again and use the filename! You need to upload it 
again!
=cut
sub file_upload {
	my ( $self, $filename ) = @_;
	my $post=[ "token" => $self->token, Filedata => [ $filename] ];
	my $cont=$self->nessus_http_upload_request("file/upload",$post);
	if ($cont eq '') {
		return ''	
	}
	my $xmls;
	eval {
	$xmls=XMLin($cont, ForceArray => 1, KeyAttr => '', SuppressEmpty => '');
	} or return '';
	if ($xmls->{'status'}->[0] eq "OK") {
		return $xmls->{'contents'}->[0]->{'fileUploaded'}->[0]; 
	} else { 
		return ''
	}
}

=head2 upload ( $filename, $content )

uploads $filename to nessus server using $content as content of file, returns filename of file uploaded
or '' if failed

Note that uploaded file is per session (i.e. it will be there until logout/attack.) 
So, don't logout or login again and use the filename! You need to upload it 
again!
=cut
sub upload {
	my ( $self, $filename, $content ) = @_;
	# Content => [ $PARAM => [undef,$FILENAME, Content => $CONTENTS ] ]);
	my $post=[ "token" => $self->token, Filedata => [ undef, $filename, Content => $content] ];
	my $cont=$self->nessus_http_upload_request("file/upload",$post);
	if ($cont eq '') {
		return ''	
	}
	my $xmls;
	eval {
	$xmls=XMLin($cont, ForceArray => 1, KeyAttr => '', SuppressEmpty => '');
	} or return '';
	if ($xmls->{'status'}->[0] eq "OK") {
		return $xmls->{'contents'}->[0]->{'fileUploaded'}->[0]; 
	} else { 
		return ''
	}
}

=head2 policy_get_first

returns policy id for the first policy found
=cut
sub policy_get_first {
	my ( $self ) = @_;

	my $post=[ 
		"token" => $self->token, 
		 ];
	
	my $xmls = $self->nessus_request("policy/list",$post);
	if ($xmls->{'contents'}->[0]->{'policies'}->[0]->{'policy'}) {
	foreach my $report (@{$xmls->{'contents'}->[0]->{'policies'}->[0]->{'policy'}}) {
		return $report->{'policyID'}->[0];
	} # foreach
	} # if
	return '';
}

=head2 policy_get_firsth

returns ref to hash %value with basic info of first policy/scan 
returned by the server

$value{'id'}, $value{'name'}, $value{'owner'}, $value{'visibility'},
$value{'comment'}
=cut
sub policy_get_firsth {
	my ( $self ) = @_;

	my $post=[ 
		"token" => $self->token, 
		 ];

	my %info;	
	my $xmls = $self->nessus_request("policy/list",$post);
	if ($xmls->{'contents'}->[0]->{'policies'}->[0]->{'policy'}) {
	foreach my $report (@{$xmls->{'contents'}->[0]->{'policies'}->[0]->{'policy'}}) {
		$info{'id'} = $report->{'policyID'}->[0];
		$info{'name'} = $report->{'policyName'}->[0];
		$info{'owner'} = $report->{'policyOwner'}->[0];
		$info{'visibility'} = $report->{'visibility'}->[0];
		$info{'comment'} = $report->{'policyContents'}->[0]->{'policyComments'}->[0];
		return \%info;
	} # foreach
	} # if
	return \%info;
}

=head2 policy_list_hash

returns ref to array of hashes %value with basic info of first policy/scan 
returned by the server

$value{'id'}, $value{'name'}, $value{'owner'}, $value{'visibility'},
$value{'comment'}
=cut
sub policy_list_hash {
	my ( $self ) = @_;

	my $post=[ 
		"token" => $self->token, 
		 ];

	my @list;
	my $xmls = $self->nessus_request("policy/list",$post);
	if ($xmls->{'contents'}->[0]->{'policies'}->[0]->{'policy'}) {
	foreach my $report (@{$xmls->{'contents'}->[0]->{'policies'}->[0]->{'policy'}}) {
		my %info;	
		$info{'id'} = $report->{'policyID'}->[0];
		$info{'name'} = $report->{'policyName'}->[0];
		$info{'owner'} = $report->{'policyOwner'}->[0];
		$info{'visibility'} = $report->{'visibility'}->[0];
		$info{'comment'} = $report->{'policyContents'}->[0]->{'policyComments'}->[0];
		push @list, \%info;
	} # foreach
	} # if
	return \@list;
}

=head2 policy_list_uids 

returns ref to array of IDs of policies available
=cut
sub policy_list_uids {
	my ( $self ) = @_;

	my $post=[ 
		"token" => $self->token, 
		 ];

	my $xmls = $self->nessus_request("policy/list",$post);
	my @list;
	if ($xmls->{'contents'}->[0]->{'policies'}->[0]->{'policy'}) {
	foreach my $report (@{$xmls->{'contents'}->[0]->{'policies'}->[0]->{'policy'}}) {
		push @list,$report->{'policyID'}->[0];
	} # foreach
	return \@list;
	} # if
	return '';
}

=head2 policy_list_names 

returns ref to array of names of policies available
=cut
sub policy_list_names {
	my ( $self ) = @_;

	my $post=[ 
		"token" => $self->token, 
		 ];

	my $xmls = $self->nessus_request("policy/list",$post);
	my @list;
	if ($xmls->{'contents'}->[0]->{'policies'}->[0]->{'policy'}) {
	foreach my $report (@{$xmls->{'contents'}->[0]->{'policies'}->[0]->{'policy'}}) {
		push @list,$report->{'policyName'}->[0];
	} # foreach
	return \@list;
	} # if
	return '';
}

=head2 policy_get_info ( $policy_id ) 

returns ref to hash %value with basic info of policy/scan identified by $policy_id 

$value{'id'}, $value{'name'}, $value{'owner'}, $value{'visibility'},
$value{'comment'}
=cut
sub policy_get_info {
	my ( $self, $policy_id ) = @_;

	my $post=[ 
		"token" => $self->token, 
		 ];
	my %info;
	my $xmls = $self->nessus_request("policy/list",$post);
	if ($xmls->{'contents'}->[0]->{'policies'}->[0]->{'policy'}) {
	foreach my $report (@{$xmls->{'contents'}->[0]->{'policies'}->[0]->{'policy'}}) {
	if ($report->{'policyID'}->[0] eq $policy_id) {
		$info{'id'} = $report->{'policyID'}->[0];
		$info{'name'} = $report->{'policyName'}->[0];
		$info{'owner'} = $report->{'policyOwner'}->[0];
		$info{'visibility'} = $report->{'visibility'}->[0];
		$info{'comment'} = $report->{'policyContents'}->[0]->{'policyComments'}->[0];
		return \%info;
	}
	} # foreach
	} # if
	return \%info;
}

=head2 policy_get_id ( $policy_name ) 

returns ID of the scan/policy identified by $policy_name 
=cut
sub policy_get_id {
	my ( $self, $policy_name ) = @_;

	my $post=[ 
		"token" => $self->token, 
		 ];
	 my $xmls = $self->nessus_request("policy/list",$post);
	 if ($xmls->{'contents'}->[0]->{'policies'}->[0]->{'policy'}) {
	 foreach my $report (@{$xmls->{'contents'}->[0]->{'policies'}->[0]->{'policy'}}) {
		if ($report->{'policyName'}->[0] eq $policy_name) {
			return $report->{'policyID'}->[0];
		}
	 } # foreach
	 } # if
	 return '';
}

=head2 policy_get_name ( $policy_id ) 

returns name of the scan/policy identified by $policy_id 
=cut
sub policy_get_name {
	my ( $self, $policy_id ) = @_;

	my $post=[ 
		"token" => $self->token, 
		 ];
	 my $xmls = $self->nessus_request("policy/list",$post);
	 if ($xmls->{'contents'}->[0]->{'policies'}->[0]->{'policy'}) {
	 foreach my $report (@{$xmls->{'contents'}->[0]->{'policies'}->[0]->{'policy'}}) {
		if ($report->{'policyID'}->[0] eq $policy_id) {
			return $report->{'policyName'}->[0];
		}
	 } # foreach
	 } # if
	 return '';
}

=head2 policy_delete ( $policy_id )

delete policy identified by $policy_id
=cut
sub policy_delete {
	my ( $self, $policy_id ) = @_;

	my $post=[ 
		"token" => $self->token, 
		"policy_id" => $policy_id,
		 ];

	my $xmls = $self->nessus_request("policy/delete",$post);
	return $xmls;
}

=head2 policy_copy ( $policy_id )

copy policy identified by $policy_id, returns $policy_id of new copied policy
=cut
sub policy_copy {
	my ( $self, $policy_id ) = @_;

	my $post=[ 
		"token" => $self->token, 
		"policy_id" => $policy_id,
		 ];

	my $xmls = $self->nessus_request("policy/copy",$post);
	if ($xmls->{'contents'}->[0]->{'policy'}->[0]) {
		return $xmls->{'contents'}->[0]->{'policy'}->[0]->{'policyID'}->[0];
	} # if
	return '';
}

=head2 policy_rename ( $policy_id, $policy_name )

rename policy to $policy_name identified by $policy_id
=cut
sub policy_rename {
	my ( $self, $policy_id, $policy_name ) = @_;

	my $post=[ 
		"token" => $self->token, 
		"policy_id" => $policy_id,
		"policy_name" => $policy_name
		 ];

	my $xmls = $self->nessus_request("policy/rename",$post);
	return $xmls;
}

=head2 policy_edit ( $policy_id, $params )

edit policy identified by $policy_id

%params (must be present): 
policy_name => name
policy_shared => 1

%params can be (examples)
max_hosts => 50,
max_checks=> 10,
use_mac_addr => no,
throttle_scan => yes,
optimize_test => yes,
log_whole_attack => no,
ssl_cipher_list => strong,
save_knowledge_base => no,
port_range => 1-65535
=cut
sub policy_edit {
	my ( $self, $policy_id, $params ) = @_;

	my $post={ 
		"token" => $self->token, 
		"policy_id" => $policy_id
		 };
	while (my ($key, $value) = each(%{$params}))
	{
		$post->{$key} = $value;
	}

	my $xmls = $self->nessus_request("policy/add",$post);
	return $xmls;
}

=head2 policy_new ( $params )

create new policy with $params, 
%params must be present:
policy_name
policy_shared

the others parameters are same as policy_edit
=cut
sub policy_new {
	my ( $self, $params ) = @_;

	my $xmls = $self->policy_edit(0, %{$params});
	return $xmls;
}

=head2 policy_get_opts ( $policy_id ) 

returns hashref with different options for policy identified by $policy_id 
=cut
sub policy_get_opts {
	my ( $self, $policy_id ) = @_;

	my $post=[ 
		"token" => $self->token, 
		 ];
	my $xmls = $self->nessus_request("policy/list",$post);

	if ($xmls->{'contents'}->[0]->{'policies'}->[0]->{'policy'}) {
		my %opts;
		foreach my $report (@{$xmls->{'contents'}->[0]->{'policies'}->[0]->{'policy'}}) {
		if ($report->{'policyID'}->[0] eq $policy_id) {
			$opts{'policy_name'}=$report->{'policyName'}->[0];
			if ($report->{'visibility'}->[0] eq "shared") {
				$opts{'policy_shared'}=1;
			} else {
				$opts{'policy_shared'}=0;
			}
			if ($report->{'policyContents'}->[0]->{'policyComments'}->[0]) {
				$opts{'policy_comments'}=$report->{'policyContents'}->[0]->{'policyComments'}->[0];
			}
			foreach my $prefs (@{$report->{'policyContents'}->[0]->{'Preferences'}->[0]->{'ServerPreferences'}->[0]->{'preference'}}) {
				$opts{$prefs->{'name'}->[0]} = $prefs->{'value'}->[0] if ($prefs->{'name'}->[0]);
			}
			foreach my $prefp (@{$report->{'policyContents'}->[0]->{'Preferences'}->[0]->{'PluginsPreferences'}->[0]->{'item'}}) {
				$opts{$prefp->{'fullName'}->[0]} = $prefp->{'selectedValue'}->[0] if ($prefp->{'fullName'}->[0]);
			}
			foreach my $plugf (@{$report->{'policyContents'}->[0]->{'FamilySelection'}->[0]->{'FamilyItem'}}) {
				$opts{"plugin_selection.family.".$plugf->{'FamilyName'}->[0]} = $plugf->{'Status'}->[0] if ($plugf->{'FamilyName'}->[0]);
			}
			foreach my $plugi (@{$report->{'policyContents'}->[0]->{'IndividualPluginSelection'}->[0]->{'PluginItem'}}) {
				$opts{"plugin_selection.individual_plugin.".$plugi->{'PluginId'}->[0]} = $plugi->{'Status'}->[0] if ($plugi->{'PluginId'}->[0]);
			}
			return \%opts;
		}
	 } # foreach
	 } # if
	 return '';
}

=head2 policy_set_opts ( $policy_id , $params ) 

sets policy options via hashref $params identified by $policy_id 
=cut
sub policy_set_opts {
	my ( $self, $policy_id, $params ) = @_;

	my $post = $self->policy_get_opts ($policy_id);
	while (my ($key, $value) = each(%{$params}))
	{
		$post->{$key} = $value;
	}
	$post->{"token"} = $self->token;
	$post->{"policy_id"} = $policy_id;

	my $xmls = $self->nessus_request("policy/edit",$post);
	return $xmls;
}

=head2 report_list_uids 

returns ref to array of IDs of reports available
=cut
sub report_list_uids {
	my ( $self ) = @_;

	my $post=[ 
		"token" => $self->token 
		 ];

	my $xmls = $self->nessus_request("report/list",$post);
	my @list;
	if ($xmls->{'contents'}->[0]->{'reports'}->[0]->{'report'}) {
	foreach my $report (@{$xmls->{'contents'}->[0]->{'reports'}->[0]->{'report'}}) {
		push @list, $report->{'name'}->[0];
	}
	}

	return \@list;
}

=head2 report_list_hash 

returns ref to array of hashes with basic info of reports 
hash has following keys:
name
status
readableName
timestamp
=cut
sub report_list_hash {
	my ( $self ) = @_;

	my $post=[ 
		"token" => $self->token 
		 ];

	my $xmls = $self->nessus_request("report/list",$post);
	my @list;
	if ($xmls->{'contents'}->[0]->{'reports'}->[0]->{'report'}) {
	foreach my $report (@{$xmls->{'contents'}->[0]->{'reports'}->[0]->{'report'}}) {	
		my %r;
		$r{'name'} = $report->{'name'}->[0];
		$r{'status'} = $report->{'status'}->[0];
		$r{'readableName'} = $report->{'readableName'}->[0];
		$r{'timestamp'} = $report->{'timestamp'}->[0];
		
		push @list, \%r;
	}
	}

	return \@list;
}

=head2 report_file_download ($report_id)

returns XML report identified by $report_id (Nessus XML v2)
=cut
sub report_file_download {
	my ( $self, $uuid ) = @_;

	my $post=[ 
		"token" => $self->token, 
		"report" => $uuid,
		 ];

	my $file = $self->nessus_http_request("file/report/download", $post);
	return $file;
}	

=head2 report_file1_download ($report_id)

returns XML report identified by $report_id (Nessus XML v1)
=cut
sub report_file1_download {
	my ( $self, $uuid ) = @_;

	my $post=[ 
		"token" => $self->token, 
		"report" => $uuid,
		"v1" => "true",
		 ];

	my $file = $self->nessus_http_request("file/report/download", $post);
	return $file;
}	

=head2 report_delete ($report_id)

delete report identified by $report_id
=cut
sub report_delete {
	my ( $self, $uuid ) = @_;

	my $post=[ 
		"token" => $self->token, 
		"report" => $uuid,
		 ];

	my $xmls = $self->nessus_request("report/delete", $post);
	return $xmls;
}	

=head2 report_import ( $filename )

tells nessus server to import already uploaded file named $filename
( i.e. you already uploaded the file via file_upload() )
=cut
sub report_import {
	my ( $self, $filename ) = @_;
	my $post={ "token" => $self->token, "file" => $filename };
	my $xmls = $self->nessus_request("file/report/import",$post);
	return $xmls;
}

=head2 report_import_file ( $filename )

uploads $filename to nessus server and imports it as nessus report
=cut
sub report_import_file {
	my ( $self, $filename ) = @_;
	my $post={ "token" => $self->token};
	$post->{"file"} = $self->file_upload($filename);
	my $xmls = $self->nessus_request("file/report/import",$post);
	return $xmls;
}

=head2 users_list 

returns ref to array of hash %values with users info 
$values{'name'}
$values{'admin'}
$values{'lastlogin'}
=cut
sub users_list {
	my ( $self ) = @_;

	my $post=[ 
		"token" => $self->token, 
		 ];
	my @users;
	my $xmls = $self->nessus_request("users/list",$post);
	if ($xmls->{'contents'}->[0]->{'users'}->[0]->{'user'}) {
	foreach my $user (@{$xmls->{'contents'}->[0]->{'users'}->[0]->{'user'}}) {
		my %info;
		$info{'name'} = $user->{'name'}->[0];
		$info{'admin'} = $user->{'admin'}->[0];
		$info{'lastlogin'} = $user->{'lastlogin'}->[0];
		push @users, \%info

	} # foreach
	} # if
	return \@users;
}

=head2 users_delete ( $login ) 

deletes user with $login

=cut
sub users_delete {
	my ( $self, $login ) = @_;

	my $post=[ 
		"token" => $self->token, 
		"login" => $login
		 ];
	my $xmls = $self->nessus_request("users/delete",$post);
	my $user = '';
	if ($xmls->{'contents'}->[0]->{'user'}->[0]->{'name'}->[0]) {
		$user = $xmls->{'contents'}->[0]->{'user'}->[0]->{'name'}->[0];
	}
	return $user;
}

=head2 users_add ( $login, $password )

deletes user with $login and $password, return username created, '' if not

=cut
sub users_add {
	my ( $self, $login, $password ) = @_;

	my $post=[ 
		"token" => $self->token, 
		"login" => $login,
		"password" => $password
		 ];
	my $xmls = $self->nessus_request("users/add",$post);
	my $user = '';
	if ($xmls->{'contents'}->[0]->{'user'}->[0]->{'name'}->[0]) {
		$user = $xmls->{'contents'}->[0]->{'user'}->[0]->{'name'}->[0];
	}
	return $user;
}

=head2 users_passwd ( $login, $password )

change user password to $password identified with $login, return username, '' if not

=cut
sub users_passwd {
	my ( $self, $login, $password ) = @_;

	my $post=[ 
		"token" => $self->token, 
		"login" => $login,
		"password" => $password
		 ];
	my $xmls = $self->nessus_request("users/chpasswd",$post);
	my $user = '';
	if ($xmls->{'contents'}->[0]->{'user'}->[0]->{'name'}->[0]) {
		$user = $xmls->{'contents'}->[0]->{'user'}->[0]->{'name'}->[0];
	}
	return $user;
}

=head1 AUTHOR

Vlatko Kosturjak, C<< <kost at linux.hr> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-net-nessus-xmlrpc at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Net-Nessus-XMLRPC>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Net::Nessus::XMLRPC


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Net-Nessus-XMLRPC>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Net-Nessus-XMLRPC>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Net-Nessus-XMLRPC>

=item * Search CPAN

L<http://search.cpan.org/dist/Net-Nessus-XMLRPC>

=back


=head1 REPOSITORY

Repository is available on GitHub: http://github.com/kost/nessus-xmlrpc-perl

=head1 ACKNOWLEDGEMENTS

I have made Ruby library as well: http://nessus-xmlrpc.rubyforge.org/

There you can find some early documentation about XMLRPC protocol used.

=head1 COPYRIGHT & LICENSE

Copyright 2010 Vlatko Kosturjak, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

1; # End of Net::Nessus::XMLRPC
