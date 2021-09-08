package Net::xFTP::Foreign;
use Fcntl ':mode';
use Net::SFTP::Foreign::Constants qw( SSH2_FXF_CREAT SSH2_FXF_WRITE );

my @permvec = ('---','--x','-w-','-wx','r--','r-x','rw-','rwx');

sub new_foreign
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
	my $saveEnvHome = $ENV{HOME};
#	$ENV{HOME} = $xftp_args{home}  if ($xftp_args{home});
	$SIG{ALRM} = sub { die "timeout" };
	eval
	{
		alarm(defined($args{'login_timeout'}) ? $args{'login_timeout'} : 25);
		$xftp->{xftp} = Net::SFTP::Foreign->new($host, %args);
	};
	my $at = $@;
	$xftp->{xftp_lastmsg} = $at  if ($at);
	alarm(0);
	return undef  if ($at =~ /timeout/io);
#	$ENV{HOME} = $saveEnvHome || '';
	if ($xftp->{xftp})
	{
		my $errORwarn;
		if ($xftp->{xftp}->error)
		{
			$errORwarn = $xftp->{xftp}->error;
#			$xftp->{xftp_lastmsg} = $xftp->{xftp}->error;
#			$@ = $xftp->{xftp_lastmsg};
#			return undef;
		}
		my $cwd = $xftp->{xftp}->setcwd('.');
		if (defined($cwd) && $cwd)
		{
			$xftp->{cwd} = $cwd;
			return $xftp;
		}
		if ($xftp->{xftp}->error)
		{
			$xftp->{xftp_lastmsg} = $xftp->{xftp}->error;
			$xftp->{xftp_lastmsg} .= ' ' . $errORwarn  if ($errORwarn);
			$@ = $xftp->{xftp_lastmsg};
			$xftp->{protocol} = 'Net::SFTP::Foreign';
			return undef;
		}
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
		$fullwd = $self->{xftp}->setcwd($cwd);
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
		my ($tmp, $t);
		my $fromHandle = $self->{xftp}->open($args[0]);
		unless (defined($fromHandle) && $fromHandle)
		{
			$self->{xftp_lastmsg} = "Copy failed1 (". ($self->{xftp}->error||'open failed - Unknown reason')
					. ')!';
			return undef;
		}
		my $offset = 0;
		my $err;
		while (1)
		{
			$tmp = $self->{xftp}->read($fromHandle, $self->{BlockSize});
			last  if ($self->{xftp}->error);
			$t .= $tmp;
			$offset += $self->{BlockSize};
		}
		$self->{xftp}->close($fromHandle);
		my $toHandle = $self->{xftp}->open($args[1], 
				SSH2_FXF_CREAT | SSH2_FXF_WRITE );
		unless (defined($toHandle) && $toHandle)
		{
			$self->{xftp_lastmsg} = "Copy failed2 (". ($self->{xftp}->error||'open2 failed - Unknown reason')
					. ')!';
			return undef;
		}
		$ok = $self->{xftp}->write($toHandle, $t);
		unless (defined($ok) && $ok)
		{
			$self->{xftp_lastmsg} = "Copy failed3 (". ($self->{xftp}->error||'write failed - Unknown reason')
					. ')!';
			return undef;
		}
		$self->{xftp}->close($toHandle);
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
	my $realpath = $path;
	$realpath = $self->{cwd} . '/' . $realpath  unless ($realpath =~ m#^(?:[a-zA-Z]\:|\/)#o);
	my $dirListRef = $self->{xftp}->ls($realpath);
	unless (defined $dirListRef)
	{
		$self->{xftp_lastmsg} = $self->{xftp}->error;
		return  undef;
	}
	my ($t, @tm, @tp, $permStr);
	@dirlist = ();
	foreach my $i (sort { $a->{filename} cmp $b->{filename} } @{$dirListRef})
	{
		push (@dirlist, $i->{filename});
	}

	##ON SOME SERVERS, THESE DON'T GET ADDED ON, SO ADD THEM HERE!
	#unshift (@dirlist, '..')  unless ($path eq '/' || $dirlist[1] =~ /\.\.$/);
	#unshift (@dirlist, '.')  unless ($dirlist[0] =~ /\.$/);

	return wantarray ? @dirlist : \@dirlist;
}

sub dir
{
	my $self = shift;
	my $path = shift || '';
	my $showall = shift || 0;
	my @dirlist;
	my $realpath = $path;
	$realpath = $self->{cwd} . '/' . $realpath  unless ($realpath =~ m#^(?:[a-zA-Z]\:|\/)#o);
	my $dirListRef = $self->{xftp}->ls($realpath);
	#return  if ($@);
	unless (defined $dirListRef)
	{
		$self->{xftp_lastmsg} = $self->{xftp}->error;
		return  undef;
	}
#	shift (@dirHash)  if ($dirHash[0]->{longname} =~ /^total \d/o);  #REMOVE TOTAL LINE!
	my ($t, @tm, @tp, $permStr);
	@dirlist = ();
	#for (my $i=0;$i<=$#dirHash;$i++)
	foreach my $i (sort { $a->{filename} cmp $b->{filename} } @{$dirListRef})
	{
		#$t = $dirHash[$i]->{longname};
		$t = $i->{filename};
		chomp $t;
		next  if ($t =~ /\.\.$/o && $path eq '/');
		next  if (!$showall && $t =~ /\.[^\.]\S*$/o);
#		$tp = substr($i->{a}->flags,0,1);
#		$tp = '-'  if ($tp =~ /f/io);
		@tm = localtime($i->{a}->mtime);
		$permStr = &getPermStr($i->{a}->{perm});
		$_ = sprintf "%10s %s %s %8s %4d-%2.2d-%2.2d %2.2d:%2.2d %s\n", 
				$permStr, (($i->{a}->uid =~ /\S/o) ? $i->{a}->uid : '-unknown-'),
				(($i->{a}->gid =~ /\S/o) ? $i->{a}->gid : '-unknown-'),
				$i->{a}->{size}||'0', 
				$tm[5]+1900, $tm[4]+1, $tm[3], $tm[2], $tm[1], $t;
		push (@dirlist, $_);
	}

	##ON SOME SERVERS, THESE DON'T GET ADDED ON, SO ADD THEM HERE!
	#unshift (@dirlist, '..')  unless ($path eq '/' || $dirlist[1] =~ /\.\.$/);
	#unshift (@dirlist, '.')  unless ($dirlist[0] =~ /\.$/);

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
#	$args[0] = $self->{cwd} . '/' . $args[0]  unless ($args[0] =~ m#^(?:[a-zA-Z]\:|\/)#o);
	if (@args >= 2)
	{
		$args[1] = \$_[1]  if (ref(\$args[1]) =~ /GLOB/io);
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
	my $ok = $self->{xftp}->get(@args);
	unless (defined($ok) && $ok)
	{
		$self->{xftp_lastmsg} = $self->{xftp}->error;
		return undef;
	}
	return 1;
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
#	$args[1] = $self->{cwd} . '/' . $args[1]  unless ($args[1] =~ m#^(?:[a-zA-Z]\:|\/)#o);

	my $ok = $self->{xftp}->put(@args);
	unless (defined($ok) && $ok)
	{
		$self->{xftp_lastmsg} = $self->{xftp}->error;
		return undef;
	}
	return 1;
}

sub delete       #RETURNED OK=2 WHEN LAST FAILED.
{
	my $self = shift;
	my $path = shift;

#	$path = $self->{cwd} . '/' . $path  unless ($path =~ m#^(?:[a-zA-Z]\:|\/)#o);
	my $ok = $self->{xftp}->remove($path);
	unless (defined($ok) && $ok)
	{
		$self->{xftp_lastmsg} = $self->{xftp}->error;
		return undef;
	}
	return 1;
}

sub rename
{
	my $self = shift;
	return undef  unless (@_ == 2);

	my ($oldfile, $newfile) = @_;

	my $ok = $self->{xftp}->rename($oldfile, $newfile);
	unless (defined($ok) && $ok)
	{
		$self->{xftp_lastmsg} = $self->{xftp}->error;
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
			$ok = $self->{xftp}->mkdir($path);
			unless (defined($ok) && $ok)
			{
				$self->{xftp_lastmsg} = $self->{xftp}->error;
				return undef;
			}
			next;
		}
	}
	$ok = $self->{xftp}->mkdir($orgPath);
	unless (defined($ok) && $ok)
	{
		$self->{xftp_lastmsg} = $self->{xftp}->error;
		return undef;
	}
	return 1;
}

sub rmdir
{
	my $self = shift;
	my $path = shift;
	$path =~ s#[\/\\]$##o  unless ($path eq '/');

	my $ok = $self->{xftp}->rmdir($path);
	unless (defined($ok) && $ok)
	{
		$self->{xftp_lastmsg} = $self->{xftp}->error;
		return undef;
	}
	return 1;
}

sub message
{
	my $self = shift;

	$self->{xftp_lastmsg} ||= '';
	chomp $self->{xftp_lastmsg};
	my $res = $self->{xftp}->status;
	return (length $res) ? ("$res - ".$self->{xftp_lastmsg}) : $self->{xftp_lastmsg};
}

sub mdtm
{
	my $self = shift;
	my $path = shift;

	my $ok;
#	$path = $self->{cwd} . '/' . $path  unless ($path =~ m#^(?:[a-zA-Z]\:|\/)#o);
	$ok = $self->{xftp}->stat($path);
	unless (defined($ok) && $ok && defined($ok->mtime))
	{
		$self->{xftp_lastmsg} = $@;
		return undef;
	}
	return $ok->mtime;
}

sub size
{
	my $self = shift;
	my $path = shift;

	my $ok;
#	$path = $self->{cwd} . '/' . $path  unless ($path =~ m#^(?:[a-zA-Z]\:|\/)#o);
	$ok = $self->{xftp}->stat($path);
	unless (defined($ok) && $ok && defined($ok->size))
	{
		$self->{xftp_lastmsg} = $@;
		return undef;
	}
	return $ok->size;
}

sub isadir
{
	my $self = shift;
	my $path = shift;

	my $ok;
	$path = $self->{cwd} . '/' . $path  unless ($path =~ m#^(?:[a-zA-Z]\:|\/)#o);
	$ok = $self->{xftp}->opendir($path);
	if (defined($ok) && $ok)
	{
		eval { $self->{xftp}->closedir($ok) };
		my $stat = $self->{xftp}->stat($path);   #JWT:NEXT 2 ADDED PATCH BY mavit.org.uk TO ADDRESS BUG#74082: Net::xFTP::Foreign::isadir() to GlobalSCAPE EFT
		return 1  if (defined($stat) && S_ISDIR($stat->perm));
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
	$attrs = $self->{xftp}->stat($path);
	unless (defined($attrs) && $attrs)
	{
		$self->{xftp_lastmsg} = $self->{xftp}->error;
		return undef;
	}
	eval "\$permissions = 0$permissions";
	if ($@)
	{
		$self->{xftp_lastmsg} = "Invalid permissions (000-777) - $@";
		return undef;
	}
	$attrs->set_perm($permissions);
	$ok = $self->{xftp}->setstat($path, $attrs);
	unless (defined($ok) && $ok)
	{
		$self->{xftp_lastmsg} = $self->{xftp}->error;
		return undef;
	}
	return 1;
}

sub getPermStr
{
	my $mode = shift;

	my (%ftypes);
	$ftypes{(S_IFDIR)} = "d";
	$ftypes{(S_IFCHR)} = "c";
	$ftypes{(S_IFREG)} = "-"  if (defined S_IFREG);
	if ($bummer)   #FOR SOME REASON WINDOWS FCNTL DOES NOT HAVE THESE, BUT WE NEED -
	{              #THEM WHEN LOOKING AT SPECIAL FILES ON OTHER UNIX SYSTEMS:
		$ftypes{24576} = "b";
		$ftypes{4096} = "p";
		$ftypes{40960} = "l";
		$ftypes{49152} = "s";
	}
	else
	{
		$ftypes{(S_IFBLK)} = "b";
		$ftypes{(S_IFIFO)} = "p";
		$ftypes{(S_IFLNK)} = "l";
		$ftypes{(S_IFSOCK)} = "s";
	}
	my @fsperms = ('----', '---t', '--s-', '--st', '-s--', '-s-t', '-ss-', '-sst');	
	
	my $permissions = sprintf "%04o", S_IMODE($mode);
	my @permissions = split(//o, sprintf("%04o", S_IMODE($mode)));	
	my @spermissions = split(//o, $fsperms[$permissions[0]]);	
	my $pstr = $ftypes{S_IFMT($mode)};
	my $ps;
	for (my $i=1;$i<=3;$i++)
	{
		$ps = $permvec[$permissions[$i]];		#r-x
		if ($spermissions[$i] =~ /\w/o)
		{
			my $loc = substr($ps,2,2);
			if ($loc =~ /\w/o)
			{
				$loc = $spermissions[$i];
			}
			else
			{
				$loc = uc($spermissions[$i]);
			}				
			$ps =~ s/^(..).$/$1$loc/;			
		}
		$pstr .= $ps;
	}		
	return $pstr;
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
		$self->{xftp_lastmsg} = "method Net::SFTP::Foreign::$method(".join(',',@_).") returned $@";
		return undef;
	}
	return $res;
}

1
