package Solstice::Server::ModPerl::API;

## no critic (RequireCamelCaseSubs)
# this api is designed to mirror mod_perl's, so it doesn't match our coding conventions


=head1 NAME

Solstice::Server::ModPerl::API - An interface to mod_perl that abstracts the differences in versions.

=head1 SYNOPSIS

  use Solstice::Server::ModPerl::API;

=head1 DESCRIPTION

An interface to mod_perl that abstracts the differences in versions.

=cut

use 5.006_000;
use strict;
use warnings;

# used to store the cached object for this singleton.
my $mod_perl;
our $use_apache_request;



use constant APACHE2_REQUEST_UTIL    => "Apache2/RequestUtil.pm";
use constant APACHE2_REQUEST_IO        => "Apache2/RequestIO.pm";
use constant APACHE2_REQUEST        => "Apache2/Request.pm";
use constant APACHE2_RESPONSE       => "Apache2/Response.pm";
use constant APACHE2_CONST            => "Apache2/Const.pm";
use constant APACHE2_ACCESS            => "Apache2/Access.pm";
use constant APACHE2_SERVER_UTIL    => "Apache2/ServerUtil.pm";
use constant APACHE2_DIRECTIVE        => "Apache2/Directive.pm";
use constant APACHE2_COOKIE              => "Apache2/Cookie.pm";
use constant APACHE_COOKIE              => "Apache/Cookie.pm";
use constant APR_TABLE                => "APR/Table.pm";
use constant APACHE2_MODULE         => "Apache2/Module.pm";

use constant APACHE_FILE         => "Apache/File.pm";
use constant APACHE_CONSTANTS     => "Apache/Constants.pm";
use constant APACHE_REQUEST        => "Apache/Request.pm";


=head2 Methods

=over 4

=cut


=item new()

=cut

sub new {
    my $obj = shift;
    my $r = shift;

    return unless $ENV{'MOD_PERL'};

    return $mod_perl if (defined $mod_perl && !defined $r);

    # this means that the caller is setting the request object
    # from within Handler().  This the first time it is called
    # during this request cycle, so we'll set things up and cache
    # them.

    my $self = bless {}, ref $obj || $obj;

    $ENV{MOD_PERL} =~ /.*?(\d).*/;
    $self->_setVersion($1);

    if ($self->is2()) {
        require(APACHE2_REQUEST_UTIL);
        require(APACHE2_REQUEST_IO);
        require(APACHE2_REQUEST);
        require(APACHE2_RESPONSE);
        require(APACHE2_CONST);
        require(APACHE2_ACCESS);
        require(APACHE2_MODULE);
        require(APACHE2_SERVER_UTIL);
        require(APACHE2_DIRECTIVE);
        require(APACHE2_COOKIE);
        require(APR_TABLE);
        Apache2::Const->import(qw(:common :override :cmd_how));
        if (!defined $use_apache_request) {
            eval { require(APACHE2_REQUEST);};
            if ($@) {
                $use_apache_request = 0;
            }
            else {
                $use_apache_request = 1;
            }
        }
        $self->_setRequest($r);
    } else {
        require(APACHE_FILE);
        require(APACHE_CONSTANTS);
        require(APACHE_COOKIE);
        Apache::Constants->import(qw(:common));
        if (!defined $use_apache_request) {
            eval {require(APACHE_REQUEST);};
            if ($@) {
                $use_apache_request = 0;
            }
            else {
                $use_apache_request = 1;
            }
        }
        $self->_setRequest(Apache->request);
    }

    # cache it
    $mod_perl = $self;

    return $self;
}

=item useApacheRequest()

Returns a boolean for whether Apache[2]::Request should be used in preference of CGI.

=cut

sub useApacheRequest {
    return $use_apache_request;
}

=item _setVersion($version)

Sets the version of mod_perl

=cut

sub _setVersion {
    my ($self, $version) = @_;
    $self->{_version} = $version;
}


