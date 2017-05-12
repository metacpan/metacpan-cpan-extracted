# $Id: Show.pm 57 2007-01-12 19:26:09Z boumenot $
# Author: Christopher Boumenot <boumenot@gmail.com>
######################################################################
#
# Copyright 2006-2007 by Christopher Boumenot.  This program is free 
# software; you can redistribute it and/or modify it under the same
# terms as Perl itself.
#
######################################################################

package Net::TiVo::Show;

use strict;
use warnings;
use base qw(Net::TiVo::Folder);

use Text::Wrap;

# Should be read as a poor man's XPath
our %DEFAULT_ATTRIBUTES_XPATH = (
    station      => [qw(Details SourceStation)],
    name         => [qw(Details Title)],
    episode      => [qw(Details EpisodeTitle)],
    episode_num  => [qw(Details EpisodeNumber)],                                 
    content_type => [qw(Details ContentType)],
    capture_date => [qw(Details CaptureDate)],    
    format       => [qw(Details SourceFormat)],
    high_definition => [qw(Details HighDefinition)],
    in_progress  => [qw(Details InProgress)],
    size         => [qw(Details SourceSize)],
    channel      => [qw(Details SourceChannel)],
    duration     => [qw(Details Duration)],
    description  => [qw(Details Description)],
    series_id    => [qw(Details SeriesId)],
    program_id   => [qw(Details ProgramId)],
    url          => [qw(Links Content Url)],
);

__PACKAGE__->make_accessor($_) for keys %DEFAULT_ATTRIBUTES_XPATH;
__PACKAGE__->make_accessor($_) for qw(tuner);

sub new {
    my ($class, %options) = @_;
    
    unless ($options{xmlref}) {
        die __PACKAGE__ . ": Mandatory param xmlref missing\n";
    }

    my $self = {
        %options,
    };

    bless $self, $class;

    for my $attr (keys %DEFAULT_ATTRIBUTES_XPATH) {
        my $value = __PACKAGE__->walk_hash_ref($options{xmlref}, $DEFAULT_ATTRIBUTES_XPATH{$attr});
        $self->$attr($value);
    }

    # do a little post processing 
    $self->capture_date(hex($self->capture_date()));

    my ($channel, $tuner) = split(/\-/, $self->channel());
    $tuner = 0 unless defined $tuner;
    $self->channel($channel);
    $self->tuner($tuner);

    return $self;
}

sub as_string {
    my $self = shift;

    $Text::Wrap::columns = 72;

    my @a;
    push @a, $self->name();
    push @a, $self->episode();
    push @a, $self->description();
    push @a, int(($self->duration() / (60 * 1000)) + 0.5) . " min";

    my $s = wrap("", "      ", join(", ", @a));
    $s .= "\n      ".$self->url();

    return $s;
}

1;

__END__

=head1 NAME

C<Net::TiVo::Show> - Class that wraps the XML interface that defines a
TiVo show.

=head1 SYNOPSIS

    use Net::TiVo;
	
    my $tivo = Net::TiVo->new(
        host => '192.168.1.25', 
        mac  => 'MEDIA_ACCESS_KEY'
    );

    for my $folder ($tivo->folders()) {
        for my $show ($folder->shows()) {
            print $show->as_string(), "\n";
        }
    }

=head1 DESCRPTION

C<Net::TiVo::Show> provides an object-oriented interface to an XML description
of a TiVo show.  It provides the necessary accessors to read the XML data. 

=head2 METHODS

=over 4

=item station_name()

Returns TiVo's name for this station, i.e. FoodTV is FOOD.

=item name()

Returns the name of this show.

=item episode()

Returns the title of this show.

=item episode_num()

Returns the episode number of the show.

=item content_type()

Returns the content type of this show in MIME format.

=item capture_date()

Returns the date this show was recorded in seconds since the epoch.

=item format()

Returns the source format of this show.

=item high_definition()

Returns Yes if the show was recorded in high definition, or No if it was not.

=item in_progress()

Returns Yes if the show is currently being recorded, or an empty string
otherwise.  This method can be used in as a predicate.

=item size()

Returns the size of this show in bytes.

=item channel()

Returns the channel this show was recorded on.

=item tuner()

Returns the number of tuner used to record the show.

=item duration()

Returns the duration of this show in milliseconds.

=item description()

Returns the description of this show.

=item program_id()

Returns a hexadecimal string containing the program id.

=item series_id()

Returns a hexadecimal string containing the series id.

=item url()

Returns the url of this show.  This information can be used to download the
episode from TiVo to machine.

=item as_string()

Returns a pretty print of the this show's information, including title, episode
title, description, duration in minutes, and url.

=back

=head1 SEE ALSO

L<Net::TiVo>, L<Net::TiVo::Folder>

=head1 AUTHOR

Christopher Boumenot, E<lt>boumenot@gmail.comE<gt>

=cut
