package Net::uFTP::FTP;

use vars qw($VERSION);

$VERSION = 0.16;
#--------------

use warnings;
use strict;
use File::Find;
use File::Basename qw(basename dirname);
use File::Path qw(mkpath);
use Cwd qw(getcwd);
use Net::FTP::AutoReconnect;
#======================================================================
use base qw(Class::Accessor::Fast::XS);
#----------------------------------------------------------------------
__PACKAGE__->mk_accessors(qw(ftp host type user password debug));
#======================================================================
sub AUTOLOAD {
	our $AUTOLOAD;
	my ($method) = $AUTOLOAD =~ /::([^:]+)$/o;

	return if $method eq 'DESTROY';	
	
	my $self = shift;
	
	croak(qq/Unsupported method "$method"/) unless $self->ftp()->can($method);
	
	return $self->ftp()->$method(@_);
}
#======================================================================
sub new {
	my ($self, $host, %params) = (shift, shift, @_);
	
	$self = bless \%params, $self;

	$self->ftp(Net::FTP::AutoReconnect->new($host, Port => $params{port}, Debug => $self->debug, ));
	$self->ftp()->login($self->user(), $self->password()) or return;
	return $self;
}
#======================================================================
sub put { 
	my ($self, $local, $remote, $recurse) = @_;
	return if not defined $local or not -e $local;

	$remote = $self->pwd() unless defined $remote;
	
	if(not $recurse and -d $local){
		$self->mkdir($remote);
	}elsif(-d $local){
		my (@dirs, @files);
		find(sub {
					return if /^\./o;
					if(-d $File::Find::name){ push @dirs, $File::Find::name; }
					elsif(-f $File::Find::name){ push @files, $File::Find::name; }
				}, $local);
				
		my $base = basename($local);
		$self->mkdir(File::Spec->catfile($remote,$_),1) for sort map { s/^$local/$base/; $_ } @dirs;
		for(@files){
			(my $r = $_) =~ s/^$local/$base/;
			$self->ftp()->put($_, File::Spec->catfile($remote,$r));
		}		
	}elsif(-f $local){
		$self->mkdir(dirname($remote));
		$self->ftp()->put($local, $remote);
	}
}
#======================================================================
sub is_dir {
	my ($self, $path) = @_;
	return unless defined $path and $self->ftp()->cwd($path);
	$self->ftp()->cdup();
	return 1;
}
#======================================================================
sub is_file {
	my ($self, $path) = @_;
	return unless defined $path and $self->ftp()->mdtm($path);
	return 1;
}
#======================================================================
sub get { 
	my ($self, $remote, $local, $recurse) = @_;
	
	return if not defined $remote;
	
	$local = getcwd() unless defined $local;
	if(-d $local){ $local = File::Spec->catfile($local, basename($remote)); }
	else{ mkpath dirname($local); }	
	
	if($self->is_dir($remote)){
		mkpath $local;
		foreach my $file($self->ftp()->ls($remote)){
			next if $file =~ /^\./o;
			my $dst = File::Spec->catfile($local, basename($file));
			if($recurse and $self->is_dir($file)){
				$self->get($file, $dst, 1);
			}elsif($self->is_dir($file)){
				mkdir $dst;
			}else{
				$self->ftp()->get($file, $dst);
			}
		}
	}else{
		$self->ftp()->get($remote, $local);
	}
}
#======================================================================
sub ls { return shift->ftp()->ls(@_); }
#======================================================================
sub dir { return shift->ftp()->dir(@_); }
#======================================================================
sub cwd { return shift->ftp()->cwd(@_); }
#======================================================================
sub pwd { return shift->ftp()->pwd(@_); }
#======================================================================
sub rename { return shift->ftp()->rename(@_); }
#======================================================================
sub size { return shift->ftp()->size(@_); } 
#======================================================================
sub mdtm { return shift->ftp()->mdtm(@_); } 
#======================================================================
sub binary { return shift->ftp()->binary(@_); } 
#======================================================================
sub ascii { return shift->ftp()->mdtm(@_); } 
#======================================================================
sub port { return shift->ftp()->port(@_); }
#======================================================================
#sub get { return shift->ftp()->get(@_); }
#======================================================================
#sub put { return shift->ftp()->put(@_); }
#======================================================================
sub mkdir { return shift->ftp()->mkdir(@_); }
#======================================================================
sub rmdir { return shift->ftp()->rmdir(@_); }
#======================================================================
sub delete { return shift->ftp()->delete(@_); }
#======================================================================
sub message { return shift->ftp()->message(@_); }
#======================================================================
sub cdup { return shift->ftp()->cdup(); }
#======================================================================
sub pasv { return shift->ftp()->pasv(@_); }
#======================================================================
sub quit { return shift->ftp()->quit(@_); }
#======================================================================
1;
