# News::Scan::Poster

package News::Scan::Poster;

use strict;
use vars '$VERSION';

use Carp;

$VERSION = '0.51';

sub new {
    my $class = shift;
    my $self  = {};
    my $art;

    croak "usage: ${class}->new(ARTICLE-OBJ)" unless @_ == 1;
    $art = shift;

    $self->{'news_scan_poster_posted_to'}   = {};
    $self->{'news_scan_poster_message_ids'} = [];

    bless $self, $class;
    $self->address($art->author);

    $self->attrib($art->author->format);

    $self->volume($art->size);
    $self->articles(1);
    $self->message_ids($art->message_id);
    $self->posted_to($art);

    $self->header_volume($art->header_size);
    $self->header_lines($art->header_lines);

    $self->body_volume($art->body_size);
    $self->body_lines($art->body_lines);

    $self->orig_volume($art->orig_size);
    $self->orig_lines($art->orig_lines);

    $self->sig_volume($art->sig_size);
    $self->sig_lines($art->sig_lines);

    $self;
}

sub address {
    my $self = shift;

    if (@_) {
        $self->{'news_scan_poster_address'} = shift;
    }
    else {
        return $self->{'news_scan_poster_address'};
    }
}

sub attrib {
    my $self = shift;

    return $self->{'news_scan_poster_attrib'}
        if $self->{'news_scan_poster_attrib'};

    my $addr = $self->{'news_scan_poster_address'};
    return unless $addr;

    my $phrase  = $addr->phrase  || '';
    my $address = $addr->address || '';
    my $comment = $addr->comment || '';

    my $attrib = '';

    for ($phrase, $address, $comment) {
        s/^\s+//;
        s/\s+$//;
    }

    if ($phrase) {
        if ($comment) {
            # expect $comment surrounded by ()
            $attrib = "$phrase $comment";
        }
        else {
            $attrib = $phrase;
        }
    }
    else {
        $attrib = $comment;
        $attrib =~ s/^\(//;
        $attrib =~ s/\)$//;
    }

    if ($attrib) {
        $attrib .= " <$address>";
    }
    else {
        $attrib = $address;
    }

    $self->{'news_scan_poster_attrib'} = $attrib;
}

sub message_ids {
    my $self = shift;

    if (@_) {
        push @{$self->{'news_scan_poster_message_ids'}}, shift;
    }
    else {
        return @{$self->{'news_scan_poster_message_ids'}};
    }
}

sub volume {
    my $self = shift;

    if (@_) {
        $self->{'news_scan_poster_volume'} = shift;
    }
    else {
        return $self->{'news_scan_poster_volume'};
    }
}

sub articles {
    my $self = shift;

    if (@_) {
        $self->{'news_scan_poster_articles'} = shift;
    }
    else {
        return $self->{'news_scan_poster_articles'};
    }
}

sub posted_to {
    my $self = shift;

    if (@_) {
        my $art = shift;
        my %uniq;

        for ($art->newsgroups) {
            $uniq{$_}++;
        }
        delete $uniq{$art->group->name};
        for (keys %uniq) {
            $self->{'news_scan_poster_posted_to'}{$_}++;
        }
    }
    else {
        return %{$self->{'news_scan_poster_posted_to'}};
    }
}

sub crossposts {
    my $self = shift;
    my $total = 0;

    for (keys %{$self->{'news_scan_poster_posted_to'}}) {
        $total += $self->{'news_scan_poster_posted_to'}{$_};
    }

    $total;
}

sub header_volume {
    my $self = shift;

    if (@_) {
        $self->{'news_scan_poster_header_volume'} = shift;
    }
    else {
        return $self->{'news_scan_poster_header_volume'};
    }
}

sub header_lines {
    my $self = shift;

    if (@_) {
        $self->{'news_scan_poster_header_lines'} = shift;
    }
    else {
        return $self->{'news_scan_poster_header_lines'};
    }
}

