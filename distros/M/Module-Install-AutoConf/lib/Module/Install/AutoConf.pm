package Module::Install::AutoConf;

use 5.005;
use strict;
use Module::Install::Base;
use Carp ();

=head1 NAME

Module::Install::AutoConf - tools to intigrate Module::Install with the
Gnu autoconf tools

=head1 VERSION

0.001

=cut

use vars qw{$VERSION $ISCORE @ISA};
BEGIN {
  $VERSION = '0.001';
  $ISCORE  = 0;
  @ISA     = qw{Module::Install::Base};
}

=head1 COMMANDS

This plugin adds the following Module::Install commands:

=head2 makefile

  makefile('pmakefile');

Change the name of the makefile to 'pamakefile'.

=cut

sub makefile {
  my ($self, $name) = @_;
  _makefile($self, $name);
}

sub _makefile {
  my ($self, $name) = @_;
  $name //= 'pmakefile';
  $self->makemaker_args->{FIRST_MAKEFILE} = $name;
}

=head1 HOW IT WORKS

=head1 BUGS

Please report any bugs or feature requests through the web interface at
L<http://rt.cpan.org>. I will be notified, and then you'll automatically be
notified of progress on your bug as I make changes.

=head1 COPYRIGHT

Copyright 2011, G. Allen Morris III.  This program is free software;  you can
redistribute it and/or modify it under the same terms as Perl itself.

=cut

1;
