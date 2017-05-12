#*** DownloadMirror.pm ***#
# Copyright (C) 2006 - 2008 by Torsten Knorr
# create-soft@tiscali.de
# All rights reserved!
#------------------------------------------------
 use strict;
#------------------------------------------------
 package Net::DownloadMirror::FileName;
 use Storable;
 sub TIESCALAR { my ($class, $obj) = @_; return(bless(\$obj, $class || ref($class))); }
 sub STORE
 	{
 	if(-f $_[1])
 		{
 		${$_[0]}->{_last_modified} = retrieve($_[1]);
 		}
 	else
 		{
 		${$_[0]}->{_last_modified} = {};
 		store(${$_[0]}->{_last_modified}, $_[1]);
 		warn("\nno information of the files last modified times\n");
 		}
 	}
 sub FETCH { return(${$_[0]}->{_filename}); }
#-------------------------------------------------
 package Net::DownloadMirror;
#------------------------------------------------
 use Net::MirrorDir 0.19;
 use File::Path;
 use Storable;
#------------------------------------------------
 @Net::DownloadMirror::ISA = qw(Net::MirrorDir);
 $Net::DownloadMirror::VERSION = '0.10';
#-------------------------------------------------
 sub _Init
 	{
 	my ($self, %arg) = @_;
 	tie($self->{_filename}, 'Net::DownloadMirror::FileName', $self);
 	$self->{_filename}		= $arg{filename}	|| 'lastmodified_remote';
 	$self->{_delete}		= $arg{delete}	|| 'disabled';
 	$self->{_current_modified}	= {};
 	return 1;
 	}
#-------------------------------------------------
 sub Download
 	{
 	my ($self) = @_;
	return 0 unless($self->Connect());
 	my ($rh_lf, $rh_ld) = $self->ReadLocalDir();
 	if($self->{_debug})
 		{
 		print("local files : $_\n") for(sort keys %$rh_lf);
 		print("local dirs : $_\n") for(sort keys %$rh_ld);
 		}
 	my ($rh_rf, $rh_rd) = $self->ReadRemoteDir();
 	if($self->{_debug})
 		{
 		print("remote files : $_\n") for(sort keys %$rh_rf);
 		print("remote dirs : $_\n") for(sort keys %$rh_rd);
 		}
 	my $ra_rdnil = $self->RemoteNotInLocal($rh_ld, $rh_rd);
 	if($self->{_debug})
 		{
 		print("remote directories not in local: $_\n") for(@$ra_rdnil);
 		}
 	$self->MakeDirs($ra_rdnil);
 	my $ra_rfnil = $self->RemoteNotInLocal($rh_lf, $rh_rf);
 	if($self->{_debug})
 		{
 		print("remote files not in local : $_\n") for(@$ra_rfnil);
 		}
 	$self->StoreFiles($ra_rfnil);
 	if($self->{_delete} eq 'enable')
 		{
 		my $ra_lfnir = $self->LocalNotInRemote($rh_lf, $rh_rf);
 		if($self->{_debug})
 			{
 			print("local files not in remote: $_\n") for(@$ra_lfnir);
 			}
 		$self->DeleteFiles($ra_lfnir);
 		my $ra_ldnir = $self->LocalNotInRemote($rh_ld, $rh_rd);
 		if($self->{_debug})
 			{
 			print("local directories not in remote : $_\n") for(@$ra_ldnir);
 			}
 		$self->RemoveDirs($ra_ldnir);
 		}
 	delete(@{$rh_rf}{@$ra_rfnil});
 	my $ra_mrf = $self->CheckIfModified($rh_rf);
 	if($self->{_debug})
 		{
 		print("modified remote files : $_\n") for(@$ra_mrf);
 		}
 	$self->StoreFiles($ra_mrf);
 	$self->Quit();
 	return 1;
 	}
#-------------------------------------------------
 sub CheckIfModified
 	{
 	my ($self, $rh_rf) = @_;
 	return [] unless($self->IsConnection());
 	my @mf;
 	my $changed = undef;
 	for my $rf (keys(%$rh_rf))
 		{
 		next unless($self->{_current_modified}{$rf} = $self->{_connection}->mdtm($rf));
 		if(defined($self->{_last_modified}{$rf}))
 			{
 			next if($self->{_last_modified}{$rf} eq $self->{_current_modified}{$rf});
 			}
 		else
 			{
 			$self->{_last_modified}{$rf} = $self->{_current_modified}{$rf};
 			$changed++;
 			}
 		push(@mf, $rf);
 		}
 	store($self->{_last_modified}, $self->{_filename}) if($changed);
 	return \@mf;
 	}
