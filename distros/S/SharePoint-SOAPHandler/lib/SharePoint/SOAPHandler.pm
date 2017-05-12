package SharePoint::SOAPHandler;

use 5.008000;
use strict;
use warnings;

#our @ISA = qw(CopyTree::VendorProof);
use base qw(CopyTree::VendorProof);
use Authen::NTLM qw/ntlmv2/;ntlmv2('sp');
#use base happens at compile time, so we don't get the runtime error from our, saying that
#Can't locate package CopyTree::VendorProof for @SharePoint::SOAPHandler::ISA at (eval 8) line 2.
our $VERSION = '0.0013';
use SOAP::Lite;
#use SOAP::Data; #included in SOAP::Lite
use LWP::UserAgent;
use LWP::Debug;
use Data::Dumper;
use MIME::Base64 ();
use Carp ();
use File::Basename ();

# Preloaded methods go here.

sub new{
	my $class=shift;
	my  %args = @_; #not used, we set default args in bless, then offer option to reset
	Carp::croak("Options to LWP::UserAgent should be key/value pairs, not hash reference")
        if ref($_[1]) eq 'HASH';
	#NOTE: you will get an error "Attempt to bless into a reference at lib/SharePoint/soaphandler.pm line 24" if you (accidentally) called a method that doesn't exist.
	my $self = bless {
						sp_creds_uaargs => [(keep_alive=>1)], #requires for NTLM
						sp_creds_uaagent => 'Mozilla/5.0',
					

							}, $class;
	return $self;

}


sub sp_creds_uaargs{
	my $inst = shift;
	if (@_){	
		#$inst->{'sp_creds_uaargs'}= [@_]; $inst; #mon aug 2
		$inst->{'sp_creds_uaargs'}= shift; $inst;
	}
	else{@{$inst ->{'sp_creds_uaargs'}}}
}
sub sp_creds_domain{
	my $inst = shift;
	if (@_){	
		my $site = shift;
		if ($site =~/%20/){
			Carp::carp("Do not use %20 for spaces\n");
			$site =~s/%20/ /g;	
		}
		$inst->{'sp_creds_domain'}=$site; $inst;
	}
	else{$inst ->{'sp_creds_domain'}}


}
sub sp_creds_user{
	my $inst = shift;
	if (@_){	
		my $domuser = shift;
		my ($dom, $user)=split /\\/, $domuser;
		$dom = uc($dom);
		$domuser = join('\\', $dom, $user);
		$inst->{'sp_creds_user'}= $domuser; $inst;}
	else{$inst ->{'sp_creds_user'}}
}
sub sp_creds_password{
	my $inst = shift;
	if (@_){	$inst->{'sp_creds_password'}= shift; $inst;}
	else{$inst ->{'sp_creds_password'}}
}
#string, "Mozilla/5.0"
sub sp_creds_uaagent{
	my $inst = shift;
	if (@_){	$inst->{'sp_creds_uaagent'}= shift; $inst;}
	else{$inst ->{'sp_creds_uaagent'}}
}

sub sp_creds_credentials{
	my $inst = shift;
	if (@_){	$inst->{'sp_creds_credentials'}= [@_]; $inst;}
	else{@{$inst ->{'sp_creds_credentials'}}}
}
#user agent object
sub sp_creds_schema_ua{
	my $inst = shift;
	if (@_){ $inst ->{'sp_creds_schema_ua'}=shift; $inst;}
	else{$inst -> {'sp_creds_schema_ua'}}
}	
#sp_authorized root is the root web address just above the Shared Documents link
#that the user cred is authorized to post
#e.g., https://sharepoint.shit.net/sitelevel/subsitelevel/collaboration
sub sp_authorizedroot{
	my $inst = shift;
	if (@_){	
		my $site = shift;
		$site =~s/\/$//; #auto removes trailing slashes
		if ($site =~/%20/){
			Carp::carp("Do not use %20 for spaces\n");
			$site =~s/%20/ /g;	
		}
		$inst->{'sp_authorizedroot'}=$site; $inst;
	}
	else{$inst ->{'sp_authorizedroot'}}
}
sub slvti{
	my $inst = shift;
	if (@_){	$inst->{'slvti'}= shift; $inst;}
	else{$inst ->{'slvti'}}
}
sub sluri{
	my $inst = shift;
	if (@_){$inst->{'sluri'}= shift;$inst;}
	else{$inst ->{'sluri'}}
}
#sitedata lists dirs
sub slsitedataobj{
	my $inst = shift;
	if (@_){	$inst->{'slsitedataobj'}= shift;
		$inst->{'slsitedataobj'}->on_action(sub{"$_[0]$_[1]"}); 
		$inst;
	}
	else{$inst ->{'slsitedataobj'}}
}
sub slcopyobj{
	my $inst = shift;
	if (@_){	$inst->{'slcopyobj'}= shift;
		$inst->{'slcopyobj'}->on_action(sub{"$_[0]$_[1]"}); 
		$inst;
	}
	else{$inst ->{'slcopyobj'}}
}     
#dws creates and deletes dirs
sub sldwsobj{
   my $inst = shift;
   if (@_){ $inst->{'sldwsobj'}= shift;
      $inst->{'sldwsobj'}->on_action(sub{"$_[0]$_[1]"});
      $inst;
   }
   else{$inst ->{'sldwsobj'}}
}              
#list enables deleting of single files and listing list items, whatever that means for sharepoint
sub sllistobj{
   my $inst = shift;
   if (@_){ $inst->{'sllistobj'}= shift;
      $inst->{'sllistobj'}->on_action(sub{"$_[0]$_[1]"});
      $inst;
   }
   else{$inst ->{'sllistobj'}}
}              


