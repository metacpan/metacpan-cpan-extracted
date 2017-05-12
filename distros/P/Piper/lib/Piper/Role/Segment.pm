#####################################################################
## AUTHOR: Mary Ehlers, regina.verbae@gmail.com
## ABSTRACT: Base role for pipeline segments
#####################################################################

package Piper::Role::Segment;

use v5.10;
use strict;
use warnings;

use Types::Standard qw(Bool CodeRef HashRef InstanceOf);
use Types::Common::Numeric qw(PositiveInt PositiveOrZeroNum);
use Types::Common::String qw(NonEmptySimpleStr);

use Moo::Role;

our $VERSION = '0.04'; # from Piper-0.04.tar.gz

#pod =head1 DESCRIPTION
#pod
#pod This role contains attributes and methods that apply to each pipeline segment, both individual process handlers (L<Piper::Process>) and pipelines (L<Piper>).
#pod
#pod =head1 REQUIRES
#pod
#pod =head2 init
#pod
#pod This role requires the definition of an C<init> method which initializes the segment as a pipeline instance and prepares it for data processing.  The method must return the created pipeline instance.
#pod
#pod =cut

requires 'init';

around init => sub {
    my ($orig, $self, @args) = @_;
    state $call = 0;
    $call++;
    # The first time this is called (per Piper object)
    #   will be from the main (or top-level) pipeline
    #   segment
    my $main = $call == 1 ? 1 : 0;

    my $instance = $self->$orig();

    if ($main) {
        # Set the args in the main instance
        $instance->_set_args(\@args);

        # Reset $call so any other Piper objects can
        #   determine their main segment
        $call = 0;
    }

    return $instance;
};

#pod =head1 ATTRIBUTES
#pod
#pod =head2 allow
#pod
#pod An optional coderef used to subset the items which are I<allowed> to be processed by the segment.
#pod
#pod The coderef runs on each item attempting to queue to the segment.  If it returns true, the item is queued.  Otherwise, the item skips the segment and proceeds to the next adjacent segment.
#pod
#pod Each item is localized to C<$_>, and is also passed in as the first argument.  These example C<allow> subroutines are equivalent:
#pod
#pod     # This segment only accepts digit inputs
#pod     sub { /^\d+$/ }
#pod     sub { $_ =~ /^\d+$/ }
#pod     sub { $_[0] =~ /^\d+$/ }
#pod
#pod =cut

has allow => (
    is => 'ro',
    isa => CodeRef,
    # Closure to enable sub to use $_ instead of $_[0],
    #   though $_[0] will also work
    coerce => sub {
        my $orig = shift;
        CodeRef->assert_valid($orig);
        return sub {
            my $item = shift;
            local $_ = $item;
            $orig->($item);
        };
    },
    predicate => 1,
);

#pod =head2 batch_size
#pod
#pod The number of items to process at a time for the segment.  Once initialized, a segment inherits the C<batch_size> of its parent(s) if not provided.
#pod
#pod =cut

has batch_size => (
    is => 'rw',
    isa => PositiveInt,
    required => 0,
    predicate => 1,
    clearer => 1,
);

#pod =head2 config
#pod
#pod A L<Piper::Config> object defining component classes and global defaults.
#pod
#pod This attribute is set according to the import options provided to S<C<use Piper>>.
#pod
#pod =cut

has config => (
    is => 'lazy',
    isa => InstanceOf['Piper::Config'],
    builder => sub { require Piper::Config; return Piper::Config->new() },
);

#pod =head2 debug
#pod
#pod Debug level for this segment.
#pod
#pod =cut

has debug => (
    is => 'rw',
    isa => PositiveOrZeroNum,
    required => 0,
    predicate => 1,
    clearer => 1,
);

#pod =head2 enabled
#pod
#pod Boolean indicating that the segment is enabled and can accept items for processing.  Defaults to true.
#pod
#pod =cut

has enabled => (
    is => 'rw',
    isa => Bool,
    coerce => sub { $_[0] ? 1 : 0 },
    required => 0,
    predicate => 1,
    clearer => 1,
);

#pod =head2 id
#pod
#pod A globally unique ID for the segment.  This is primarily useful for debugging only.
#pod
#pod =cut

has id => (
    is => 'ro',
    isa => NonEmptySimpleStr,
    builder => sub {
        my ($self) = @_;
        state $id = {};
        my $base = ref $self;
        $id->{$base}++;
        return "$base$id->{$base}";
    },
);

#pod =head2 label
#pod
#pod A label for this segment.  If no label is provided, the segment's id will be used.
#pod
#pod Labels are necessary if any handlers wish to use the C<injectAt> or C<injectAfter> methods (described in L<Piper> or L<Piper::Process> documentation).  Otherwise, labels are primarily useful for logging and/or debugging (see L<Piper::Logger>).
#pod
#pod =cut

