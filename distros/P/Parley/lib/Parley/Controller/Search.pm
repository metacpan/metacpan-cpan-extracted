package Parley::Controller::Search;
# vim: ts=8 sts=4 et sw=4 sr sta
use strict;
use warnings;

use Parley::Version;  our $VERSION = $Parley::VERSION;
use base 'Catalyst::Controller::FormValidator';

use Data::Dump qw(pp);
use Date::Manip;
use Text::Search::SQL;
use URI;
use URI::QueryParam;
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Global class data
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

my %dfv_profile_for = (
    # DFV validation profile for adding a new topic
    advanced => {
        required    => [qw< match_type >],
        require_some => {
            search_terms => [
                1,
                qw<
                    author_search_terms
                    message_search_terms
                    subject_search_terms
                    search_post_date
                >
            ]
        },
        optional    => [qw<
            author_search_terms
            message_search_terms
            subject_search_terms
            author_search_type
            message_search_type
            subject_search_type
            search_post_date
            search_forum
        >],
        filters     => [qw< trim >],
    },
);

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Controller Actions
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

sub index : Private {
    my ( $self, $c ) = @_;
    $c->forward('advanced');
}

sub end :Private {
    my ($self, $c) = @_;

    # we're likely to want pages results for numerous seaches
    $self->_results_view_pager($c);

    # finish processing the page and display
    $c->forward('/end');
}

