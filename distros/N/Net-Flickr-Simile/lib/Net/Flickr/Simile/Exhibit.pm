# $Id: Exhibit.pm,v 1.7 2007/09/03 05:30:37 asc Exp $

use strict;

package Net::Flickr::Simile::Exhibit;
use base qw (Net::Flickr::Simile);

$Net::Flickr::Simile::Exhibit::VERSION = '0.1';

=head1 NAME

Net::Flickr::Simile::Exhbit - OOP for generating Simile Exhibit files using the Flickr API

=head1 SYNOPSIS

 use Getopt::Std;
 use Config::Simple;
 use Net::Flickr::Simile::Exhibit;

 my %opts = ();
 getopts('c:j:h:t:', \%opts);

 my $cfg = Config::Simple->new($opts{'c'});

 my %args = ('exhibit_json' => $opts{'j'},
             'exhibit_html' => $opts{'h'},
             'tags' => $opts{'t'});

 my $fl = Net::Flickr::Simile::Exhibit->new($cfg);
 $fl->search(\%args);
 
 # So then you might do :
 # perl ./myscript -c /my/flickr.cfg -h ./mystuff.html -j ./mystuff.js -t kittens

=head1 DESCRIPTION

OOP for generating Simile Exhibit files using the Flickr API.

=head1 OPTIONS

Options are passed to Net::Flickr::Backup using a Config::Simple object or
a valid Config::Simple config file. Options are grouped by "block".

=head2 flick

=over 4

=item * B<api_key>

String. I<required>

A valid Flickr API key.

=item * B<api_secret>

String. I<required>

A valid Flickr Auth API secret key.

=item * B<auth_token>

String. I<required>

A valid Flickr Auth API token.

=item * B<api_handler>

String. I<required>

The B<api_handler> defines which XML/XPath handler to use to process API responses.

=over 4 

=item * B<LibXML>

Use XML::LibXML.

=item * B<XPath>

Use XML::XPath.

=back

=back

=head2 reporting

=over 

=item * B<enabled>

Boolean.

Default is false.

=item * B<handler>

String.

The default handler is B<Screen>, as in C<Log::Dispatch::Screen>

=item * B<handler_args>

For example, the following :

 reporting_handler_args=name:foobar;min_level=info

Would be converted as :

 (name      => "foobar",
  min_level => "info");

The default B<name> argument is "__report". The default B<min_level> argument
is "info".

=back

=cut

use JSON::Any;
use IO::AtomicFile;
use File::Basename;

=head1 PACKAGE METHODS

=cut

=head2 __PACKAGE__->new($cfg)

Where B<$cfg> is either a valid I<Config::Simple> object or the path
to a file that can be parsed by I<Config::Simple>.

Returns a I<Net::Flickr::Simile::Exhbit> object.

=cut

=head1 OBJECT METHODS YOU SHOULD CARE ABOUT

Net::Flickr::Simile::Exhibit subclasses Net::Flickr::Simile and Net::Flickr::API so
all of those methods are available to your object. The following methods are also
defined.

=cut

=head2 $obj->getRecentPhotos(\%args)

Valid arguments are anything you would (need to) pass to the I<flickr.photos.search>
API method and :

=over 4

=item * B<exhibit_json>

String. I<required>

The path where Exhbit JSON data should be written to disk.

=item * B<exhibit_html>

String. I<required>

The path where Exhbit HTML data should be written to disk. It will contain
a relative pointer to I<exhibit_json>.

=back

The user_id bound to the Flickr Auth token defined in the object's config file
will automatically be added to the method arguments and used to scope the query.

Returns true or false.

=cut

sub getRecentPhotos {
        my $self = shift;
        my $args = shift;
        $args ||= {};

        my $nsid = $self->get_auth_nsid()
                || return 0;

        $args->{'user_id'} = $nsid;

        use Data::Dumper;
        print Dumper($args);

        return $self->search($args);
}

=head2 $obj->search(\%args)

