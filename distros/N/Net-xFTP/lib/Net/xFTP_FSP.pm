package Net::xFTP::FSP;

sub new_fsp
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

	$xftp->{xftp} = Net::FSP->new($host, \%args);
	$ENV{HOME} = $saveEnvHome || '';
	if ($xftp->{xftp})
	{
		my $cwd = $xftp->{xftp}->current_dir();
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
		$fullwd = $self->{xftp}->change_dir($cwd);
		$ok = $self->{xftp}->current_dir();
		if ($ok eq $cwd)   # fullwd is set to the PREVIOUS directory!
		{
			$self->{cwd} = $cwd;
			$ok = 1;
		}
		return undef;
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
		my ($buff);
		my $fromHandle = $self->{xftp}->open_file($args[0], '<');
		unless (defined($fromHandle) && $fromHandle)
		{
			$self->{xftp_lastmsg} = "Copy failed (". ($!||'open1 failed - Unknown reason')
					. ')!';
			return undef;
		}
		my $toHandle;
		$toHandle = $self->{xftp}->open_file($args[1], '>');
		unless (defined($toHandle) && $toHandle)
		{
			$self->{xftp_lastmsg} = "Copy failed (". ($!||'do_open2 failed - Unknown reason')
					. ')!';
			return undef;
		}
		my $offset = 0;
		my $err;
		while ($buff = <$fromHandle>)
		{
			print $toHandle $buff;
				$offset += length($buff);
		}
		close $toHandle;
		close $fromHandle;
		$ok = 1;
		return $ok ? 1 : undef;
	}

	sub move
	{
		my $self = shift;

		return undef  unless (@_ >= 2);
#		return ($self->copy(@_) && $self->delete($_[0])) ? 1 : undef;
		$self->{xftp}->move_file($_[0], $_[1]);
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
	$self->{xftp}->say_bye();
	$self->{xftp} = undef;
	delete($self->{xftp});

	return;
}

sub ls
{
	my $self = shift;
	my $path = shift || '';
	my $showall = shift || 0;
	my @dirHash = $self->{xftp}->list_dir($path|'.');
	return  unless (defined $dirHash[0]);     #ADDED 20071024 FOR CONSISTENCY.
	my $t;
	my @dirlist = ();
	for (my $i=0;$i<=$#dirHash;$i++)
	{
		$t = $dirHash[$i]->{name};
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
#	$realpath = $self->{cwd} . '/' . $realpath  unless ($realpath =~ m#^(?:[a-zA-Z]\:|\/)#o);
	my @dirHash = $self->{xftp}->list_dir($path||'.');
	return  unless (defined $dirHash[0]);     #ADDED 20071024 FOR CONSISTENCY.
	my ($t, @tm, $tp);
	@dirlist = ();
	foreach my $i (@dirHash)
	{
		#$t = $dirHash[$i]->{longname};
		$t = $i->short_name();
		next  if ($t =~ /\d \.\.$/o && $path eq '/');
		next  if (!$showall && $t =~ /\d \.[^\.]\S*$/o);
		$tp = substr($i->type(),0,1);
		$tp = '-'  if ($tp =~ /f/io);
		@tm = localtime($i->time());
		$_ = sprintf "%1s----------unknown- -unknown- %8s %4d-%2.2d-%2.2d %2.2d:%2.2d %s\n", 
				$tp, $i->{size}, $tm[5]+1900, $tm[4]+1, $tm[3], $tm[2], $tm[1], $t;
		push (@dirlist, $_);
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
	eval { $self->{xftp}->download_file(@args); };
	if ($@)
	{
		$self->{xftp_lastmsg} = $@;
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
	eval { $self->{xftp}->upload_file($args[1], $args[0]); };  #THEY REVERSED THE ARGS ON THIS (READS FROM 2ND ARG - ARGS[0])?!?!?!
	if ($@)
	{
		$self->{xftp_lastmsg} = $@;
		return undef;
	}
	return 1;
}

sub delete       #RETURNED OK=2 WHEN LAST FAILED.
{
	my $self = shift;
	my $path = shift;

	eval { $self->{xftp}->remove_file($path) };
	if ($@)
	{
		$self->{xftp_lastmsg} = $@;
		return undef;
	}
	return 1;
}

sub rename
{
	my $self = shift;
	return undef  unless (@_ == 2);

	my ($oldfile, $newfile) = @_;

#	$oldfile = $self->{cwd} . '/' . $oldfile  unless ($oldfile =~ m#^(?:[a-zA-Z]\:|\/)#o);
#	$newfile = $self->{cwd} . '/' . $newfile  unless ($newfile =~ m#^(?:[a-zA-Z]\:|\/)#o);
	eval { $self->{xftp}->move_file($oldfile, $newfile) };
	if ($@)
	{
		$self->{xftp_lastmsg} = $@;
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
			eval { $self->{xftp}->make_dir($path) };
			if ($@)
			{
				$self->{xftp_lastmsg} = $@;
				return undef;
			}
			next;
		}
	}
	eval { $self->{xftp}->make_dir($orgPath) };
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

	$path = $self->{cwd} . '/' . $path  unless ($path =~ m#^(?:[a-zA-Z]\:|\/)#o);
	eval { $self->{xftp}->remove_dir($path) };
	if ($@)
	{
		$self->{xftp_lastmsg} = $@;
		return undef;
	}
	return 1;
}

sub message
{
	my $self = shift;

	chomp $self->{xftp_lastmsg};
	return $self->{xftp_lastmsg};
}

sub mdtm
{
	my $self = shift;
	my $path = shift;

	my $ok;
#	$path = $self->{cwd} . '/' . $path  unless ($path =~ m#^(?:[a-zA-Z]\:|\/)#o);
	eval { $ok = $self->{xftp}->stat_file($path) };
	if ($@ || !defined($ok))
	{
		$self->{xftp_lastmsg} = $@ || "xFTP: size() failed for unknown reason!";
		return undef;
	}
	return $ok->time();
}

sub size
{
	my $self = shift;
	my $path = shift;

	my $ok;
#	$path = $self->{cwd} . '/' . $path  unless ($path =~ m#^(?:[a-zA-Z]\:|\/)#o);
	eval { $ok = $self->{xftp}->stat_file($path) };
	if ($@ || !defined($ok))
	{
		$self->{xftp_lastmsg} = $@ || "xFTP: size() failed for unknown reason!";
		return undef;
	}
	return $ok->size();
}

sub isadir
{
	my $self = shift;
	my $path = shift;

	my $ok;
	eval { $ok = $self->{xftp}->stat_file($path) };
	if ($@ || !defined($ok))
	{
		$self->{xftp_lastmsg} = $@ || "xFTP: isadir() failed for unknown reason!";
		return undef;
	}
	return ($ok->type() =~ /d/io) ? 1 : 0;
}

sub chmod
{
	my $self = shift;
	my $permissions = shift;
	my $path = shift;

	$self->{xftp_lastmsg} = 'Net::FSP:  chmod function not supported!';
	return undef;
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
		$self->{xftp_lastmsg} = "method Net::FSP::$method(".join(',',@_).") returned $@";
		return undef;
	}
	return $res;
}

1
