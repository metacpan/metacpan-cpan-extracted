package REST::Buildbot;

use strict;
use warnings;

use Moose;
use REST::Buildbot::Change;
use REST::Buildbot::BuildSet;
use REST::Buildbot::BuildRequest;
use REST::Buildbot::Build;
use REST::Buildbot::Builder;
use REST::Buildbot::Step;
use REST::Buildbot::SourceStamp;
use REST::Buildbot::Log;
use LWP::UserAgent;
use JSON;

has 'url' => (is => 'ro', isa => 'Str', required => 1);
has '_ua' => (is => 'ro', isa => 'LWP::UserAgent',
             default => sub {LWP::UserAgent->new});
has '_builders' => (is => 'ro', isa => 'HashRef[REST::Buildbot::Builder]',
                   lazy => 1, builder => '_build_builders');
has 'errorstr' => (is => 'ro', isa => 'Maybe[Str]');


=head1 NAME

REST::Buildbot - Interface to the Buildbot v2 REST API

=head1 VERSION

Version 0.02

=cut

our $VERSION = '0.02';


=head1 SYNOPSIS

This is an interface to the REST API provided by Buildbot instances. Most
object types can be fetched by name or id, and most object types can be
used to look up associated objects. The individual objects have no methods,
but do have accessors for all of the data returned by the REST API. Most
attributes are pure perl data types, the only exception is BuildSets and
Changes, both of which have an attribute that contains a
REST::BuildBot::SourceStamp or an arrayref of them.

    use REST::Buildbot;

    my $bb = REST::Buildbot->new(url => 'http://localhost:8010/api/v2/');

    # Get the 'linux' builder's first build
    my $linux_builder = $bb->get_builder_by_name('linux');
    my $build = $bb->get_build_by_builder_and_number($linux_builder, 1);

    # Learn about this build
    my $buildrequest = $bb->get_buildrequest_by_id($build->buildrequestid);
    my $buildset = $bb->get_buildset_by_id($buildrequest->buildsetid);
    my $sourcestamp = $buildset->sourcestamps->[0];
    # Branch, revision ID, and commit message are in the SourceStamp object

    # Look up all the builds with a certain revision
    my $rev = '0123456789abcdef...';
    my $buildsets = $bb->get_buildsets_by_revision($rev);
    # There may be several, choose in your own way
    my $buildset = $buildsets->[0];
    # Find all the builds on this buildset, and explore some information
    my $buildrequests = $bb->get_buildrequests_by_buildset($bsid);
    foreach my $buildrequest (@$buildrequests) {
        my $brid = $buildrequest->buildrequestid;
        my $builds = $bb->get_builds_by_buildrequest($brid);
        # Again, choose one build. Usually most recent, older ones may
        # be cancels or retries
        my $build = $builds->[0];
        my $steps = $bb->get_steps_by_build($build->buildid);
        # The last step is make test for me
        my $make_test = $steps->[-1];
        my $logs = $bb->get_logs_by_step($make_test->stepid);
        # Choose which log to use - probably by looping and
        # comparing against name
        my $log;
        foreach my $l (@$logs) {
            if ($l->name =~ /stdio/) {
                $log = $l;
                last;
            }
        }
        die "No stdio log" unless $log;
        my $stdio_text = $bb->get_log_text($log->logid);
    }

=head1 AVAILABLE METHODS

The following subtypes are available: Build, Builder, BuildRequest,
BuildSet, Change, Log, SourceStamp, Step. Of these, all 8 have an
ID which they can be looked up by, for example, get_build_by_id, or
they can all be looked up at once by, for example, get_builds.

Additionally, Builders can be looked up by name, Changes can be
looked up by revision. These methods use names like
get_builder_by_name.

Builds can also be looked up using the build "number" (which is
unique by builder, but not globally unique - it is distinct from
the build id). This method requires the Builder object and the
build number, and is called get_build_by_builder_and_number.

The objects themselves have a number of interrelationships. Most
of these are one-to-many, even though some of them are one-to-one
under most normal cases. For example, buildset to buildrequest is
expected to be one-to-many (if one scheduler triggers more than
one builder), but usually each buildrequest has only one build.
There may be multiple builds per buildrequest if one of the builds
was cancelled manually or due to a client restart. Here is a full
list of valid relationships:

=over 4

=item Builder to Build
=item Builder to BuildRequest
=item BuildSet to BuildRequest
=item BuildRequest to Build
=item Build to Step
=item Step to Log

=back

Each of the above is a one-to-many relationship. For example,
get_builds_by_builder returns an arrayref of Builds, but
get_builder_by_build returns a single Builder.

Additionally, a Change is one-to-one with a SourceStamp, and
a BuildSet is one-to-many with SourceStamps. Generally, you
will not use this relationship, instead using a helper function
like get_buildsets_by_revision or get_changes_by_revision if
you have a source control revision, or the ->sourcestamp->*
properties of a Change, or the ->sourcestamps->[$i]->*
properties of a BuildSet, to get a source control revision.

Finally, it is possible to get the text of a log object using
get_log_text.

=head1 ERROR HANDLING

On error, REST::Buildbot methods will return undef and set an error
string, which can be accessed by ->errorstr. An error is defined as
an LWP::UserAgent error, a lookup by an ID that does not exist, or
calling a method with insufficient or incorrect arguments.

If no items are found for a query, REST::Buildbot will return undef,
for methods returning a single object, or an empty array ref, for
methods potentially returning multiple objects.

=head1 CACHING

REST::Buildbot may cache the results of common calls, such as the
list of all builders. In general, you should assume that data is no
more recent than the first call made against a REST::Buildbot object.
If you wish to ensure that cached data is not being used, for example,
if you are using REST::Buildbot within an application that runs as a
daemon, you should create a new REST::Buildbot object.

=cut

# Not a public API function - subject to change
# Used by internal methods to access the REST API
sub _get {
    my $self = shift;
    my $query = shift;

    my $res = $self->_ua->get($self->url.$query);
    return $self->_set_err($res->status_line) unless $res->is_success;

    my $content = $res->decoded_content;
    my $ret = decode_json($content);

    return $ret;
}

sub _build_builders {
    my $self = shift;

    my $data = $self->_get('builders');

    my $ret = {};

    foreach my $b (@{$data->{'builders'}}) {
        $ret->{$b->{'builderid'}} = REST::Buildbot::Builder->new(%$b);
    }

    return $ret;
}

# Returns undef, it is safe to return $self->_set_err
sub _set_err {
    my $self = shift;
    my $errstr = shift || "An error has occurred";
    
    $self->{'errstr'} = $errstr;
    
    return;
}

sub _reqd_arg {
    my $arg = shift;
    my $type = shift;
    
    my ($package, $sub) = (caller(1))[0, 3];
    my ($caller, $line) = (caller(2))[1, 2];
    return _set_err($package.'::'.$sub.' requires an additional argument ' .
        ($type ? 'of type '.$type.' ' : '') .
        'at '.$caller.' line '.$line .'.'
        ) unless defined $arg && (!defined $type || ref $arg eq $type);
    return $arg;    
}

=head1 METHODS

=head1 new

Constructor. Takes one mandatory argument, the URL to the API of the
Buildbot instance to use. Should end in /api/v2/.

    my $bb = REST::Buildbot->new(url => 'http://localhost:8010/api/v2/');

=head2 get_*

This set of methods allows lookup of all objects of a given type that
the buildbot instance has. It returns a reference to an array of those
objects. If there are none, it returns an empty array.

=over 4

=item get_builds
=item get_builders
=item get_buildrequests
=item get_buildsets
=item get_changes
=item get_logs
=item get_sourcestamps
=item get_steps

=back

=cut

sub get_builds {
    my $self = shift;

    my $data = $self->_get('builds');

    my $ret = [];

    foreach my $b (@{$data->{'builds'}}) {
        push @$ret, REST::Buildbot::Build->new(%$b);
    }

    return $ret;
}

sub get_builders {
    my $self = shift;

    my $ret = @{$self->_builders}{sort {$a <=> $b} keys %{$self->_builders}};

    return $ret;
}

sub get_buildrequests {
    my $self = shift;

    my $data = $self->_get('buildrequests');

    my $ret = [];

    foreach my $br (@{$data->{'buildrequests'}}) {
        push @$ret, REST::Buildbot::BuildRequest->new(%$br);
    }

    return $ret;
}