Valid arguments are anything you would (need to) pass to the I<flickr.photos.search>
API method and :

=over 4

=item * B<exhibit_json>

String. I<required>

The path where Exhbit JSON data should be written to disk.

=item * B<exhibit_html>

String. I<required>

The path where Exhbit HTML data should be written to disk. It will contain
a relative pointer to I<exhibit_json>.

=back

Returns true or false.

=cut

sub search {
        my $self = shift;
        my $args = shift;
        $args ||= {};

        my $paths = $self->_output_paths($args)
                || return 0;

        my $rsp = $self->api_call({'method' => 'flickr.photos.search',
                                 'args' => $args});

        return $self->writeExhibitFiles($paths, $rsp);
}

=head2 $obj->getContactsPhotos(\%args)

Valid arguments are anything you would (need to) pass to the I<flickr.photos.getContactsPhotos>
API method and :

=over 4

=item * B<exhibit_json>

String. I<required>

The path where Exhbit JSON data should be written to disk.

=item * B<exhibit_html>

String. I<required>

The path where Exhbit HTML data should be written to disk. It will contain
a relative pointer to I<exhibit_json>.

=back

Returns true or false.

=cut

sub getContactsPhotos {
        my $self = shift;
        my $args = shift;
        $args ||= {};

        my $paths = $self->_output_paths($args)
                || return 0;

        my $rsp = $self->api_call({'method' => 'flickr.photos.getContactsPhotos',
                                 'args' => $args});

        return $self->writeExhibitFiles($paths, $rsp);
}

=head2 $obj->getContactsPublicPhotos(\%args)

Valid arguments are anything you would (need to) pass to the I<flickr.photos.getContactsPublicPhotos>
API method and :

=over 4

=item * B<exhibit_json>

String. I<required>

The path where Exhbit JSON data should be written to disk.

=item * B<exhibit_html>

String. I<required>

The path where Exhbit HTML data should be written to disk. It will contain
a relative pointer to I<exhibit_json>.

=back

Returns true or false.

=cut

sub getContactsPublicPhotos {
        my $self = shift;
        my $args = shift;
        $args ||= {};

        my $paths = $self->_output_paths($args)
                || return 0;

        my $rsp = $self->api_call({'method' => 'flickr.photos.getContactsPublicPhotos',
                                 'args' => $args});

        return $self->writeExhibitFiles($paths, $rsp);
}

=head1 OBJECT METHODS YOU MAY CARE ABOUT

=cut

=head2 $obj->rspToExhibitJson($rsp)

Where I<$rsp> is the return value of a call to I<Net::Flickr::API->api_call>.

Returns a JSON string representing the data in I<$rsp> suitable for including with
a Simile Exhibit document.

=cut

