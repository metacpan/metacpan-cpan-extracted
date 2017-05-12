# BEGIN BPS TAGGED BLOCK {{{
# 
# COPYRIGHT:
#  
# This software is Copyright (c) 1996-2005 Best Practical Solutions, LLC 
#                                          <jesse@bestpractical.com>
# 
# (Except where explicitly superseded by other copyright notices)
# 
# 
# LICENSE:
# 
# This work is made available to you under the terms of Version 2 of
# the GNU General Public License. A copy of that license should have
# been provided with this software, but in any event can be snarfed
# from www.gnu.org.
# 
# This work is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
# 
# 
# CONTRIBUTION SUBMISSION POLICY:
# 
# (The following paragraph is not intended to limit the rights granted
# to you to modify and distribute this software under the terms of
# the GNU General Public License and is only of importance to you if
# you choose to contribute your changes and enhancements to the
# community by submitting them to Best Practical Solutions, LLC.)
# 
# By intentionally submitting any modifications, corrections or
# derivatives to this work, or any other work intended for use with
# Request Tracker, to Best Practical Solutions, LLC, you confirm that
# you are the copyright holder for those contributions and you grant
# Best Practical Solutions,  LLC a nonexclusive, worldwide, irrevocable,
# royalty-free, perpetual, license to use, copy, create derivative
# works based on those contributions, and sublicense and distribute
# those contributions and any derivatives thereof.
# 
# END BPS TAGGED BLOCK }}}
package RT::URI::svn;

use RT::Ticket;

use RT::URI::base;

use strict;
use vars qw(@ISA);
@ISA = qw/RT::URI::base/;


=head1 LocalURIPrefix  

Returns the prefix for a local SVN URI. 

=begin testing

use_ok("RT::URI::svn");
my $uri = RT::URI::svn->new($RT::SystemUser);

ok(ref($uri));

use Data::Dumper;


ok (UNIVERSAL::isa($uri,RT::URI::svn), "It's an RT::URI::svn");

ok ($uri->isa('RT::URI::base'), "It's an RT::URI::base");
ok ($uri->isa('RT::Base'), "It's an RT::Base");

=end testing



=cut

BEGIN { $RT::Logger->debug("Loaded svn URI parser"); }

sub LocalURIPrefix {
    my $self = shift;
    
    my $scheme = $self->Scheme;

    my $prefix;
    if (defined $RT::SvnRepository && $RT::SvnRepository =~ /^$scheme/) {
      $prefix = $RT::SvnRepository;
    } else {
      $prefix = 'svn://localhost/';
    }

    $RT::Logger->debug("Prefix looks like: $prefix");
    #$RT::Logger->debug("SVN lives at ". $RT::SvnRepository);

    return ($prefix);
}

=head2 ObjectType

=cut

sub ObjectType {
    my $self = shift;
    return undef;
}


=head2 ParseURI URI

When handed an svn: URI, figures out whether it's a commit to the local SVN
server.

=cut


sub ParseURI {
    my $self = shift;
    my $uri  = shift;

    # if we were passed a URI, store it for later use; if not, retrieve it
    if ($uri) {
      $self->{'uri'} = $uri;
    } else {
      $uri = $self->{'uri'};
    }

    #If it's a local SVN commit URI, return the revision number
    if ( $self->_IsLocalSvn ) {
        my $scheme = $self->Scheme;
        if ( $uri =~ /^$scheme:\/\/(.+)\/(.+)?\@(\d+)$/i ) {
            $self->{'svn_server'} = $1;
            $self->{'repository_path'} = $2;
            $self->{'revision'} = $3;
            return $self->{'revision'};
        }
    } else {
        return $uri || $self->{'uri'};
    }
    
}

=head2 IsLocal

Returns true if this URI is for a commit to the local SVN repository.
Returns undef otherwise.



=cut

sub _IsLocalSvn {
	my $self = shift;
        my $local_uri_prefix = $self->LocalURIPrefix;
	if ($self->{'uri'} =~ /^$local_uri_prefix/i) {
                $RT::Logger->debug("Local URI ". $self->{'uri'});
		return 1;
    }
	else {
                $RT::Logger->debug("Not a local URI ". $self->{'uri'});
		return undef;
	}
}

sub IsLocal {
  my $self = shift;
  return $self->SUPER::IsLocal;
}

sub URI {
    my $self = shift;
    return $self->{'uri'};
}

=head2 Scheme

Return the URI scheme for SVN commits

=cut

sub Scheme {
    my $self = shift;
	return "svn";
}

=head2 HREF

If this is a local ticket, return an HTTP url to it.
Otherwise, return its URI.

By default, this assumes that your SVN repository lives at svn://localhost,
which can be changed by setting the $SvnRepository configuration 
variable.

Most svn:// URIs look like
svn://svn.example.com/path/to/repository/@1234

RT will assume that this means the Web view of the revision lives at
http://svn.example.com/cgi-bin/index.cgi/path/to/repository/?rev=1234

This URL can be changed in RT_SiteConfig.pm with the directive
Set( $SvnRepositoryWebView, 'http://svn.example.com/path/to/?rev=');
and the correct revision number will be appended.

=cut


sub HREF {
    my $self = shift;

    if ($self->_IsLocalSvn) {
        # we can assume that ParseURI has already run and stored its 
        # information in $self
        my $web_url;
        if ($RT::SvnRepositoryWebView) {
            $web_url = ($RT::SvnRepositoryWebView . $self->{'revision'});
        } else {
            $web_url = ('http://'. $self->{'svn_server'}. '/cgi-bin/index.cgi/'. $self->{'repository_path'}. '?rev='. $self->{'revision'});
        }
        $RT::Logger->debug("Web URL: $web_url");
        return $web_url;
    }
    else {
        return ($self->URI);
    }
}

=head2 AsString

Returns either a localized string 'SVN revision 1234 (svn://svn.bestpractical.com)' or the full URI if the object is not local

=cut

sub AsString {
    my $self = shift;
    if ($self->_IsLocalSvn) {
	    return $self->loc("SVN revision [_1] ([_2])", $self->ParseURI, $self->LocalURIPrefix);
    }
    else {
	    return $self->URI;
    }
}

eval "require RT::URI::svn_Vendor";
die $@ if ($@ && $@ !~ qr{^Can't locate RT/URI/svn_Vendor.pm});
eval "require RT::URI::svn_Local";
die $@ if ($@ && $@ !~ qr{^Can't locate RT/URI/svn_Local.pm});

1;
