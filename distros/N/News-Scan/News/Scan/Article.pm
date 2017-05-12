package News::Scan::Article;

use strict;
use vars qw( $VERSION @ISA );

use Mail::Internet;
use Mail::Address;
use Date::Parse;

$VERSION = '0.51';
@ISA = qw( Mail::Internet );

sub new {
    my $class = shift;
    my $group = pop;
    my $self  = $class->SUPER::new(@_);

    bless $self, $class;

    $self->group($group);
    $self->calculate_sizes;

    if ($self->in_period($group->period)) {
        return $self;
    }
    else {
        return undef;
    }
}

sub in_period {
    my $self = shift;
    my $period = shift(@_) * 60 * 60 * 24;

    my $date = $self->head->get('Date');

    return 0 unless (defined $date and $date);
    chomp $date;

    my $time = str2time $date;
    if ($time < ($^T - $period)) {
        return 0;
    }

    $self->group->earliest($time);
    $self->group->latest($time);

    1;
}

sub group {
    my $self = shift;

    if (@_) {
        my $old = $self->{'news_scan_article_group'};

        $self->{'news_scan_article_group'} = shift;

        return $old;
    }
    else {
        return $self->{'news_scan_article_group'};
    }
}

sub calculate_sizes {
    my $self = shift;

    my $total = 0;
    my $line;

    ## header
    my $header_size = 0;
    foreach $line (@{ $self->head->header }) {
        $header_size += length $line;
        $self->{'news_scan_article_header_lines'}++;
    }

    $total += $header_size;
    $self->{'news_scan_article_header_size'} = $header_size;

    ## add a byte for the separator
    $total++;

    ## signature (if present)
    my @body = @{ $self->body };
    my $sig_start = 0;
    my $found_sig = 0;
    foreach $line (reverse @body) {
        $sig_start--;

        if ($line =~ /^-- $/) {
            $found_sig++;
            last;
        }
    }

    if ($found_sig) {
        my @signature = splice @body, $sig_start;
        shift @signature;  ## toss cutline

        $self->{'news_scan_article_sig_lines'} = @signature;

        my $sig_size = 0;
        foreach $line (@signature) {
            $sig_size += length $line;
        }
        $self->{'news_scan_article_sig_size'} = $sig_size;

        $total += $sig_size;
    }
    else {
        $self->{'news_scan_article_sig_lines'} = 0;
        $self->{'news_scan_article_sig_size'}  = 0;
    }

    ## body
    my $body_size = 0;
    foreach $line (@body) {
        $body_size += length $line;
    }
    $self->{'news_scan_article_body_size'} = $body_size;
    $self->{'news_scan_article_body_lines'} = @body;

    $total += $body_size;
    $self->{'news_scan_article_size'} = $total;

    ## original
    if (my $group = $self->group || 0) {
        my $quote_re = $group->quote_re;

        if ($quote_re) {
            my @orig = grep { ! /$quote_re/o } @body;

            my $orig_size = 0;
            foreach $line (@orig) {
                $orig_size += length $line;
            }
            $self->{'news_scan_article_orig_size'}  = $orig_size;
            $self->{'news_scan_article_orig_lines'} = @orig;
        }
    }
    else {
        $self->{'news_scan_article_orig_size'}  = 0;
        $self->{'news_scan_article_orig_lines'} = 0;
    }
}

sub author {
    my $self = shift;

    my $hd = $self->head || return;

    my $from = $hd->get('Reply-To')
            || $hd->get('From')
            || $hd->get('Sender')
            || "";
    chomp $from;

    my $addr = ( Mail::Address->parse($from) )[0];
    if (exists $self->group->aliases->{lc $addr->address}) {
        ## XXX: Danger, Will Robinson!  Broken Encapsulation Alert!!!
        $addr->[1] = $self->group->aliases->{lc $addr->address};
    }

    unless (defined $addr and ref $addr) {
        return;
    }
    else {
        return $addr;
    }
}

sub message_id {
    my $self = shift;

    my $hdr = $self->head->get('Message-ID');
    chomp $hdr;

    $hdr;
}

sub subject {
    my $self = shift;

    my $hdr = $self->head->get('Subject');
    chomp $hdr;

    $hdr;
}

sub newsgroups {
    my $self = shift;

    my $hdr = $self->head->get('Newsgroups') || '';
    $hdr =~ s/^\s+//;
    $hdr =~ s/\s+$//;

    split /\s*,+\s*/, $hdr;
}

sub size        { $_[0]->{'news_scan_article_size'} }
sub header_size { $_[0]->{'news_scan_article_header_size'} }
sub body_size   { $_[0]->{'news_scan_article_body_size'} }
sub orig_size   { $_[0]->{'news_scan_article_orig_size'} }
sub sig_size    { $_[0]->{'news_scan_article_sig_size'} }

sub header_lines { $_[0]->{'news_scan_article_header_lines'} }
sub body_lines   { $_[0]->{'news_scan_article_body_lines'} }
sub orig_lines   { $_[0]->{'news_scan_article_orig_lines'} }
sub sig_lines    { $_[0]->{'news_scan_article_sig_lines'} }

1;

__END__

=head1 NAME

News::Scan::Article - collect information about news articles

=head1 SYNOPSIS

    use News::Scan::Article;

    my $art = News::Scan::Article->new( ARG, [ OPTIONS, ] SCAN );

=head1 DESCRIPTION

This module provides a derived class of C<Mail::Internet> whose objects
are suitable for digesting Usenet news articles.

=head1 CONSTRUCTOR

=over 4

=item new ( ARG, [ OPTIONS, ] SCAN-OBJ )

The C<ARG> and C<OPTIONS> parameters are identical to those required by
C<Mail::Internet>, except C<ARG> is required.  See L<Mail::Internet>.
The C<SCAN> parameter should be a C<News::Scan> object.  See L<News::Scan>.

If the article falls into the period of interest for C<SCAN>, the object
is returned, else C<undef>.

=back

=head1 METHODS

=over 4

=item group ( [ SCAN-OBJ ] )

Sets or returns an object's group depending on whether C<SCAN-OBJ> is
present.

=item author

Returns the article's author represented as a C<Mail::Address> object.

=item message_id

Returns the article's Message-ID.

=item subject

Returns the article's subject.

=item newsgroups

Returns the list of newsgroups this article was posted to.

=item size

Returns the size of this article in bytes.

=item header_size

Returns the size of this article's header in bytes.

=item header_lines

Returns the number of lines consumed in this article by headers.

=item body_size

Returns the size of this article's body in bytes.

=item body_lines

Returns the number of lines consumed in this article by the body.

=item orig_size

Returns the size of this article's original content in bytes.  See
L<News::Scan/"QuoteRE">.

=item orig_lines

Returns the number of lines consumed in this article by original content.
Keep in mind that original content is a subset of the body.

=item sig_size

Returns the size of this article'ss signature in bytes.

=item sig_lines

Returns the number of lines consumed in this article by the signature.

=back

=head1 SEE ALSO

L<News::Scan>, L<Mail::Internet>, L<Mail::Address>

=head1 AUTHOR

Greg Bacon <gbacon@cs.uah.edu>

=head1 COPYRIGHT

Copyright (c) 1997 Greg Bacon.  All Rights Reserved.
This library is free software.  You may distribute and/or modify it under
the same terms as Perl itself.

=cut
