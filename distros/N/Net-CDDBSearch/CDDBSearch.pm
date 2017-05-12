package Net::CDDBSearch;

require 5.005_62;
use strict;

use LWP::Simple;
use URI::Escape;

require Exporter;

our @ISA = qw/Exporter/;

our @EXPORT = qw//;

our @EXPORT_OK = qw/new get_albums_artist get_albums_album get_songs_album albums tracks info url/;

our $VERSION = '2.01';


sub new {
    my $class = shift;
    my $self = {
	DEBUG => undef,
	@_
   };
    bless($self, $class);
    $self ? return $self : return undef;
}


sub albums {
    my $self = shift;
    return $self->{ALBUMS};
}


sub tracks {
    my $self = shift;
    return $self->{TRACKS};
}

sub info {
    my $self = shift;
    return {'Title'	=> $self->{TITLE},
	    'Artist'	=> $self->{ARTIST},
	    'Year' 	=> $self->{YEAR},
	    'Genre'	=> $self->{GENRE},
	    'Tracks'	=> $self->{TRACKN},
	    'Time'	=> $self->{TIME}};
}


sub url {
    my $self = shift;
    my $line = lc(shift);
    
    if($self->{TYPE} eq 'artist') {
	foreach (keys %{$self->{ALBUMS}}) {
	    return $_ if (lc($self->{ALBUMS}->{$_}[0]) eq lc($self->{QUERY}) && lc($self->{ALBUMS}->{$_}[1]) eq $line);
	}
    } elsif($self->{TYPE} eq 'disc') {
	foreach (keys %{$self->{ALBUMS}}) {
	    return $_ if (lc($self->{ALBUMS}->{$_}[1]) eq lc($self->{QUERY}) && lc($self->{ALBUMS}->{$_}[0]) eq $line);
	}
    }
    return undef;
}


sub get_albums_artist {
    my $self      = shift;
    $self->{QUERY}= shift;
    
    if ($self->{QUERY}) {
	$self->{URL}   = uri_escape($self->{QUERY});
	$self->{ERROR} = undef;
	$self->{TYPE}  = 'artist';
	print "$self >> Calling _get_albums();\n" if $self->{DEBUG};
	$self = _get_albums($self);
	defined $self->{ERROR} ? return undef : return $self;
    }
    $self->{ERROR} = 'No query provided';
    return undef;
}

sub get_albums_album {
    my $self      = shift;
    $self->{QUERY}= shift;
    
    if ($self->{QUERY}) {
	$self->{URL}   = uri_escape($self->{QUERY});
	$self->{ERROR} = undef;
	$self->{TYPE}  = 'title';
	print "$self >> Calling _get_albums();\n" if $self->{DEBUG};
	$self = _get_albums($self);
	defined $self->{ERROR} ? return undef : return $self;
    }
    $self->{ERROR} = 'No query provided';
    return undef;
}


sub get_songs_album {
    my $self = shift;
    $self->{URL}= shift;
    
    if ($self->{URL}) {
	$self->{ERROR} = undef;
	$self->{TYPE} = 'track';
	print "$self >> Calling _get_songs();\n" if defined $self->{DEBUG};
	$self = _get_songs($self);
	defined $self->{ERROR} ? return undef : return $self;
    }
    $self->{ERROR} = 'No url provided';
    return undef;
}


sub DESTROY {
    my $self = shift;
    $self = {};
    return 1;
}

sub _get_url {
    my $self = shift;
    unless ($self->{URL} =~ /^http/) {
	$self->{URL} = 'http://www.freedb.org/freedb_search.php?allfields=NO&allcats=YES&grouping=none&words=' . $self->{URL};
	$self->{URL} .= '&fields=' . $self->{TYPE};
    }

    print "$self >> URL: $self->{URL}\n" if $self->{DEBUG};
    my $data = get($self->{URL});

    $self->{DATA} = $data;
    return $self;
}

sub _get_albums {
    my $self = shift;
    
    my($line, $n1, $n2, $n3, $n4);

    print "$self >> Calling _get_url();\n" if $self->{DEBUG};
    $self = _get_url($self);

    return $self if (!$self->{DATA});

    while ($self->{DATA} =~ m!<a href="([^"]+)\/freedb_search_fmt\.php\?([^"]+)">([^<]+)\s+\/\s+([^<]+)</a>!ig) {
	($n1,$n2,$n3,$n4) = ($1,$2,$3,$4);
	$self->{ALBUMS}->{$n1.'/freedb_search_fmt.php?'.$n2} = [$n3,$n4];
    }
    return $self;
}