sub get_buildsets {
    my $self = shift;

    my $data = $self->_get('buildsets');

    my $ret = [];

    foreach my $bs (@{$data->{'buildsets'}}) {
        push @$ret, REST::Buildbot::BuildSet->new(%$bs);
    }

    return $ret;
}

sub get_changes {
    my $self = shift;

    my $data = $self->_get('changes');

    my $ret = [];

    foreach my $c (@{$data->{'changes'}}) {
        push @$ret, REST::Buildbot::Change->new(%$c);
    }

    return $ret;
}

sub get_logs {
    my $self = shift;

    my $data = $self->_get('logs');

    my $ret = [];

    foreach my $l (@{$data->{'logs'}}) {
        push @$ret, REST::Buildbot::Log->new(%$l);
    }

    return $ret;
}

sub get_sourcestamps {
    my $self = shift;

    my $data = $self->_get('sourcestamps');

    my $ret = [];

    foreach my $ss (@{$data->{'sourcestamps'}}) {
        push @$ret, REST::Buildbot::SourceStamp->new(%$ss);
    }

    return $ret;
}

sub get_steps {
    my $self = shift;

    my $data = $self->_get('steps');

    my $ret = [];

    foreach my $s (@{$data->{'steps'}}) {
        push @$ret, REST::Buildbot::Step->new(%$s);
    }

    return $ret;
}

=head2 get_*_by_id

This set of methods allows looking up an item by its unique id. Looking
up an item that does not exist is an error, and is currently handled by
dying. In the future, this behavior may change, likely by having these
methods return undef.

=over 4

=item get_build_by_id
=item get_builder_by_id
=item get_buildrequest_by_id
=item get_buildset_by_id
=item get_change_by_id
=item get_log_by_id
=item get_sourcestamp_by_id
=item get_step_by_id

=back

=cut

sub get_build_by_id {
    my $self = shift;
    my $id = _reqd_arg(shift) // return;

    my $data = $self->_get('builds/'.$id);

    my $ret = REST::Buildbot::Build->new(%{$data->{'builds'}->[0]});

    return $ret;
}

sub get_builder_by_id {
    my $self = shift;
    my $id = _reqd_arg(shift) // return;

    return $self->_set_err("No such builder with id $id") unless exists $self->_builders->{$id};
    
    my $ret = $self->_builders->{$id};

    return $ret;
}

sub get_buildrequest_by_id {
    my $self = shift;
    my $id = _reqd_arg(shift) // return;

    my $data = $self->_get('buildrequests/'.$id);

    my $ret = REST::Buildbot::BuildRequest->new(%{$data->{'buildrequests'}->[0]});

    return $ret;
}

sub get_buildset_by_id {
    my $self = shift;
    my $id = _reqd_arg(shift) // return;

    my $data = $self->_get('buildsets/'.$id);

    my $ret = REST::Buildbot::BuildSet->new(%{$data->{'buildsets'}->[0]});

    return $ret;
}

sub get_change_by_id {
    my $self = shift;
    my $id = _reqd_arg(shift) // return;

    my $data = $self->_get('changes/'.$id);

    my $ret = REST::Buildbot::Change->new(%{$data->{'changes'}->[0]});

    return $ret;
}

sub get_log_by_id {
    my $self = shift;
    my $id = _reqd_arg(shift) // return;

    my $data = $self->_get('logs/'.$id);

    my $ret = REST::Buildbot::Log->new(%{$data->{'logs'}->[0]});

    return $ret;
}

sub get_sourcestamp_by_id {
    my $self = shift;
    my $id = _reqd_arg(shift) // return;

    my $data = $self->_get('sourcestamps/'.$id);

    my $ret = REST::Buildbot::SourceStamp->new(%{$data->{'sourcestamps'}->[0]});

    return $ret;
}

sub get_step_by_id {
    my $self = shift;
    my $id = _reqd_arg(shift) // return;

    my $data = $self->_get('steps/'.$id);

    my $ret = REST::Buildbot::Step->new(%{$data->{'steps'}->[0]});

    return $ret;
}