=item version()

Gets the version of mod_perl.

=cut

sub version {
    my $self = shift;
    return $self->{_version};
}


=item setPostMax($post_max)

Sets the maximum post size.

=cut

sub setPostMax {
    my $self = shift;
    return $self->{_post_max} = shift;
}


=item getPostMax()

Gets the maximum post size.

=cut

sub getPostMax {
    my $self = shift;
    return $self->{_post_max};
}


=item is2()

Returns whether the version is 2.

=cut

sub is2 {
    my $self = shift;
    return $self->version() >= 2;
}


=item is1()

Returns whether the version is 1.

=cut

sub is1 {
    my $self = shift;
    return $self->version() < 2;
}


=item _setRequest($r)

Sets the apache request object that is passed to the mod_perl handler.

=cut

sub _setRequest {
    my $self = shift;
    $self->{_r} = shift;
}


=item request()

Gets the apache request object.

=cut

sub request {
    my $self = shift;
    return $self->{_r};
}


=item apacheRequest()

Gets the apache request object that is provided by libapreq.

=cut

sub apacheRequest {
    my $self = shift;

    return $self->{_apache_request} if defined $self->{_apache_request};
    
    my $apache_request_package = $self->is2() ? 'Apache2::Request' : 'Apache::Request';

    if($self->is2()){

        if (defined $self->getPostMax()) {
            $self->{_apache_request} = $apache_request_package->new($self->request(),
                POST_MAX => $self->getPostMax(),
                DISABLE_UPLOADS => 0);
        } else {
            $self->{_apache_request} = $apache_request_package->new($self->request(),
                DISABLE_UPLOADS => 0);
        }

    }else{
        if (defined $self->getPostMax()) {
            $self->{_apache_request} = $apache_request_package->instance($self->request(),
                POST_MAX => $self->getPostMax(),
                DISABLE_UPLOADS => 0);
        } else {
            $self->{_apache_request} = $apache_request_package->instance($self->request(),
                DISABLE_UPLOADS => 0);
        }
    }

    return $self->{_apache_request};
}


=back

=head2 mod_perl wrappers

=over 4

=cut

=item sendfile()
=cut

sub sendfile {
    my $self = shift;
    if ($self->is2()) {
        return $self->request()->sendfile(@_);
    } else {
        return $self->request()->send_fd(@_);
    }
}

=item uri()
=cut

sub uri {
    my $self = shift;
    return $self->request()->uri(@_);
}

=item args()
=cut

sub args {
    my $self = shift;
    return $self->request()->args(@_);
}

=item filename()
=cut

sub filename {
    my $self = shift;
    return $self->request()->filename(@_);
}

=item set_last_modified()
=cut

sub set_last_modified {
    my $self = shift;
    return $self->request()->set_last_modified(@_);
}

=item set_etag()
=cut

sub set_etag {
    my $self = shift;
    return $self->request()->set_etag(@_);
}

=item set_content_length()
=cut

sub set_content_length {
    my $self = shift;
    return $self->request()->set_content_length(@_);
}

=item set_content_disposition()
=cut

sub set_content_disposition {
    my $self = shift;
    my $input = shift;
    return $self->header_out('Content-Disposition', $input);
}

=item set_content_type()
=cut

sub set_content_type {
    my $self = shift;
    return $self->content_type(@_);
}

=item content_type()
=cut

sub content_type {
    my $self = shift;
    my $type = shift;
    if( $type ){
        $self->request()->content_type($type);
    }else{
        return $self->request()->content_type();
    }
}

=item update_mtime()
=cut

sub update_mtime {
    my $self = shift;
    return $self->request()->update_mtime(@_);
}

=item meets_conditions()
=cut

sub meets_conditions {
    my $self = shift;
    return $self->request()->meets_conditions(@_);

}

=item method()
=cut

sub method {
    my $self = shift;
    return $self->request()->method(@_);
}