sub rspToExhibitJson {
        my $self = shift;
        my $rsp = shift;

        my %data = (
                    'items' => [],
                   );

        foreach my $ph ($rsp->findnodes("/rsp/photos/photo")){


                my $res = $self->api_call({'method' => 'flickr.photos.getInfo',
                                           'args' => {'photo_id' => $ph->getAttribute('id')}});

                if (! $res) {
                        next;
                }

                my $thumb = sprintf("http://farm%s.static.flickr.com/%s/%s_%s_t.jpg",
                                    $ph->getAttribute("farm"), $ph->getAttribute("server"),
                                    $ph->getAttribute("id"), $ph->getAttribute("secret"));

                my $taken = $res->findvalue("/rsp/photo/dates/\@taken");
                $taken =~ s/\:\s{2}\:\d{2}//;

                my %info = (
                            'imageURL' => $thumb,
                            'label' => $res->findvalue("/rsp/photo/title"),
                            'description' => $res->findvalue("/rsp/photo/description"),
                            'date' => $taken,
                            'owner' => $res->findvalue("/rsp/photo/owner/\@username"),
                            'photoURL' => $res->findvalue("/rsp/photo/urls/url[\@type='photopage']"),
                           );

                foreach my $t ($res->findnodes("/rsp/photo/tags/tag")){
                        $info{'tags'} ||= [];

                        my $raw = $t->getAttribute("raw");

                        if ($t->getAttribute("machine_tag")){

                                $info{'namespaces'} ||= [];
                                $info{'predicates'} ||= [];
                                $info{'values'} ||= [];

                                if ($raw =~ /^([a-z](?:[a-z0-9_]+))\:([a-z](?:[a-z0-9_]+))=(.*)/){
                                
                                        my $ns = $1;
                                        my $pred = $2;
                                        my $value = $3;

                                        push @{$info{'namespaces'}}, $ns;
                                        push @{$info{'predicates'}}, $pred;
                                        push @{$info{'values'}}, $value;
                                        push @{$info{'tags'}}, $value;
                                }                                
                        }
                        
                        else {
                                push @{$info{'tags'}}, $raw;
                        }
                }

                if (my $geo = ($res->findnodes("/rsp/photo/location"))[0]){

                        foreach my $pl ("locality", "region", "country"){
                                $info{'places'} ||= [];

                                if (my $label = $geo->findvalue($pl)){
                                        push @{$info{'places'}}, $label;
                                }
                        }

                        my %coords = ('id' => $info{'label'});
                        $coords{'addressLatLng'} = join(",", $geo->getAttribute("latitude"), $geo->getAttribute("longitude"));
                        push @{$data{'items'}}, \%coords;                        
                }

                # use Data::Dumper;
                # print STDERR Dumper(\%info);

                push @{$data{'items'}}, \%info;
        }

        my $json = JSON::Any->new();
        return $json->objToJson(\%data);
}

=head2 $obj->writeExhbitFiles(\%paths, $rsp)

Returns true or false.

=cut

sub writeExhibitFiles {
        my $self = shift;
        my $paths = shift;
        my $rsp = shift;

        if (! $rsp){
                $self->log()->error("Not a valid response; can not write Exhibit files");
                return 0;
        }

        my $src_json = basename($paths->{'exhibit_json'});

        if (! $self->writeExhibitJson($paths->{'exhibit_json'}, $rsp)){
                return 0;
        }

        if (! $self->writeExhibitHtml($paths->{'exhibit_html'}, $src_json)){
                return 0;
        }

        return 1;
}

=head2 $obj->writeExhibitJson($path, $rsp)

Returns true or false

=cut

sub writeExhibitJson {
        my $self = shift;
        my $path = shift;
        my $rsp = shift;

        my $fh_json = IO::AtomicFile->open($path, "w");

        if (! $fh_json){
                $self->log()->error("Failed to open '$path' for writing, $!");
                return 0;
        }

        $fh_json->print($self->rspToExhibitJson($rsp));
        $fh_json->close();

        return 1;
}

=head2 $obj->writeExhibitHtml($path, $rsp)

Returns true or false

=cut

sub writeExhibitHtml {
        my $self = shift;
        my $path = shift;
        my $src = shift;

        my $html = $self->readExhibitHtml();
        $html =~ s/USER_JSON_DATA/$src/m;

        my $fh_html = IO::AtomicFile->open($path, "w");

        if (! $fh_html){
                $self->log()->error("Failed to open '$path' for writing, $!");
                return 0;
        }

        $fh_html->print($html);
        $fh_html->close();
        return 1;
}

sub readExhibitHtml {
        my $self = shift;

        my $html = undef;

        {
                local $/;
                undef $/;
                $html = <DATA>;
        }

        return $html;
}

sub _output_paths {
        my $self = shift;
        my $args = shift;

        my %paths = ();

        foreach my $which ("exhibit_json", "exhibit_html"){
                
                if (! exists($args->{$which})){
                        return undef;
                }

                $paths{$which} = $args->{$which};
                delete($args->{$which});
        }

        return \%paths;
}


=head1 VERSION

0.1

=head1 AUTHOR

Aaron Straup Cope &lt;ascope@cpan.org&gt;

