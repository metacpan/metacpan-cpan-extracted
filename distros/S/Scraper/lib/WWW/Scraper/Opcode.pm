package WWW::Scraper::Opcode;

use strict;
use vars qw($VERSION);
$VERSION = sprintf("%d.%02d", q$Revision: 1.1 $ =~ /(\d+)\.(\d+)/);

# Default new() simply assumes each parameter of the operation is a field name,
#  unless:
#  1. it is a reference,
#  2. it is a number, (??gdw.2003.03.14??) or 
#  3. it begins with '#'.

sub new { 
    my ($cls, $scaffold, $params) = @_;
    my $self = bless {},$cls;
    my @scfld = @$scaffold;
    shift @scfld;
    my @fields;
    map { push @fields, $_ unless ref($_) || m{^#} } @scfld;
    $self->{'fieldsCaptured'} = \@fields;

    return $self;
}

# Base scrape() method performs the following -
#   1. getMarkedTextAndAttributes(OpcodeName)
#   2. Walking along your Opcode scraper frame paramater . . .
#   3. Executes any function you list there.
#   4. Put attributes into same named fields in the list if they
#      appear in your 'CaptureAttributes' array.
#   5. Puts the (current) content of the element into any otherwise
#      named field (by current meaning after previous processing by
#      any functions you've put in the parameter list.)
#
sub scrape {
    my ($self, $scraper, $scaffold, $TidyXML, $hit) = @_;
    
    my $tag = ref($self); $tag =~ s{^.*::(\w[\w\d]*)$}{$1};
    
    my ($sub_string, $attributes) = $TidyXML->getMarkedTextAndAttributes($tag);
    return undef unless defined($sub_string);
    my @ary = @$scaffold;
    shift @ary;
    for ( @ary ) 
    {
        if ( ! defined $_ ) { # "if ( $_ eq '' )" reports "use of uninitialized variable" under diagnostics.
        }
        elsif ( ref($_) eq 'CODE' ) {
            $sub_string = &$_($scraper,$hit,$sub_string);
        }
        elsif ( $self->isCapturedField($_) ) {
            $self->plug_elem($_, $attributes->{$_}, $TidyXML);
        }
        elsif ( $_ eq 'url' )
        {
            my $url = new URI::URL($sub_string, $scraper->{_base_url});
            $url = $url->abs();
            $hit->plug_url($url);
        } 
        else {
            $hit->plug_elem($_, $sub_string, $TidyXML) if defined $sub_string;
        }
    }
    return ($self->_next_scaffold($scaffold), $sub_string, $attributes);
}

sub isCapturedField {
    my ($self, $parm) = @_;
    for ( @{$self->{'CaptureAttributes'}} ) {
        return 1 if ( uc $parm eq uc $_ );
    }
    return 0;
}

# Replace string Opcodes with their respective objects.
sub InitiateScaffold {
    my ($scaffold) = @_;
    my @fields = ();
    my $next_scaffold;
SCAFFOLD: for my $scaffold ( @$scaffold ) {
        
        my $tag = $$scaffold[0];
        if ( $tag =~ m/^(HIT|HIT\*|HTML|TidyXML|TRX|DL|FOR|DATA|DL|DT|DD|DIV|SPAN|RESIDUE|TAG|AN|AQ|F|SNIP|CALLBACK|XPath|COUNT|TRACE)$/ )
        {
            my @scfld = @$scaffold;
            $next_scaffold = $scfld[$#scfld] if ref($scfld[$#scfld]) eq 'ARRAY';
        } else
        {
            my @fieldsCaptured;
            my ($op,$params,$opmod);
            if ( ref($tag) ) {
                $op = $tag;
            }
            else {
                ($op,$params) = ($tag =~ m{^(\w+)(?:\((.*)\))?$});
                my @params = split /\s*,\s*/, $params if $params;
                eval "\$opmod = new WWW::Scraper::Opcode::$op(\$scaffold, \\\@params)";
                unless ( ref($opmod) ) {
                    eval "require WWW::Scraper::Opcode::$op; \$opmod = new WWW::Scraper::Opcode::$op(\$scaffold, \\\@params)";
                }
                die "WWW::Scraper::Response - - no $tag Scraper opcode class: $@" if $@ || !ref($opmod);
                $$scaffold[0] = $opmod;
            }
            push @fields, @{$opmod->{'fieldsCaptured'}} if $opmod->{'fieldsCaptured'};
            my @scfld = @$scaffold;
            $next_scaffold = $scfld[$#scfld] if ref($scfld[$#scfld]) eq 'ARRAY';
        }
        push @fields, InitiateScaffold($next_scaffold) if $next_scaffold;
    }
    return @fields;
}

# Calculate the next scaffold element of the give scaffold.
sub _next_scaffold {
    my $scaffold = $_[1];
    return $scaffold->[$#$scaffold] if ref($scaffold->[$#$scaffold]) eq 'ARRAY';
    return undef;
}
1;

__END__

=head1 NAME

WWW::Scraper::Opcodecode - Canonical form for Scraper requests

=head1 SYNOPSIS

    use WWW::Scraper::Opcodecode;
    #
    $request = new WWW::Scraper::Opcodecode( [$nativeQuery] [. {'fieldName' => $fieldValue, . . . }] );
    $request->$fieldName($fieldValue);
    .
    .
    .
    
    # or based on and attached to a particular Scraper engine.
    my $scraper = new WWW::Scraper('engineName');
    $request = new WWW::Scraper::Opcodecode( $scraper [, $nativeQuery]   [, {'fieldName' => $fieldValue, . . . }] );
    $request->$fieldName($fieldValue);
    .
    .
    .

=head1 DESCRIPTION

=over 4

=item See ScraperPOD for a description of how the Op class fits into Scraper.

=back

=head2 setQuery

Set the canonical "query" field value.
The Op class converts that to the appropriate native query string and field according to the associated Scraper engine.
You may also set the query string in the new() method.

Custom Op sub-classes may also define other canonical fields.
For instance, the Jobs Op sub-class defines canonical fields 'skills', ,'locations' and 'payrate'.
When you set these values, this Op sub-class translates each into the appropriate values and field names
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

The Scraper::Opcodecode object that is the actual response.
This is probably (or should be) an extension to a sub-class appropriate to your Scraper::Opcodecode sub-class.

=item $alreadyDone

The Scraper module will tell you which fields, by name, that it has already has (or will) handle on it's own.
This parameter may be a string holding a field name, or a reference to an array of field names.

C<Scraper::Opcodecode> contains a method for helping you vector on $alreadyDone. 
The method 

    $request->alreadyDone('fieldName', $alreadyDone)

will return true if the field 'fieldName' is in $alreadyDone.

=back

=head1 TRANSLATIONS

The Scraper modules that do table driven field translations (from canonical requests to native requests) will have
files included in their package representing the translation table in Storable format. The names of these files are
<ScraperModuleName>.<requestType>.<canonicalFieldName>. E.G., Brainpower.pm owns a translation table for the 'locations'
field of the canonical Op::Job module; it is named C<Brainpower.Job.locations> . 

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

C<WWW::Scraper::Opcodecode> is written and maintained
by Glenn Wood, http://search.cpan.org/search?mode=author&query=GLENNWOOD.


=head1 DESCRIPTION

Scraper automatically generates a "Op" class for each scraper engine.
It does this by parsing the "scraperFrame" to identify all the field names fetched by the scraper.
It defines a get/set method for each of these fields, each named the same as the field name found in the "scraperFrame".

Optionally, you may write your own Op class and declare that as the Op class for your queries.
This is useful for defining a common Op class to a set of scraper engines (all auction sites, for instance).
See WWW::Scraper::Opcodecode::Auction for an example of this type of Op class.

=head1 METHODS

=over 8

=item $fieldName

As mentioned, Op will automatically define get/set methods for each of the fields in the "scraperFrame".
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

A well-constructed Op class (as Scraper auto-generates) implements a lazy-access method for each
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

C<WWW::Scraper::Opcodecode::Scraper> is written and maintained
by Glenn Wood, http://search.cpan.org/search?mode=author&query=GLENNWOOD.

=head1 COPYRIGHT

Copyright (c) 2001 Glenn Wood
All rights reserved.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

