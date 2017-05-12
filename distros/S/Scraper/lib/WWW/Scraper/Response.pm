package WWW::Scraper::Response;

=head1 NAME

WWW::Scraper::Response - Response class of generic scrapes.

=head1 SYNOPSIS

    use WWW::Scraper('engineName');
    #
    my $scraper = new WWW::Scraper('engineName');
    my $response = $scraper->Response();
    #
    my $field = $response->$fieldName();
    # or
    my $field = $scraper->Response->$fieldName();
    #
    # or, specify your own Response class.
    my $scraper = new WWW::Scraper('engineName', 'responseClass');
    my $field = $scraper->Response->$fieldName();

=head1 DESCRIPTION

Scraper automatically generates a "Response" class for each scraper engine.
It does this by parsing the "scraperFrame" to identify all the field names fetched by the scraper.
It defines a get/set method for each of these fields, each named the same as the field name found in the "scraperFrame".

Optionally, you may write your own Response class and declare that as the Response class for your queries.
This is useful for defining a common Response class to a set of scraper engines (all auction sites, for instance).
See WWW::Scraper::Response::Auction for an example of this type of Response class.

=head1 METHODS

=over 8

=item $fieldName

As mentioned, Response will automatically define get/set methods for each of the fields in the "scraperFrame".
For instance, for a field named "postDate", you can get the field value with 

    $response->postDate();

You may also set the value of the postDate, but that would be kind of silly, wouldn't it?

=item GetFieldNames

A reference to a hash is returned listing all the field names in this response.
The keys of the hash are the field names, while the values are 1, 2, or 3.
A value of 1 means the value comes from the result page;
2 means the value comes from the detail page;
3 means the value is in both pages.

=item SkipDetailPage

A well-constructed Response class (as Scraper auto-generates) implements a lazy-access method for each
of the fields that come from the detail page. 
This means the detail page is fetched only if you ask for that field value.
The SkipDetailPage() method controls whether the detail page will be fetched or not.
If you set it to 1, then the detail page is never fetched (detail dependent fields return undef).
Set to 2 to read the detail page on demand.
Set to 3 to read the detail page for fields that are only on the detail page,
and don't fetch the detail page, but return the results page value, for fields that appear on both pages.

SkipDetailPage defaults to 2.

=item ScrapeDetailPage

Forces the detail page to be read and scraped right now.

=item GetFieldValues

Returns all field values of the response in a hash table (by reference).
Like GetFieldNames(), the keys are the field names, but in this case the values are the field values of each field.

=item GetFieldTitles

Returns a reference to a hash table containing titles for each field (which might be different than the field names).

=back

=head1 AUTHOR

C<WWW::Scraper::Response::Scraper> is written and maintained
by Glenn Wood, http://search.cpan.org/search?mode=author&query=GLENNWOOD.

=head1 COPYRIGHT

Copyright (c) 2001 Glenn Wood
All rights reserved.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

use strict;
use vars qw($VERSION @ISA);
@ISA = qw(WWW::SearchResult);
$VERSION = sprintf("%d.%02d", q$Revision: 1.13 $ =~ /(\d+)\.(\d+)/);
require WWW::SearchResult;
my (%AlreadyDeclared, $idCounter);

print "WWW::Scraper::Response v$VERSION\n" if ( $WWW::Scraper::PRINT_VERSION );

