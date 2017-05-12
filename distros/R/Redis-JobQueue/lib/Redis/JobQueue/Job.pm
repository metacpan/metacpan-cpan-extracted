package Redis::JobQueue::Job;

=head1 NAME

Redis::JobQueue::Job - Object interface for creating and manipulating jobs

=head1 VERSION

This documentation refers to C<Redis::JobQueue::Job> version 1.19

=cut

#-- Pragmas --------------------------------------------------------------------

use 5.010;
use strict;
use warnings;

# ENVIRONMENT ------------------------------------------------------------------

our $VERSION = '1.19';

#-- load the modules -----------------------------------------------------------

use Exporter qw(
    import
);
our @EXPORT_OK  = qw(
    STATUS_CREATED
    STATUS_WORKING
    STATUS_COMPLETED
    STATUS_FAILED
);

#-- load the modules -----------------------------------------------------------

# Modules
use Carp;
use List::Util qw(
    min
);
use Mouse;                                      # automatically turns on strict and warnings
use Mouse::Util::TypeConstraints;
use Params::Util qw(
    _HASH0
    _INSTANCE
);
use Time::HiRes qw();

#-- declarations ---------------------------------------------------------------

=head1 SYNOPSIS

There are several ways to create a C<Redis::JobQueue::Job>
object:

    my $pre_job = {
        id           => '4BE19672-C503-11E1-BF34-28791473A258',
        queue        => 'lovely_queue',
        job          => 'strong_job',
        expire       => 12*60*60,               # 12h
        status       => STATUS_CREATED,
        workload     => \'Some stuff up to 512MB long',
        result       => \'JOB result comes here, up to 512MB long',
    };

    my $job = Redis::JobQueue::Job->new(
        id           => $pre_job->{id},
        queue        => $pre_job->{queue},
        job          => $pre_job->{job},
        expire       => $pre_job->{expire},
        status       => $pre_job->{status},
        workload     => $pre_job->{workload},
        result       => $pre_job->{result},
    );

    $job = Redis::JobQueue::Job->new( $pre_job );

    my $next_job = Redis::JobQueue::Job->new( $job );

Access methods to read and assign the relevant attributes of the object.
For example:

    $job->$workload( \'New workload' );
    # or
    $job->$workload( 'New workload' );

    my $id = $job->id;
    # 'workload' and 'result' return a reference to the data
    my $result = ${ $job->result };

Returns a list of names of the modified object fields:

    my @modified = $job->modified_attributes;

Resets the sign of changing an attribute. For example:

    $job->clear_modified( qw( status ) );

=head1 DESCRIPTION

Job API is implemented by C<Redis::JobQueue::Job> class.

The main features of the C<Redis::JobQueue::Job> class are:

=over 3

=item *

Provides an object oriented model of communication.

=item *

Supports data representing various aspects of the job.

=item *

Supports the creation of the job object, an automatic allowance for the change
attributes and the ability to cleanse the signs of change attributes.

=back

=head1 EXPORT

None by default.

The following additional constants, defining defaults for various parameters, are available for export:

=over

=item C<STATUS_CREATED>

Initial status of the job, showing that it was created.

=cut
use constant STATUS_CREATED     => '__created__';

=item C<STATUS_WORKING>

Jobs is being executed. Set by the worker function.

=cut
use constant STATUS_WORKING     => '__working__';

=item C<STATUS_COMPLETED>

Job is completed. Set by the worker function.

=cut
use constant STATUS_COMPLETED   => '__completed__';

=item C<STATUS_FAILED>

Job has failed. Set by the worker function.

=cut
use constant STATUS_FAILED      => '__failed__';

=back

User himself should specify the status L</ STATUS_WORKING>, L</ STATUS_COMPLETED>, L</ STATUS_FAILED>
or own status when processing the job.

=cut

my $meta = __PACKAGE__->meta;

subtype __PACKAGE__.'::NonNegInt',
    as 'Int',
    where { $_ >= 0 },
    message { ( $_ || '' ).' is not a non-negative integer!' },
;

subtype __PACKAGE__.'::NonNegNum',
    as 'Num',
    where { $_ >= 0 },
    message { ( $_ || '' ).' is not a non-negative number!' },
;

subtype __PACKAGE__.'::Progress',
    as 'Num',
    where { $_ >= 0 and $_ <= 1 },
    message { ( $_ || '' ).' is not a progress number!' },
;

subtype __PACKAGE__.'::WOSpStr',
    as 'Str',
    where { $_ !~ / / },
    message { ( $_ || '' ).' contains spaces!' },
;

subtype __PACKAGE__.'::DataRef',
    as 'ScalarRef'
;

coerce __PACKAGE__.'::DataRef',
    from 'Str',
    via { \$_ },
;

