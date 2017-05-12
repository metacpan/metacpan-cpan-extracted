package WWW::Scraper::Sherlock;

=pod

=head1 NAME

WWW::Scraper::Sherlock - Scrapes search engines via Sherlock plugins.


=head1 SYNOPSIS

    require WWW::Scraper;
    $search = new WWW::Scraper('Sherlock');
    $search->sherlockPlugin($pluginURI);
    
    # then proceed as any normal WWW::Search module.
    $result = $search->next_result();
    
    # The result objects include additional methods specifically for Sherlock.
    $result->name();
    $result->url();
    $result->relevance();
    $result->price();
    $result->avail();
    $result->email();
    $result->detail();
    $result->banner();
    $result->browserResultType();    

    # Attributes of the <SEARCH> and <BROWSER> blocks of the plugin
    #  can be accessed via a hash in the object named 'sherlockSearchParam'.
    $search->{'sherlockSearchParam'}{'name'}  # name
       . . . {...}{'description'}             # description
       . . . {...}{'method'}                  # method
       . . . {...}{'action'}                  # action
       . . . {...}{'routeType'}               # routeType
       . . . {...}{'update'}                  # update
       . . . {...}{'updateCheckDays'}         # updateCheckDays

=head1 DESCRIPTION

Performs WWW::Scraper-style searches on search engines, given a Sherlock plugin
to define the request and response
(as defined in F<http://developer.apple.com/technotes/tn/tn1141.html>
and enhanced by F<http://www.mozilla.org/projects/search/technical.html>).

The plugin is named by a URI, such as "file:yahoo.src" or "http://sherlock.mozdev.org/yahoo.src".

This version does not automatically update plugins; it ignores the 'update' and 'updateCheckDays' attributes
of the <SEARCH> block.

Getchur plugins red-hot from F<http://sherlock.mozdev.org/source/browse/sherlock/www/>.

Also ignored in this version are the <INTERPRET> attributes of 'skipLocal' (partially implemented),
'charset', 'resultEncoding', 'resultTranslationEncoding' and 'resultTranslation'.

=head1 OPTIONS

    $search->sherlockPlugin(pluginURI, { 'option' => $value });

You may supply any of the options available to WWW::Scraper objects (which are, in turn,
WWW::Search objects). Options may also be passed to new Sherlock object via the C<sherlockPlugin()> method, just as they
would be in WWW::Search's C<next_result()>. New Sherlock options include

B<noUpdate> - boolean, do not fetch an updated plugin, even if that is called for by updateCheckDays.

=head1 EXAMPLE

This sample is a complete script that runs Sherlock against Yahoo.com.
The query is "Greeting Cards". It lists all the harvested fields to STDOUT.
Note that WWW::Scraper('Sherlock') loads WWW::Scraper::Sherlock, so you don't have to.

    use WWW::Scraper;
    
    my $scraper = new WWW::Scraper('Sherlock');
    $scraper->sherlockPlugin('http://sherlock.mozdev.org/yahoo.src'); # or 'file:Sherlock/yahoo.src';
   
    $scraper->native_query('Greeting Cards', {'search_debug' => 1});
   
    while ( my $result = $scraper->next_result() ) {
        print "NAME: '".$result->name()."'\n";
        print "URL: '".$result->url()."'\n";
        print "RELEVANCE: '".$result->relevance()."'\n";
        print "PRICE: '".$result->price()."'\n";
        print "AVAIL: '".$result->avail()."'\n";
        print "EMAIL: '".$result->email()."'\n";
        print "DETAIL: '".$result->detail()."'\n";
    }

=head1 SEE ALSO

=over 4

=item B<Apple's Introduction to Sherlock plugin development>

F<http://www.apple.com/sherlock/plugindev.html>

=item B<Sherlock Specification Technote TN1141>

F<http://developer.apple.com/technotes/tn/tn1141.html>

=item B<Mozilla Enhancements>

F<http://www.mozilla.org/projects/search/technical.html>

=item B<Mozdev Plugins Library>

F<http://sherlock.mozdev.org/source/browse/sherlock/www/>

=back

=head1 AUTHOR

C<WWW::Scraper::Sherlock> is written and maintained
by Glenn Wood, F<glenwood@alumni.caltech.com>.

=head1 COPYRIGHT

Copyright (c) 2001 Glenn Wood
All rights reserved.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.


=cut


#####################################################################

require Exporter;
@EXPORT = qw();
@EXPORT_OK = qw(trimTags);
@ISA = qw(WWW::Scraper Exporter);
$VERSION = sprintf("%d.%02d", q$Revision: 1.0 $ =~ /(\d+)\.(\d+)/);

use Carp ();
use WWW::Scraper(qw(2.12 addURL trimTags));
my $isNowTesting;

use HTML::Form;
use HTTP::Cookies;
use Text::ParseWords;

use strict;

sub generic_option 
{
    my ($option) = @_;
    return 1 if $option =~ /^sherlock/;
    return WWW::Scraper::generic_option($option);
}


sub sherlockPlugin {
    my ($self, $sherlockPlugin, $options_ref) = @_;
    
    $self->{'sherlockPlugin'} = $sherlockPlugin;
    
    # Transport the parameter options into the object options.
  	map { $self->{_options}->{$_} = $options_ref->{$_} } keys %$options_ref
        if defined($options_ref);
    
    # Unfortunately, we can't get and parse the plugin right now,
    # since we'd prefer to rely on WWW::Search for our URI access,
    # and it hasn't set that up for us yet. 
    # See native_setup_search(), where this process will continue.
}



sub native_setup_search
{
    my($self, $native_query, $native_options_ref) = @_;
    $self->user_agent('user');
    $self->{_next_to_retrieve} = 0;

    $self->{'scraperRequest'} = 
        { 
              'type' => 'SHERLOCK'    # This is a WWW::Search module - notify native_setup_search_NULL() of that.
              # This is the basic URL on which to build the query.
             ,'url' => 'http://'
              # names the native input field to recieve the query string.
             ,'nativeQuery' => 'query'
              # specify defaults, by native field names
             ,'nativeDefaults' => { 'query' => undef }
             ,'fieldTranslations' => undef # This gives us a null %inputsHash, so WWW::Scraper will ignore that functionality (hopefully)
             , 'cookies' => 0 # The WWW::Search module must maintain its own cookies.
        };

    $self->{'sherlockPluginRes'} = $self->http_request('GET', $self->{'sherlockPlugin'});

    my $plugin = $self->{'sherlockPluginRes'}->content();
    $plugin =~ s/\r//gs;

    my $interpretCount = 0;
    $self->{'sherlockInterprets'} = [];
    for ( &quotewords('<|/?>', 1, $plugin) ) {
        if ( $_ ) {
            do { s/\s+$// } while ( chomp );
        }
        next unless $_;

    m/^search/i && do  { 
            for ( split /\n/ ) {
                do { s/\s+$// } while ( chomp ); next unless $_;
                my ($x,$y) = parseString(\$_);
                $self->{'sherlockSearchParam'}{$x} = $y if $x;
            }
            next;
        };

    m/^browser/i && do  { 
            for ( split /\n/ ) {
                do { s/\s+$// } while ( chomp ); next unless $_;
                my ($x,$y) = parseString(\$_);
                $self->{'sherlockSearchParam'}{$x} = $y if $x;
            }
            next;
        };

    m/^input/i && do {
            # Translate ' name="NAME" value="VALUE" ' into a mini-hash-table;
            s/^input\s+//i;
            my %nameVal;
            my $isUser = 0;
            while ( my ($x,$y) = parseString(\$_) ) {
                last unless $x;
                $x = lc $x;
                $nameVal{$x} = $y;
            }
            # In our context, 'user' means $native_query will to into this field.
            if ( m/user/ ) {
                $isUser = 1;
            }
            if ( $isUser ) {
                $self->{'sherlockNativeQuery'} = $nameVal{'name'};
            } else {
                $self->{'sherlockInput'}{$nameVal{'name'}} = $nameVal{'value'} if $nameVal{'name'};
            }
            next;
        };

    m/^interpret/i && do {
            for ( split /\n/ ) {
                do { s/\s+$// } while ( chomp ); next unless $_;
                my ($x,$y) = parseString(\$_);
                $self->{'sherlockInterprets'}[$interpretCount]{$x} = $y if $x;
            }
            $interpretCount += 1;
            next;
        };
    }

    # Translate Sherlock's 'update' to the required action.
    if ( $self->{'sherlockSearchParam'}{'update'} and not $self->{'_options'}{'noUpdate'} ) {
        unless ( $self->{'isTesting'} ) {
            print STDERR "Update method for Sherlock Plugin is not implemented, yet.\n";
            print STDERR "See ".$self->{'sherlockSearchParam'}{'update'}." for an update.\n";
        }
    }
    # Translate Sherlock's 'action' and 'method' to WWW::Search's parameters.
    $self->{'_options'}{'search_url'} = $self->{'sherlockSearchParam'}{'action'};
    $self->{'_http_method'} = $self->{'sherlockSearchParam'}{'method'};

    # Translate Sherlock's 'input' name/values to our parameters list.
    for ( keys %{$self->{'sherlockInput'}} ) {
        $self->{'_options'}{$_} = $self->{'sherlockInput'}{$_};
    }

    # Translage Sherlock's 'interpret' elements into our scraper frame format.
    my @allResultList; # Handle multiple <interpret> elements.
    for my $interpret ( @{$self->{'sherlockInterprets'}} ) {
        my @results;
        for ( qw(relevance price avail date name email) ) { 
            if ( $$interpret{$_.'Start'} or
                 $$interpret{$_.'End'} ) {
                my @rslts = ( 'CALLBACK', \&resultData, 
                                $$interpret{$_.'Start'}, 
                                $$interpret{$_.'End'}, "$_" );
                push @results, \@rslts;
            }
        }
        my $resultItem;
        if ( $$interpret{'resultItemStart'} or
             $$interpret{'resultItemEnd'} ) {
            $resultItem = [ [ 'CALLBACK', \&resultItem, 
                            $$interpret{'resultItemStart'}, 
                            $$interpret{'resultItemEnd'}, \@results, $$interpret{'skipLocal'} ] ];
        } else
        {
            $resultItem = \@results;
        }
        $resultItem = [ [ 'HIT*', 'Sherlock', $resultItem, $$interpret{'browserResultType'} ] ];
    
        my $resultList;
        if ( $$interpret{'resultListStart'} or
             $$interpret{'resultListEnd'} ) {
            $resultList = [ 'CALLBACK', \&resultList, 
                            $$interpret{'resultListStart'}, 
                            $$interpret{'resultListEnd'}, $resultItem ];
        } else
        {
            $resultList = $resultItem;
        }
        push @allResultList, $resultList;
    }
    $self->{'_options'}{'scrapeFrame'} = [ 'HTML', [ @allResultList ] ];
    # whew!
    #use Data::Dumper; print Dumper($self->{'_options'}{'scrapeFrame'}); if $self->ScraperTrace('X');

    # Ok, we'll add anything other inputs the user wants to throw at the search engine, too.
    my($options_ref) = $self->{_options};
    if (defined($native_options_ref)) {
    	# Copy in new options.
    	foreach (keys %$native_options_ref) {
    	    $options_ref->{$_} = $native_options_ref->{$_};
    	};
    };
    # Process the options.
    # (Now in sorted order for consistency regarless of hash ordering.)
    my($options) = '';
    foreach (sort keys %$options_ref) {
    	# printf STDERR "option: $_ is " . $options_ref->{$_} . "\n";
    	next if (generic_option($_));
    	$options .= $_ . '=' . $options_ref->{$_} . '&';
    };
    $self->{_debug} = $options_ref->{'search_debug'};
    $self->{_debug} = 2 if ($options_ref->{'search_parse_debug'});
    $self->{_debug} = 0 if (!defined($self->{_debug}));
    
    $self->{'_next_url'} = $self->{'_options'}{'search_url'} .'?'. $options . 
                                $self->{'sherlockNativeQuery'} . '=' .$native_query;

    $self->SetRequest( new WWW::Scraper::Request({$self->{'scraperRequest'}->{'nativeQuery'} => $native_query}) );
    print STDERR $self->{_base_url} . "\n" if $self->ScraperTrace('U');
}


sub testParameters {
    my ($self) = @_;
    
    if ( ref $self ) {
        $self->{'isTesting'} = 1;
        $self->sherlockPlugin('http://sherlock.mozdev.org/yahoo.src'); # Set our plugin for eg/test.pl
    }
    
    return {
                 'SKIP' => "Sherlock.pm is not working today; many changes out on the frontier that I haven't caught up with yet"
                ,'testNativeQuery' => 'Greeting Cards'
                ,'expectedOnePage' => 9
                ,'expectedMultiPage' => 11
                ,'expectedBogusPage' => 0
           };
}

sub scraperRequest { return $_[0]->{'scraperRequest'}; }

##########################################################################
# Handles "attribute" specifications of the form:
#
#   name = "string" or
#   name = 'string' or
#   name = word
#
# returns (name, string)
#
# (does not handle escaped quotes)
sub parseString {
    $_ = ${$_[0]};
    my $w = $_[1];
    $w = '\w+' unless $w;
    return ($1,$2) if s/^\s*($w)\s*=\s*"([^"]*)"\s*//i ;
    return ($1,$2) if s/^\s*($w)\s*=\s*'([^']*)'\s*//i ;
    return ($1,$2) if s/^\s*($w)\s*=\s*(\w+)\s*//i ;
    return (undef,undef);
}

##########################################################################
#
# CALLBACK function: resultList
#
# Find the resultList at the scaffold location; return that to Scraper.pm
#
sub resultList {  
    my ($self, $hit, $content, $scaffold) = @_;
    my $next_scaffold = $$scaffold[4];

    my $sub_content = '';
    my $found_sub_content = 0;
    if ( $$scaffold[2] and $$scaffold[3] ) {
        if ( $$content =~ m-($$scaffold[2].*?$$scaffold[3])-si ) {
            $sub_content = $1;
            $found_sub_content = 1;
        } elsif ( $$content =~ m-($$scaffold[2].*$)-si ) {
            $sub_content = $1;
            $found_sub_content = 1;
        }
    };
    # Sherlock's very loose logic requires a match even if resultListEnd can not be found, at all.
    if ( $$scaffold[2] and not $found_sub_content ) {
        if ( $$content =~ m-($$scaffold[2].*$)-si ) {
            $sub_content = $1;
            $found_sub_content = 1;
        }
    }
    # Sherlock's very loose logic requires a match even if resultListStart can not be found, at all.
    if ( $$scaffold[3] and not $found_sub_content ) {
        if ( $$content =~ m-^(.*?$$scaffold[3])-si ) {
            $sub_content = $1;
            $found_sub_content = 1;
        }
    }
    $next_scaffold = undef unless $found_sub_content;
    
    $hit->{'browserResultType'} = $$scaffold[5];
    return ($sub_content, $next_scaffold);
}

##########################################################################
#
# CALLBACK function: resultItem
#
# Find the resultItem at the scaffold location; return that to Scraper.pm
# Very similar to resultList, except that since Scraper.pm will continue
# scanning the same $content string until all items are harvested, resultItem()
# must remove each harvested item from the $content string.
#
# And finally, resultItem() harvests the "links immediately following the text pattern".
#
sub resultItem {  
    my ($self, $hit, $content, $scaffold, $total_hits_found, $skipLocal) = @_;
    my $next_scaffold = $$scaffold[4];
    my $skip_local = $$scaffold[5];

    my $sub_content = '';
    my $found_sub_content = 0;
    if ( $$scaffold[2] and $$scaffold[3] ) {
        if ( $$content =~ s-($$scaffold[2].*?$$scaffold[3])--si ) {
            $sub_content = $1;
            $found_sub_content = 1;
        } elsif ( $$content =~ s-($$scaffold[2].*$)--si ) {
            $sub_content = $1;
            $found_sub_content = 1;
        }
    };
    # Sherlock's very loose logic requires a match even if resultItemEnd can not be found, at all.
    if ( $$scaffold[2] and not $found_sub_content ) {
        if ( $$content =~ s-($$scaffold[2].*$)--si ) {
            $sub_content = $1;
            $found_sub_content = 1;
        }
    }
    # Sherlock's very loose logic requires a match even if resultItemStart can not be found, at all.
    if ( $$scaffold[3] and not $found_sub_content ) {
        if ( $$content =~ s-^(.*?$$scaffold[3])--si ) {
            $sub_content = $1;
            $found_sub_content = 1;
        }
    }
    if ( $found_sub_content ) {
        $$total_hits_found += 1;
        my $url;
        if ( $sub_content =~ s-<A\s+HREF="([^"]+)"[^>]*>--si ) {
            $url = $1;
        }
        elsif ( $sub_content =~ s-<A\s+HREF='([^']+)'[^>]*>--si ) {
            $url = $1;
        }
        elsif ( $sub_content =~ s-<A\s+HREF='([^']+)'[^>]*>--si ) {
            $url = $1;
        }
        if ( $skipLocal ) {
            # $url = '' if $url is a local href.
        };
        if ( $url ) {
            $url = new URI::URL($url, $self->{_base_url});
            $url = $url->abs;
            $hit->plug_url($url);
        }
        $hit->plug_elem('detail', $sub_content);
    } else {
        $next_scaffold = undef;
    }
    
    return ($sub_content, $next_scaffold);
}


