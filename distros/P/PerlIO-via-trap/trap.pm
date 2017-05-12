package PerlIO::via::trap;
require Exporter;
@ISA = 'Exporter';
@EXPORT = 'open';
$VERSION = '0.09';

use strict;
use Carp;
use IO::Handle;

our $PASS = 0;

sub PUSHED { bless \*PUSHED,$_[0] }
sub FILL { readline( $_[1] ) }

sub SEEK {
    seek $_[3], $_[1], $_[2];
    return 0;
} #SEEK

sub WRITE {
    my ($obj, $buf, $fh) = @_;
    confess "attempt to write ".length($_[1])."bytes to $_[2]" unless $PASS;
    $fh->print($buf);
} #WRITE

sub import {
    my $pkg = shift;
    return unless @_;
    my $sym = shift;
    $pkg->export('CORE::GLOBAL', $sym, @_);
}

sub open (*;@) {
    no strict 'refs';
    my $fh = $_[0] ? *{caller()."::$_[0]"} : $_[0];
    my ($mode, $file) = @_[1,2];

    unless (defined $file) {
	($mode, $file) = ($mode =~ /^(\+?(?:<|>>?|\|)?)(.+)$/);
	# XXX: should we take care of > here to avoid truncation?
	$mode ||= '<';
    }

    my $ret = CORE::open($fh, $mode, $file);
    binmode $fh, ':via(trap)';
    $_[0] ||= $fh;
    $ret;
}

1;
__END__

=head1 NAME

PerlIO::via::trap - PerlIO layer to trap write

=head1 SYNOPSIS

 use PerlIO::via::trap;

 open( my $in,'<:via(trap)','file.txt' );	# no effect
 open( my $out,'>:via(trap)','file.txt' );	# write will cause confess

 use PerlIO::via::trap ('open');		# auto trap

 $PerlIO::via::trap::PASS = 1;			# disable trap

=head1 DESCRIPTION

This module implements a PerlIO layer that captures attemps to write
to files. This is especially useful for debugging modules that
are corrupting files.

=head1 CAVEATS

Note that the PERLIO environment variable does not work with :via
modules, so you need to override core::open if you don't want to
change the modules are you trying to fix.

=head1 SEE ALSO

L<PerlIO::via>

=head1 AUTHORS

Chia-liang Kao E<lt>clkao@clkao.orgE<gt>

=head1 COPYRIGHT

Copyright 2002 by Chia-liang Kao E<lt>clkao@clkao.orgE<gt>.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See L<http://www.perl.com/perl/misc/Artistic.html>

=cut
