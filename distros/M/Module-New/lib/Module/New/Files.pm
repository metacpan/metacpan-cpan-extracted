package Module::New::Files;

use strict;
use warnings;

sub new { bless [], shift; }

sub add {
  my $self = shift;
  push @{ $self }, @_ if @_;
}

sub next  {
  my $self = shift;
  shift @{ $self };
}

sub clear {
  my $self = shift;
  @{ $self } = [];
}

1;

__END__

=head1 NAME

Module::New::Files

=head1 DESCRIPTION

Queue used internally to store which files to be created.

=head1 METHODS

=head2 new

creates an object.

=head2 add

add files.

=head2 next

returns the first file left in the queue.

=head2 clear

clears the queue.

=head1 AUTHOR

Kenichi Ishigaki, E<lt>ishigaki@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009 by Kenichi Ishigaki.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