#if there are shell env variables to tell anything to go through a proxy server,
#this swtich says either to follow(0) or ignore(1) the proxy directions
sub sp_creds_proxy{
	my $inst = shift;
	if (@_){	$inst->{'sp_creds_proxy'}=[@_] ; $inst;}
	else{@{$inst ->{'sp_creds_proxy'}}}
}
sub sp_creds_noproxy{
	my $inst = shift;
	if (@_){	$inst->{'sp_creds_noproxy'}= [@_]; $inst;}
	else{@{$inst ->{'sp_creds_noproxy'}}}
}
#sp_connect requires two ua's, one for LWP and one for SOAP::Lite operations
sub sp_connect_lwp{
	my $soap_inst = shift;
	Carp::carp("sp_creds_uaargs not set\n") if (! $soap_inst->sp_creds_uaargs);
	if (! $soap_inst->sp_creds_domain){
		Carp::croak("sp_creds_domain not set\n");
	}
	elsif ($soap_inst->sp_creds_domain =~m/http/ or $soap_inst->sp_creds_domain =~m/\/\//){
		Carp::croak("sp_creds_domain should not contain protocol\n".
			"use 'sharepoint.site:443' instead of 'https://sharepoint.site:443'"
		);
	}
	Carp::carp("sp_creds_user not set\n") if (! $soap_inst->sp_creds_user);
	Carp::carp("sp_creds_password not set\n") if (! $soap_inst->sp_creds_password);
	Carp::carp("sp_creds_uaagent not set\n") if (! $soap_inst->sp_creds_uaagent);
	#skip this sub if LWP shema_ua is already set
	if (ref $soap_inst ->sp_creds_schema_ua){
		return $soap_inst;
	}
	$soap_inst ->sp_creds_credentials($soap_inst->sp_creds_domain, '', $soap_inst->sp_creds_user, $soap_inst->sp_creds_password);
	my $sp_schema_ua = LWP::UserAgent->new($soap_inst->sp_creds_uaargs);
	#LWP wants credentials in an array, not arrayref	
	$sp_schema_ua -> credentials($soap_inst->sp_creds_credentials);
	$sp_schema_ua ->agent($soap_inst->sp_creds_uaagent);
	#$sp_schema_ua ->proxy($soap_inst->sp_creds_proxy);
	#$sp_schema_ua ->no_proxy($soap_inst->sp_creds_noproxy);
	$soap_inst ->sp_creds_schema_ua($sp_schema_ua);

	return ($soap_inst);
}


