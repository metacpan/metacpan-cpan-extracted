#
#
# Creates a new interface class based on the following call -
#
#    package WWW::Scraper::Request::Job;
#    sub new {
#       shift;
#       my $self = WWW::Scraper::Request::new(
#                   'Job',
#                  ,{   
#                      'skills' => ''
#                     ,'locations' => ''
#                     ,'payrate' => ''
#                   }
#                  ,@_
#                  );
#       return $self;
#    }
#

package WWW::Scraper::Request;

use strict;
use vars qw($VERSION @ISA);
$VERSION = sprintf("%d.%02d", q$Revision: 1.4 $ =~ /(\d+)\.(\d+)/);

my %AlreadyDeclared;
my $VirtualCount;

sub fieldCapture {
    my ($scaffold) = @_;
    my @fields;
    my $next_scaffold;
    return @fields;
}


sub new { 
    my $class = shift;
    my $self;

    my ($options, $scraperFieldsFrame);
    my ($SubClass, $nativeQuery, $isCanonical, $SubClassNormal, $declaredMethodNames);
    
    # This gives us a subClass name via "Scraper::Request::new('subClassName')"; rather than "new Scraper::Request()", that is.
    if ( $class ne 'WWW::Scraper::Request' ) { 
        $SubClass = $class;
        $isCanonical = $SubClass;
        $SubClassNormal = "$SubClass\_";
        $SubClass .= '::_canonical_';
    }

    while ( my $whatzit = shift ) {
        if ( my $rf = ref $whatzit ) {
            if ( 'HASH' eq $rf ) {
               map { $options->{$_} = $whatzit->{$_} } keys %$whatzit;
            }
            elsif ( 'ARRAY' eq $rf ) {
                $declaredMethodNames = $whatzit unless $declaredMethodNames; # not sure why the "unless" is necessary . . .
            }
            elsif ( $rf =~ m/^WWW::Scraper::([^:]*)$/ ) {
                my $scraperRequest = $whatzit->scraperRequest();
                if ( !$whatzit->_wantsNativeRequest() and $scraperRequest->{'defaultRequestClass'} ) {
                    $SubClass = $scraperRequest->{'defaultRequestClass'};
                    $SubClassNormal = "$SubClass" unless $SubClassNormal;
                    eval "use WWW::Scraper::Request::$SubClass;\$self = new WWW::Scraper::Request::$SubClassNormal\(\@_);";
                    die $@ if $@;
                    $isCanonical = $SubClass;
                    $SubClassNormal = "$SubClass";
                    $SubClass .= '::_default_';
                } else {
                    $scraperFieldsFrame = $scraperRequest->{'nativeDefaults'};
                }
            }
        }

        elsif ( $whatzit eq 'ClassName' ) {
            $SubClass = shift;
            $isCanonical = $SubClass;
            $SubClassNormal = "$SubClass::__";
            $SubClass .= '::_ClassName_';
        }
        else {
            $nativeQuery = $whatzit;
        }
    }

    unless ( $SubClass ) {
        $VirtualCount += 1;
        $SubClassNormal = "virtual_$VirtualCount";
        $SubClass = "$SubClassNormal\:\:_struct_";
    }
    
    $SubClass = "::$SubClass";
    $AlreadyDeclared{"::$SubClass"} = [(keys %$options)+11, $options, $isCanonical] if $self;
    
    unless ( $scraperFieldsFrame ) {
        $scraperFieldsFrame = { '_native_query' => 1 };
        map { $scraperFieldsFrame->{$_} = 1 } keys %$options;
    }
    map { $scraperFieldsFrame->{$_} = 1 } @$declaredMethodNames;
    my (%subFields,$countSubFields);
    unless ( $AlreadyDeclared{$SubClass} ) {
#        $subFields{'url'} = 1 if $SubClass eq '::Sherlock'; # Help Sherlock along.
#        $subFields{'detail'} = 1 if $SubClass eq '::Sherlock'; # Help Sherlock along.
        
        # value of {'fieldName'} == 1 means field is from searchResultsFrame, only
        my %subFieldsMethod;
        for ( keys %$scraperFieldsFrame ) { 
            next if m/\.[xy]$/; # these "submit" style buttons can't be native methods (dot gets in the way) . . .
            $subFields{$_} = 1;  
            my $mthd = $_; 
            $mthd =~ s/\s/_/g; $subFieldsMethod{$mthd} = 1 
        };

        my @subFields = join '\'=>\'$\',\'', keys %subFields;
        my $subFieldsStruct = join '\'=>\'$\',\'', keys %subFieldsMethod;

        die "No fields were found in the scraperFrames for WWW::Scraper::Request$SubClass\n" unless keys %subFields;

        eval <<EOT;
{ package WWW::Scraper::Request$SubClass;
use Class::Struct;
    struct ( 'WWW::Scraper::Request$SubClass' => {
                 '_state'   => '\$'
                ,'_fields'  => '\$'
                ,'_engines' => '\%'
                ,'_native_query' => '\$'     # native_query for legacy (WWW::Search) style requests.
                ,'_native_options' => '\$'   # native_options for legacy (WWW::Search) style requests.
                ,'_isCanonical' => '\$'      # isCanonical? also holds sub-class name.
                ,'_scraperNativeQuery' => '\$' # Request.pm builds the native parameters here.
                ,'_postSelect' => '\%'
                ,'_searchObject'  => '\$'
                ,'_fieldCount'  => '\$'
                ,'_fieldNames'  => '\$'
                ,'_engines' => '\%'
                ,'_ScraperEngine'  => '\$'
                ,'_Scraper_debug'  => '\$'
# Now for the $SubClass specific members.
,'$subFieldsStruct'=>'\$'
                }
           );
}

package WWW::Scraper::Request::$SubClassNormal;
use WWW::Scraper::Request;
use vars qw(\@ISA);
\@ISA = qw( WWW::Scraper::Request$SubClass WWW::Scraper::Request );
        
1;
EOT
        die $@ if $@;
        delete $subFields{'_native_query'};
        $AlreadyDeclared{$SubClass} = [(keys %subFields)+11, \%subFields, $isCanonical];
    }
    
    eval "\$self = new WWW::Scraper::Request::$SubClassNormal" unless $self;
    die $@ if $@;
    
    $self->_fieldCount(${AlreadyDeclared{$SubClass}}[0]);
    $self->_fieldNames(${AlreadyDeclared{$SubClass}}[1]);
    $self->_isCanonical(${AlreadyDeclared{$SubClass}}[2]);

    $self->_init($nativeQuery,$options);
    return $self;
}
sub scraperFieldsFrame { undef }

