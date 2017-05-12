package Proc::Lock;

$Proc::Lock::VERSION = (split " ", '# 	$Id: Lock.pm,v 1.5 2000/09/21 14:14:20 mkul Exp $	')[3];

=head1 NAME

Proc::Lock - lock interface module

=head1 SYNOPSIS

 use Proc::Lock;
 my $lock = new Proc::Lock ( ... );
 $lock->set ();
 die "locked" if $lock->isSet ();
 $lock->unset ();

=head1 DESCRIPTION

 Generic lock module. You must subclass this class and overwrite set, unset, isSet and new (possible) for do your work

=cut

=head2 new

Construct new lock object. You can setup parameters:

ProcessName => $name of process for make lock file name
Pid         => $ pid of process for make lock file name
HostName    => $ name of host for make lock file name
Wait        => wait for lock is clean and continue
Timeout     => limit of time of wait of lock clean
NoUnset     => not unset lock at unset operation

 my $lock = new Proc::Lock... ( ProcessName => $0,
                                Pid         => $$,
                                Hostname    => gethostname(),
                                Wait        => 1,
				NoUnset     => 1,
                                Timeout     => 30 );

 $lock->set || die "already runned";

=cut

sub new
{
    my ( $class, %params ) = @_;
    $params{processname} || die "Your must setup ProcessName for lock";
    foreach my $key ( keys %params ) { $params{ lc $key } = delete $params{$key}; }
    bless { %params }, $class;
}

=head2 set

setup lock. Return true if success

=cut

sub set
{
    my $this = shift;
    eval
    {
	local $SIG{ALRM} = sub { die "lock timeout" };
	alarm ( $this->{timeout} ) if ( $this->{timeout} );
	$this->_set ();
    };
}

=head2 unset

unset lock, return true if success

=cut

sub unset
{
    my $this = shift;
    return 1 if $this->{nounset};
    $this->_unset();
}

=head2 isSet

return true if lock is up

=cut

sub isSet
{
    my $this = shift;
    $this->_isSet();
}

=head2 DESTROY

destroy lock object

=cut

sub DESTROY
{
    my $this = shift || return;
    $this->unset();
}

=head2 log

Return log object

=cut

sub log
{
    my $this = shift;
    my $log = ( $this->{log} ||= new Log::Dispatch );
    $log;
}

=head2 _set _unset _isSet

private methods, You must put your functionality to this methods.
The real methods ( set, unset, isSet ) call this method.

=cut

1;

__END__