sub sp_sitedataini{
	my $soap_inst=shift;
	return $soap_inst if (ref $soap_inst->slsitedataobj);
	$soap_inst -> sp_connect_lwp;
	$soap_inst->slvti($soap_inst->sp_authorizedroot()."/_vti_bin/SiteData.asmx");
	#remember this uri requires a trailing slash
	$soap_inst -> sluri("http://schemas.microsoft.com/sharepoint/soap/");
	#Important.  SOAP::Lite-> proxy wants arguments to be in list form; uaargs is the same format
	#as LWP would prefer;
	#credentials is NOT the same: LWP wants array; SOAP::Lite::porxy wants array ref

	$soap_inst -> slsitedataobj ( SOAP::Lite ->proxy ($soap_inst->slvti, $soap_inst ->sp_creds_uaargs, credentials =>[$soap_inst->sp_creds_credentials]) );

	$soap_inst -> slsitedataobj() -> schema->useragent($soap_inst->sp_creds_schema_ua);
	#$soap_inst -> slsitedataobj() -> uri($s_uri);
	$soap_inst -> slsitedataobj() -> uri($soap_inst->sluri);
	return $soap_inst;#->slsitedataobj; 
	#@$slsitedataobj ->on_action(sub{qq/$_[0]$_[1]/});#now included in sub slsitedataobj
#################IMPORTANT#################

#=head1 IMPORTANT: Microsoft soap doesn't use header info that SOAP::Lite requires
#
#i.e. SOAP::Lite uses default schemas.soap.come/#Function (uri#method), while MS uses
#shcemas.microsoft.com/soap/Function (urimethod)
#
#If this is not set properly, you will get soap errors.  Took me 3 days printing Dumpers
#to everything to discover this stupid error
#
#This function is now included when setting the obj, i.e. sub slsitedataobj
#
#=cut

}
sub carpenvproxy{
	Carp::carp("_____________________________________________________________\nYou might get a 500 can't connect error (Bad service 'port/')\n\t if your sharepoint is on https, and you have\n\t a https_proxy env var set,\n\t but the sharepoint does NOT require a proxy to connect.\n\t to fix, remove your https_proxy env variable. (in perl, delete \$ENV{'https_proxy'})\n\t".
      " bug from SOAP::Transport::HTTP, calls for SUPER::env_proxy from LWP::UserAgent, does\n\t".
      " not know how to deal with https_proxy (no_proxy does not override https_proxy, only http_proxy\n");

}
	
sub fdls{
	my $soap_inst = shift;
	#my $sp_sitedataobj = shift;
	Carp::croak("fdls item must be an instance, not a class\n") unless (ref $soap_inst);

	my $lsoption=shift; #'d', 'f', 'fdarrayrefs'  or undef
	$lsoption ='' if !($lsoption);
	my $rootsearchfolder =shift;
	$rootsearchfolder = $soap_inst ->SUPER::path if (!$rootsearchfolder); #'Shared Documents' or 'Shared Documents/something'
	$rootsearchfolder=~s/\/$//;#removes trailing slashes, should be trouble

	$soap_inst ->sp_sitedataini if (!ref $soap_inst->slsitedataobj );
	my $sp_sitedataobj= $soap_inst->slsitedataobj;
	my $in_strfolderurl=SOAP::Data::name('strFolderUrl'=>$rootsearchfolder);
	if ($ENV{'https_proxy'}){
		$soap_inst ->carpenvproxy;
	}
	my $enufolderobj=$sp_sitedataobj->EnumerateFolder($in_strfolderurl);
	#SHAREPOINT BUG STUPID:  if only 1 item is returned, we get a hashref;
	#if more than 1 item is returned, we get an array ref of hashrefs
	#if no items returned, we get scalar undef
	#REMEMBER: EnumerateFolder DOES NOT work on files - must test parent dir first
	my $resultref = $enufolderobj -> body ->{'EnumerateFolderResponse'}{'vUrls'}{'_sFPUrl'};
	if (ref $resultref eq 'HASH'){#fix stupid SHAREPOINT bug
		$resultref = [$resultref];
	}
	
	#Carp::carp("resultref is ". print Dumper $resultref);
	delete $soap_inst->{'sp_sitedataenufolderret'};
	$soap_inst->{'sp_sitedataenufolderret'}->{'dir'}=[];
	$soap_inst->{'sp_sitedataenufolderret'}->{'file'}=[];
	if ($resultref){ #$resultref is undef if no items returned
		for my $item (@$resultref){
   	      if ($item->{'IsFolder'} eq 'true'){
   	         #print "[d] ".$item->{'Url'}."\n";# if ($item->{'IsFolder'} eq 'true'); #Url, IsFolder, LastModified
					push @{$soap_inst->{'sp_sitedataenufolderret'}->{'dir'}}, $item ->{'Url'};
   	      }
   	      else {
   	         #print "[f] ".$item->{'Url'}."\n";
					push @{$soap_inst->{'sp_sitedataenufolderret'}->{'file'}}, $item ->{'Url'};
   	      }
   	}#end for my $item
	}
	$soap_inst ->SUPER::fdls_ret ( $lsoption, \@{$soap_inst->{'sp_sitedataenufolderret'}->{'file'}},  \@{$soap_inst->{'sp_sitedataenufolderret'}->{'dir'}} );

}

