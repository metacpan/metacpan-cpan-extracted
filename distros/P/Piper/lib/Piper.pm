#####################################################################
## AUTHOR: Mary Ehlers, regina.verbae@gmail.com
## ABSTRACT: Flexible, iterable pipeline engine with automatic batching
#####################################################################

package Piper;

use v5.10;
use strict;
use warnings;

use Carp;
use Piper::Instance;
use Piper::Process;
use Types::Standard qw(ArrayRef ConsumerOf Tuple slurpy);

use Moo;
use namespace::clean;

with qw(Piper::Role::Segment);

use overload (
    q{""} => sub { $_[0]->label },
    fallback => 1,
);

our $VERSION = '0.04'; # from Piper-0.04.tar.gz

my $CONFIG;

sub import {
    my $class = shift;
    if (@_) {
        require Piper::Config;
        $CONFIG = Piper::Config->new(@_);
    }
}

#pod =head1 SYNOPSIS
#pod
#pod =for stopwords clearers dataflow injectAfter iterable mentorship queueing
#pod
#pod     use Piper;
#pod
#pod     my $pipeline = Piper->new(
#pod         first_process => sub {
#pod             my ($instance, $batch) = @_;
#pod             $instance->emit( map { ... } @$batch );
#pod         },
#pod         second_processes => Piper->new(...),
#pod         final_process => sub { ... },
#pod     )->init;
#pod
#pod     $pipeline->enqueue(@data);
#pod
#pod     while ($pipeline->isnt_exhausted) {
#pod         my $item = $pipeline->dequeue;
#pod         ...
#pod     }
#pod
#pod =head1 DESCRIPTION
#pod
#pod The software engineering concept known as a pipeline is a chain of processing segments, arranged such that the output of each segment is the input of the next.
#pod
#pod L<Piper> is a pipeline builder.  It composes arbitrary processing segments into a single pipeline instance with the following features:
#pod
#pod =over
#pod
#pod =item *
#pod
#pod Pipeline instances are iterators, only processing data as needed.
#pod
#pod =item *
#pod
#pod Data is automatically processed in batches for each segment (with configurable batch sizes).
#pod
#pod =item *
#pod
#pod Built-in support exists for non-linear and/or recursive pipelines.
#pod
#pod =item *
#pod
#pod Processing segments are pluggable and reusable.
#pod
#pod =back
#pod
#pod =head1 CONSTRUCTOR
#pod
#pod =head2 new(@segments)
#pod
#pod Create a container pipeline segment (parent) from the provided child C<@segments>.
#pod
#pod Additionally, a single hashref of attributes for the container/parent segment may be included as an argument to the constructor (anywhere in the argument list). See the L</SEGMENT ATTRIBUTES> section for a description of attributes available for both parent and child segments.
#pod
#pod Accepted segment types are as follows:
#pod
#pod =over
#pod
#pod =item L<Piper> object
#pod
#pod Creates a sub-container of pipeline segments.  There is no (explicit) limit to the number of nested containers a pipeline may contain.
#pod
#pod =item L<Piper::Process|/PROCESS HANDLER> object
#pod
#pod See the L</PROCESS HANDLER> section for a description of L<Piper::Process> objects.
#pod
#pod =item A coderef (which will be coerced into a L<Piper::Process> object).
#pod
#pod =item A hashref that can be coerced into a L<Piper::Process> object.
#pod
#pod In order to be considered a candidate for coercion, the hashref must contain (at a minimum) the 'handler' key.
#pod
#pod =item L<Piper::Instance|/INITIALIZATION> object
#pod
#pod In this case, the associated L<Piper> or L<Piper::Process> object is extracted from the L<Piper::Instance> object for use in the new pipeline segment.
#pod
#pod See L</INITIALIZATION> for a description of L<Piper::Instance> objects.
#pod
#pod =item A C<< $label => $segment >> pair
#pod
#pod For such pairs, the C<$segment> can be any of the above segment types, and C<$label> is a simple scalar which will be used as C<$segment>'s label.
#pod
#pod If the C<$segment> already has a label, C<$label> will override it.
#pod
#pod =back
#pod
#pod =head2 Constructor Example
#pod
#pod     my $pipe = Piper->new(
#pod         \%main_opts,
#pod         subpipe_label => Piper->new(
#pod             first_handler => Piper::Process->new(sub { ... }),
#pod             second_handler => sub { ... },
#pod             third_handler => {
#pod                 handler => sub { ... },
#pod             },
#pod             another_subpipe => Piper->new(...),
#pod             \%subpipe_opts,
#pod         ),
#pod         Piper::Process->new({
#pod             label => 'another_handler',
#pod             handler => sub { ... },
#pod         }),
#pod         sub {
#pod             # An un-labeled handler
#pod             ...
#pod         },
#pod         {
#pod             label => 'final_handler',
#pod             handler => sub { ... },
#pod         },
#pod     );
#pod
#pod =head1 INITIALIZATION
#pod
#pod Piper segments were designed to be easily reusable.  Prior to initialization, L<Piper> and L<Piper::Process> objects do not process data; they simply contain the blueprint for creating the pipeline.  As such, blueprints for commonly-used pipeline segments can be stored in package libraries and imported wherever needed.
#pod
#pod To create a functioning pipeline from one such blueprint, simply call the C<init> method on the outermost segment.  The C<init> method returns a L<Piper::Instance> object of the outermost segment, which is the realization of the pipeline design, and which contains L<Piper::Instance> objects created from all its contained segments.
#pod
#pod Initialization fuses the pipeline segments together, establishes the relationships between the segments, and initializes the dataflow infrastructure.
#pod
#pod The C<init> method may be chained from the constructor if the blueprint object is not needed:
#pod
#pod     my $instance = Piper->new(...)->init;
#pod
#pod Any arguments passed to the C<init> method will be cached and made available to each handler in the pipeline (see the L</PROCESS HANDLER> section for full description of handlers).  This is a great way to share a resource (such as a database handle) among process handlers.
#pod
#pod     my $pipe = Piper->new(
#pod         query => sub {
#pod             my ($instance, $batch, $dbh) = @_;
#pod             $instance->emit(
#pod                 $dbh->do_query(@$batch)
#pod             );
#pod         },
#pod         ...
#pod     );
#pod     my $instance = $pipe->init($dbh);
#pod
#pod Instances are ready to accept data for processing:
#pod
#pod     $instance->enqueue(@data);
#pod     while ($instance->isnt_exhausted) {
#pod         my $result = $instance->dequeue;
#pod     }
#pod
#pod =head1 PROCESS HANDLER
#pod
#pod L<Piper::Process> objects have the same L</SEGMENT ATTRIBUTES> as L<Piper> objects, but have an additional required attribute known as its C<handler>.
#pod
#pod A process C<handler> is the data-processing subroutine for the segment.
#pod
#pod In its simplest form, the process handler takes input from the previous pipeline segment, processes it, and passes it on to the next segment; but handlers also have built-in support for non-linear and recursive dataflow (see L</FLOW CONTROL>).
#pod
#pod The arguments provided to the C<handler> subroutine are:
#pod
#pod =over
#pod
#pod =item C<$instance>
#pod
#pod The instance (a L<Piper::Instance> object) corresponding to the segment.
#pod
#pod =item C<$batch>
#pod
#pod An arrayref of data items to process.
#pod
#pod =item C<@args>
#pod
#pod Any arguments provided to the C<init> method during the L</INITIALIZATION> of the pipeline.
#pod
#pod =back
#pod
#pod After processing a batch of data, the C<handler> may pass the results to the next segment using the C<emit> method called from the handler's C<$instance>.
#pod
#pod =head2 Example:
#pod
#pod     sub {
#pod         my ($instance, $batch) = @_;
#pod         $instance->emit( map { ... } @$batch );
#pod     }
#pod
#pod =head1 FLOW CONTROL
#pod             
#pod Since L<Piper> has built-in support for non-linear and/or recursive pipelines, a L</PROCESS HANDLER> may send data to any other segment in the pipeline, including itself.
#pod
#pod The following methods may be called from the C<$instance> object passed as the first argument to a C<handler>:
#pod
#pod =head2 emit(@data)
#pod
#pod Send C<@data> to the next segment in the pipeline.  If the instance is the last in the pipeline, emits to the drain, making the C<@data> ready for C<dequeue>.
#pod
#pod =head2 recycle(@data)
#pod
#pod Re-queue C<@data> to the top of the current segment in an order such that C<dequeue(1)> would subsequently return C<$data[0]> and so forth.
#pod
#pod =head2 injectAt($location, @data)
#pod
#pod =head2 injectAfter($location, @data)
#pod
#pod Send C<@data> to the segment I<at> or I<after> the specified C<$location>.
#pod
#pod For each of the above methods, C<$location> must be the label of a segment in the pipeline or a path-like representation of an hierarchy of labels.
#pod
#pod For example, in the following pipeline, a few possible C<$location> values include C<a>, C<subpipe/b>, or C<main/subpipe/c>.
#pod
#pod     my $pipe = Piper->new(
#pod         { label => 'main' },
#pod         subpipe => Piper->new(
#pod             a => sub { ... },
#pod             b => sub { ... },
#pod             c => sub { ... },
#pod         ),
#pod     );
#pod
#pod If a label is unique within the pipeline, only the label is required.  For non-unique labels, searches are performed in a nearest-neighbor, depth-first manner.
#pod
#pod For example, in the following pipeline, searching for C<processA> from the handler of C<processB> would find C<main/pipeA/processA>, not C<main/processA>.  So to reach C<main/processA> from C<processB>, the handler would need to search for C<main/processA>.
#pod
#pod     my $pipe = Piper->new(
#pod         { label => 'main' },
#pod         pipeA => Piper->new(
#pod             processA => sub { ... },
#pod             processB => sub { ... },
#pod         ),
#pod         processA => sub { ... },
#pod     );
#pod
#pod =head2 inject(@data)
#pod
#pod If the segment has a parent, enqueues C<@data> to its parent.  Otherwise, enqueues C<@data> to itself.
#pod
#pod =head2 eject(@data)
#pod
#pod If the segment has a parent, send C<@data> to the drain of its parent.  Otherwise, enqueues C<@data> to the segment's drain.
#pod
#pod =head1 SEGMENT ATTRIBUTES
#pod
#pod All of the following attributes are available for both container (L<Piper>) and processor (L<Piper::Process>) segment types.
#pod
#pod Each attribute is equipped with an accessor of the same name.
#pod
#pod A star (*) indicates that the attribute is writable, and can be modified at runtime by passing a value as an argument to the method of the same name.
#pod
#pod All attributes (except C<label>) have an associated predicate method called C<has_$attribute> which returns a boolean indicating whether the attribute has been set for the segment.
#pod
#pod All writable attributes (indicated by *) can be cleared by passing an explicit C<undef> to the writer method or by calling the appropriate clearer method called C<clear_$attribute>.
#pod
#pod All accessors, writers, predicates, and clearers are available for each segment before and after L</INITIALIZATION>.
#pod
#pod =head2 allow
#pod
#pod A coderef which can be used to subset the items which are I<allowed> to be processed by the segment.
#pod
#pod The coderef executes on each item attempting to queue to the segment.  If it returns true, the item is queued.  Otherwise, the item skips the segment and proceeds to the next adjacent segment.
#pod
#pod Each item is localized to C<$_>, and is also passed in as the first argument.
#pod
#pod These example C<allow> subroutines are equivalent:
#pod
#pod     # This segment only accepts digit inputs
#pod     allow => sub { /^\d+$/ }
#pod     allow => sub { $_ =~ /^\d+$/ }
#pod     allow => sub { $_[0] =~ /^\d+$/ }
#pod
#pod =head2 *batch_size
#pod
#pod The number of items to process at a time for the segment.
#pod
#pod Once initialized (see L</INITIALIZATION>), a segment inherits the C<batch_size> of any existing parent(s) if not provided.  If the segment has no parents, or if none of the parents have a C<batch_size> defined, the default C<batch_size> will be used.  The default C<batch_size> is 200, but can be configured in the import statement (see the L</GLOBAL CONFIGURATION> section).
#pod
#pod =head2 *debug
#pod
#pod The debug level for the segment.
#pod
#pod Once initialized (see L</INITIALIZATION>), a segment inherits the debug level of any existing parent(s) if not specified.  The default level is 0, but can be globally overridden by the environment variable C<PIPER_DEBUG>.
#pod
#pod See the L</LOGGING AND DEBUGGING> section for specifics about debug and verbosity levels.
#pod
#pod =head2 *enabled
#pod
#pod A boolean indicating that the segment is enabled and can accept items for processing.
#pod
#pod Once initialized (see L</INITIALIZATION>), a segment inherits this attribute from any existing parent(s).  The default is true.
#pod
#pod If a segment is disabled (C<enabled = 0>), all items attempting to queue to the segment are forwarded to the next adjacent segment.
#pod
#pod =head2 label
#pod
#pod A label for the segment.  If no label is provided, a globally unique ID will be used.
#pod
#pod Labels are necessary for certain types of L</FLOW CONTROL> (for example, L<injectAt> or L<injectAfter>).  For pipelines that do not utilize L</FLOW CONTROL> features, labels are primarily useful for L</LOGGING AND DEBUGGING>.
#pod
#pod =head2 *verbose
#pod
#pod The verbosity level for the segment.
#pod
#pod Once initialized (see L</INITIALIZATION>), a segment inherits the verbosity level of any existing parent(s) if not specified.  The default level is 0, but can be globally overridden by the environment variable C<PIPER_VERBOSE>.
#pod
#pod See the L</LOGGING AND DEBUGGING> section for specifics about debug and verbosity levels.
#pod
#pod =head2 INSTANCE ATTRIBUTES
#pod
#pod The following attributes have read-only accessors (of the same name).
#pod
#pod =head3 children
#pod
#pod For container instances (made from L<Piper> objects, not L<Piper::Process> objects), holds an arrayref of the contained instance objects.
#pod
#pod =head3 main
#pod
#pod For any instance in the pipeline, this attribute holds a reference to the outermost container instance.
#pod
#pod =head3 parent
#pod
#pod For all instances in the pipeline except the outermost container (C<main>), this attribute holds a reference to the instance's immediate container segment.
#pod
#pod =head3 path
#pod
#pod The full path to the instance, built as the concatenation of all the parent(s) labels and the instance's label, joined by C</>.  Instances stringify to this attribute.
#pod
#pod =head2 INSTANCE METHODS
#pod
#pod Methods marked with a (*) should only be called from the outermost instance.
#pod
#pod =head3 *dequeue([$num])
#pod
#pod Remove at most C<$num> S<(default 1)> processed items from the end of the pipeline.
#pod
#pod =head3 *enqueue(@data)
#pod
#pod Queue C<@data> for processing by the pipeline.
#pod
#pod =head3 find_segment($location)
#pod
#pod Find and return the segment instance according to C<$location>, which can be a label or a path-like hierarchy of labels.  See L<injectAfter|/injectAfter($location, @data)> for a detailed description of C<$location>.
#pod
#pod =head3 *flush
#pod
#pod Process batches until there are no more items pending.
#pod
#pod =head3 has_children
#pod
#pod A boolean indicating whether the instance has any children.
#pod
#pod =head3 has_parent
#pod
#pod A boolean indicating whether the instance has a parent.
#pod
#pod =head3 has_pending
#pod
#pod Returns a boolean indicating whether there are any items that are queued at some level of the segment but have not completed processing.
#pod
#pod =head3 *is_exhausted
#pod
#pod Returns a boolean indicating whether there are any items left to process or dequeue.
#pod
#pod =head3 *isnt_exhausted
#pod
#pod Returns the opposite of C<is_exhausted>.
#pod
#pod =head3 next_segment
#pod
#pod Returns the next adjacent segment from the calling segment.  Returns undef for the outermost container.
#pod
#pod =head3 pending
#pod
#pod Returns the number of items that are queued at some level of the pipeline segment but have not completed processing.
#pod
#pod =head3 *prepare([$num])
#pod
#pod Process batches while data is still C<pending> until at least C<$num> S<(default 1)> items are C<ready> for C<dequeue>.
#pod
#pod =head3 ready
#pod
#pod Returns the number of items that have finished processing and are ready for C<dequeue> from the pipeline segment.
#pod
#pod =head1 GLOBAL CONFIGURATION
#pod
#pod The following global attributes are configurable from the Piper import statement.
#pod
#pod     Ex:
#pod     # Change the default batch_size to 50
#pod     use Piper batch_size => 50;
#pod
#pod =head2 batch_size
#pod
#pod The default batch size used by pipeline segments which do not have a locally defined C<batch_size> and do not have a parent segment with a defined C<batch_size>.
#pod
#pod The C<batch_size> attribute must be a positive integer.
#pod
#pod The default C<batch_size> is 200.
#pod
#pod =head1 LOGGING AND DEBUGGING
#pod
#pod Logging and debugging facilities are available upon L</INITIALIZATION> of a pipeline.
#pod
#pod Warnings and errors are issued regardless of debug and verbosity levels via C<carp> and C<croak> from the L<Carp> module, and are therefore configurable with any of L<Carp>'s global options or environment variables.
#pod
#pod Debugging and/or informational messages are printed to STDERR if debug and/verbosity levels have been set.  There are three levels used by L<Piper> for each of C<debug>/C<verbose>: S<0, 1, or 2>.  The default is S<0 (off)>.
#pod
#pod =head2 Levels
#pod
#pod Levels can be set by any of the following mechanisms: at construction of the L<Piper>/L<Piper::Process> objects, dynamically via the C<debug> and C<verbose> methods of segments, or with the environment variables C<PIPER_DEBUG> and C<PIPER_VERBOSE>.
#pod
#pod Levels can be set local to specific segments.  The default levels of a sub-segment are inherited from its parent.
#pod
#pod     Ex:
#pod         # main                 verbose => 0 (default)
#pod         # main/subpipe         verbose => 1
#pod         # main/subpipe/normal  verbose => 1 (inherited)
#pod         # main/subpipe/loud    verbose => 2
#pod         # main/subpipe/quiet   verbose => 0
#pod
#pod         my $pipe = Piper->new(
#pod             { label => 'main' },
#pod             subpipe => Piper->new(
#pod                 { verbose => 1 },
#pod                 normal => sub {...},
#pod                 loud => {
#pod                     verbose => 2,
#pod                     handler => sub {...},
#pod                 },
#pod                 quiet => {
#pod                     verbose => 0,
#pod                     handler => sub {...},
#pod                 },
#pod             ),
#pod         );
#pod
#pod Levels set via the environment variables C<PIPER_DEBUG> and C<PIPER_VERBOSE> are global.  If set, these environment variables override any and all settings defined in the source code.
#pod
#pod =head2 Messages
#pod
#pod All messages include information about the segment which called the logger.
#pod
#pod Existing informational (C<verbose> or S<< C<debug> > 0 >>) messages describe data processing steps, such as noting when items are queueing or being processed by specific segments.  Increasing S<level(s) > 1> simply adds more detail to the printed messages.
#pod
#pod Existing debug messages describe the decision actions of the pipeline engine itself.  Examples include logging its search steps when locating a named segment or explaining how it chooses which batch to process.  Increasing the debug S<< level > 1 >> simply adds more detail to the printed messages.
#pod
#pod =head2 Custom messaging
#pod
#pod User-defined errors, warnings, and debug or informational messages can use the same logging system as L<Piper> itself.
#pod
#pod The first argument passed to a L</PROCESS HANDLER> is the L<Piper::Instance> object associated with that segment, which has the below-described methods available for logging, debugging, warning, or throwing errors.
#pod
#pod In each of the below methods, the C<@items> are optional and only printed if the verbosity level for the segment S<< is > 1 >>.  They can be used to pass additional context or detail about the data being processed or which caused the message to print (for conditional messages).
#pod
#pod The built-in messaging only uses debug/verbosity levels S<1 and 2>, but there are no explicit rules enforced on maximum debug/verbosity levels, so users may explicitly require higher levels for custom messages to heighten the required levels for any custom message.
#pod
#pod =head3 ERROR($message, [@items])
#pod
#pod Throws an error with C<$message> via C<croak>.
#pod
#pod =head3 WARN($message, [@items])
#pod
#pod Issues a warning with C<$message> via C<carp>.
#pod
#pod =head3 INFO($message, [@items])
#pod
#pod Prints an informational C<$message> to STDERR if either the debug or verbosity level for the segment S<< is > 0 >>.
#pod
#pod =head3 DEBUG($message, [@items])
#pod
#pod Prints a debug C<$message> to STDERR if the debug level for the segment S<< is > 0 >>.
#pod
#pod =head3 Example:
#pod
#pod     my $pipe = Piper->new(
#pod         messenger => sub {
#pod             my ($instance, $batch) = @_;
#pod             for my $data (@$batch) {
#pod                 if ($data->is_bad) {
#pod                     $instance->ERROR("Data <$data> is bad!");
#pod                 }
#pod             }
#pod             # User-heightened verbosity level
#pod             $instance->INFO('Data all good!', @$batch)
#pod                 if $instance->verbose > 2;
#pod             ...
#pod         },
#pod         ...
#pod     );
#pod
#pod =head1 ACKNOWLEDGEMENTS
#pod
#pod Much of the concept and API for this project was inspired by the work of L<Nathaniel Pierce|mailto:nwpierce@gmail.com>.
#pod
#pod Special thanks to L<Tim Heaney|http://oylenshpeegul.typepad.com> for his encouragement and mentorship.
#pod
#pod =cut

