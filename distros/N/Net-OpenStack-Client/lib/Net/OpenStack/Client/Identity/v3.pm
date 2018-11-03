package Net::OpenStack::Client::Identity::v3;
$Net::OpenStack::Client::Identity::v3::VERSION = '0.1.4';
use strict;
use warnings;

use Set::Scalar;
use Readonly;

use Net::OpenStack::Client::API::Convert qw(convert);
use Net::OpenStack::Client::Identity::Tagstore;
use Net::OpenStack::Client::Request qw(mkrequest);

use MIME::Base64 qw(encode_base64url decode_base64url);

Readonly my $IDREG => qr{[0-9a-z]{33}};

# This list is ordered:
#  Configuration of n-th item does not require
#  configuration of any items after that, but
#  might require configuration of previous ones
Readonly our @SUPPORTED_OPERATIONS => qw(
    region
    domain
    project
    user
    group
    role
    rolemap
    service
    endpoint
);

Readonly my %PARENT_ATTR => {
    region => 'parent_region_id',
    project => 'parent_id',
};

# tagstore cache
# key is project id; value is instance
my $_tagstores = {};

=head1 Functions

=over

=item sort_parent

Sort according to parent attribute.

=cut

# Use toposort?
# see https://rosettacode.org/wiki/Topological_sort#Perl

sub sort_parent
{
    # We assume that an empty string or number 0 is not a valid/used region name
    # force strings, so we can do eq tests
    my $ra = $a->{name};
    my $rb = $b->{name};
    my $pra = $a->{parent} || '';
    my $prb = $b->{parent} || '';

    my $res;
    if ($pra eq $rb) {
        # b is parent of a: order b a
        $res = 1;
    } elsif ($prb eq $ra) {
        # a is parent of b: order a b
        $res = -1;
    } elsif ($pra && !$prb) {
        # a has parent, b does not: order b a
        $res = 1;
    } elsif ($prb && !$pra) {
        # b has parent, a does not: order a b
        $res = -1;
    } else {
        # does not matter, use alphabetical sort
        $res = $ra cmp $rb;
    }

    return $res;
}

=item sort_parents

Sort arrayref of C<names> with data from C<items> using parent C<attr>.

=cut

sub sort_parents
{
    my ($names, $items, $attr) = @_;

    # Assume the id is equal to the name of the region
    my @snames = sort sort_parent (map {{name => $_, parent => $items->{$_}->{$attr}}} @$names);
    return map {$_->{name}} @snames;
}

=item rest

Convenience wrapper for direct REST calls
for C<method>, C<operation> and options C<ropts>.

=cut

sub rest
{
    my ($self, $method, $operation, %ropts) = @_;
    my $defropts = {
        method => $method,
        version => 'v3',
        service => 'identity',
    };

    %ropts = (%$defropts, %ropts);

    # generate raw data
    $ropts{raw} = {$operation => delete $ropts{data}} if ($ropts{data});

    my $endpoint = "${operation}s/" . (delete $ropts{what} || '') . "?name=name";

    return $self->rest(mkrequest($endpoint, $method, %ropts));
};

=item get_id

Return the ID of an C<operation>.
If the name is an ID, return the ID without a lookup.
If the operation is 'region', return the name.

Options

=over

=item error: report an error when no id is found

=item msg: use the value as (part of) the reported message

=back

=cut

sub get_id
{
    my ($self, $operation, $name, %opts) = @_;

    # region has no id (or no name, whatever you like)
    return $name if ($name =~ m/$IDREG/ || $operation eq 'region');

    # GET the list for name
    my $resp = $self->api_identity_rest('GET', $operation, result => "/${operation}s", params => {name => $name});

    my $msg = "found for $operation with name $name";
    $msg .= " $opts{msg}" if $opts{msg};

    my $id;
    if ($resp) {
        my @ids = (map {$_->{id}} @{$resp->result || []});
        if (scalar @ids > 1) {
            # what? do not return anything
            $self->error("More than one ID $msg: @ids");
        } elsif (@ids) {
            $id = $ids[0];
            $self->verbose("ID $id $msg");
        } else {
            my $method = $opts{error} ? 'error' : 'verbose';
            $self->$method("No ID $msg");
        }
    } else {
        $self->error("get_id invalid request $msg: $resp->{error}");
    };

    return $id;
}

