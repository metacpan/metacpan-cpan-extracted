use strict;
package ObjStore::notify;
use Carp;
use vars qw(@Check);

sub import {
    no strict 'refs';
    shift;
    my $p = caller;
    for my $m (@_) {
	# add more intelligence for extra call tracking?
#	croak "can't find method $ {p}::do_$m" 
#	    unless defined *{"$ {p}::do_$m"}{CODE};
	*{"$p\::$m"} = sub {
	    for my $x (@Check) { $x->($p,$m,@_) }
	    my $o = shift;
	    my $msg = join($;, $m, @_);
	    $o->notify($msg, 'now');
	    ()
	};
	ObjStore::_mark_method(\&{"$p\::$m"});
    }
}

sub check_arguments {
    my $p = shift;
    my $m = shift;
    my $o = shift;
    my $ok=1;
    for my $arg (@_) { $ok=0 if !defined $arg || $arg =~ / $; /x }
    if (!$ok) {
	my @args;
	for my $arg (@_) { push @args, defined $arg?$arg:'UNDEF' }
	my $args = join(',', @args);
	$args =~ s/ $; /\$\;/gx;
	carp "$o->$p\::$m($args)\n";
    }
}

1;

=head1 NAME

ObjStore::notify - Pragma to Declare Methods That Will Execute Remotely

=head1 SYNOPSIS

  package MyObject;
  use ObjStore;
  use base 'ObjStore::HV';

  use ObjStore::notify qw(jump);
  sub do_jump {
     my ($obj, $why) = @_;     # server side
     warn $why; # 'very high'
  }

  $obj->jump('very high'); #client side

=head1 DESCRIPTION

Declares a simple stub method that invokes the C<notify> method.
Works in concert with C<ObjStore::Process::autonotify>.

There will probably be a way to alias this package to 'notify', so you
can type 'use notify' instead of 'use ObjStore::notify'.

=cut
