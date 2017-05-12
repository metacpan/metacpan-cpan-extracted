#!/usr/local/bin/perl

use strict;
use warnings;
use sigtrap die => 'normal-signals';
use vars qw( $VERSION );
$VERSION = '0.82';

use CGI qw/:standard/;
use CGI::Carp qw(croak);
use Wiki::Toolkit;
use OpenGuides;
use OpenGuides::CGI;
use OpenGuides::Config;
use OpenGuides::RDF;
use OpenGuides::JSON;
use OpenGuides::Utils;
use OpenGuides::Template;
use Time::Piece;
use URI::Escape;

my $config_file = $ENV{OPENGUIDES_CONFIG_FILE} || "wiki.conf";
my $config = OpenGuides::Config->new( file => $config_file );

my $script_name = $config->script_name;
my $script_url  = $config->script_url;

my ($guide, $wiki, $formatter, $q);
eval {
    $guide = OpenGuides->new( config => $config );
    $wiki = $guide->wiki;
    $formatter = $wiki->formatter;
    $q = CGI->new;

    # See if we need to redirect due to spaces in URL.  Don't do this for
    # POST requests though - it leads to all the data being stuffed into the
    # URL, which breaks things if there's a lot of data.
    my $request_method = $q->request_method() || "";
    unless ( $request_method eq "POST" ) {
      my $redirect = OpenGuides::CGI->check_spaces_redirect(
                                         cgi_obj => $q, wiki => $wiki );

      if ( $redirect ) {
          print $q->redirect( -uri => $redirect, -status => 303 );
          exit 0;
      }
    }

    # No redirect - carry on.
    my $node = OpenGuides::CGI->extract_node_name(
                                         cgi_obj => $q, wiki => $wiki );

    # If we did a post, then CGI->param probably hasn't fully de-escaped,
    #  in the same way as a get would've done
    if($request_method eq 'POST') {
        $node = uri_unescape($node);
    }

    # Grab our common parameters
    my $action       = $q->param('action')  || 'display';
    my $commit       = $q->param('Save')    || 0;
    my $preview      = $q->param('preview') || 0;
    my $search_terms = $q->param('terms')   || $q->param('search') || '';
    my $format       = $q->param('format')  || '';
    my $oldid        = $q->param('oldid')   || '';

    # Alternative method of calling search, supported by usemod.
    $action = 'search' if $q->param("search");

    if ($commit) {
        $guide->commit_node(
                             id      => $node,
                             cgi_obj => $q,
                           );
    } elsif ($preview) {
        $guide->preview_edit(
                              id      => $node,
                              cgi_obj => $q,
                            );
    } elsif ($action eq 'edit') {
        $guide->display_edit_form( id => $node );
    } elsif ($action eq 'search') {
        do_search($search_terms);
    } elsif ($action eq 'show_backlinks') {
        $guide->show_backlinks( id => $node );
    } elsif ($action eq 'show_wanted_pages') {
        show_wanted_pages();
    } elsif ($action eq 'show_needing_moderation') {
        show_needing_moderation();
    } elsif ($action eq 'index') {
        $guide->show_index(
                            cat    => $q->param( "cat" ) || "",
                            loc    => $q->param( "loc" ) || "",
                            format => $format,
                            # Next two for backwards compatibility (deprecated)
                            type   => $q->param("index_type") || "Full",
                            value  => $q->param("index_value") || "",
                          );
    } elsif ($action eq 'random') {
        print $guide->display_random_page(
                            category => $q->param( "category" ) || "",
                            locale   => $q->param( "locale" ) || "",
                                         );
    } elsif ($action eq 'find_within_distance') {
        $guide->find_within_distance(
                                      id => $node,
                                      metres => $q->param("distance_in_metres")
                                    );
    } elsif ( $action eq 'admin' ) {
        $guide->display_admin_interface(
                             moderation_completed => $q->param("moderation"),
        );
    } elsif ( $action eq 'revert_user' ) {
        $guide->revert_user_interface(
                        username => $q->param("username") || "",
                        host     => $q->param("host") || "",
                        password => $q->param("password") || "",
        );
    } elsif ( $action eq 'show_missing_metadata' ) {
        $guide->show_missing_metadata(
                   metadata_type  => $q->param("metadata_type") || "",
                   metadata_value => $q->param("metadata_value") || "",
                   exclude_locales => $q->param("exclude_locales") || "",
                   exclude_categories => $q->param("exclude_categories") || "",
                   format => $q->param( "format" ) || "",
        );
    } elsif ( $action eq 'set_moderation' ) {
        $guide->set_node_moderation(
                             id       => $node,
                             password => $q->param("password") || "",
                             moderation_flag => $q->param("moderation_flag") || "",
                           );
    } elsif ( $action eq 'moderate' ) {
        $guide->moderate_node(
                             id       => $node,
                             version  => $q->param("version") || "",
                             password => $q->param("password") || "",
                           );
    } elsif ( $action eq 'delete'
              and ( lc($config->enable_page_deletion) eq "y"
                    or $config->enable_page_deletion eq "1" )
            ) {
        $guide->delete_node(
                             id       => $node,
                             version  => $q->param("version") || "",
                             password => $q->param("password") || "",
                           );
    } elsif ($action eq 'userstats') {
        show_userstats(
                        username => $q->param("username") || "",
                        host     => $q->param("host") || "",
                      );
    } elsif ($action eq 'list_all_versions') {
        if($format && ($format eq "rss" || $format eq "atom")) {
            my %args = (
                            feed_type    => $format,
                            feed_listing => 'node_all_versions',
                            name         => $node
            );
            $guide->display_feed( %args );
        } else {
            $guide->list_all_versions( id => $node );
        }
    } elsif ($action eq 'rc') {
        if ($format && $format eq 'rss') {
            my $feed = $q->param("feed");
            if ( !defined $feed or $feed eq "recent_changes" ) {
                my %args = map { $_ => ( $q->param($_) || "" ) }
                           qw( feed items days ignore_minor_edits username
                               category locale );
                $args{feed_type} = 'rss';
                $args{feed_listing} = 'recent_changes';
                $guide->display_feed( %args );
            } elsif ( $feed eq "chef_dan" ) {
                display_node_rdf( node => $node );
            } else {
                croak "Unknown RSS feed type '$feed'";
            }
        } elsif ($format && $format eq 'atom') {
            my %args = map { $_ => ( $q->param($_) || "" ) }
                       qw( feed items days ignore_minor_edits username
                           category locale );
            $args{feed_type} = 'atom';
            $args{feed_listing} = 'recent_changes';
            $guide->display_feed( %args );
        } else {
            $guide->display_node( id => 'RecentChanges' );
        }
    } elsif ($action eq 'rss') {
        my $redir_target = $script_url . $script_name . '?action=rc;format=rss';
        my %args = map { $_ => ( $q->param($_) || "" ) }
            qw( feed items days ignore_minor_edits username
                category locale );
        foreach my $arg (sort keys %args) {
            if ($args{$arg} ne "") {
                $redir_target .= ";$arg=$args{$arg}";
            }
        }
        print $q->redirect( $redir_target );
    } elsif ($action eq 'about') {
        $guide->display_about(format => $format);
    } elsif ($action eq 'metadata') {
        $guide->show_metadata(
                            type   => $q->param("type") || "",
                            format => $format,
                          );
    } elsif ($action eq 'display') {
        if ( $format and $format eq "rdf" ) {
            display_node_rdf( node => $node );
        } elsif ( $format and $format eq "json" ) {
            display_node_json( node => $node );
        } elsif ( $format and $format eq 'raw' ) {
            $guide->display_node(
                                  id       => $node,
                                  format   => 'raw',
                                );
        } else {
            my $version = $q->param("version");
            my $other_ver = $q->param("diffversion");
            if ( $other_ver ) {
                $guide->display_diffs(
                                       id            => $node,
                                       version       => $version,
                                       other_version => $other_ver,
                                     );
            } else {
                my $redirect;

                if ((defined $q->param("redirect")) && ($q->param("redirect") == 0)) {
                  $redirect = 0;
                } else {
                  $redirect = 1;
                }

                $guide->display_node(
                                      id       => $node,
                                      version  => $version,
                                      oldid    => $oldid,
                                      redirect => $redirect,
                                    );
            }
        }
    } else {
        # Fallback: redirect to the display page, preserving all vars
        # except for the action, which we override.
        # Note: $q->Vars needs munging if we need to support any
        # multi-valued params
        my $params = $q->Vars;
        $params->{'action'} = 'display';
        my $redir_target = $script_url . $script_name . '?';
        my @args = map { "$_=" . $params->{$_} } keys %{$params};
        $redir_target .= join ';', @args;

        print $q->redirect(
            -uri => $redir_target,
            -status => 303
        );
    }

};

