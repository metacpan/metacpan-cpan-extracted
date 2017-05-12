package POE::Declare::Meta::Message;

=pod

=head1 NAME

POE::Declare::Meta::Message - A named message that is emitted to the parent

=head1 SYNOPSIS

  # Declare the message (in the child)
  declare ShutdownComplete => 'Message';
  
  # Emit the message (in the child)
  $self->send_message('ShutdownComplete', 'param');
  
  # Register for the message (in the parent)
  my $child = Foo::Child->new(
      ShutdownComplete => $self->lookback('child_completed'),
  );

=head1 DESCRIPTION

Each L<POE::Declare> object contains a series of declared messages.

Message registration is done (primarily) during object creation, and
the parameter checking for each message parameter is checked in a defined
way.

=cut

use 5.008007;
use strict;
use warnings;
use POE::Declare::Meta::Param ();

use vars qw{$VERSION @ISA};
BEGIN {
	$VERSION = '0.59';
	@ISA     = 'POE::Declare::Meta::Param';
}

sub as_perl { <<"END_PERL" }
sub $_[0]->{name} {
	\$_[0]->{$_[0]->{name}} or return '';
	\$_[0]->{$_[0]->{name}}->( \$_[0]->{Alias}, \@_[1..\$#_] );
	return 1;
}
END_PERL

1;

=pod

=head1 SUPPORT

Bugs should be always be reported via the CPAN bug tracker at

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=POE-Declare>

For other issues, or commercial enhancement or support, contact the author.

=head1 AUTHORS

Adam Kennedy E<lt>adamk@cpan.orgE<gt>

=head1 SEE ALSO

L<POE>, L<POE::Declare>

=head1 COPYRIGHT

Copyright 2006 - 2012 Adam Kennedy.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