#-- constructor ----------------------------------------------------------------

=head2 CONSTRUCTOR

An error will cause the program to halt if the argument is not valid.

=head3 C<new( id =E<gt> $uuid, ... )>

It generates a Job object and can be called as either a class method or
an object method.

If invoked with the first argument being an object of C<Redis::JobQueue::Job> class
or a reference to a hash, then the new object attribute values are taken from
the hash of the first argument.

C<new> optionally takes arguments. These arguments are in key-value pairs.

This example illustrates a C<new()> call with all the valid arguments:

    $job = Redis::JobQueue::Job->new(
        id          => '4BE19672-C503-11E1-BF34-28791473A258',
                # UUID string, using conventional UUID string format.
                # Do not use it because filled in automatically when
                # you create a job.
        queue       => 'lovely_queue',  # The name of the job queue.
                                        # (required)
        job         => 'strong_job',    # The name of the job.
                                        # (optional attribute)
        expire      => 12*60*60,        # Job's time to live in seconds.
                                        # 0 for no expire time.
                                        # (required)
        status      => STATUS_CREATED,  # Current status of the job.
                # Do not use it because value should be set by the worker.
        workload    => \'Some stuff up to 512MB long',
                # Baseline data for the function of the worker
                # (the function name specified in the 'job').
                # Can be a scalar, an object or a reference to a scalar, hash, or array
        result      => \'JOB result comes here, up to 512MB long',
                # The result of the function of the worker
                # (the function name specified in the 'job').
                # Do not use it because value should be set by the worker.
    );

Returns the object itself, we can chain settings.

The attributes C<workload> and C<result> may contain a large amount of data,
therefore, it is desirable that they be passed as references to the actual
data to improve performance.

Do not use spaces in an C<id> attribute value.

Each element in the struct data has an accessor method, which is
used to assign and fetch the element's value.

=cut
around BUILDARGS => sub {
    my $orig  = shift;
    my $class = shift;

    if ( _INSTANCE( $_[0], __PACKAGE__ ) ) {
        my $job = shift;
        return $class->$orig( ( map { ( $_, $job->$_ ) } $job->job_attributes ), @_ );
    } else {
        return $class->$orig( @_ );
    }
};

#-- public attributes ----------------------------------------------------------

=head2 METHODS

An error will cause the program to halt if the argument is not valid.

=head3 C<id>

=head3 C<queue>

=head3 C<job>

=head3 C<expire>

=head3 C<status>

=head3 C<workload>

=head3 C<result>

The family of methods for a multitude of accessor methods for your data with
the appropriate names. These methods are able to read and assign the relevant
attributes of the object.

As attributes C<workload> and C<result> may contain a large amount of data
(scalars, references to arrays and hashes, objects):

=over 3

=item *

A read method returns a reference to the data.

=item *

A write method can receive both data or a reference to the data.

=back

=cut
has 'id'            => (
    is          => 'rw',
    isa         => __PACKAGE__.'::WOSpStr',
    default     => '',
    trigger     => sub { $_[0]->_modified_set( 'id' ) },
);

has 'queue'         => (
    is          => 'rw',
    isa         => 'Maybe[Str]',
    required    => 1,
    trigger     => sub { $_[0]->_modified_set( 'queue' ) },
);

has 'job'           => (
    is          => 'rw',
    isa         => 'Maybe[Str]',
    default     => '',
    trigger     => sub { $_[0]->_modified_set( 'job' ) },
);

has 'status'        => (
    is          => 'rw',
    isa         => 'Str',
    default     => STATUS_CREATED,
    trigger     => sub { $_[0]->_modified_set( 'status', $_[1] ) },
);

has 'expire'        => (
    is          => 'rw',
    isa         => 'Maybe['.__PACKAGE__.'::NonNegInt]',
    required    => 1,
    trigger     => sub { $_[0]->_modified_set( 'expire' ) },
);

for my $name ( qw( workload result ) ) {
    has $name           => (
        is          => 'rw',
        # A reference because attribute can contain a large amount of data
        isa         => __PACKAGE__.'::DataRef | HashRef | ArrayRef | ScalarRef | Object',
        coerce      => 1,
        builder     => '_build_data',           # will throw an error if you pass a bare non-subroutine reference as the default
        trigger     => sub { $_[0]->_modified_set( $name ) },
    );
}

=head3 C<progress>

Optional attribute, the progress of the task,
contains a user-defined value from 0 to 1.

=cut
has 'progress'      => (
    is          => 'rw',
    isa         => __PACKAGE__.'::Progress',
    default     => 0,
    trigger     => sub { $_[0]->_modified_set( 'progress' ) },
);

=head3 C<message>

Optional attribute, a string message with additional user-defined information.

