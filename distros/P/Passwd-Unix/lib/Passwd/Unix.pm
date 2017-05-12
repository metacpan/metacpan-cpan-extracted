package Passwd::Unix;

use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);

use warnings;
use strict;
use Carp;
use Config;
use File::Spec;
use File::Path;
use File::Copy;
use File::Basename qw(dirname basename);
use IO::Compress::Bzip2 qw($Bzip2Error);
use Struct::Compare;
use Crypt::PasswdMD5 qw(unix_md5_crypt);
require Exporter;
#======================================================================
$VERSION = '0.71';
@ISA = qw(Exporter);
@EXPORT_OK = qw(check_sanity reset encpass passwd_file shadow_file 
				group_file backup debug warnings del del_user uid gid 
				gecos home shell passwd rename maxgid maxuid exists_user 
				exists_group user users users_from_shadow del_group 
				group groups groups_from_gshadow default_umask
				unused_uid unused_gid);
#======================================================================
use constant TRUE 	=> not undef;
use constant FALSE 	=> undef;
#======================================================================
use constant DAY		=> 86400;
use constant PASSWD 	=> '/etc/passwd';
use constant GROUP  	=> '/etc/group';
use constant SHADOW 	=> '/etc/shadow';
use constant GSHADOW  	=> '/etc/gshadow';
use constant BACKUP 	=> TRUE;
use constant DEBUG  	=> FALSE;
use constant WARNINGS 	=> FALSE;
use constant UMASK		=> 0022;
use constant PERM_PWD	=> 0644;
use constant PERM_GRP	=> 0644;
use constant PERM_SHD	=> 0400;
use constant PATH		=>  qr/^[\w\+_\040\#\(\)\{\}\[\]\/\-\^,\.:;&%@\\~]+\$?$/;
#======================================================================
my $_CHECK = {
	'rename' 	=> sub { return if not defined $_[0] or $_[0] !~ /^[A-Z0-9_\.-]+$/io; TRUE },
	'gid'		=> sub { return if not defined $_[0] or $_[0] !~ /^[0-9]+$/o; TRUE },
	'uid'		=> sub { return if not defined $_[0] or $_[0] !~ /^[0-9]+$/o; TRUE },
	'home'		=> sub { return if not defined $_[0] or $_[0] !~ PATH; TRUE },
	'shell'		=> sub { return if not defined $_[0] or $_[0] !~ PATH; TRUE },
	'gecos'		=> sub { return if not defined $_[0] or $_[0] !~ /^[^:]+$/o; TRUE },
	'passwd' 	=> sub { return if not defined $_[0]; TRUE},
};
#======================================================================
my $Self = __PACKAGE__->new();
#======================================================================
sub new {
	my ($class, %params) = @_;
	
	my $self = bless {
				passwd 		=> (defined $params{passwd} 	? $params{passwd} 	: PASSWD	),
				group 		=> (defined $params{group} 		? $params{group} 	: GROUP		),
				shadow 		=> (defined $params{shadow} 	? $params{shadow} 	: SHADOW	),
				gshadow 	=> (defined $params{gshadow} 	? $params{gshadow} 	: GSHADOW	),
				backup 		=> (defined $params{backup} 	? $params{backup} 	: BACKUP	),
				debug 		=> (defined $params{debug} 		? $params{debug} 	: DEBUG		),
				warnings	=> (defined $params{warnings} 	? $params{warnings} : WARNINGS	),
				'umask'		=> (defined $params{'umask'} 	? $params{'umask'}	: UMASK		),
			}, $class;
			
	$self->check_sanity(TRUE) if (caller())[0] ne __PACKAGE__;
			
	return $self;
}
#======================================================================
sub error {
	my $self = scalar @_ && ref $_[0] eq __PACKAGE__ ? shift : $Self;
	
	$self->{ error } = shift if defined $_[0];

	return $self->{ error } || q//;
}
#======================================================================
sub check_sanity {
	my $self = scalar @_ && ref $_[0] eq __PACKAGE__ ? shift : $Self;
	my $quiet = shift;

	for($self->shadow_file, $self->passwd_file, $self->group_file){
		next if -f $_;
		croak('File not found: ' . $_);
	}

	unless($quiet){
		carp(q/Insecure permissions to group file!/)	and sleep(1) if ((stat($self->group_file)  )[2] & 07777) != PERM_GRP;
		carp(q/Insecure permissions to passwd file!/)	and sleep(1) if ((stat($self->passwd_file) )[2] & 07777) != PERM_PWD;
		carp(q/Insecure permissions to shadow file!/)	and sleep(1) if ((stat($self->shadow_file) )[2] & 07777) != PERM_SHD;
		carp(q/Insecure permissions to gshadow file!/)	and sleep(1) if ((stat($self->gshadow_file))[2] & 07777) != PERM_GRP;
	}

	if($( !~ /^0/o){
		carp(q/Running as "/ . getlogin() . qq/", which has currently no permissions to write to system files. Some operations (i.e. modify) may fail!/) unless $quiet;
		return;
	}

	my %filenames = ( shadow => $self->shadow_file, passwd => $self->passwd_file, group => $self->group_file, gshadow => $self->gshadow_file );
	foreach my $file0 (keys %filenames){
		foreach my $file1 (keys %filenames){
			next if $file0 eq $file1;
			croak(q/Files "/ . $file0 . q/" and "/ . $file1 . q/" cannot be the same!/) if $filenames{$file0} eq $filenames{$file1};
		}
	}

	unless(compare([$self->users()], [$self->users_from_shadow()])){
		carp(qq/\nYour ENVIRONMENT IS INSANE! Users in files "/.$self->passwd_file().q/" and "/.$self->shadow_file().qq/ are diffrent!!!\nI'll continue, but it is YOUR RISK! You'll probably go into BIG troubles!\n\n/);
		warn "\a\n";
		sleep 5;
	}

	return;
}
#======================================================================
sub reset {
	my $self = scalar @_ && ref $_[0] eq __PACKAGE__ ? shift : $Self;
	$self->{passwd}		= PASSWD;
	$self->{group}		= GROUP;
	$self->{shadow}		= SHADOW;
	$self->{gshadow}	= GSHADOW;
	$self->{'umask'}	= UMASK;
	return TRUE;
}
#======================================================================
sub encpass {
	my $self = scalar @_ && ref $_[0] eq __PACKAGE__ ? shift : $Self;
	my ($val) = @_;
	return unless defined $val;
	return unix_md5_crypt($val);
}
#======================================================================
sub _do_backup {
	my $self = scalar @_ && ref $_[0] eq __PACKAGE__ ? shift : $Self;
	my ($sec,$min,$hour,$mday,$mon,$year) = localtime(time);

	my $umask = umask $self->{'umask'};

	$self->error(q//);

	my $dir = File::Spec->catfile($self->passwd_file.'.bak', ($year+1900).'.'.($mon+1).'.'.$mday.'-'.$hour.'.'.$min.'.'.$sec);
	mkpath $dir; chmod 0500, $dir;

	my $cpasswd		= File::Spec->catfile($dir, basename($self->passwd_file())  . q/.bz2/);
	my $cgroup		= File::Spec->catfile($dir, basename($self->group_file())   . q/.bz2/);
	my $cshadow		= File::Spec->catfile($dir, basename($self->shadow_file())  . q/.bz2/);
	my $cgshadow	= File::Spec->catfile($dir, basename($self->gshadow_file()) . q/.bz2/);

	# passwd
	my $compress = IO::Compress::Bzip2->new($cpasswd, AutoClose => 1, Append => 1, BlockSize100K => 9) or ($self->error($Bzip2Error) and umask $umask and return);
	open(my $fh, '<', $self->passwd_file) or (umask $umask and return);
	$compress->print($_) while <$fh>;
	$compress->close;
	chmod 0644, $cpasswd;
	
	# group
	$compress = IO::Compress::Bzip2->new($cgroup, AutoClose => 1, Append => 1, BlockSize100K => 9) or ($self->error($Bzip2Error) and umask $umask and return);
	open($fh, '<', $self->group_file) or (umask $umask and return);
	$compress->print($_) while <$fh>;
	$compress->close;
	chmod 0644, $cgroup;

	# shadow
	$compress = IO::Compress::Bzip2->new($cshadow, AutoClose => 1, Append => 1, BlockSize100K => 9) or ($self->error($Bzip2Error) and umask $umask and return);
	open($fh, '<', $self->shadow_file) or (umask $umask and return);
	$compress->print($_) while <$fh>;
	$compress->close;
	chmod 0400, $cshadow;

	# gshadow
	if(-f $self->gshadow_file){
		$compress = IO::Compress::Bzip2->new($cgshadow, AutoClose => 1, Append => 1, BlockSize100K => 9) or ($self->error($Bzip2Error) and umask $umask and return);
		open($fh, '<', $self->gshadow_file) or (umask $umask and return);
		$compress->print($_) while <$fh>;
		$compress->close;
		chmod 0400, $cgshadow;
	}

	umask $umask;

	return TRUE;
}
#======================================================================
sub passwd_file { 
	my $self = scalar @_ && ref $_[0] eq __PACKAGE__ ? shift : $Self;
	my ($val) = @_;
	return $self->{passwd} unless defined $val;
	$self->{passwd} = File::Spec->canonpath($val);
	return $self->{passwd};
}
#======================================================================
sub group_file { 
	my $self = scalar @_ && ref $_[0] eq __PACKAGE__ ? shift : $Self;
	my ($val) = @_;
	return $self->{group} unless defined $val;
	$self->{group} = File::Spec->canonpath($val);
	return $self->{group};
}
#======================================================================
sub shadow_file { 
	my $self = scalar @_ && ref $_[0] eq __PACKAGE__ ? shift : $Self;
	my ($val) = @_;
	return $self->{shadow} unless defined $val;
	$self->{shadow} = File::Spec->canonpath($val);
	return $self->{shadow};
}
#======================================================================
sub gshadow_file { 
	my $self = scalar @_ && ref $_[0] eq __PACKAGE__ ? shift : $Self;
	my ($val) = @_;
	return $self->{gshadow} unless defined $val;
	$self->{gshadow} = File::Spec->canonpath($val);
	return $self->{gshadow};
}
#======================================================================
sub backup {
	my $self = scalar @_ && ref $_[0] eq __PACKAGE__ ? shift : $Self;
	my ($val) = @_;
	return $self->{backup} unless defined $val;
	$self->{backup} = $val ? TRUE : FALSE;
	return $self->{backup};
}
#======================================================================
sub debug {
	my $self = scalar @_ && ref $_[0] eq __PACKAGE__ ? shift : $Self;
	my ($val) = @_;
	return $self->{debug} unless defined $val;
	$self->{debug} = $val ? TRUE : FALSE;
	return $self->{debug};
}
#======================================================================
sub warnings {
	my $self = scalar @_ && ref $_[0] eq __PACKAGE__ ? shift : $Self;
	my ($val) = @_;
	return $self->{warnings} unless defined $val;
	$self->{warnings} = $val ? TRUE : FALSE;
	return $self->{warnings};
}
#======================================================================
sub default_umask {
	my $self = scalar @_ && ref $_[0] eq __PACKAGE__ ? shift : $Self;
	my ($val) = @_;
	return $self->{'umask'} unless defined $val;
	$val = oct($val) if length($val) != 2;
	$self->{'umask'} = $val;
	return $self->{'umask'};
}
#======================================================================
*del_user = { };
*del_user = \&del;
sub del { 
#	This method will fail, if user doesn't have permissions to files.
#   Error will be in $self->error() and error();
#	return if $( !~ /^0/o;

	my $self = scalar @_ && ref $_[0] eq __PACKAGE__ ? shift : $Self;
	$self->error(q//);

	unless(scalar @_){
		my $error = $self->error(q|Method/function "del" cannot run without params!|);
		carp($error) if $self->warnings();
		return;
	}

	if( $self->backup() ){
		$self->_do_backup() or return;
	}
	
	my $regexp = '^'.join('$|^',@_).'$';
	$regexp = qr/$regexp/;
	
	# here unused gids will be saved
	my (@gids, @deleted, %_gids);
	
	my $umask = umask $self->{'umask'};

	# remove from passwd
	my $tmp = $self->passwd_file.'.tmp';
	open(my $fh, '<', $self->passwd_file()) or ($self->error($!) and umask $umask and return);
	open(my $ch, '>', $tmp) or ($self->error($!) and umask $umask and return);
	chmod PERM_PWD, $ch;
	while(my $line = <$fh>){
		my ($user, undef, undef, $gid) = split(/:/,$line, 5);
		if($user =~ $regexp){ 
			push @gids, $gid; 
			push @deleted, $user;
		}else{ 
			$_gids{$gid} = defined $_gids{$gid} ? $_gids{$gid} + 1 : 1;
			print $ch $line; 
		}
	}
	close($fh);close($ch);
	move($tmp, $self->passwd_file()) or ($self->error($!) and umask $umask and return);
	
	# remove from shadow
	$tmp = $self->shadow_file.'.tmp';
	open($fh, '<', $self->shadow_file()) or ($self->error($!) and umask $umask and return);
	open($ch, '>', $tmp) or ($self->error($!) and umask $umask and return);
	chmod PERM_SHD, $ch;
	while(my $line = <$fh>){
		next if (split(/:/,$line,2))[0] =~ $regexp;
		print $ch $line;
	}
	close($fh);close($ch);
	move($tmp, $self->shadow_file()) or ($self->error($!) and umask $umask and return);

	# remove from group
	my $gids = '^'.join('$|^',@gids).'$';
	$gids = qr/$gids/;
	$tmp = $self->group_file.'.tmp';
	open($fh, '<', $self->group_file()) or ($self->error($!) and umask $umask and return);
	open($ch, '>', $tmp) or ($self->error($!) and umask $umask and return);
	chmod PERM_GRP, $ch;
	while(my $line = <$fh>){
		chomp $line;
		my ($name, $passwd, $gid, $users) = split(/:/,$line,4);
		$users = join(q/,/, grep { !/$regexp/ } split(/\s*,\s*/, $users));
		print $ch join(q/:/, $name, $passwd, $gid, $users),"\n";
	}
	close($fh);close($ch);
	move($tmp, $self->group_file()) or ($self->error($!) and umask $umask and return);
	
	# remove from gshadow
	if(-f $self->gshadow_file){
		$tmp = $self->gshadow_file.'.tmp';
		open($fh, '<', $self->gshadow_file()) or ($self->error($!) and umask $umask and return);
		open($ch, '>', $tmp) or ($self->error($!) and umask $umask and return);
		chmod PERM_SHD, $ch;
		while(my $line = <$fh>){
			chomp $line;
			my ($name, $passwd, $gid, $users) = split(/:/,$line,4);
			$users = join(q/,/, grep { !/$regexp/ } split(/\s*,\s*/, $users));
			print $ch join(q/:/, $name, $passwd, $gid, $users),"\n";
		}
		close($fh);close($ch);
		move($tmp, $self->gshadow_file()) or ($self->error($!) and umask $umask and return);
	}

	umask $umask;

	return @deleted if wantarray;
	return scalar @deleted;
}
#======================================================================
sub _set {
#	This method will fail, if user doesn't have permissions to files.
#   Error will be in $self->error() and error();
#	return if $( !~ /^0/o;

	my $self = scalar @_ && ref $_[0] eq __PACKAGE__ ? shift : $Self;
	$self->error(q//);

	return if scalar @_ < 4;
	my ($file, $user, $pos, $val, $count) = @_;
	
	my @t = split(/::/,(caller(1))[3]);
	croak(qq/\n"_set" cannot be called from outside of Passwd::Unix!/) if $t[-2] ne 'Unix';	
	unless($_CHECK->{$t[-1]}($val)){ 
		my $error = $self->error(qq/Incorrect parameters for "$t[-1]! Leaving unchanged..."/);
		carp($error) if $self->warnings(); 
		return; 
	}

	if( $self->backup() ){
		$self->_do_backup() or return;
	}

	my $umask = umask $self->{'umask'};
	my $mode	=	$file eq $self->passwd_file()	?	PERM_PWD	:
					$file eq $self->group_file()	?	PERM_GRP	:
					$file eq $self->shadow_file()	?	PERM_SHD	:
														PERM_SHD	;

	$count ||= 6;
	my $tmp = $file.'.tmp';
	open(my $fh, '<', $file) or ($self->error($!) and umask $umask and return);
	open(my $ch, '>', $tmp) or ($self->error($!) and umask $umask and return);
	chmod $mode, $ch;
	my $ret;
	while(<$fh>){
		chomp;
		my @a = split /:/;
		if($a[0] eq $user){
			$a[$pos] = $val;
			$ret = TRUE;
			for(scalar @a .. $count){ push @a, ''; }
			print $ch join(q/:/, @a),"\n";
		}else{
			print $ch $_,"\n";	
		}
	}
	close($fh);close($ch);
	move($tmp, $file) or ($self->error($!) and umask $umask and return);

	umask $umask;

	return $ret;
}
#======================================================================
sub _get {
	my $self = scalar @_ && ref $_[0] eq __PACKAGE__ ? shift : $Self;
	$self->error(q//);

	return if scalar @_ != 3;
	my ($file, $user, $pos) = @_;
	
	unless($_CHECK->{'rename'}($user)){ 
		my $error = $self->error(qq/Incorrect user "$user"!/);
		carp($error) if $self->warnings(); 
		return; 
	}
	
	open(my $fh, '<', $file) or ($self->error($!) and return);
	while(<$fh>){
		my @a = split /:/;
		next if $a[0] ne $user;
		chomp $a[$pos];
		return $a[$pos];
	}
	return;
}
#======================================================================
sub uid { 
	my $self = scalar @_ && ref $_[0] eq __PACKAGE__ ? shift : $Self;
	$self->error(q//);

	if(scalar @_ == 1){
		return $self->_get($self->passwd_file(), $_[0], 2);
	}elsif(scalar @_ != 2){
		my $error = $self->error( q/Incorrect parameters for "uid"!/ );
		carp($error) if $self->warnings();
		return;
	}
	return $self->_set($self->passwd_file(), $_[0], 2, $_[1]);
}
#======================================================================
sub gid {
	my $self = scalar @_ && ref $_[0] eq __PACKAGE__ ? shift : $Self;
	$self->error(q//);

	if(scalar @_ == 1){
		return $self->_get($self->passwd_file(), $_[0], 3);
	}elsif(scalar @_ != 2){
		my $error = $self->error( q/Incorrect parameters for "gid"!/ );
		carp($error) if $self->warnings();
		return;
	}
	return $self->_set($self->passwd_file(), $_[0], 3, $_[1]);
}
#======================================================================
sub gecos {
	my $self = scalar @_ && ref $_[0] eq __PACKAGE__ ? shift : $Self;
	$self->error(q//);

	if(scalar @_ == 1){
		return $self->_get($self->passwd_file(), $_[0], 4);
	}elsif(scalar @_ != 2){
		my $error = $self->error(q/Incorrect parameters for "gecos"!/);
		carp($error) if $self->warnings();
		return;
	}
	return $self->_set($self->passwd_file(), $_[0], 4, $_[1]);
}
#======================================================================
sub home { 
	my $self = scalar @_ && ref $_[0] eq __PACKAGE__ ? shift : $Self;
	$self->error(q//);

	if(scalar @_ == 1){
		return $self->_get($self->passwd_file(), $_[0], 5);
	}elsif(scalar @_ != 2){
		my $error = $self->error(q/Incorrect parameters for "home"!/);
		carp($error) if $self->warnings();
		return;
	}
	return $self->_set($self->passwd_file(), $_[0], 5, $_[1]);
}
#======================================================================
sub shell { 
	my $self = scalar @_ && ref $_[0] eq __PACKAGE__ ? shift : $Self;
	$self->error(q//);

	if(scalar @_ == 1){
		return $self->_get($self->passwd_file(), $_[0], 6);
	}elsif(scalar @_ != 2){
		my $error = $self->error(q/Incorrect parameters for "shell"!/);
		carp($error) if $self->warnings();
		return;
	}
	return $self->_set($self->passwd_file(), $_[0], 6, $_[1]);	
}
#======================================================================
sub passwd { 
	my $self = scalar @_ && ref $_[0] eq __PACKAGE__ ? shift : $Self;
	$self->error(q//);

	if(scalar @_ == 1){
		return $self->_get($self->shadow_file(), $_[0], 1);
	}elsif(scalar @_ != 2){
		my $error = $self->error(q/Incorrect parameters for "passwd"!/);
		carp($error) if $self->warnings();
		return;
	}
	return $self->_set($self->shadow_file(), $_[0], 1, $_[1], 8);	
}
#======================================================================
sub rename { 
#	This method will fail, if user doesn't have permissions to files.
#   Error will be in $self->error() and error();
#	return if $( !~ /^0/o;

	my $self = scalar @_ && ref $_[0] eq __PACKAGE__ ? shift : $Self;
	$self->error(q//);
	
	if(scalar @_ != 2){ 
		my $error = $self->error(q/Incorrect parameters for "rename"!/);
		carp($error) if $self->warnings(); 
		return; 
	}
	
	my ($user, $val) = @_;
	unless($self->exists_user($user)){ 
		my $error = $self->error(qq/User "$user" does not exists!/);
		carp($error) if $self->warnings(); 
		return; 
	}
	
	my $gid = $self->gid($user);
	unless(defined $gid){ 
		my $error = $self->error(qq/Cannot retrieve GID of user "$user"! Leaving unchanged.../);
		carp($error) if $self->warnings(); 
		return; 
	}
	
	if( $self->backup() ){
		$self->_do_backup() or return;
	}

	my $umask = umask $self->{'umask'};
	
	my $tmp = $self->group_file.'.tmp';
	open(my $fh, '<', $self->group_file()) or ($self->error($!) and umask $umask and return);
	open(my $ch, '>', $tmp) or ($self->error($!) and umask $umask and return);
	chmod PERM_GRP, $ch;
	while(my $line = <$fh>){
		chomp $line;
		my ($name, $passwd, $gid, $users) = split(/:/,$line,4);
		$users = join(q/,/, map { $_ eq $user ? $val : $_ } split(/\s*,\s*/, $users));
		print $ch join(q/:/, $name, $passwd, $gid, $users),"\n";
	}
	close($fh);close($ch);
	move($tmp, $self->group_file()) or ($self->error($!) and umask $umask and return);
	
	if(-f $self->gshadow_file){
		my $tmp = $self->gshadow_file.'.tmp';
		open(my $fh, '<', $self->gshadow_file()) or ($self->error($!) and umask $umask and return);
		open(my $ch, '>', $tmp) or ($self->error($!) and umask $umask and return);
		chmod PERM_PWD, $ch;
		while(my $line = <$fh>){
			chomp $line;
			my ($name, $passwd, $gid, $users) = split(/:/,$line,4);
			$users = join(q/,/, map { $_ eq $user ? $val : $_ } split(/\s*,\s*/, $users));
			print $ch join(q/:/, $name, $passwd, $gid, $users),"\n";
		}
		close($fh);close($ch);
		move($tmp, $self->gshadow_file()) or ($self->error($!) and umask $umask and return);
	}
	
	$self->_set($self->passwd_file(), $user, 0, $val);	

	umask $umask;

	return $self->_set($self->shadow_file(), $user, 0, $val);
}
#======================================================================
sub maxgid {
	my $self = scalar @_ && ref $_[0] eq __PACKAGE__ ? shift : $Self;
	$self->error(q//);

	my $max = 0;
	open(my $fh, '<', $self->passwd_file()) or ($self->error($!) and return);
	while(<$fh>){
		my $tmp = (split(/:/,$_))[3];
		$max = $tmp > $max ? $tmp : $max;
	}
	close($fh);
	
	# we should check group file too...
	open($fh, '<', $self->group_file()) or ($self->error($!) and return);
	while(<$fh>){
		my $tmp = (split(/:/,$_))[2];
		$max = $tmp > $max ? $tmp : $max;
	}
	close($fh);

	return $max;
}
#======================================================================
sub maxuid {
	my $self = scalar @_ && ref $_[0] eq __PACKAGE__ ? shift : $Self;
	$self->error(q//);

	my $max = 0;
	open(my $fh, '<', $self->passwd_file()) or ($self->error($!) and return);
	while(<$fh>){
		my $tmp = (split(/:/,$_))[2];
		$max = $tmp > $max ? $tmp : $max;
	}
	close($fh);
	return $max;
}
#======================================================================
sub unused_uid {
	my $self = scalar @_ && ref $_[0] eq __PACKAGE__ ? shift : $Self;
	$self->error(q//);

	my $min  = shift || 0;
	my $max  = shift || ( 2 ** ( $Config{ intsize } * 8 ) );

	# UIDs could be in random order, so this is only safe way...
	my ( @seen, $last );
	
	open(my $fh, '<', $self->passwd_file()) or ($self->error($!) and return);
	push @seen, (split(/:/,$_))[2] while <$fh>;
	close($fh);
	
	@seen = sort { $a <=> $b } @seen;
	return $min if $seen[ -1 ] < $min;
	
	for my $uid ( @seen, $max ){
		next if $uid < $min;

		if( not defined $last ){
			return $min if $uid > $min;

			$last = $uid;
			#next;
		}

		return $last + 1 if $uid > $last + 1 and $last + 1 <= $max;
		return if $uid > $max;
		$last = $uid;
	}
	
	return;
}
#======================================================================
sub unused_gid {
	my $self = scalar @_ && ref $_[0] eq __PACKAGE__ ? shift : $Self;
	$self->error(q//);

	my $min  = shift || 0;
	my $max  = shift || ( 2 ** ( $Config{ intsize } * 8 ) );

	# GIDs could be in random order, so this is only safe way...
	my ( %seen, $last );
	
	open(my $fh, '<', $self->passwd_file()) or ($self->error($!) and return);
	$seen{ (split(/:/,$_))[3] } = 1 while <$fh>;
	close($fh);
	
	# we should check group file too...
	open($fh, '<', $self->group_file()) or ($self->error($!) and return);
	$seen{ (split(/:/,$_))[2] } = 1 while <$fh>;
	close($fh);
	
	my @seen = sort { $a <=> $b } keys %seen;
	return $min if $seen[ -1 ] < $min;
	
	for my $gid ( @seen, $max ){
		next if $gid < $min;
		
		if( not defined $last ){
			return $min if $gid > $min;

			$last = $gid;
			#next;
		}

		return $last + 1 if $gid > $last + 1 and $last + 1 <= $max;
		return if $gid > $max;
		$last = $gid;
	}
	
	return;
}
#======================================================================
sub _exists {
	my $self = scalar @_ && ref $_[0] eq __PACKAGE__ ? shift : $Self;
	$self->error(q//);

	return if scalar @_ != 3;
	my ($file, $pos, $val) = @_;
	
	open(my $fh, '<', $file) or ($self->error($!) and return);
	while(<$fh>){
		my @a = split /:/;
		return TRUE if $a[$pos] eq $val;
	}
	return;
}
#======================================================================
sub exists_user {
	my $self = scalar @_ && ref $_[0] eq __PACKAGE__ ? shift : $Self;
	$self->error(q//);

	my ($user) = @_;
	unless($_CHECK->{rename}($user)){ 
		my $error = $self->error(qq/Incorrect user "$user"!/);
		carp($error) if $self->warnings(); 
		return; 
	}
	return $self->_exists($self->passwd_file(), 0, $user);
}
#======================================================================
sub exists_group {
	my $self = scalar @_ && ref $_[0] eq __PACKAGE__ ? shift : $Self;
	$self->error(q//);

	my ($group) = @_;
	unless($_CHECK->{rename}($group)){ 
		my $error = $self->error(qq/Incorrect group "$group"!/);
		carp($error) if $self->warnings(); 
		return; 
	}
	return $self->_exists($self->group_file(), 0, $group);
}
#======================================================================
sub user { 
	my $self = scalar @_ && ref $_[0] eq __PACKAGE__ ? shift : $Self;
	$self->error(q//);

	my (@user) = @_;
	
	unless($_CHECK->{rename}($user[0])){ 
		my $error = $self->error(qq/Incorrect user "$user[0]"!/);
		carp($error) if $self->warnings(); 
		return; 
	}

	if(scalar @_ != 7){
		open(my $fh, '<', $self->passwd_file()) or ($self->error($!) and return);
		while(<$fh>){
			my @a = split /:/;
			next if $a[0] ne $user[0];
			chomp $a[-1];
			splice @a, 0, 2;
			return $self->passwd($user[0]), @a;
		}
		my $error = $self->error(qq/User "$user[0]" does not exists!/);
		carp($error) if $self->warnings();
		return;
	}
	
#	The rest of this method will fail, if user doesn't have permissions to files.
#   Error will be in $self->error() and error();
#	return if $( !~ /^0/o;

	my @tests = qw(rename passwd uid gid gecos home shell);
	for(1..6){
		unless($_CHECK->{$tests[$_]}($user[$_])){ 
			my $error = $self->error(qq/Incorrect parameters for "$tests[$_]"!/);
			carp($error) if $self->warnings(); 
			return; 
		}
	}
	
	if( $self->backup() ){
		$self->_do_backup() or return;
	}

	my $umask = umask $self->{'umask'};
	
	my $passwd = splice @user,1, 1, 'x';
	
	my $mod;
	my $tmp = $self->passwd_file.'.tmp';
	open(my $fh, '<', $self->passwd_file()) or ($self->error($!) and umask $umask and return);
	open(my $ch, '>', $tmp) or ($self->error($!) and umask $umask and return);
	chmod PERM_PWD, $ch;
	while(<$fh>){
		my @a = split /:/;
		if($user[0] eq $a[0]){
			$mod = TRUE;
			print $ch join(q/:/, @user),"\n";
		}else{ print $ch $_; }
	}
	close($fh);
	print $ch join(q/:/, @user),"\n" unless $mod;
	close($ch);
	move($tmp, $self->passwd_file()) or ($self->error($!) and umask $umask and return);
	
	# user already exists	
	if($mod){ $self->passwd($user[0], $passwd); }
	else{ 
		open(my $fh, '>>', $self->shadow_file()) or ($self->error($!) and umask $umask and return);
		chmod PERM_SHD, $fh;
		print $fh join(q/:/, $user[0], $passwd, int(time()/DAY), ('') x 5, "\n");
		close($fh);
	}

	umask $umask;	
	return TRUE;
}
#======================================================================
sub users { 
	my $self = scalar @_ && ref $_[0] eq __PACKAGE__ ? shift : $Self;
	$self->error(q//);

	my @a;
	open(my $fh, '<', $self->passwd_file()) or ($self->error($!) and return);
	push @a, (split(/:/,$_))[0] while <$fh>;
	close($fh);
	return @a;
}
#======================================================================
sub users_from_shadow { 
#	This method will fail, if user doesn't have permissions to files.
#   Error will be in $self->error() and error();
#	return if $( !~ /^0/o;
	
	my $self = scalar @_ && ref $_[0] eq __PACKAGE__ ? shift : $Self;
	$self->error(q//);

	my @a;
	open(my $fh, '<', $self->shadow_file()) or ($self->error($!) and return);
	push @a, (split(/:/,$_))[0] while <$fh>;
	close($fh);
	return @a;
}
#======================================================================
sub del_group {
#	This method will fail, if user doesn't have permissions to files.
#   Error will be in $self->error() and error();
#	return if $( !~ /^0/o;
	
	my $self = scalar @_ && ref $_[0] eq __PACKAGE__ ? shift : $Self;
	$self->error(q//);

	my ($group) = @_;
	unless($_CHECK->{rename}($group)){ 
		my $error = $self->error(qq/Incorrect group "$group"!/);
		carp($error) if $self->warnings(); 
		return; 
	}
	
	if( $self->backup() ){
		$self->_do_backup() or return;
	}

	my $umask = umask $self->{'umask'};
	
	my @dels;
	my $tmp = $self->group_file.'.tmp';
	open(my $fh, '<', $self->group_file()) or ($self->error($!) and umask $umask and return);
	open(my $ch, '>', $tmp) or ($self->error($!) and umask $umask and return);
	chmod PERM_GRP, $ch;
	while(my $line = <$fh>){
		my ($name) = split(/:/,$line,2);
		if($group eq $name){ push @dels, $name; }
		else{ print $ch $line; }
	}
	close($fh);close($ch);
	move($tmp, $self->group_file()) or ($self->error($!) and umask $umask and return);
	
	if(-f $self->gshadow_file){
		my $tmp = $self->gshadow_file.'.tmp';
		open(my $fh, '<', $self->gshadow_file()) or ($self->error($!) and umask $umask and return);
		open(my $ch, '>', $tmp) or ($self->error($!) and umask $umask and return);
		chmod PERM_SHD, $ch;
		while(my $line = <$fh>){
			my ($name) = split(/:/,$line,2);
			print $ch $line if $group ne $name;
		}
		close($fh);close($ch);
		move($tmp, $self->gshadow_file()) or ($self->error($!) and umask $umask and return);
	}

	umask $umask;

	return @dels if wantarray;
	return scalar @dels;
}
#======================================================================
sub group { 
	my $self = scalar @_ && ref $_[0] eq __PACKAGE__ ? shift : $Self;
	$self->error(q//);

	my ($group, $gid, $users) = @_;
	unless($_CHECK->{rename}($group)){ 
		my $error = $self->error(qq/Incorrect group "$group"!/);
		carp($error) if $self->warnings(); 
		return; 
	}
	
	if(scalar @_ == 3){
#	The rest of this "if" will fail, if user doesn't have permissions to files.
#   Error will be in $self->error() and error();
#		return if $( !~ /^0/o;

		if( $self->backup() ){
			$self->_do_backup() or return;
		}

		my $umask = umask $self->{'umask'};
		
		unless($_CHECK->{gid}($gid)){ 
			my $error = $self->error(qq/Incorrect GID "$gid"!/);
			carp($error) if $self->warnings(); 
			umask $umask;
			return; 
		}
# 2009.03.30 - Thx to Jonas Genannt; will allow to add empty groups
#		unless(ref $users and ref $users eq 'ARRAY'){ warn "AAA";		
		if(defined($users) && ref $users ne 'ARRAY' ){ 
			my $error = $self->error(qq/Incorrect parameter "users"! It should be arrayref.../);
			carp($error) if $self->warnings(); 
			umask $umask;
			return; 
		}
		$users ||= [ ];
		foreach(@$users){
			unless($_CHECK->{rename}($_)){ 
				my $error = $self->error(qq/Incorrect user "$_"!/);
				carp($error) if $self->warnings(); 
				umask $umask;
				return; 
			}
		}
		
		my $mod;
		my $tmp = $self->group_file.'.tmp';
		open(my $fh, '<', $self->group_file()) or ($self->error($!) and umask $umask and return);
		open(my $ch, '>', $tmp) or ($self->error($!) and umask $umask and return);
		chmod PERM_GRP, $ch;
		while(my $line = <$fh>){
			chomp $line;
			my ($name, $passwd) = split(/:/,$line,3);
			if($group eq $name){ 
				print $ch join(q/:/, $group, $passwd, $gid, join(q/,/, @$users)),"\n"; 
				$mod = TRUE;
			} else{ print $ch $line,"\n"; }
		}
		print $ch join(q/:/, $group, 'x', $gid, join(q/,/, @$users)),"\n" unless $mod;
		close($fh);close($ch);
		move($tmp, $self->group_file()) or ($self->error($!) and umask $umask and return);

		if(-f $self->gshadow_file){
			my $mod;
			my $tmp = $self->gshadow_file.'.tmp';
			open(my $fh, '<', $self->gshadow_file()) or ($self->error($!) and umask $umask and return);
			open(my $ch, '>', $tmp) or ($self->error($!) and umask $umask and return);
			chmod PERM_SHD, $ch;
			while(my $line = <$fh>){
				chomp $line;
				my ($name, $passwd) = split(/:/,$line,3);
				if($group eq $name){ 
					print $ch join(q/:/, $group, $passwd, q//, join(q/,/, @$users)),"\n"; 
					$mod = TRUE;
				} else{ print $ch $line,"\n"; }
			}
			print $ch join(q/:/, $group, '!', q//, join(q/,/, @$users)),"\n" unless $mod;
			close($fh);close($ch);
			move($tmp, $self->gshadow_file()) or ($self->error($!) and umask $umask and return);
		}
		
		umask $umask;
	}else{
		my ($gid, @users);
		open(my $fh, '<', $self->group_file()) or ($self->error($!) and return);
		while(my $line = <$fh>){
			chomp $line;
			my ($name, undef, $id, $usrs) = split(/:/,$line,4);
			next if $group ne $name;
			$gid = $id;
			$usrs =~ s/\s+$//o;
			push @users, split(/\s*,\s*/o, $usrs) if $usrs;
			last;
		}
		
		# if searched ground does not exist
		return undef, [ ] unless defined $gid;
	
		open($fh, '<', $self->passwd_file()) or ($self->error($!) and return);
		while(my $line = <$fh>){
			my ($login, undef, undef, $id) = split(/:/,$line,5);
			next if $id != $gid;
			push @users, $login;
		}

		@users = sort @users;
		for(reverse 0..$#users){
			last if $_ == 0;
			splice @users, $_, 1 if $users[$_] eq $users[ $_ - 1 ];
		}
		return $gid, \@users;
	}
	
	return;
}
#======================================================================
sub groups { 
	my $self = scalar @_ && ref $_[0] eq __PACKAGE__ ? shift : $Self;
	$self->error(q//);

	my @a;
	open(my $fh, '<', $self->group_file()) or ($self->error($!) and return);
	push @a, (split(/:/,$_))[0] while <$fh>;
	close($fh);
	return @a;
}
#======================================================================
sub groups_from_gshadow { 
	my $self = scalar @_ && ref $_[0] eq __PACKAGE__ ? shift : $Self;
	$self->error(q//);

	my @a;
	open(my $fh, '<', $self->gshadow_file()) or ($self->error($!) and return);
	push @a, (split(/:/,$_))[0] while <$fh>;
	close($fh);
	return @a;
}
#======================================================================
1;

=encoding utf8

=head1 NAME

Passwd::Unix - access to standard unix files

=head1 SYNOPSIS

	use Passwd::Unix;
	
	my $pu = Passwd::Unix->new();
	my $err = $pu->user("example", $pu->encpass("my_secret"), $pu->maxuid + 1, 10,
						"My User", "/home/example", "/bin/bash" );
	$pu->passwd("example", $pu->encpass("newsecret"));
	foreach my $user ($pu->users) {
		print "Username: $user\nFull Name: ", $pu->gecos($user), "\n\n";
	}
	my $uid = $pu->uid('example');
	$pu->del("example");

	# or 

	use Passwd::Unix qw(check_sanity reset encpass passwd_file shadow_file 
				group_file backup warnings del del_user uid gid gecos
				home shell passwd rename maxgid maxuid exists_user 
				exists_group user users users_from_shadow del_group 
				group groups groups_from_gshadow);
	
	my $err = user( "example", encpass("my_secret"), $pu->maxuid + 1, 10,
					"My User", "/home/example", "/bin/bash" );
	passwd("example",encpass("newsecret"));
	foreach my $user (users()) {
		print "Username: $user\nFull Name: ", gecos($user), "\n\n";
	}
	my $uid = uid('example');
	del("example");

=head1 ABSTRACT

Passwd::Unix provides an abstract object-oriented and function interface to
standard Unix files, such as /etc/passwd, /etc/shadow, /etc/group. Additionally
this module provides  environment to testing new software, without using
system critical files in /etc/dir.

=head1 DESCRIPTION

The Passwd::Unix module provides an abstract interface to /etc/passwd, 
/etc/shadow and /etc/group format files. It is inspired by 
Unix::PasswdFile module (that one does not handle /etc/shadow file, 
what is necessary in modern systems like Sun Solaris 10 or Linux).

=head1 SUBROUTINES/METHODS

=over 4

=item B<new( [ param0 => 1, param1 => 0... ] )>

Constructor. Possible parameters are:

=over 8

=item B<passwd> - path to passwd file; default C</etc/passwd>

=item B<shadow> - path to shadow file; default C</etc/shadow>

=item B<group> - path to group file; default C</etc/group>

=item B<gshadow> - path to gshadow file if any; default C</etc/gshadow>

=item B<umask> - umask for creating files; default C<0022> (standard for UNIX and Linux systems)

=item B<backup> - boolean; if set to C<1>, backup will be made; default C<1>

=item B<warnings> - boolean; if set to C<1>, important warnings will be displayed; default C<0>

=back


=item B<check_sanity()>

This method check if environment is sane. I.e. if users in I<shadow> and
in I<passwd> are the same. This method is invoked in constructor.

=item B<del( USERNAME0, USERNAME1... )>

This method is an alias for C<del_user>. It's for transition only.

=item B<del_user( USERNAME0, USERNAME1... )>

This method will delete the list of users. It has no effect if the 
supplied users do not exist.

=item B<del_group( GROUPNAME0, GROUPNAME1... )>

This method will delete the list of groups. It has no effect if the 
supplied groups do not exist.

=item B<encpass( PASSWORD )>

This method will encrypt plain text into unix style MD5 password.

=item B<gecos( USERNAME [,GECOS] )>

Read or modify a user's GECOS string (typically their full name). 
Returns the result of operation (C<1> or C<undef>) if GECOS was specified. 
Otherwhise returns the GECOS.

=item B<gid( USERNAME [,GID] )>

Read or modify a user's GID. Returns the result of operation (TRUE or 
FALSE) if GID was specified otherwhise returns the GID.

=item B<home( USERNAME [,HOMEDIR] )>

Read or modify a user's home directory. Returns the result of operation 
(C<1> or C<undef>) if HOMEDIR was specified otherwhise returns the HOMEDIR.

=item B<maxuid( )>

This method returns the maximum UID in use by all users. 

=item B<maxgid( )>

This method returns the maximum GID in use by all groups. 

=item B<unused_uid( [MINUID] [,MAXUID] )>

This method returns the first unused UID in a given range. The default MINUID is 0. The default MAXUID is maximal integer value (computed from C<$Config{ intsize }> ).

=item B<unused_gid( [MINGID] [,MAXGID] )>

This method returns the first unused GID in a given range. The default MINGID is 0. The default MAXGID is maximal integer value (computed from C<$Config{ intsize }> ).

=item B<passwd( USERNAME [,PASSWD] )>

Read or modify a user's password. If you have a plaintext password, 
use the encpass method to encrypt it before passing it to this method. 
Returns the result of operation (C<1> or C<undef>) if PASSWD was specified. 
Otherwhise returns the PASSWD.

=item B<rename( OLDNAME, NEWNAME )>

This method changes the username for a user. If NEWNAME corresponds to 
an existing user, that user will be overwritten. It returns FALSE on 
failure and TRUE on success.

=item B<shell( USERNAME [,SHELL] )>

Read or modify a user's shell. Returns the result of operation (TRUE 
or FALSE) if SHELL was specified otherwhise returns the SHELL.

=item B<uid( USERNAME [,UID] )>

Read or modify a user's UID. Returns the result of operation (TRUE or 
FALSE) if UID was specified otherwhise returns the UID.

=item B<user( USERNAME [,PASSWD, UID, GID, GECOS, HOMEDIR, SHELL] )>

This method can add, modify, or return information about a user. 
Supplied with a single username parameter, it will return a six element 
list consisting of (PASSWORD, UID, GID, GECOS, HOMEDIR, SHELL), or 
undef if no such user exists. If you supply all seven parameters, 
the named user will be created or modified if it already exists.

=item B<group( GROUPNAME [,GID, ARRAYREF] )>

This method can add, modify, or return information about a group. 
Supplied with a single groupname parameter, it will return a two element 
list consisting of (GID, ARRAYREF), where ARRAYREF is a ref to array 
consisting names of users in this GROUP. It will return undef and ref to empty array (C<undef, [ ]>) if no such group 
exists. If you supply all three parameters, the named group will be 
created or modified if it already exists.

=item B<users()>

This method returns a list of all existing usernames. 

=item B<users_from_shadow()>

This method returns a list of all existing usernames in a shadow file. 

=item B<groups()>

This method returns a list of all existing groups. 

=item B<groups_from_gshadow()>

This method returns a list of all existing groups in a gshadow file. 

=item B<exists_user(USERNAME)>

This method checks if specified user exists. It returns TRUE or FALSE.

=item B<exists_group(GROUPNAME)>

This method checks if specified group exists. It returns TRUE or FALSE.

=item B<default_umask([UMASK])>

This method, if called with an argument, sets default umask for this module (not Your program!).
Otherwise returns the current UMASK. Probably You don't want to change this.

=item B<passwd_file([PATH])>

This method, if called with an argument, sets path to the I<passwd> file.
Otherwise returns the current PATH.

=item B<shadow_file([PATH])>

This method, if called with an argument, sets path to the I<shadow> file.
Otherwise returns the current PATH.

=item B<group_file([PATH])>

This method, if called with an argument, sets path to the I<group> file.
Otherwise returns the current PATH.

=item B<gshadow_file([PATH])>

This method, if called with an argument, sets path to the I<gshadow> file.
Otherwise returns the current PATH.

=item B<reset()>

This method sets paths to files I<passwd>, I<shadow>, I<group> to the
default values.

=item B<error()>

This method returns the last error (even if "warnings" is disabled).

=back

=head1 DEPENDENCIES

=over 4

=item Struct::Compare

=item Crypt::PasswdMD5

=back

=head1 INCOMPATIBILITIES

None known.

=head1 BUGS AND LIMITATIONS

None. I hope. 

=head1 THANKS

=over 4

=item Thanks to Jonas Genannt for many suggestions and patches! 

=item Thanks to Christian Kuelker for suggestions and reporting some bugs :-).

=item Thanks to Steven Haryanto for suggestions.

=item BIG THANKS to Lopes Victor for reporting some bugs and his exact sugesstions :-)

=item Thanks to Foudil BRÉTEL for some remarks, suggestions as well as supplying relevant patch!

=item BIG thanks to Artem Russakovskii for reporting a bug.

=back

=head1 AUTHOR

Strzelecki Lukasz <lukasz@strzeleccy.eu>

=head1 LICENCE AND COPYRIGHT

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

See http://www.perl.com/perl/misc/Artistic.html
