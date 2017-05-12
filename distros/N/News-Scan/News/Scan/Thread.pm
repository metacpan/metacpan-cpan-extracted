# News::Scan::Thread

package News::Scan::Thread;

use strict;
use vars '$VERSION';

use Carp;

use News::Scan::Article;

$VERSION = '0.51';

sub new {
    my $class = shift;
    my $self  = {};
    my $art   = shift;
    my $subj  = shift;
    
    bless $self, $class;

    $self->subject($subj);
    $self->volume($art->size);
    $self->articles(1);

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

sub subject {
    my $self = shift;

    if (@_) {
        $self->{'news_scan_thread_subject'} = shift;
    }
    else {
        return $self->{'news_scan_thread_subject'};
    }
}

sub volume {
    my $self = shift;

    if (@_) {
        $self->{'news_scan_thread_volume'} = shift;
    }
    else {
        return $self->{'news_scan_thread_volume'};
    }
}

sub articles {
    my $self = shift;

    if (@_) {
        $self->{'news_scan_thread_articles'} = shift;
    }
    else {
        return $self->{'news_scan_thread_articles'};
    }
}

sub header_volume {
    my $self = shift;

    if (@_) {
        $self->{'news_scan_thread_header_volume'} = shift;
    }
    else {
        return $self->{'news_scan_thread_header_volume'};
    }
}

sub header_lines {
    my $self = shift;

    if (@_) {
        $self->{'news_scan_thread_header_lines'} = shift;
    }
    else {
        return $self->{'news_scan_thread_header_lines'};
    }
}

sub body_volume {
    my $self = shift;

    if (@_) {
        $self->{'news_scan_thread_body_volume'} = shift;
    }
    else {
        return $self->{'news_scan_thread_body_volume'};
    }
}

sub body_lines {
    my $self = shift;

    if (@_) {
        $self->{'news_scan_thread_body_lines'} = shift;
    }
    else {
        return $self->{'news_scan_thread_body_lines'};
    }
}

sub orig_volume {
    my $self = shift;

    if (@_) {
        $self->{'news_scan_thread_orig_volume'} = shift;
    }
    else {
        return $self->{'news_scan_thread_orig_volume'};
    }
}

sub orig_lines {
    my $self = shift;

    if (@_) {
        $self->{'news_scan_thread_orig_lines'} = shift;
    }
    else {
        return $self->{'news_scan_thread_orig_lines'};
    }
}

sub sig_volume {
    my $self = shift;

    if (@_) {
        $self->{'news_scan_thread_sig_volume'} = shift;
    }
    else {
        return $self->{'news_scan_thread_sig_volume'};
    }
}

sub sig_lines {
    my $self = shift;

    if (@_) {
        $self->{'news_scan_thread_sig_lines'} = shift;
    }
    else {
        return $self->{'news_scan_thread_sig_lines'};
    }
}

1;

__END__

=head1 NAME

News::Scan::Thread - keep track of threads in a Usenet newsgroup

=head1 SYNOPSIS

    use News::Scan::Thread;

    my $thr = News::Scan::Thread->new($news_scan_article_obj);

=head1 DESCRIPTION

This module provides a class whose objects can be used to keep track
of threads of discussion in a Usenet newsgroup.

=head1 CONSTRUCTOR

=over 4

=item new ( ARTICLE )

C<ARTICLE> should be a C<News::Scan::Article> object or an object of some
class derived from C<News::Scan::Article>.

C<new> performs some initialization and returns a C<News::Scan::Thread>.

=back

=head1 METHODS

=over 4

=item subject

Returns this thread's subject.

=item volume

Returns the volume in bytes generated in this thread.

=item articles

Returns the number of posts to this thread.

=item header_volume

Returns the volume in bytes of the headers in this thread's articles.

=item header_lines

Returns the number of header lines in this thread's articles.

=item body_volume

Returns the volume in bytes of the message bodies of this thread's articles.

=item body_lines

Returns the number of lines in this thread's message bodies.

=item orig_volume

Returns the volume in bytes of the original content of this thread's articles.

=item orig_lines

Returns the number of original lines in this thread's articles.

=item sig_volume

Returns the volume in bytes of the signatures of this thread's articles.

=item sig_lines

Returns the number of signature lines in this thread's articles.

=back

=head1 SEE ALSO

L<News::Scan>, L<News::Scan::Article>

=head1 AUTHOR

Greg Bacon <gbacon@cs.uah.edu>

=head1 COPYRIGHT

Copyright (c) 1997 Greg Bacon.  All Rights Reserved.
This library is free software.  You may distribute and/or modify it under
the same terms as Perl itself.

=cut
