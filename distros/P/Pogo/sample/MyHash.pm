package MyHash;
use Pogo;
use strict;
use vars qw(@ISA %HOOK);
@ISA = qw(Pogo::Hash);

%HOOK = (set => \&hook_set);

sub hook_set {
	my($self, $key, $value) = @_;
	$self->set('UTIME', time) unless $key eq 'UTIME';
	1;
}

1;
