package OpenGuides::Search;
use strict;
our $VERSION = '0.15';

use CGI qw( :standard );
use Wiki::Toolkit::Plugin::Locator::Grid;
use File::Spec::Functions qw(:ALL);
use OpenGuides::Template;
use OpenGuides::Utils;
use Parse::RecDescent;

=head1 NAME

OpenGuides::Search - Search form generation and processing for OpenGuides.

=head1 DESCRIPTION

Does search stuff for OpenGuides.  Distributed and installed as part of
the OpenGuides project, not intended for independent installation.
This documentation is probably only useful to OpenGuides developers.

=head1 SYNOPSIS

  use CGI;
  use OpenGuides::Config;
  use OpenGuides::Search;

  my $config = OpenGuides::Config->new( file => "wiki.conf" );
  my $search = OpenGuides::Search->new( config => $config );
  my %vars = CGI::Vars();
  $search->run( vars => \%vars );

=head1 METHODS

=over 4

=item B<new>

  my $config = OpenGuides::Config->new( file => "wiki.conf" );
  my $search = OpenGuides::Search->new( config => $config );

=cut

sub new {
    my ($class, %args) = @_;
    my $config = $args{config};
    my $self   = { config => $config };
    bless $self, $class;

    my $wiki = OpenGuides::Utils->make_wiki_object( config => $config );

    $self->{wiki}     = $wiki;
    $self->{wikimain} = $config->script_url . $config->script_name;
    $self->{css}      = $config->stylesheet_url;
    $self->{head}     = $config->site_name . " Search";

    my $geo_handler = $config->geo_handler;
    my %locator_params;
    if ( $geo_handler == 1 ) {
        %locator_params = ( x => "os_x", y => "os_y" );
    } elsif ( $geo_handler == 2 ) {
        %locator_params = ( x => "osie_x", y => "osie_y" );
    } elsif ( $geo_handler == 3 ) {
        %locator_params = ( x => "easting", y => "northing" );
    }

    my $locator = Wiki::Toolkit::Plugin::Locator::Grid->new( %locator_params );
    $wiki->register_plugin( plugin => $locator );
    $self->{locator} = $locator;

    return $self;
}

=item B<wiki>

  my $wiki = $search->wiki;

An accessor; returns the underlying L<Wiki::Toolkit> object.

=cut

sub wiki {
    my $self = shift;
    return $self->{wiki};
}

=item B<config>

  my $config = $search->config;

An accessor; returns the underlying L<OpenGuides::Config> object.

=cut

sub config {
    my $self = shift;
    return $self->{config};
}

=item B<run>

  my %vars = CGI::Vars();
  $search->run(
                vars           => \%vars,
                return_output  => 1,   # defaults to 0
                return_tt_vars => 1,  # defaults to 0
              );

The C<return_output> parameter is optional.  If supplied and true, the
stuff that would normally be printed to STDOUT will be returned as a
string instead.

The C<return_tt_vars> parameter is also optional.  If supplied and
true, the template is not processed and the variables that would have
been passed to it are returned as a hash.  This parameter takes
precedence over C<return_output>.

These two parameters exist to make testing easier; you probably don't
want to use them in production.

You can also request just the raw search results:

  my %results = $search->run(
                              os_x    => 528864,
                              os_y    => 180797,
                              os_dist => 750,
                              format  => "raw",
                            );

Results are returned as a hash, keyed on the page name.  All results
are returned, not just the first C<page>.  The values in the hash are
hashes themselves, with the following key/value pairs:

=over 4

=item * name

=item * wgs84_lat - WGS-84 latitude

=item * wgs84_long - WGS-84 longitude

=item * summary

=item * distance - distance (in metres) from origin, if origin exists

=item * score - relevance to search string, if search string exists; higher score means more relevance

=back

In case you're struggling to follow the code, it does the following:
1) Processes the parameters, and bails out if it hit a problem with them
2) If a search string was given, do a text search
3) If distance search paramaters were given, do a distance search
4) If no search has occured, print out the search form
5) If an error occured, bail out
6) If we got a single hit on a string search, redirect to it
7) If no results were found, give an empty search results page
8) Sort the results by either score or distance
9) Decide which results to show, based on paging
10) Display the appropriate page of the results

=back

=cut