=head2 get_*_by_*

This is the set of methods that employs the relationships between data
types. In all cases, they take a single argument: an object of the type
to be searched by.

The following items return a reference to an array containing
any number of the target type:

=over 4

=item get_buildrequests_by_builder
=item get_buildrequests_by_buildset
=item get_builds_by_builder
=item get_builds_by_buildrequest
=item get_steps_by_build
=item get_logs_by_step
=item get_sourcestamps_by_buildset

=back

The following items return an object of the target type, or undef on failure.

=over 4

=item get_builder_by_buildrequest
=item get_buildset_by_buildrequest
=item get_builder_by_build
=item get_buildrequest_by_build
=item get_build_by_step
=item get_step_by_log
=item get_sourcestamp_by_change

=back

=cut

sub get_buildrequests_by_builder {
    my $self = shift;
    my $builder = _reqd_arg(shift, 'REST::Buildbot::Builder') // return;

    my $data = $self->_get('buildrequests?builderid='.$builder->builderid);

    my $ret = [];

    foreach my $br (@{$data->{'buildrequests'}}) {
        push @$ret, REST::Buildbot::BuildRequest->new(%$br);
    }

    return $ret;
}

sub get_buildrequests_by_buildset {
    my $self = shift;
    my $buildset = _reqd_arg(shift, 'REST::Buildbot::BuildSet') // return;

    my $data = $self->_get('buildrequests?buildsetid='.$buildset->bsid);

    my $ret = [];

    foreach my $br (@{$data->{'buildrequests'}}) {
        push @$ret, REST::Buildbot::BuildRequest->new(%$br);
    }

    return $ret;
}

sub get_builds_by_builder {
    my $self = shift;
    my $builder = _reqd_arg(shift, 'REST::Buildbot::Builder') // return;

    my $data = $self->_get('builds?builderid='.$builder->builderid);

    my $ret = [];

    foreach my $b (@{$data->{'builds'}}) {
        push @$ret, REST::Buildbot::Build->new(%$b);
    }

    return $ret;
}

sub get_builds_by_buildrequest {
    my $self = shift;
    my $request = _reqd_arg(shift, 'REST::Buildbot::BuildRequest') // return;

    my $data = $self->_get('builds?buildrequestid='.$request->buildrequestid);

    my $ret = [];

    foreach my $b (@{$data->{'builds'}}) {
        push @$ret, REST::Buildbot::Build->new(%$b);
    }

    return $ret;
}

sub get_steps_by_build {
    my $self = shift;
    my $build = _reqd_arg(shift, 'REST::Buildbot::Build') // return;

    my $data = $self->_get('builds/'.$build->buildid.'/steps');

    my $ret = [];

    foreach my $s (sort {$a->{'number'} <=> $b->{'number'}}
                        @{$data->{'steps'}}
    ) {
        push @$ret, REST::Buildbot::Step->new(%$s);
    }

    return $ret;
}

sub get_logs_by_step {
    my $self = shift;
    my $step = _reqd_arg(shift, 'REST::Buildbot::Step') // return;

    my $data = $self->_get('steps/'.$step->stepid.'/logs');

    my $ret = [];

    foreach my $l (sort {$a->{'logid'} <=> $b->{'logid'}}
                        @{$data->{'logs'}}
    ) {
        push @$ret, REST::Buildbot::Log->new(%$l);
    }

    return $ret;
}

sub get_sourcestamps_by_buildset {
    my $self = shift;
    my $buildset = _reqd_arg(shift, 'REST::Buildbot::BuildSet') // return;
    
    return $buildset->sourcestamps;
}

sub get_builder_by_buildrequest {
    my $self = shift;
    my $buildrequest = _reqd_arg(shift, 'REST::Buildbot::BuildRequest') // return;

    return $self->get_builder_by_id($buildrequest->builderid);
}

sub get_buildset_by_buildrequest {
    my $self = shift;
    my $buildrequest = _reqd_arg(shift, 'REST::Buildbot::BuildRequest') // return;

    return $self->get_buildset_by_id($buildrequest->buildsetid);
}

