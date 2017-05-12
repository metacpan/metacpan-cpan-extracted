use strict;

package Net::Moo;
use base qw(LWP::UserAgent);

$Net::Moo::VERSION = '0.11';

=head1 NAME

Net::Moo - OOP wrapper for the Moo.com API

=head1 SYNOPSIS

 use Net::Moo;

 my $moo = Net::Moo->new();
 my $rsp = $moo->api_call('build', 'stickers', \@designs); 

 print $rsp->findvalue("start_url");

 # Or, if you're feeling verbose...

 use Net::Moo;
 use Net::Moo::Validate;

 my $xml = $moo->builder('stickers', \@designs);

 my $vld = Net::Moo::Validate->new();
 my $rpt = $vld->report_errors($xml)

 if ($vld->is_valid_xml($rpt)){
 	my $res = $moo->execute_request($xml);
 	my $rsp = $moo->parse_response($res);
 	print $rsp->findvalue("start_url");
 }

=head1 DESCRIPTION

Net::Moo is an OOP wrapper for the Moo.com API.

=head1 OPTIONS

Options are passed to Net::Moo using a Config::Simple object or
a valid Config::Simple config file. Options are grouped by "block".

=head2 moo

=over 4

=item * B<api_key>

String. I<required>

A valid Moo API key.

=item * B<validate>

Boolean.

Indicates whether product requests should be validated before they are
submitted to the Moo API for processing.

Default is false.

=back

=head1 LOGGING AND ERROR HANDLING

All errors are logged using the object's I<log> method which dispatches notices
to an internal I<Log::Dispatch> object. By default, only error messages are logged
to STDERR.

=head1 METHODS, PRODUCTS AND DESIGNS

This section describes the various arguments passed to the I<api_call> method as well
as the various other helper methods that it calls to generate requests to the Moo API.

=head2 Methods

=over 4

=item * B<choose>

For submitting a list of images that the user can then modify to make before placing
an order.

=item * B<build>

For submitting a list of images that will be used to make place and order.

=back

=head2 Products

Whatever the Moo API supports. As of this writing, this includes : 

=over 4

=item * B<minicard>

Small cards.

=item * B<notecard>

Square cards.

=item * B<sticker>

Sticky cards. Small ones.

=item * B<postcard>

Cards from the past, to the future.

=item * B<greetingcard>

OH HAI.

=head2 Designs 

Designs are the list of images and any formatting used when placing and order. Designs
are passed in as an array reference of hash references, with the following keys :

=over 4

=item * B<url>

The URL for the image. Really, the only thing you sort of have to include.

=item * B<type>

There's not much point in passing this at the moment as the API docs indicated
its value must always be B<variable> for now.

=item * B<crop>

Defines how an image will be cropped. Possible values are B<auto> and B<manual>.

Default is I<auto>.

=item * B<manual>

Required only if the I<crop> args is set to B<manual>, it is a hash ref containing 
the following keys :

=over 4 

=item * B<x>

The top left (x) co-ordinate of the cropping rectangle in pixels.

=item * B<y>

The top left (y) co-ordinate of the cropping rectangle in pixels.

=item * B<width>

The width of the cropping rectangle in pixels.

=item * B<height>

The height of the cropping rectangle in pixels.

=back 

=item * B<text>

The text for the back of a card. This is also an array reference of hash references,
each with the following keys :

=over 4 

=item * B<id>

The id of the text line that tells us where to place it on the back of the card. The IDs
allowed are defined in the schema document. Links to examples of where the ids go are below.

=item * B<string>

The text you want to add. As a general rule, if the id is a number, then the string can only
be on one line.

=item * B<bold>

This can either be (the string literals) 'true' or 'false'. If ommitted, the default is 'false'

=item * B<align>

This is either left, right or center. Some products only allow a subset of these (such as
greetingcard). The default value is left unless otherwise stated in the schema.

=item * B<font>

You can specify one of three fonts: modern (arial/helvetica), traditional (georgia) and
typewriter (courier). The default is modern.

=item * B<colour>