sub run {
    my ($self, %args) = @_;
    $self->{return_output}  = $args{return_output}  || 0;
    $self->{return_tt_vars} = $args{return_tt_vars} || 0;

    my $want_raw;
    if ( $args{vars}{format} && $args{vars}{format} eq "raw" ) {
        $want_raw = 1;
    }

    $self->process_params( $args{vars} );
    if ( $self->{error} ) {
        warn $self->{error};
        my %tt_vars = ( error_message => $self->{error} );
        $self->process_template( tt_vars => \%tt_vars );
        return;
    }

    my %tt_vars = (
                   format      => $args{'vars'}->{'format'},
                   ss_version  => $VERSION,
                   ss_info_url => 'http://openguides.org/search_help'
                  );

    my $doing_search;

    # Run a text search if we have a search string.
    if ( $self->{search_string} ) {
        $doing_search = 1;
        $tt_vars{search_terms} = $self->{search_string};
        $self->run_text_search;
    }

    # Run a distance search if we have sufficient criteria.
    if ( defined $self->{distance_in_metres}
         && defined $self->{x} && defined $self->{y} ) {
        $doing_search = 1;
        # Make sure to pass the criteria to the template.
        $tt_vars{dist} = $self->{distance_in_metres};
        $tt_vars{latitude} = $self->{latitude};
        $tt_vars{longitude} = $self->{longitude};
        if ( $self->config->geo_handler eq 1 ) {
            $tt_vars{coord_field_1_value} = $self->{os_x};
            $tt_vars{coord_field_2_value} = $self->{os_y};
        } elsif ( $self->config->geo_handler eq 2 ) {
            $tt_vars{coord_field_1_value} = $self->{osie_x};
            $tt_vars{coord_field_2_value} = $self->{osie_y};
        } elsif ( $self->config->geo_handler eq 3 ) {
            $tt_vars{coord_field_1_value} = $self->{latitude};
            $tt_vars{coord_field_2_value} = $self->{longitude};
        }
        $self->run_distance_search;
    }

    # If we're not doing a search then just print the search form (or return
    # an empty hash if we were asked for raw results).
    if ( !$doing_search ) {
        if ( $want_raw ) {
            return ( );
        } else {
            return $self->process_template( tt_vars => \%tt_vars );
        }
    }

    # At this point either $self->{error} or $self->{results} will be filled.
    if ( $self->{error} ) {
        $tt_vars{error_message} = $self->{error};
        $self->process_template( tt_vars => \%tt_vars );
        return;
    }

    # So now we know that we have been asked to perform a search, and we
    # have performed it.
    #
    # $self->{results} will be a hash of refs to hashes like so:
    #   'Node Name' => {
    #                    name     => 'Node Name',
    #                    distance => $distance_from_origin_if_any,
    #                    score    => $relevance_to_search_string
    #                  }

    my %results_hash = %{ $self->{results} || [] };

    # If we were asked for just the raw results, return them now, after
    # grabbing additional info.
    if ( $want_raw ) {
        foreach my $node ( keys %results_hash ) {
            my %data = $self->wiki->retrieve_node( $node );
            $results_hash{$node}{summary} = $data{metadata}{summary}[0];
            my $lat  = $data{metadata}{latitude}[0];
            my $long = $data{metadata}{longitude}[0];
            my ( $wgs84_lat, $wgs84_long ) = OpenGuides::Utils->get_wgs84_coords( latitude => $lat, longitude => $long, config => $self->config );
            $results_hash{$node}{wgs84_lat} = $wgs84_lat;
            $results_hash{$node}{wgs84_long} = $wgs84_long;
        }
        return %results_hash;
    }

    my @results = values %results_hash;
    my $numres = scalar @results;

    # If we only have a single hit, and the title is a good enough match
    # to the search string, redirect to that node.
    # (Don't try a fuzzy search on a blank search string - Plucene chokes.)
    if ( $self->{search_string} && $numres == 1 && !$self->{return_tt_vars}) {
        my %fuzzies = $self->wiki->fuzzy_title_match($self->{search_string});
        if ( scalar keys %fuzzies ) {
            my $node = $results[0]{name};
            my $formatter = $self->wiki->formatter;
            my $node_param = CGI::escape(
                            $formatter->node_name_to_node_param( $node )
                                        );
            my $output = CGI::redirect( $self->{wikimain} . "?$node_param" );
            return $output if $self->{return_output};
            print $output;
            return;
	}
    }

    # If we had no hits then go straight to the template.
    if ( $numres == 0 ) {
        %tt_vars = (
                     %tt_vars,
                     first_num => 0,
                     results   => [],
                   );
        return $self->process_template( tt_vars => \%tt_vars );
    }

    # Otherwise, we browse through the results a page at a time.

    # Figure out which results we're going to be showing on this
    # page, and what the first one for the next page will be.
    my $startpos = $args{vars}{next} || 0;
    $tt_vars{first_num} = $numres ? $startpos + 1 : 0;
    $tt_vars{last_num}  = $numres > $startpos + 20 ? $startpos + 20 : $numres;
    $tt_vars{total_num} = $numres;
    if ( $numres > $startpos + 20 ) {
        $tt_vars{next_page_startpos} = $startpos + 20;
    }

    # Sort the results - by distance if we're searching on that
    # or by score otherwise.
    if ( $self->{distance_in_metres} ) {
        @results = sort { $a->{distance} <=> $b->{distance} } @results;
    } else {
        @results = sort { $b->{score} <=> $a->{score} } @results;
    }

    # Now snip out just the ones for this page.  The -1 is because
    # arrays index from 0 and people from 1.
    my $from = $tt_vars{first_num} ? $tt_vars{first_num} - 1 : 0;
    my $to   = $tt_vars{last_num} - 1; # kludge to empty arr for no results
    @results = @results[ $from .. $to ];

    # Add the URL to each result hit.
    my $formatter = $self->wiki->formatter;
    foreach my $i ( 0 .. $#results ) {
        my $name = $results[$i]{name};

        # Add the one-line summary of the node, if there is one.
        my %node = $self->wiki->retrieve_node($name);
        $results[$i]{summary} = $node{metadata}{summary}[0];

        my $node_param = $formatter->node_name_to_node_param( $name );
        $results[$i]{url} = $self->{wikimain} . "?$node_param";
    }

    # Finally pass the results to the template.
    $tt_vars{results} = \@results;
    $self->process_template( tt_vars => \%tt_vars );
}