=cut
has 'message'       => (
    is          => 'rw',
    isa         => 'Maybe[Str]',
    default     => '',
    trigger     => sub { $_[0]->_modified_set( 'message' ) },
);

=head3 C<created>

Returns time of job creation.
Set to the current time (C<Time::HiRes::time>) when job is created.

If necessary, alternative value can be set as:

    $job->created( time );

=head3 C<updated>

Returns the time of the most recent modification of the job.

Set to the current time (C<Time::HiRes::time>) when value(s) of any of the following data changes:
L</status>, L</workload>, L</result>, L</progress>, L</message>, L</completed>, L</failed>.

Can be updated manually:

    $job->updated( time );

=cut
for my $name ( qw( created updated ) ) {
    has $name           => (
        is          => 'rw',
        isa         => __PACKAGE__.'::NonNegNum',
        default     => sub { Time::HiRes::time },
        trigger     => sub { $_[0]->_modified_set( $name ) },
    );
}

=head3 C<started>

Returns the time that the job started processing.
Set to the current time (C<Time::HiRes::time>) when the L</status> of the job is set to L</STATUS_WORKING>.

If necessary, you can set your own value, for example:

    $job->started( time );

=head3 C<completed>

Returns the time of the task completion.

It is set to 0 when task is created.

Set to C<Time::HiRes::time> when L</status> is changed to L</STATUS_COMPLETED>.

Can be modified manually:

    $job->completed( time );

Change the C<completed> attribute sets C<failed> = 0.
The attributes C<completed> and C<failed> are mutually exclusive.

=head3 C<failed>

Returns the time of the task failure.

It is set to 0 when task is created.

Set to C<Time::HiRes::time> when L</status> is changed to L</STATUS_FAILED>.

Can be modified manually:

    $job->failed( time );

Change the C<failed> attribute sets C<completed> = 0.
The attributes C<failed> and C<completed> are mutually exclusive.

=cut
for my $name ( qw( started completed failed ) ) {
    has $name           => (
        is          => 'rw',
        isa         => __PACKAGE__.'::NonNegNum',
        default     => 0,
        trigger     => sub { $_[0]->_modified_set( $name ) },
    );
}

#-- private attributes ---------------------------------------------------------

has '_meta_data'    => (
    is          => 'rw',
    isa         => 'HashRef',
    init_arg    => 'meta_data',
    default     => sub { {} },
);

has '__modified'    => (
    is          => 'ro',
    isa         => 'HashRef[Int]',
    lazy        => 1,
    init_arg    => undef,                       # we make it impossible to set this attribute when creating a new object
    builder     => '_build_modified',
);

has '__modified_meta_data'  => (
    is          => 'rw',
    isa         => 'HashRef[Int]',
    lazy        => 1,
    init_arg    => undef,                       # we make it impossible to set this attribute when creating a new object
    default     => sub { return {}; },
);

#-- public methods -------------------------------------------------------------

=head3 C<elapsed>

Returns the time (a floating seconds since the epoch) since the job started processing (see L</started>)
till job L</completed> or L</failed> or to the current time.
Returns C<undef> if the start processing time was set to 0.

=cut
sub elapsed {
    my ( $self ) = @_;

    if ( my $started = $self->started ) {
        return( ( $self->completed || $self->failed || Time::HiRes::time ) - $started );
    } else {
        return( undef );
    }
}

=head3 C<meta_data>

With no arguments, returns a reference to a hash of metadata (additional information related to the job).
For example:

    my $md = $job->meta_data;

Hash value of an individual item metadata is available by specifying the name of the hash key.
For example:

    my $foo = $job->meta_data( 'foo' );

Separate metadata value can be set as follows:

    my $foo = $job->meta_data( next => 16 );

Group metadata can be specified by reference to a hash.
Metadata may contain scalars, references to arrays and hashes, objects.
For example:

    $job->meta_data(
        {
            'foo'   => 12,
            'bar'   => [ 13, 14, 15 ],
            'other' => { a => 'b', c => 'd' },
        }
    );

The name of the metadata fields should not match the standard names returned by
L</job_attributes> and must not begin with C<'__'}>.
An invalid name causes die (C<confess>).

=cut
my %_attributes = map { ( $_->name eq '_meta_data' ? 'meta_data' : $_->name ) => 1 } grep { substr( $_->name, 0, 2 ) ne '__' } $meta->get_all_attributes;