has label => (
    is => 'rwp',
    isa => NonEmptySimpleStr,
    lazy => 1,
    builder => sub {
        my $self = shift;
        return $self->id;
    },
);

#pod =head2 verbose
#pod
#pod Verbosity level for this segment.
#pod
#pod =cut

has verbose => (
    is => 'rw',
    isa => PositiveOrZeroNum,
    required => 0,
    predicate => 1,
    clearer => 1,
);

#pod =head1 METHODS
#pod
#pod =head2 clear_batch_size
#pod
#pod Clears any assigned C<batch_size> for the segment.
#pod
#pod =head2 clear_debug
#pod
#pod Clears any assigned C<debug> level for the segment.
#pod
#pod =head2 clear_enabled
#pod
#pod Clears any assigned C<enabled> setting for the segment.
#pod
#pod =head2 clear_verbose
#pod
#pod Clears any assigned C<verbose> level for the segment.
#pod
#pod =head2 has_allow
#pod
#pod A boolean indicating whether or not an C<allow> attribute exists for this segment.
#pod
#pod =head2 has_batch_size
#pod
#pod A boolean indicating whether the segment has an assigned C<batch_size>.
#pod
#pod =head2 has_debug
#pod
#pod A boolean indicating whether the segment has an assigned C<debug> level.
#pod
#pod =head2 has_enabled
#pod
#pod A boolean indicating whether the segment has an assigned C<enabled> setting.
#pod
#pod =head2 has_verbose
#pod
#pod A boolean indicating whether the segment has an assigned C<verbose> level.
#pod
#pod =cut

1;

__END__

=pod

=for :stopwords Mary Ehlers Heaney Tim

=head1 NAME

Piper::Role::Segment - Base role for pipeline segments

=head1 DESCRIPTION

This role contains attributes and methods that apply to each pipeline segment, both individual process handlers (L<Piper::Process>) and pipelines (L<Piper>).

=head1 REQUIRES

=head2 init

This role requires the definition of an C<init> method which initializes the segment as a pipeline instance and prepares it for data processing.  The method must return the created pipeline instance.

=head1 ATTRIBUTES

=head2 allow

An optional coderef used to subset the items which are I<allowed> to be processed by the segment.

The coderef runs on each item attempting to queue to the segment.  If it returns true, the item is queued.  Otherwise, the item skips the segment and proceeds to the next adjacent segment.

Each item is localized to C<$_>, and is also passed in as the first argument.  These example C<allow> subroutines are equivalent:

    # This segment only accepts digit inputs
    sub { /^\d+$/ }
    sub { $_ =~ /^\d+$/ }
    sub { $_[0] =~ /^\d+$/ }

=head2 batch_size

The number of items to process at a time for the segment.  Once initialized, a segment inherits the C<batch_size> of its parent(s) if not provided.

=head2 config

A L<Piper::Config> object defining component classes and global defaults.

This attribute is set according to the import options provided to S<C<use Piper>>.

=head2 debug

Debug level for this segment.

=head2 enabled

Boolean indicating that the segment is enabled and can accept items for processing.  Defaults to true.

=head2 id

A globally unique ID for the segment.  This is primarily useful for debugging only.

=head2 label

A label for this segment.  If no label is provided, the segment's id will be used.

Labels are necessary if any handlers wish to use the C<injectAt> or C<injectAfter> methods (described in L<Piper> or L<Piper::Process> documentation).  Otherwise, labels are primarily useful for logging and/or debugging (see L<Piper::Logger>).

=head2 verbose

Verbosity level for this segment.

=head1 METHODS

=head2 clear_batch_size

Clears any assigned C<batch_size> for the segment.

=head2 clear_debug

Clears any assigned C<debug> level for the segment.

=head2 clear_enabled

Clears any assigned C<enabled> setting for the segment.

=head2 clear_verbose

Clears any assigned C<verbose> level for the segment.

=head2 has_allow

A boolean indicating whether or not an C<allow> attribute exists for this segment.

=head2 has_batch_size

A boolean indicating whether the segment has an assigned C<batch_size>.

=head2 has_debug

A boolean indicating whether the segment has an assigned C<debug> level.

=head2 has_enabled

A boolean indicating whether the segment has an assigned C<enabled> setting.

=head2 has_verbose

A boolean indicating whether the segment has an assigned C<verbose> level.

=head1 SEE ALSO

=over

=item L<Piper>

=item L<Piper::Process>

=item L<Piper::Instance>

=item L<Piper::Logger>

=item L<Piper::Config>

=back

=head1 VERSION

version 0.04

=head1 AUTHOR

Mary Ehlers <ehlers@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2017 by Mary Ehlers.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
