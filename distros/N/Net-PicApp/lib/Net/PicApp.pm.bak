package Net::PicApp;

# use 'our' on v5.6.0
use vars qw($VERSION @EXPORT_OK %EXPORT_TAGS $DEBUG);
use XML::Simple;
use LWP::UserAgent;
use Net::PicApp::Response;
use URI::Escape;

$DEBUG = 0;
$VERSION = '0.1';

use base qw(Class::Accessor);
Net::PicApp->mk_accessors(qw(apikey url));

# We are exporting functions
use base qw/Exporter/;

use constant {
    CONTRIB_CORBIS => 466,
    CONTRIB_ENTERTAINMENT_PRESS => 16797,
    CONTRIB_GETTY => 3,
    CONTRIB_IMAGE_SOURCE => 4,
    CONTRIB_JUPITER => 5,
    CONTRIB_NEWSCOM => 7387,
    CONTRIB_PACIFIC_COAST => 12342,
    CONTRIB_SPLASH => 4572,
    CAT_EDITORIAL => 2,
    CAT_CREATIVE => 3,
    CAT_ENTERTAINMENT => 4,
    CAT_NEWS => 5,
    CAT_SPORTS => 6,
    SORT_RELEVANT => 1,
    SORT_RECENT => 2,
    SORT_RANDOM => 6
};

# Methods to support:
# * getimagedetails
# * login

# Export list - to allow fine tuning of export table
@EXPORT_OK = qw( search get_image_details login );

use strict;

sub DESTROY { }

$SIG{INT} = sub { die "Interrupted\n"; };

$| = 1;  # autoflush

sub new {
    my $class = shift;
    my $params = shift;
    my $self = {};
    foreach my $prop ( qw/ apikey / ) {
        if ( exists $params->{ $prop } ) {
            $self->{ $prop } = $params->{ $prop };
        }
#        else {
#            confess "You need to provide the $prop parameter!";
#        }
    }
    my $ua = LWP::UserAgent->new;
    $ua->agent("Net::PicApp/$VERSION");
    $self->{ua} = $ua;
    $self->{url} = 'http://api.picapp.com/API/ws.asmx' unless $self->{url};
    bless $self, $class;
    return $self;
}

sub search {
    my $self = shift;
    my ($term, $options) = @_;
    my $method;
    if ($options->{'with_thumbnails'}) {
        if ($options->{'subcategory'} || $options->{'contributor'}) {
            $method = 'SearchImagesWithThumbnailsContributorAndSubCategory';
        } else {
            $method = 'SearchImagesWithThumbnails';
        }
    } else {
        if ($options->{'subcategory'} || $options->{'contributor'}) {
            $method = 'SearchWithContributorAndSubCategory';
        } else {
            $method = 'Search';
        }
    }
    my $url = $self->url . "/".$method."?ApiKey=" . $self->apikey;
    $url .= '&term=' . uri_escape($term);
    my $keys = {
        'categories' => 'cats',
        'colors' => 'clrs',
        'orientation' => 'oris',
        'types' => 'types',
        'match_phrase' => 'mp',
        'post' => 'post',
        'sort' => 'sort',
        'page' => 'Page',
        'total_records' => 'totalRecords',
    };
    foreach my $key (keys %$keys) {
        $url .= '&'.$keys->{$key}.'=' . ($options->{$key} ? $options->{$key} : '');
    }
    if ($method =~ /(contributor|category)/i) {
        $keys = {
            'contributor' => 'contributorId',
            'subcategory' => 'subCategory'
        };
        foreach my $key (keys %$keys) {
            $url .= '&'.$keys->{$key}.'=' . ($options->{$key} ? $options->{$key} : '');
        }
    }

    require Net::PicApp::Response;
    my $response = Net::PicApp::Response->new;
    $response->url_queried($url);

    # Call PicApp
    my $req = HTTP::Request->new(GET => $url);
    my $res = $self->{ua}->request($req);

    # Check the outcome of the response
    if ($res->is_success) {
        my $content = $res->content;
        # Hack to clean results
#        $content =~ s/<!\[CDATA\[missing thumbnails\]\]>//gm;
        my $xml = eval { XMLin($content) };
        if ($@) {
            print STDERR "ERROR: $@\n";
            $response->error_message("Could not parse response: $@");
        } else {
            print STDERR "Success!\n";
            $response->init($xml);
        }
    }
    else {
        $response->error_message("Could not conduct query to: $url");
    }
    return $response;
}

