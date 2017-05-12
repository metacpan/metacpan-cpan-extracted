package Solstice::Server::ModPerl;

=head1 NAME

Solstice::Server::ModPerl - Solstice's interface to mod_perl for Apache 1 and 2.

=head2 Export

None by default.

=head2 Methods

=cut

use strict;
use warnings;
use 5.006_000;

use base qw(Solstice::Server);

use constant TRUE => 1;
use constant FALSE => 0;
use File::stat;

eval {
    Solstice::Server::ModPerl->new();

    require Solstice::Server::ModPerl::API;
    my $config = Solstice::Configure->new();

#Let's have our way with apache here.
    if( Solstice::Server::ModPerl::API->new()->is2 ){
        my @directives = (
            {
                name         => '<SolsticeAuthLocation',
                func         => 'Solstice::Server::ModPerl::customDirectiveCallback',
                req_override => Solstice::Server::ModPerl::API->new()->const('RSRC_CONF'),
                args_how     => Solstice::Server::ModPerl::API->new()->const('RAW_ARGS'),
                errmsg       => 'The SolsticeAuthLocation directive should be filled out exactly as a <Location> block you wish to secure',
            },
            {
                name         => '<SolsticeWebServiceLocation',
                func         => 'Solstice::Server::ModPerl::customDirectiveCallback',
                req_override => Solstice::Server::ModPerl::API->new()->const('RSRC_CONF'),
                args_how     => Solstice::Server::ModPerl::API->new()->const('RAW_ARGS'),
                errmsg       => 'SolsticeWebServiceLocation should contain any configuration you desire for your webserivces, similar to a <Location> block. SSL client cert configuration is a common example.',
            },

        );
        Apache2::Module::add('Solstice::Server::ModPerl', \@directives);
    }

    my $path = $config->getNoConfig() ? 'solstice' : $config->getURL();
    $path = "/$path/";
    $path =~ s/\/+/\//g;

    my $webservice_root = $path . $config->getWebServiceRestRoot() .'/';
    $webservice_root =~ s/\/+/\//g;

    my $auth_root = $path . '_auth/';
    $auth_root =~ s/\/+/\//g;

    if( Solstice::Server::ModPerl::API->new()->is2 ){
        my $apache_config = Apache2::Directive::conftree()->as_hash;
        %Apache2::ReadConfig::Location =  (
            $path => {
                SetHandler              => 'perl-script',
                PerlResponseHandler     => 'Solstice::Server::ModPerl',
                PerlHeaderParserHandler => 'Solstice::Server::ModPerl::UploadHandler',
                PerlCleanupHandler      => 'Solstice::Server::ModPerl::CleanupHandler',
            },
            $auth_root          => $apache_config->{'SolsticeAuthLocation'}{''},
            $webservice_root    => $apache_config->{'SolsticeWebServiceLocation'}{''},
        );
    }else{
        %Apache::ReadConfig::Location =  (
            $path => {
                SetHandler              => 'perl-script',
                PerlHandler             => 'Solstice::Server::ModPerl',
                PerlHeaderParserHandler => 'Solstice::Server::ModPerl::UploadHandler',
                PerlCleanupHandler      => 'Solstice::Server::ModPerl::CleanupHandler',
            },
        );
    }
};

if($@){
    warn "Solstice failed to configure Apache: $@";
    Solstice::Server->setStartupError($@);
}

#### Server startup ends here

sub customDirectiveCallback {
    #dummy - 
    #Apache provides callbacks so we can take actions as the custom directives are
    #found while the config is being parsed.  They seem to be required, but we 
    #actually don't need them.   We read the content of our custom directives
    #here in server::modperl.
}

sub handler : method {
    my $package = shift;
    my $r = shift;
    my $mp = Solstice::Server::ModPerl::API->new($r);
    my $return = Solstice::Dispatch->dispatch();

    my $status = _getStatus();
    # In apache 1.3, if we don't return the right return code, we get a 200 in addition to the proper return code, which the 
    # browser just sees as a 200 with no content.
    # In apache 2.*, if we return a 200, we get a double 200, if we have another return and don't pass it along, it's not seen by apache
    # So, we mask the statuses that we handle and return the rest.
    if ( $status == 200 || $status == 404 || $status == 500 ){
        return;
    }else{
        return $status;
    }
}

sub _getIsSSL {
    return ((defined $ENV{'HTTPS'} && $ENV{'HTTPS'} eq 'on') ? TRUE : FALSE);
}

