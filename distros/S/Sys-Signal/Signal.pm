package Sys::Signal;

use DynaLoader ();

@ISA = qw(DynaLoader);

$VERSION = '0.02';

__PACKAGE__->bootstrap($VERSION);

1;
__END__

=head1 NAME

Sys::Signal - Set signal handlers with restoration of existing C sighandler

=head1 SYNOPSIS

  use Sys::Signal ();
  eval {    
      my $h = Sys::Signal->set(ALRM => sub { die "timeout\n" });    
      alarm $timeout;   
      ... do something thay may timeout ...
      alarm 0;    
  };    
  die $@ if $@;

=head1 DESCRIPTION

The I<Sys::Signal> I<set> method works much like C<local $SIG{FOO}>, 
but with the added functionality of restoring the underlying signal
handler to the previous C function, rather than Perl's.  Unless, of course,
Perl's C signal handler was the previous handler.

=head1 AUTHOR

Doug MacEachern

=head1 SEE ALSO

perl(1).

=cut
