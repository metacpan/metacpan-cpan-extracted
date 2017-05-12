# $Id: TiVo.pm 63 2007-03-29 14:09:37Z boumenot $
# Author: Christopher Boumenot <boumenot@gmail.com>
######################################################################
#
# Copyright 2006-2007 by Christopher Boumenot.  This program is free 
# software; you can redistribute it and/or modify it under the same
# terms as Perl itself.
#
######################################################################

package Net::TiVo;

use strict;
use warnings;

our $VERSION = '0.11';

use LWP::UserAgent;
use HTTP::Request;
use XML::Simple;
use Data::Dumper;
use Log::Log4perl qw(:easy get_logger);
use Net::TiVo::Folder;
use Net::TiVo::Show;

use constant TIVO_URL => '/TiVoConnect?Command=QueryContainer&Container=%2FNowPlaying';

sub new { 
    my $class = shift;
    my $self = {username => 'tivo',
                realm    => 'TiVo DVR',
                @_};

    $self->{host}     || die "%Error: no host was defined!\n";
    $self->{mac}      || die "%Error: no mac was defined!\n";
    $self->{username} || die "%Error: no username was defined!\n";

    $self->{ua}  = LWP::UserAgent->new() or
        die "%Error: failed to create a LWP::UserAgent!";

    $self->{ua}->credentials($self->{host}.':443',
                             $self->{realm}, 
                             $self->{username} => $self->{mac});

    $self->{url} = 'https://'.$self->{host}.TIVO_URL;

    bless $self, $class;
    return $self;
}


sub folders {
    my $self = shift;

    my $resp = $self->_fetch($self->{url});

    if ($resp->is_success()) {
        my @folders;
        $self->_parse_content($resp->content(), \@folders);

        return unless @folders;
        return (wantarray) ? @folders : \@folders;
    } 

    print "%Error: $resp->status_line()!\n";
    return;
}


sub _fetch {
    my ($self, $url) = @_;
    my $resp;

    INFO("fetching $url");

    if (exists $self->{cache}) {
        $resp = $self->{cache}->get($url, $resp);
        if (defined $resp) {
            INFO("cache hit");
            return $resp;
        }
        INFO("cache miss");
    } 

    $resp = $self->{ua}->request(HTTP::Request->new(GET => $url));
    die "%Error: fetch failed, " . $resp->status_line() . "!\n" unless $resp->is_success();

    if (exists $self->{cache}) {
        $self->{cache}->set($url, $resp);
    }

    return $resp;
}

sub _parse_content {
    my ($self, $cont, $folder_aref) = @_;

    DEBUG(sub { "Received [" . $cont . "]"});

    my $xmlref = XMLin($cont, ForceArray => ['Item']);
    unless (defined $xmlref->{Item}) {
        INFO("No content to parse, skipping ...");
        return;
    }
    
    DEBUG(sub { Dumper($xmlref) });

    # TiVo only allows you to create one folder to hold shows, but the
    # top most folder, Now Playing, as to be accounted for too.  If we
    # haven't created any folders yet, then this is the Now Playing
    # folder, and needs to be treated specially.
    push @$folder_aref, Net::TiVo::Folder->new(xmlref => $xmlref);

    # 2006/12/29 - RHARMAN: TiVo Suggestions can exist but contain zero videos
    if ($folder_aref->[-1]->total_items() > 0) {
        INFO("added the folder " . $folder_aref->[-1]->name());
    } else {
        INFO("skipped the folder " , $folder_aref->[-1]->name(), " because it was empty.");
        pop @$folder_aref;
    }

    for my $i (@{$xmlref->{Item}}) {
        my $ct = $i->{Links}->{Content}->{ContentType};


        if ($ct eq 'x-tivo-container/folder') {
            my $resp = $self->_fetch($i->{Links}->{Content}->{Url});
            $self->_parse_content($resp->content(), $folder_aref);
        } else {
            INFO("skipping the content for $ct");
        }
    }
}


1;
__END__

=head1 NAME

Net::TiVo - Perl interface to TiVo.

=head1 SYNOPSIS

    use Net::TiVo;

    my $tivo = Net::TiVo->new(
        host => '192.168.1.25', 
        mac  => 'MEDIA_ACCESS_KEY'
    );

    for ($tivo->folders()) {
        print $_->as_string(), "\n";
    }	

=head1 ABSTRACT

C<Net::TiVo> provides an object-oriented interface to TiVo's REST interface.
This makes it possible to enumerate the folders and shows, and dump their
meta-data.

=head1 DESCRIPTION

C<Net::TiVo> has a very simple interface, and currently only supports the
enumeration of folder and shows using the REST interface.  The main purpose of
this module was to provide access to the TiVo programmatically to automate the
process of downloading shows from a TiVo.

C<Net::TiVo> does not provide support for downloading from TiVo.  There are
several options available, including LWP, wget, and curl.  Note: I have used
wget version >= 1.10 with success.  wget version 1.09 appeared to have an issue
with TiVo's cookie.

=head1 BUGS

One user has reported 500 errors when using the library.  He was able to track
the bug down to LWP and Net::SSLeay.  Once he switched from using Net::SSLeay
to Crypt::SSLeay the 500 errors went away.

=head1 CACHING

C<Net::TiVo> is slow due to the amount of time it takes to fetch data from
TiVo.  This is greatly sped up by using a cache.  C<Net::TiVo>'s C<new> method
accepts a reference to a C<Cache> object.  Any type of caching object may be
supported as long as it meets the requirements below.  There are several cache
implementations available on CPAN, such as C<Cache::Cache>.

The following example creates a cache that lasts for 600 seconds.

    use Cache::FileCache;
    
    my $cache = Cache::FileCache->new(
         namespace          => 'TiVo',
         default_expires_in => 600,
    }

    my $tivo = Net::TiVo->new(
         host  => '192.168.1.25',
         mac   => 'MEDIA_ACCESS_KEY',
         cache => $cache,
    }

C<Net::TiVo> uses I<positive> caching, errors are not stored in the cache.

Any C<Cache> class may be used as long as it supports the following method
signatures.

    # Set a cache value
    $cache->set($key, $value);

    # Get a cache value
    $cache->get($key);


=head2 METHODS

=over 4

=item folders()

Returns an array in list context or array reference in scalar context
containing a list of Net::TiVo::Folder objects.

=back

=head1 SEE ALSO

L<Net::TiVo::Folder>, L<Net::TiVo::Show>

=head1 AUTHOR

Christopher Boumenot, E<lt>boumenot@gmail.comE<gt>

=cut