# Return a table of names and origins for all data result columns.
sub GetFieldNames {
    $_[0]->_fieldNames();
}

# Return a table of names and titles for all data result columns.
sub GetFieldTitles {
    my ($self) = @_;
    my $answer = {'url' => 'URL'};
    for ( keys %$self ) {
        $answer->{$_} = $_ unless $_ =~ /^_/ or $_ =~ /^WWW::Search/;
    }
    return $answer;
}


sub GetFieldValues {
    my $self = shift;
    my $answer = { };
    for ( keys %{$self->GetFieldNames()} ) {
        my $mthd = $_;
        $mthd =~ s/\s/_/g;
        $answer->{$_} = $self->$mthd();
    }
    return $answer;
}



sub FieldTitles {
    return {  };
}

sub _init {
    my ($self, $native_query, $options_ref) = @_;
    
    $self->_native_query($native_query) if ( $native_query );
    map { my $mthd = $_; $mthd =~ s/\s/_/g;
          $self->$mthd($options_ref->{$_})
        } keys %$options_ref;

    $self->_native_query($native_query) unless ref($native_query) eq 'HASH';
    $self->_native_options($native_query) if ref($native_query) eq 'HASH';
    $self->_native_options($options_ref) if ref($options_ref) eq 'HASH';

    return $self;
}


# A generalize get/set method for "field" attributes.
sub field {
    my ($self, $field, $value) = @_;
    my $rtn = $self->_fields($field);
    $self->{'_fields'}->{$field} = $value if defined $value;
#print "$field:'$self->{'_fields'}->{$field}'\n" if defined $value;    
    return $rtn;
}
# Return the fields array (which is actually a hashref, v1.00).
sub fields { $_[0]->{'_fields'} }



### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### 
# Prepare the query and options of the Scraper module, based on the given request.
# Parse the SQL WHERE-ish clause in '_query' into '_fields' array.
#
# We don't do this process in v1.00; we rely on the user to have set the fields array.
sub prepare {
    my ($self, $scraper) = @_;

    # Move the field values from $self into $scraper, translating
    # field names to option names according to $scraper->fieldTranslations.
    # fieldTranlations{'*'} eq '*' - clone the name
    # fieldTranlations{'*'} ne '*' - drop that field.
    my $options_ref = $self->_native_options;
    $options_ref = {} unless ( $options_ref );
    $self->_scraperNativeQuery($options_ref);

    # This gets our defaults into these values, if the Scraper engine is not fully defined.
    my $scraperRequest = $scraper->scraperRequest();
    $scraper->queryDefaults($scraperRequest->{'nativeDefaults'}) unless $scraper->queryDefaults();
    $scraper->fieldTranslations($scraperRequest->{'fieldTranslations'}) unless $scraper->fieldTranslations();
    
    # Set nativeQuery field value first; it may be overwritten by FieldTranslations later, which is what we'd want.
    $options_ref->{$scraperRequest->{'nativeQuery'}} = $self->_native_query() if $scraperRequest->{'nativeQuery'};

    $scraper->cookie_jar(HTTP::Cookies->new()) if $scraperRequest->{'cookies'}; 

    my $fieldTranslationsTable = $scraper->fieldTranslations();
    my $fieldTranslations = $fieldTranslationsTable->{'*'}; # We'll do this until context sensitive work is done - gdw.2001.08.18
    my $fieldTranslation;

    if ( $self->_isCanonical ) {
        # Translate all the fields whose titles are listed by this Request object.
        for my $mthd ( keys %{$self->_fieldNames} ) {
            $mthd =~ s/\s/_/g;
            # Find what option we'll be translating to, or default (by cloning).
            $fieldTranslation = $$fieldTranslations{$mthd};
            next if defined $fieldTranslation and $fieldTranslation eq '';
            unless ( $fieldTranslation ) {
                if ($$fieldTranslations{'*'} eq '*' ) {
                    $fieldTranslation = $mthd;
                } else {
                    next;
                }
            }
            # 'fieldTranslation' may be a string naming the option, or 
            # a subroutine tranforming the field into a (nam,val) pair,
            # or a FieldTranslation object.
            if ( 'CODE' eq ref $fieldTranslation ) {
                my ($nam, $val, $postSelect) = &$fieldTranslation($scraper, $self, $self->$mthd());
                next unless ( $nam );
                $options_ref->{$nam} = $val;
                # Stuff the postSelect criteria for checking later.
                $self->_postSelect($nam, $postSelect) if defined $postSelect;
            } elsif ( ref $fieldTranslation ) { # We assume any other ref is an object of some sort.
                my $nam = $fieldTranslation->translate($scraper, $self, $self->$mthd());
                for ( keys %$nam ) {
                    $options_ref->{$_} = $$nam{$_};
                }
            }
            else {
                $options_ref->{$fieldTranslation} = $self->$mthd();
            }
        }
    }
    
#canon    $scraper->{'native_options'} = $options_ref;
}

### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### 
# Given a candidate hit, do post-selection.
# Return 1 to keep this hit, 0 to cast it away.
sub postSelect {
#    my ($rqst, $scraper, $rslt, $alreadyDone) = @_;
    # The Request module does a postSelect for Scraper modules too lazy to do their own.
    return 1;
}

# Return true if the string $which is in the string, or the array referenced by, $alreadyDone.
sub alreadyDone {
    my ($self, $which, $alreadyDone) = @_;
    return 0 unless $alreadyDone;
    my $alD = $alreadyDone;
    $alD = [$alreadyDone] unless 'ARRAY' eq ref $alD;
    for ( @$alD ) {
        return 1 if ( $_ eq $which );
    }
    return 0;
}

1;

__END__

=head1 NAME

WWW::Scraper::Request - Canonical form for Scraper requests

