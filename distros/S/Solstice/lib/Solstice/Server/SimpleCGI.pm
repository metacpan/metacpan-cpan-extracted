package Solstice::Server::SimpleCGI;

use strict;
use warnings;
use 5.006_000;

use base qw(Solstice::Server Solstice::Service);

use Solstice::ContentTypeService;
use File::stat;
use CGI;

use constant TRUE   => 1;
use constant FALSE  => 0;

sub _getURI {
    my $self = shift;
    my $uri = $ENV{'REQUEST_URI'};
    $uri =~ s/\?.*$//;
    return $uri;
}

sub _setStatus {
    my $self = shift;
    my $status = shift;
    $self->_addHeader('status', $status);
}

sub _getStatus {
    my $self = shift;
    return $self->_getHeader('status');
}

sub _getMeetsConditions {
    #XXX we are not currently doing intelligent caching
    return TRUE;
}

sub _setContentType {
    my $self = shift;
    my $type = shift;
    $self->_addHeader('type', $type);
}

sub _addHeader {
    my $self = shift;
    my $name = shift;
    my $value = shift;
    my $headers = $self->get('headers') || {};
    $headers->{$name} = $value;
    $self->set('headers', $headers);
}

sub _getHeader {
    my $self = shift;
    my $header = shift;

    my $headers = $self->get('headers');
    return $headers->{$header};
}



sub _getRequestBody {
    my $self = shift;

    my $body = '';
    while(<STDIN>){
        $body .= $_;
    }
    return $body;
}

sub _getHeaderIn {
    my $self = shift;
    my $name = shift;
    return CGI->new()->http($name);
}

sub _printHeaders {
    my $self = shift;
    my $cgi = CGI->new();

    unless( $self->get('headers_printed')){
        $self->set('headers_printed', TRUE);

        $self->setContentType('text/html') unless $self->getContentType();
        $self->setStatus(200) unless $self->getStatus();

        my %headers = %{$self->get('headers')};
        my %groomed_headers;
        for my $key (keys %headers){
            $groomed_headers{"-$key"} = $headers{$key};
        }
        $groomed_headers{"-nph"} = TRUE;
        print $cgi->header(%groomed_headers);
    }
}

sub _getContentType {
    my $self = shift;
    my $value = $self->_getHeader('type');
    return $value;
}

sub _getMethod {
    return $ENV{'REQUEST_METHOD'};
}

sub _setPostMax {
    #not implemented
}

sub _setContentLength {
    my $self = shift;
    my $length = shift;
    $self->_addHeader('Content-length', $length);
}

sub _setContentDisposition {
    my $self = shift;
    my $disposition = shift;
    $self->_addHeader('Content-disposition', $disposition);
}

sub _getUploadData {
    my $self = shift;
    my $name = shift;

    my $cgi = CGI->new();
    my $handle = $cgi->upload($name);
    my $type = Solstice::ContentTypeService->new()->getContentTypeByFilehandle($handle);

    return {
        name    => ''.$cgi->param($name),
        size    => stat($handle)->size,
        type    => $type,
        handle  => $handle,
    };
}

1;

=head1 COPYRIGHT

Copyright 1998-2007 Office of Learning Technologies, University of Washington

Licensed under the Educational Community License, Version 1.0 (the "License");
you may not use this file except in compliance with the License. You may obtain
a copy of the License at: http://www.opensource.org/licenses/ecl1.php

Unless required by applicable law or agreed to in writing, software distributed
under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
CONDITIONS OF ANY KIND, either express or implied.  See the License for the
specific language governing permissions and limitations under the License.

=cut

