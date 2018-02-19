#####################################################################
## AUTHOR: Mary Ehlers, regina.verbae@gmail.com
## ABSTRACT: Configuration object for Piper
#####################################################################

package Piper::Config;

use v5.10;
use strict;
use warnings;

use Carp;
use Types::Common::Numeric qw(PositiveInt);
use Types::LoadableClass qw(ClassDoes);
use Types::Standard qw(ClassName);

use Moo;
use namespace::clean;

our $VERSION = '0.05'; # from Piper-0.05.tar.gz

#pod =head1 SYNOPSIS
#pod
#pod =for stopwords queueing
#pod
#pod   # Defaults
#pod   use Piper (
#pod       batch_size   => 200,
#pod       logger_class => 'Piper::Logger',
#pod       queue_class  => 'Piper::Queue',
#pod   );
#pod
#pod =head1 DESCRIPTION
#pod
#pod A configuration object, instantiated during import of the L<Piper> module according to any supplied import arguments.
#pod
#pod =head1 ATTRIBUTES
#pod
#pod =head2 batch_size
#pod
#pod The default batch size used by pipeline segments which do not have a locally defined C<batch_size> and do not have a parent segment with a defined C<batch_size>.
#pod
#pod The C<batch_size> attribute must be a positive integer.
#pod
#pod The default C<batch_size> is 200.
#pod
#pod =cut

has batch_size => (
    is => 'lazy',
    isa => PositiveInt,
    default => 200,
);

#pod =head2 logger_class
#pod
#pod The logger class is used for printing debug and info statements, issuing warnings, and throwing
#pod errors.
#pod
#pod The C<logger_class> attribute must be a valid class that does the role defined by L<Piper::Role::Logger>.
#pod
#pod The default C<logger_class> is L<Piper::Logger>.
#pod
#pod =cut

has logger_class => (
    is => 'lazy',
    isa => ClassDoes['Piper::Role::Logger'],
    default => 'Piper::Logger',
);

#pod =head2 queue_class
#pod
#pod The queue class handles the queueing of data for each of the pipeline segments.
#pod
#pod The C<queue_class> attribute must be a valid class that does the role defined by L<Piper::Role::Queue>.
#pod
#pod The default C<queue_class> is L<Piper::Queue>.
#pod
#pod =cut

has queue_class => (
    is => 'lazy',
    isa => ClassDoes['Piper::Role::Queue'],
    default => 'Piper::Queue',
);

1;

__END__

=pod

=for :stopwords Mary Ehlers Heaney Tim queueing

=head1 NAME

Piper::Config - Configuration object for Piper

=head1 SYNOPSIS

  # Defaults
  use Piper (
      batch_size   => 200,
      logger_class => 'Piper::Logger',
      queue_class  => 'Piper::Queue',
  );

=head1 DESCRIPTION

A configuration object, instantiated during import of the L<Piper> module according to any supplied import arguments.

=head1 ATTRIBUTES

=head2 batch_size

The default batch size used by pipeline segments which do not have a locally defined C<batch_size> and do not have a parent segment with a defined C<batch_size>.

The C<batch_size> attribute must be a positive integer.

The default C<batch_size> is 200.

=head2 logger_class

The logger class is used for printing debug and info statements, issuing warnings, and throwing
errors.

The C<logger_class> attribute must be a valid class that does the role defined by L<Piper::Role::Logger>.

The default C<logger_class> is L<Piper::Logger>.

=head2 queue_class

The queue class handles the queueing of data for each of the pipeline segments.

The C<queue_class> attribute must be a valid class that does the role defined by L<Piper::Role::Queue>.

The default C<queue_class> is L<Piper::Queue>.

=head1 SEE ALSO

=over

=item L<Piper>

=item L<Piper::Logger>

=item L<Piper::Queue>

=item L<Piper::Role::Logger>

=item L<Piper::Role::Queue>

=back

=head1 VERSION

version 0.05

=head1 AUTHOR

Mary Ehlers <ehlers@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2017 by Mary Ehlers.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