#-------------------------------------------------
 sub UpdateLastModified
 	{
 	my ($self, $ra_rf) = @_;
 	return unless($self->IsConnection());
 	my $mt;
 	for(@$ra_rf)
 		{
 		next unless($mt = $self->{_connection}->mdtm($_));
 		next unless($mt =~ m/^\d+$/);
 		$self->{_last_modified}{$_} = $mt;
 		}
	store($self->{_last_modified}, $self->{_filename});
 	return 1;
 	}
#-------------------------------------------------
 sub StoreFiles
 	{
 	my ($self, $ra_rf) = @_;
 	return 0 unless(@$ra_rf && $self->IsConnection());
 	my $lf;
 	for my $rf (@$ra_rf)
 		{
 		$lf = $rf;
 		$lf =~ s!$self->{_regex_remotedir}!$self->{_localdir}!;
 		next unless($self->{_connection}->get($rf, $lf));
 		$self->{_last_modified}{$rf} = 
 			$self->{_current_modified}{$rf}
 			|| $self->{_connection}->mdtm($rf);
 		}
 	store($self->{_last_modified}, $self->{_filename});
 	return 1;
 	}
#-------------------------------------------------
 sub MakeDirs
 	{
 	my ($self, $ra_rd) = @_;
 	return 0 unless(@$ra_rd);
 	my $ld;
 	for my $rd (@$ra_rd)
 		{
 		$ld = $rd;
 		$ld =~ s!$self->{_regex_remotedir}!$self->{_localdir}!;
 		mkpath($ld, $self->{_debug}) unless(-d $ld);
 		}
 	return 1;
 	}
#-------------------------------------------------
 sub DeleteFiles
 	{
 	my ($self, $ra_lf) = @_;
 	return 0 unless(($self->{_delete} eq 'enable') && @$ra_lf);
	my $rf;
 	for my $lf (@$ra_lf)
 		{
 		$rf = $lf; 
 		next unless(-f $lf);
 		warn("can not unlink : $lf\n") unless(unlink($lf));
 		$rf =~ s!$self->{_regex_localdir}!$self->{_remotedir}!;
 		delete($self->{_last_modified}{$rf})
 			if(defined($self->{_last_modified}{$rf}));
 		}
 	store($self->{_last_modified}, $self->{_filename});
 	return 1;
 	} 
#-------------------------------------------------
 sub RemoveDirs
 	{
 	my ($self, $ra_ld) = @_;
 	return 0 unless(($self->{_delete} eq 'enable') && @$ra_ld);
 	for my $ld (@$ra_ld)
 		{
 		next unless(-d $ld);
 		rmtree($ld, $self->{_debug}, 1);
 		}
 	return 1;
 	}
#------------------------------------------------
 sub CleanUp
 	{
 	my ($self, $ra_exists) = @_;
 	my %h_temp = ();
 	for my $key (@$ra_exists)
 		{
		if(
 			defined($self->{_last_modified}{$key})
 			&& 
 			($self->{_last_modified}{$key} =~ m/^\d+$/)
 			)
 			{
 			$h_temp{$key} = delete($self->{_last_modified}{$key});
 			}
 	 	if($self->{_debug})
 	 		{
 			print(
 				"key: $_	value: "
 				. (defined($self->{_last_modified}{$_}) ? $self->{_last_modified}{$_} : 'undef')
 				. " removed\n")
					for(keys(%{$self->{_last_modified}}));
 			}
 		}
 	%{$self->{_last_modified}} = %h_temp;
 	store($self->{_last_modified}, $self->{_filename});
 	return 1;
 	}
#-------------------------------------------------
 sub LtoR
 	{
 	my ($self, $ra_lp) = @_;
 	my $ra_rp = [];
 	my $rp;
 	for(@$ra_lp)
 		{
 		$rp = $_;
 		$rp =~ s!$self->{_regex_localdir}!$self->{_remotedir}!;
 		push(@$ra_rp, $rp);
 		}
 	return $ra_rp;
 	}
#-------------------------------------------------
 sub RtoL
 	{
 	my ($self, $ra_rp) = @_;
 	my $ra_lp = [];
 	my $lp;
 	for(@$ra_rp)
 		{
 		$lp = $_;
 		$lp =~ s!$self->{_regex_remotedir}!$self->{_localdir}!;
 		push(@$ra_lp, $lp);
 		}
 	return $ra_lp;
 	}
#-------------------------------------------------
1;
#------------------------------------------------
__END__

=head1 NAME

