use strict;
package ObjStore::ServerInfo;
use Carp;
use ObjStore;
use base 'ObjStore::HV';
use vars qw($EXE $HOST $SELF);

$EXE = $0;
$EXE =~ s{^ .* / }{}x;
chop($HOST = `hostname`);

# Should start rather low until it is established that there
# are no other servers running.
$ObjStore::TRANSACTION_PRIORITY = 0x2000;

# Auto-retry of deadlocks can cause havoc.  You must take
# responsibility to address this yourself.
#ObjStore::set_max_retries(0);

sub new {
    my $o = shift->SUPER::new(@_);
    $$o{exe} = $EXE;
    $$o{argv} = \@ARGV;
    $$o{host} = $HOST;
    $$o{pid} = $$;
    $$o{uid} = getpwuid($>);
    $$o{mtime} = time;
    $SELF = $o->new_ref;
    $o;
}

sub touch {
    my ($class, $time) = @_;
    $time ||= time;
    my $s = $SELF->focus;
    if ($s) {
	$$s{mtime} = $time;
    }
    $s;
}

sub last_update { time - shift->{mtime} }

1;

=head1 NAME

    ObjStore::ServerInfo - associate a Unix process with a database

=head1 SYNOPSIS

=head1 DESCRIPTION

The minimum amount of database code to reasonably represent a Unix
process.  Patches for non-Unixen welcome.

=head1 TODO

'time' should come from Event?

=cut