sub get_builder_by_build {
    my $self = shift;
    my $build = _reqd_arg(shift, 'REST::Buildbot::Build') // return;

    return $self->get_builder_by_id($build->builderid);
}

sub get_buildrequest_by_build {
    my $self = shift;
    my $build = _reqd_arg(shift, 'REST::Buildbot::Build') // return;

    return $self->get_buildrequest_by_id($build->buildrequestid);
}

sub get_build_by_step {
    my $self = shift;
    my $step = _reqd_arg(shift, 'REST::Buildbot::Step') // return;

    return $self->get_build_by_id($step->buildid);
}

sub get_step_by_log {
    my $self = shift;
    my $log = _reqd_arg(shift, 'REST::Buildbot::Log') // return;

    return $self->get_step_by_id($log->stepid);
}

sub get_sourcestamp_by_change {
    my $self = shift;
    my $change = _reqd_arg(shift, 'REST::Buildbot::Change') // return;

    return $change->sourcestamp;
}

=head2 get_builder_by_name

Looks up a builder by name. Returns a REST::Buildbot::Builder object.
Returns undef if there is not exactly one builder with a matching name.

=cut

sub get_builder_by_name {
    my $self = shift;
    my $name = _reqd_arg(shift) // return;

    my @res = grep {$_->name eq $name} values %{$self->_builders};
    return $self->_set_err("ambiguous builder name $name") if @res > 1;
    return $self->_set_err("no such builder name $name") if @res == 0;
    my $ret = $res[0];

    return $ret;
}

=head2 get_changes_by_revision

Looks up changes by a revision string. Returns a reference to an array
of REST::Buildbot::Change objects. If there are no results, the reference
will be to an empty array.

=cut

sub get_changes_by_revision {
    my $self = shift;
    my $rev = _reqd_arg(shift) // return;

    my $data = $self->_get('changes?revision='.$rev);

    my $ret = [];

    foreach my $c (@{$data->{'changes'}}) {
        push @$ret, REST::Buildbot::Change->new(%$c);
    }

    return $ret;
}

=head2 get_buildsets_by_revision

Looks up buildsets by a revision string. Returns a reference to an array
of REST::Buildbot::BuildSet objects. If there are no results, the reference
will be to an empty array.

=cut

sub get_buildsets_by_revision {
    my $self = shift;
    my $rev = _reqd_arg(shift) // return;

    my $data = $self->_get('buildsets');

    my $ret = [];

    foreach my $bs (@{$data->{'buildsets'}}) {
        next unless (grep {$_->{'revision'} eq $rev} @{$bs->{'sourcestamps'}});
        push @$ret, REST::Buildbot::BuildSet->new(%$bs);
    }

    return $ret;
}

=head2 get_build_by_builder_and_number

Looks up a build using the Builder object and the build number. Returns
a REST::Buildbot::Build object. Returns undef if there is no match.

=cut

sub get_build_by_builder_and_number {
    my $self = shift;
    my $builder = _reqd_arg(shift, 'REST::Buildbot::Builder') // return;
    my $buildnum = _reqd_arg(shift) // return;

    my $builderid = $builder->builderid;

    my $data = $self->_get('builders/'.$builderid.'/builds/'.$buildnum);

    my $ret = REST::Buildbot::Build->new(%{$data->{'builds'}->[0]});

    return $ret;
}

=head2 get_log_text

Returns the contents of a log as a string. Returns undef on failure.

=cut

sub get_log_text {
    my $self = shift;
    my $log = _reqd_arg(shift, 'REST::Buildbot::Log') // return;

    my $res = $self->_ua->get($self->url.'logs/'.$log->logid.'/raw');
    return $self->_set_err($res->status_line) unless $res->is_success;

    my $ret = $res->decoded_content;

    return $ret;
}

=head1 AUTHOR

Dan Collins, C<< <DCOLLINS at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-rest-buildbot at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=REST-Buildbot>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc REST::Buildbot


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=REST-Buildbot>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/REST-Buildbot>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/REST-Buildbot>

=item * Search CPAN

L<http://search.cpan.org/dist/REST-Buildbot/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2016 Dan Collins.

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see L<http://www.gnu.org/licenses/>.


=cut

1; # End of REST::Buildbot
