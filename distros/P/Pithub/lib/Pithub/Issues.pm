package Pithub::Issues;
our $AUTHORITY = 'cpan:PLU';
our $VERSION = '0.01040';
# ABSTRACT: Github v3 Issues API

use Moo;
use Carp qw( croak );
use Pithub::Issues::Assignees;
use Pithub::Issues::Comments;
use Pithub::Issues::Events;
use Pithub::Issues::Labels;
use Pithub::Issues::Milestones;
extends 'Pithub::Base';


sub assignees {
    return shift->_create_instance('Pithub::Issues::Assignees', @_);
}


sub comments {
    return shift->_create_instance('Pithub::Issues::Comments', @_);
}


sub create {
    my ( $self, %args ) = @_;
    croak 'Missing key in parameters: data (hashref)' unless ref $args{data} eq 'HASH';
    $self->_validate_user_repo_args( \%args );
    return $self->request(
        method => 'POST',
        path   => sprintf( '/repos/%s/%s/issues', delete $args{user}, delete $args{repo} ),
        %args,
    );
}


sub events {
    return shift->_create_instance('Pithub::Issues::Events', @_);
}


sub get {
    my ( $self, %args ) = @_;
    croak 'Missing key in parameters: issue_id' unless $args{issue_id};
    $self->_validate_user_repo_args( \%args );
    return $self->request(
        method => 'GET',
        path   => sprintf( '/repos/%s/%s/issues/%s', delete $args{user}, delete $args{repo}, delete $args{issue_id} ),
        %args,
    );
}


sub labels {
    return shift->_create_instance('Pithub::Issues::Labels', @_);
}


sub list {
    my ( $self, %args ) = @_;
    $self->_get_user_repo_args( \%args );
    if ( $args{user} && $args{repo} ) {
        return $self->request(
            method => 'GET',
            path   => sprintf( '/repos/%s/%s/issues', delete $args{user}, delete $args{repo} ),
            %args,
        );
    }
    return $self->request(
        method => 'GET',
        path   => sprintf('/issues'),
        %args,
    );
}


sub milestones {
    return shift->_create_instance('Pithub::Issues::Milestones', @_);
}


