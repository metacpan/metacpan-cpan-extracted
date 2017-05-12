package RunApp::Control;
use strict;
use base qw(RunApp::Base);

AUTOLOAD {
  our $AUTOLOAD;
  my ($cmd) = $AUTOLOAD =~ m/:?(\w+)$/;
  return unless $cmd =~ m/[a-z]/;
  my $self = shift;
  $self->dispatch ($cmd, @_);
}

# abstract
sub dispatch {
    die "This must be implemented by child.";
}

=head1 NAME

RunApp::Control - Control class for RunApp

=head1 SYNOPSIS

 use base 'RunApp::Control'

=head1 DESCRIPTION

The class is not intended for direct use.  It provides a C<AUTOLOAD>
function that delegates calls to the C<dispatch> method.

=head1 SEE ALSO

L<RunApp>

=head1 AUTHORS

Chia-liang Kao <clkao@clkao.org>

Refactored from works by Leon Brocard E<lt>acme@astray.comE<gt> and
Tom Insam E<lt>tinsam@fotango.comE<gt>.

=head1 COPYRIGHT

Copyright (C) 2002-5, Fotango Ltd.

This module is free software; you can redistribute it or modify it
under the same terms as Perl itself.

=cut

1;
