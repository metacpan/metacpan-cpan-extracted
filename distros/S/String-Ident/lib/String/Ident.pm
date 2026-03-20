package String::Ident;

use warnings;
use strict;
use utf8;

our $VERSION = 0.05;

use Text::Unidecode 'unidecode';
use Scalar::Util 'blessed';

sub new {
    my ( $class, %args ) = @_;
    return bless {
        min_len => $args{min_len},
        max_len => $args{max_len},
    }, $class;
}

sub min_len {
    my ( $self, $new ) = @_;
    $self->{min_len} = $new if @_ > 1;
    $self->{min_len} = 4
        unless defined( $self->{min_len} );
    return $self->{min_len};
}

sub max_len {
    my ( $self, $new ) = @_;
    $self->{max_len} = $new if @_ > 1;
    $self->{max_len} = 30
        unless defined( $self->{max_len} );
    return $self->{max_len};
}

sub cleanup {
    my ( $self, $text, $max_len ) = @_;

    $self = $self->new( max_len => $max_len )
        unless blessed($self);
    $max_len = ( defined($max_len) ? $max_len : $self->max_len );

    $text = '' unless defined($text);
    $text = unidecode($text);
    $text =~ s/[^-A-Za-z0-9]/-/g;
    $text =~ s/--+/-/g;
    $text =~ s/-$//g;
    $text =~ s/^-//g;

    if ( $max_len > 0 ) {
        $text = substr( $text, 0, $max_len );
    }
    while ( length($text) < $self->min_len ) {
        $text .= chr( ord('a') + rand( ord('z') - ord('a') + 1 ) );
    }

    return $text;
}

1;

__END__

=encoding utf8

=head1 NAME

String::Ident - clean up strings for use as identifiers and in URLs

=head1 SYNOPSIS

    my $ident = String::Ident->cleanup('Hello wœrlď!');
    is( $ident, 'Hello-woerld' );

    my $s_ident = String::Ident->new( min_len => 5, max_len => 10 );
    is( $s_ident->cleanup('Hěλλo wœřľδ!'), 'Hello-woer' );

=head1 DESCRIPTION

This module cleans up strings so they can be used as identifiers and in URLs.

=head1 METHODS

=head2 new()

Object constructor. You can set the following options:

=over

=item * min_len

Minimum length of the identifier. Default is 4.

=item * max_len

Maximum length of the identifier. Default is 30.

=back

=head2 min_len()

Accessor for the minimum length. If the cleaned identifier is shorter than this
value, it is padded with random lowercase letters. The default is 4.

=head2 max_len()

Accessor for the maximum length. The default is 30.

=head2 cleanup()

C<cleanup> converts a string into something that you can use as an identifier.
It can be called as a class method, or as an object method created with
C<new>.

It performs the following steps:

    # replace Unicode with ASCII
    $text = unidecode($text);

    # replace anything besides numbers, letters, and dashes with a dash
    $text =~ s/[^-A-Za-z0-9]/-/g;

    # collapse consecutive dashes
    $text =~ s/--+/-/g;

    # remove leading and trailing dashes
    $text =~ s/-$//g;
    $text =~ s/^-//g;

    # apply the maximum length
    $text = substr($text,0,30);

    # pad to the minimum length with random lowercase letters

By default, C<cleanup> truncates the text to 30 characters. You can pass a
different limit as the second argument, or C<-1> to disable truncation:

    String::Ident->cleanup("some very long töxt Lorem ipsum dolor sit amet, consectetur adipiscing elit, ", 20);
    # 'some-very-long-toxt-'

    String::Ident->cleanup("some very long töxt Lorem ipsum dolor sit amet, consectetur adipiscing elit, ", -1);
    # 'some-very-long-toxt-Lorem-ipsum-dolor-sit-amet-consectetur-adipiscing-elit'

=head1 AUTHOR

Jozef Kutej, C<< <jkutej at cpan.org> >>

=head1 CONTRIBUTORS
 
The following people have contributed to the String::Ident by committing their
code, sending patches, reporting bugs, asking questions, suggesting useful
advises, nitpicking, chatting on IRC or commenting on my blog (in no particular
order):

=over

=item * Andrea Pavlovic

=item * Syohei YOSHIDA

=item * Thomas Klausner, C<< <domm@plix.at> >>

=back

=head1 THANKS

Thanks to L<VÖV - Verband Österreichischer Volkshochschulen|http://www.vhs.or.at/>
for sponsoring development of this module.

=head1 LICENSE AND COPYRIGHT

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