Net::DownloadMirror - Perl extension for mirroring a remote location via FTP to the local directory

=head1 SYNOPSIS

  use Net::DownloadMirror;
  my $um = Net::DownloadMirror->new(
 	ftpserver		=> 'my_ftp.hostname.com',
 	user		=> 'my_ftp_user_name',
 	pass		=> 'my_ftp_password',
 	);
 $um->Download();
 
 or more detailed
 my $md = Net::DownloadMirror->new(
 	ftpserver		=> 'my_ftp.hostname.com',
 	user		=> 'my_ftp_user_name',
 	pass		=> 'my_ftp_password',
 	localdir		=> 'home/nameA/homepageA',
 	remotedir	=> 'public',
 	debug		=> 1 # 1 for yes, 0 for no
 	timeout		=> 60 # default 30
 	delete		=> 'enable' # default 'disabled'
 	connection	=> $ftp_object, # default undef
# "exclusions" default empty arrayreferences []
 	exclusions	=> ["private.txt", "Thumbs.db", ".sys", ".log"],
# "subset" default empty arrayreferences [ ]
 	subset		=> [".txt, ".pl", ".html", "htm", ".gif", ".jpg", ".css", ".js", ".png"],
# or substrings in pathnames
#	exclusions	=> ["psw", "forbidden_code"]
#	subset		=> ["name", "my_files"]
# or you can use regular expressions
# 	exclusinos	=> [qr/SYSTEM/i, $regex]
# 	subset		=> {qr/(?i:HOME)(?i:PAGE)?/, $regex]
 	filename		=> "modified_times",
 	);
 $um->Download();

=head1 DESCRIPTION

This module is for mirroring a remote location to a local directory via FTP.
For example websites, documentations or developmentstuff which ones were
uploaded or changed in the net. Local files will be overwritten,
also in case they are newer. It is not developt for mirroring large archivs.
But there are not in principle any limits.

=head1 Constructor and Initialization

=item (object) new (options)
 Net::DownloadMirror is a derived class from Net::MirrorDir.
 For detailed information about constructor or options
 read the documentation of Net::MirrorDir.

=head2 methods

=item (1) _Init (%arg)
 This function is called by the constructor.
 You do not need to call this function by yourself.

=item (1|0) Downlaod (void)
 Call this function for mirroring automatically, recommended!!!

=item (ref_hash_modified_files) CheckIfModified (ref_array_local_files)
 Takes a hashreference of remoe filenames to compare the last modification time,
 which is stored in a file, named by the attribute "filename", while downloading. 
 Returns a reference of a array.

=item (1|undef) UpdateLastModified (ref_array_remote_files)
 Update the stored modified-times of the remote files.

=item (1|0) StoreFiles (ref_array_paths)
 Takes a arrayreference of remote-paths to download via FTP.

=item (1|0) MakeDirs (ref_array_paths)
 Takes a arrayreference of directories to make in the local directory.

=item (1|0) DeleteFiles (ref_array_paths)
 Takes a arrayreference of files to delete in the local directory.

=item (1|0) RemoveDirs (ref_array_paths)
 Takes a arrayreference of directories to remove in the local directory.

=item (1) CleanUp (ref_array_paths)
 Takes a arrayreference of directories to compare with the keys 
 in the {_last_modified} hash. Is the key not in the array or
 the value is incorrect, the key will be deleted.

=item (ref_array_local_paths) RtoL (ref_array_remote_paths)
 Takes a arrayreference of Remotepathnames and returns
 a arrayreference of the corresponding Localpathnames.

=item (ref_array_remote_paths) LtoR (ref_array_local_paths)
 Takes a arrayreference of Localpathnames and returns
 a arrayreference of the corresponding Remotepathnames.

=head2 optional options

=item filename
 The name of the file in which the last modified times will be stored.
 default = 'lastmodified_remote'

 =item delete
 When directories or files are to be deleted = 'enable'
 default = 'disabled'

=head2 EXPORT

None by default.

=head1 SEE ALSO

 Net::MirrorDir
 Net::UploadMirror
 Tk::Mirror
 http://freenet-homepage.de/torstenknorr/index.html

=head1 FILES

 Net::MirrorDir 0.19
 Storable
 File::Path

=head1 BUGS

Maybe you'll find some. Let me know.

=head1 REPORTING BUGS

When reporting bugs/problems please include as much information as possible.

=head1 AUTHOR

Torsten Knorr, E<lt>create-soft@tiscali.deE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 - 2008 by Torsten Knorr

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.9.2 or,
at your option, any later version of Perl 5 you may have available.

=cut

