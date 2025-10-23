# BEGIN BPS TAGGED BLOCK {{{
#
# COPYRIGHT:
#
# This software is Copyright (c) 1996-2025 Best Practical Solutions, LLC
#                                          <sales@bestpractical.com>
#
# (Except where explicitly superseded by other copyright notices)
#
#
# LICENSE:
#
# This work is made available to you under the terms of Version 2 of
# the GNU General Public License. A copy of that license should have
# been provided with this software, but in any event can be snarfed
# from www.gnu.org.
#
# This work is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA
# 02110-1301 or visit their web page on the internet at
# http://www.gnu.org/licenses/old-licenses/gpl-2.0.html.
#
#
# CONTRIBUTION SUBMISSION POLICY:
#
# (The following paragraph is not intended to limit the rights granted
# to you to modify and distribute this software under the terms of
# the GNU General Public License and is only of importance to you if
# you choose to contribute your changes and enhancements to the
# community by submitting them to Best Practical Solutions, LLC.)
#
# By intentionally submitting any modifications, corrections or
# derivatives to this work, or any other work intended for use with
# Request Tracker, to Best Practical Solutions, LLC, you confirm that
# you are the copyright holder for those contributions and you grant
# Best Practical Solutions,  LLC a nonexclusive, worldwide, irrevocable,
# royalty-free, perpetual, license to use, copy, create derivative
# works based on those contributions, and sublicense and distribute
# those contributions and any derivatives thereof.
#
# END BPS TAGGED BLOCK }}}

package RT::REST2::Resource::User;
use strict;
use warnings;

use Moose;
use namespace::autoclean;
use JSON ();
use RT::REST2::Util qw( error_as_json );

has 'action' => (
    is  => 'ro',
    isa => 'Str',
);

has 'merge_data' => (
    is  => 'rw',
    isa => 'HashRef',
);

around 'dispatch_rules' => sub {
    my $orig = shift;
    my $class = shift;

    return (
        $orig->($class, @_),
        Path::Dispatcher::Rule::Regex->new(
            regex => qr{^/user/(\d+)/(merge|unmerge)$},
            block => sub {
                my ($match, $req) = @_;
                my $user = RT::User->new($req->env->{"rt.current_user"});
                $user->LoadOriginal( id => $match->pos(1) );
                return {
                    record => $user,
                    action => $match->pos(2),
                };
            },
        ),
        Path::Dispatcher::Rule::Regex->new(
            regex => qr{^/user/([^/]+)/(merge|unmerge)$},
            block => sub {
                my ($match, $req) = @_;
                my $user = RT::User->new($req->env->{"rt.current_user"});
                $user->LoadOriginal( Name => $match->pos(1) );
                return {
                    record => $user,
                    action => $match->pos(2),
                };
            },
        ),
    );
};

around 'content_types_accepted' => sub {
    my $orig = shift;
    my $self = shift;

    if ($self->action && ($self->action eq 'merge' || $self->action eq 'unmerge')) {
        return [ { 'application/json' => 'handle_merge_action' } ];
    }

    return $self->$orig(@_);
};

around 'allowed_methods' => sub {
    my $orig = shift;
    my $self = shift;

    if ($self->action) {
        return ['POST'];
    }

    return $self->$orig(@_);
};

sub handle_merge_action {
    my $self = shift;

    unless ($self->current_user->HasRight(Right => 'AdminUsers', Object => RT->System)) {
        return error_as_json(
            $self->response,
            \403, "Permission denied");
    }

    my $body;
    eval {
        my $content = $self->request->content;
        $body = $content ? JSON::decode_json($content) : {};
    };
    if ($@) {
        return error_as_json(
            $self->response,
            \400, "Invalid JSON: $@");
    }

    my $action = $self->action;

    if ($action eq 'merge') {
        return $self->_handle_merge($body);
    }
    elsif ($action eq 'unmerge') {
        return $self->_handle_unmerge($body);
    }
}

