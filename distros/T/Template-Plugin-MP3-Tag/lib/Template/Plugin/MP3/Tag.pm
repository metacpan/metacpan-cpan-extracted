package Template::Plugin::MP3::Tag;

# ----------------------------------------------------------------------
# $Id: Tag.pm,v 1.7 2006/04/24 03:30:05 travail Exp $
# ----------------------------------------------------------------------

use 5.008002;
use strict;
use warnings;
use vars qw ( $VERSION $AUTOLOAD );
use base qw( Template::Plugin );
use MP3::Tag ();
use Template::Plugin;

my $ETYPE = 'plugin.mp3_tag';
$VERSION = '0.01';

sub new {
    my ( $class, $context, $file ) = @_;

    -e $file || $context->throw( $ETYPE, "File '$file' does not exist" );

    my $mp3_tag = MP3::Tag->new( $file )
        || $context->throw( $ETYPE, "Can't create MP3::Tag object for mp3 file '$file'" );

    bless {
        _CONTEXT => $context,
        _FILE    => $file,
        _MP3_TAG => $mp3_tag
    }, $class;
}

sub AUTOLOAD {
    my $self = shift;

    my $method = $AUTOLOAD;
    $method =~ s/.*:://;
    return if ( $method eq 'DESTROY' );

    return $self->{_MP3_TAG}->$method( @_ );
}

sub album {
    my ( $self ) = @_;

    return $self->autoinfo->{album};
}

sub artist {
    my ( $self ) = @_;

    return $self->autoinfo->{artist};
}

sub song {
    my ( $self ) = @_;

    return $self->autoinfo->{song};
}

sub track {
    my ( $self ) = @_;

    return $self->autoinfo->{track};
}

sub title {
    my ( $self ) = @_;

    return $self->autoinfo->{title};
}

sub genre {
    my ( $self ) = @_;

    return $self->autoinfo->{genre};
}

sub year {
    my ( $self ) = @_;

    return $self->autoinfo->{year};
}

1;

__END__

=head1 NAME

Template::Plugin::MP3::Tag - Interface to the MP3::Tag Module

=head1 SYNOPSIS

    [% USE tag = MP3("path_to_mp3_file") %]

    [% tag.title %]
    [% tag.album %]

    # perldoc MP3::Tag for more ideas

=head1 DESCRIPTION

C<Template::Plugin::MP3::Tag> provides a simple wrapper for using
C<MP3::Tag> in object oriented mode; see L<MP3::Tag> for more
details.

Although C<Template::Plugin::MP3> can fetch MP3 files, but it Supports only ID3v1.
When you have to fetch MP3 files ID3v2, I recommend you to use this module.

=head1 CONSTRUCTIR

C<Template::Plugin::MP3::Tag> tales a filename as primary argument:

    [% USE tag = MP3::Tag("path_to_mp3file") %]
    [% tag.album %] 
    [% tag.artist %]

    # If you need encode the tag information,
    # code just like below.

    [% tag.album.jcode.euc %]
    [% tag.artist.jcode.euc %]

=head1 SEE ALSO

L<Template::Plugin>, L<MP3::Tag>

=head1 AUTHOR

Tomoyuki SAWA, E<lt>travail@cabane.no-ip.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 by Tomoyuki SAWA

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.2 or,
at your option, any later version of Perl 5 you may have available.


=cut