sub sp_sitedatagetlistcol{
	my $soap_inst = shift;
	$soap_inst ->sp_sitedataini if (!ref $soap_inst->slsitedataobj );
		my $sp_sitedataobj= $soap_inst->slsitedataobj;
		if ($ENV{'https_proxy'}){
			$soap_inst ->carpenvproxy;
		}
		my $getlistcolobj=$sp_sitedataobj->GetListCollection();
	
		my $resultref = $getlistcolobj -> body->{'GetListCollectionResponse'}{'vLists'}{'_sList'};
		return $resultref;
		#the return is an array ref of hash refs of keys and values

}

sub sp_copyini{
	my $soap_inst=shift;
	return $soap_inst if (ref $soap_inst->slcopyobj);
	$soap_inst -> sp_connect_lwp;
	$soap_inst->slvti($soap_inst->sp_authorizedroot()."/_vti_bin/Copy.asmx");
	#remember this uri requires a trailing slash
	$soap_inst -> sluri("http://schemas.microsoft.com/sharepoint/soap/");
	#Important.  SOAP::Lite-> proxy wants arguments to be in list form; uaargs is the same format
	#as LWP would prefer;
	#credentials is NOT the same: LWP wants array; SOAP::Lite::porxy wants array ref

	$soap_inst -> slcopyobj ( SOAP::Lite ->proxy ($soap_inst->slvti, $soap_inst ->sp_creds_uaargs, credentials =>[$soap_inst->sp_creds_credentials]) );

	$soap_inst -> slcopyobj() -> schema->useragent($soap_inst->sp_creds_schema_ua);
	#$soap_inst -> slcopyobj() -> uri($s_uri);
	$soap_inst -> slcopyobj() -> uri($soap_inst->sluri);
	return $soap_inst;#->slcopyobj; 
}
#memory is a ref to a scalar, in bin mode
sub read_into_memory{
	my $soap_inst = shift;
	my $sourcepath =shift; #return obj from  sitedataenufolder, e.g., "Shared Documents/index.html"
	$sourcepath=$soap_inst->SUPER::path if (!$sourcepath);

	$soap_inst->sp_copyini if (!ref $soap_inst->slcopyobj );
		my $sp_copyobj= $soap_inst->slcopyobj;
		if ($ENV{'https_proxy'}){
			$soap_inst ->carpenvproxy;
		}
		my $in_strfileurl=SOAP::Data::name('Url'=>$soap_inst->sp_authorizedroot()."/".$sourcepath);
		my $getcopy=$sp_copyobj->GetItem($in_strfileurl);

		my $result_bin=MIME::Base64::decode_base64( $getcopy -> body->{'GetItemResponse'}{'Stream'} );
		Carp::carp("source file/dir on sharepoint [$sourcepath] does not exit (no stream) - ignoring this entry\n") if (! $result_bin);

		#IMPORTANT: GetItem returns NO ERROR on files that doesn't exist
		return (\$result_bin); #I decided to not decode the file in case it's a binary.
			#will rely on calling program to decode it to make data transfer safe
}


#memory is a ref to a scalar, in bin mode
sub write_from_memory{
	my $soap_inst = shift;
	my $binref =shift;
	my $destinationurl = shift;# in this version, I will only support writeing to one single dest
								#Shared Documents/something - do not use full path
	$destinationurl = $soap_inst ->SUPER::path if (!$destinationurl);
	my $sourceurl='local'; #doesn't do shit, but needs a value for it to work
	my $fields=[];# = shift; #array ref of field items, 
	#my $stream = ; #array ref of single item byte stream, from slurping in binmode

	Carp::carp ("no destinationurl in write_from_memory \n") if (! $destinationurl);
	Carp::carp ("no stream in write_from_memory \n") if (! $$binref);
	$soap_inst->sp_copyini if (!ref $soap_inst->slcopyobj );
		my $sp_copyobj= $soap_inst->slcopyobj;
		if ($ENV{'https_proxy'}){
			$soap_inst ->carpenvproxy;
		}
		my $in_sourceurl=SOAP::Data::name('SourceUrl'=>$sourceurl);
		#construct full path
		my $destinationurls = [$destinationurl];
		for my $destfileurl(@$destinationurls){
			$destfileurl = $soap_inst->sp_authorizedroot(). "/".$destfileurl;
			$destfileurl = SOAP::Data::name ('string' => $destfileurl);
		}
		my $in_destinationurls=&soaparrayfmt("DestinationUrls", $destinationurls);
		my $in_fields=&soaparrayfmt("Fields", $fields);
		my $in_stream = SOAP::Data::name ('Stream' =>MIME::Base64::encode_base64($$binref));
		my $copyresult = $sp_copyobj ->CopyIntoItems($in_sourceurl, $in_destinationurls, $in_fields, $in_stream);
		return $copyresult->body; #returns the same msg if file exists vs copy success


}