=item header_only()
=cut

sub header_only {
    my $self = shift;
    return $self->request()->header_only(@_);
}

=item header_in('header')
=cut

sub header_in {
    my $self = shift;
    my $header = shift;

    if($self->is2()){
        return $self->request()->headers_in->{$header};
    }else{
        return $self->request()->header_in($header);
    }
}

=item header_out()
=cut

sub header_out {
    my $self = shift;
    my $header = shift;
    my $value = shift;

    my $r = $self->request();

    if ($self->is2()) {
        return $r->headers_out->add($header => $value);
    } else {
        return $self->request()->header_out($header => $value);
    }
}

#I don't believe this method is used any longer, if you see this after nov 2007 or so, remove it
sub send_http_header {
    my $self = shift;

    if($self->is2()) {
        #there is no equivalent to send_http_header in mp2
        #mp2 should handle this correctly now, we might need to look into rflush if we find this
        #is not good enough
    }else {
        return $self->request()->send_http_header();
    }
}


=item status (return code)

Sets the statuscode of the response

=cut 

sub status {
    my $self = shift;
    my $value = shift;

    #blissfully identicaly in 1 and 2
    my $r = $self->request();
    if (defined $value) {
        return $r->status($value);
    }
    return $r->status();
}

#sub notes{
#    my $self = shift;
#    my ($key, $value) = @_;
#
#    if($mod_perl2){
#
#        if(defined $value){
#            return $self->request()->pnotes($key => $value);
#        }else{
#            return $self->request()->pnotes($key);
#        }
#
#    }else{
#
#        if(defined $value){
#            return $self->request()->notes($key, $value);
#        }else{
#            return $self->request()->notes($key);
#        }
#    }
#}

=item const($constant_name)

Returns the equivalent Apache::Constant or Apache2::Const, depending
on what version of mod_perl you're using.

=cut

sub const {
    my $self = shift;
    my $name = shift;

    if($self->is2()){
        return eval "Apache2::Const::$name();"; ##no critic
    }else{
        return eval "Apache::Constants::$name();"; ##no critic
    }
}

=back

=head2  mod_perl server wrappers

=over 4

=cut

=item get_handlers('hook_name')
=cut

sub get_handlers {
    my $self = shift;
    if ($self->is2()) {
        # Allegedly you can just do the following: 
        # return Apache2::ServerUtil->server->get_handlers(@_);
        # but i always get nothing.  So, instead i traverse the config tree.
        # TODO: See if this is a known mod_perl2 bug, that we can upgrade past
        
        my $handler_name = $_[0];
        my $virtual_root = $ENV{'SOLSTICE_VIRTUAL_ROOT'};
        my $tree = Apache2::Directive::conftree();
        my $conf_data = $tree->as_hash;

        my $vhost_data = $conf_data->{'VirtualHost'};
        
        return [] unless defined $vhost_data;
        
        foreach my $vhost (keys %{$vhost_data}) {
            my $location_data = $vhost_data->{$vhost}->{'Location'};
            return [] unless defined $location_data;
            
            foreach my $location (keys %{$location_data}) {
                # If this is handling the path given in config, and it's handled by Solstice, assume that this is the place.
                # If there are multiple VHosts with Solstice handling the same virtual root, this could be problematic.
                # Hopefully before that happens, we'll be able to use the get_handlers() method mentioned above.
                if ($location eq $virtual_root && 'Solstice::Handler' eq $location_data->{$location}->{'PerlResponseHandler'}) {
                    return [$location_data->{$location}->{$handler_name}];
                }
            }
        }
        
        return [];
    }
    elsif ($self->is1()) {
        return $self->request()->get_handlers(@_);
    }
    
    return [];
}

1;
__END__

=back

=head1 AUTHOR

Catalyst Group, E<lt>catalyst@u.washington.eduE<gt>

=head1 VERSION

$Revision$



=cut

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
