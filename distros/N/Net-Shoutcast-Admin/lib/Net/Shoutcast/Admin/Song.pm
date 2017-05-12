package Net::Shoutcast::Admin::Song;
# $Id: Song.pm 315 2008-03-19 00:07:39Z davidp $

use warnings;
use strict;
use Carp;

use vars qw($VERSION);
$VERSION = '0.02';


=head1 NAME

Net::Shoutcast::Admin::Song - object to represent a song


=head1 DESCRIPTION

An object representing a song (either the current song, or an entry in the
song history).  Barely justifies being an object rather than a hashref
at the moment, but at some point I may be able to add other useful methods,
perhaps $song->lyrics to attempt to fetch lyrics.


=head1 SYNOPSIS

    use Net::Shoutcast::Admin;

    my $shoutcast = Net::Shoutcast::Admin->new(
                                    host => 'server hostname',
                                    port => 8000,
                                    admin_password => 'mypassword',
    );
    
    if ($shoutcast->source_connected) {
        my $song = $shoutcast->current_song;
        
        print "Current song is: " . $song->title;
    } else {
        print "No source is currently connected.";
    }
  
  
=head1 DESCRIPTION

Object representing a song, returned by Net::Shoutcast::Admin


=head1 INTERFACE 

=over 4

=item new

There's no reason to create instances of Net::Shoutcast::Admin::Song directly;
Net::Shoutcast::Admin creates and returns instances for you.

Having said that:

  $song = Net::Shoutcast::Admin::Song->new( %params );

Creates a new Net::Shoutcast::Admin object.  Takes a hash of options
as follows:

=over 4

=item I<title>

The title of the song

=item I<played_at>

The timestamp this song started playing.

=back

=cut

sub new {

    my ($class, %params) = @_;
    
    my $self = bless {}, $class;
        
    $self->{last_update} = 0;
    
    my %acceptable_params = map { $_ => 1 } 
        qw(title played_at);
    my %required_params = map { $_ => 1 } 
        qw(title);
    
    
    # make sure we haven't been given any bogus parameters:
    if (my @bad_params = grep { ! $acceptable_params{$_} } keys %params) {
        carp "Net::Shoutcast::Admin::Song does not recognise param(s) "
            . join ',', @bad_params;
        return;
    }
    
    $self->{$_} = $params{$_} for keys %acceptable_params;
    
    if (my @missing_params = grep { ! $self->{$_} } keys %required_params) {
        carp "Net::Shoutcast::Admin->new() must be supplied with params: "
            . join ',', @missing_params;
        return;
    }
    
    return $self;

}


=item title

Returns the artist

=cut

sub title {
    return shift->{title};
}

sub played_at {
    return shift->{played_at};
}



1; # Magic true value required at end of module
__END__


=back

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-net-shoutcast-admin@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.


=head1 AUTHOR

David Precious  C<< <davidp@preshweb.co.uk> >>


=head1 LICENCE AND COPYRIGHT

Copyright (c) 2008, David Precious C<< <davidp@preshweb.co.uk> >>. 
All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.


=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.