sub advanced : Local {
    my ($self, $c) = @_;
    # because we're potentially being forwarded to from / set the template
    # explicitly
    $c->stash->{template} = q{search/advanced};

    # if we have a method and any (GET) parameters, do the searchy stuff
    if (
        keys %{$c->request->query_parameters}
            and
        defined $c->request->method
    ) {
        $c->forward('form_check', [$dfv_profile_for{advanced}, 'GET']);

        # everything passed (DFV) validation
        if ($c->stash->{validation}->success) {
            my $foo = $c->stash->{search_results};
            $c->forward('do_advanced_search');
        }
        # something didn't validate
        else {
            $c->log->debug(
                q{Something didn't validate}
                #pp($c->stash->{validation})
            );
        }
    }

    return;
}

sub forum :Local {
    my ($self, $c) = @_;
    my ($search_terms, $resultset, $tss, $search_where, $where, @join);

    # page to show - either a param, or show the first
    $c->stash->{current_page}= $c->request->param('page') || 1;

    # the search terms
    $search_terms = $c->request->param('search_terms');

    # if we don't have anything to search for ..
    if (not defined $search_terms or $search_terms =~ m{\A\s*\z}xms) {
        return;
    }

    # start with no join(s)
    @join = ();

    # save the search terms for the template to display
    $c->stash->{search_terms}{raw} = $search_terms;

    # get a suitable where-clause to use based on the search terms
    $tss = Text::Search::SQL->new(
        {
            search_term     => $search_terms,
            search_type     => q{ilike},
            search_fields   => [ qw(me.subject me.message) ],
        }
    );
    $tss->parse();
    $search_where = $tss->get_sql_where();
    $c->log->debug(
        pp $search_where
    );

    # build the where clause to pass to our search
    $where = {
        # we want to OR the items in $sql_where
        -or => $search_where,
    };
    $c->log->debug(pp($where));

    # if we have a search_forum, limit to that
    if (defined $c->request->param('search_forum')) {
        my ($forum);
        eval {
            $forum = $c->model('ParleyDB')->resultset('Forum')->find(
                {
                    'me.id'    => $c->request->param('search_forum'),
                }
            );
        };

        if (defined $forum) {
            $where->{'thread.forum_id'} = $forum->id(),
            push @join, 'thread';
            # put in the stash
            $c->stash->{search_forum} = $forum;
        }
    }

    # search for any posts in the forum with the search_terms (phrase) in the
    # subject or body
    $resultset = $c->model('ParleyDB')->resultset('Post')->search(
        $where,
        {
            join        => \@join,
            order_by    => [\'created DESC'],
            # results paging
            rows        => $c->config->{search_results_per_page},
            page        => $c->stash->{current_page},
        }
    );

    if ($resultset->count() > 0) {
        $c->stash->{search_results} = $resultset;
    }
}

sub do_advanced_search : Private {
    my ($self, $c) = @_;
    my $results = $c->stash->{validation};
    my ($where, $search_where, $resultset, @join, $order_by, @forum_ids);

    # default ORDER BY
    $order_by = [\'created DESC'];

    # page to show - either a param, or show the first
    $c->stash->{current_page}= $c->request->param('page') || 1;

    $search_where = undef;
    foreach my $search_field (qw<author message subject date>) {
        # process the search field
        my $results = 
            $c->forward(q{search_clauses_} . $search_field);
        if (defined $results) {
            my ($extra_clauses, $extra_joins) = @{ $results };

            # add any search clauses
            if ($extra_clauses) {
                push @{$search_where}, @$extra_clauses;
            }
            # add any required table joins
            if ($extra_joins) {
                push @join, @$extra_joins;
            }
        }
    }

    # are we limiting to a particular (list of) forum(s)
    if (defined $results->valid('search_forum')) {
        if (
            defined(ref $results->valid('search_forum'))
                and
            (q{ARRAY} eq ref($results->valid('search_forum')))
        ) {
            @forum_ids = sort @{ $results->valid('search_forum') };
        }
        else {
            @forum_ids = ( $results->valid('search_forum') );
        }
    }

    # make sure we're searching for something
    # if it turns out we're searching for nothingness, return an empty
    # result set
    if (not defined $search_where) {
        return; # no need to do anything else
    }

    # build the where clause to pass to our search
    if (q{any} eq $results->valid('match_type')) {
        $where = {
            # we want to OR the items in $sql_where
            -or => $search_where,
        };
        # ... AND in the list of forums to resrict to
        if (@forum_ids) {
            $where->{'-and'} =
                [ 'thread.forum_id' => { 'IN', \@forum_ids } ];
        }
    }
    elsif (q{all} eq $results->valid('match_type')) {
        if (@forum_ids) {
            push @{$search_where},
                'thread.forum_id' => { 'IN', \@forum_ids };
        }
        $where = {
            # we want to OR the items in $sql_where
            -and => $search_where,
        };
    }

    $c->log->debug('SEARCH TERMS: ' . pp($where)) if (0);

    $resultset = $c->model('ParleyDB')->resultset('Post')->search(
        $where,
        {
            join        => \@join,
            order_by    => $order_by,
            # results paging
            rows        => $c->config->{search_results_per_page},
            page        => $c->stash->{current_page},
        }
    );

    # if we have any matches, stash them
    if ($resultset->count() > 0) {
        $c->stash->{search_results} = $resultset;
    }

    return;
}

sub add_search_clauses : Private {
    my ($self, $c, $current_clauses, $type, $search_field, $terms) = @_;
    my @search_where;

    # do we have any terms to search for?
    if ($terms) {
        if (q{contains} eq $type) {
            push @search_where,
                $search_field,
                { ilike => q{%} . $terms .  q{%} }
            ;
        }
        elsif (q{exact} eq $type) {
            push @search_where,
                $search_field,
                { q{=}  => $terms }
            ;
        }
        else {
            $c->log->error(qq{fsc/$search_field: hmm, what's the search type?});
            return;
        }
    }
    # no terms, nothing to do
    else {
        return;
    }

    # add to the current list of search clauses
    push @{$current_clauses}, @search_where;

    return;
}

sub search_clauses_author : Private {
    my ($self, $c) = @_;
    my $results = $c->stash->{validation};
    my $search_field = 'author';
    my @search_where;
    my @joins;

    my $terms = $results->valid(
            $search_field
        . q{_search_terms}
    );
    my $type = $results->valid(
            $search_field
        . q{_search_type}
    ) || q{};

    # add search clauses for the forum_name of the post's creator
    $c->forward(
        add_search_clauses => [\@search_where, $type, 'creator.forum_name', $terms]
    );
    # add the required JOIN relation name
    push @joins, 'creator';

    return [\@search_where, \@joins];
}

sub search_clauses_date : Private {
    my ($self, $c) = @_;
    my $results = $c->stash->{validation};
    my $terms = $results->valid('search_post_date');
    my (@search_where);

    # if we don't have date "stuff", don't add any terms
    if (not $terms) {
        return []; # add nothing at all
    }

    # the mapping from form values to search clauses
    my %search_clauses = (
        last_hour => {
            '>=' => UnixDate('1 hour ago', "%Y-%m-%d %H:%M:%S")
        },
        last_day => {
            '>=' => UnixDate('1 day ago', "%Y-%m-%d %H:%M:%S")
        },
        last_month => {
            '>=' => UnixDate('1 month ago', "%Y-%m-%d %H:%M:%S")
        },
        last_six_months => {
            '>=' => UnixDate('6 months ago', "%Y-%m-%d %H:%M:%S")
        },
        last_year => {
            '>=' => UnixDate('1 year ago', "%Y-%m-%d %H:%M:%S")
        },
        over_a_year => {
            '<' => UnixDate('1 year ago', "%Y-%m-%d %H:%M:%S")
        },
    );

    # if we don't have a matching search clause, abort ...
    if (not exists $search_clauses{$terms}) {
        $c->log->error(
              $terms
            . q{ is not a valid date label in search_clauses_date()}
        );
        return [];
    };

    push @search_where,
        'me.created',
        $search_clauses{$terms}
    ;

    return [\@search_where, undef];
}

sub search_clauses_message : Private {
    my ($self, $c) = @_;
    my $results = $c->stash->{validation};
    my $search_field = 'message';
    my @search_where;

    my $terms = $results->valid(
            $search_field
        . q{_search_terms}
    );
    my $type = $results->valid(
            $search_field
        . q{_search_type}
    ) || q{};

    # nice and easy - we're just searching the message body
    $c->forward(
        add_search_clauses => [\@search_where, $type, $search_field, $terms]
    );

    return [\@search_where, undef];
}

sub search_clauses_subject : Private {
    my ($self, $c) = @_;
    my $results = $c->stash->{validation};
    my $search_field = 'subject';
    my @search_where;
    my @joins;

    my $terms = $results->valid(
            $search_field
        . q{_search_terms}
    );
    my $type = $results->valid(
            $search_field
        . q{_search_type}
    ) || q{};

    # post subjects
    $c->forward(
        add_search_clauses => [\@search_where, $type, 'me.subject', $terms]
    );

    # thread subjects
    $c->forward(
        add_search_clauses => [\@search_where, $type, 'thread.subject', $terms]
    );
    # add the required JOIN relation name
    push @joins, 'thread';

    return [\@search_where, \@joins];
}

sub _results_view_pager {
    my ($self, $c) = @_;

    # if we don't have any search results, do nothing
    if (not $c->stash->{search_results}) {
        return;
    }

    # get the pager (from the search results)
    $c->stash->{page} = $c->stash->{search_results}->pager();

    # TODO - find a better way to do this if possible
    # set up Data::SpreadPagination
    my $pagination = Data::SpreadPagination->new(
        {
            totalEntries        => $c->stash->{page}->total_entries(),
            entriesPerPage      => $c->config->{search_results_per_page},
            currentPage         => $c->stash->{current_page},
            maxPages            => 4,
        }
    );
    $c->stash->{page_range_spread} = $pagination->pages_in_spread();

    # extra params to use in pager links (to preserve search data)
    my $u = URI->new("", "http");
    $u->query_param(search_terms => $c->stash->{search_terms}{raw});
    $u->query_param(search_forum => $c->request->param('search_forum'));
    $c->stash->{url_extra_args} = '&' . $u->query();
}

=head1 NAME

Parley::Controller::Search - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=head2 index 

=head1 AUTHOR

Chisel Wright C<< <chiselwright@users.berlios.de> >>

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
