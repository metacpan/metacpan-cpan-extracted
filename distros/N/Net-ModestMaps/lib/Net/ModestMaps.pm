use strict;

# $Id: ModestMaps.pm,v 1.9 2008/07/24 06:05:16 asc Exp $

package Net::ModestMaps;
use base qw(LWP::UserAgent);

$Net::ModestMaps::VERSION = '1.1';

=head1 NAME

Net::ModestMaps - Simple OOP wrapper for calling ModestMaps web services.

=head1 SYNOPSIS

 my %args = (
 	'provider' => 'MICROSOFT_ROAD',
        'method' => 'center',
        'latitude' => '45.521375561025756',
        'longitude' => '-73.57049345970154',
        'zoom' => 15,
        'height' => 500,
        'width' => 500
 );

 my $mm = Net::ModestMaps->new();
 my $data = $mm->draw(\%args);

 if (my $err = $data->{'error'}){
 	die "$err->{'message'}";
 }

 my $img = $data->{'path'};

=head1 DESCRIPTION

Simple OOP wrapper for calling the I<ws-compose> and I<ws-pinwin> ModestMaps web
services.

=cut

use URI;
use HTTP::Request;
use FileHandle;
use File::Temp qw(tempfile);

=head1 PACKAGE METHODS

=cut

=head2 __PACKAGE__->new(%options)

Net::ModestMaps subclasses I<LWP::UserAgent> so all its constructor arguments
are valid. No other arguments are required.

Returns a I<Net::ModestMaps> object!

=cut

sub new {
        my $pkg = shift;

        my $self = $pkg->SUPER::new(@_);

        if (! $self){
                return undef;
        }

        $self->{'__host'} = 'http://127.0.0.1:9999';
        return bless $self, $pkg;
}

=head1 OBJECT METHODS

=cut

=head2 $obj->draw(\%args, $img='')

Valid args are any query parameters that you would pass to a ModestMaps web service
using the I<URI-E<gt>query_form> conventions (multiple parameters with same name passed
as an array reference, etc.)

I<$img> is the path where the map image returned by the ModestMaps web service should
be written to disk. If no argument is passed the map image will be return to a file
in your operating system's temporary directory.

The method always returns a hash reference, whether or not it succeeded.

If a failure condition was encountered the hash will contain a single key
labeled "error" which is a pointer to another hash containing (error) "code"
and "message" pairs.

On success, the hash will contain at least two keys : "path" indicating where the 
resultant map image was written and "url" indicating the actual URL used to retrieve
map image.

Additionally, any "X-wscompose-*" headers returned by the ModestMaps server are also
stored in the hash.

=cut

sub draw {
        my $self = shift;
        my $args = shift;
        my $out = shift;

        if (! defined($out)){
                my ($fh, $filename) = tempfile(UNLINK => 0, SUFFIX => ".png");
                $out = $filename;
        }

        my $host = $self->host();

        my $uri = URI->new('http:');
        $uri->query_form(%$args);
        my $content = $uri->query();

        # print STDERR $host . "\n";
        # print STDERR $content . "\n";

        my $req = HTTP::Request->new();
        $req->uri($host);
        $req->method('POST');
        $req->content($content);

        my $res = $self->request($req);
        my $status = $res->code();

        if ($status != 200){

                my $h = $res->headers();
                my $code = $h->header('x-errorcode');
                my $msg = $h->header('x-errormessage');

                $code ||= $res->code();
                $msg ||= $res->message();

                return {'error' => {'code' => $code, 'message' => $msg}};
        }

        my $fh = FileHandle->new();

        if (! $fh->open(">$out")){
                return {'error' => {'code' => 999, 'message' => "can not open '$out' for writing, $!"}};
        }

        binmode($fh);
        $fh->print($res->content());
        $fh->close();

        my %data = (
                    'url' => join("?", ($host, $content)),
                    'path' => $out,
                   );
        
        my $headers = $res->headers();

        foreach my $field ($headers->header_field_names()){

                if ($field =~/^X-wscompose-(.*)$/i){
                        $data{lc($1)} = $headers->header($field);
                }
        }

        return \%data;
}

=head2 $obj->host($url='')

Get and set the host where ModestMaps web service requests should be
sent.

The default values is I<http://127.0.0.1:9999>

=cut

sub host {
        my $self = shift;
        my $host = shift;

        if (defined($host)){
                $self->{'__host'} = $host;
        }

        return $self->{'__host'};
}

=head2 $obj->ensure_max_header_lines(\@items)

By default the I<Net::HTTP> package sets the maximum number of headers that
may be returned with a response to 128. If you are plotting lots of "markers"
(pinwins, dots, etc.) this number may be too low.

This method will check to see how many items you are plotting and update the
I<MaxHeaderLines> config, if necessary.
 
=cut

sub ensure_max_header_lines {
        my $self = shift;
        my $markers = shift;

	if (ref($markers) ne "ARRAY"){
		return;
	}

        my $cnt = scalar(@$markers);
        my $max = ($cnt > int(128 * .1)) ? $cnt * 1.2 : $cnt * 1.1;

        return $self->set_max_header_lines(int($max));
}

sub set_max_header_lines {
        my $self = shift;
        my $max = shift;

        if ($max > 128){
                @LWP::Protocol::http::EXTRA_SOCK_OPTS = ('MaxHeaderLines' => $max);
        }        
}

=head1 VERSION

1.1

=head1 DATE 

$Date: 2008/07/24 06:05:16 $

=head1 AUTHOR 

Aaron Straup Cope  E<lt>ascope@cpan.orgE<gt>

=head1 SEE ALSO

L<http://www.modestmaps.com>

L<http://modestmaps.com/examples-python-ws/>

L<http://www.aaronland.info/weblog/2008/02/05/fox/#ws-modestmaps>

=head1 BUGS

Sure, why not.

Please report all bugs via L<http://rt.cpan.org>

=head1 LICENSE

Copyright (c) 2008 Aaron Straup Cope. All Rights Reserved.

This is free software. You may redistribute it and/or
modify it under the same terms as Perl itself.

=cut

return 1;