# Function to retrun the name attribute based on the the operation
sub _name_attribute
{
    my ($operation) = @_;
    return $operation eq 'region' ? 'id' : 'name';
}

# Function to return the name based on the operation and data
sub _make_name
{
    my ($operation, $data) = @_;
    if ($operation eq 'endpoint') {
        # for endpoint, we construct an internal unique name based on
        # interface and url, seperated by a underscore
        return "$data->{interface}_$data->{url}";
    } else {
        my $attr = _name_attribute($operation);
        return $data->{$attr};
    }
}

=item tagstore_init

Function to initialise tagstore or return cached version based on tagstore project name.

=cut

sub tagstore_init
{
    my ($client, $tagstore_proj) = @_;

    if (!$_tagstores->{$tagstore_proj}) {

        # Does the project exist?
        my $resp = $client->api_identity_projects(name => $tagstore_proj);
        if ($resp) {
            my @proj = @{$resp->result};
            if (scalar @proj > 1) {
                $client->error("More than one tagstore project $tagstore_proj found: ids ",
                             join(",", map {$_->{id}} @proj), ". Unsupported for now");
                return;
            } elsif (scalar @proj == 1) {
                $client->verbose("Found one tagstore project $tagstore_proj id ", $proj[0]->{id});
            } else {
                $resp = $client->api_identity_add_project(name => $tagstore_proj,
                                                        description => "Main tagstore project $tagstore_proj");
                if ($resp) {
                    $client->verbose("Created main tagstore project $tagstore_proj id ", $resp->result->{id});
                } else {
                    $client->error("Failed to add main tagstore project $tagstore_proj: $resp->{error}");
                    return;
                }
            }
        } else {
            $client->error("Failed to list possible tagstore project $tagstore_proj: $resp->{error}");
            return;
        }

        # Get instance
        my $tgst = Net::OpenStack::Client::Identity::Tagstore->new(
            $client,
            $tagstore_proj,
            );

        if ($tgst) {
            $_tagstores->{$tagstore_proj} = $tgst;
        } else {
            $client->error("sync: failed to create new tagstore for project $tagstore_proj");
            return;
        }
    }

    return $_tagstores->{$tagstore_proj};
}

=item tagstore_postprocess

Function to postprocess sync operations when a tagstore is used.

=cut

sub tagstore_postprocess
{
    my ($tagstore, $phase, $operation, $name, $result) = @_;

    my $msg = "sync postprocess $operation $name stopped after failure to $phase";
    if (exists($result->{id})) {
        my $id = $result->{id};
        my $ok = 1;

        if ($phase eq 'create' || $phase eq 'delete') {
            my $method = $phase eq 'create' ? 'add' : $phase;
            $ok = $tagstore->$method("ID_${operation}_${id}");
        } else {
            $tagstore->verbose("sync: nothing to do for tagstore postprocessing during $phase for $name id $id");
        }

        if ($ok) {
            return 1;
        } else {
            $tagstore->error("$msg tag $id to tagstore. See previous error where to add the tag to continue");
            return;
        }
    } else {
        $tagstore->error("$msg no id in response");
        return;
    }
}

=pod

=back

=head1 Methods

=over

=item sync

For an C<operation> (like C<user>, C<group>, C<service>, ...),
given an hashref of C<items> (key is the name),
compare it with all existing items:

=over

=item Non-existing ones are added/created

=item Existing ones are possibly updated

=item Existing ones that are not requested are disbaled

=back

Returns a hasref with responses for the created items. The keys are
C<create>, C<update> and C<delete> and the values an arrayref of responses.

For C<endpoint> operations, as they have no name, use the C<<<interface>_<url>>>
as the name for the C<items> hashref.

Following options are supported:

=over

=item filter: a function to filter the existing items.
Return a true value to keep the existing item (false will ignore it).
By default, all existing items are considered.

=item delete: when the delete option is true, existing items that are
not in the C<items> hashref, will be deleted (instead of disabled).