sub update {
    my ( $self, %args ) = @_;
    croak 'Missing key in parameters: issue_id' unless $args{issue_id};
    croak 'Missing key in parameters: data (hashref)' unless ref $args{data} eq 'HASH';
    $self->_validate_user_repo_args( \%args );
    return $self->request(
        method => 'PATCH',
        path   => sprintf( '/repos/%s/%s/issues/%s', delete $args{user}, delete $args{repo}, delete $args{issue_id} ),
        %args,
    );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Pithub::Issues - Github v3 Issues API

=head1 VERSION

version 0.01040

=head1 METHODS

=head2 assignees

Provides access to L<Pithub::Issues::Assignees>.

=head2 comments

Provides access to L<Pithub::Issues::Comments>.

=head2 create

=over

=item *

Create an issue

    POST /repos/:user/:repo/issues

Parameters:

=over

=item *

B<user>: mandatory string

=item *

B<repo>: mandatory string

=item *

B<data>: mandatory hashref, having following keys:

=over

=item *

B<title>: mandatory string

=item *

B<body>: optional string

=item *

B<assignee>: optional string - Login for the user that this issue
should be assigned to.

=item *

B<milestone>: optional number - Milestone to associate this issue
with.

=item *

B<labels>: optional arrayref of strings - Labels to associate with this
issue.

=back

=back

Examples:

    my $i = Pithub::Issues->new;
    my $result = $i->create(
        user => 'plu',
        repo => 'Pithub',
        data => {
            assignee  => 'octocat',
            body      => "I'm having a problem with this.",
            labels    => [ 'Label1', 'Label2' ],
            milestone => 1,
            title     => 'Found a bug'
        }
    );

Response: B<Status: 201 Created>

    {
        "url": "https://api.github.com/repos/octocat/Hello-World/issues/1",
        "html_url": "https://github.com/octocat/Hello-World/issues/1",
        "number": 1347,
        "state": "open",
        "title": "Found a bug",
        "body": "I'm having a problem with this.",
        "user": {
            "login": "octocat",
            "id": 1,
            "gravatar_url": "https://github.com/images/error/octocat_happy.gif",
            "url": "https://api.github.com/users/octocat"
        },
        "labels": [
        {
            "url": "https://api.github.com/repos/octocat/Hello-World/labels/bug",
            "name": "bug",
            "color": "f29513"
        }
        ],
        "assignee": {
            "login": "octocat",
            "id": 1,
            "gravatar_url": "https://github.com/images/error/octocat_happy.gif",
            "url": "https://api.github.com/users/octocat"
        },
        "milestone": {
            "url": "https://api.github.com/repos/octocat/Hello-World/milestones/1",
            "number": 1,
            "state": "open",
            "title": "v1.0",
            "description": "",
            "creator": {
                "login": "octocat",
                "id": 1,
                "gravatar_url": "https://github.com/images/error/octocat_happy.gif",
                "url": "https://api.github.com/users/octocat"
            },
            "open_issues": 4,
            "closed_issues": 8,
            "created_at": "2011-04-10T20:09:31Z",
            "due_on": null
        },
        "comments": 0,
        "pull_request": {
            "html_url": "https://github.com/octocat/Hello-World/issues/1",
            "diff_url": "https://github.com/octocat/Hello-World/issues/1.diff",
            "patch_url": "https://github.com/octocat/Hello-World/issues/1.patch"
        },
        "closed_at": null,
        "created_at": "2011-04-22T13:33:48Z",
        "updated_at": "2011-04-22T13:33:48Z"
    }

=back

=head2 events

Provides access to L<Pithub::Issues::Events>.

=head2 get

=over

=item *

Get a single issue

    GET /repos/:user/:repo/issues/:id

Parameters:

=over

=item *

B<user>: mandatory string

=item *

B<repo>: mandatory string

=item *

B<issue_id>: mandatory integer

=back

Examples:

    my $i = Pithub::Issues->new;
    my $result = $i->get(
        user => 'plu',
        repo => 'Pithub',
        issue_id => 1,
    );

Response: B<Status: 200 OK>

    {
        "url": "https://api.github.com/repos/octocat/Hello-World/issues/1",
        "html_url": "https://github.com/octocat/Hello-World/issues/1",
        "number": 1347,
        "state": "open",
        "title": "Found a bug",
        "body": "I'm having a problem with this.",
        "user": {
            "login": "octocat",
            "id": 1,
            "gravatar_url": "https://github.com/images/error/octocat_happy.gif",
            "url": "https://api.github.com/users/octocat"
        },
        "labels": [
        {
            "url": "https://api.github.com/repos/octocat/Hello-World/labels/bug",
            "name": "bug",
            "color": "f29513"
        }
        ],
        "assignee": {
            "login": "octocat",
            "id": 1,
            "gravatar_url": "https://github.com/images/error/octocat_happy.gif",
            "url": "https://api.github.com/users/octocat"
        },
        "milestone": {
            "url": "https://api.github.com/repos/octocat/Hello-World/milestones/1",
            "number": 1,
            "state": "open",
            "title": "v1.0",
            "description": "",
            "creator": {
                "login": "octocat",
                "id": 1,
                "gravatar_url": "https://github.com/images/error/octocat_happy.gif",
                "url": "https://api.github.com/users/octocat"
            },
            "open_issues": 4,
            "closed_issues": 8,
            "created_at": "2011-04-10T20:09:31Z",
            "due_on": null
        },
        "comments": 0,
        "pull_request": {
            "html_url": "https://github.com/octocat/Hello-World/issues/1",
            "diff_url": "https://github.com/octocat/Hello-World/issues/1.diff",
            "patch_url": "https://github.com/octocat/Hello-World/issues/1.patch"
        },
        "closed_at": null,
        "created_at": "2011-04-22T13:33:48Z",
        "updated_at": "2011-04-22T13:33:48Z"
    }

=back

=head2 labels

Provides access to L<Pithub::Issues::Labels>.

=head2 list

=over

=item *

List the issues of the authenticated user

    GET /issues

This API call can be influenced via the C<< params >>
hashref with following parameters:

=over

=item *

B<filter>: one of the following:

=over

=item *

B<assigned>: Issues assigned to you (default)

=item *

B<created>: Issues created by you

=item *

B<mentioned>: Issues mentioning you

=item *

B<subscribed>: Issues you're subscribed to updates for

=back

=item *

B<state>: one of the following:

=over

=item *

B<open> (default)

=item *

B<closed>

=back

=item *

B<labels>: String list of comma separated Label names.
Example: C<< bug,ui,@high >>

=item *

B<sort>: one of the following:

=over

=item *

B<created> (default)

=item *

B<updated>

=item *

B<comments>

=back

=item *

B<direction>: one of the following:

=over

=item *

B<asc>

=item *

B<desc> (default)

=back

=item *

B<since>: optional string of a timestamp in ISO 8601 format: YYYY-MM-DDTHH:MM:SSZ

=back

Examples:

    my $i      = Pithub::Issues->new;
    my $result = $i->list(
        params => {
            filter    => 'assigned',
            state     => 'open',
            labels    => 'bug',
            sort      => 'updated',
            direction => 'asc',
        }
    );

Response: B<Status: 200 OK>

    [
        {
            "url": "https://api.github.com/repos/octocat/Hello-World/issues/1",
            "html_url": "https://github.com/octocat/Hello-World/issues/1",
            "number": 1347,
            "state": "open",
            "title": "Found a bug",
            "body": "I'm having a problem with this.",
            "user": {
                "login": "octocat",
                "id": 1,
                "gravatar_url": "https://github.com/images/error/octocat_happy.gif",
                "url": "https://api.github.com/users/octocat"
            },
            "labels": [
            {
                "url": "https://api.github.com/repos/octocat/Hello-World/labels/bug",
                "name": "bug",
                "color": "f29513"
            }
            ],
            "assignee": {
                "login": "octocat",
                "id": 1,
                "gravatar_url": "https://github.com/images/error/octocat_happy.gif",
                "url": "https://api.github.com/users/octocat"
            },
            "milestone": {
                "url": "https://api.github.com/repos/octocat/Hello-World/milestones/1",
                "number": 1,
                "state": "open",
                "title": "v1.0",
                "description": "",
                "creator": {
                    "login": "octocat",
                    "id": 1,
                    "gravatar_url": "https://github.com/images/error/octocat_happy.gif",
                    "url": "https://api.github.com/users/octocat"
                },
                "open_issues": 4,
                "closed_issues": 8,
                "created_at": "2011-04-10T20:09:31Z",
                "due_on": null
            },
            "comments": 0,
            "pull_request": {
                "html_url": "https://github.com/octocat/Hello-World/issues/1",
                "diff_url": "https://github.com/octocat/Hello-World/issues/1.diff",
                "patch_url": "https://github.com/octocat/Hello-World/issues/1.patch"
            },
            "closed_at": null,
            "created_at": "2011-04-22T13:33:48Z",
            "updated_at": "2011-04-22T13:33:48Z"
        }
    ]

=item *

List issues for a repository

    GET /repos/:user/:repo/issues

Parameters:

=over

=item *

B<user>: mandatory string

=item *

B<repo>: mandatory string

=back

This API call can be influenced via the C<< params >>
hashref with following parameters:

=over

=item *

B<milestone>: one of the following:

=over

=item *

C<< Integer >> Milestone number

=item *

C<< none >> for Issues with no Milestone

=item *

C<< * >> for Issues with any Milestone

=back

=item *

B<state>: one of the following:

=over

=item *

B<open> (default)

=item *

B<closed>

=back

=item *

B<assignee>: one of the following:

=over

=item *

C<< String >> User login

=item *

C<< none >> for Issues with no assigned User

=item *

C<< * >> for Issues with any assigned User

=back

=item *

B<mentioned>: String User login

=item *

B<labels>: String list of comma separated Label names.
Example: C<< bug,ui,@high >>

=item *

B<sort>: one of the following:

=over

=item *

B<created> (default)

=item *

B<updated>

=item *

B<comments>

=back

=item *

B<direction>: one of the following:

=over

=item *

B<asc>

=item *

B<desc> (default)

=back

=item *

B<since>: optional string of a timestamp in ISO 8601 format: YYYY-MM-DDTHH:MM:SSZ

=back

Examples:

    my $i      = Pithub::Issues->new;
    my $result = $i->list(
        user    => 'plu',
        repo    => 'Pithub',
        params => {
            milestone => 42,
            state     => 'open',
            labels    => 'bug',
            sort      => 'updated',
            direction => 'asc',
        }
    );

Response: B<Status: 200 OK>

    [
        {
            "url": "https://api.github.com/repos/octocat/Hello-World/issues/1",
            "html_url": "https://github.com/octocat/Hello-World/issues/1",
            "number": 1347,
            "state": "open",
            "title": "Found a bug",
            "body": "I'm having a problem with this.",
            "user": {
                "login": "octocat",
                "id": 1,
                "gravatar_url": "https://github.com/images/error/octocat_happy.gif",
                "url": "https://api.github.com/users/octocat"
            },
            "labels": [
            {
                "url": "https://api.github.com/repos/octocat/Hello-World/labels/bug",
                "name": "bug",
                "color": "f29513"
            }
            ],
            "assignee": {
                "login": "octocat",
                "id": 1,
                "gravatar_url": "https://github.com/images/error/octocat_happy.gif",
                "url": "https://api.github.com/users/octocat"
            },
            "milestone": {
                "url": "https://api.github.com/repos/octocat/Hello-World/milestones/1",
                "number": 1,
                "state": "open",
                "title": "v1.0",
                "description": "",
                "creator": {
                    "login": "octocat",
                    "id": 1,
                    "gravatar_url": "https://github.com/images/error/octocat_happy.gif",
                    "url": "https://api.github.com/users/octocat"
                },
                "open_issues": 4,
                "closed_issues": 8,
                "created_at": "2011-04-10T20:09:31Z",
                "due_on": null
            },
            "comments": 0,
            "pull_request": {
                "html_url": "https://github.com/octocat/Hello-World/issues/1",
                "diff_url": "https://github.com/octocat/Hello-World/issues/1.diff",
                "patch_url": "https://github.com/octocat/Hello-World/issues/1.patch"
            },
            "closed_at": null,
            "created_at": "2011-04-22T13:33:48Z",
            "updated_at": "2011-04-22T13:33:48Z"
        }
    ]

=back

=head2 milestones

Provides access to L<Pithub::Issues::Milestones>.

=head2 update

=over

=item *

Edit an issue

    PATCH /repos/:user/:repo/issues/:id

Parameters:

=over

=item *

B<user>: mandatory string

=item *

B<repo>: mandatory string

=item *

B<data>: mandatory hashref, having following keys:

=over

=item *

B<title>: mandatory string

=item *

B<body>: optional string

=item *

B<assignee>: optional string - Login for the user that this issue
should be assigned to.

=item *

B<milestone>: optional number - Milestone to associate this issue
with.

=item *

B<labels>: optional arrayref of strings - Labels to associate with
this issue. Pass one or more Labels to replace the set of Labels
on this Issue. Send an empty arrayref (C<< [] >>) to clear all
Labels from the Issue.

=back

=back

Examples:

    my $i = Pithub::Issues->new;
    my $result = $i->update(
        user     => 'plu',
        repo     => 'Pithub',
        issue_id => 1,
        data     => {
            assignee  => 'octocat',
            body      => "I'm having a problem with this.",
            labels    => [ 'Label1', 'Label2' ],
            milestone => 1,
            state     => 'open',
            title     => 'Found a bug'
        }
    );

=back

=head1 AUTHOR

Johannes Plunien <plu@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Johannes Plunien.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
