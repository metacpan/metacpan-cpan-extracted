package Net::uFTP::SFTP;

use vars qw($VERSION);

$VERSION = 0.16;
#--------------

use warnings;
use strict;
use Carp;
use Net::SSH2;
use File::Spec;
use File::Basename qw(basename dirname);
use File::Stat::ModeString;
use File::Find;
use File::Path qw(mkpath);
use Cwd qw(getcwd);
#======================================================================
use base qw(Class::Accessor::Fast::XS);
#----------------------------------------------------------------------
__PACKAGE__->mk_accessors(qw(ssh sftp host user password debug root _cwd port));
#======================================================================
sub new {
	my ($self, $host, %params) = (shift, shift, @_);
	
	$self = bless \%params, $self;	
	$self->host($host);
	$self->ssh(Net::SSH2->new());
	$self->ssh()->blocking( 1 );
	$self->ssh()->debug($self->debug() ? 1 : 0);
	#$self->ssh()->connect($host . q/:/ . $params{port});
	$self->ssh()->connect($host, $self->port) or return;
	$self->ssh()->auth_password($self->user(), $self->password()) or return;
	#$self->ssh()->auth(username => $self->user(), password => $self->password());
	$self->sftp($self->ssh()->sftp());
	$self->root($self->sftp()->realpath('.'));
	$self->cwd($self->root());
	$self->_cwd('/');

	return $self;
}
#======================================================================
sub change_root {
	my ($self, $root) = @_;
	$self->root($root);
	$self->cwd($root);
	$self->_cwd('/');
	return $root;
}
#======================================================================
sub cwd {
	# ustawiamy sciezke na poczatkowa jesli nie zostal podany argument
	return $_[0]->_cwd($_[0]->root()) unless defined $_[1];
	my $realpath = $_[0]->sftp()->realpath(File::Spec->catfile($_[0]->_cwd(), $_[1]));
	return $realpath ? $_[0]->_cwd($realpath) : undef;
}
#======================================================================
sub pwd { 
	my ($self) = @_;
	my $root = $self->root();
	(my $cwd = $self->_cwd()) =~ s/^$root//;
	return ($cwd and $cwd ne 0) ? $cwd : '/';
}
#======================================================================
sub ls {
	my ($self, $path) = @_;
	
	my $_path = defined $path ? $path : $self->pwd();
	my $root = ($_path =~ /^\//o) ? $self->root() : $self->_cwd();
	$root = File::Spec->catfile($root,$_path);
	my $r = $self->root();
	(my $remote = $root) =~ s/^$r//;
	
	if(my $dir = $self->sftp()->opendir($root)){
		my @files;
		while(my $file = $dir->read){
			next if $file->{name} =~ /^\./;
			push @files, $file->{name};
		}
		return @files unless defined $path;
		return map { File::Spec->catfile($path,$_) } @files;
	}else{
		return $remote if $self->sftp()->open($root);
	}
}
#======================================================================
sub dir {
	my ($self, $path) = @_;
	
	my @abbr = qw( Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec );
	$path = $self->pwd() unless defined $path;
	my $root = ($path =~ /^\//o) ? $self->root() : $self->_cwd();
	$root = File::Spec->catfile($root,$path);
	
	if(my $dir = $self->sftp()->opendir($root)){
		my @files;
		while(my $file = $dir->read){
			next if $file->{name} =~ /^\./;
			my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime($file->{mtime});
			push @files, mode_to_string($file->{mode}).qq/\tx $file->{uid}\t\t$file->{gid}\t\t$file->{size}\t$abbr[$mon] $mday $hour:$min\t$file->{name}/;
		}
		return @files;
	}else{
		return unless my $dir = $self->sftp()->opendir(dirname($root));
		my $basename = basename($root);
		while(my $file = $dir->read()){
			my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime($file->{mtime});
			return mode_to_string($file->{mode}).qq/\tx $file->{uid}\t\t$file->{gid}\t\t$file->{size}\t$abbr[$mon] $mday $hour:$min\t$file->{name}/
				if $file->{name} eq $basename;
		}
	}
}
#======================================================================
sub rename { 
	my ($self, $remote, $nremote) = @_;
	return unless defined $remote and defined $nremote;

	my $root  = ($remote =~ /^\//o)  ? $self->root() : $self->_cwd();
	my $nroot = ($nremote =~ /^\//o) ? $self->root() : $self->_cwd();
	
	return $self->sftp()->rename(File::Spec->catfile($root,$remote), File::Spec->catfile($nroot,$nremote)); 
}
#======================================================================
sub size { 
	my ($self, $remote) = @_;
	return unless defined $remote;
	my $root = ($remote =~ /^\//o) ? $self->root() : $self->_cwd();
	$remote = File::Spec->catfile($root,$remote);
	return unless $self->sftp()->open($remote);
	return ($self->sftp()->stat($remote))->{size}; 
}
#======================================================================
sub mdtm { 
	my ($self, $remote) = @_;
	return unless defined $remote;
	my $root = ($remote =~ /^\//o) ? $self->root() : $self->_cwd();
	$remote = File::Spec->catfile($root,$remote);
	return unless $self->sftp()->open($remote);
	return ($self->sftp()->stat($remote))->{mtime}; 
}
#======================================================================
sub put { 
	my ($self, $local, $remote, $recurse) = @_;
	return if not defined $local or not -e $local;

	$remote = $self->pwd() unless defined $remote;
	my $root = ($remote =~ /^\//o) ? $self->root() : $self->_cwd();
	$root = File::Spec->catfile($root,$remote);
	$root = File::Spec->catfile($root, basename($local)) if $self->sftp()->opendir($root);
	$root = File::Spec->canonpath($root);
	
	if(not $recurse and -d $local){
		$self->mkdir($root);
	}elsif(-d $local){
		my (@dirs, @files);
		find(sub {
					return if /^\./o;
					if(-d $File::Find::name){ push @dirs, $File::Find::name; }
					elsif(-f $File::Find::name){ push @files, $File::Find::name; }
				}, $local);
	
		@dirs  = map { s/^$local//o; $_} @dirs;	
		$self->mkdir($root, 1);
		$self->mkdir(File::Spec->catfile($root,$_),1) for @dirs;
		
		for(@files){
			(my $r = $_) =~ s/^$local//o;
			$self->ssh()->scp_put($_, quotemeta(File::Spec->canonpath(File::Spec->catfile($root,$r))));
		}		
	}elsif(-f $local){
		$self->mkdir(dirname($remote));
		$self->ssh()->scp_put($local, quotemeta($root));
	}
}
#======================================================================
sub is_dir {
	my ($self, $path) = @_;
	return 1 if defined $path and $self->sftp()->opendir($path);
	return;
}
#======================================================================
sub get { 
	my ($self, $remote, $local, $recurse) = @_;
	return unless defined $remote and $self->mdtm($remote);
	
	$local = getcwd() unless defined $local;
	if(-d $local){ $local = File::Spec->catfile($local, basename($remote)); }
	else{ mkpath dirname($local); }	
	
	my $root = $remote =~ /^\//o ? $self->root() : $self->_cwd();
	(my $src = $remote) =~ s/^$root//o;
	$src = File::Spec->catfile($root, $src);
	
	if(my $dir = $self->sftp()->opendir($src)){
		mkpath $local;
		return unless $recurse;
		while(my $file = $dir->read()){
			next if $file->{name} =~ /^\./o;
			my $this = File::Spec->catfile($src, $file->{name});
			my $dst = File::Spec->catfile($local, $file->{name});
			if($self->is_dir($this)){
				$self->get(File::Spec->catfile($remote, $file->{name}), $dst, 1);
			}else{
				$self->ssh()->scp_get(quotemeta($this), $dst);
			}
		}
	}else {
		$self->ssh()->scp_get(quotemeta($src), $local);
	}
}
#======================================================================
sub delete {
	my ($self, $remote) = @_;
	return unless defined $remote;
	my $root = $remote =~ /^\//o ? $self->root() : $self->_cwd();
	$remote =~ s/^$root//o;
	return $self->sftp()->unlink(File::Spec->catfile($root, $remote));
}
#======================================================================
sub mkdir { 
	my ($self, $path, $recurse) = @_;
	return unless defined $path;
	my $root = $path =~ /^\//o ? $self->root() : $self->_cwd();
	(my $tmp = $path) =~ s/^$root//o;
	
	# powrot jest taki katalog juz istnieje
	return File::Spec->catfile($self->pwd(),$path) if $self->sftp()->opendir(File::Spec->catfile($root, $tmp));
	
	my @path = $recurse ? split(/\//o, $tmp) : ($tmp);
	
	for my $dir(@path){
		$root = File::Spec->catfile($root, $dir);
		$self->sftp()->mkdir($root);
	}
	
	return File::Spec->catfile($self->pwd(),$path); 
}
#======================================================================
sub rmdir {
	my ($self, $path, $recurse) = @_;
	return unless defined $path;
	my $root = $self->_cwd();
	$path =~ s/^$root//o;
	$path = File::Spec->catfile($root, $path);
	
	if($recurse){
		my $dir = $self->sftp()->opendir($path);
		return unless $dir;
		while(my $file = $dir->read()){
			next if $file->{name} eq q/./ or $file->{name} eq q/../;
			my $p = File::Spec->catfile($path, $file->{name});
			if($self->sftp()->opendir($p)){ $self->rmdir($p, 1); }
			else { $self->sftp()->unlink($p); }
		}
	}
	
	$self->sftp()->rmdir($path);
	
	return;
}
#======================================================================
sub message { return $_[0]->ssh()->error(); }
#======================================================================
sub cdup {
	my ($self) = @_;
	# powrot, jesli wyzej sie nie da
	return 1 if $self->root() eq $self->_cwd();
	$self->cwd(dirname($self->_cwd()));
	return 1;
}
#======================================================================
sub binary { }
#======================================================================
sub ascii { }
#======================================================================
sub pasv { }
#======================================================================
sub quit { return $_[0]->ssh()->disconnect(); }
#======================================================================
#======================================================================
1;