sub _handle_merge {
    my $self = shift;
    my $body = shift;

    unless ($body && $body->{User}) {
        return error_as_json(
            $self->response,
            \400, "User is a required field");
    }

    my $target_user = RT::User->new( $self->current_user );
    $target_user->Load( $body->{User} );

    unless ($target_user->Id) {
        return error_as_json(
            $self->response,
            \400, "Unable to load user: " . $body->{User});
    }

    my ($ok, $msg) = $self->record->MergeInto( $target_user );

    if ($ok) {
        my $result = {
            message => $msg,
            merged_user => {
                id => $self->record->Id,
                name => $self->record->Name,
            },
            target_user => {
                id => $target_user->Id,
                name => $target_user->Name,
            },
        };

        $self->response->body( JSON::encode_json($result) );
        $self->response->content_type('application/json; charset=utf-8');
        return 1;
    } else {
        return error_as_json(
            $self->response,
            \400, $msg || "Merge failed for unknown reason");
    }
}

sub _handle_unmerge {
    my $self = shift;
    my $body = shift;

    # Two modes:
    # 1. No params: unmerge ALL secondary users from this primary user (default)
    # 2. {"User": "id/name"}: unmerge specified secondary user from this primary user

    if ($body->{User}) {
        return $self->_unmerge_specific($body->{User});
    }
    else {
        return $self->_unmerge_all();
    }
}

sub _unmerge_specific {
    my $self = shift;
    my $user_identifier = shift;

    my $secondary_user = RT::User->new( $self->current_user );
    $secondary_user->LoadOriginal(
        $user_identifier =~ /^\d+$/ ? (id => $user_identifier) : (Name => $user_identifier)
    );

    unless ($secondary_user->Id) {
        return error_as_json(
            $self->response,
            \400, "Unable to load user: $user_identifier");
    }

    my ($effective_id_attr) = $secondary_user->Attributes->Named("EffectiveId");
    unless ($effective_id_attr && $effective_id_attr->Content == $self->record->Id) {
        return error_as_json(
            $self->response,
            \400, "User " . $secondary_user->Name . " is not merged into " . $self->record->Name);
    }

    my ($ok, $msg) = $secondary_user->UnMerge();

    if ($ok) {
        my $result = {
            message => $msg,
            unmerged_user => {
                id => $secondary_user->Id,
                name => $secondary_user->Name,
            },
            from_primary_user => {
                id => $self->record->Id,
                name => $self->record->Name,
            },
        };

        $self->response->body( JSON::encode_json($result) );
        $self->response->content_type('application/json; charset=utf-8');
        return 1;
    } else {
        return error_as_json(
            $self->response,
            \400, $msg || "UnMerge failed for unknown reason");
    }
}

sub _unmerge_all {
    my $self = shift;

    my $merged_users = $self->record->GetMergedUsers;
    my @merged_user_ids = @{$merged_users->Content || []};

    unless (@merged_user_ids) {
        return error_as_json(
            $self->response,
            \400, "No users are merged into " . $self->record->Name);
    }

    my @results;
    my @unmerged;

    foreach my $user_id (@merged_user_ids) {
        my $secondary_user = RT::User->new( $self->current_user );
        $secondary_user->LoadOriginal( id => $user_id );

        if ($secondary_user->Id) {
            my ($ok, $msg) = $secondary_user->UnMerge();
            if ($ok) {
                push @unmerged, {
                    id => $secondary_user->Id,
                    name => $secondary_user->Name,
                    message => $msg,
                };
            }
            push @results, $msg;
        }
    }

    if (@unmerged) {
        my $result = {
            message => "Unmerged " . scalar(@unmerged) . " user(s) from " . $self->record->Name,
            unmerged_users => \@unmerged,
            primary_user => {
                id => $self->record->Id,
                name => $self->record->Name,
            },
        };

        $self->response->body( JSON::encode_json($result) );
        $self->response->content_type('application/json; charset=utf-8');
        return 1;
    } else {
        return error_as_json(
            $self->response,
            \400, "Failed to unmerge users: " . join(", ", @results));
    }
}

1;