=head1 SYNOPSIS

    use WWW::Scraper::Request;
    #
    $request = new WWW::Scraper::Request( [$nativeQuery] [. {'fieldName' => $fieldValue, . . . }] );
    $request->$fieldName($fieldValue);
    .
    .
    .
    
    # or based on and attached to a particular Scraper engine.
    my $scraper = new WWW::Scraper('engineName');
    $request = new WWW::Scraper::Request( $scraper [, $nativeQuery]   [, {'fieldName' => $fieldValue, . . . }] );
    $request->$fieldName($fieldValue);
    .
    .
    .

=head1 DESCRIPTION

=over 4

=item See ScraperPOD for a description of how the Request class fits into Scraper.

=back

=head2 setQuery

Set the canonical "query" field value.
The Request class converts that to the appropriate native query string and field according to the associated Scraper engine.
You may also set the query string in the new() method.

Custom Request sub-classes may also define other canonical fields.
For instance, the Jobs Request sub-class defines canonical fields 'skills', ,'locations' and 'payrate'.
When you set these values, this Request sub-class translates each into the appropriate values and field names
for the whatever Scraper engine you are using.

=head1 Callback Functions

=head2 postSelect

C<postSelect()> is a callback function that may be called by the Scraper module to help it 
decide if the response it has received will actually qualify against this request. 
C<postSelect()> should return true if the response matches the request, false if not.

The parameters C<postSelect()> will receive are

=over 8

=item $request

A reference to itself, of course.

=item $scraper

A reference to the Scraper module under which all of this is happening.
You probably won't need this, but there it is.

=item $response

The Scraper::Request object that is the actual response.
This is probably (or should be) an extension to a sub-class appropriate to your Scraper::Request sub-class.

=item $alreadyDone

The Scraper module will tell you which fields, by name, that it has already has (or will) handle on it's own.
This parameter may be a string holding a field name, or a reference to an array of field names.

C<Scraper::Request> contains a method for helping you vector on $alreadyDone. 
The method 

    $request->alreadyDone('fieldName', $alreadyDone)

will return true if the field 'fieldName' is in $alreadyDone.

=back

=head1 TRANSLATIONS

The Scraper modules that do table driven field translations (from canonical requests to native requests) will have
files included in their package representing the translation table in Storable format. The names of these files are
<ScraperModuleName>.<requestType>.<canonicalFieldName>. E.G., Brainpower.pm owns a translation table for the 'locations'
field of the canonical Request::Job module; it is named C<Brainpower.Job.locations> . 

The Scraper module will locate the translation file, when required, by searching the @INC path-search until it is found
(the same path-search Perl uses to locate Perl modules.)

=head2 set<fieldName>Translation()

The methods set<fieldName>Translations() can be used to help maintain these translation files. 
For instance, setLocationsTranslation('canonical', 'native') will establish a translation from 'canonical' to 'native'
for the 'locations' request field.

    setLocationsTranslation('CA-San Jose', 5);       # CA-San Jose => '5'
    setLocationsTranslation('CA-San Jose', [5,6]);   # CA-San Jose => '5' + '6'
    
If you have used this method to upgrade your translations, 
then a new upgrade of F<WWW::Scraper> will probably over-write your tranlation file(s),
so watch out for that! Back up your translation files before upgrading F<WWW::Scraper>!

=head1 AUTHOR

C<WWW::Scraper::Request> is written and maintained
by Glenn Wood, http://search.cpan.org/search?mode=author&query=GLENNWOOD.


=head1 DESCRIPTION

Scraper automatically generates a "Request" class for each scraper engine.
It does this by parsing the "scraperFrame" to identify all the field names fetched by the scraper.
It defines a get/set method for each of these fields, each named the same as the field name found in the "scraperFrame".

Optionally, you may write your own Request class and declare that as the Request class for your queries.
This is useful for defining a common Request class to a set of scraper engines (all auction sites, for instance).
See WWW::Scraper::Request::Auction for an example of this type of Request class.

=head1 METHODS

=over 8

=item $fieldName

As mentioned, Request will automatically define get/set methods for each of the fields in the "scraperFrame".
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

A well-constructed Request class (as Scraper auto-generates) implements a lazy-access method for each
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

C<WWW::Scraper::Request::Scraper> is written and maintained
by Glenn Wood, http://search.cpan.org/search?mode=author&query=GLENNWOOD.

=head1 COPYRIGHT

Copyright (c) 2001 Glenn Wood
All rights reserved.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