##########################################################################
#
# CALLBACK function: resultData
#
# Find the resultData at the scaffold location; add the data to the $hit, and return
# undef to Scraper.pm (this is the appropriate return for a leaf of the scaffold tree.)
#
sub resultData {  
    my ($self, $hit, $content, $scaffold, $total_hits_found) = @_;
    my $next_scaffold = $$scaffold[4];

    my $sub_content = '';
    my $found_sub_content = 0;
    if ( $$scaffold[2] and $$scaffold[3] ) {
        if ( $$content =~ m-$$scaffold[2](.*)?$$scaffold[3]-si ) {
            $sub_content = $1;
            $found_sub_content = 1;
        } elsif ( $$content =~ m-$$scaffold[2](.*)$-si ) {
            $sub_content = $1;
            $found_sub_content = 1;
        }
    };
    # Sherlock's very loose logic requires a match even if resultDataEnd can not be found, at all.
    if ( $$scaffold[2] and not $found_sub_content ) {
        if ( $$content =~ m-$$scaffold[2](.*)$-si ) {
            $sub_content = $1;
            $found_sub_content = 1;
        }
    }
    # Sherlock's very loose logic requires a match even if resultDataStart can not be found, at all.
    if ( $$scaffold[3] and not $found_sub_content ) {
        if ( $$content =~ m-^(.*?)$$scaffold[3]-si ) {
            $sub_content = $1;
            $found_sub_content = 1;
        }
    }

    if ( $found_sub_content) {
        $hit->plug_elem($$scaffold[4], $sub_content);
        $$total_hits_found = 1;
    }
    return (undef, undef);
}

1;
