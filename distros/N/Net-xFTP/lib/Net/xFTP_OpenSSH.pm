package Net::xFTP::OpenSSH;

use Time::Local;

sub new_openssh
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
	delete($args{'Debug'})  if (defined $args{'Debug'});
	delete($args{'warn'})  if (defined $args{'warn'});
	$args{'timeout'} = 15  unless (defined $args{'timeout'});
	if (defined $args{'user'})
	{
		$host =~ s/^[^\@]*\@//o;
		$host = $args{'user'} . '@' . $host;
		delete($args{'user'});
	}
	if (defined $args{'password'})
	{
		if (defined($args{'passphrase'}) && $args{'passphrase'} =~ /\*/)
		{
			#FOR "passphrase => '*'":  USE USER-ENTERED PASSWORD FIELD AS THE PASSPHRASE INSTEAD!:
			$args{'passphrase'} = $args{'password'};
		}
		else
		{
			$host =~ s/\:[^\@]*//o;
			$host =~ s/\@/\:$args{'password'}\@/;
		}
		delete($args{'password'});
	}
	my $saveEnvHome = $ENV{HOME};
	$ENV{HOME} = $xftp_args{home}  if ($xftp_args{home});

	$xftp->{xftp} = Net::OpenSSH->new($host, %args);
	$xftp->{xftp_lastmsg} = $@  if ($@);
	$ENV{HOME} = $saveEnvHome || '';
	if ($xftp->{xftp})
	{
		if ($xftp->{xftp}->error)
		{
			$xftp->{xftp_lastmsg} = $xftp->{xftp}->error;
			$@ = $xftp->{xftp_lastmsg};
			return undef;
		}
		my $cwd = $xftp->{xftp}->capture('pwd');
		if (!$cwd || $xftp->{xftp}->error)
		{
			$xftp->{xftp_lastmsg} = $xftp->{xftp}->error || "xFTP:new_openssh() failed for unknown reason!"
					. ')!';
			$@ = $xftp->{xftp_lastmsg};
			return undef;
		}
		chomp $cwd;
		$xftp->{cwd} = $cwd;
		$xftp->{protocol} = 'Net::OpenSSH';

		return $xftp;
	}
	return undef;
}

sub protocol
{
	return shift->{protocol};
}

