
####################################################################################
####################################################################################
####################################################################################
####################################################################################
package WWW::Scraper;

use strict;
require Exporter;
use vars qw($VERSION $MAINTAINER @ISA @EXPORT @EXPORT_OK $PRINT_VERSION);

$VERSION = '3.05';

my $CVS_VERSION = sprintf("%d.%02d", q$Revision: 1.2 $ =~ /(\d+)\.(\d+)/);
$MAINTAINER = 'Glenn Wood http://search.cpan.org/search?mode=author&query=GLENNWOOD';
$PRINT_VERSION = 0;

sub import
{
    my $package = shift;

    for my $opts (grep { "HASH" eq ref($_) } @_)
    {
        for my $opt ( keys %$opts ) {
            my $optfunc = 
            {
                'PRINT_VERSION' => sub { $WWW::Scraper::PRINT_VERSION = 1; }
            }->{$opt};
            if ( $optfunc ) {
                &$optfunc($opts->{$opt});
            } else {
                warn "Unknown option '$opt' in $package\n";
            }
        }
    }

    # Prints "WWW::Scraper v3.01", as appropriate to the sub-class of Scraper.
    eval "print \"$package v\$$package\::VERSION\\\n\"" if ( $WWW::Scraper::PRINT_VERSION );
    
    @_ = ($package, grep { "HASH" ne ref($_) } @_);
    goto &Exporter::import;
}


use Carp ();
use URI::URL; # some Unix boxes simply won't load this one via WWW:Search, so . . .

use WWW::Search( 2.28 );
use WWW::Scraper::Request;
use WWW::Scraper::Response;
use WWW::Scraper::Response::generic;
use WWW::Scraper::TidyXML;
use WWW::Scraper::Opcode;

@EXPORT_OK = qw( generic_option testParameters trimTags trimLFs trimLFLFs trimComments
                @ENGINES_WORKING addURL trimXPathAttr trimXPathHref
                findNextForm findNextFormInXML removeScriptsInHTML cleanupHeadBody);


#------------------------------------------------------------------#
# Here we begin our gradual migration from "can-o-worms" to 
#   Class::Struct structured Scraper.
{ package WWW::Scraper::_struct_;
use Class::Struct;
    struct ( 'WWW::Scraper::_struct_' =>
              {
                  'response'          => '$'
                 ,'searchEngineHome'  => '$'
                 ,'searchEngineLogo'  => '$'
                 ,'errorMessage'      => '$'
                 ,'_artifactFolder'    => '$' # Folder into which certain Scraper artifacts will be gathered.
                 ,'_responseClass'     => '$'
                 ,'_wantsNativeRequest' => '$'
                 ,'_wwwSearchBackend' => '$'
                 ,'_forInterator'     => '$'
                 ,'_retryGetCount'    => '$'
                 ,'_tidyXmlObject'    => '$'
                 ,'pageNumber'        => '$' # Page number of the current 'response' object.
                 ,'_scraperRequest'   => '$'
                 ,'_scraperFrame'     => '$'
                 ,'_scraperDetail'    => '$'
              }
           );
}
use base qw( WWW::Scraper::_struct_ WWW::Search Exporter );
my @HitStack = ();
#------------------------------------------------------------------#

sub new {
    my ($class, $subclass, $native_query, $native_options) = @_;
    
    my ($self, $wantsNativeRequest);
    $subclass = '' unless $subclass;
    $wantsNativeRequest = $subclass =~ s/^NativeRequest\:\:(.*)$/$1/;
    if ( $subclass =~ m-^\.\.[\/](.*)$- ) {  # Allow the form "../name" to indicate
       die "The '..\\backend' form is deprecated in favor of scraperFrame = 'WWW::Search::backend' - see HeadHunter.pm for an example.\n";
    } else {
        if ( $subclass =~ s/^(.*)\((.*)\)$/$1/ ) {
            my $subclassVersion = $2;
            eval "use WWW::Scraper::$subclass($subclassVersion)";
            if ( $@ ) {
                print "Can't use engine $subclass($subclassVersion): $@\n";
                return undef;
            }
        }
        
## > > > > > >  #############################################################################################
                #############################################################################################
                #############################################################################################
                #############################################################################################
                # THIS STUFF IS A FACTORING OF WWW::Search::new() - we must track any of Martin's changes!
                # $self = new WWW::Search("../Scraper::$subclass");
                my $newclass = "${class}::$subclass";
                if (!defined(&$newclass)) 
                {
                    eval "use $newclass";
                    Carp::croak("unknown Scraper interface '$newclass': $@") if ($@);
                }
                
                $self = bless {
                                engine => $newclass,
                                maximum_to_retrieve => 500,  # both pages and hits
                                interrequest_delay => 0.25,  # in seconds
                                agent_name => "WWW::Scraper/$VERSION",
                                agent_e_mail => 'glenwood@alumni.caltech.edu;MartinThurn@iname.com',
                                env_proxy => 0,
                                http_method => 'GET',
                                http_proxy => '',
                                http_proxy_user => undef,
                                http_proxy_pwd => undef,
                                timeout => 60,
                                _debug => 0,
                                _parse_debug => 0,
                                search_from_file => undef,
                                search_to_file => undef,
                                search_to_file_index => 0,
                                @_,
                                # variable initialization goes here
                               }, $newclass;
                    $self->reset_search();
                }
                #############################################################################################
                #############################################################################################
    
    $self->_wantsNativeRequest($wantsNativeRequest);

    $self->{'agent_name'} = 'Mozilla/4.0 (compatible; MSIE 4.01; Windows 95)';#"Mozilla/WWW::Scraper/$VERSION";
    $self->{'scraperQF'} = 0; # Explicitly declare 'scraperQF' as the deprecated mode.
    $self->{'scraperName'} = $subclass;

    $self->_init(); # Some property initializations, mostly to eliminate useless diagnostic warnings.

    # Finally, call the sub-scraper's init() method.
    return $self->init($subclass, $native_query, $native_options);
}