sub run_text_search {
    my $self = shift;
    my $searchstr = $self->{search_string};
    my $wiki = $self->wiki;
    my $config = $self->config;

    if ( $config->use_lucy ) {
        require OpenGuides::Search::Lucy;
        my $lucy = OpenGuides::Search::Lucy->new( config => $config );
        my %results = $lucy->run_text_search( search_string => $searchstr );
        $self->{results} = \%results;
        return $self;
    }

    # Create parser to parse the search string.
    my $parser = Parse::RecDescent->new( q{

        search: list eostring {$return = $item[1]}

        list: comby(s)
            {$return = (@{$item[1]}>1) ? ['AND', @{$item[1]}] : $item[1][0]}

        comby: <leftop: term ',' term>
            {$return = (@{$item[1]}>1) ? ['OR', @{$item[1]}] : $item[1][0]}

        term: '(' list ')' {$return = $item[2]}
            |        '-' term {$return = ['NOT', @{$item[2]}]}
            |        '"' word(s) '"' {$return = ['phrase', join " ", @{$item[2]}]}
            |        word {$return = ['word', $item[1]]}
            |        '[' word(s) ']' {$return = ['title', @{$item[2]}]}

        word: /[\w'*%]+/ {$return = $item[1]}

        eostring: /^\Z/

    } );

    unless ( $parser ) {
        warn $@;
        $self->{error} = "Can't create parse object - $@";
        return $self;
    }

    # Run parser over search string.
    my $tree = $parser->search( $searchstr );
    unless ( $tree ) {
        $self->{error} = "Syntax error in search: $searchstr";
        return $self;
    }

    # Run the search over the generated search tree.
    my %results = $self->_run_search_tree( tree => $tree );
    $self->{results} = \%results;
    return $self;
}

sub _run_search_tree {
    my ($self, %args) = @_;
    my $tree = $args{tree};
    my @tree_arr = @$tree;
    my $op = shift @tree_arr;
    my $method = "_run_" . $op . "_search";
    return $self->can($method) ? $self->$method(@tree_arr) : undef;
}

=head1 INPUT

=over

=item B<word>

a single word will be matched as-is. For example, a search on

  escalator

will return all pages containing the word "escalator".

=cut

sub _run_word_search {
    my ($self, $word) = @_;
    # A word is just a small phrase.
    return $self->_run_phrase_search( $word );
}

=item B<AND searches>

A list of words with no punctuation will be ANDed, for example:

  restaurant vegetarian

will return all pages containing both the word "restaurant" and the word
"vegetarian".

=cut

sub _run_AND_search {
    my ($self, @subsearches) = @_;

    # Do the first subsearch.
    my %results = $self->_run_search_tree( tree => $subsearches[0] );

    # Now do the rest one at a time and remove from the results anything
    # that doesn't come up in each subsearch.  Results that survive will
    # have a score that's the sum of their score in each subsearch.
    foreach my $tree ( @subsearches[ 1 .. $#subsearches ] ) {
        my %subres = $self->_run_search_tree( tree => $tree );
        my @pages = keys %results;
        foreach my $page ( @pages ) {
	  if ( exists $subres{$page} ) {
                $results{$page}{score} += $subres{$page}{score};
	      } else {
                delete $results{$page};
            }
        }
      }

    return %results;
}

=item B<OR searches>

A list of words separated by commas (and optional spaces) will be ORed,
for example:

  restaurant, cafe

will return all pages containing either the word "restaurant" or the
word "cafe".

=cut

sub _run_OR_search {
    my ($self, @subsearches) = @_;

    # Do all the searches.  Results will have a score that's the sum
    # of their score in each subsearch.
    my %results;
    foreach my $tree ( @subsearches ) {
        my %subres = $self->_run_search_tree( tree => $tree );
        foreach my $page ( keys %subres ) {
	  if ( $results{$page} ) {
                $results{$page}{score} += $subres{$page}{score};
	      } else {
                $results{$page} = $subres{$page};
            }
        }
      }
    return %results;
}

=item B<phrase searches>

Enclose phrases in double quotes, for example:

  "meat pie"

will return all pages that contain the exact phrase "meat pie" - not pages
that only contain, for example, "apple pie and meat sausage".

=cut

sub _run_phrase_search {
    my ($self, $phrase) = @_;
    my $wiki = $self->wiki;

    # Search title and body.
    my %contents_res = $wiki->search_nodes( $phrase );

    # Rationalise the scores a little.  The scores returned by
    # Wiki::Toolkit::Search::Plucene are simply a ranking.
    my $num_results = scalar keys %contents_res;
    foreach my $node ( keys %contents_res ) {
        $contents_res{$node} = int( $contents_res{$node} / $num_results ) + 1;
    }

    my @tmp = keys %contents_res;
    foreach my $node ( @tmp ) {
        my $content = $wiki->retrieve_node( $node );

        # Don't include redirects in search results.
        if ($content =~ /^#REDIRECT/) {
            delete $contents_res{$node};
            next;
        }

        # It'll be a real phrase (as opposed to a word) if it has a space in it.
        # In this case, dump out the nodes that don't match the search exactly.
        # I don't know why the phrase searching isn't working properly.  Fix later.
        if ( $phrase =~ /\s/ ) {
            unless ( $content =~ /$phrase/i || $node =~ /$phrase/i ) {
                delete $contents_res{$node};
            }
        }

    }

    my %results = map { $_ => { name => $_, score => $contents_res{$_} } }
                      keys %contents_res;

    # Bump up the score if the title matches.
    foreach my $node ( keys %results ) {
        $results{$node}{score} += 10 if $node =~ /$phrase/i;
    }

    # Search categories.
    my @catmatches = $wiki->list_nodes_by_metadata(
				 metadata_type  => "category",
 				 metadata_value => $phrase,
				 ignore_case    => 1,
    );

    foreach my $node ( @catmatches ) {
        if ( $results{$node} ) {
            $results{$node}{score} += 3;
        } else {
            $results{$node} = { name => $node, score => 3 };
        }
    }

    # Search locales.
    my @locmatches = $wiki->list_nodes_by_metadata(
				 metadata_type  => "locale",
 				 metadata_value => $phrase,
				 ignore_case    => 1,
    );

    foreach my $node ( @locmatches ) {
        if ( $results{$node} ) {
            $results{$node}{score} += 3;
        } else {
            $results{$node} = { name => $node, score => 3 };
        }
    }

    return %results;
}

=back

=head1 SEARCHING BY DISTANCE

To perform a distance search, you need to supply one of the following
sets of criteria to specify the distance to search within, and the
origin (centre) of the search:

=over

=item B<os_dist, os_x, and os_y>

Only works if you chose to use British National Grid in wiki.conf

=item B<osie_dist, osie_x, and osie_y>

Only works if you chose to use Irish National Grid in wiki.conf

=item B<latlong_dist, latitude, and longitude>

Should always work, but has a habit of "finding" things a couple of
metres away from themselves.

=back

You can perform both pure distance searches and distance searches in
combination with text searches.

=cut

# Note this is called after any text search is run, and it is only called
# if there are sufficient criteria to perform the search.
sub run_distance_search {
    my $self = shift;
    my $x    = $self->{x};
    my $y    = $self->{y};
    my $dist = $self->{distance_in_metres};

    my @close = $self->{locator}->find_within_distance(
                                                        x      => $x,
                                                        y      => $y,
                                                        metres => $dist,
                                                      );

    if ( $self->{results} ) {
        my %close_hash = map { $_ => 1 } @close;
        my %results = %{ $self->{results} };
        my @candidates = keys %results;
        foreach my $node ( @candidates ) {
            if ( exists $close_hash{$node} ) {
                my $distance = $self->_get_distance(
                                                     node => $node,
                                                     x    => $x,
                                                     y    => $y,
                                                   );
                $results{$node}{distance} = $distance;
	    } else {
                delete $results{$node};
            }
        }
        $self->{results} = \%results;
    } else {
        my %results;
        foreach my $node ( @close ) {
            my $distance = $self->_get_distance (
                                                     node => $node,
                                                     x    => $x,
                                                     y    => $y,
                                                   );
            $results{$node} = {
                                name     => $node,
                                distance => $distance,
                              };
        }
        $self->{results} = \%results;
    }
    return $self;
}

sub _get_distance {
    my ($self, %args) = @_;
    my ($node, $x, $y) = @args{ qw( node x y ) };
    return $self->{locator}->distance(
                                       from_x  => $x,
                                       from_y  => $y,
	     	                       to_node => $node,
                                       unit    => "metres"
                                     );
}

sub process_params {
    my ($self, $vars_hashref) = @_;
    my %vars = %{ $vars_hashref || {} };

    # Make sure that we don't have any data left over from previous invocation.
    # This is useful for testing purposes at the moment and will be essential
    # for mod_perl implementations.
    delete $self->{x};
    delete $self->{y};
    delete $self->{distance_in_metres};
    delete $self->{search_string};
    delete $self->{results};

    # Strip out any non-digits from distance and OS co-ords.
    foreach my $param ( qw( os_x os_y osie_x osie_y
                            osie_dist os_dist latlong_dist ) ) {
        if ( defined $vars{$param} ) {
            $vars{$param} =~ s/[^0-9]//g;
            # 0 is an allowed value but the empty string isn't.
            delete $vars{$param} if $vars{$param} eq "";
	}
    }

    # Latitude and longitude are also allowed '-' and '.'
    foreach my $param( qw( latitude longitude ) ) {
        if ( defined $vars{$param} ) {
            $vars{$param} =~ s/[^-\.0-9]//g;
            # 0 is an allowed value but the empty string isn't.
            delete $vars{$param} if $vars{$param} eq "";
	}
    }

    # Set $self->{distance_in_metres}, $self->{x}, $self->{y},
    # depending on whether we got
    # OS co-ords or lat/long.  Only store parameters if they're complete,
    # and supported by our method of distance calculation.
    if ( defined $vars{os_x} && defined $vars{os_y} && defined $vars{os_dist}
         && $self->config->geo_handler eq 1 ) {
        $self->{x} = $vars{os_x};
        $self->{y} = $vars{os_y};
        $self->{distance_in_metres} = $vars{os_dist};
    } elsif ( defined $vars{osie_x} && defined $vars{osie_y}
         && defined $vars{osie_dist}
         && $self->config->geo_handler eq 2 ) {
        $self->{x} = $vars{osie_x};
        $self->{y} = $vars{osie_y};
        $self->{distance_in_metres} = $vars{osie_dist};
    } elsif ( defined $vars{latitude} && defined $vars{longitude}
              && defined $vars{latlong_dist} ) {
        # All handlers can do lat/long, but they all do it differently.
        if ( $self->config->geo_handler eq 1 ) {
            require Geo::Coordinates::OSGB;
            my ( $x, $y ) = Geo::Coordinates::OSGB::ll_to_grid(
                                $vars{latitude}, $vars{longitude} );
            $self->{x} = sprintf( "%d", $x );
            $self->{y} = sprintf( "%d", $y );
	} elsif ( $self->config->geo_handler eq 2 ) {
            require Geo::Coordinates::ITM;
            my ( $x, $y ) = Geo::Coordinates::ITM::ll_to_grid(
                                $vars{latitude}, $vars{longitude} );
            $self->{x} = sprintf( "%d", $x );
            $self->{y} = sprintf( "%d", $y );
        } elsif ( $self->config->geo_handler eq 3 ) {
	    require Geo::Coordinates::UTM;
            my ($zone, $x, $y) = Geo::Coordinates::UTM::latlon_to_utm(
                                                $self->config->ellipsoid,
                                                $vars{latitude},
                                                $vars{longitude},
                                              );
            $self->{x} = $x;
            $self->{y} = $y;
	}
        $self->{distance_in_metres} = $vars{latlong_dist};
    }

    # Store os_x etc so we can pass them to template.
    foreach my $param ( qw( os_x os_y osie_x osie_y latitude longitude ) ) {
        $self->{$param} = $vars{$param};
    }

    # Strip leading and trailing whitespace from search text.
    $vars{search} ||= ""; # avoid uninitialised value warning
    $vars{search} =~ s/^\s*//;
    $vars{search} =~ s/\s*$//;

    # Check for only valid characters in tainted search param
    # (quoted literals are OK, as they are escaped)
    # This regex copied verbatim from Ivor's old supersearch.
    if ( $vars{search}
         && $vars{search} !~ /^("[^"]*"|[\w \-',()!*%\[\]])+$/i) {
        $self->{error} = "Search expression $vars{search} contains invalid character(s)";
        return $self;
    }
    $self->{search_string} = $vars{search};

    return $self;
}

# thin wrapper around OpenGuides::Template, or OpenGuides::Feed
sub process_template {
    my ($self, %args) = @_;

    my $tt_vars = $args{tt_vars} || {};
    $tt_vars->{not_editable} = 1;
    $tt_vars->{not_deletable} = 1;
    return %$tt_vars if $self->{return_tt_vars};

    # Do we want a feed, or TT html?
    my $output;
    if($tt_vars->{'format'}) {
        my $format = $tt_vars->{'format'};
        my @nodes = @{$tt_vars->{'results'}};

        my $feed = OpenGuides::Feed->new(
                                               wiki       => $self->wiki,
                                               config     => $self->config,
                                               og_version => $VERSION,
                                        );
        $feed->set_feed_name_and_url_params(
                    "Search Results for ".$tt_vars->{search_terms},
                    "search.cgi?search=".$tt_vars->{search_terms}
        );

        $output  = "Content-Type: ".$feed->default_content_type($format)."\n";
        $output .= $feed->build_mini_feed_for_nodes($format,@nodes);
    } else {
        $output =  OpenGuides::Template->output(
                                                wiki     => $self->wiki,
                                                config   => $self->config,
                                                template => "search.tt",
                                                vars     => $tt_vars,
                                              );
    }

    return $output if $self->{return_output};

    print $output;
    return 1;
}

=head1 OUTPUT

Results will be put into some form of relevance ordering.  These are
the rules we have tests for so far (and hence the only rules that can
be relied on):

=over

=item *

A match on page title will score higher than a match on page category
or locale.

=item *

A match on page category or locale will score higher than a match on
page content.

=item *

Two matches in the title beats one match in the title and one in the content.

=back

=cut

=head1 AUTHOR

The OpenGuides Project (openguides-dev@lists.openguides.org)

=head1 COPYRIGHT

     Copyright (C) 2003-2013 The OpenGuides Project.  All Rights Reserved.

The OpenGuides distribution is free software; you can redistribute it
and/or modify it under the same terms as Perl itself.

=head1 SEE ALSO

L<OpenGuides>

=cut

1;
