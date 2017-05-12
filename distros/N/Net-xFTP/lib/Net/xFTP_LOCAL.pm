package Net::xFTP::LOCAL;

#THIS "PLACEHOLDER" MODULE IMPLEMENTS THE Net::*FTP OBJECT AND FUNCTIONS ON THE 
#"LOCAL" FILESYSTEM AS "Net::LOCAL".

my @permvec = ('---','--x','-w-','-wx','r--','r-x','rw-','rwx');

sub new_local
{
	my $subclass = shift;
	my $pkg = shift;
	my $host = shift;
	my %args = @_;
	my %xftp_args;
	my $xftp = bless { }, $subclass;

	$@ = '';
	$xftp->{cwd} = Cwd::cwd();  #JWT:NOTE 20150123: DOES NOT RETURN A TRAILING "/" UNLESS "/"!
	$xftp->{xftp} = 1;
	return $xftp;
}

{
	no warnings 'redefine';
	sub cwd  #SET THE "CURRENT" DIRECTORY.
	{
		my $self = shift;
		my $cwd = shift || '/';
		$cwd = Cwd::cwd() . '/' . $cwd  unless ($cwd =~ m#^(?:[a-zA-Z]\:|\/)#o);   #JWT:ADDED 20150123 TO HANDLE CASE WHERE USER SPECIFIES A RELATIVE PATH:
		$cwd =~ s#\/\/#\/#o;
		unless ($cwd =~ m#^(?:[A-Za-z]\:)?\/$#) {  #JWT:ADDED 20150123 TO ENSURE NO TRAILING SLASH (UNLESS "/" OR "C:/")
			chop $cwd  if ($cwd =~ m#\/$#);
		}
		my $ok;
		$self->{cwd} = $cwd;
		$ok = 1;
		return $ok;
	}

	sub copy
	{
		my $self = shift;

		return undef  unless (@_ >= 2);
		my @args = @_;
		for (my $i=0;$i<=1;$i++)
		{
			$args[$i] = $self->{cwd} . '/' . $args[$i]  unless ($args[$i] =~ m#^(?:[a-zA-Z]\:|\/)#o);
			$args[$i] =~ s#\/\/#\/#o;

		}
		if ($self->isadir($args[1]))
		{
			my $filename = $1  if ($args[0] =~ m#([^\/]+)$#o);
			$args[1] .= '/'  unless ($args[1] =~ m#[\:\/]$#o);
			$args[1] .= $filename;
		}

		my $ok;
		$ok = File::Copy::copy($args[0], $args[1]);
		unless ($ok)
		{
			$self->{xftp_lastmsg} = $! || 'xFTP:Copy() failed - Local copy failed for unknown reason!';
		}
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
	my $realpath = $path || $self->{cwd} || Cwd::cwd();
	if ($realpath =~ /^\./o)
	{
		my $rp = $realpath;
		$realpath = $self->{cwd} || Cwd::cwd();
		chop $realpath  if ($realpath =~ m#[^\:]\/$#o);
		$realpath =~ s#\/[^\/]+$#\/#o  if ($rp eq '..');
	}
	unless ($realpath =~ m#^(?:[a-zA-Z]\:|\/)#o) {
		$realpath = $self->{cwd} . (($self->{cwd} =~ m#[\:\/]$#) ? '' : '/') . $realpath;
	}
	if ($self->{cwd} =~ m#^[a-zA-Z]\:# && $realpath !~ /\:/) {
		$realpath = $self->{cwd} . (($self->{cwd} =~ m#\/$# || $realpath =~ m#^\/#) ? '' : '/') . $realpath;
		$realpath =~ s#\/\/#\/#;
	}
	my $t;
	@dirlist = ();
	if (opendir D, $realpath)
	{
		while ($t = readdir(D))
		{
			next  if ($t =~ /^total \d/o);
			next  if ($t eq '..' && $path eq '/');
			next  if (!$showall && $t =~ /^\.[^\.]/o);
			push (@dirlist, $t);
		}
		closedir D;
	}
	else
	{
		$self->{xftp_lastmsg} = $! || 'xFTP:ls() failed - Local ls failed for unknown reason!';
		return;
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
	my $realpath = $path || $self->{cwd} || Cwd::cwd();
	if ($realpath =~ /^\./o)
	{
		my $rp = $realpath;
		$realpath = $self->{cwd} || Cwd::cwd();
		chop $realpath  if ($realpath =~ m#[^\:]\/$#o);
		$realpath =~ s#\/[^\/]+$#\/#o  if ($rp eq '..');
	}
	unless ($realpath =~ m#^(?:[a-zA-Z]\:|\/)#o) {
		$realpath = $self->{cwd} . (($self->{cwd} =~ m#[\:\/]$#) ? '' : '/') . $realpath;
	}
	if ($self->{cwd} =~ m#^[a-zA-Z]\:# && $realpath !~ /\:/) {
		$realpath = $self->{cwd} . (($self->{cwd} =~ m#\/$# || $realpath =~ m#^\/#) ? '' : '/') . $realpath;
		$realpath =~ s#\/\/#\/#;
	}
	my $t;
	if ($self->{bummer})
	{
		if (opendir D, $realpath)
		{
			$realpath .= '/'  unless ($realpath =~ m#[\:\/]$#o);
			my (@sb, @tm, $permval, @permdigits, $permstr);
			while ($t = readdir(D))
			{
				next  if ($t =~ /^total \d/o);
				next  if ($t eq '..' && $path eq '/');
				next  if (!$showall && $t =~ /^\.[^\.]/o);
				@sb = stat("$realpath$t");
				@tm = localtime($sb[9]);
				$permval = sprintf('%04o', $sb[2]&07777);
				@permdigits = split(//, $permval);

				$permstr = (-d "$realpath$t") ? 'd' : '-';
				$_ = $permvec[$permdigits[1]];
				if ($permdigits[0] >= 4)
				{
					s/\-/S/o;
					s/x/s/o;
				}
				$permstr .= $_;
				$_ = $permvec[$permdigits[2]];
				if ($permvec[$permdigits[0]] =~ /w/o)
				{
					s/\-/S/o;
					s/x/s/o;
				}
				$permstr .= $_;
				$_ = $permvec[$permdigits[3]];
				if ($permvec[$permdigits[0]] =~ /x/o)
				{
					s/\-/S/o;
					s/x/s/o;
				}
				$permstr .= $_;

				push (@dirlist, sprintf "%s\x02%10s %2d %8s %8s %10d %4d-%2.2d-%2.2d %2.2d:%2.2d %s\n", 
						$t, $permstr, $sb[3], $sb[4], $sb[5], $sb[7], $tm[5]+1900, $tm[4]+1, $tm[3], $tm[2], $tm[1], $t);
			}
			@dirlist = sort(@dirlist);
			for (my $i=0;$i<=$#dirlist;$i++)
			{
				$dirlist[$i] =~ s/^[^\x02]*\x02//so;
			}
		}
	}
	else
	{
		my @d = $showall ? `ls -la "$realpath"` : `ls -l "$realpath"`;
		if (@d)
		{
			shift @d  if ($d[0] =~ /^total \d/o);   #REMOVE "TOTAL" LINE.
			foreach my $t (@d)
			{
				chomp $t;
				next  if ($t =~ /\d \.\.$/o && $path eq '/');
				next  if (!$showall && $t =~ /\d \.[^\.]\S*$/o);
				push (@dirlist, $t);
			}
		
		}
		elsif ($@)
		{
			$self->{xftp_lastmsg} = $@;
			return;
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
#	my $cwd;
#	$self->{cwd} ||= Cwd::cwd() || $ENV{PWD};

	return $self->{cwd};
}

sub get    #(Remote, => Local)
{
	my $self = shift;

	return undef  unless (@_ >= 1);
	my @args = @_;
	$args[0] = $self->{cwd} . '/' . $args[0]  unless ($args[0] =~ m#^(?:[a-zA-Z]\:|\/)#o);
	$args[0] =~ s#\/\/#\/#o;

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
	if (ref(\$args[1]) =~ /GLOB/io)
	{
		my $buff;
		my $unsubscriptedFH = $args[1];

		flush $unsubscriptedFH;  #DOESN'T SEEM TO HELP - NEEDED IN CALLING ROUTINE TOO?!?!?!

		local *TF;
		unless (open(TF, $args[0]))
		{
			$self->{xftp_lastmsg} = "Could not open remote file ($args[0]) ("
					. ($! ? $! : 'unknown reasons') .')!';
		}
		while ($buff = <TF>)
		{
			print $unsubscriptedFH $buff;
		}
		close TF;
		flush $unsubscriptedFH;
		return 1;
	}
	else
	{
		$ok = File::Copy::copy($args[0], $args[1]);
	}
	unless ($ok)
	{
		$self->{xftp_lastmsg} = $! || 'xFTP:get() failed - Local copy failed for unknown reason!';
	}
	return $ok ? 1 : undef;
}

sub put    #(LOCAL => REMOTE) SFTP returns OK=1 on SUCCESS.
{
	my $self = shift;

	return undef  unless (@_ >= 1);
	my @args = @_;
	unless (@args >= 2 || ref(\$args[0]) =~ /GLOB/io)
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
	$args[1] = $self->{cwd} . '/' . $args[1]  unless ($args[1] =~ m#^(?:[a-zA-Z]\:|\/)#o);
	$args[1] =~ s#\/\/#\/#o;

	if (ref(\$args[0]) =~ /GLOB/io)
	{
		my $buff;
		my $unsubscriptedFH = $args[0];

		local *TF;
		unless (open(TF, ">$args[1]"))
		{
			$self->{xftp_lastmsg} = "Could not open remote file ($args[1]) ("
					. ($! ? $! : 'unknown reasons') .')!';
		}
		my $t;
		while ($buff = <$unsubscriptedFH>)
		{
			$t .= $buff;
		}
		print TF $t;
		close TF;
		return 1;
	}
	else
	{
		$ok = File::Copy::copy($args[0], $args[1]);
	}
	unless ($ok)
	{
		$self->{xftp_lastmsg} = $! || 'xFTP:put() failed - Local copy failed for unknown reason!';
	}
	return $ok ? 1 : undef;
}

sub delete       #RETURNED OK=2 WHEN LAST FAILED.
{
	my $self = shift;
	my $path = shift;

	my $ok;
	$path = $self->{cwd} . '/' . $path  unless ($path =~ m#^(?:[a-zA-Z]\:|\/)#o);
	$path =~ s#\/\/#\/#o;

	return  unless ($path);
	#!!!!return ($_ == 1) ? 1 : undef;
	return unlink($path) ? 1 : undef;
}

sub rename
{
	my $self = shift;
	return undef  unless (@_ == 2);

	my ($oldfile, $newfile) = @_;

	my $ok;
	$oldfile = $self->{cwd} . '/' . $oldfile  unless ($oldfile =~ m#^(?:[a-zA-Z]\:|\/)#o);
	$oldfile =~ s#\/\/#\/#o;
	$newfile = $self->{cwd} . '/' . $newfile  unless ($newfile =~ m#^(?:[a-zA-Z]\:|\/)#o);
	$newfile =~ s#\/\/#\/#o;

	$ok = rename($oldfile, $newfile);
	unless ($ok)
	{
		$self->{xftp_lastmsg} = $! || 'xFTP:rename() failed - Local rename failed for unknown reason!';
	}
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
	my $orgPath = $path;
	my $didRecursion = 0;
	my $errored = 0;
	$path = $self->{cwd} . '/' . $path  unless ($path =~ m#^(?:[a-zA-Z]\:|\/)#o);
	$path =~ s#\/\/#\/#o;
	while ($path)
	{
		$ok = mkdir $path;
		last  if ($ok);
		if ($tryRecursion)
		{
			push (@pathStack, $path);
			$path =~ s#[^\/\\]+$##o;
			$path =~ s#[\/\\]$##o;
			$didRecursion = 1;
		}
		else
		{
			$self->{xftp_lastmsg} = "mkdir:mkdir($path):failed($!)!";
				$errored = 1;
			last;
		}
	}
	if ($didRecursion)
	{
		while (@pathStack)
		{
			$path = pop @pathStack;
			next  if (mkdir $path);
			$self->{xftp_lastmsg} = "mkdir:mkdir($path):Could not recursively create subdirectory($!)!";
			return undef;

		}
		return 1;
	}
	return $errored ? undef : 1;
}

sub rmdir
{
	my $self = shift;
	my $path = shift;
	$path =~ s#[\/\\]$##o  unless ($path eq '/');

	my $ok;
	$path = $self->{cwd} . '/' . $path  unless ($path =~ m#^(?:[a-zA-Z]\:|\/)#o);
	$path =~ s#\/\/#\/#o;

	return undef  unless ($path);
	$ok  = rmdir $path;
	unless ($ok)
	{
		$self->{xftp_lastmsg} = $! || 'xFTP:rmdir() failed - Local rename failed for unknown reason!';
	}
	return $ok ? 1 : undef;
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
	$path = $self->{cwd} . '/' . $path  unless ($path =~ m#^(?:[a-zA-Z]\:|\/)#o);
	$path =~ s#\/\/#\/#o;

	eval { (undef, undef, undef, undef, undef, undef, undef, undef, undef,
			$ok) = stat($path) };
	return $@ ? undef : $ok;
}

sub size
{
	my $self = shift;
	my $path = shift;

	my $ok;
	$path = $self->{cwd} . '/' . $path  unless ($path =~ m#^(?:[a-zA-Z]\:|\/)#o);
	$path =~ s#\/\/#\/#o;

	eval { (undef, undef, undef, undef, undef, undef, undef, $ok) = stat($path) };
	return $@ ? undef : $ok;
}

sub isadir
{
	my $self = shift;
	my $path = shift;

	my $ok;
	$path = $self->{cwd} . '/' . $path  unless ($path =~ m#^(?:[a-zA-Z]\:|\/)#o);
	$path =~ s#\/\/#\/#o;
	return (-d $path) ? 1 : 0;
}

sub chmod
{
	my $self = shift;
	my $permissions = shift;
	my $path = shift;

	my ($ok, $attrs);
	$path = $self->{cwd} . '/' . $path  unless ($path =~ m#^(?:[a-zA-Z]\:|\/)#o);
	$path =~ s#\/\/#\/#o;
	eval "\$permissions = 0$permissions";
	if ($@)
	{
		$self->{xftp_lastmsg} = "Invalid permissions (0-777) - $@";
		return undef;
	}
	$ok = chmod $permissions, $path;
	unless ($ok)
	{
		$self->{xftp_lastmsg} = $! || 'xFTP:chmod() failed - Local chmod failed for unknown reason!';
	}
	return $ok ? 1 : undef;
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
		$self->{xftp_lastmsg} = "method Net::Local::$method(".join(',',@_).") returned $@";
		return undef;
	}
	return $res;
}

1