if ($@) {
    my $error = $@;
    warn $error;
    print $q->header;
    my $contact_email = $config->contact_email;
    print qq(<html><head><title>ERROR</title></head><body>
             <p>Sorry!  Something went wrong.  Please contact the
             Wiki administrator at
             <a href="mailto:$contact_email">$contact_email</a> and quote
             the following error message:</p><blockquote>)
      . $q->escapeHTML($error)
      . qq(</blockquote><p><a href="$script_name">Return to the Wiki home page</a>
           </body></html>);
}

############################ subroutines ###################################

sub show_userstats {
    my %args = @_;
    my ($username, $host) = @args{ qw( username host ) };
    croak "No username or host supplied to show_userstats"
        unless $username or $host;
    my %criteria = ( last_n_changes => 5 );
    $criteria{metadata_was} = $username ? { username => $username }
                                        : { host     => $host };
    my @nodes = $wiki->list_recent_changes( %criteria );
    @nodes = map { {name          => $q->escapeHTML($_->{name}),
            last_modified => $q->escapeHTML($_->{last_modified}),
            comment       => OpenGuides::Utils::parse_change_comment(
                $q->escapeHTML($_->{metadata}{comment}[0]),
                $script_url . '?',
            ),
            url           => "$script_name?"
          . $q->escape($formatter->node_name_to_node_param($_->{name})) }
                       } @nodes;
    my %tt_vars = ( last_five_nodes => \@nodes,
            username        => $username,
            username_param  => $wiki->formatter->node_name_to_node_param($username),
                    host            => $host,
                  );
    process_template("userstats.tt", "", \%tt_vars);
}