around BUILDARGS => sub {
    my ($orig, $self, @args) = @_;

    my $opts;
    my @children;
    my $label;
    for my $i (0..$#args) {
        # Label
        if (!ref $args[$i]) {
            croak 'ERROR: Label ('.($label // $args[$i]).') missing a segment'
                if defined $label or !exists $args[$i+1];
            $label = $args[$i];
            next;
        }

        # Options hash
        if (!defined $opts and ref $args[$i] eq 'HASH'
                # Options should not be labeled
                and !defined $label
                # Options shouldn't have a handler
                and !exists $args[$i]->{handler}
        ) {
            $opts = $args[$i];
            next;
        }

        # Segment
        my $thing = $args[$i];
        if (eval { $thing->isa('Piper') }
                or eval { $thing->isa('Piper::Process') }
        ) {
            $thing->_set_label($label) if $label;
            push @children, $thing;
        }
        elsif (eval { $thing->isa('Piper::Instance') }) {
            $thing = $thing->segment;
            $thing->_set_label($label) if $label;
            push @children, $thing;
        }
        elsif ((ref $thing eq 'CODE') or (ref $thing eq 'HASH')) {
            croak 'ERROR: Segment is missing a handler [ '
                    . ($label ? "label => $label" : "position => $i") . ' ]'
                if ref $thing eq 'HASH' and !exists $thing->{handler};

            $thing = Piper::Process->new(
                ($label ? $label : ()),
                $thing
            );
            push @children, $thing;
        }
        else {
            croak 'ERROR: Cannot coerce type ('.(ref $thing).') into a segment [ '
                . ($label ? "label => $label" : "position => $i") . ' ]';
        }

        undef $label;
    }

    croak 'ERROR: No segments provided to constructor' unless @children;

    $opts->{config} = $CONFIG if defined $CONFIG;

    return $self->$orig(
        %$opts,
        children => \@children,
    );
};

has children => (
    is => 'rwp',
    # Force to contain at least one child
    isa => Tuple[ConsumerOf['Piper::Role::Segment'],
        slurpy ArrayRef[ConsumerOf['Piper::Role::Segment']]
    ],
    required => 1,
);

sub init {
    my $self = shift;

    my $instance = Piper::Instance->new(
		segment => $self,
		children => [
			map { $_->init } @{$self->children}
		],
	);

    # Set parents for children
    for my $child (@{$instance->children}) {
        $child->_set_parent($instance);
    }

    return $instance;
}

1;

__END__

=pod

=for :stopwords Mary Ehlers Heaney Tim clearers dataflow injectAfter iterable mentorship
queueing

=head1 NAME

Piper - Flexible, iterable pipeline engine with automatic batching

=head1 SYNOPSIS

    use Piper;

    my $pipeline = Piper->new(
        first_process => sub {
            my ($instance, $batch) = @_;
            $instance->emit( map { ... } @$batch );
        },
        second_processes => Piper->new(...),
        final_process => sub { ... },
    )->init;

    $pipeline->enqueue(@data);

    while ($pipeline->isnt_exhausted) {
        my $item = $pipeline->dequeue;
        ...
    }

=head1 DESCRIPTION

The software engineering concept known as a pipeline is a chain of processing segments, arranged such that the output of each segment is the input of the next.

L<Piper> is a pipeline builder.  It composes arbitrary processing segments into a single pipeline instance with the following features:

=over

=item *

Pipeline instances are iterators, only processing data as needed.

=item *

Data is automatically processed in batches for each segment (with configurable batch sizes).

=item *

Built-in support exists for non-linear and/or recursive pipelines.

=item *

Processing segments are pluggable and reusable.

=back

=head1 CONSTRUCTOR

=head2 new(@segments)

Create a container pipeline segment (parent) from the provided child C<@segments>.

Additionally, a single hashref of attributes for the container/parent segment may be included as an argument to the constructor (anywhere in the argument list). See the L</SEGMENT ATTRIBUTES> section for a description of attributes available for both parent and child segments.

Accepted segment types are as follows:

=over

=item L<Piper> object

Creates a sub-container of pipeline segments.  There is no (explicit) limit to the number of nested containers a pipeline may contain.

=item L<Piper::Process|/PROCESS HANDLER> object

See the L</PROCESS HANDLER> section for a description of L<Piper::Process> objects.

=item A coderef (which will be coerced into a L<Piper::Process> object).

=item A hashref that can be coerced into a L<Piper::Process> object.

In order to be considered a candidate for coercion, the hashref must contain (at a minimum) the 'handler' key.

=item L<Piper::Instance|/INITIALIZATION> object

In this case, the associated L<Piper> or L<Piper::Process> object is extracted from the L<Piper::Instance> object for use in the new pipeline segment.

See L</INITIALIZATION> for a description of L<Piper::Instance> objects.

=item A C<< $label => $segment >> pair

For such pairs, the C<$segment> can be any of the above segment types, and C<$label> is a simple scalar which will be used as C<$segment>'s label.

If the C<$segment> already has a label, C<$label> will override it.

=back

=head2 Constructor Example

    my $pipe = Piper->new(
        \%main_opts,
        subpipe_label => Piper->new(
            first_handler => Piper::Process->new(sub { ... }),
            second_handler => sub { ... },
            third_handler => {
                handler => sub { ... },
            },
            another_subpipe => Piper->new(...),
            \%subpipe_opts,
        ),
        Piper::Process->new({
            label => 'another_handler',
            handler => sub { ... },
        }),
        sub {
            # An un-labeled handler
            ...
        },
        {
            label => 'final_handler',
            handler => sub { ... },
        },
    );

=head1 INITIALIZATION

Piper segments were designed to be easily reusable.  Prior to initialization, L<Piper> and L<Piper::Process> objects do not process data; they simply contain the blueprint for creating the pipeline.  As such, blueprints for commonly-used pipeline segments can be stored in package libraries and imported wherever needed.

To create a functioning pipeline from one such blueprint, simply call the C<init> method on the outermost segment.  The C<init> method returns a L<Piper::Instance> object of the outermost segment, which is the realization of the pipeline design, and which contains L<Piper::Instance> objects created from all its contained segments.

Initialization fuses the pipeline segments together, establishes the relationships between the segments, and initializes the dataflow infrastructure.

The C<init> method may be chained from the constructor if the blueprint object is not needed:

    my $instance = Piper->new(...)->init;

Any arguments passed to the C<init> method will be cached and made available to each handler in the pipeline (see the L</PROCESS HANDLER> section for full description of handlers).  This is a great way to share a resource (such as a database handle) among process handlers.

    my $pipe = Piper->new(
        query => sub {
            my ($instance, $batch, $dbh) = @_;
            $instance->emit(
                $dbh->do_query(@$batch)
            );
        },
        ...
    );
    my $instance = $pipe->init($dbh);

Instances are ready to accept data for processing:

    $instance->enqueue(@data);
    while ($instance->isnt_exhausted) {
        my $result = $instance->dequeue;
    }

=head1 PROCESS HANDLER

L<Piper::Process> objects have the same L</SEGMENT ATTRIBUTES> as L<Piper> objects, but have an additional required attribute known as its C<handler>.

A process C<handler> is the data-processing subroutine for the segment.

In its simplest form, the process handler takes input from the previous pipeline segment, processes it, and passes it on to the next segment; but handlers also have built-in support for non-linear and recursive dataflow (see L</FLOW CONTROL>).

The arguments provided to the C<handler> subroutine are:

=over

=item C<$instance>

The instance (a L<Piper::Instance> object) corresponding to the segment.

=item C<$batch>

An arrayref of data items to process.

=item C<@args>

Any arguments provided to the C<init> method during the L</INITIALIZATION> of the pipeline.

=back

After processing a batch of data, the C<handler> may pass the results to the next segment using the C<emit> method called from the handler's C<$instance>.

=head2 Example:

    sub {
        my ($instance, $batch) = @_;
        $instance->emit( map { ... } @$batch );
    }

=head1 FLOW CONTROL

Since L<Piper> has built-in support for non-linear and/or recursive pipelines, a L</PROCESS HANDLER> may send data to any other segment in the pipeline, including itself.

The following methods may be called from the C<$instance> object passed as the first argument to a C<handler>:

=head2 emit(@data)

Send C<@data> to the next segment in the pipeline.  If the instance is the last in the pipeline, emits to the drain, making the C<@data> ready for C<dequeue>.

=head2 recycle(@data)

Re-queue C<@data> to the top of the current segment in an order such that C<dequeue(1)> would subsequently return C<$data[0]> and so forth.

=head2 injectAt($location, @data)

=head2 injectAfter($location, @data)

Send C<@data> to the segment I<at> or I<after> the specified C<$location>.

For each of the above methods, C<$location> must be the label of a segment in the pipeline or a path-like representation of an hierarchy of labels.

For example, in the following pipeline, a few possible C<$location> values include C<a>, C<subpipe/b>, or C<main/subpipe/c>.

    my $pipe = Piper->new(
        { label => 'main' },
        subpipe => Piper->new(
            a => sub { ... },
            b => sub { ... },
            c => sub { ... },
        ),
    );

If a label is unique within the pipeline, only the label is required.  For non-unique labels, searches are performed in a nearest-neighbor, depth-first manner.

For example, in the following pipeline, searching for C<processA> from the handler of C<processB> would find C<main/pipeA/processA>, not C<main/processA>.  So to reach C<main/processA> from C<processB>, the handler would need to search for C<main/processA>.

    my $pipe = Piper->new(
        { label => 'main' },
        pipeA => Piper->new(
            processA => sub { ... },
            processB => sub { ... },
        ),
        processA => sub { ... },
    );

=head2 inject(@data)

If the segment has a parent, enqueues C<@data> to its parent.  Otherwise, enqueues C<@data> to itself.

=head2 eject(@data)

If the segment has a parent, send C<@data> to the drain of its parent.  Otherwise, enqueues C<@data> to the segment's drain.

=head1 SEGMENT ATTRIBUTES

All of the following attributes are available for both container (L<Piper>) and processor (L<Piper::Process>) segment types.

Each attribute is equipped with an accessor of the same name.

A star (*) indicates that the attribute is writable, and can be modified at runtime by passing a value as an argument to the method of the same name.

All attributes (except C<label>) have an associated predicate method called C<has_$attribute> which returns a boolean indicating whether the attribute has been set for the segment.

All writable attributes (indicated by *) can be cleared by passing an explicit C<undef> to the writer method or by calling the appropriate clearer method called C<clear_$attribute>.

All accessors, writers, predicates, and clearers are available for each segment before and after L</INITIALIZATION>.

=head2 allow

A coderef which can be used to subset the items which are I<allowed> to be processed by the segment.

The coderef executes on each item attempting to queue to the segment.  If it returns true, the item is queued.  Otherwise, the item skips the segment and proceeds to the next adjacent segment.

Each item is localized to C<$_>, and is also passed in as the first argument.

These example C<allow> subroutines are equivalent:

    # This segment only accepts digit inputs
    allow => sub { /^\d+$/ }
    allow => sub { $_ =~ /^\d+$/ }
    allow => sub { $_[0] =~ /^\d+$/ }

=head2 *batch_size

The number of items to process at a time for the segment.

Once initialized (see L</INITIALIZATION>), a segment inherits the C<batch_size> of any existing parent(s) if not provided.  If the segment has no parents, or if none of the parents have a C<batch_size> defined, the default C<batch_size> will be used.  The default C<batch_size> is 200, but can be configured in the import statement (see the L</GLOBAL CONFIGURATION> section).

=head2 *debug

The debug level for the segment.

Once initialized (see L</INITIALIZATION>), a segment inherits the debug level of any existing parent(s) if not specified.  The default level is 0, but can be globally overridden by the environment variable C<PIPER_DEBUG>.

See the L</LOGGING AND DEBUGGING> section for specifics about debug and verbosity levels.

=head2 *enabled

A boolean indicating that the segment is enabled and can accept items for processing.

Once initialized (see L</INITIALIZATION>), a segment inherits this attribute from any existing parent(s).  The default is true.

If a segment is disabled (C<enabled = 0>), all items attempting to queue to the segment are forwarded to the next adjacent segment.

=head2 label

A label for the segment.  If no label is provided, a globally unique ID will be used.

Labels are necessary for certain types of L</FLOW CONTROL> (for example, L<injectAt> or L<injectAfter>).  For pipelines that do not utilize L</FLOW CONTROL> features, labels are primarily useful for L</LOGGING AND DEBUGGING>.

=head2 *verbose

The verbosity level for the segment.

Once initialized (see L</INITIALIZATION>), a segment inherits the verbosity level of any existing parent(s) if not specified.  The default level is 0, but can be globally overridden by the environment variable C<PIPER_VERBOSE>.

See the L</LOGGING AND DEBUGGING> section for specifics about debug and verbosity levels.

=head2 INSTANCE ATTRIBUTES

The following attributes have read-only accessors (of the same name).

=head3 children

For container instances (made from L<Piper> objects, not L<Piper::Process> objects), holds an arrayref of the contained instance objects.

=head3 main

For any instance in the pipeline, this attribute holds a reference to the outermost container instance.

=head3 parent

For all instances in the pipeline except the outermost container (C<main>), this attribute holds a reference to the instance's immediate container segment.

=head3 path

The full path to the instance, built as the concatenation of all the parent(s) labels and the instance's label, joined by C</>.  Instances stringify to this attribute.

=head2 INSTANCE METHODS

Methods marked with a (*) should only be called from the outermost instance.

=head3 *dequeue([$num])

Remove at most C<$num> S<(default 1)> processed items from the end of the pipeline.

=head3 *enqueue(@data)

Queue C<@data> for processing by the pipeline.

=head3 find_segment($location)

Find and return the segment instance according to C<$location>, which can be a label or a path-like hierarchy of labels.  See L<injectAfter|/injectAfter($location, @data)> for a detailed description of C<$location>.

=head3 *flush

Process batches until there are no more items pending.

=head3 has_children

A boolean indicating whether the instance has any children.

=head3 has_parent

A boolean indicating whether the instance has a parent.

=head3 has_pending

Returns a boolean indicating whether there are any items that are queued at some level of the segment but have not completed processing.

=head3 *is_exhausted

Returns a boolean indicating whether there are any items left to process or dequeue.

=head3 *isnt_exhausted

Returns the opposite of C<is_exhausted>.

=head3 next_segment

Returns the next adjacent segment from the calling segment.  Returns undef for the outermost container.

=head3 pending

Returns the number of items that are queued at some level of the pipeline segment but have not completed processing.

=head3 *prepare([$num])

Process batches while data is still C<pending> until at least C<$num> S<(default 1)> items are C<ready> for C<dequeue>.

=head3 ready

Returns the number of items that have finished processing and are ready for C<dequeue> from the pipeline segment.

=head1 GLOBAL CONFIGURATION

The following global attributes are configurable from the Piper import statement.

    Ex:
    # Change the default batch_size to 50
    use Piper batch_size => 50;

=head2 batch_size

The default batch size used by pipeline segments which do not have a locally defined C<batch_size> and do not have a parent segment with a defined C<batch_size>.

The C<batch_size> attribute must be a positive integer.

The default C<batch_size> is 200.

=head1 LOGGING AND DEBUGGING

Logging and debugging facilities are available upon L</INITIALIZATION> of a pipeline.

Warnings and errors are issued regardless of debug and verbosity levels via C<carp> and C<croak> from the L<Carp> module, and are therefore configurable with any of L<Carp>'s global options or environment variables.

Debugging and/or informational messages are printed to STDERR if debug and/verbosity levels have been set.  There are three levels used by L<Piper> for each of C<debug>/C<verbose>: S<0, 1, or 2>.  The default is S<0 (off)>.

=head2 Levels

Levels can be set by any of the following mechanisms: at construction of the L<Piper>/L<Piper::Process> objects, dynamically via the C<debug> and C<verbose> methods of segments, or with the environment variables C<PIPER_DEBUG> and C<PIPER_VERBOSE>.

Levels can be set local to specific segments.  The default levels of a sub-segment are inherited from its parent.

    Ex:
        # main                 verbose => 0 (default)
        # main/subpipe         verbose => 1
        # main/subpipe/normal  verbose => 1 (inherited)
        # main/subpipe/loud    verbose => 2
        # main/subpipe/quiet   verbose => 0

        my $pipe = Piper->new(
            { label => 'main' },
            subpipe => Piper->new(
                { verbose => 1 },
                normal => sub {...},
                loud => {
                    verbose => 2,
                    handler => sub {...},
                },
                quiet => {
                    verbose => 0,
                    handler => sub {...},
                },
            ),
        );

Levels set via the environment variables C<PIPER_DEBUG> and C<PIPER_VERBOSE> are global.  If set, these environment variables override any and all settings defined in the source code.

=head2 Messages

All messages include information about the segment which called the logger.

Existing informational (C<verbose> or S<< C<debug> > 0 >>) messages describe data processing steps, such as noting when items are queueing or being processed by specific segments.  Increasing S<level(s) > 1> simply adds more detail to the printed messages.

Existing debug messages describe the decision actions of the pipeline engine itself.  Examples include logging its search steps when locating a named segment or explaining how it chooses which batch to process.  Increasing the debug S<< level > 1 >> simply adds more detail to the printed messages.

=head2 Custom messaging

User-defined errors, warnings, and debug or informational messages can use the same logging system as L<Piper> itself.

The first argument passed to a L</PROCESS HANDLER> is the L<Piper::Instance> object associated with that segment, which has the below-described methods available for logging, debugging, warning, or throwing errors.

In each of the below methods, the C<@items> are optional and only printed if the verbosity level for the segment S<< is > 1 >>.  They can be used to pass additional context or detail about the data being processed or which caused the message to print (for conditional messages).

The built-in messaging only uses debug/verbosity levels S<1 and 2>, but there are no explicit rules enforced on maximum debug/verbosity levels, so users may explicitly require higher levels for custom messages to heighten the required levels for any custom message.

=head3 ERROR($message, [@items])

Throws an error with C<$message> via C<croak>.

=head3 WARN($message, [@items])

Issues a warning with C<$message> via C<carp>.

=head3 INFO($message, [@items])

Prints an informational C<$message> to STDERR if either the debug or verbosity level for the segment S<< is > 0 >>.

=head3 DEBUG($message, [@items])

Prints a debug C<$message> to STDERR if the debug level for the segment S<< is > 0 >>.

=head3 Example:

    my $pipe = Piper->new(
        messenger => sub {
            my ($instance, $batch) = @_;
            for my $data (@$batch) {
                if ($data->is_bad) {
                    $instance->ERROR("Data <$data> is bad!");
                }
            }
            # User-heightened verbosity level
            $instance->INFO('Data all good!', @$batch)
                if $instance->verbose > 2;
            ...
        },
        ...
    );

=head1 ACKNOWLEDGEMENTS

Much of the concept and API for this project was inspired by the work of L<Nathaniel Pierce|mailto:nwpierce@gmail.com>.

Special thanks to L<Tim Heaney|http://oylenshpeegul.typepad.com> for his encouragement and mentorship.

=head1 VERSION

version 0.04

=head1 AUTHOR

Mary Ehlers <ehlers@cpan.org>

=head1 CONTRIBUTOR

=for stopwords Tim Heaney

Tim Heaney <oylenshpeegul@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2017 by Mary Ehlers.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