sub _init {
    my $self = shift;
    $self->{cache} = [];  # Eliminate some useless "warnings" from WWW::Search(lines 544-549) during make test, and elsewhere.
    $self->pageNumber(0); # Use of uninitialized value in addition (+) at lib/WWW/Search/Scraper.pm line 609
    
    if ( $self->scraperFrame ) {
        my @scfld = @{$self->scraperFrame};
        my $next_scaffold = $scfld[$#scfld] if ref($scfld[$#scfld]) eq 'ARRAY';
        WWW::Scraper::Opcode::InitiateScaffold($next_scaffold) if $next_scaffold; #$self->GetScraperFrame)};
    }
    
    if ( $self->scraperDetail ) {
        my @scfld = @{$self->scraperDetail};
        my $next_scaffold = $scfld[$#scfld] if ref($scfld[$#scfld]) eq 'ARRAY';
        WWW::Scraper::Opcode::InitiateScaffold($next_scaffold) if $next_scaffold; #$self->GetScraperDetail);
    }
}


# The Scraper module should override this.
sub init {
   my ($self, $subclass, $native_query, $native_options) = @_;
   my $scraperFrame = $self->scraperFrame();
   if ( ${$scraperFrame}[0] =~ m{^WWW::Search::(.*)$} ) {
      $self->_wwwSearchBackend(new WWW::Search($1, $native_query, $native_options)); # Uses a WWW::Search backend.
   } else {
       if ( ref($native_query) && !$native_options ) {
           $native_options = $native_query;
           $native_query = undef;
       }
       $self->native_query($native_query, $native_options);
   }
   return $self;
}


# To help avoid embarrassment when he inadvertently releases test, debug or tracing code to CPAN, Glenn uses this.
sub isGlennWood { return $ENV{'VSROOT'} and ($ENV{'USERNAME'} eq 'Glenn') and ($ENV{'USERDOMAIN'} eq 'ORCHID'); }

# Access methods for the structural declarations of this Scraper engine.
use vars qw($scraperRequest $scraperFrame $scraperDetail);
sub SetScraperRequest { my ($self,$rqst)  = @_; $self->_scraperRequest($rqst); }
sub SetScraperFrame   { my ($self,$frame) = @_; $self->_scraperFrame($frame); 
    WWW::Scraper::Opcode::InitiateScaffold($frame->[1]) if $frame; #$self->GetScraperFrame)};
}
sub SetScraperDetail  { my ($self,$frame) = @_; $self->_scraperDetail($frame); 
    WWW::Scraper::Opcode::InitiateScaffold($frame->[1]) if $frame; #$self->GetScraperFrame)};
}
sub GetScraperRequest { $_[0]->_scraperRequest; }
sub GetScraperFrame   { $_[0]->_scraperFrame; }
sub GetScraperDetail  { $_[0]->_scraperDetail; }

sub scraperFrameX {
    $_[0]->{'_options'}{'scrapeFrame'} = $_[1] if $_[1];
    return $_[0]->{'_options'}{'scrapeFrame'}
}

# backward compatible, pre v3.01 ( gdw.2003.03.14 )
sub scraperRequest { return $_[0]->GetScraperRequest }
sub scraperFrame   { $_[0]->SetScraperFrame($_[1]) if $_[1];  return $_[0]->GetScraperFrame }
sub scraperDetail  { $_[0]->SetScraperDetail($_[1]) if $_[1]; return $_[0]->GetScraperDetail }

# Return empty testFrame for sub-scrapers that choose not to provide one.
sub testParameters {
    my ($self) = @_;

    if ( ref $self ) {
        $self->{'isTesting'} = 1;
    }
    
    my $isNotTestable = WWW::Scraper::isGlennWood()?0:'No testParameters provided.';
    return { 
             'SKIP' => $isNotTestable
            ,'testNativeQuery' => 'search scraper'
            ,'expectedOnePage' => 9
            ,'expectedMultiPage' => 11
            ,'expectedBogusPage' => 0
           };
}

sub artifactFolder {
    my ($self, $fldr) = @_;
    if ( $fldr ) {
        mkdir $fldr unless -d $fldr;
        $self->_artifactFolder($fldr);
    }
    return $self->_artifactFolder();
}


sub generic_option 
{
    my ($option) = @_;
    return 1 if $option =~ /^scrape/;
    return WWW::Search::generic_option($option);
}

# A generalize get/set method for object attributes.
sub _attr {
    my ($self, $attr, $value) = @_;
    my $rtn = $self->{$attr};
    $self->{$attr} = $value if defined $value;
# neat idea, but we've got to rewrite a lot of method invocations to make this ok. gdw.2001.07.04
#    if ( wantarray ) {
#        return $rtn if 'ARRAY' eq ref $rtn;
#        return [$rtn];
#    }
    return $rtn;
}
# ## # ## # ## # ## # ## # ## # ## # ## # ## # ## # ## # ## # ## # ## # ## # ## # ## 
### # ## # ## # ## # ## # ## # ## # ## # ## # ## # ## # ## # ## # ## # ## # ## # ## 
## # ## # ## # ## # ## # ## # ## # ## # ## # ## # ## # ## # ## # ## # ## # ## # ## #
sub query          { $_[0]->_attr('_query', $_[1]) }
sub queryDefaults  { $_[0]->_attr('_queryDefaults', $_[1]) }
sub queryOptions   { $_[0]->_attr('_queryOptions', $_[1]) }
sub fieldTranslations  { $_[0]->_attr('_fieldTranslations', $_[1]) }


# Some tracing options -
#   U - lists URLs as they are generated/accessed.
#   T - lists progress of each TidyXML tree-walking operation.
#   d - excruciating details about parsing the results and details pages.
sub ScraperTrace {
    return undef unless defined $_[0]->{'_traceFlags'};
    return $_[0]->{'_traceFlags'} unless $_[1]; # default traceFlags if no match string sent.
    return ( $_[0]->{'_traceFlags'} =~ m-$_[1]- );
}
sub setScraperTrace {
    $_[0]->{'_traceFlags'} = $_[1];
}

# ## # ## # ## # ## # ## # ## # ## # ## # ## # ## # ## # ## # ## # ## # ## # ## # ## 
### # ## # ## # ## # ## # ## # ## # ## # ## # ## # ## # ## # ## # ## # ## # ## # ## 
## # ## # ## # ## # ## # ## # ## # ## # ## # ## # ## # ## # ## # ## # ## # ## # ## #
sub SetRequest {
    my ($self, $rqst) = @_;
    
    my $nonBlankWWWSearchNativeQuery = 'nonBlankWWWSearchNativeQuery';
    if ( $rqst ) {
        # Make sure the request object is ready for us.
        $rqst->prepare($self);
        
        # Move the debug option from the request to the Scraper module.
        $self->{'_debug'} = $rqst->_Scraper_debug() if defined $rqst->_Scraper_debug();

        $self->{'_scraperRequest'} = $rqst;
        
        $nonBlankWWWSearchNativeQuery = $rqst->_native_query() || $nonBlankWWWSearchNativeQuery;
    }
    
    # WWW::Search(2.26) required native_query to be non-blank, even before it hands it off to Scraper!
    $self->{'native_query'} = $nonBlankWWWSearchNativeQuery unless $self->{'native_query'};

    return $self->{'_scraperRequest'};
}

sub GetRequest { return $_[0]->{'_scraperRequest'} }

sub SetResponseClass { $_[0]->_responseClass($_[1]) }
sub GetResponseClass { $_[0]->_responseClass() }


sub native_setup_search
{
    my $self = shift;
    my ($native_query, $native_options) = @_;
    $native_query = WWW::Search::unescape_query($native_query); # Thanks, but no thanks, Search.pm!

    $self->{'_first_url'} = undef;
    $self->{'_first_url_method'} = undef;

    my $scraperRequest = $self->scraperRequest;

    # ## # ## # ## # ## # ## # ## # ## # ## # ## # ## # ## # ## # ## # ## # ## # ## # ## 
    #
    # This pecular set of code translates old interface mode into 'canonical request' mode,
    #
    # NOTE THAT IF THE CANONICAL REQUEST HAS BEEN SET, ALL native_setup_search() PARAMETERS ARE IGNORED!
    #
    # otherwise, they get picked up here.

    # ## # ## # ## # ## # ## # ## # ## # ## # ## # ## # ## # ## # ## # ## # ## # ## # ## 
    # Get the scraperRequest declaration of the Scraper module, or fake one (as in when using a WWW::Search module).
    unless ( $scraperRequest ) {
        $scraperRequest = 
            { 
                  'type' => 'SEARCH'    # This is a WWW::Search module - notify native_setup_search_NULL() of that.
                  # This is the basic URL on which to build the query.
                 ,'url' => 'http://'
                  # names the native input field to recieve the query string.
                 ,'nativeQuery' => 'query'
                  # specify defaults, by native field names
                 ,'nativeDefaults' => { }
                 ,'fieldTranslations' => undef # This gives us a null %inputsHash, so WWW::Scraper will ignore that functionality (hopefully)
                 , 'cookies' => 0 # The WWW::Search module must maintain its own cookies.
            };
        $self->scraperRequest($scraperRequest, $native_query, $native_options);
    }
    # ## # ## # ## # ## # ## # ## # ## # ## # ## # ## # ## # ## # ## # ## # ## # ## # ## 
    
    #$self->SetRequest( new WWW::Scraper::Request($self, $native_query, $native_options) ) unless ( $self->GetRequest());

    # These traceFlags will ultimately come from many places . . .
    #$self->setScraperTrace($self->{'_debug'}) unless $self->{'_traceFlags'};

    for ( $self->scraperRequest()->{'type'} ) {
        m/^SHERLOCK$/    && do { return $self->native_setup_search_SHERLOCK(@_); };
        m/^FORM$/        && do { return $self->native_setup_search_FORM(@_); };
        m/^QUERY$|^GET$/ && do { return $self->native_setup_search_QUERY(@_); };
        m/^POST$/        && do { $self->{'_http_method'} = 'POST';
                              return $self->native_setup_search_QUERY(@_); };
        m/^SEARCH$/      && do { return $self->native_setup_search_NULL(@_); };
        m/^WSDL$/        && do { return $self->native_setup_search_WSDL(@_); };
        m/^WWW::Search/  && do { return $self->native_setup_search_WWW_Search(@_); };
        die "Invalid mode in WWW::Scraper - '$_'\n";
    }
}



sub native_setup_search_SHERLOCK
{
    my ($self, $native_query, $native_options) = @_;
    $self->SetRequest( new WWW::Scraper::Request($self, $native_query, $native_options) ) unless ( $self->GetRequest());
    die "Unimplemented mode in WWW::Scraper - 'SHERLOCK'\n";
}


sub native_setup_search_FORM
{
    my ($self, $native_query, $native_options) = @_;
    $self->SetRequest( new WWW::Scraper::Request($self, $native_query, $native_options) ) unless ( $self->GetRequest());
    
    $self->user_agent('user');
    $self->{_next_to_retrieve} = 0;
    
    # $scraperForm = [ 'url', 'formIndex' (or formName, NYI), 'submitButtonName' or undef ]
    my $url = $self->scraperRequest($native_query, $native_options)->{'url'};
    if ( ref $url ) {
        $self->{'_base_url'} = &$url($self, $self->GetRequest()->_native_query(), $self->{'native_options'});
    } else {
        $self->{'_base_url'} = $url;
    }
    unless ( $self->{'_base_url'} ) {
        print STDERR "No base url was specified by ".ref($self).".pm, so no search is possible.\n";
        undef $self->{'_next_url'};
        return undef;
    }
    $self->{'_http_method'} = 'GET' unless $self->{'_http_method'};    

    print STDERR 'FORM URL: '.$self->{'_base_url'} . "\n" if ($self->ScraperTrace('U'));
    my $response = $self->http_request($self->{'_http_method'}, $self->{'_base_url'});
    unless ( $response->is_success ) {
        print STDERR "Request for FORM failed in Scraper.pm: ".$response->message() if $self->ScraperTrace();
        return undef ;
    }

    my @forms = HTML::Form->parse($response->content(), $response->base());
    return undef unless @forms;
    my $formNameOrNumber = $self->scraperRequest->{'formNameOrNumber'};
    my $form;
    if ( $formNameOrNumber =~ m{^\d+$} ) { # is formNameOrNumber a number?
        $form = $forms[$self->scraperRequest->{'formNameOrNumber'} or 0];
    } else { # it is a name, not a number.
        # Unfortunately, HTML::Form->parse() does not stash the forms' names, so we use
        # this inperfect method to get to them (inperfect? what if "<form" is in a comment?)
        my (@formNames) = ($response->content =~ m{<form\s[^>]*name=['"]?([^'" >]+)['"> ]}gsi);
        for my $tmp (@forms) {
            if ( $formNameOrNumber eq shift @formNames ) {
                $form = $tmp;
                last;
            }
        }
    }
    return undef unless $form;

    $self->{'_http_method'} = $self->{'search_method'} = uc $form->method() || 'POST';
    
    # Finally figure out the url.
    # Process the inputs.
    # Fill in the defaults, first
    my %optsHash = %{$self->queryDefaults()};
    # Override those with what came with the request.
    my $options_ref = $self->{'native_options'};
       foreach (sort keys %$options_ref) {
        $optsHash{$_} = $$options_ref{$_};
    };
    $optsHash{$self->scraperRequest()->{'nativeQuery'}} = $self->GetRequest()->_native_query() if $self->scraperRequest()->{'nativeQuery'};

    for my $key (sort keys %optsHash) {
        my $opts = $optsHash{$key};
#        if ( 'ARRAY' eq ref $opts ) {
#            for ( @$opts) {
#                $options .= "$key=".cgi_escape($_)."&";
#            }
#        } else {
            my $field = $form->find_input($key);
            next unless $field;
            my $fldtyp = $field->type();
            if ( $fldtyp eq 'option' ) {
            my $n = 1;
            SUBFIELD: while ( my $field = $form->find_input($key, undef, $n++) ) {
                    for ( @{$field->{'menu'}} ) {
                        if ( $_ eq $opts ) {
                            $field->value($opts);
                            last SUBFIELD;
                        }
                    }
                }
#'password'', ``hidden'', ``textarea'', ``image'', ``submit'', ``radio'',
#``checkbox'', ``option''...my $x = $field->form_name_value();
            }
            else {
                $field->value($opts);
            }
        }
#bless( {
#      'seen' => [
#        1,
#        0
#      ],
#      'menu' => [
#        undef,
#        '2'
#      ],
#      'multiple' => 'multiple',
#      'current' => 0,
#      'size' => '4',
#      'type' => 'option',
#      'name' => 'countyIDs'
#    }, 'HTML::Form::ListInput' )
    
    my $submit_button = $form->find_input($self->scraperRequest()->{'submitButton'}, 'submit');
    $submit_button = $form->find_input($self->scraperRequest()->{'submitButton'}, 'image') unless $submit_button;
    die "Can't find 'submit' button named '".$self->scraperRequest()->{'submitButton'}."' in '$url'" unless $submit_button;
    my $req = $submit_button->click($form); #

    $self->{_base_url} = $self->{_next_url} = $req->uri();
    $self->{_base_url} .= '?'.$req->content() if $req->content();
    print STDERR "FORM SUBMIT: ".$self->{_base_url} . "\n" if $self->ScraperTrace('U');
}


sub native_setup_search_QUERY
{
    my ($self, $native_query, $native_options) = @_;
   $self->SetRequest( new WWW::Scraper::Request($self, $native_query, $native_options) ) unless ( $self->GetRequest());
    
    $self->user_agent('user');
    $self->{_next_to_retrieve} = 0;
    
    my $url = $self->scraperRequest($native_query, $native_options)->{'url'};
    
    if ( ref $url ) {
        $self->{'_base_url'} = &$url($self, $self->GetRequest()->_native_query(), $self->{'native_options'});
    } else {
        $self->{'_base_url'} = $url;
    }
    unless ( $self->{'_base_url'} ) {
        print STDERR "No base url was specified by ".ref($self).".pm, so no search is possible.\n";
        undef $self->{'_next_url'};
        return undef;
    }
    $self->{'_http_method'} = 'GET' unless $self->{'_http_method'};
#    $rqst->{'_base_url'} = $self->{'_base_url'};

    $self->{'_next_url'} = $self->generateQuery();
    print STDERR $self->{_next_url} . "\n" if $self->ScraperTrace('U');
}


# This one handles the deprecated Scraper::native_setup_search()
sub native_setup_search_NULL
{
    my ($self, $native_query, $native_options) = @_;
    $self->SetRequest( new WWW::Scraper::Request($self, $native_query, $native_options) ) unless ( $self->GetRequest());
    
    die "native_setup_search_NULL() is no longer supported!";
    # This is a cheap way to get back to the non-canonical form.
    # We'll clean up the rest of this code later, so it won't look
    # like such a waste of time to prepare(canonical) just to come
    # back to the legacy form here. gdw.2001.06.30
    #my ($native_query, $native_options) = ($self->GetRequest()->_native_query(), $self->{'native_options'});
    
    my $subJob = 'Perl';
    $self->user_agent('user');
    $self->{_next_to_retrieve} = 0;
    if (!defined($self->{_options})) {
	$self->{_options} = {
#	    'search_url' => 'http://www.defaultdomain.com/plus-cgi-bin/and-cgi-program-name'  SHOULD BE PASSED IN AS AN OPTION.
        };
    };
    $self->{'_http_method'} = 'GET';        # SHOULD BE PASSED IN AS AN OPTION; this is the default.
 
    my($options_ref) = $self->{_options};
    if (defined($native_options)) {
	# Copy in new options.
	foreach (keys %$native_options) {
	    $options_ref->{$_} = $native_options->{$_};
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
    $self->{_debug} |= $options_ref->{'search_debug'};
    $self->{_debug} = 2 if ($options_ref->{'search_parse_debug'});
    $self->{_debug} = 0 if (!defined($self->{_debug}));
    
    # Finally figure out the url.
    $self->{_base_url} = 
	$self->{_next_url} =
            	$self->{_options}{'search_url'} .
        	    "?" . $options .
            	"KEYWORDS=" . $native_query;

    print STDERR $self->{_next_url} . "\n" if $self->ScraperTrace('U');
}


sub native_setup_search_WSDL
{
    my ($self, $native_query, $native_options) = @_;
    
    $self->user_agent('user');
    $self->{_next_to_retrieve} = 0;
    
    my $url = $self->scraperRequest(@_)->{'url'};
    
    if ( ref $url ) {
        $self->{'_base_url'} = &$url($self, $self->GetRequest()->_native_query(), $self->{'native_options'});
    } else {
        $self->{'_base_url'} = $url;
    }
    unless ( $self->{'_base_url'} ) {
        print STDERR "No base url was specified by ".ref($self).".pm, so no search is possible.\n";
        undef $self->{'_next_url'};
        return undef;
    }
    $self->{'_http_method'} = 'GET' unless $self->{'_http_method'};
#    $rqst->{'_base_url'} = $self->{'_base_url'};

    $self->{'_next_url'} = $self->generateQuery();

    print STDERR $self->{_next_url} . "\n" if $self->ScraperTrace('U');
}



### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### 
### Use WWW::Search "backend", attached to this Scraper canonical engine, to do the scraping.
sub native_setup_search_WWW_Search {
   my ($self, $native_query, $native_options) = shift;
   $self->SetRequest( new WWW::Scraper::Request($self, $native_query, $native_options) ) unless ( $self->GetRequest());
   my $oSearch = $self->_wwwSearchBackend();
   ($oSearch->{'native_query'}, $oSearch->{'native_options'}) = ($self->GetRequest()->_native_query(), $self->{'native_options'});
   return $oSearch->native_setup_search($oSearch->{'native_query'}, $oSearch->{'native_options'});
}

sub cgi_escape
{
    my $text = join(' ', @_);
    $text = '' unless defined $text;
    $text =~ s/([^ A-Za-z0-9])/$URI::Escape::escapes{$1}/g; #"
    $text =~ s/ /+/g;
    return $text;
}

### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### 
# The options have been prepared into the Scraper Request object by Scraper::Request::prepare().
# generateQuery() creates the HTTP query based on _scraperNativeQuery.
sub generateQuery {
    my ($self) = @_;

    # Process the inputs.
    my $options = ''; # Was scraperRequest, now fieldTranslations 
    
    # The following line allows us to use native_query(), ala pre-v2.00 modules, with this Scraper.pm
#    $options = $self->queryFieldName().'='.$rqst->_native_query().'&' if $rqst->_native_query() and $self->queryFieldName();

    my $vals = $self->GetRequest->_scraperNativeQuery();

    # Fill in the defaults from the Scraper module.
    my $defaults = $self->queryDefaults();
    map { $vals->{$_} = $defaults->{$_} unless defined $vals->{$_} } keys %$defaults;

    for my $key (sort keys %{$vals}) {
        my $opts = $vals->{$key};
        if ( 'ARRAY' eq ref $opts ) {
            for ( @$opts) {
                $options .= "$key=".cgi_escape($_)."&";
            }
        } else {
            $options .= "$key=".cgi_escape($opts)."&";
        }
    };
    chop $options;
    return $self->{'_base_url'}.$options;
}



### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### 
sub native_retrieve_some
{
    my $self = shift;
    if ( $self->_wwwSearchBackend() ) {
       return $self->_wwwSearchBackend()->native_retrieve_some(@_);
    }
    my $debug = $self->{_debug};

    $self->{'total_hits_count'} = 0; # for HIT(i)

    # fast exit if already done
AGAIN:    
    unless ( $self->{_next_url} ) {
        print STDERR "END_OF_SEARCH: _next_url is empty.\n" if $self->ScraperTrace('U');
        return undef;
    };
    
    # get some
    print STDERR ref($self)."::native_retrieve_some: fetching " . $self->{_next_url} . "\n"  if ($self->ScraperTrace('U') && $debug );

    my $method = $self->{'_http_method'};
    $method = 'POST' unless $method;

    print STDERR "Fetching NEXT_URL via $method: '".$self->{_next_url}."'\n" if $self->ScraperTrace('U');
    
    $self->{'_last_url'} = $self->{_next_url};
    unless ( $self->{'_first_url'} ) {
        $self->{'_first_url'} = $self->{_next_url};
        $self->{'_first_url_method'} = $method;
    }
    
    # Some search engines don't connect every time, so we might give them a couple of retries.
    my $response;
   $self->_retryGetCount('0');
   while ( $self->keepRetrying() ) {
       $response = $self->http_request($method, $self->{_next_url});
   
       while ( $response->code() eq '302' ) {
           my $redirect = $response->header('location');
           if ( $redirect =~ m-^/- ) {
               my $url = $self->{_next_url};
               $url =~ m-^(\w+://[^/]*)/-;
               $url = $1;
               $self->{_next_url} = $url.$redirect;
           } elsif ( ! ($redirect =~ m-^(\w+://[^/]*)-) ) {
               my $url = $self->{_next_url};
               $url =~ m-^(.*/)-;
               $url = $1;
               $self->{_next_url} = $url.$redirect;
           } else {
               $self->{_next_url} = $redirect;
           }
           print STDERR "Redirected to: '".$self->{_next_url}."'\n" if $self->ScraperTrace('U');
           $method = $self->scraperRequest()->{'redirectMethod'} || $method;
           $response = $self->http_request($method, $self->{_next_url});
       }
   
       $self->{'_last_url'} = $self->{'_next_url'}; $self->{'_next_url'} = undef;
       $self->response($response);
       
       if ( $response->is_success ) {
           $self->pageNumber($self->pageNumber()+1);
          last;
       }
       else {
           $self->errorMessage("Request failed in Scraper.pm: ".$response->message());
           print STDERR $self->errorMessage()."\n" if $self->ScraperTrace();
           print STDERR $response->content()."\n" if $self->ScraperTrace('f'); # detailed failure reports.
           return undef;
       }
    }
    
    my $hits_found = $self->scrape($response->content(), $self->{_debug});

    # sleep so as to not overload the remote engine
    $self->user_agent_delay if ( defined($self->{_next_url}) );
    
    return $hits_found;
}


# Some search engines don't connect every time, so we might give them a couple of retries.
sub keepRetrying {
   my $self = shift;
   $self->_retryGetCount($self->_retryGetCount()+1);
   my $retryCount = $self->scraperRequest()->{'retry'} || 1;
   if ( $self->_retryGetCount() > $retryCount ) {
      return 0;
   }
   return 1;
}


### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### 
# Given a candidate hit, do post-selection.
# Return 1 to keep this hit, 0 to cast it away.
sub postSelect {
    my ($self, $rqst, $rslt) = @_;
    # By default, the Request object will do the postSelect for the Scraper module.
    # If the Scraper module wants to override that, then it overrides this Scraper::postSelect().
    
    my $fields = $rqst->FieldTitles;
    
    my $fieldTranslationsTable = $self->fieldTranslations();
    my $fieldTranslations = $fieldTranslationsTable->{'*'}; # We'll do this until context sensitive work is done - gdw.2001.08.18
    my $fieldTranslation;

    for ( keys %$fields ) {
        $fieldTranslation = $$fieldTranslations{$_};
        next if defined $fieldTranslation and $fieldTranslation eq '';
        # 'fieldTranslation' may be a string naming the option, or 
        # a subroutine tranforming the field into a (nam,val) pair,
        # or a FieldTranslation object - that's the only one that'll have a postSelect() method!
        if ( 'CODE' eq ref $fieldTranslation ) {
        }
        elsif ( ref $fieldTranslation ) # We assume any other ref is an object of some sort.
        { 
            return 0 unless $fieldTranslation->postSelect($self, $rqst, $rslt);
        }
    }
    return $rqst->postSelect($self, $rslt);
}


{ package WWW::Search;
sub scraperName {
   return $_[0]->{'scraperName'};
}

}



{
    package LWP::RobotUA;

# Dice always redirects the first query page via 302 status code.
# BAJobs frequently (but not always) redirects via 302 status code.
# We need to tell LWP::RobotUA that it's ok to redirect on Dice and BAJobs.
sub redirect_ok
{
    # draft-ietf-http-v10-spec-02.ps from www.ics.uci.edu, specify:
    #
    # If the 30[12] status code is received in response to a request using
    # the POST method, the user agent must not automatically redirect the
    # request unless it can be confirmed by the user, since this might change
    # the conditions under which the request was issued.
    
    my($self, $request) = @_;
    return 1 if $request->uri() =~ m-seeker\.dice\.com/jobsearch/jobsearch_r\.epl-i;
    return 1 if $request->uri() =~ m-seeker\.dice\.com/jobsearch/resultSummary\.epl-i;
#    return 1 if $request->uri() =~ m-jobsearch\.dice\.com/jobsearch/jobsearch\.cgi-i;
    return 1 if $request->uri() =~ m-www\.bajobs\.com/jobseeker/searchresults\.jsp-i;
    return 1 if $request->uri() =~ m-\.techies\.com/Common-i;
    return 0 if $request->method eq "POST";
    1;
}
}


##################### < E X C E P T I O N S > ######################
# some kind of problem with URI in LWP since LWP(5.60)
eval <<EOT
    use URI::http;
    { package URI::http;
    sub abs {
        my \$self = shift;
        return \$self->SUPER::abs(\@_) if \$_[0];
        return \$self->canonical(\@_);
    }
    use URI::https;
    { package URI::https;
    sub abs {
        my \$self = shift;
        return \$self->SUPER::abs(\@_) if \$_[0];
        return \$self->canonical(\@_);
    }
EOT
if ( ($LWP::VERSION ge '5.60') );
#################### < / E X C E P T I O N S > #####################


##### ##### ##### ##### ##### ##### ##### ##### ##### ##### ##### ##### ##### ##### ##### ##### 
 ##### ##### ##### ##### ##### ##### ##### ##### ##### ##### ##### ##### ##### ##### ##### ##### 
  ##### ##### ##### ##### ##### ##### ##### ##### ##### ##### ##### ##### ##### ##### ##### ##### 
   ##### ##### ##### ##### ##### ##### ##### ##### ##### ##### ##### ##### ##### ##### ##### ##### 
    ##### ##### ##### ##### ##### ##### ##### ##### ##### ##### ##### ##### ##### ##### ##### ##### 
     ##### ##### ##### ##### ##### ##### ##### ##### ##### ##### ##### ##### ##### ##### ##### ##### 
     ##### ##### ##### ##### ##### ##### ##### ##### ##### ##### ##### ##### ##### ##### ##### ##### 
    ##### ##### ##### ##### ##### ##### ##### ##### ##### ##### ##### ##### ##### ##### ##### ##### 
   ##### ##### ##### ##### ##### ##### ##### ##### ##### ##### ##### ##### ##### ##### ##### ##### 
  ##### ##### ##### ##### ##### ##### ##### ##### ##### ##### ##### ##### ##### ##### ##### ##### 
 ##### ##### ##### ##### ##### ##### ##### ##### ##### ##### ##### ##### ##### ##### ##### ##### 
##### ##### ##### ##### ##### ##### ##### ##### ##### ##### ##### ##### ##### ##### ##### ##### 

sub scrape { my ($self, $content, $debug, $scraperFrame, $hit) = @_;
    $scraperFrame = $self->scraperFrame() unless $scraperFrame;
   for (${$scraperFrame}[0]) {
       return $self->scraperHTML($scraperFrame, \$content, $hit, $debug) if m/HTML/;
       return $self->scraperTidyXML($scraperFrame, \$content, $hit, $debug) if m/TidyXML/;
   }
   die "Scraper mode '${$scraperFrame}[0]' is not implemented in version $VERSION of Scraper.pm for ".ref($self)."\n";
}

# private
sub scraperHTML { my ($self, $scaffold_array, $content, $hit, $debug) = @_;
    my $TidyXML = new WWW::Scraper::TidyXML($self, $content, {'frameType' => 'HTML', 'artifactFolder' => $self->artifactFolder()});
    $self->_tidyXmlObject($TidyXML);
    $TidyXML->m_asString($content);
    return $self->scraper($$scaffold_array[1], $TidyXML, $hit, $debug);
}

# private
sub scraperTidyXML { my ($self, $scaffold_array, $content, $hit, $debug) = @_;
    # Execute any preprocessors this TidyXML may declare.
    my $i = 1;
    while ( 'ARRAY' ne ref $$scaffold_array[$i] ) {
        my $datParser = $$scaffold_array[$i];
        $i += 1;
        $content = &$datParser($self, $hit, $content);
    }
    my $TidyXML = new WWW::Scraper::TidyXML($self, $content, {'frameType' => 'TidyXML', 'artifactFolder' => $self->artifactFolder()});
    $self->_tidyXmlObject($TidyXML);
    return $self->scraper($$scaffold_array[$i], $TidyXML, $hit, $debug);
}


# private
sub scraperRecurse { my ($self, $sub_string, $next_scaffold, $TidyXML, $hit, $debug) = @_;

    my $myTidyXML = $TidyXML;
    my ($saveContext, $saveFoundContext, $saveString);
    if ( $myTidyXML ) {
        $saveContext = $TidyXML->m_context();
        $saveFoundContext = $TidyXML->m_found_context();
        $myTidyXML->m_context($TidyXML->m_found_context);
        $saveString = $myTidyXML->m_asString();
        if ( $$sub_string ) {
            $myTidyXML->m_asString($sub_string);
        }
    } else {
        $myTidyXML = new WWW::Scraper::TidyXML;
        $myTidyXML->m_asString($sub_string);
    }
    
    unshift @HitStack, $hit;
    my $total_hits_found = $self->scraper($next_scaffold, $myTidyXML, $hit, $debug);
    shift @HitStack;

    $myTidyXML->m_context($saveContext);
    $myTidyXML->m_found_context($saveFoundContext);
    $myTidyXML->m_asString($saveString);

    return $total_hits_found;
}
   
# private
sub scraperRecurseAndChop { my ($self, $sub_string, $next_scaffold, $TidyXML, $hit, $debug) = @_;

    my $myTidyXML = $TidyXML;
    my ($saveContext, $saveFoundContext, $saveString);
    if ( $myTidyXML ) {
        ($saveContext,$saveFoundContext,$saveString) = ($TidyXML->m_context(),$TidyXML->m_found_context(),$myTidyXML->m_asString());
        $myTidyXML->m_context($TidyXML->m_found_context);
        if ( $$sub_string ) {
            $myTidyXML->m_asString($sub_string);
        }
    } else {
        $myTidyXML = new WWW::Scraper::TidyXML;
        $myTidyXML->m_asString($sub_string);
    }
    
    unshift @HitStack, $hit;
    my $total_hits_found = $self->scraper($next_scaffold, $myTidyXML, $hit, $debug);
    shift @HitStack;

    $myTidyXML->m_context($saveContext);
    $myTidyXML->m_found_context($saveFoundContext);
    $myTidyXML->m_asString($saveString);

    return $total_hits_found;
}
   
# private
sub scraper { my ($self, $scaffold_array, $TidyXML, $hit, $debug) = @_;

	# Here are some variables that we use frequently done here.
    my $total_hits_found = 0; # counts hits, and is boolean for "any-hit-found".
    
    my $sub_string = undef;
    my $next_scaffold = undef;
    my $attributes = undef;
    $TidyXML->m_TRACE($self->{'_traceFlags'}) if $TidyXML;

    my (@ary,@dts); # 'F' and 'REGEX' are co-functional, so we need these shared variables here.

SCAFFOLD: for my $scaffold ( @$scaffold_array ) {
        my $tag = $$scaffold[0];
        
        # 'HIT*' is special since it has pre- and post- processing (adding the hits to the hit-list).
        # All other tokens simply process data as it moves along, then they're done,
        #  so they will do a set up, then pass along to recurse on scraper() . . .
        if ( ref($tag) ) {
            $hit->_hitfound(0) if defined $hit;
            ($next_scaffold, $sub_string, $attributes) = $tag->scrape($self, $scaffold, $TidyXML, $hit);
            
            #$hit->name(\$attributes->{'name'}); # for ScraperDiscovery
            #$hit->content(\$sub_string);        # for ScraperDiscovery
            #$hit->name(\$attributes->{'name'});
            #$hit->action(\$attributes->{'action'});
            #$hit->method(\$attributes->{'method'});
            #$hit->caption($caption) if $attributes->{'type'} =~ m{^radio|checkbox$}i;
            #$hit->name(\$attributes->{'name'});
            #$hit->type(\$attributes->{'type'});
            #$hit->value(\$attributes->{'value'});
            #$hit->background(\$attributes->{'background'});
            #$hit->bgcolor(\$attributes->{'bgcolor'});

            $total_hits_found = 1 if defined $hit && $hit->_hitfound;
            $sub_string = ${$TidyXML->asString()} if $next_scaffold && !defined($sub_string);
            next SCAFFOLD unless $sub_string;
        }
        elsif ( 'HIT' eq $tag ) {
            $self->{'total_hits_count'} = 1;
            my $resultType = $$scaffold[1];
            if ( 'ARRAY' eq ref $resultType ) {
                $next_scaffold = $resultType;
                $resultType =  $self->GetResponseClass();
            }
            $next_scaffold = $$scaffold[2];
            $next_scaffold = $$scaffold[1] unless defined $next_scaffold;
        }
        elsif ( 'HIT*' eq $tag )
        {
            my $resultType = $$scaffold[1];
            if ( 'ARRAY' eq ref $resultType ) {
                $next_scaffold = $resultType;
                $resultType =  $self->GetResponseClass();
            }
            else
            {
                $next_scaffold = $$scaffold[2];
            }
            $next_scaffold = $$scaffold[2];
            $next_scaffold = $$scaffold[1] unless defined $next_scaffold;
            my $hit;
            do 
            {
                $self->{'total_hits_count'} += 1;
                print "HIT number ".$self->{'total_hits_count'}."\n" if ($self->ScraperTrace('d'));
                if ( $hit && $self->postSelect($self->GetRequest(), $hit) )
                {
                    $self->_AddToHitList($hit); #push @{$self->{cache}}, $hit;
                    $total_hits_found += 1;
                }
                $hit = $self->newHit($resultType, $next_scaffold, $self->scraperDetail()?$self->scraperDetail()->[1]:undef);
            } while ( $self->scraperRecurse($TidyXML->asString(), $next_scaffold, $TidyXML, $hit, $debug) );
            next SCAFFOLD;
        }
    
        elsif ( 'BODY' eq $tag )
        {  
            $sub_string = undef;
            if ( $$scaffold[1] and $$scaffold[2] ) {
                ${$TidyXML->asString()} =~ s-$$scaffold[1](.*?)$$scaffold[2]--si; # Strip off the adminstrative clutter at the beginning and end.
                $sub_string = $1;
            } elsif ( $$scaffold[1] ) {
                ${$TidyXML->asString()} =~ s-$$scaffold[1](.*)$-$1-si; # Strip off the adminstrative clutter at the beginning.
                $sub_string = $1;
            } elsif ( $$scaffold[2] ) {
                ${$TidyXML->asString()} =~ s-^(.*?)$$scaffold[2]-$1-si; # Strip off the adminstrative clutter at the end.
                $sub_string = $1;
            } else {
                next SCAFFOLD;
            }
            if ( 'ARRAY' ne ref $$scaffold[3]  ) # if next_scaffold is an array ref, then we'll recurse (below)
            {
                next SCAFFOLD unless $sub_string;

                my $binding = $$scaffold[3];
                my $datParser = $$scaffold[4];
                $datParser = \&WWW::Scraper::trimTags unless $datParser;
                if ( $binding eq 'url' )
                {
                    my $url = new URI::URL(&$datParser($self, $hit, $sub_string), $self->{_base_url});
                    $url = $url->abs();
                    $hit->plug_url($url);
                } 
                elsif ( $binding) {
                    my $dat = &$datParser($self, $hit, $sub_string);
                    $hit->plug_elem($binding, $dat) if defined $dat;
                }
                $total_hits_found = 1;
                next SCAFFOLD;
            } else {
                $next_scaffold = $$scaffold[3];
            }
        }
    	
        elsif ( 'DATA' eq $tag )
        {
            $sub_string = '';
            if ( $$scaffold[1] and $$scaffold[2] ) {
                ${$TidyXML->asString()} =~ s-$$scaffold[1](.*?)$$scaffold[2]--si;
                $sub_string = $1;
            } else {
                next SCAFFOLD;
            }
            my $binding = $$scaffold[3];
            $hit->plug_elem($binding, $sub_string) if defined $sub_string;
            $total_hits_found = 1;
            next SCAFFOLD;
        }
    	
        elsif ( 'COUNT' eq $tag )
    	{
            #$self->approximate_result_count(0);
    	    if ( ${$TidyXML->asString()} =~ m/$$scaffold[1]/si )
    		{
    			print STDERR  "approximate_result_count: '$1'\n" if ($self->ScraperTrace('d'));
    			$self->approximate_result_count ($1);
    		}
            else {
                print STDERR "Can't find COUNT: '$$scaffold[1]'\n" if ($self->ScraperTrace('d'));
            }
            next SCAFFOLD;
    	}

        elsif ( 'HTML' eq $tag )
        {
            ${$TidyXML->asString()} =~ m-<HTML>(.*)</HTML>-si;
            $sub_string = $1;
            $next_scaffold = $$scaffold[1];
        }

    	elsif ( $tag =~ m/^(TABLEX|TRX|DL)$/ )
    	{
            my $tagLength = length ($tag) + 2;
            my $elmName = $$scaffold[1];
            $elmName = '#0' unless $elmName;
            if ( 'ARRAY' eq ref $$scaffold[1] )
            {
                $next_scaffold = $$scaffold[1];
            }
            elsif ( $elmName =~ /^#(\d*)$/ )
    		{
                for (1..$1)
    			{
                    $TidyXML->getMarkedText($tag); # and throw it away.
    			}
                $next_scaffold = $$scaffold[2];
            }
            else {
                print STDERR  "elmName: $elmName\n" if ($self->ScraperTrace('d'));
                $next_scaffold = $$scaffold[2];
                die "Element-name form of <$tag> is not implemented, yet.";
            }
            next SCAFFOLD unless $sub_string = $TidyXML->getMarkedText($tag);
        }
    	

    	elsif ( 'TAG' eq $tag )
        {
            next SCAFFOLD unless $sub_string = $TidyXML->getMarkedText($$scaffold[1]); # and throw it away.
            $next_scaffold = $$scaffold[2];
            if ( 'ARRAY' ne ref $next_scaffold  ) # if next_scaffold is an array ref, then we'll recurse (below)
            {
                my $binding = $next_scaffold;
                my $datParser = $$scaffold[3];
                print STDERR  "raw dat: '$sub_string'\n" if ($self->ScraperTrace('d'));
                if (  $self->ScraperTrace('d') ) {
                  print STDERR  "datParser: ".ref($datParser)."\n";
                };
                $datParser = \&WWW::Scraper::trimTags unless $datParser;
                print STDERR  "binding: '$binding', " if ($self->ScraperTrace('d'));
                print STDERR  "parsed dat: '".&$datParser($self, $hit, $sub_string)."'\n" if ($self->ScraperTrace('d'));
                if ( $binding eq 'url' )
                {
                   my $url = new URI::URL(&$datParser($self, $hit, $sub_string), $self->{_base_url});
                   $url = $url->abs();
                   $hit->plug_url($url);
                } 
                elsif ( $binding) {
                    my $dat = &$datParser($self, $hit, $sub_string);
                   $hit->plug_elem($binding, $dat) if defined $dat;
                }
                $total_hits_found = 1;
                next SCAFFOLD;
            }
        }
        elsif ( $tag =~ m/^(TDX|DT|DD|DIV|SPAN)$/ )
        {
            next SCAFFOLD unless $sub_string = $TidyXML->getMarkedText($tag); # and throw it away.
    		$next_scaffold = $$scaffold[1];
            if ( 'ARRAY' ne ref $next_scaffold  ) # if next_scaffold is an array ref, then we'll recurse (below)
            {
                my $binding = $next_scaffold;
                my $datParser = $$scaffold[2];
                print STDERR  "raw dat: '$sub_string'\n" if ($self->ScraperTrace('d'));
                if (  $self->ScraperTrace('d') ) { # print ref $ aways does something screwy
                  print STDERR  "datParser: ";
                  print STDERR  ref $datParser;
                  print STDERR  "\n";
                };
                $datParser = \&WWW::Scraper::trimTags unless $datParser;
                print STDERR  "binding: '$binding', " if ($self->ScraperTrace('d'));
                print STDERR  "parsed dat: '".&$datParser($self, $hit, $sub_string)."'\n" if ($self->ScraperTrace('d'));
                next SCAFFOLD unless $binding;
                if ( $binding eq 'url' )
                {
                    my $url = new URI::URL(&$datParser($self, $hit, $sub_string), $self->{_base_url});
                    $url = $url->abs();
                    $hit->plug_url($url);
                } 
                elsif ( $binding) {
                    my $dat = &$datParser($self, $hit, $sub_string);
                    $hit->plug_elem($binding, $dat) if defined $dat;
                }
                $total_hits_found = 1;
                next SCAFFOLD;
            }
        }
        elsif ( 'AX' eq $tag ) 
        {
            my $lbl = $$scaffold[1];
            my $anchor;
            next SCAFFOLD unless ($sub_string, $anchor) = $TidyXML->getMarkedText('A'); # and throw it away.
            next SCAFFOLD unless $anchor;
            if ( ( $anchor =~ s-A\s.*?HREF=(["'])([^"']+)\1--si) or
                 ( $anchor =~ s-A\s.*?HREF(=)([^> ]+)--si) 
               )
            {
                print "<A> binding: $$scaffold[2]: '$sub_string', $$scaffold[1]: '$2'\n" if ($self->ScraperTrace('d'));
                my $datParser = $$scaffold[3];
                $datParser = \&WWW::Scraper::trimTags unless $datParser;
                my $dat = &$datParser($self, $hit, $sub_string);
                $hit->plug_elem($$scaffold[2], $dat) if defined $dat;

               my ($url) = new URI::URL($2, $self->{_base_url});
               $url = $url->abs();
               if ( $lbl eq 'url' ) {
                   $url = WWW::Scraper::unescape_query($url) if $TidyXML->m_isTidyd();
                   $hit->plug_url($url);
               }
               else {
                   $hit->plug_elem($lbl, $url) if defined $url;
               }
               $total_hits_found = 1;
            }
            next SCAFFOLD;
        }
        elsif ( 'AN' eq $tag ) 
        {
            my $lbl = $$scaffold[1];
            if ( ${$TidyXML->asString()} =~ s-<A[^>]+?HREF=([^>]+)>(.*?)</A>--si )
            {
                print "<A> binding: $$scaffold[2]: '$2', $$scaffold[1]: '$1'\n" if ($self->ScraperTrace('d'));
                
                my $datParser = $$scaffold[3];
                $datParser = \&WWW::Scraper::trimTags unless $datParser;
                my $dat = &$datParser($self, $hit, $2);
                $hit->plug_elem($$scaffold[2], $dat) if defined $dat;

               my ($url) = new URI::URL($1, $self->{_base_url});
               $url = $url->abs();
               if ( $lbl eq 'url' ) {
                   $url = WWW::Scraper::unescape_query($url) if $TidyXML->m_isTidyd();
                   $hit->plug_url($url);
               }
               else {
                   $hit->plug_elem($lbl, $url) if defined $url;
               }
               $total_hits_found = 1;
            }
            next SCAFFOLD;
        }
        elsif ( 'AQ' eq $tag ) 
        {
            my $lbl = $$scaffold[2];
            my $anchor;
            next SCAFFOLD unless ($sub_string, $anchor) = $TidyXML->getMarkedText('A',$$scaffold[1]); # and throw it away.
            next SCAFFOLD unless $anchor;
            if ( ( $anchor =~ s-A\s.*?HREF=(["'])([^"']+)\1--si) or
                 ( $anchor =~ s-A\s.*?HREF(=)([^> ]+)--si) 
               )
            {
                print "<AQ> binding: $$scaffold[3]: '$sub_string', $$scaffold[2]: '$2'\n" if ($self->ScraperTrace('d'));
                my $datParser = $$scaffold[4];
                $datParser = \&WWW::Scraper::trimTags unless $datParser;
                my $dat = &$datParser($self, $hit, $sub_string);
                $hit->plug_elem($$scaffold[3], $dat) if defined $dat;

               my ($url) = new URI::URL($2, $self->{_base_url});
               $url = $url->abs();
               if ( $lbl eq 'url' ) {
                   $url = WWW::Scraper::unescape_query($url) if $TidyXML->m_isTidyd();
                   $hit->plug_url($url);
               }
               else {
                   $hit->plug_elem($lbl, $url) if defined $url;
               }
               $total_hits_found = 1;
            }
            next SCAFFOLD;
        } elsif ( $tag eq 'SNIP' ) { # another idea: 'CROP', the inverse of 'SNIP' - gdw.2003.01.16
            $sub_string = ${$TidyXML->asString()};
            my $matchString = $$scaffold[1];
            if ( 'ARRAY' eq ref $matchString ) {
                $next_scaffold = $matchString;
                $matchString = '';
            } else {
                $next_scaffold = $$scaffold[2];
            }
            $sub_string =~ s{$matchString}{}gsi;

        } elsif ( $tag eq 'RESIDUE' )
        {
            $sub_string = ${$TidyXML->asString()};
            my $binding = $$scaffold[1];
            my $datParser = $$scaffold[2];
            $datParser = \&WWW::Scraper::null unless $datParser;
            my $dat = &$datParser($self, $hit, $sub_string);
            $hit->plug_elem($binding, $dat) if defined $dat;
            next SCAFFOLD;

        } elsif ( $tag eq 'FOR' ) {
            my $iterator = $$scaffold[1];
            my $iterationString = $$scaffold[2];
            $next_scaffold = $$scaffold[3];
            my ($i,$j) = ($iterationString =~ m/^(\d+)\.\.(\d+)$/);
            for my $itr ($i..$j) {
                $self->_forInterator($itr);
                $total_hits_found += $self->scraperRecurse(\$sub_string, $next_scaffold, $TidyXML, $hit, $debug);
            }
        } elsif ( $tag eq 'XPath' )
        {
            my $xpath = $$scaffold[1];
            if ( $xpath =~ /for\((\w+)?\)/i ) {
                my $forN = $self->_forInterator();
                $xpath =~ s/for\((\w+)?\)/$forN/i;
            }
            if ( $xpath =~ /hit\((\d+)?\)/i ) {
                my $hitN = $self->{'total_hits_count'} + ($1||0);
                $xpath =~ s/hit\((\d+)?\)/$hitN/i;
            }
            my $binding = $$scaffold[2];
            $sub_string = ${$TidyXML->asString($xpath)};  # This also sets m_found_context, for recursing.
            next SCAFFOLD unless $sub_string;
            if ( 'ARRAY' eq ref $binding ) {
                $sub_string = undef; # We don't need sub_string for recursing.
                $next_scaffold = $binding;
            } elsif ( defined $$scaffold[2] ) {
                my $i = 3;
                while ( $$scaffold[$i] and 'ARRAY' ne ref $$scaffold[$i] ) {
                    my $datParser = $$scaffold[$i];
                    $i += 1;
                    $sub_string = &$datParser($self, $hit, $sub_string);
                }
                print "<XPath> binding: $binding: $sub_string\n" if ($self->ScraperTrace('d'));
                $hit->plug_elem($binding, $sub_string) if defined $sub_string;
                $total_hits_found = 1;
                next SCAFFOLD;
            } else {
                next SCAFFOLD;
            }

        } elsif ( $tag eq 'CLEANUP' )
        {
            my $i = 1;
            my $content = $TidyXML->asString();
            while ( $$scaffold[$i] and ('ARRAY' ne ref $$scaffold[$i]) ) {
                my $datParser = $$scaffold[$i];
                $i += 1;
                $content = &$datParser($self, $hit, $content);
            }
            $TidyXML->m_asString($content);
        }
        elsif ( $tag eq 'BOGUS' )
        {
            # Take back any hits at the header that are declared to be "bogus".
            my $bogusCount = $$scaffold[1];
            do { for ( 1..$bogusCount ) {
                last unless $total_hits_found > 0;
                $total_hits_found -= 1;
                shift @{$self->{cache}};
               }
            } if $bogusCount > 0;
            # Take back any hits at the footer that are declared to be "bogus".
            do { for ( 1..(-$bogusCount) ) {
                last unless $total_hits_found > 0;
                $total_hits_found -= 1;
                pop @{$self->{cache}};
               }
            } if $bogusCount < 0;
            next SCAFFOLD;
        }
        elsif ( $tag eq 'TRACE' )
        {
            my $x = ${$TidyXML->asString()};
            $x =~ s/\r//gs;
            print STDERR "TRACE:\n'$x'\n";
            $total_hits_found += $$scaffold[1];
        }
        elsif ( $tag eq 'CALLBACK' ) { # deprecated by WWW::Scraper::Opcodecode - gdw.2003.03.14
            ($sub_string, $next_scaffold) = &{$$scaffold[1]}($self, $hit, $TidyXML->asString(), $scaffold, \$total_hits_found);
        }
        else {
            die "Unrecognized ScraperFrame option: '$tag'";
        }

        next SCAFFOLD unless $next_scaffold;
        $total_hits_found += $self->scraperRecurse(\$sub_string, $next_scaffold, $TidyXML, $hit, $debug);
    }
    return $total_hits_found;
}


# private
sub newHit {
    my ($self, $resultType, $scraperFrame, $scraperDetailFrame) = @_;
    my $hit;
    if ( 'CODE' eq ref $resultType ) {
        $hit = &$resultType();
    } else {
        my $subResultType = undef; # Set up for Response::generic to build a properly named Response class.
        unless ( $resultType ) {
            $resultType = 'generic';
            ($subResultType) = (ref($self) =~ m{([^:]+)$});
        }
        eval "\$hit = new WWW::Scraper::Response::$resultType\::new(\$scraperFrame, \$scraperDetailFrame, \$subResultType);";
        if ( $@ ) {
            eval "use WWW::Scraper::Response::$resultType; \$hit = new WWW::Scraper::Response::$resultType(\$scraperFrame, \$scraperDetailFrame, \$subResultType);";
            if ( $@ ) {
                print "Can't require Response subclass '$resultType': $@\n";
                return undef;
            }
        }
    }
    unless ( $hit ) {
        die "Can't instantiate your Response module '$resultType': $@";
    }
    $hit->_ScraperEngine($self);
    $hit->_searchObject($self);
    
    return $hit;
}

# private
sub _AddToHitList {
    my ($self, $hit) = @_;
    
    if ( my $parentHit = $HitStack[0] ) {
        $parentHit->_AddToHitList($hit);
    } else {
        push @{$self->{'cache'}}, $hit;
    }
}
# private
sub _AddToHitStack {
}

sub touchUp {
    my ($self, $hit, $dat, $datParser) = @_;
}


# Returns the marked up text from the referenced string, as designated by the given tag.
# This algorithm extracts the contents of the first <$tag> element it encounters,
#   taking into consideration that it may contain <$tag> elements within it.
# It removes the marked text from the original string, strips off the markup tags,
#   and returns that result.
# (if wantarray, will return result and first tag, with brackets removed)
#
sub getMarkedText {
    my ($self, $tag, $content, $withContent) = @_;
    
    my $eidx = 0;
    my $sidx = -1;
    my $depth = 0;

#    while ( $$content =~ m-<(/)?$tag[^>]*?>-gsi ) {
    while ( $$content =~ m-<(/)?$tag(\s[^>]*?)?>-gsi ) {
        if ( $1 ) { # then we encountered an end-tag
            $depth -= 1;
            if ( $depth < 0 ) {
                # . . . then somehow we've stumbled into the midst of a table whose end-tag
                #   has just been encountered - let's be generous and start over.
                $eidx = 0;
                $sidx = -1;
                $depth = 0;
            }
            elsif ( $depth == 0 ) { # we've counted as many end-tags as start-tags; we're done!
                $eidx = pos $$content;
                if ( $withContent ) {
                    my $rslt = substr $$content, $sidx, $eidx - $sidx;
                    my (undef, undef, $txt) = ($rslt =~ m-^<($tag(\s[^>]*?)?)>(.*?)</$tag\s*[^>]*?>$-si);
                    unless ($txt =~ m{$withContent}si) {
                        $eidx = 0;
                        $sidx = -1;
                        $depth = 0;
                        next;
                    }
                }
                last;
            }
        } else # we encountered a start-tag
        {
            $depth += 1;
            $sidx = length $` unless $sidx >= 0; 
            if ( ($tag eq 'BR') && ($depth == 2) ) {
                $eidx = pos $$content;
                last;
            }
        }
    }
    

    return undef if $sidx < 0;
    my $rslt = substr $$content, $sidx, $eidx - $sidx, '';
    $$content =~ m/./;
#    $rslt =~ m-^<($tag[^>]*?)>(.*?)</$tag\s*[^>]*?>$-si;
    $rslt =~ m-^<($tag(\s[^>]*?)?)>(.*?)</?$tag\s*[^>]*?>$-si;
    return ($3, $1) if wantarray;
    return $3;
}


sub addURL {
   my ($self, $hit, $dat) = @_;
   
   if ( $dat =~ m-<A\s+HREF="([^"]+)"[^>]*>-si )
   {
      my ($url) = new URI::URL($1, $self->{_base_url});
      $url = $url->abs();
      $hit->plug_url($url);
   } else
   {
      $hit->plug_url("Can't find HREF in '$dat'");
   }

   return trimTags($self, $hit, $dat);
}

# trimTags($hit, $dat) - Strip tag clutter from $dat, in the context of $hit.
# trimTags($hit, $dat) - Strip double-LFs, then trim the tag clutter from $_;
# Note: "ref-not-ref" interface on $dat -
#   $dat may be a string, or a reference to a string.
#   if string, trimLFLFs() returns string, if ref, trimLFLFs() uses and returns ref.
sub trimTags {
    my ($self, $hit, $dat) = @_;
    return undef unless defined $dat;
    return $dat unless $dat;
    my $dt;
    my $isRef=0;
    if ( ref($dat) ) {
        $isRef = 1;
    } else {
        $dt = $dat;
        $dat = \$dt;
    }
    $$dat =~ s{<br>}{\n}gi;
    $$dat =~ s{\r}{}gsi;
    $$dat =~ s{</?[^>]+>}{}gsi;
    $$dat =~ s/&nbsp;/ /gs;
    $$dat =~ s{&lt;}{>}g;
    $$dat =~ s{&gt;}{>}g;
    $$dat =~ s{&quot;}{\042}gs;
    
    return $isRef?$dat:$$dat;
}

sub trimLFs { # Strip LFs, then tag clutter from $_;
    my ($self, $hit, $dat) = @_;
    $dat = $self->trimTags($hit, $dat);
    $dat =~ s/\s*\r?\n\s*//gs;
   # This simply rearranges the parameter list from the datParser form.
    return $dat;
}


# trimLFLFs($hit, $dat) - Strip double-LFs, then trim the tag clutter from $_;
# Note: "ref-not-ref" interface on $dat -
#   $dat may be a string, or a reference to a string.
#   if string, trimLFLFs() returns string, if ref, trimLFLFs() uses and returns ref.
sub trimLFLFs {
    my ($self, $hit, $dat) = @_;
    my $dt;
    my $isRef=0;
    if ( ref($dat) ) {
        $isRef = 1;
    } else {
        $dt = $dat;
        $dat = \$dt;
    }
    $dat = $self->trimTags($hit, $dat);
#    while ( 
        $$dat =~ s/[\s]*\n([\s]*\n[\s]*)*/\n/gsi;
#         ) {}; # Do several times, rather than /g, to handle triple, quadruple, quintuple, etc.
   # This simply rearranges the parameter list from the datParser form.
    return $isRef?$dat:$$dat;
}

# XML::XPath seems to keep a blank, the attribute name, and the '=' sign in the result.
#       Is this standard XPath conventions? useless to us, though.
sub trimXPathAttr {
    my ($self, $hit, $dat) = @_;
    $dat =~ s/^ \w+?=(['"])(.*)\1$/$2/;
    return $dat;
}
# This does trimXPathAttr, then converts the result to an absolute URL.
sub trimXPathHref {
    my ($self, $hit, $dat) = @_;
    $dat =~ m/^ \w+?=(['"])(.*)\1$/;
    my ($url) = new URI::URL($2, $self->{_base_url});
    $url = $url->abs();
    $url = WWW::Scraper::unescape_query($url);
    return $url;
}

sub trimComments { # Strip comments from $_.
    my ($self, $hit, $dat) = @_;
    $dat =~ s/<!--.*?-->//gs;
    return $dat;
}


sub removeScriptsInHTML {
    my ($self, $hit, $xml) = @_;
    
    # Strip out some regions that contain no information, but might be ill-formed output of "Tidy".
    my $removedScripts;
    for my $tag ( qw( script noscript ) ) {
        while ( $$xml =~ s-(<$tag.*?</$tag>)--si ) {
            $removedScripts .= $1;
        }
    }
    $self->{'removedScripts'} = \$removedScripts;
    
    return $xml;
}

# Remove everything between </HEAD> and <BODY> - this confuses TidyXML.
sub cleanupHeadBody {
    my ($self, $hit, $xml) = @_;
    $$xml =~ s-<html>(.*)<head>-<html><head>-gsi;
    $$xml =~ s-</head>(.*)<body>-</head><body>-gsi;
    $self->{'cleanedupHeadBody'} = \$1;
    return $xml;
}

# A null filter.
sub null { # Strip tag clutter from $_;
    my ($self, $hit, $dat) = @_;
    return $dat;
}

# Alternative name for the next_result() method for Scraper.
sub next_response {
    my $self = shift;
    if ( my $oSearch = $self->_wwwSearchBackend() ) {
   $self->SetRequest( new WWW::Scraper::Request($self, $self->{'native_query'}, $self->{'native_options'}) ) unless ( $self->GetRequest());
   ($oSearch->{'native_query'}, $oSearch->{'native_options'}) = ($self->GetRequest()->_native_query(), $self->{'native_options'});
       return $oSearch->next_result(@_);
    }
    $self->{'native_query'} = '' unless defined($self->{'native_query'}); # Prevent "search not yet specified" in WWW::Search::next_result().
    $self->next_result(@_);
}

# Alternative name for the results() method for Scraper.
sub responses {
    my $self = shift;
    $self->results(@_);
}

# Alternative name for the native_query() method for Scraper.
sub setup_query {
    my $self = shift;
    $self->native_query(@_);
}
sub native_query {
  my $self = shift;
  delete $self->{'_scraperRequest'};
  $self->{'native_query'} = '' unless defined($self->{'native_query'}); # Prevent "search not yet specified" in WWW::Search::next_result().
  $self->SUPER::native_query(@_);
}



# #######################################################################################
# Get the Next URL from a <form> on the page.
# Sometimes there's just a NEXT form, sometimes there's a PREV form and a NEXT form . . .
use HTML::Form;
sub findNextForm {
    my ($self, $hit, $dat) = @_;
    
    my $next_content = $dat;
    while ( my ($sub_content, $frm) = $self->getMarkedText('FORM', \$next_content) ) {
        last unless $sub_content;
#warn "\n\n\n\nFORM:\n$sub_content";
        # Reconstruct the form that contains the NEXT data.
        my @forms = HTML::Form->parse("<form $frm>$sub_content</form>", $self->{'_base_url'});
        my $form = $forms[0];

        my $submit_button;
        for ( $form->inputs() ) {
            if ( $_->value() =~ m/Next/ ) {
                $submit_button = $_;
                last;
            }
        }
        if ( $submit_button ) {
            my $req = $submit_button->click($form); #
            return $req->uri();
        }
    }
    return undef;
}

# #######################################################################################
# Get the Next URL from a <form> on the page.
# Sometimes there's just a NEXT form, sometimes there's a PREV form and a NEXT form . . .
sub findNextFormInXML {
    my ($self, $hit, $dat) = @_;
    
    my $next_content = $dat;
    while ( my ($sub_content, $frm) = $self->getMarkedText('FORM', \$next_content) ) {
        last unless $sub_content;
        # Reconstruct the form that contains the NEXT data.
        my $asHTML = "<form $frm>$sub_content</form>";
        $asHTML =~ s-/>->-gs;
        my @forms = HTML::Form->parse($asHTML, $self->{'_base_url'});
        my $form = $forms[0];

        my $submit_button;
        for ( $form->inputs() ) {
            if ( $_->value() =~ m/Next/ ) {
                $submit_button = $_;
                last;
            }
        }
        if ( $submit_button ) {
            my $req = $submit_button->click($form); #
            return $req->uri();
        }
    }
    return undef;
}

sub unescape_query {
    # code stolen, and enhanced, from URI::Escape.pm.
    my @copy = @_;
    for (@copy) {
	    s/\+/ /g;
        s/\&amp;/&/g;
    	s/%([\dA-Fa-f]{2})/chr(hex($1))/eg;
    }
    return wantarray ? @copy : $copy[0];
}

# ContentAnalysis()
# This method looks at general HTML content and pulls out as much relevant information as it can.
sub ContentAnalysis {
    my ($self) = @_;

    return \"" unless $self->response();
    my $dat = $self->response()->content;
    my $rDat = $self->trimLFLFs(undef, \$dat);
    return $rDat;
}

1;

__END__
=pod

=head1 NAME

WWW::Scraper - framework for scraping results from search engines.

B<NOTE: You can find a full description of the Scraper framework in F<WWW::Scraper::ScraperPOD.pm>.>

=head1 SYNOPSIS

    use WWW::Scraper;
    $scraper = new WWW::Scraper('engineName', $queryString);
    $scraper->GetRequest->$fieldName($fieldValue);    
    $response = $scraper->next_response();
    print $response->$fieldName();

=head1 DESCRIPTION

B<NOTE: You can find a full description of the Scraper framework in F<WWW::Scraper::ScraperPOD.pm>.>

"Scraper" is a framework for issuing queries to a search engine, and scraping the
data from the resultant multi-page responses, and the associated detail pages.

As a framework, it allows you to get these results using only slight knowledge
of HTML and Perl. (All you need to know you can learn by reading F<WWW::Scraper::ScraperPOD.pm>.)

A Perl script, "Scraper.pl", uses Scraper.pm to investigate the "advanced search page"
of a search engine, issue a user specified query, and parse the results. (Scraper.pm can
be used by itself to support more elaborate searching Perl scripts.) Scraper.pl and Scraper.pm
have enough intelligence to figure out how to interpret the search page and its results.

=head1 MAJOR FEATURES

B<NOTE: You can find a full description of the Scraper framework in F<WWW::Scraper::ScraperPOD.pm>.>

=over 4

=item Framing

A simple opcode based language makes describing the results and details pages of new engines easy,
and adapting to occasional changes in an existing engine's format simple.

=item Canonical Requests

A common Request container makes multiple search engine searches easy to implement, and 
automatically adapts to changes.

=item Canonical Response

A common Response container makes interpretation of results common among all search engines possible.
Also adapts easily to changes.

=item Post-filtering

Post-filtering provides a powerful client-based extension of the search capabilities to all search engines.

=back

=head1 AUTHOR

Glenn Wood, http://search.cpan.org/search?mode=author&query=GLENNWOOD.

=head1 COPYRIGHT

Copyright (C) 2001-2002 Glenn Wood. All rights reserved.
This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