sub body_volume {
    my $self = shift;

    if (@_) {
        $self->{'news_scan_poster_body_volume'} = shift;
    }
    else {
        return $self->{'news_scan_poster_body_volume'};
    }
}

sub body_lines {
    my $self = shift;

    if (@_) {
        $self->{'news_scan_poster_body_lines'} = shift;
    }
    else {
        return $self->{'news_scan_poster_body_lines'};
    }
}

sub orig_volume {
    my $self = shift;

    if (@_) {
        $self->{'news_scan_poster_orig_volume'} = shift;
    }
    else {
        return $self->{'news_scan_poster_orig_volume'};
    }
}

sub orig_lines {
    my $self = shift;

    if (@_) {
        $self->{'news_scan_poster_orig_lines'} = shift;
    }
    else {
        return $self->{'news_scan_poster_orig_lines'};
    }
}

sub sig_volume {
    my $self = shift;

    if (@_) {
        $self->{'news_scan_poster_sig_volume'} = shift;
    }
    else {
        return $self->{'news_scan_poster_sig_volume'};
    }
}

sub sig_lines {
    my $self = shift;

    if (@_) {
        $self->{'news_scan_poster_sig_lines'} = shift;
    }
    else {
        return $self->{'news_scan_poster_sig_lines'};
    }
}

1;

__END__

=head1 NAME

News::Scan::Poster - keep track of posters to a newsgroup

=head1 SYNOPSIS

    use News::Scan::Poster;

    my $poster = News::Scan::Poster->new($news_scan_article_obj);

=head1 DESCRIPTION

This module provides a class whose objects can be used to keep track of
cumulative statistics for posters to a Usenet newsgroup such as header
volume or signature lines.

=head1 CONSTRUCTOR

=over 4

=item new ( ARTICLE )

C<ARTICLE> should be a C<News::Scan::Article> object or inherit from the
C<News::Scan::Article> class.

C<new> performs some initialization and returns a C<News::Scan::Poster>
object.

=back

=head1 METHODS

=over 4

=item address ( [ ADDRESS ] )

Returns the address of this poster represented as a C<Mail::Internet>
object.

If present, C<ADDRESS> tells the object that the C<Mail::Internet>
object in C<ADDRESS> is its address.
idea.

=item attrib ( [ ATTRIBUTION ] )

Returns some nice attribution for this poster.

If present, C<ATTRIBUTION> tells the object how it shall identify itself
when asked.

=item message_ids ( [ MESSAGE-ID ] )

Returns a list of Message-IDs attributed to this poster.

If present, C<MESSAGE-ID> is added to this list of this poster's articles.

=item volume

Returns the volume in bytes of the traffic generated by this poster.

=item articles

Returns the number of articles attributed to this poster.

=item posted_to

Returns a hash whose keys are newsgroup names and whose values are the
number of times this poster has crossposted to the group of interest
and the corresponding newsgroup.

=item crossposts

Returns the total number of crossposts this poster has sent through the
group of interest.

=item header_volume

Returns the volume in bytes generated by this poster's headers.

=item header_lines

Returns the number of header lines generated by this poster.

=item body_volume

Returns the volume in bytes generated by this poster's message bodies.

=item body_lines

Returns the number of body lines generated by this poster.

=item orig_volume

Returns the volume in bytes of original content generated by this poster.

=item orig_lines

Returns the number of original lines generated by this poster.

=item sig_volume

Returns the volume in bytes generated by this poster's signatures.

=item sig_lines

Returns the number of signature lines generated by this poster.

=back

=head1 SEE ALSO

L<News::Scan>, L<Mail::Address>, L<News::Scan::Article>

=head1 AUTHOR

Greg Bacon <gbacon@cs.uah.edu>

=head1 COPYRIGHT

Copyright (c) 1997 Greg Bacon.  All Rights Reserved.
This library is free software.  You may distribute and/or modify it under
the same terms as Perl itself.

=cut
