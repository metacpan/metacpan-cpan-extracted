package Net::xFTP::SFTP;

sub new_sftp
{
	my $subclass = shift;
	my $pkg = shift;
	my $host = shift;
	my %args = @_;
	my %xftp_args;
	my $xftp = bless { }, $subclass;
	$xftp->{BlockSize} = 10240;
	if (defined $args{BlockSize})
	{
		$xftp->{BlockSize} = $args{BlockSize} || 10240;
		delete($args{BlockSize});
	}	
	my $saveEnvHome = $ENV{HOME};
	$ENV{HOME} = $xftp_args{home}  if ($xftp_args{home});
	eval { $xftp->{xftp} = Net::SFTP->new($host, %args, warn => \&sftpWarnings); };
	$xftp->{xftp_lastmsg} = $@  if ($@);
	$ENV{HOME} = $saveEnvHome || '';
	if ($xftp->{xftp})
	{
		my $cwd;
		eval { $cwd = $xftp->{xftp}->do_realpath('.') };
		$xftp->{cwd} = $cwd  if ($cwd);
		return $xftp;
	}
	return undef;
}

{
	no warnings 'redefine';
	sub cwd  #SET THE "CURRENT" DIRECTORY.
	{
		my $self = shift;
		my $cwd = shift || '/';

		my $ok;
		my $fullwd;
		#NEXT 22 ADDED 20060815 TO FIX RELATIVE PATH CHANGES.
		if ($cwd !~ m#^\/# && $self->{cwd} && $self->{cwd} !~ /^\./o)
		{
			if ($self->{cwd} =~ m#\/$#o)
			{
				$cwd = $self->{cwd} . $cwd;
			}
			else
			{
				$cwd = $self->{cwd} . '/' . $cwd;
			}
		}
		elsif ($cwd eq '..')
		{
			$cwd = $self->{xftp}->do_realpath($self->{cwd});
			chop($cwd)  if ($cwd =~ m#\/$#o);
			$cwd =~ s#\/[^\/]+$##o;
			$cwd ||= '/';
		}
		elsif ($cwd eq '.')
		{
			$cwd = $self->{xftp}->do_realpath($self->{cwd});
		}
		eval { $fullwd = $self->{xftp}->do_realpath($cwd) };
		if ($fullwd)
		{
			$self->{cwd} = $fullwd;
			$ok = 1;
		}
		return $ok ? 1 : undef;
	}

	sub copy
	{
		my $self = shift;

		return undef  unless (@_ >= 2);
		my @args = @_;
		for (my $i=0;$i<=1;$i++)
		{
			$args[$i] = $self->{cwd} . '/' . $args[$i]  unless ($args[$i] =~ m#^(?:[a-zA-Z]\:|\/)#o);
		}
		if ($self->isadir($args[1]))
		{
			my $filename = $1  if ($args[0] =~ m#([^\/]+)$#o);
			$args[1] .= '/'  unless ($args[1] =~ m#\/$#o);
			$args[1] .= $filename;
		}

		my $ok;
		unless (defined($self->{haveSFTPConstants}) && $self->{haveSFTPConstants})
		{
			$self->{xftp_lastmsg} = 
				"Copy failed (You must install the Net::SFTP::Constants Perl module!)";
			return undef;
		}
		my ($tmp, $t);
		my $fromHandle;
		eval { $fromHandle = $self->{xftp}->do_open($args[0], 0) };
		unless (defined($fromHandle) && $fromHandle)
		{
			$self->{xftp_lastmsg} = "Copy failed (". ($@||'do_open1 failed - Unknown reason')
					. ')!';
			return undef;
		}
		my $offset = 0;
		my $err;
		while (1)
		{
			($tmp, $err) = $self->{xftp}->do_read($fromHandle, $offset, $self->{BlockSize});
			last  if (defined $err);
			$t .= $tmp;
			$offset += $self->{BlockSize};
		}
		$self->{xftp}->do_close($fromHandle);
		my $toHandle;
		eval { no strict 'subs'; $toHandle = $self->{xftp}->do_open($args[1], 
				SSH2_FXF_WRITE | SSH2_FXF_CREAT | SSH2_FXF_TRUNC) };
		unless (defined($toHandle) && $toHandle)
		{
			$self->{xftp_lastmsg} = "Copy failed (". ($@||'do_open2 failed - Unknown reason')
					. ')!';
			return undef;
		}
		eval { $self->{xftp}->do_write($toHandle, 0, $t) };
		if ($@)
		{
			$self->{xftp_lastmsg} = "Copy failed (". ($@||'write failed - Unknown reason')
					. ')!';
			return undef;
		}
		$self->{xftp}->do_close($toHandle);
		$ok = 1;
		return $ok ? 1 : undef;
	}

	sub move
	{
		my $self = shift;

		return undef  unless (@_ >= 2);
		return ($self->copy(@_) && $self->delete($_[0])) ? 1 : undef;
	}
}

sub ascii
{
	my $self = shift;

	return undef;
}

sub binary
{
	my $self = shift;

	return undef;
}

sub quit
{
	my $self = shift;
	$self->{xftp} = undef;
	delete($self->{xftp});

	return;
}

sub ls
{
	my $self = shift;
	my $path = shift || '';
	my $showall = shift || 0;
	my @dirlist;
	my $realpath;
	eval { $realpath = $self->{xftp}->do_realpath($path||$self->{cwd}||'.') };
	chomp $realpath;
	$realpath = $self->{cwd} . '/' . $realpath  unless ($realpath =~ m#^(?:[a-zA-Z]\:|\/)#o);
	my @dirHash;
	eval { @dirHash = $self->{xftp}->ls($realpath) };
	if ($@)
	{
		$self->{xftp_lastmsg} = $@;
		my $err = $self->{xftp}->status;
		return  if ($err);
	}
	return  unless (defined $dirHash[0]);     #ADDED 20071024 FOR CONSISTENCY.
	shift (@dirHash)  if ($dirHash[0]->{longname} =~ /^total \d/o);  #REMOVE TOTAL LINE!
	my $t;
	@dirlist = ();
	for (my $i=0;$i<=$#dirHash;$i++)
	{
		$t = $dirHash[$i]->{filename};
		next  if ($t eq '..' && $path eq '/');
		next  if (!$showall && $t =~ /^\.[^\.]/o);
		push (@dirlist, $t);
	}
	@dirlist = sort @dirlist;

	##ON SOME SERVERS, THESE DON'T GET ADDED ON, SO ADD THEM HERE!
	#unshift (@dirlist, '..')  unless ($path eq '/' || $dirlist[1] eq '..');
	#unshift (@dirlist, '.')  unless ($dirlist[0] eq '.');

	return wantarray ? @dirlist : \@dirlist;
}

sub dir
{
	my $self = shift;
	my $path = shift || '';
	my $showall = shift || 0;
	my @dirlist;
	my $realpath;
	eval { $realpath = $self->{xftp}->do_realpath($path||$self->{cwd}||'.') };
	chomp $realpath;
	$realpath = $self->{cwd} . '/' . $realpath  unless ($realpath =~ m#^(?:[a-zA-Z]\:|\/)#o);
	my @dirHash;
	eval { @dirHash = $self->{xftp}->ls($realpath) };
	#return  if ($@);
	if ($@)
	{
		$self->{xftp_lastmsg} = $@;
		my $err = $self->{xftp}->status;
		return  if ($err);
	}
	return  unless (defined $dirHash[0]);     #ADDED 20071024 FOR CONSISTENCY.
	shift (@dirHash)  if ($dirHash[0]->{longname} =~ /^total \d/o);  #REMOVE TOTAL LINE!
	my $t;
	@dirlist = ();
	#for (my $i=0;$i<=$#dirHash;$i++)
	foreach my $i (sort { $a->{filename} cmp $b->{filename} } @dirHash)
	{
		#$t = $dirHash[$i]->{longname};
		$t = $i->{longname};
		next  if ($t =~ /\d \.\.$/o && $path eq '/');
		next  if (!$showall && $t =~ /\d \.[^\.]\S*$/o);
		push (@dirlist, $t);
	}

	##ON SOME SERVERS, THESE DON'T GET ADDED ON, SO ADD THEM HERE!
	#unshift (@dirlist, '..')  unless ($path eq '/' || $dirlist[1] =~ /\d \.\.$/);
	#unshift (@dirlist, '.')  unless ($dirlist[0] =~ /\d \.$/);

	return wantarray ? @dirlist : \@dirlist;
}

sub pwd  #GET AND RETURN THE "CURRENT" DIRECTORY.
{
	my $self = shift;

	return $self->{cwd};
}

sub get    #(Remote, => Local)
{
	my $self = shift;

	return undef  unless (@_ >= 1);
	my @args = @_;
	$args[0] = $self->{cwd} . '/' . $args[0]  unless ($args[0] =~ m#^(?:[a-zA-Z]\:|\/)#o);
	if (@args >= 2)
	{
		$args[1] = \$_[1]  if (ref(\$args[1]) =~ /GLOB/io);
	}
	else
	{
		if (ref(\$args[0]) eq 'GLOB')
		{
			$self->{xftp_lastmsg} = 'Must specify a remote filename (2 arguments) since 1st arg. is a filehandle!';
			return undef;
		}
		$args[1] = $args[0];
		$args[1] = $1  if ($args[1] =~ m#([^\/\\]+)$#o);
	}
	my $ok;
	if (ref(\$_[1]) eq 'GLOB')
	{
		my $remoteHandle;
		my $offset = 0;
		my $buff;
		my $unsubscriptedFH = $_[1];
		eval { $remoteHandle = $self->{xftp}->do_open($args[0], 0) };
		if ($remoteHandle)
		{
			my $err;
			while (1)
			{
				($buff, $err) = $self->{xftp}->do_read($remoteHandle, $offset, $self->{BlockSize});
				last  if (defined $err);
				print $unsubscriptedFH $buff;
				$offset += $self->{BlockSize};
			}
			$self->{xftp}->do_close($remoteHandle);
			return 1;
		}
		else
		{
			$self->{xftp_lastmsg} = $@ || 'Could not open remote handle for unknown reasons!';
			return undef;
		}
	}
	else
	{
		eval { $self->{xftp}->get(@args) };
		if ($@)
		{
			$self->{xftp_lastmsg} = $@;
			$ok = $self->{xftp}->status;
			return $ok ? undef : 1;
		}
		else
		{
			return 1;
		}
	}
	return $ok ? 1 : undef;
}

sub put    #(LOCAL => REMOTE) SFTP returns OK=1 on SUCCESS.
{
	my $self = shift;

	return undef  unless (@_ >= 1);
	my @args = @_;
	if (@args >= 2)
	{
		$args[0] = \$_[0]  if (ref(\$args[0]) =~ /GLOB/io);
	}
	else
	{
		if (ref(\$args[0]) =~ /GLOB/io)
		{
			$self->{xftp_lastmsg} = 'Must specify a remote filename (2 arguments) since 1st arg. is a filehandle!';
			return undef;
		}
		$args[1] = $args[0];
		$args[1] = $1  if ($args[1] =~ m#([^\/\\]+)$#o);
	}
	$args[1] = $self->{cwd} . '/' . $args[1]  unless ($args[1] =~ m#^(?:[a-zA-Z]\:|\/)#o);

	my $ok;
	if (ref(\$_[0]) eq 'GLOB')
	{
		unless (defined($self->{haveSFTPConstants}) && $self->{haveSFTPConstants})
		{
			$self->{xftp_lastmsg} = 
				"Copy failed (You must install the Net::SFTP::Constants Perl module!)";
			return undef;
		}
		my $remoteHandle;
		my $offset = 0;
		my $buff;
		my $unsubscriptedFH = $_[0];
		eval { no strict 'subs'; $remoteHandle = $self->{xftp}->do_open($args[1], 
				SSH2_FXF_WRITE | SSH2_FXF_CREAT | SSH2_FXF_TRUNC) };
		if ($remoteHandle)
		{
			my $t;
			while ($buff = <$unsubscriptedFH>)
			{
				$t .= $buff;
			}
			eval { $self->{xftp}->do_write($remoteHandle, 0, $t) };
			if ($@)
			{
				$self->{xftp_lastmsg} = $@;
				$ok = $self->{xftp}->status;
				return $ok ? undef : 1;
			}
			else
			{
				return 1;
			}
			$self->{xftp}->do_close($remoteHandle);
			return 1;
		}
		else
		{
			$self->{xftp_lastmsg} = $@ || 'Could not open remote handle for unknown reasons!';
			return undef;
		}
	}
	else
	{
		eval { $ok = $self->{xftp}->put(@args) };
		$self->{xftp_lastmsg} = $@  if ($@);
	}
	return $ok ? 1 : undef;
}

sub delete       #RETURNED OK=2 WHEN LAST FAILED.
{
	my $self = shift;
	my $path = shift;

	my $ok;
	$path = $self->{cwd} . '/' . $path  unless ($path =~ m#^(?:[a-zA-Z]\:|\/)#o);
	eval { $ok = $self->{xftp}->do_remove($path) };
	$self->{xftp_lastmsg} = $@  if ($@);
	return $@ ? undef : 1;
}

sub rename
{
	my $self = shift;
	return undef  unless (@_ == 2);

	my ($oldfile, $newfile) = @_;

	my $ok;
	$oldfile = $self->{cwd} . '/' . $oldfile  unless ($oldfile =~ m#^(?:[a-zA-Z]\:|\/)#o);
	$newfile = $self->{cwd} . '/' . $newfile  unless ($newfile =~ m#^(?:[a-zA-Z]\:|\/)#o);
	eval { $ok = $self->{xftp}->do_rename($oldfile, $newfile) };
	$self->{xftp_lastmsg} = $@  if ($@);
	return $@ ? undef : 1;
}

sub mkdir
{
	my $self = shift;
	my $path = shift;
	my $tryRecursion = shift||0;
	$path =~ s#[\/\\]$##o  unless ($path eq '/');

	my @pathStack;
	my $ok = '';
	my $orgPath = $path;
	my $didRecursion = 0;
	$path = $self->{cwd} . '/' . $path  unless ($path =~ m#^(?:[a-zA-Z]\:|\/)#o);
	while ($path)
	{
		$path =~ s#[^\/\\]+$##o;
		$path =~ s#[\/\\]$##o;
		$path = '/'  unless ($path);
		last  if ($self->isadir($path));
		if ($tryRecursion)
		{
			push (@pathStack, $path);
			$didRecursion = 1;
			last  if ($path eq '/');
		}
		else
		{
			$self->{xftp_lastmsg} = "mkdir:Could not create path($orgPath) since parent not directory!";
			return undef;
		}
	}
	if ($didRecursion)
	{
		while (@pathStack)
		{
			$path = pop @pathStack;
			eval { $ok = $self->{xftp}->do_mkdir($path, Net::SFTP::Attributes->new()) };
			if ($@)
			{
				$self->{xftp_lastmsg} = $@;
				return undef;
			}
			next;
		}
	}
	eval { $ok = $self->{xftp}->do_mkdir($orgPath, Net::SFTP::Attributes->new()) };
	if ($@)
	{
		$self->{xftp_lastmsg} = $@;
		return undef;
	}
	return 1;
}

sub rmdir
{
	my $self = shift;
	my $path = shift;
	$path =~ s#[\/\\]$##o  unless ($path eq '/');

	my $ok;
	$path = $self->{cwd} . '/' . $path  unless ($path =~ m#^(?:[a-zA-Z]\:|\/)#o);
	eval { $ok = $self->{xftp}->do_rmdir($path) };
	$self->{xftp_lastmsg} = $@  if ($@);
	return $@ ? undef : 1;
}

sub message
{
	my $self = shift;

	chomp $self->{xftp_lastmsg};
	my @res = $self->{xftp}->status;
	return ($self->{xftp_lastmsg} =~ /^\s*$res[0]/) ? $self->{xftp_lastmsg} : "$res[0]: $res[1] - $self->{xftp_lastmsg}";
}

sub sftpWarnings  #ONLY WAY TO GET NON-FATAL WARNINGS INTO $@ INSTEAD OF STDERR IS TO USE THIS CALLBACK!
{                 #(WE ALWAYS WRAP SFTP->METHODS W/AN EVAL)!
	my $self = shift;
	my @res = $self->status;
	die "$res[0]: $res[1] - ".join(' ', @_)."\n";
}

sub mdtm
{
	my $self = shift;
	my $path = shift;

	my $ok;
	$path = $self->{cwd} . '/' . $path  unless ($path =~
	m#^(?:[a-zA-Z]\:|\/)#o);
	eval { $ok = $self->{xftp}->do_stat($path) };
	unless (defined($ok) && $ok)
	{
		$self->{xftp_lastmsg} = $@;
		return undef;
	}
	return $ok->mtime();
}

sub size
{
	my $self = shift;
	my $path = shift;

	my $ok;
	$path = $self->{cwd} . '/' . $path  unless ($path =~ m#^(?:[a-zA-Z]\:|\/)#o);
	eval { $ok = $self->{xftp}->do_stat($path) };
	unless (defined($ok) && $ok)
	{
		$self->{xftp_lastmsg} = $@;
		return undef;
	}
	return $ok->size();
}

sub isadir
{
	my $self = shift;
	my $path = shift;

	my $ok;
	$path = $self->{cwd} . '/' . $path  unless ($path =~ m#^(?:[a-zA-Z]\:|\/)#o);
	eval { $ok = $self->{xftp}->do_opendir($path) };
	if (defined($ok) && $ok)
	{
		eval { $self->{xftp}->do_close($ok) };
		return 1;
	}
	return 0;
}

sub chmod
{
	my $self = shift;
	my $permissions = shift;
	my $path = shift;

	my ($ok, $attrs);
	$path = $self->{cwd} . '/' . $path  unless ($path =~ m#^(?:[a-zA-Z]\:|\/)#o);
	eval { $attrs = $self->{xftp}->do_stat($path) };
	unless (defined($attrs) && $attrs)
	{
		$self->{xftp_lastmsg} = $@;
		return undef;
	}
	eval "\$permissions = 0$permissions";
	if ($@)
	{
		$self->{xftp_lastmsg} = "Invalid permissions (000-777) - $@";
		return undef;
	}
	$attrs->perm($permissions);
	eval { $ok = $self->{xftp}->do_setstat($path, $attrs) };
	if ($@ || !defined($ok))
	{
		$self->{xftp_lastmsg} = $@;
		return undef;
	}
	return 1;
}

sub method
{
	my $self = shift;
	my $method = shift;

	for (my $i=0;$i<scalar(@_);$i++)
	{
		$_[$i] = "'" . $_[$i] . "'"  unless ($_[$i] =~ /^['"]/o || $_[$i] =~ /^[\d\.\+\-]+$/o);
	}
	my $res;
	my $xeq = " \$res = \$self->{xftp}->$method(".join(',', @_).")";
	eval $xeq;
	if ($@)
	{
		$self->{xftp_lastmsg} = "method Net::SFTP::$method(".join(',',@_).") returned $@";
		return undef;
	}
	return $res;
}

1
