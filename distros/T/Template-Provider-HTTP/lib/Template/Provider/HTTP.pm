package Template::Provider::HTTP;
use base qw( Template::Provider );

use strict;
use warnings;

use LWP::UserAgent;

our $VERSION = 0.05;

=head1 NAME

Template::Provider::HTTP - fetch templates from a webserver

=begin html

<a href="https://travis-ci.org/evdb/template-provider-http">
  <img src="https://secure.travis-ci.org/evdb/template-provider-http.png?branch=master" alt="Build status" />
</a>

=end html

=head1 SYNOPSIS

    use Template;
    use Template::Provider::HTTP;

    my %provider_config = (
        INCLUDE_PATH => [
            "/some/local/path",                        # file
            "http://svn.example.com/svn/templates/",    # url
        ],
    );

    my $tt = Template->new(
        {   LOAD_TEMPLATES => [
                Template::Provider::HTTP->new( \%provider_config ),
                Template::Provider->new( \%provider_config ),
            ],
        }
    );

    # now use $tt as normal
    $tt->process( 'my_template.html', \%vars );

=head1 DESCRIPTION

Templates usually live on disk, but this is not always ideal. This module lets
you serve your templates over HTTP from a webserver.

For our purposes we wanted to access the latest templates from a Subversion
repository and have them update immediately.

ABSOLUTE = 1 when passed to the constructor acts as a helper to support full 
path to your http template.  "Full" path begins at the domain 
name(omit http://):

    use Template;
    use Template::Provider::HTTP;
    
    my $tt = Template->new( { LOAD_TEMPLATES => [
        Template::Provider::HTTP->new( ABSOLUTE => 1 ) ], } );
    $tt->process( 'www.example.com/templates/my_template.html', \%vars );

EXPAND_RELATIVE = 1 when passed to the constructor will attempt to expand
relative paths in the source document into absolute paths.  For example:
    href="../../main.css" will turn into: 
    href="http://www.someurl.tld/some/path/../../main.css"

=head1 NOTE

Currently there is NO caching, so the webserver will get multiple hits every
time that a template is requested. Patches welcome.

=head1 METHODS

This module is a very thin layer on top of L<Template::Provider> - please see the documentation there for full details.

=head1 PRIVATE METHODS

=head2 _init

Does some setup. Notably goes through the C<INCLUDE_PATH> and removes anything
that does not start with C<http>.

=cut

sub _init {
    my ( $self, $params ) = @_;

    $self->SUPER::_init($params);

    my @path
        = grep {m{ \A http s? :// \w }xi} @{ $self->{INCLUDE_PATH} || [] };
    push( @path, "http:" ) if $self->{ABSOLUTE}; 
    $self->{INCLUDE_PATH} = \@path;
    
    $self->{UA} = $params->{UA};
    $self->{EXPAND_RELATIVE} = $params->{EXPAND_RELATIVE};

    return $self;

}

=head2 _ua

Returns a L<LWP::UserAgent> object, or a cached one if it has already been
called.

=cut

sub _ua {
    my $self = shift;
    return $self->{UA} ||= LWP::UserAgent->new;
}

=head2 _template_modified

Returns the current time if the request is a success, otherwise undef. Could be
smartened up with a bt of local caching.

=cut

#------------------------------------------------------------------------
# _template_modified($path)
#
# Returns the last modified time of the $path.
# Returns undef if the path does not exist.
# Override if templates are not on disk, for example
#------------------------------------------------------------------------

sub _template_modified {
    my $self = shift;

    my $template = shift || return;
    $template =~ s{http:/}{http://};

    $self->debug("_template_modified( '$template' )") if $self->{DEBUG};

    return $self->_ua->get($template)->is_success ? time : undef;
}

=head2 _template_content

Returns the content from the request, or an error.

=cut

#------------------------------------------------------------------------
# _template_content($path)
#
# Fetches content pointed to by $path.
# Returns the content in scalar context.
# Returns ($data, $error, $mtime) in list context where
#   $data       - content
#   $error      - error string if there was an error, otherwise undef
#   $mtime      - last modified time from calling stat() on the path
#------------------------------------------------------------------------

sub _template_content {
    my $self = shift;

    my $path = shift;
    $path =~ s{http:/}{http://};
    $self->debug("_template_content( '$path' )") if $self->{DEBUG};

    return ( undef, "No path specified to fetch content from " )
        unless $path;

    my $data;
    my $mod_date;
    my $error;
    my $res;

    if ( $path =~ m{ \A http s? :// \w }xi ) {
        $res = $self->_ua->get($path);

        if ( $res->is_success ) {
            $data     = $res->decoded_content;
            $mod_date = time;
        } else {
            $error = "error with request: " . $res->status_line;
        }
    } else {
        $error = 'NOT A URL';
    }

    if( !$error && $self->{EXPAND_RELATIVE} ) {
        my $urlbase = $res->base;
        if( $urlbase !~ m/\/$/ ) {
            my @chunks = split /\/+/, $urlbase;
            delete $chunks[ scalar( @chunks ) - 1 ];
            delete $chunks[0];
            
            $urlbase = "http://";
            foreach my $chunk ( @chunks ) {
                if( $chunk ) {
                    $urlbase .= "$chunk/";
                }
            }
        }

        my @path_chunks = split( /\/+/, $urlbase );
        my $domain = "http://" . $path_chunks[1];

        my @dbl_matches = $data =~ m/"([^ ]+)"/g;
        my @sgl_matches = $data =~ m/'([^ ]+)'/g;

        foreach my $path ( grep { $_ && /^\./ } @dbl_matches ) {
            $data =~ s/"$path"/"$urlbase$path"/g;
        }
        
        foreach my $path ( grep { $_ && /^\./ } @sgl_matches ) {
            $data =~ s/'$path'/'$urlbase$path'/g;
        }

        foreach my $path ( grep { $_ && /^\// } @dbl_matches ) {
            $data =~ s/"$path"/"$domain$path"/g;
        }
        
        foreach my $path ( grep { $_ && /^\// } @sgl_matches ) {
            $data =~ s/'$path'/'$domain$path'/g;
        }
    }

    return wantarray
        ? ( $data, $error, $mod_date )
        : $data;
}

=head1 SEE ALSO

L<Template::Provider> - which this module inherits from.

=head1 BUGS AND REPO

This code is hosted on GitHub:

code: https://github.com/evdb/template-provider-http

bugs: https://github.com/evdb/template-provider-http/issues

=head1 AUTHOR

Edmund von der Burg C<<evdb@ecclestoad.co.uk>>

=head1 THANKS

Developed whilst working at Foxtons for an internal system there and released
with their blessing.

Kevin Kane (https://github.com/klkane) added support for C<ABSOLUTE => 1>.

=head1 GOD SPEED

TT3 - there has to be a better way than this :)

=head1 LICENSE

Sam as Perl.

=cut

1;