sub meta_data {
    my ( $self, $key, $val ) = @_;

    return $self->_meta_data
        if !defined $key;

    # metadata can be set with an external hash
    if ( _HASH0( $key ) ) {
        foreach my $field ( keys %$key ) {
            confess 'The name of the metadata field the same as standart job field name'
                if exists $_attributes{ $field } || substr( $field, 0, 2 ) eq '__';
        }
        $self->_meta_data( $key );
        $self->__modified_meta_data( {} );
        $self->__modified_meta_data->{ $_ } = 1
            foreach keys %$key;
        return;
    }

    # getter
    return $self->_meta_data->{ $key }
        if !defined $val;

    # setter
    confess 'The name of the metadata field the same as standart job field name'
        if exists $_attributes{ $key } || substr( $key, 0, 2 ) eq '__';
    $self->_meta_data->{ $key } = $val;
    ++$self->__modified_meta_data->{ $key };

    # job data change
    $self->updated( Time::HiRes::time );
    ++$self->__modified->{ 'updated' };

    return;
}

=head3 C<clear_modified( @fields )>

Resets the sign of any specified attributes that have been changed.
If no attribute names are specified, the signs are reset for all attributes.

=cut
sub clear_modified {
    my ( $self, @fields ) = @_;

    unless ( @fields ) {
        $self->clear_modified( $self->job_attributes );
        my @keys = keys %{ $self->__modified_meta_data };
        $self->clear_modified( @keys )
            if @keys;
        return;
    }

    foreach my $field ( @fields ) {
        if    ( exists $self->__modified->{ $field } ) { $self->__modified->{ $field } = 0 }
        elsif ( exists $self->__modified_meta_data->{ $field } ) { $self->__modified_meta_data->{ $field } = 0 }
    }

    return;
}

=head3 C<modified_attributes>

Returns a list of names of the object attributes that have been modified.

=cut
sub modified_attributes {
    my ( $self ) = @_;

    my @all_modified = (
        grep( { $self->__modified->{ $_ } } $self->job_attributes ),
        grep( { $self->__modified_meta_data->{ $_ } } keys( %{ $self->__modified_meta_data } ) ),
    );

    return @all_modified;
}

=head3 C<job_attributes>

Returns a sorted list of the names of object attributes.

=cut
sub job_attributes {
    return( sort keys %_attributes );
}

#-- private methods ------------------------------------------------------------

sub _build_data {
    my $empty_data = q{};
    return \$empty_data;
}

sub _build_modified {
    my ( $self ) = @_;

    my %modified;
    map { $modified{ $_ } = 1 } $self->job_attributes;
    return \%modified;
}

sub _modified_set {
    my $self    = shift;
    my $field   = shift;

    if ( $field =~ /^(status|meta_data|workload|result|progress|message|started|completed|failed)$/ ) {
        $self->updated( Time::HiRes::time );
        ++$self->__modified->{ 'updated' };
    }

    if ( $field eq 'status' ) {
        my $new_status = shift;
        if      ( $new_status eq STATUS_CREATED )   { $self->created( Time::HiRes::time ) }
        elsif   ( $new_status eq STATUS_WORKING )   { $self->started( Time::HiRes::time ) unless $self->started }
        elsif   ( $new_status eq STATUS_COMPLETED ) { $self->completed( Time::HiRes::time ) }
        elsif   ( $new_status eq STATUS_FAILED )    { $self->failed( Time::HiRes::time ) }
    }

    ++$self->__modified->{ $field };

    return;
}

#-- Closes and cleans up -------------------------------------------------------

no Mouse::Util::TypeConstraints;
no Mouse;                                       # keywords are removed from the package
__PACKAGE__->meta->make_immutable();

__END__

=head1 DIAGNOSTICS

An error will cause the program to halt (C<confess>) if an argument
is not valid. Use C<$@> for the analysis of the specific reasons.

=head1 SEE ALSO

The basic operation of the L<Redis::JobQueue|Redis::JobQueue> package modules:

L<Redis::JobQueue|Redis::JobQueue> - Object interface for creating and
executing jobs queues, as well as monitoring the status and results of jobs.

L<Redis::JobQueue::Job|Redis::JobQueue::Job> - Object interface for creating
and manipulating jobs.

L<Redis::JobQueue::Util|Redis::JobQueue::Util> - String manipulation utilities.

L<Redis|Redis> - Perl binding for Redis database.

=head1 SOURCE CODE

Redis::JobQueue is hosted on GitHub:
L<https://github.com/TrackingSoft/Redis-JobQueue>

=head1 AUTHOR

Sergey Gladkov, E<lt>sgladkov@trackingsoft.comE<gt>

Please use GitHub project link above to report problems or contact authors.

=head1 CONTRIBUTORS

Alexander Solovey

Jeremy Jordan

Sergiy Zuban

Vlad Marchenko

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012-2016 by TrackingSoft LLC.

This package is free software; you can redistribute it and/or modify it under
the same terms as Perl itself. See I<perlartistic> at
L<http://dev.perl.org/licenses/artistic.html>.

This program is
distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
PARTICULAR PURPOSE.

=cut
