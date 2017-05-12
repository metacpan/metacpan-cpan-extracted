package Proc::Lock::File;

#Proc::Lock::File::VERSION = (split " ", '# 	$Id: File.pm,v 1.3 2000/09/21 14:15:21 mkul Exp $	')[3];

=head1 NAME

Proc::Lock::File - lock interface module

=head1 SYNOPSIS

 use Proc::Lock::File;
 my $lock = new Proc::Lock::File ( Directory => '/var/locks',
				   ProcessName => 'locker' );
 $lock->set () || die "already locked";
 die "locked" if $lock->isSet ();
 $lock->unset ();

=head1 DESCRIPTION

 Generic lock module. You must subclass this class and overwrite set, clear, isSet and new (possible) for do your work

=cut

=head2 new

Construct new file lock object. Add Directory parameter to parent constructor.

=cut

use strict;
use IO::File;
use Proc::Lock;
use base qw(Proc::Lock);
use Fcntl ':flock';

sub new
{
    my ( $class, %params ) = @_;
    my $this = $class->SUPER::new ( %params );
    $this->{directory} || die "You must set Directory parameter";
    $this;
}

sub _set
{
    my $this = shift;
    my $fileName = $this->{processname};
    $fileName   .= '.' . $this->{hostname} if $this->{hostname};
    $fileName   .= '.' . $this->{pid}      if $this->{pid};
    $fileName    = $this->{directory} . '/' . $fileName;
    $fileName   =~ s#//#/#g;

    return undef if ( ( -e $fileName ) && ( ! $this->{wait} ) );

    my $file = new IO::File ( $fileName, 'w' );
    if ( ! $file )
    {
	$this->notice ( "Error open file $fileName for write access: $!" );
	return undef;
    }

    my $lockMethod = LOCK_EX;
    $lockMethod    = $lockMethod | LOCK_NB if ( ! $this->{wait} );

    if ( ! flock ( $file, $lockMethod ) )
    {
	$file->close ();
	$this->log->notice ( "can't lock file $fileName: $!" );
	return undef;
    };

    $file->print ( $$ );

    $this->{file}     = $file;
    $this->{filename} = $fileName;
    $this->{isset}    = 1;

    1;
}

sub _unset
{
    my $this     = shift || return;

    my $result   = 1;
    my $fileName = $this->{filename} || return;

    if ( ! unlink ( $this->{filename} ) )
    {
	$this->log->error ( "Error unlink file $fileName: $!" );
	$result = 0;
    }

    if ( ( $this->{file} ) and ( ! $this->{file}->close ) )
    {
	$this->log->error ( "Error close file $fileName: $!" );
	$result = 0;
    }

    $result;
}

sub _isSet
{
    my $this = shift;
    $this->{isset};
}

1;

__END__