A hexidecimal string (with the #) for the colour of the line of text. The default is
#000000 (i.e. black).

=back

=item * B<text (for greeting cards)>

But wait! There's more!! When you are specifying text for greeting card products, it gets
a little more involved.

Rather than pass an array of hash references, you need to pass a hash of arrays of hash
references where the top level keys represent the page on which the text will be placed. (See
the examples section below.)

Valid keys are : 

=over 4 

=item * B<main>

Contains an array reference of hash references whose keys (described above) may be : 'string',
'align', 'font', 'colour'

=item * B<back>

Contains an array reference of hash references whose keys (described above) may be : 'id', 
'string', 'bold', 'align', 'font', 'colour'

=back

=back

=head2 Examples

More examples are available in the tests (./t) directory for this package but here's
an idea of how you specify a list of "designs" : 

 my @minicards = ({'url' => 'http://farm3.static.flickr.com/2300/2179038972_23d2a1ff40_o.jpg',
                  'text' => [{'id' => 1, 'string' => 'Bold / left / modern / red', 'bold' => 'true', 'align' => 'left', 'font' => 'modern', 'colour' => '#ff0000'},
                             {'id' => 2, 'string' => 'normal / center / traditional / green', 'bold' => 'false', 'align' => 'center', 'font' => 'traditional', 'colour' => '#00ff00'},
                             {'id' => 3, 'string' => 'bold / right / typewriter / blue', 'bold' => 'true', 'align' => 'right', 'font' => 'typewriter', 'colour' => '#0000ff'},
                             {'id' => 4, 'string' => 'normal / left / modern / yellow', 'bold' => 'false', 'align' => 'left', 'font' => 'modern', 'colour' => '#fff000'},
                             {'id' => 5, 'string' => 'bold / center / traditional / purple', 'bold' => 'true', 'align' => 'center', 'font' => 'traditional', 'colour' => '#ff00ff'},
                             {'id' => 6, 'string' => 'normal / right / typewriter / cyan', 'bold' => 'false', 'align' => 'right', 'font' => 'typewriter', 'colour' => '#00ffff'}],
 });

 my @greeting_cards = ({
         'url' => 'http://farm3.static.flickr.com/2300/2179038972_23d2a1ff40_o.jpg',
         'text' => {'main' => [{'string' => qq(Script to the right (red)), 'align' => 'right', 'font' => 'script', 'colour' => '#ff0000'}],
                    'back' => [{'id' => 1, 'string' => qq(Can has cheese burger?)}] },
 });

=cut

use HTTP::Request;
use IO::String;
use Config::Simple;
use XML::XPath;

use Log::Dispatch;
use Log::Dispatch::Screen;

use Net::Moo::Document;
use Net::Moo::Validate;

=head1 PACKAGE METHODS

=cut

=head2 __PACKAGE__->new($cfg)

Where B<$cfg> is either a valid I<Config::Simple> object or the path
to a file that can be parsed by I<Config::Simple>.

Returns a I<Net::Moo> object.

=cut

sub new {
        my $pkg = shift;
        my %opts = @_;

        # Otherwise, LWP::UserAgent complains of
        # unknown options...

        my $cfg = $opts{'config'};
        delete($opts{'config'});

        my $self = $pkg->SUPER::new(%opts);

        if (! $self){
                warn "Unable to instantiate parent class, $!";
                return undef;
        }

        #
        # Configs
        #

        $self->{'cfg'} = (UNIVERSAL::isa($cfg, "Config::Simple")) ? $cfg : Config::Simple->new($cfg);

        #
        # Logs
        #

        my $log_fmt = sub {
                my %args = @_;
                
                my $msg = $args{'message'};
                chomp $msg;
                
                if ($args{'level'} eq "error") {
                        
                        my ($ln, $sub) = (caller(4))[2,3];
                        $sub =~ s/.*:://;
                        
                        return sprintf("[%s][%s, ln%d] %s\n",
                                       $args{'level'}, $sub, $ln, $msg);
                }
                
                return sprintf("[%s] %s\n", $args{'level'}, $msg);
        };
        
        my $logger = Log::Dispatch->new(callbacks => $log_fmt);

        my $error  = Log::Dispatch::Screen->new(name => '__error',
                                                min_level => 'error',
                                                stderr => 1);
        
        $logger->add($error);
        $self->{'log'} = $logger;

        #
        # Happy happy!
        #

        bless $self, $pkg;
        return $self;
}

=head1 OBJECT METHODS YOU SHOULD CARE ABOUT

=cut

=head2 $obj->api_call($method, $product, \@designs)

Submit a set of designs to the Moo API for processing. 

Returns a I<XML::XPath::Node> object (referencing the Moo API response
<payload> element)  on success and undef if an error was encountered.

=cut

sub api_call {
        my $self = shift;
        my $method = shift;
        my $product = shift;
        my $designs = shift;

        my $xml = ($method eq 'choose') ? $self->chooser($product, $designs) : $self->builder($product, $designs);

        if ($self->{'cfg'}->param("moo.validate")){
                my $validator = Net::Moo::Validate->new();

                if (my $errors = $validator->report_errors($xml)){

                        foreach my $msg (@$errors){
                                $self->log()->error($msg);
                        }

                        return undef;
                }
        }

        my $res = $self->execute_request($xml);
        
        return $self->parse_response($res);
}

=head1 OBJECT METHODS YOU MAY CARE ABOUT

=cut

=head2 $obj->builder($product, \@designs)

Generate the required XML document for submitting a list of images that will be used
to make cards or stickers.

Returns a string.

=cut

sub builder {
        my $self = shift;
        my $product = shift;
        my $designs = shift;

        my $xml = '';
        my $fh = IO::String->new(\$xml);

        my $writer = Net::Moo::Document->new($fh);
        $writer->startDocument({'api_key' => $self->{'cfg'}->param("moo.api_key")});

        $writer->startTag("products");
        $writer->product($product, $designs);
        $writer->endTag("products");

        $writer->endDocument();

        $fh->close();
        return $xml;
}

=head2 $obj->chooser($product, \@urls)

Generate the required XML document for submitting a list of images (\@urls) that the
user can pick from and/or modify to make cards or stickers.

Returns a string.

=cut

sub chooser {
        my $self = shift;
        my $product = shift;
        my $urls = shift;

        my $xml = '';
        my $fh = IO::String->new(\$xml);

        my $writer = Net::Moo::Document->new($fh);
        $writer->startDocument({'api_key' => $self->{'cfg'}->param("moo.api_key")});

        $writer->startTag("chooser");

        $writer->startTag("product_type");
        $writer->characters($product);
        $writer->endTag("product_type");

        foreach my $url (@$urls){
                $self->image({'url' => $url});
        }

        $writer->endTag("chooser");
        $writer->endDocument();

        $fh->close();
        return $xml;
}

=head2 $obj->execute_request($xml)

Issue a request to the Moo API and get back a reponse (fancy talk for HTTP).

Returns a I<HTTP::Response> object.

=cut

sub execute_request {
        my $self = shift;
        my $xml = shift;

        my $req = HTTP::Request->new('POST' => 'http://www.moo.com/api/api.php');
        $req->content_type('application/x-www-form-urlencoded'); 
        $req->content("method=direct&xml=" . $xml);

        # print $req->as_string() . "\n";

        my $res = $self->send_request($req);
        return $res;
}

=head2 $obj->parse_response(HTTP::Response)

Parse a response from the Moo API and return the payload information.

Returns a I<XML::XPath::Node> object (referencing the Moo API response
<payload> element) on success and undef if an error was encountered.

=cut

sub parse_response {
        my $self = shift;
        my $res = shift;

        my $xml = undef;

        eval {
                $xml = XML::XPath->new('xml' => $res->content());
        };

        if ($@){
                $self->log()->error("Failed to parse response from the Moo API, $@");
                return undef;
        }

        if (my $err = $xml->findvalue("/moo/response/error")){
                $self->log()->error("Error reported by the Moo API : $err");
                return undef;
        }
        
        return ($xml->findnodes("/moo/payload"))[0];
}

=head2 $obj->config()

Returns a I<Config::Simple> object.

=cut

sub config {
        my $self = shift;
        return $self->{'cfg'};
}

=head2 $obj->log()

Returns a I<Log::Dispatch> object.

=cut

sub log {
        my $self = shift;
        return $self->{'log'};
}

=head1 VERSION

0.11

=head1 DATE

$Date: 2008/06/19 15:15:34 $

=head1 AUTHOR

Aaron Straup Cope E<lt>ascope@cpan.orgE<gt>

=head1 SEE ALSO

L<http://www.moo.com/api/documentation.php>

L<http://www.moo.com/xsd/api_0.7.xsd>

=head1 BUGS

Sure, why not.

Please report all bugs via http://rt.cpan.org/

=head1 LICENSE

Copyright (c) 2008 Aaron Straup Cope. All rights reserved.

This is free software. You may redistribute it and/or
modify it under the same terms as Perl itself.

=cut

return 1;