=item keep: when the keep option is true, existing items that are
not in the C<items> hashref are ignored.
This precedes any value of C<delete> option.

=item tagstore: use project tagstore to track synced ids.
If no filter is set, the tagstore is used to filter known ids
as existing tags in the tagstore.

=back

=cut

sub sync
{
    my ($self, $operation, $items, %opts) = @_;

    if (! grep {$_ eq $operation} @SUPPORTED_OPERATIONS) {
        $self->error("Unsupported operation $operation");
        return;
    }

    my $tagstore;
    $tagstore = tagstore_init($self, $opts{tagstore}) if $opts{tagstore};

    my $filter;
    if ($opts{filter}) {
        $filter = $opts{filter};
        if (ref($filter) ne 'CODE') {
            $self->error("sync filter is not CODE");
            return;
        }
    } elsif ($tagstore) {
        $filter = sub {return $tagstore->get("ID_${operation}_".$_[0]->{id})};
    } else {
        $filter = sub {return 1};
    };

    # GET the list
    my $resp_list = $self->api_identity_rest('GET', $operation, result => "/${operation}s");

    my $found = {
        map {_make_name($operation, $_) => $_}
        grep {$filter->($_)}
        @{$resp_list->result || []}
    };

    my $existing = Set::Scalar->new(keys %$found);
    my $wanted = Set::Scalar->new(keys %$items);

    # Add default enabled=1 to all wanted operation
    foreach my $want (@$wanted) {
        $items->{$want}->{enabled} = convert(1, 'boolean') if ! exists($items->{$want}->{enabled});
    };

    # compare

    my @tocreate = sort @{$wanted - $existing};

    # regions and projects can have parent relations, so they need to be sorted accordingly
    # we only expect the order to be important with creation, not for updates or deletes
    #   the parent attr might also be the names, not the actual ids
    #   e.g. to support ordering not yet created parent
    my $parentattr = $PARENT_ATTR{$operation};
    @tocreate = sort_parents(\@tocreate, $items, $parentattr) if $parentattr;

    my $res = {
        create => [],
        update => [],
        delete => [],
    };

    my $postprocess;
    $postprocess = sub { return tagstore_postprocess($tagstore, @_) } if ($tagstore);

    my $created = $self->api_identity_create($operation, \@tocreate, $items, $res, $postprocess) or return;

    my @checkupdate = sort @{$wanted * $existing};
    $self->api_identity_update($operation, \@checkupdate, $found, $items, $res, $postprocess) or return;
    # no tagstore operations?

    my @toremove = sort @{$existing - $wanted};
    $self->api_identity_delete($operation, \@toremove, $found, \%opts, $res, $postprocess) or return;

    return $res;
}

=item get_item

Retrieve and augment an item with C<name> from hashref C<items>.

Modification to the data

=over

=item name is inserted (unless this is an endpoint)

=item any named ids (either from (other) operation(s) or parenting) are resolved
to their actual id.

=back

=cut

sub get_item
{
    my ($self, $operation, $name, $items) = @_;

    my $new = $items->{$name};

    if ($operation ne 'endpoint') {
        my $nameattr = _name_attribute($operation);
        # add name
        $new->{$nameattr} = $name;
    }

    # resolve ids
    my %toresolve = (map {$_."_id" => $_} @SUPPORTED_OPERATIONS);
    # resolve parent ids
    $toresolve{$PARENT_ATTR{$operation}} = $operation if $PARENT_ATTR{$operation};

    foreach my $attr (sort keys %toresolve) {
        # no autovivification
        next if ! exists($new->{$attr});

        my $resolved = $self->api_identity_get_id($toresolve{$attr}, $new->{$attr}, error => 1);
        if (defined($resolved)) {
            $new->{$attr} = $resolved;
        } else {
            $self->error("Failed to resolve id for $operation name $name attr $attr with value $new->{$attr}");
            return;
        }
    }

    return $new;
}

=item _process_response

Helper function for all 3 sync phases

C<res> is updated in place.

Returns 1 on success, undef otherwise (and reports an error).

=cut