sub copy_local_files{
	my $soap_inst = shift;
	my $sourceurl=shift;
	my $destinationurl = shift;# SCALAR now, different from sp_copyremotefiles
								#Shared Documents/something - do not use full path
	Carp::carp ("no sourceurl in sp_copypostfile \(copy no source\)\n") if (! $sourceurl);
	Carp::carp ("no destinationurls in sp_copypostfile \(copy no destination\)\n") if (! $destinationurl);
	$soap_inst -> sp_copyini if (!ref $soap_inst->slcopyobj );
		my $sp_copyobj= $soap_inst->slcopyobj;
		if ($ENV{'https_proxy'}){
			$soap_inst ->carpenvproxy;
		}
		my $in_sourceurl=SOAP::Data::name('SourceUrl'=>$soap_inst->sp_authorizedroot().'/'.$sourceurl);
		#construct full path
		my $destinationurls = [$destinationurl];
		for my $destfileurl(@$destinationurls){
			$destfileurl = $soap_inst->sp_authorizedroot(). "/".$destfileurl;
			$destfileurl = SOAP::Data::name ('string' => $destfileurl);
		}
	
		my $in_destinationurls=&soaparrayfmt("DestinationUrls", $destinationurls);
		my $copyresult = $sp_copyobj ->CopyIntoItemsLocal($in_sourceurl, $in_destinationurls) ->body;		
		return $copyresult;

}	
#not really necessary functionally since write_from_memory and read_to_memory covers this,
#but it is more efficient since files are moved within sharepoint


sub soaparrayfmt {
	my $arraytitle = shift;
	my $arrayref = shift;
	my $in_arraytitle =SOAP::Data::name($arraytitle =>\SOAP::Data::value(
								SOAP::Data::name('anonymous' => @$arrayref)
												)#end value
							);#end name
	return $in_arraytitle; 
}	


sub sp_dwsini{
	my $soap_inst=shift;
	return $soap_inst if (ref $soap_inst->sldwsobj);
	$soap_inst -> sp_connect_lwp;
	$soap_inst->slvti($soap_inst->sp_authorizedroot()."/_vti_bin/Dws.asmx");
	####dws is the only one where the uri is in a sub dir
	#remember this uri requires a trailing slash
	$soap_inst -> sluri("http://schemas.microsoft.com/sharepoint/soap/dws/");
	#Important.  SOAP::Lite-> proxy wants arguments to be in list form; uaargs is the same format
	#as LWP would prefer;
	#credentials is NOT the same: LWP wants array; SOAP::Lite::porxy wants array ref

	$soap_inst -> sldwsobj ( SOAP::Lite ->proxy ($soap_inst->slvti, $soap_inst ->sp_creds_uaargs, credentials =>[$soap_inst->sp_creds_credentials]) );

	$soap_inst -> sldwsobj() -> schema->useragent($soap_inst->sp_creds_schema_ua);
	#$soap_inst -> sldwsobj() -> uri($s_uri);
	$soap_inst -> sldwsobj() -> uri($soap_inst->sluri);
	return $soap_inst;#->sldwsobj; 

}

