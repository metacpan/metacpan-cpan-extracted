package Module::New::Queue;

use strict;
use warnings;

our $QUEUE = [];

sub localize {
  my ($class, $code) = @_;

  local $QUEUE = [];
  $code->();
}

sub register {
  my ($class, $code) = @_;

  push @{ $QUEUE }, $code;
}

sub consume {
  my ($class, @args) = @_;

  while ( my $func = shift @{ $QUEUE } ) {
    $func->( @args );
  }
}

sub queue { @{ $QUEUE } }
sub clear { $QUEUE = [] }

1;

__END__

=head1 NAME

Module::New::Queue

=head1 SYNOPSIS

  use Module::New::Queue;

  Module::New::Queue->register(sub { print "global\n" });
  Module::New::Queue->localize(sub {
    Module::New::Queue->register(sub { print "local\n" });
    Module::New::Queue->consume(@args); # consume local queue
  });
  Module::New::Queue->consume(@args); # consume global queue

=head1 DESCRIPTION

Used internally to register commands.

=head1 METHODS

=head2 localize

runs a code reference with a localized queue.

=head2 register

register a code reference to the queue.

=head2 consume

consumes the code references in the queue.

=head2 queue

returns an array of the registered code references.

=head2 clear

clears the queue.

=head1 AUTHOR

Kenichi Ishigaki, E<lt>ishigaki@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009 by Kenichi Ishigaki.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