sub _getURI {
    my $self = shift;
    my $mp = Solstice::Server::ModPerl::API->new();
    return $mp->uri();
}

sub _setPostMax {
    my $self = shift;
    my $mp = Solstice::Server::ModPerl::API->new();
    return $mp->setPostMax(shift);
}

sub _setContentLength {
    my $self = shift;
    my $length = shift;
    my $mp = Solstice::Server::ModPerl::API->new();
    return $mp->set_content_length($length);
}

sub _setContentDisposition {
    my $self = shift;
    my $disposition = shift;
    my $mp = Solstice::Server::ModPerl::API->new();
    return $mp->set_content_disposition($disposition);
}

sub _setContentType {
    my $self = shift;
    my $mp = Solstice::Server::ModPerl::API->new();
    return $mp->content_type(shift);
}

sub _getContentType {
    my $self = shift;
    my $mp = Solstice::Server::ModPerl::API->new();
    return $mp->content_type();
}

sub _setStatus {
    my $self = shift;
    my $mp = Solstice::Server::ModPerl::API->new();
    return $mp->status(shift);
}

sub _getStatus {
    my $self = shift;
    my $mp = Solstice::Server::ModPerl::API->new();
    return $mp->status();
}

sub _getMeetsConditions {
    my $self = shift;
    my $filename = shift;

    my $mp = Solstice::Server::ModPerl::API->new();

    open(my $fh, '<', $filename);
    $mp->filename($filename);
    $mp->update_mtime(stat($fh)->mtime);
    $mp->set_last_modified();
    $mp->set_etag();
    $mp->set_content_length(stat($fh)->size);

    my $rc = $mp->meets_conditions();
    if($rc != $mp->const('OK')){
        close $fh;
        $self->setStatus($rc);
        return FALSE;
    }
    close $fh;
    return TRUE;

}

sub _addHeader {
    my $self = shift;
    my $name = shift;
    my $value = shift;
    my $mp = Solstice::Server::ModPerl::API->new();
    return $mp->header_out($name, $value);
}

sub _getHeaderIn {
    my $self = shift;
    my $name = shift;
    my $mp = Solstice::Server::ModPerl::API->new();
    return $mp->header_in($name);
}

sub _getMethod {
    my $self = shift;
    my $mp = Solstice::Server::ModPerl::API->new();

    return $mp->method();
}

sub _getRequestBody {
    my $self = shift;
    my $mp = Solstice::Server::ModPerl::API->new();

    my $buff;
    my $body = '';
    while($mp->request()->read($buff, 1024)){
        $body .= $buff;
    }
    return $body;
}

sub param {
    my $self = shift;
    my $mod_perl = Solstice::Server::ModPerl::API->new();
    if ($mod_perl->useApacheRequest()) {
        return $mod_perl->apacheRequest()->param(@_);
    } else {
        if(@_){
            return CGI::param(@_);
        }elsif(wantarray){
            return CGI::param();
        }else{
            my $params;
            for my $name ( CGI::param() ){
                $params->{$name} = CGI::param($name);
            }
            return $params;
        }
    }

}

sub getUploadSuccessful {
    my $self = shift;

    my $mod_perl = Solstice::Server::ModPerl::API->new();
    if (!$mod_perl->useApacheRequest()) {
        die "upload(): Apache::Request (or Apache2::Request) required. Please install libapreq or libapreq2.";
    }
    my $r = $mod_perl->apacheRequest();
    my $status = $r->parse();

    if ($status != $mod_perl->const('OK')) {
        # probably because upload was above post_max
        warn 'Upload error: '.$r->notes("error-notes");
        return FALSE;
    }
    return TRUE;
}


sub _getUploadData {
    my $self = shift;
    my $name = shift;

    my $mod_perl = Solstice::Server::ModPerl::API->new();
    my $r = $mod_perl->apacheRequest();
    my $upload = $r->upload($name);

    return {} unless defined $upload;

    my $is2 = $mod_perl->is2();

    return {
        name    => $is2 ? (''.$upload) : (''.$r->param($name)),
        size    => $is2 ? $upload->upload_size() : $upload->size(),
        type    => $is2 ? $upload->upload_type() : $upload->type(),
        handle  => $is2 ? $upload->upload_fh() : $upload->fh(),
    };
}

sub _printHeaders {
    #mod_perl will send our headers for us once we start printing
    my $mod_perl = Solstice::Server::ModPerl::API->new();
    $mod_perl->send_http_header();
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