sub get_cookie {
    my $pref_name = shift or return "";
    my %cookie_data = OpenGuides::CGI->get_prefs_from_cookie(config=>$config);
    return $cookie_data{$pref_name};
}

sub display_node_rdf {
    my %args = @_;
    my $rdf_writer = OpenGuides::RDF->new( wiki => $wiki,
                                           config => $config );
    print "Content-type: application/rdf+xml\n\n";
    print $rdf_writer->emit_rdfxml( node => $args{node} );
}

sub display_node_json {
    my %args = @_;
    my $json_writer = OpenGuides::JSON->new( wiki => $wiki,
                                             config => $config );
    print "Content-type: text/javascript\n\n";
    print $json_writer->emit_json( node => $args{node} );
}

sub process_template {
    my ($template, $node, $vars, $conf, $omit_header) = @_;

    my %output_conf = ( wiki     => $wiki,
            config   => $config,
                        node     => $node,
            template => $template,
            vars     => $vars
    );
    $output_conf{noheaders} = 1 if $omit_header; # defaults otherwise
    print OpenGuides::Template->output( %output_conf );
}


sub do_search {
    my $terms = shift;
    my %finds = $wiki->search_nodes($terms);
#    my @sorted = sort { $finds{$a} cmp $finds{$b} } keys %finds;
    my @sorted = sort keys %finds;
    my @results = map {
        { url   => $q->escape($formatter->node_name_to_node_param($_)),
      title => $q->escapeHTML($_)
        }             } @sorted;
    my %tt_vars = ( results      => \@results,
                    num_results  => scalar @results,
                    not_editable => 1,
                    search_terms => $q->escapeHTML($terms) );
    process_template("search_results.tt", "", \%tt_vars);
}

sub show_wanted_pages {
    my @dangling = $wiki->list_dangling_links;
    my @wanted;
    my %backlinks_count;
    foreach my $node_name (@dangling) {
        $backlinks_count{$node_name} = scalar($wiki->list_backlinks( node => $node_name ));
    }
    foreach my $node_name (sort { $backlinks_count{$b} <=> $backlinks_count{$a} } @dangling) {
        my $node_param =
         uri_escape($formatter->node_name_to_node_param($node_name));
        push @wanted, {
            name          => $q->escapeHTML($node_name),
            edit_link     => $script_url . uri_escape($script_name)
                           . "?action=edit;id=$node_param",
            backlink_link => $script_url . uri_escape($script_name)
                    . "?action=show_backlinks;id=$node_param",
            backlinks_count => $backlinks_count{$node_name}
        };
    }
    process_template( "wanted_pages.tt",
                      "",
                      { not_editable  => 1,
                        not_deletable => 1,
                        deter_robots  => 1,
                        wanted        => \@wanted } );
}

sub show_needing_moderation {
    my @nodes = $wiki->list_unmoderated_nodes;

    # Build the moderate links
    foreach my $node (@nodes) {
        my $node_param =
            uri_escape($formatter->node_name_to_node_param($node->{'name'}));
        $node->{'moderate_url'} = $script_name . "?action=moderate;id=".$node_param.";version=".$node->{'version'};
        $node->{'view_url'} = $script_name . "?id=".$node_param.";version=".$node->{'version'};
        $node->{'diff_url'} = $script_name . "?id=".$node_param.";version=".$node->{'moderated_version'}.";diffversion=".$node->{'version'};
        $node->{'delete_url'} = $script_name . "?action=delete;version=".$node->{'version'}.";id=".$node_param;
    }

    process_template( "needing_moderation.tt",
                      "",
                      { not_editable  => 1,
                        not_deletable => 1,
                        deter_robots  => 1,
                        nodes        => \@nodes } );
}
