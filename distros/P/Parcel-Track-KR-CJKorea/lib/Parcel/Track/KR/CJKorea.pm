package Parcel::Track::KR::CJKorea;
# ABSTRACT: Parcel::Track driver for the CJ Korea Express (CJ 대한통운)

use utf8;

use Moo;

our $VERSION = '0.004';

with 'Parcel::Track::Role::Base';

use Encode;
use File::Which;
use HTML::Selector::XPath;
use HTML::TreeBuilder::XPath;
use HTTP::Tiny;

#
# to support HTTPS
#
use IO::Socket::SSL;
use Mozilla::CA;

our $URI =
    'https://www.doortodoor.co.kr/parcel/doortodoor.do?fsp_action=PARC_ACT_002&fsp_cmd=retrieveInvNoACT&invc_no=%s';

our $AGENT = 'Mozilla/4.0 (compatible; MSIE 6.0; Windows NT 5.1)';

sub BUILDARGS {
    my ( $class, @args ) = @_;

    my %params;
    if ( ref $args[0] eq 'HASH' ) {
        %params = %{ $args[0] };
    }
    else {
        %params = @args;
    }
    $params{id} =~ s/\D//g;

    return \%params;
}

sub uri { sprintf( $URI, $_[0]->id ) }

sub track {
    my $self = shift;

    my %result = (
        from   => q{},
        to     => q{},
        result => q{},
        htmls  => [],
        descs  => [],
    );

    my $http = HTTP::Tiny->new( agent => $AGENT );
    my $res = $http->get( $self->uri );

    unless ( $res->{success} ) {
        $result{result} = 'failed to get parcel tracking info from the site';
        return \%result;
    }

    my $content = Encode::decode_utf8( $res->{content} );

    unless ($content) {
        $result{result} = 'failed to tracking parcel info';
        return \%result;
    }

    #
    # http://stackoverflow.com/questions/19703341/disabling-html-entities-expanding-in-htmltreebuilder-perl-module
    #
    my $tree = HTML::TreeBuilder::XPath->new;
    $tree->ignore_unknown(0);
    $tree->no_expand_entities(1);
    $tree->attr_encoded(1);
    $tree->parse($content);
    $tree->eof;

    my $prefix = '/html/body/div/div[2]/div/div[2]/ul/li[1]/div';

    my $html1 = ( $tree->findnodes("$prefix/div[1]/div/table") )[0];
    my $html2 = ( $tree->findnodes("$prefix/div[2]/div/table") )[0];
    unless ( $html1 && $html2 ) {
        $result{result} = 'cannot find such parcel info';
        return \%result;
    }

    my $found      = ( $tree->findnodes("$prefix/div[2]/div/table/tr[2]/td") )[0];
    my $found_text = $found ? $found->as_text : q{};
    my $not_found  = Encode::encode_utf8('조회된 데이터가 없습니다');
    if ( $found_text =~ m/$not_found/ ) {
        $result{result} = 'cannot find such parcel info';
        return \%result;
    }

    $result{from}  = $tree->findvalue("$prefix/div[1]/div/table/tr[2]/td[2]");
    $result{to}    = $tree->findvalue("$prefix/div[1]/div/table/tr[2]/td[3]");
    $result{htmls} = [ $html1->as_HTML, $html2->as_HTML ];

    my @elements  = $tree->findnodes("$prefix/div[2]/div/table/tr");
    my $row_index = 0;
    for my $e (@elements) {
        next if $row_index++ == 0;

        my @tds = $e->look_down( '_tag', 'td' );
        push @{ $result{descs} }, join( q{ }, map $_->as_text, @tds[ 1, 0, 3, 2 ] );

        $result{result} = join( q{ }, map $_->as_text, @tds[ 1, 0 ] );
    }

    return \%result;
}

1;

#
# This file is part of Parcel-Track-KR-CJKorea
#
# This software is copyright (c) 2016 by Keedi Kim.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#

__END__

=pod

=encoding UTF-8

=head1 NAME

Parcel::Track::KR::CJKorea - Parcel::Track driver for the CJ Korea Express (CJ ëííµì´)

=head1 VERSION

version 0.004

=head1 SYNOPSIS

    use Parcel::Track;

    # Create a tracker
    my $tracker = Parcel::Track->new( 'KR::CJKorea', '808-123-4567' );

    # ID & URI
    print $tracker->id . "\n";
    print $tracker->uri . "\n";

    # Track the information
    my $result = $tracker->track;

    # Get the information what you want.
    if ( $result ) {
        print "Message sent ok\n";
        print "$result->{from}\n";
        print "$result->{to}\n";
        print "$result->{result}\n";
        print "$_\n" for @{ $result->{descs} };
        print "$_\n" for @{ $result->{htmls} };
    }
    else {
        print "Failed to track information\n";
    }

=head1 ATTRIBUTES

=head2 id

=head1 METHODS

=head2 track

=head2 uri

=for Pod::Coverage BUILDARGS

=head1 SEE ALSO

=over 4

=item *

L<Parcel::Track>

=item *

L<CJ Korea Express (CJ 대한통운)|https://www.doortodoor.co.kr>

=back

=for :stopwords cpan testmatrix url annocpan anno bugtracker rt cpants kwalitee diff irc mailto metadata placeholders metacpan

=head1 SUPPORT

=head2 Bugs / Feature Requests

Please report any bugs or feature requests through the issue tracker
at L<https://github.com/keedi/Parcel-Track-KR-CJKorea/issues>.
You will be notified automatically of any progress on your issue.

=head2 Source Code

This is open source software.  The code repository is available for
public review and contribution under the terms of the license.

L<https://github.com/keedi/Parcel-Track-KR-CJKorea>

  git clone https://github.com/keedi/Parcel-Track-KR-CJKorea.git

=head1 AUTHOR

김도형 - Keedi Kim <keedi@cpan.org>

=head1 CONTRIBUTOR

=for stopwords 홍형석 - Hyungsuk Hong

홍형석 - Hyungsuk Hong <aanoaa@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Keedi Kim.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