{
	no warnings 'redefine';
	sub cwd  #SET THE "CURRENT" DIRECTORY.
	{
		my $self = shift;
		my $cwd = shift || '/';

		my $fullwd;
		#NEXT 22 ADDED 20060815 TO FIX RELATIVE PATH CHANGES.
		if ($cwd !~ m#^\/# && $self->{cwd} && $self->{cwd} !~ /^\./o)
		{
			$cwd = ($self->{cwd} =~ m#\/$#o) ? $self->{cwd} . $cwd : $self->{cwd} . '/' . $cwd;
		}
		elsif ($cwd eq '..')
		{
#DOES NOT CHANGE PWD TO CWD, SO WE KEEP	OURSELVES?!			$self->{xftp}->capture("cd \"$$self{cwd}\"");
#DOES NOT CHANGE PWD TO CWD, SO WE KEEP	OURSELVES?!			$cwd = $self->{xftp}->capture('pwd');
			$cwd = $self->{cwd};  #DOES NOT CHANGE PWD TO CWD, SO WE KEEP	OURSELVES?!
			chomp $cwd;
			chop $cwd  if ($cwd =~ m#\/$#o);
			$cwd =~ s#\/[^\/]+$##o;
			$cwd ||= '/';
		}
		elsif ($cwd eq '.')
		{
#DOES NOT CHANGE PWD TO CWD, SO WE KEEP	OURSELVES?!			$cwd = $self->{xftp}->capture('pwd');
			$cwd = $self->{cwd};  #DOES NOT CHANGE PWD TO CWD, SO WE KEEP	OURSELVES?!
		}
		$self->{xftp}->capture("cd \"$cwd\"");
		$fullwd = $self->{xftp}->capture('pwd');
		if (!$fullwd || $self->{xftp}->error)
		{
			$self->{xftp_lastmsg} = $self->{xftp}->error || "xFTP:cwd() failed for unknown reason!"
					. ')!';
			return undef;
		}
#DOES NOT CHANGE PWD TO CWD, SO WE KEEP	OURSELVES?!	chomp $fullwd;
#DOES NOT CHANGE PWD TO CWD, SO WE KEEP	OURSELVES?!		$self->{cwd} = $fullwd;
		$self->{cwd} = $cwd;   #DOES NOT CHANGE PWD TO CWD, SO WE KEEP	OURSELVES?!
		return 1;
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

		my $notok = $self->{xftp}->capture("cp \"$args[0]\" \"$args[1]\"");
		if ($notok || $self->{xftp}->error)
		{
			$self->{xftp_lastmsg} = "Copy failed (". ($self->{xftp}->error || "xFTP:scp_put() failed for unknown reason!")
					. ')!';
			return undef;
		}
		return 1;
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
	my $realpath = $path || $self->{cwd} || '.';

	$realpath = $self->{cwd} . '/' . $realpath  unless ($realpath =~ m#^(?:[a-zA-Z]\:|\/)#o);
	my @dirHash = $self->{xftp}->capture("ls \"$realpath\"");
	if (!@dirHash || $self->{xftp}->error)
	{
		$self->{xftp_lastmsg} = $self->{xftp}->error || "xFTP:ls() failed for unknown reason!";
		my $err = $self->{xftp}->error;
		return undef;
	}
	return  unless (defined $dirHash[0]);     #ADDED 20071024 FOR CONSISTENCY.

#	shift (@dirHash)  if ($dirHash[0]->{longname} =~ /^total \d/o);  #REMOVE TOTAL LINE!
	my $t;
	@dirlist = ();
	for (my $i=0;$i<=$#dirHash;$i++)
	{
		$t = $dirHash[$i];
		chomp $t;
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
	my $realpath = $path || $self->{cwd} || '.';
	$realpath = $self->{cwd} . '/' . $realpath  unless ($realpath =~ m#^(?:[a-zA-Z]\:|\/)#o);
	my @dirHash = $self->{xftp}->capture("ls -l \"$realpath\"");
	if (!@dirHash || $self->{xftp}->error)
	{
		$self->{xftp_lastmsg} = $self->{xftp}->error || "xFTP:dir() failed for unknown reason!";
		my $err = $self->{xftp}->error;
		return undef;
	}
	my $t;
	@dirlist = ();
	foreach my $t (sort @dirHash)
	{
		#$t = $dirHash[$i]->{longname};
		next  if ($t =~ /\d \.\.$/o && $path eq '/');
		next  if (!$showall && $t =~ /\d \.[^\.]\S*$/o);
		next  if ($t =~ /^total\s+\d+$/o);
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

	return $self->{cwd} || $self->{xftp}->capture('pwd');
}

sub get    #(Remote, => Local [, opts])
{
	my $self = shift;

	return undef  unless (@_ >= 1);
	my @args = @_;
	my $getops = undef;
#	$args[0] = $self->{cwd} . '/' . $args[0]  unless ($args[0] =~ m#^(?:[a-zA-Z]\:|\/)#o);
	if (scalar(@args) >= 2)
	{
		$args[1] = \$_[1]  if (ref(\$args[1]) =~ /GLOB/io);
		$getops = pop(@args)  if (scalar(@args) > 2);
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
	my $ok;
	if (ref(\$_[1]) =~ /GLOB/io)   #2ND ARG(LOCAL FID) IS A FILE HANDLE!
	{
		my ($remoteHandle, $pid);
		my $offset = 0;
		my $buff;
		my $unsubscriptedFH = $_[1];
		($remoteHandle, $pid) = $self->{xftp}->pipe_out("cat $args[0]");
		if (defined($remoteHandle) && $remoteHandle)
		{
			binary $remoteHandle;
			while ($buff = <$remoteHandle>)   #NEVER SEEMS TO READ ANYTHING, THOUGH THIS IS HOW THE DOCS SAY TO DO IT?!
			{
				print $unsubscriptedFH $buff;
				$offset += length($buff);
			}
			close $remoteHandle;
			return $offset;  #FOR FILE-HANDLES, LET'S RETURN THE LENGTH READ (ZERO IS STILL FALSE!)
		}
		else
		{
			$self->{xftp_lastmsg} = $self->{xftp}->error || 'xFTP:get() Could not open remote source handle for unknown reason!';
			return undef;
		}
	}
	else
	{
		my $ok = (defined $getops) ? $self->{xftp}->scp_get($getops, @args)
				: $self->{xftp}->scp_get(@args);
		if ($ok)
		{
			return $ok  if (-f $args[1]);
			#RETURNED OK, BUT LOCAL FILE NOT CREATED?!:
			$self->{xftp_lastmsg} = 'xFTP:get() returned "Ok" but local file not created? ('
					. $! . ') (' . $xftp->{xftp}->error . ')!';
			return undef;
		}
		my $bang = $!;
		my $err = $self->{xftp}->error;
		if ($err || $bang)
		{
			$self->{xftp_lastmsg} = $err || $bang || "xFTP:get() failed - unknown reason!";
			if ($SIG{CHLD} eq 'IGNORE' && $err eq 'scp failed: child exited with code 1')
			{
				$self->{xftp_lastmsg} = $bang;
				if (-f $args[1]) {
					return 1;
				} else {
					return undef;
				}
			}
			return $ok ? 1 : undef;
		}
	}
	return $ok ? 1 : undef;
}

sub put    #(LOCAL, => REMOTE [, opts]) SFTP returns OK=1 on SUCCESS.
{
	my $self = shift;

	return undef  unless (@_ >= 1);
	my @args = @_;
	my $putops = undef;
	if (scalar(@args) >= 2)
	{
		$args[0] = \$_[0]  if (ref(\$args[0]) =~ /GLOB/io);
		$putops = pop(@args)  if (scalar(@args) > 2);
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
#	$args[1] = $self->{cwd} . '/' . $args[1]  unless ($args[1] =~ m#^(?:[a-zA-Z]\:|\/)#o);

	my $ok;
	if (ref(\$_[0]) =~ /GLOB/io)   #1ST ARG(LOCAL FID) IS A FILE HANDLE!
	{
		my ($remoteHandle, $pid);
		my $offset = 0;
		my $buff;
		my $unsubscriptedFH = $_[0];
		($remoteHandle, $pid) = $self->{xftp}->pipe_out(" cat >\"$args[1]\"");
		if (defined($remoteHandle) && $remoteHandle)
		{
			binary $remoteHandle;
			while ($buff = <$unsubscriptedFH>)
			{
				print $remoteHandle $buff;
				$offset += length($buff);
			}
			close $remoteHandle;
			return $offset;  #FOR FILE-HANDLES, LET'S RETURN THE LENGTH WRITTEN (ZERO IS STILL FALSE!)
		}
		else
		{
			$self->{xftp_lastmsg} = $self->{xftp}->error || 'xFTP:put() Could not open remote target handle for unknown reason!';
			return undef;
		}
	}
	else
	{
		my $ok = (defined $putops) ? $self->{xftp}->scp_put($putops, @args)
				: $self->{xftp}->scp_put(@args);
		my $bang = $!;
		my $err = $self->{xftp}->error;
		if (!$ok || $err || $bang)
		{
			$self->{xftp_lastmsg} = $err || $bang || "xFTP:put() failed - unknown reason!";
			if ($SIG{CHLD} eq 'IGNORE' && $err eq 'scp failed: child exited with code 1')
			{
				$self->{xftp_lastmsg} = $bang;
				return 1;
			}
			return $ok ? 1 : undef;
		}
	}
	return $ok ? 1 : undef;
}

sub delete       #RETURNED OK=2 WHEN LAST FAILED.
{
	my $self = shift;
	my $path = shift;

	$path = $self->{cwd} . '/' . $path  unless ($path =~ m#^(?:[a-zA-Z]\:|\/)#o);
	my $notok = $self->{xftp}->capture("rm -f \"$path\"");
	if ($notok || $self->{xftp}->error)
	{
		$self->{xftp_lastmsg} = $self->{xftp}->error || "xFTP:delete() failed - unknown reason!";
		return undef;
	}
	return 1;
}

sub rename
{
	my $self = shift;

	return undef  unless (@_ == 2);

	my ($oldfile, $newfile) = @_;

	$oldfile = $self->{cwd} . '/' . $oldfile  unless ($oldfile =~ m#^(?:[a-zA-Z]\:|\/)#o);
	$newfile = $self->{cwd} . '/' . $newfile  unless ($newfile =~ m#^(?:[a-zA-Z]\:|\/)#o);
	my $notok = $self->{xftp}->capture("mv \"$oldfile\" \"$newfile\"");
	if ($notok || $self->{xftp}->error)
	{
		$self->{xftp_lastmsg} = $self->{xftp}->error || "xFTP:rename() failed - unknown reason!";
		return undef;
	}
	return 1;
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
			$ok = $self->{xftp}->capture("mkdir \"$path\"");
			if ($ok || $self->{xftp}->error)
			{
				$self->{xftp_lastmsg} = $self->{xftp}->error || "xFTP:mkdir() failed - unknown reason!";
				return undef;
			}
			next;
		}
	}
	$ok = $self->{xftp}->capture("mkdir \"$orgPath\"");
	if ($ok || $self->{xftp}->error)
	{
		$self->{xftp_lastmsg} = $self->{xftp}->error || "xFTP:mkdir() failed - unknown reason!";
		return undef;
	}
	return 1;
}

sub rmdir
{
	my $self = shift;
	my $path = shift;

	$path =~ s#[\/\\]$##o  unless ($path eq '/');

	$path = $self->{cwd} . '/' . $path  unless ($path =~ m#^(?:[a-zA-Z]\:|\/)#o);
	my $notok = $self->{xftp}->capture("rmdir \"$path\"");
	if ($notok || $self->{xftp}->error)
	{
		$self->{xftp_lastmsg} = $self->{xftp}->error || "xFTP:rmdir() failed - unknown reason!";
		return undef;
	}
	return $@ ? undef : 1;
}

sub message
{
	my $self = shift;

	return ''  unless ($self->{xftp_lastmsg});
	chomp $self->{xftp_lastmsg};

	return $self->{xftp_lastmsg};
}

sub mdtm
{
	my $self = shift;
	my $path = shift;

	my $ok;
#	$path = $self->{cwd} . '/' . $path  unless ($path =~ m#^(?:[a-zA-Z]\:|\/)#o);
	my @dirHash = $self->{xftp}->capture("stat \"$path\"");
	if (!@dirHash || $self->{xftp}->error)
	{
		$self->{xftp_lastmsg} = $self->{xftp}->error || "xFTP:mdtm() failed for unknown reason!";
		return undef;
	}
	while (@dirHash)
	{
		$ok = shift(@dirHash);
		if ($ok =~ /^Modify\:\s*(\d+)\-(\d+)\-(\d+)\s+(\d+)\:(\d+)\:(\d+)/o)
		{
			my ($yr, $mth, $d, $h, $m, $s) = ($1, $2, $3, $4, $5, $6);
			$ok = timelocal($s, $m, $h, $d, $mth-1, $yr);
			return ($ok > 1) ? $ok : undef;
		}
	}
	return undef;		
}

sub size
{
	my $self = shift;
	my $path = shift;

#	$path = $self->{cwd} . '/' . $path  unless ($path =~ m#^(?:[a-zA-Z]\:|\/)#o);
	my @dirHash = $self->{xftp}->capture("ls -l \"$path\"");
	if (!@dirHash || $self->{xftp}->error)
	{
		$self->{xftp_lastmsg} = $self->{xftp}->error || "xFTP:size() failed for unknown reason!";
		return undef;
	}
	return undef  if ($dirHash[0] =~ /^total\s+\d+$/o);
	return $1  if ($dirHash[$#dirHash] =~ /^\S+\s+\d+\s+\S+\s+\S+\s+(\d+)/o);
	return undef;
}

sub isadir
{
	my $self = shift;
	my $path = shift;

#x	$path = $self->{cwd} . $path  unless ($path =~ m#^\/\.#o);
	unless ($path =~ m#^[\/\.]#o)
	{
		$path = ($self->{cwd} =~ m#\/$#o) ? $self->{cwd} . $path : $self->{cwd} . '/' . $path;
	}
	my @dirHash = $self->{xftp}->capture("ls -ld \"$path\"");
	if (!@dirHash || $self->{xftp}->error)
	{
		$self->{xftp_lastmsg} = $self->{xftp}->error || "xFTP:isadir() failed for unknown reason!";
		return undef;
	}
	return 1  if ($dirHash[0] =~ /^(?:dr|total\s+\d+)/o || $dirHash[$#dirHash] =~ /^total\s+\d+$/o);
	return 0;
}

sub chmod
{
	my $self = shift;
	my $permissions = shift;
	my $path = shift;

	my ($notok, $attrs, @dirHash);
	$path = $self->{cwd} . '/' . $path  unless ($path =~ m#^(?:[a-zA-Z]\:|\/)#o);
	$notok = $self->{xftp}->capture("chmod $permissions \"$path\"");
	if ($notok || $self->{xftp}->error)
	{
		$self->{xftp_lastmsg} = $self->{xftp}->error || "xFTP:chmod() failed for unknown reason!";
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
		$self->{xftp_lastmsg} = "method Net::OpenSSH::$method(".join(',',@_).") returned $@";
		return undef;
	}
	return $res;
}

1