1;
__END__

=head1 NAME

Net::PicApp - A toolkit for interacting with the PicApp service.

=head1 SYNOPSIS

   my $picapp = Net::PicApp->new({
    apikey => '4d8c591b-e2fc-42d2-c7d1-xxxabc00d000'
   });
   my $response = $picapp->search('cats');
   if ($response->is_success) {
     foreach my $img (@{$response->images}) {
       print $img->imageTitle . "\n";
     }
   } else {
     die $picapp->error_message;
   }
   
=head1 DESCRIPTION

This module provides a convenient interface to the PicApp web service.
It requires that you have been given an API Key by PicApp.

=head1 PREREQUISITES

=over

=item PicApp API Key

=item L<XML::Simple>

=item L<LWP>

=back

=head1 USAGE

=head2 METHODS

=over 4

=item B<search($terms, %options)>

This function receives a term for searching and retrieves the results in XML.
This function allows the user to send search parameters in addition to the 
search term, corresponding to advanced search options in the www.picapp.com 
website.

B<Search Options:>

=over 4

=item C<with_thumbnails> - boolean

=item C<categories> - "Editorial" or "Creative" (default: all)

=item C<subcategory> - A sub-category by which to filter. See Constants.

=item C<colors> - "BW" or "Color" (default both)

=item C<orientation> - "Horizontal" or "Vertical" or "Panoramic" (default: all)

=item C<types> - "Photography" or "Illustration" (default: all)

=item C<match_phrase> - "AllTheseWords" or "ExactPhrase" or "AnyTheseWords" or "FreeText"

=item C<time_period> - "Today" or "Yesterday" or "Last3Days" or "LastWeek" or "LastMonth" or "Last3Months" or "Anytime"

=item C<sort> - How to sort the results (by relevancy, by recency, or randomly). See Constants.

=item C<page> - This parameter depicts the page number (1 and above) to be retrieved from the system.

=item C<total_records> - This parameter indicates the maximal number of results requested from Picapp (1 and above).

=back

B<Usage Notes:>

If C<with_thumbnails> has been specified and is true, then this function will 
retrieve the search results upon user definitions with extra rectangular 
cropped thumbnails on top of the regular thumbnail. These thumbnails will be 
available in the response object.

If C<subcategory> OR C<contributor> has been specified then this function will 
also filter the search results by image contributor (Getty, Corbis, Splash,
 etc..) and by image category (news, creative, sports, etc..)

=item B<get_image_details($id)>

This function receives the unique key and the image ID (the image ID received 
from the search XML results). 

=item B<does_user_exist($username, $password)>

This function receives a login name a password and retrieves an xml with the 
user details.

=item B<publish_image_with_search_term(TODO)>

This function receives an email, image ID and a key and the function retrieves 
the script in XML. Also the SearchTerm parameter should be the keyword used to 
find the image which is published.

TODO: options

=back

=head2 CONSTANTS

The following constants have been defined to assist in specifying the 
appropriate values to a search request:

=head3 Contributors

=over 4

=item CONTRIB_CORBIS

=item CONTRIB_ENTERTAINMENT_PRESS

=item CONTRIB_GETTY

=item CONTRIB_IMAGE_SOURCE

=item CONTRIB_JUPITER

=item CONTRIB_NEWSCOM

=item CONTRIB_PACIFIC_COAST

=item CONTRIB_SPLASH

=back

=head3 Sub-Categories

=over 4

=item CAT_EDITORIAL

=item CAT_CREATIVE

=item CAT_ENTERTAINMENT

=item CAT_NEWS

=item CAT_SPORTS

=back

=head3 Sort Values

=over 4

=item SORT_RELEVANT

=item SORT_RECENT

=item SORT_RANDOM

=back

=head2 INITIALIZATION OPTIONS

Each of the following options are also accessors on the main
Net::PicApp object.

=over

=item B<apikey>

The API Key given to you by PicApp for accessing the service.

=item B<url>

The base URL of the PicApp service. Defaults to: 'http://api.picapp.com/API/ws.asmx'

=back

=head1 SEE ALSO

=head1 VERSION CONTROL

L<http://github.com/byrnereese/perl-Net-PicApp>

=head1 AUTHORS and CREDITS

Author: Byrne Reese <byrne@majordojo.com>

=cut