sub sp_dws{
	my $soap_inst = shift;
	my $dirtomk = shift;
	my $action=shift;
	$soap_inst->sp_dwsini if (!ref $soap_inst->sldwsobj );
		my $sp_dwsobj= $soap_inst->sldwsobj;
		if ($ENV{'https_proxy'}){
			$soap_inst ->carpenvproxy;
		}
		#url starts with Shared Documents
		my $in_url=SOAP::Data::name('url'=>$dirtomk);
		my $dwsret;
		if ($action eq 'mkdir'){
			$dwsret = $sp_dwsobj ->CreateFolder($in_url)->body->{'CreateFolderResponse'}{'CreateFolderResult'};
#returns "<Error ID="13">AlreadyExists</Error>" if already exists, '<Result/>' if success
		}
		elsif ($action eq 'rmdir'){
			$dwsret =  $sp_dwsobj ->DeleteFolder($in_url)->body->{'DeleteFolderResponse'}{'DeleteFolderResult'};
#returns '<Result/>' if success or folder does not exist
		}
		return $dwsret;
}
sub sp_listini{
	my $soap_inst=shift;
	return $soap_inst if (ref $soap_inst->sllistobj);
	$soap_inst -> sp_connect_lwp;
	$soap_inst->slvti($soap_inst->sp_authorizedroot()."/_vti_bin/Lists.asmx");
	####list is the only one where the uri is in a sub dir
	#remember this uri requires a trailing slash
	$soap_inst -> sluri("http://schemas.microsoft.com/sharepoint/soap/");
	#Important.  SOAP::Lite-> proxy wants arguments to be in list form; uaargs is the same format
	#as LWP would prefer;
	#credentials is NOT the same: LWP wants array; SOAP::Lite::porxy wants array ref

	$soap_inst -> sllistobj ( SOAP::Lite ->proxy ($soap_inst->slvti, $soap_inst ->sp_creds_uaargs, credentials =>[$soap_inst->sp_creds_credentials]) );

	$soap_inst -> sllistobj() -> schema->useragent($soap_inst->sp_creds_schema_ua);
	#$soap_inst -> sllistobj() -> uri($s_uri);
	$soap_inst -> sllistobj() -> uri($soap_inst->sluri);
	return $soap_inst;#->sllistobj; 

}
#returns "<Error ID="13">AlreadyExists</Error>" if already exists, '<Result/>' if success
sub cust_mkdir {
	my $soap_inst =shift;
	my $dirtomk = shift;
	if ($dirtomk eq '/' or $dirtomk eq 'Shared Documents'){
		Carp::carp('should not be mkdiring a root');
	}
	else {
		$soap_inst ->sp_dws($dirtomk, 'mkdir');
	}

}
#returns '<Result/>' if success or folder does not exist
sub cust_rmdir{
	my $soap_inst =shift;
	my $dirtomk = shift;
	if ($dirtomk eq '/' or $dirtomk eq 'Shared Documents'){
		Carp::carp('should not be rmdiring a root');
	}
	elsif ($soap_inst ->is_fd($dirtomk) eq 'd'){
		$soap_inst ->sp_dws($dirtomk, 'rmdir');
	}
	else {
		Carp::croak("wait. you told me to delete something that's not a dir. I'll stop for your protection");
	}
}
sub cust_rmfile{
	my $soap_inst=shift;
	my $filepath =shift;
	Carp::croak ("cannot rmfile a non-file") if ($soap_inst->is_fd($filepath) ne 'f');
	$soap_inst ->sp_listini if (! ref $soap_inst ->sllistobj);
	my $sp_listobj = $soap_inst -> sllistobj;
	if ($ENV{'https_proxy'}){
		$soap_inst ->carpenvproxy;
	}
	#first, we need the shared documents list id to do the delete.
	my $shareddoclistid =$soap_inst -> {'sllistid'}{'Shared Documents'} ;
	if (!$shareddoclistid){
		#the dataof function returns a series of blessed references.  These series of refs are not put 
		#in an arrayref.  Rather, they are just a series of blessed items.  You can put it in @results, 
		#and each item will be a SOAP::Data instance.  You CANNOT access these instances through @{blah->dataof('/blah') }
		#the error msg will say Not an ARRAY reference 
		my @results = $sp_listobj ->GetListCollection() ->dataof('//GetListCollectionResult/Lists/List');
		for my $data (@results){#{ $sp_listobj ->GetListCollection() ->dataof('//GetListCollectionResult/Lists/List') }){
			if ($data->attr ->{'Title'} eq "Shared Documents"){
				$shareddoclistid = $data ->attr ->{'ID'} ;
				$soap_inst -> {'sllistid'}{'Shared Documents'}=$shareddoclistid;		
			}#end if
		}#end for my $data
	}#end if !shareddoclistid
	my $in_str_listname = SOAP::Data::name('listName' => $shareddoclistid);
	my $fullqualified = $soap_inst->sp_authorizedroot().'/'.$filepath;
	my $xml = qq#<Batch OnError="Continue" PreCalc="TRUE" ListVersion="0"> <Method ID="1" Cmd="Delete"> <Field Name="ID">3</Field> <Field Name="FileRef">$fullqualified</Field> </Method> </Batch>#;
	my $in_str_xml_xml = SOAP::Data->type ('xml' =>qq# <updates>$xml</updates>#);
#basically, we want the xml to look like this: (spaces between update tags and $xml will crash the command)
#  <soap:Body>
#    <UpdateListItems xmlns="http://schemas.microsoft.com/sharepoint/soap/">
#      <listName>$shareddoclistid</listName>
#      <updates>$xml</updates>
#    </UpdateListItems>
#  </soap:Body>
	$sp_listobj ->UpdateListItems($in_str_listname, $in_str_xml_xml);

}
sub is_fd{
	my $soap_inst = shift;
	my $query =shift;
	if ($query =~m/\/$/){ #if query ends with slash 'someting/'
		Carp::carp("sharepoint file/dir should not have trailing slashes\n");
		return 0;
	}
	else {
		my $queryparent = File::Basename::dirname($query);
		#in sharepoint, you can't really query the root Shared Documents folder.
		#to do it right, you're supposed to use getlistcollection.  more resources -
		#not doing it.
		if ($queryparent eq '.'){ #result of no slashes in $query
			if ($query eq 'Shared Documents'){
				return 'd';
			}
			else {return 0}
		}
		my ($testfunderparent, $testdunderparent) = $soap_inst -> fdls('fdarrayrefs' , $queryparent);#only needs to return what's defined as file
		#my @testparent = $soap_inst -> sp_ls($queryparent, 'f');#only needs to return what's defined as file
		if ( @$testfunderparent + @$testdunderparent ==0){#$query can not be anything if it's parent is not a dir
			# Carp::carp("query $query 's parent is not a valid folder..check your path[$query]\n");
			return 0;
		}#end if (! @testparent)
		else{
			my %trackmatchf;
			for my $file (@$testfunderparent) {
				$trackmatchf {$file} ++;
			}
			my %trackmatchd;
			for my $dir (@$testdunderparent){
				$trackmatchd{$dir} ++;
			}

			if ($trackmatchf {$query}){
			#  Carp::carp("query $query is a file through searching parent\n");
				return 'f';
			}
			elsif ($trackmatchd {$query}){
				return 'd';
			}
			else {return 'pd'};
		}#end else 
	} #end else main test

}


1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

SharePoint::SOAPHandler - Perl extension for providing a Sharepoint connecter instance for CopyTree::VendorProof.

This module provides a new [sic.] contructor and necessary subclass methods for CopyTree::VendorProof in order to deal with remote Sharepoint file operations.


What?

Oh, yes.  You've probabaly stumbled across this module because you wanted to copy something recursively.  Did you want to move some files into or off your SharePoint file server?  Did you buy Opentext's Livelink EWS and wish to automate some file transfers?  Well, this is kinda the right place, but it gets righter. Check out the documentation on my CopyTree::VendorProof module, where I have a priceless drill and screw analogy for how these modules all work together.  The information on this page is a tad too technical if all you're trying to decide is whether this is the module you need.

=head1 IMPORTANT NOTICE: Your Implementation might not work unless you read this!

Currenly, you need to install Authen::NTLM version 1.09 or greater for this module to work.  With my v1.09 tweak to Authen::NTLM on CPAN, this module should just work.  If you actually use Authen::NTLM directly for some reason, remember to set

	ntlmv2('sp');

prior to using SharePoint::SOAPHandler.  You did remember to export ntlmv2, no?

	use Authen::NTLM qw(ntlmv2);

For those of you with earlier versions of Authen::NTLM, see the historic segment below.

Also, if your Sharepoint connects through https, but does not go through a proxy server, even though all your OTHER http/ https traffic does, you must:

	delete $ENV{'https_proxy'}

This is because when SOAP::Lite -> proxy calls SOAP::Transport, your %ENV is inspected for proxy settings.
Specifying the https sharepoint domain on the no_proxy list will not mask https_proxy, because oddly, no_proxy only works for 'no http' and not 'no https'.  These are just some annoying things I discovered.  Your milage may vary.

----historic----

Please note that as of this writing in July 2011, there is an NTLM bug that needs to be hacked for the sharepoint connector SharePoint::SPCOPY to work.  Basically, LWP normally automatically negotiates NTLM protocols, and calls its LWP::Authen::Ntlm to in turn call Authen::NTLM to authenticate against windows domains.  The problem is, sharepoint prefers an authentication between ntlmv2 and ntlmv1 that's offered by the Authen::NTLM package.  LWP::Authen::Ntlm does not specify any version.  This causes authentication to fail on sharepoint.  The web community offers a quick fix to 'patch' Authen::NTLM, which involves finding the Authen::NTLM module (perhaps in /usr/local/share/perl/5.10.1/Authen/NTLM.pm) and changing around line 289, where $domain =substr($challenge, $c_info->{domain}{offset}, $c_info->{domain}{len}); is to be changed to $domain = &unicode("domain");  This is CRITICALLY IMPORTANT if you want SharePoint::SOAPHandler to work.  I have created a patch that is a varient of this solution, but does not break backwards compatibility.  You can find this patch at 

https://rt.cpan.org/Ticket/Display.html?id=70703

Remember, either of these fixes must be applied for this module to work.  If the above instructions are unclear, please google http://shareperl.blogspot.com/2010/01/sharepoint-perl-connection.html. 

----end historic----

=head1 SYNOPSIS

  use SharePoint::SOAPHandler;

To create a soaphandler connector instance:

	my $soaphandler_inst = SharePoint::SOAPHandler ->new;

#set up connection parameters

#IMPORTANT sp_creds_domain should not have the protocol (http or https://)

	$soaphandler_inst ->sp_creds_domain('www.sharepointsite.org:443');
	$soaphandler_inst ->sp_creds_user('DOMAIN_in_CAPs\username');
	$soaphandler_inst ->sp_creds_password('domain_password');
	$soaphandler_inst ->sp_authorizedroot('https://www.sharepointsite.org:443/some_dirs/the_dir_just_above_the_Shared_Documents_dir_that_you_are_allowed_to_edit');

To add a source or destination item to a CopyTree::VendorProof instance:

	my $ctvp_inst = CopyTree::VendorProof ->new;

All Sharepoint file operations defined in this module uses 'Shared Documents' as a starting root path.  To define any file, you need not (and may not) provide the full uri.  Since Microsoft sometimes requests partial url and sometimes requests full urls, I prefer to append information rather than match and remove information from a url string.  Was that whining I hear?  I didn't see you writing a module for sharepoint.

#all soaphandler paths starts with Shared Documents/

	$ctvp_inst ->src ('Shared Documents/path to your source', $soaphandler_inst);

	$ctvp_inst ->dst ('Shared Documents/path to your destination', $soaphandler_inst);

	$ctvp_inst ->cp;

This in effect copies 

	Shared Documents/path to your source

to your 

	path to your destination/source base name' 

if your source is a dir, or if your sources are a mixture of dirs and /or files.

If you're doing single file to single file copy, you would have

	'Shared Documents/path to your destination'

holding the content of your source file.

=head1 DESCRIPTION

SharePoint::SOAPHandler provides different types of methods.  

First, it provides connection methods to allow us to connect to sharepoint.  These connection methods that you see in the SYNOPSIS are pretty self explanatory. 

Second, SharePoint::SOAPHandler provides methods for its parent class (CopyTree::VendorProof), which includes

	new
	fdls				
	is_fd
	read_info_memory
	write_from_memory
	copy_local_files
	cust_mkdir
	cust_rmdir
	cust_rmfile

The functionality of these methods are described in 

perldoc CopyTree::VendorProof 

Under the section "Object specific instance methods for the base class CopyTree::VendorProof"

It is worth nothing that fdls comes in quite handy for testing whether you can actually connect to your sharepoint resource using this module.  Simply open up your web browser and go to your sharepoint site, and fdls any directory that you can see under Shared Documents.  If you do a Dumper print, you should have a list of files and dirs.

	use Data::Dumper;
	print Dumper $soaphandler_inst -> fdls('', 'Shared Documents');

Lastly, SharePoint::SOAPHandler also provides methods for interacting with sharepoint's getlistcollection items.  These sharepoint methods are not extensively tested and are not supported, nor is it documented here.  To tell the truth, not all methods are *entensively* tested, but with these you are especially on your own.


=head1 SEE ALSO

CopyTree::VendorProof
CopyTree::VendorProof::LocalFileOp 
Livelink::DAV

=head1 AUTHOR

dbmolester, dbmolester de gmail.com

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011 by dbmolester

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself, either Perl version 5.10.1 or, at your option, any later version of Perl 5 you may have available.  

=cut
