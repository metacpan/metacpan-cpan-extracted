package Sys::Proctitle;

use 5.008;
use strict;
use warnings;

require Exporter;

our @ISA = qw(Exporter);
our %EXPORT_TAGS=(
		  all=>[qw(setproctitle getproctitle)],
		 );
our @EXPORT_OK=(@{ $EXPORT_TAGS{'all'}});
our @EXPORT=();

our $VERSION = '0.04';
our $setproctitle_so=$INC{'Sys/Proctitle.pm'};
$setproctitle_so=~s!/Sys/Proctitle\.pm$!/auto/Sys/Proctitle/setproctitle.so!
  unless( $setproctitle_so=~s!blib/lib/Sys/Proctitle\.pm$!blib/arch/auto/Sys/Proctitle/setproctitle.so! and
	  -f $setproctitle_so and -r _ );

require XSLoader;
XSLoader::load('Sys::Proctitle', $VERSION);

sub getproctitle;
sub setproctitle;

sub new {
  my $class=ref($_[0]) || $_[0];
  my $I=bless do{\my $dummy}=>$class;

  $$I=getproctitle;
  setproctitle( @_[1..$#_] );

  return $I;
}

sub DESTROY {
  my ($I)=@_;
  setproctitle( $$I ) if( length $$I );
}

1;
__END__

=head1 NAME

Sys::Proctitle - modify proctitle on Linux

=head1 SYNOPSIS

  use Sys::Proctitle qw/:all/;
  setproctitle( "my new title" );
  setproctitle( qw/my new title/ );
  $s=getproctitle;

 or

  {
    # set proctitle while in block
    my $proctitle=Sys::Proctitle->new( 'my new title' );
    ...
  }

=head1 DESCRIPTION

C<Sys::Proctitle> provides an interface for setting the process title shown
by C<ps>, C<top> or similar tools on Linux. Why do we need this? One could
simply change C<$0> to achieve the same result.  Well, first setting C<$0>
did not work with 5.8.0. Further, setting $0 won't work with mod_perl.

=head2 Procedural Interface

=over 4

=item I<setproctitle( arg1, arg2, ... argN )>

all arguments are joined with C<\0>. The resulting string is set as process
title.

=item I<getproctitle()>

returns the current process title. On Linux the space useable as process
title consists of the original space for argv the process was executed
with plus the space of the original environment. This function returns the
current content of this buffer.

The length of the returned string is the maximum process title length.

=back

=head2 Object Interface

=over 4

=item I<new( arg1, arg2, ... argN )>

the current process title is saved. Then the arguments are passed to
C<setproctitle>.

=item I<DESTROY()>

restores the saved process title.

=back

=head1 EXPORT

None by default.

On demand C<setproctitle> and C<getproctitle> are exported.

The C<:all> Exporter tag exports C<setproctitle> and C<getproctitle>.

=head1 SEE ALSO

L<Apache::ShowStatus>

=head1 AUTHOR

Torsten Foertsch, E<lt>torsten.foertsch@gmx.netE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2004 by Torsten Foertsch

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.


=cut