sub _process_response
{
    my ($client, $phase, $resp, $res, $operation, $name, $postprocess) = @_;

    if ($resp) {
        my $result = $resp->result("/$operation");
        push(@{$res->{$phase}}, [$name, $result]);
        $client->verbose("sync: ${phase}d $operation $name");
        if ($postprocess) {
            $postprocess->($phase, $operation, $name, $result) or return;
        }
        return 1;
    } else {
        $client->error("sync: failed to $phase $operation $name: $resp->{error}");
        return;
    }
}


=item create

Create C<operation> items in arrayref C<tocreate> from configured C<items>
(using name attriute C<nameattr>),
with result hashref C<res>. C<res> is updated in place.

C<postprocess> is a anonymous function called after a succesful REST call,
and is passed following arguments:

=over

=item phase: one of C<create>, C<update> or C<delete>, depending on what pahse of the sync
the REST call is made.

=item operation: type of operation

=item name: name of the operation

=item result: result of the REST call

=back

=cut

sub create
{
    my ($self, $operation, $tocreate, $items, $res, $postprocess) = @_;

    my @tocreate = @$tocreate;

    if (@tocreate) {
        $self->info("Creating ${operation}s: @tocreate");
        foreach my $name (@tocreate) {
            # POST to create
            my $new = $self->api_identity_get_item($operation, $name, $items) or return;
            my $resp = $self->api_identity_rest('POST', $operation, data => $new);
            _process_response($self, 'create', $resp, $res, $operation, $name, $postprocess) or return;
        }
    } else {
        $self->verbose("No ${operation}s to create");
    }

    return 1;
}

=item update

Update C<operation> items in arrayref C<checkupdate> from C<found> items
with configured C<items>, with result hashref C<res>.
C<res> is updated in place.

=cut

sub update
{
    my ($self, $operation, $checkupdate, $found, $items, $res, $postprocess) = @_;

    my @checkupdate = @$checkupdate;

    if (@checkupdate) {
        $self->info("Possibly updating existing ${operation}s: @checkupdate");
        my @toupdate;
        foreach my $name (@checkupdate) {
            # anything to update?
            my $update;
            my $update_data = $self->api_identity_get_item($operation, $name, $items) or return;
            foreach my $attr (sort keys %$update_data) {
                my $wa = $update_data ->{$attr};
                my $fo = $found->{$name}->{$attr};
                my $action = $attr eq 'enabled' ? ($wa xor $fo): ($wa ne $fo);
                # hmmm, how to keep this JSON safe?
                $update->{$attr} = $wa if $action;
            }
            if (scalar keys %$update) {
                push(@toupdate, $name);
                my $resp = $self->api_identity_rest('PATCH', $operation, what => $found->{$name}->{id}, data => $update);
                _process_response($self, 'update', $resp, $res, $operation, $name, $postprocess) or return;
            }
        }
        $self->info(@toupdate ? "Updated existing ${operation}s: @toupdate" : "No existing ${operation}s updated");
    } else {
        $self->verbose("No existing ${operation}s to update");
    }

    return 1;
}

=item delete

Delete (or disable) C<operation> items in arrayref C<toremove> from C<found>
existing items, with options C<opts> (for C<delete> and C<ignore>)
and result hashref C<res>. C<res> is updated in place.

When C<ignore> option is true, nothing will happen.
When C<delete> is true, items will be delete; when items will be disabled.

=cut

sub delete
{
    my ($self, $operation, $toremove, $found, $opts, $res, $postprocess) = @_;

    my @toremove = @$toremove;

    my $dowhat = $opts->{delete} ? 'delet' : 'disabl';

    if (@toremove) {
        if ($opts->{ignore}) {
            $self->info("Ignoring existing ${operation}s (instead of ${dowhat}ing): @toremove");
        } else {
            $self->info(ucfirst($dowhat)."ing existing ${operation}s: @toremove");
            foreach my $name (@toremove) {
                my $resp;
                if ($opts->{delete}) {
                    # DELETE to delete
                    $resp = $self->api_identity_rest('DELETE', $operation, what => $found->{$name}->{id});
                } else {
                    # PATCH to disable
                    # do not disable if already disabled
                    if ($found->{$name}->{enabled}) {
                        $resp = $self->api_identity_rest('PATCH', $operation,
                                                         what => $found->{$name}->{id},
                                                         data => {enabled => convert(0, 'boolean')});
                    } else {
                        $self->verbose("Not disabling already disabled ".
                                     "$operation $name (id ".$found->{$name}->{id}.")");
                    }
                }

                if (defined($resp)) {
                    _process_response($self, 'delete', $resp, $res, $operation, $name, $postprocess) or return;
                }
            }
        }
    } else {
        $self->verbose("No existing ${operation}s to ${dowhat}e");
    }

    return 1;
}


