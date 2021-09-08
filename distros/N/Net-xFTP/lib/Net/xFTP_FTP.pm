package Net::xFTP::FTP;

sub new_ftp
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
	}	
	$xftp->{xftp} = Net::FTP->new($host, %args);
	unless (defined $xftp->{xftp})
	{
		$xftp->{xftp_lastmsg} = $@;
		return undef;
	}
	if (defined $args{user})
	{
		$args{user} ||= 'anonymous';
		$args{password} ||= 'anonymous@'  if ($args{user} eq 'anonymous');
		my @loginargs = ($args{user});
		push (@loginargs, $args{password})  if (defined $args{password});
		push (@loginargs, $args{account})  if (defined $args{account});
		if ($xftp->{xftp}->login(@loginargs))
		{
			my $cwd = $xftp->{xftp}->pwd();
			$xftp->{cwd} = $cwd  if ($cwd);
			$xftp->{protocol} = 'Net::FTP';
			return $xftp;
		}
	}
	else
	{
		return $xftp  if ($xftp->{xftp}->login());
	}
	$@ ||= 'Invalid Password?';
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
		$ok = $self->{xftp}->cwd($cwd);
		$self->{cwd} = $cwd  if ($ok);
		return $ok ? 1 : undef;
	}

	sub copy
	{
		my $self = shift;

		return undef  unless (@_ >= 2);
		my @args = @_;
		if ($self->isadir($args[1]))
		{
			my $filename = $1  if ($args[0] =~ m#([^\/]+)$#o);
			$args[1] .= '/'  unless ($args[1] =~ m#\/$#o);
			$args[1] .= $filename;
		}

		my $ok;
		my ($tmp, $t);
		my $fromHandle;
		eval { $fromHandle = $self->{xftp}->retr($args[0]) };
		unless ($fromHandle)
		{
			$self->{xftp_lastmsg} = "Copy failed (". ($@||'retr failed - Unknown reason')
					. ')!';
			return undef;
		}
		while ($fromHandle->read($tmp, $self->{BlockSize}))
		{
			$t .= $tmp;
		}
		$fromHandle->close();
		my $toHandle;
		eval { $toHandle = $self->{xftp}->stor($args[1]) };
		unless ($toHandle)
		{
			$self->{xftp_lastmsg} = "Copy failed (". ($@||'stor failed - Unknown reason')
					. ')!';
			return undef;
		}
		eval { $toHandle->write($t, length($t)) };
		if ($@)
		{
			$self->{xftp_lastmsg} = "Copy failed (". ($@||'write failed - Unknown reason')
					. ')!';
			return undef;
		}
		$toHandle->close();
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

	$self->{xftp}->ascii();
	return undef;
}

sub binary
{
	my $self = shift;

	$self->{xftp}->binary();
	return undef;
}

sub quit
{
	my $self = shift;
	$self->{xftp}->quit();
	return;
}

sub ls
{
	my $self = shift;
	my $path = shift || '';
	my $showall = shift || 0;
	my @dirlist;
	@dirlist = $self->{xftp}->ls($path||'.');
	return  unless (defined $dirlist[0]);     #ADDED 20070613 TO PREVENT WARNING.
	shift (@dirlist)  if ($dirlist[0] =~ /^total \d/o);  #REMOVE TOTAL LINE!
	my $i = 0;
	while ($i<=$#dirlist)
	{
		#$dirlist[$i] =~ s#\/\/#\/#;
		$dirlist[$i] = $1  if ($dirlist[$i] =~ m#([^\/\\]+)$#o);
		$dirlist[$i] = $1  if ($dirlist[$i] =~ /\/(\.\.?)$/o);
		if ($dirlist[$i] eq '..' && $path eq '/')
		{
			splice(@dirlist, $i, 1);
		}
		elsif (!$showall && $dirlist[$i] =~ /^\.[^\.]/o)
		{
			splice(@dirlist, $i, 1);
		}
		else
		{
			++$i;
		}
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
	@dirlist = $self->{xftp}->dir($path||'.');
	return  unless (defined $dirlist[0]);     #ADDED 20070613 TO PREVENT WARNING.
	shift (@dirlist)  if ($dirlist[0] =~ /^total \d/o);  #REMOVE TOTAL LINE!
	my $i = 0;
	while ($i<=$#dirlist)
	{
		#$dirlist[$i] =~ s#\/\/#\/#;
		$dirlist[$i] = $1  if ($dirlist[$i] =~ m#([^\/\\]+)$#o);
		$dirlist[$i] = $1  if ($dirlist[$i] =~ /\/(\.\.?)$/o);
		if ($dirlist[$i] =~ /\d \.\.$/o && $path eq '/')
		{
			splice(@dirlist, $i, 1);
		}
		elsif (!$showall && $dirlist[$i] =~ /\d \.[^\.]\S*$/o)
		{
			splice(@dirlist, $i, 1);
		}
		else
		{
			++$i;
		}
	}

	##ON SOME SERVERS, THESE DON'T GET ADDED ON, SO ADD THEM HERE!
	#unshift (@dirlist, '..')  unless ($path eq '/' || $dirlist[1] =~ /\d \.\.$/);
	#unshift (@dirlist, '.')  unless ($dirlist[0] =~ /\d \.$/);

	return wantarray ? @dirlist : \@dirlist;
}

sub pwd  #GET AND RETURN THE "CURRENT" DIRECTORY.
{
	my $self = shift;

#	my $cwd = $self->{xftp}->pwd();
#	$self->{cwd} = $cwd  if ($cwd);

	return $self->{cwd};
}

sub get    #(Remote, => Local)
{
	my $self = shift;

	return undef  unless (@_ >= 1);
	my @args = @_;
	unless (@args >= 2)
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
	eval { $ok = $self->{xftp}->get(@args) };
	$self->{xftp_lastmsg} = $@  if ($@);
	return $ok ? 1 : undef;
}

sub put    #(LOCAL => REMOTE) SFTP returns OK=1 on SUCCESS.
{
	my $self = shift;

	return undef  unless (@_ >= 1);
	my @args = @_;
	unless (@args >= 2)
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
	eval { $ok = $self->{xftp}->put(@args) };
#print STDERR "-ftp.put(".join('|',@args)."= ok=$ok= at=$at=\n";
	$self->{xftp_lastmsg} = $@  if ($@);
	return $ok ? 1 : undef;
}

sub delete       #RETURNED OK=2 WHEN LAST FAILED.
{
	my $self = shift;
	my $path = shift;

	my $ok;
	eval { $ok = $self->{xftp}->delete($path) };
	$self->{xftp_lastmsg} = $@  if ($@);
	return $ok ? 1 : undef;
}

sub rename
{
	my $self = shift;
	return undef  unless (@_ == 2);

	my ($oldfile, $newfile) = @_;

	my $ok;
	eval { $ok = $self->{xftp}->rename($oldfile, $newfile) };
	$self->{xftp_lastmsg} = $@  if ($@);
	return $ok ? 1 : undef;
}

sub mkdir
{
	my $self = shift;
	my $path = shift;
	my $tryRecursion = shift||0;
	$path =~ s#[\/\\]$##o  unless ($path eq '/');

	my @pathStack;
	my $ok = '';
	eval { $ok = $self->{xftp}->mkdir($path, $tryRecursion) };
	$self->{xftp_lastmsg} = $@  if ($@);
	return $ok ? 1 : undef;
}

sub rmdir
{
	my $self = shift;
	my $path = shift;
	$path =~ s#[\/\\]$##o  unless ($path eq '/');

	my $ok;
	eval { $ok = $self->{xftp}->rmdir($path) };
	$self->{xftp_lastmsg} = $@  if ($@);
	return $ok ? 1 : undef;
}

sub message
{
	my $self = shift;

	chomp $self->{xftp_lastmsg};
	return $self->{xftp}->message;
}

sub mdtm
{
	my $self = shift;
	my $path = shift;

	my $ok;
	return $self->{xftp}->mdtm($path);
}

sub size
{
	my $self = shift;
	my $path = shift;

	my $ok;
	return $self->{xftp}->size($path);
}

sub isadir
{
	my $self = shift;
	my $path = shift;

	my $ok;
	my $curdir = $self->{xftp}->pwd();
	eval { $ok = $self->{xftp}->cwd($path); };
	if ($ok)
	{
		$self->{xftp}->cwd($curdir);
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
	unless ($self->{xftp}->supported('SITE CHMOD'))
	{
		$@ = 'Server does not support chmod!';
		$self->{xftp_lastmsg} = $@;
#		$self->{xftp}->set_status(1, $@);
	}
	$ok = $self->{xftp}->site('CHMOD', $permissions, $path);
	return ($ok == 2) ? 1 : undef;
}

1