sub fieldCapture {
    my ($scaffold) = @_;
    my @fields = ();
    my $next_scaffold;
SCAFFOLD: for my $scaffold ( @$scaffold ) {
        $next_scaffold = undef;
        
        my $tag = $$scaffold[0];
        if ( ref($tag) ) {
            push @fields, @{$tag->{'fieldsCaptured'}} if $tag->{'fieldsCaptured'};
            my @scfld = @$scaffold;
            $next_scaffold = $scfld[$#scfld] if ref($scfld[$#scfld]) eq 'ARRAY';
            push @fields, fieldCapture($next_scaffold) if $next_scaffold;
        }
        elsif ( $tag =~ m/HIT|HIT\*/ )
        {
            my $resultType = $$scaffold[1];
            if ( 'ARRAY' eq ref $resultType ) {
                $next_scaffold = $resultType;
                $resultType = '';
            }
            else
            {
                $resultType = "::$resultType";
                $next_scaffold = $$scaffold[2];
            }
        }
        elsif ( $tag =~ m/(HTML|TidyXML|TABLEX|TRX|DL|FOR)$/ )
        {
            my $i = 1;
            while ( $$scaffold[$i] and 'ARRAY' ne ref($$scaffold[$i]) ) { $i += 1; }
            $next_scaffold = $$scaffold[$i];
        }
        elsif ('BODYX' eq $tag) { # 'BODY', 'x', 'y' , [[.]]
            if ( 'ARRAY' ne ref $$scaffold[3]  ) # if next_scaffold is an array ref, then we'll recurse (below)
            {
                push @fields, $$scaffold[3];
                next SCAFFOLD;
            } else {
                $next_scaffold = $$scaffold[3];
            }
        }
        elsif ( 'DATA' eq $tag )
        {
            next SCAFFOLD unless ( $$scaffold[1] and $$scaffold[2] ) ;
            push @fields, $$scaffold[3];
            next SCAFFOLD;
        }
    	elsif ( $tag =~ m/^(TABLEX|TRX|DL)$/ )
    	{
            $next_scaffold = $$scaffold[1];
            $next_scaffold = $$scaffold[2] unless ( 'ARRAY' eq ref $next_scaffold );
        }
    	elsif ( 'TAG' eq $tag )
        {
    		$next_scaffold = $$scaffold[2];
            if ( 'ARRAY' ne ref $next_scaffold  ) # if next_scaffold is an array ref, then we'll recurse (below)
            {
                push @fields, $next_scaffold if $next_scaffold;
                next SCAFFOLD;
            }
        }
    	elsif ( $tag =~ m/^(TDX|DT|DD|DIV|SPAN|RESIDUE)$/ )
        {
    		$next_scaffold = $$scaffold[1];
            if ( 'ARRAY' ne ref $next_scaffold  ) # if next_scaffold is an array ref, then we'll recurse (below)
            {
                push @fields, $next_scaffold if $next_scaffold;
                next SCAFFOLD;
            }
        }
        elsif ( 'AN' eq $tag ) 
        {
            #my $lbl = $$scaffold[1];
            push @fields, $$scaffold[1] if $$scaffold[1];
            push @fields, $$scaffold[2] if $$scaffold[2];
            next SCAFFOLD;
        }
        elsif ( 'AQ' eq $tag ) 
        {
            #my $lbl = $$scaffold[1];
            push @fields, $$scaffold[2] if $$scaffold[2];
            push @fields, $$scaffold[3] if $$scaffold[3];
            next SCAFFOLD;
        }
        elsif ( $tag =~ m{^(F|SNIP)$} ) # another idea: REGEX and F give their results to a sub-scraperFrame
        {                                     #  instead of to a field - gdw.2003.01.16
            my @ary = @$scaffold;
            shift @ary;
            shift @ary if (($tag eq 'SNIP') && $ary[0] && !ref($ary[0])); 
            map {
                if ( 'ARRAY' eq ref($_) ) {
                    push @$next_scaffold, @$_;
                } else {
                    push @fields, $_;
                }
            } @ary;
        }
        elsif ( 'CALLBACK' eq $tag ) 
        {
            my @ary = @$scaffold;
            shift @ary; shift @ary; shift @ary; shift @ary;
            $next_scaffold = shift @ary;
            unless ( 'ARRAY' eq ref $next_scaffold ) {
                push @fields, $next_scaffold if ( defined $next_scaffold );
                next SCAFFOLD;
            }
        }
        elsif ( $tag eq 'XPath' )
        {
            $next_scaffold = $$scaffold[2];
            unless ( 'ARRAY' eq ref $next_scaffold ) {
                push @fields, $next_scaffold if ( defined $next_scaffold );
                next SCAFFOLD;
            }
        }
        elsif ( $tag eq 'TRACE' )
        {
            next SCAFFOLD;
        }
        else {
            die "Can't recognize Opcode '$tag' in scraper frame, from WWW::Scraper::Response::fieldCapture()";
        }
        push @fields, fieldCapture($next_scaffold) if $next_scaffold;
    }
    return @fields;
}


sub new { 
    my $SubClass = shift;
    die "Scraper::Response::new() requires a subclass-name parameter." if !defined $SubClass || ref($SubClass);
    $SubClass =~ s{^WWW\::Scraper\::Response\::}{};

    my $self;
    my $scraperFrameCount = 0;
    my $canonicalByResponseSubClassParameters = 0;
    $SubClass = "::$SubClass";

    my (%subFields,$countSubFields);
    unless ( $AlreadyDeclared{$SubClass} ) {
        
        $subFields{'url'} = 1    if $SubClass eq '::Sherlock'; # Help Sherlock along.
        $subFields{'detail'} = 1 if $SubClass eq '::Sherlock'; # Help Sherlock along.
        
        while ( my $whatzit = shift ) {
            if ( my $rf = ref $whatzit ) {
                if ( 'HASH' eq $rf ) {
                   map { $subFields{$_} = $whatzit->{$_} || 1 } keys %$whatzit;
                   $canonicalByResponseSubClassParameters = 1;
                }
                elsif ( 'ARRAY' eq $rf ) {
                    $scraperFrameCount += 1;
                    map { $subFields{$_} = (defined $subFields{$_})?3:$scraperFrameCount if defined $_ } fieldCapture($whatzit);
                }
                else {
                    die "Invalid parameter to Scraper::Response: '$whatzit'";
                }
            }
        }
        delete $subFields{''}; # undef's in frame code's parameter lists are allowed, but should be ignored.

        my $subFieldsStruct = join '\'=>\'@\',\'__', keys %subFields;
        die "No fields were found in the scraperFrames for WWW::Scraper::Response$SubClass\n" unless keys %subFields;

        my $type = $SubClass;
        $type =~ s{^::}{};
        my $typeLeaf = $type;
        $typeLeaf =~ s{^.*:([^:]+)$}{$1};
        my $baseClasses = '';
        $baseClasses = "WWW::Scraper::Response::$1" if ( $type =~ m{^(.*)::[^:]+$} );
        $baseClasses = "WWW::Scraper::Response$SubClass\::_struct_ $baseClasses WWW::Scraper::Response";
        { 
        no warnings 'redefine';
        eval <<EOT;
{ package WWW::Scraper::Response$SubClass\::_struct_;
use Class::Struct;
    struct ( 'WWW::Scraper::Response$SubClass\::_struct_' => {
                 '_state'   => '\$'
                ,'_searchObject'  => '\$'
                ,'_fieldCount'  => '\$'
                ,'_fieldNames'  => '\$'
                ,'_skipDetailPage' => '\$'
                ,'_gotDetailPage'  => '\$'
                ,'_engines' => '\%'
                ,'_native_query' => '\$'
                ,'_native_options' => '\$'   # reference to hash of native_options.
                ,'_ScraperEngine'  => '\$'
                ,'_Scraper_debug'  => '\$'
                ,'_grubLevel'  => '\$'
                ,'_hitfound'   => '\$'
                ,'SubHitList'  => '\$'
                ,'SubHitList'  => '\$'
# Now for the $SubClass specific members.
,'__$subFieldsStruct'=>'\@'
                }
           );
}

package WWW::Scraper::Response$SubClass;
use WWW::Scraper::Response;
use vars qw(\@ISA);
\@ISA = qw( $baseClasses );
sub new { bless new WWW::Scraper::Response$SubClass\::_struct_ }
sub type { return '$type' }
sub typeLeaf { return '$typeLeaf' }
1;
EOT
        }
        die $@ if $@;
        $AlreadyDeclared{$SubClass} = [(keys %subFields)+11, \%subFields];
    
    # Build 'wantarray' context sensitive accessors for all fields
    # Build lazy-accessors for fields available from the Details page.
#    my $fieldNames = ${AlreadyDeclared{$SubClass}}[1];
    
        my $accessors = '';
        for ( keys %subFields ) {
        if ( $subFields{$_} == 1 ) {
            $accessors .= <<EOT;
sub $_ {
    my \$slf = shift;
    my \$val = shift;
    if ( defined \$val ) {
        \$slf->_hitfound(1);
        my \$ref = \$slf->__$_();
        if ( defined \$ref ) {
            push \@\$ref, \$val;
        } else {
            \$slf->__$_(1,\$val);
        }
    }
    if ( wantarray ) {
        return \@{\$slf->__$_()};
    } else {
        return \${\$slf->__$_()}[0];
    }
}
EOT
        }
        if ( $subFields{$_} == 2 ) {
            $accessors .= <<EOT;
sub $_ {
    my \$slf = shift;
    my \$val = shift;
    \$slf->ScrapeDetailPage(\$slf->url());
    if ( defined \$val ) {
        \$slf->_hitfound(1);
        my \$ref = \$slf->__$_();
        if ( defined \$ref ) {
            push \@\$ref, \$val;
        } else {
            \$slf->__$_(1,\$val);
        }
    }
    if ( wantarray ) {
        return \@{\$slf->__$_()};
    } else {
        return \${\$slf->__$_()}[0];
    }
}
EOT
        }
        elsif ( $subFields{$_} == 3 ) {
            $accessors .= <<EOT;
sub $_ {
    my \$slf = shift;
    my \$val = shift;
    \$slf->ScrapeDetailPage(\$slf->url()) if defined(\$slf->_skipDetailPage()) && \$slf->_skipDetailPage() != 3;
    if ( defined \$val ) {
        \$slf->_hitfound(1);
        my \$ref = \$slf->__$_();
        if ( defined \$ref ) {
            push \@\$ref, \$val;
        } else {
            \$slf->__$_(1,\$val);
        }
    }
    if ( wantarray ) {
        return \@{\$slf->__$_()};
    } else {
        return \${\$slf->__$_()}[0];
    }
}
EOT
        }
    }

        my $warn = $^W;
        $^W = 0; # Eliminates useless "warnings" during make test.
        eval "{package WWW::Scraper::Response$SubClass; $accessors } 1";
        $^W = $warn;
        die $@ if $@;
    }

    eval "\$self = new WWW::Scraper::Response$SubClass";
    
    return $self;
}

# private - friend of WWW::Scraper.
sub _AddToHitList {
    my ($self,$hit) = @_;
    my $subHitList = $self->SubHitList;
    unless ( $subHitList ) {
        $subHitList = [];
        $self->SubHitList($subHitList);
    }
    push @$subHitList, $hit;
}

sub plug_elem {
    my ($self, $name, $value, $TidyXML) = @_;
    return unless defined $name;
    $value = [$value] unless ref($value) eq 'ARRAY';
    $self->_elem($name, $$value[0]);
    for ( @$value ) {
        # sometimes this crashes cause $name is undefined.
        # I don't know how it happens, but happened with ::CNN a lot. gdw.2002.09.09
        eval { $self->$name(\$_); }; #die $@ if $@;
    }
    $self->_hitfound(1);
}
sub plug_url {
    my ($self, $url) = @_;
    $self->add_url($url);
    $self->url(\$url);
    $self->_hitfound(1);
}


# Return a table of names and origins for all data result columns.
sub GetFieldNames {
    my $SubClass = ref(shift);
    $SubClass =~ s{^WWW\::Scraper\::Response}{};
    return $AlreadyDeclared{$SubClass}[1];
}

# Return a table of names and titles for all data result columns.
sub GetFieldTitles {
    my ($self) = @_;
    my $answer = {'url' => 'URL'};
    for ( keys %{$self->GetFieldNames} ) {
        $answer->{$_} = $_ unless $_ =~ /^_/  or $_ =~ /^WWW::Search/;
    }
    return $answer;
}


sub GetFieldValues {
    my $self = shift;
    my $answer = {
#                'relevance'  => $self->relevance()
               'url'        => scalar $self->url()
           };
    for ( keys %$self ) {
        $answer->{$_} = $self->{$_} unless $_ =~ /^_/ or $_ eq 'url';
    }
    return $answer;
}

# This gets the target document via HTTP GET, if needed.
sub response {
    my ($self) = @_;

    my $request = HTTP::Request->new(GET => ${$self->url()});
    $self->{'_response'} = $self->_searchObject()->{'user_agent'}->request($request);
    return $self->{'_response'};
}


sub content {
    my ($self) = @_;

    my $response = $self->response();
    return $response->content() if $response->is_success;
    return undef;
}

# The default Response class "detail page" frame is null.
sub scraperDetail { undef }

sub toString { shift->asString(@_) }
sub asString {
    my ($self, $mod, $tabnum) = @_;
    my $answer = '';

    $mod = 0 unless $mod; # Prevents useless diagnostics message.
    $tabnum = 0 unless $tabnum; # Prevents useless diagnostics message.

    $answer .= "    "x$tabnum."#--- ".ref($self)." ---#\n";
    my %resultTitles = %{$self->GetFieldTitles()};# unless %resultTitles;
    my %results = %{$self->GetFieldValues()};
#        for ( keys %resultTitles ) {
    my $fieldNames = $self->GetFieldNames();
    for ( keys %$fieldNames ) {
        if ( $mod == 0 ) {
            my @value = $self->$_;
            $answer .= "    "x$tabnum."$resultTitles{$_}: (";
            my $comma = '';
            for ( @value ) {
                #next unless defined $_ and defined $$_; #hmm. . . how does this happen, in eBay.
                $answer .= "$comma'$$_'";# if $results{$_};
                $comma = ', ';
            }
            $answer .= ")\n";
        } else {
            my $value = $self->$_;
#                print "$resultTitles{$_}:= '$results{$_}'\n";# if $results{$_};
            if ( defined $value ) {
                $answer .= "    "x$tabnum."$_: '$$value'\n";# if $results{$_};
            } else {
                $answer .= "    "x$tabnum."$_: <NULL>\n";# if $results{$_};
            }
        }
    }
    if ( my $subHitList = $self->SubHitList ) {
        for ( @$subHitList ) {
            $answer .= $_->toString(0,$tabnum+1);
        }
    }
    $answer .= "\n";
}


# Pairs in the $anchors hash are combined into <A> anchor tags.
sub toHTML { shift->asHtml(@_) }
sub asHtml {
    my ($self, $anchors) = @_;
    my $result = "<TABLE BORDER='4'>"; #<DT>from:</DT><DD>".$self->{'searchObject'}->scraperName()."</DD>\n";
    my %results = %{$self->GetFieldValues()};
    my %resultTitles = %{$self->GetFieldTitles()};
    
    my $resultCount = 0;
    my %missingResults = ();
    for ( keys %resultTitles ) 
    {
        if ( $results{$_} ) {
            $resultCount += 1 if $_ ne 'url' and $_ ne 'Description' and $_ ne 'Title';
        } else {
            $missingResults{$_} = 1;
        }
    }

    my $title = $self->title;
    $title = $$title if ref($title);
    my $url;
    if ( $title eq 'Cached' or $title eq 'Similar pages' or
         $title =~ m{^More results from } ) {
            $url = $self->cachedURL();
            $url = $$url if ref ($url);
    } else {
        $url = $results{'url'};
        $url = $$url if ref($url);
    }
    $result .= "<TR><TD><B>$resultCount</B> fields";
    if ( keys %missingResults ) {
        my $comma = '';
        $result .= '<BR>(';
        for ( sort keys %missingResults ) {
            $result .= $comma.$_;
            $comma = ',';
        }
        $result .= ')';
    }
    $idCounter += 1;
    $result .= "</TD><TD COLSPAN='2'>$resultTitles{'title'}: <A NAME='a_$idCounter' HREF='a_$idCounter' onclick='window.open(\"$url\",\"detailWindow\");detailWindow.focus()'>$title</A></TD></TR>\n";
    
    $result .= "<TR><TD COLSPAN='3'>$resultTitles{'company'}: <A HREF='$results{'companyProfileURL'}'>$results{'company'}</A></TD></TR>\n"
        if ($results{'companyProfileURL'});

    for my $title ( sort keys %resultTitles ) {
        next if $title eq 'companyProfileURL' or $title eq 'company';
        next if $title eq 'url' or $title eq 'title' or $title eq 'Description' or $title eq 'Title';
        next unless $results{$title};
        my @rslt = $self->$title;
        shift @rslt unless $rslt[0];
        $result .= "<TR><TD COLSPAN='1' valign='top'>$resultTitles{$title}</TD><TD COLSPAN='2'>";
        my $comma = '';
        for ( @rslt ) {
           if ( $resultTitles{$title} =~ m{url}i ) {
              $result .= "$comma<a href=\"$$_\">$$_</a>";
           } else {
              $result .= "$comma$$_";
           }
           $comma = "<BR>"
        }
        $result .= "</TD></TR>\n";
    }
    return $result.'</TABLE><BR>';
}


sub SkipDetailPage {
    my $self = shift;
    return $self->_skipDetailPage() if $_[0] < 1 or $_[0] > 3;
    $self->_skipDetailPage(@_);
}

# Fetch and scrape the detail page if necessary.
sub ScrapeDetailPage {
    my ($self, $url) = @_;

    return unless $url;
    return if defined($self->_skipDetailPage()) && $self->_skipDetailPage() == 1;
    
    my $detail = $self->_gotDetailPage();
    return if $detail;

    my $scraper = $self->_ScraperEngine();

    print STDERR 'DETAIL PAGE: '.$$url. "\n" if ($scraper->ScraperTrace('U'));

    eval {
        # Why does http_request() cause Scraper::Brainpower to fail "Object Not Found" on next_url?        
        # this code from WWW::Search::http_request().
        use HTTP::Request;
        my $request = new HTTP::Request('GET', $$url);
        
        if ($scraper->is_http_proxy_auth_data)
        {
            $request->proxy_authorization_basic($scraper->http_proxy_user,
                                                $scraper->http_proxy_pwd);
        }
        $scraper->{'_cookie_jar'}->add_cookie_header($request) if ref($scraper->{'_cookie_jar'});
        
        my $ua = $scraper->{'user_agent'};
        my $response = $ua->request($request);
        $detail = $response->content();
    };
    return if $@;
        
    $self->_gotDetailPage($detail);
    my $debug = '';
    # Get scraper detail frame from the Response class, or the engine class if no Response frame.
    my $scraperDetail = $self->scraperDetail?$self->scraperDetail:$scraper->scraperDetail();
    $scraper->scrape($detail, $debug, $scraperDetail, $self);
}

1;