=item sync_rolemap

Add missing roles for project/domain and group/user,
and delete any when tagstore is used.

The roles are defined with a nested hashref, like
the url is structured (with an arrayref of roles as value).
E.g.
    $roles = {
        domain => {
            dom1 => {
                user => {
                    user1 => [role1 role2],
                    ...
                },
                group => {
                    ...
                    },
                },
            ...
        project => {
           ...
           },
        }

Options

=over

=item tagstore: use project tagstore to track synced roles.

=back

=cut


sub sync_rolemap
{
    my ($self, $roles, %opts) = @_;

    # Get all roles from tagstore (if defined)
    # The role tag is ROLE_url
    # url is
    #    projects/{project_id} OR domains/{domain_id} +
    #      groups/{group_id} OR users/{user_id} +
    #      roles/{role_id}

    # Will use url as identifier

    my ($tagstore, @found);

    if ($opts{tagstore}) {
        $tagstore = tagstore_init($self, $opts{tagstore}) if $opts{tagstore};
        # Strip ROLE_, decode/unescape the url
        @found = map {my $url = $_; $url =~ s/^ROLE_//; decode_base64url($url)} grep {m/^ROLE_/} sort keys %{$tagstore->fetch};
    };
    my $existing = Set::Scalar->new(@found);

    # create hash: key is url, value is 1
    my $items;
    foreach my $base (qw(project domain)) {
        foreach my $bval (sort keys %{$roles->{$base} || {}}) {
            my $bid = $self->api_identity_get_id($base, $bval, error => 1, msg => 'for role sync')
                or return;
            foreach my $who (qw(user group)) {
                foreach my $wval (sort keys %{$roles->{$base}->{$bval}->{$who} || {}}) {
                    my $wid = $self->api_identity_get_id($who, $wval, error => 1, msg => 'for role sync')
                        or return;
                    foreach my $role (@{$roles->{$base}->{$bval}->{$who}->{$wval}}) {
                        my $rid = $self->api_identity_get_id('role', $role, error => 1, msg => 'for role sync')
                            or return;
                        $items->{"${base}s/$bid/${who}s/$wid/roles/$rid"} = 1;
                    }
                }
            };
        };
    };

    my $wanted = Set::Scalar->new(keys %$items);

    my $rest = sub {
        my ($urls, $method, $tagmethod) = @_;

        if (@$urls) {
            $self->verbose("roles sync: going to $tagmethod @$urls");
        } else {
            $self->verbose("roles sync: nothing to $tagmethod");
            return 1;
        };

        foreach my $url (@$urls) {
            my $resp = $self->rest(mkrequest($url, $method, version => 'v3', service => 'identity'));
            if ($resp) {
                if ($tagstore) {
                    my $tag = "ROLE_" . encode_base64url($url);
                    if (!$tagstore->$tagmethod($tag)) {
                        $tagstore->error("Failed to $tagmethod tag $tag to tagstore. ".
                                         "See previous error where to add the tag to continue");
                        return;
                    }
                }
            } else {
                $self->error("Failed to sync role $method $url");
                return;
            }
        }
        return 1
    };

    # Add new ones
    my @tocreate = sort @{$wanted - $existing};
    $rest->(\@tocreate, 'PUT', 'add') or return;

    # Delete unknown
    my @toremove = sort @{$existing - $wanted};
    $rest->(\@toremove, 'DELETE', 'delete') or return;

    return 1;
}

=pod

=back

=cut

1;