sub _get_songs {
    my $self = shift;
    
    my($line, $n1, $n2, $n3, $n4);

    print "$self >> Calling _get_url();\n" if defined $self->{DEBUG};

    $self = _get_url($self);

    return $self if (!$self->{DATA});

    if ($self->{DATA} =~ m!<h2>([^<]+)\s+\/\s+([^<]+)</h2>\s*tracks:\s+([^<]*)<br>\s*total time:\s+([^<]*)<br>\s*year:\s+([^<]*)<br>\s*genre:\s+([^<]*)!is) {
	$self->{ARTIST} = $1;
	$self->{TITLE}  = $2;
	$self->{GENRE}  = $6;
	$self->{YEAR}   = $5;
	$self->{TRACKN} = $3;
	$self->{TIME}   = $4; 
    }

    while ($self->{DATA} =~ m!<tr><td valign=top>\s*(\d+)\.</td><td valign=top> ([^<]*)</td><td><b>([^>]+)</b>!g) {
	$self->{TRACKS}->{$1} = $3;
    }
    $self->{DATA} = undef;
    return $self;
}

1;

__END__

=head1 NAME

Net::CDDBSearch - String search interface to CDDB database

=head1 SYNOPSIS

  use Net::CDDBSearch;

  Grab a list of all albums for 'Megadeth'
  $cddb = Net::CDDBSearch->new();
  $cddb->get_albums_artist('Megadeth');
  $albums = $cddb->albums();

  print @{$albums->{$_}}[0],"\n" foreach keys %{$albums};

=head1 DESCRIPTION

Net::CDDBSearch is an interface to the www.freedb.org website; 
or more specifically to their online search engine for the cddb database. 
Originally based on Net::CDDBScan by David J. Shultz.
This module allows you to take any artist name like 'Madonna' and get all
albums from said artist and all songs and some additional info on ANY album 
said artist has ever worked on. 
[This is assuming the cddb database has a record of the given artist / album / song.]


=head1 USING Net::CDDBSearch

=over 4

=item B<1. Creating a Net::CDDBSearch object>

You first must create a Net::CDDBSearch object.

  my $cddb = Net::CDDBSearch->new();

new() has the following optional parameters:

B<DEBUG>

B<$cddb = Net::CDDBSearch-E<gt>new(DEBUG =E<gt> 1);>

DEBUG: enables debug mode. Debug mode shows all internal function calls,
all urls, albums and songs as it finds them.

=item B<2. Getting a list of all albums of a given artist.>

get_albums_artist()

  $cddb->get_albums_artist('Megadeth');
  $albums = $cddb->albums();
  print @{$albums->{$_}}[0],"\n" foreach keys %{$albums};

Returns a reference to a hash of album urls. The key is the url and the value 
is the reference to array [Artist_Name,Album_Name].


=item B<3. Getting a list of all albums similar to a given album.>

get_albums_album()

  $cddb->get_albums_album('Youthanasia');
  $albums = $cddb->albums();
  print @{$albums->{$_}}[0],"\n" foreach keys %{$albums};

Returns a reference to a hash of album urls. The key is the url and the value 
is the reference to array [Artist_Name,Album_Name].

=item B<4. Getting a track listing and info of a given album.>

get_albums_album()

  $cddb->get_songs_album($album_url);
  $info   = $cddb->info();
  $tracks = $cddb->tracks();

  print "Album info\n";
  print $_,"\t ==> ",$info->{$_},"\n" foreach keys %{$info};
  print "Track list :\n";
  print $_," : ",$tracks->{$_}, "\n" foreach (sort keys %{$tracks});

Method info() returns reference to a hash of album info. The keys are :
Title,Year,Label,Artist. 

Method tracks() returns reference to a hash of album info. The key is the 
track number and the value is track title.

NOTE: $album_url in example above is a result of get_albums_artist() or
get_albums_albums(). This is unique URL to album in freedb.org. Usually it
looks like 'http://www.freedb.org/freedb_search_fmt.php?cat=misc&id=2210a203'

=back


=head1 AUTHOR

Vitaliy Babiy E<lt>admin@mpscope.netE<gt>.

=head1 THANKS

David J. Shultz E<lt>dshultz@redchip.comE<gt> for original module Net::CDDBScan

=head1 COPYRIGHT

This program is free software; you can redistribute it and/or modify it 
under the same terms as Perl itself.

=head1 SEE ALSO

perl(1).

=cut