=head1 NOTES

=over 4

=item * B<helper methods>

Basically anything that returns a "standard photo response" (or /rsp/photos/photo)
from the Flickr API can be used with this package to generate Exhibit data.

As this time, however, only a handful of (API) methods have (Perl) helper methods.
There will be others.

=item * B<pagination>

This package does not know how to account for pagination in the Flickr API.
That may change over time.

=item * B<HTML files>

This package contains a bare-bones template for generating an HTML file to
view your Exhibit data. 

You may need to tweak the output after the fact or you can subclass the
I<readExhibitHtml> method.

=back

=head1 EXAMPLES

L<http://aaronland.info/perl/net/flickr/simile/exhibit.html>

L<http://aaronland.info/perl/net/flickr/simile/exhibit.js>

=head1 SEE ALSO

L<Net::Flickr::API>

L<http://simile.mit.edu/exhibit/>

=head1 BUGS

Please report all bugs via http://rt.cpan.org/

=head1 LICENSE

Copyright (c) 2007 Aaron Straup Cope. All Rights Reserved.

This is free software. You may redistribute it and/or
modify it under the same terms as Perl itself.

=cut

return 1;

__DATA__
<html>
<head>
   <title>Test</title>
 
   <link href="USER_JSON_DATA" type="application/json" rel="exhibit/data" />
 
   <script src="http://static.simile.mit.edu/exhibit/api-2.0/exhibit-api.js"
           type="text/javascript"></script>
           
   <script src="http://static.simile.mit.edu/exhibit/extensions-2.0/time/time-extension.js"
           type="text/javascript"></script>

   <script src="http://static.simile.mit.edu/exhibit/extensions-2.0/map/map-extension.js?gmapkey="><script>
           
   <style>
       body {
           margin: 1in;
       }
       table.photo {
           border:     1px solid #ddd;
           padding:    0.5em;
       }
       div.title {
           font-weight: bold;
           font-size:   120%;
       }
       .tags {
       font-size:small;
       }
       .description {
       }
       .date {
           font-style:  italic;
       }
       .owner {
           color:  #888;
       }
       .co-winners {
       }
   </style>
</head> 
<body>
   <table width="100%">
       <tr valign="top">
           <td ex:role="viewPanel">
               <table ex:role="lens" class="photo">
                   <tr>
                       <td><a ex:href-content=".photoURL"><img ex:src-content=".imageURL" /></a></td>
                       <td>
                           <div ex:content=".label" class="title"></div>
                           <div ex:content=".tags" class="tags"></div>
                           <div ex:content=".owner" class="owner"></div>
                           <br clear="all" />
                       </td>
                   </tr>
               </table>

               <div ex:role="view"
                   ex:viewClass="Timeline"
                   ex:start=".date"
                   ex:content=".tags"
                   ex:colorKey=".owner">
               </div>

               <div ex:role="view"
                    ex:viewClass="Thumbnail"
                    ex:orders=""
                    ex:possibleOrders="">
               </div>

               <div ex:role="view"
                    ex:viewClass="Map"
                    ex:latlng=".addressLatLng"
                    ex:colorKey=".owner">
               </div>

           </td>
           <td width="25%">
               <div ex:role="facet" ex:facetClass="TextSearch"></div>
               <div ex:role="facet" ex:expression=".tags" ex:facetLabel="Tags"></div>
               <div ex:role="facet" ex:expression=".places" ex:facetLabel="Places"></div>
               <div ex:role="facet" ex:expression=".owner" ex:facetLabel="Owners"></div>
               <div ex:role="facet" ex:expression=".namespaces" ex:facetLabel="Machine Tag Namespaces"></div>
               <div ex:role="facet" ex:expression=".predicates" ex:facetLabel="Machine Tag Predicates"></div>
               <div ex:role="facet" ex:expression=".values" ex:facetLabel="Machine Tag Values"></div>
           </td>
       </tr>
   </table>
</body>
</html>
