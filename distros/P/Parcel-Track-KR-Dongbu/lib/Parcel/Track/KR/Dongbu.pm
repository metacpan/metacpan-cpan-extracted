package Parcel::Track::KR::Dongbu;
# ABSTRACT: Parcel::Track driver for the KG Dongbu Express (KG 동부택배)

use utf8;

use Moo;

our $VERSION = '0.001';

with 'Parcel::Track::Role::Base';

use Encode;
use File::Which;
use HTML::Selector::XPath;
use HTML::TreeBuilder::XPath;
use HTTP::Tiny;
use IPC::Open3;

#
# to support HTTPS
#
use IO::Socket::SSL;
use Mozilla::CA;
use Net::SSLeay;

our $URI =
    'https://www.dongbups.com/newHtml/delivery/dvsearch.jsp?mode=SEARCH&search_type=1&sellNum=Y&search_item_no=%s';
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

    my $content;
    if ( exists &Net::SSLeay::CTX_v2_new ) {
        my $http = HTTP::Tiny->new(
            agent       => $AGENT,
            SSL_options => { SSL_version => 'SSLv2', }
        );

        my $res = $http->get( $self->uri );
        print $res->{content};
        unless ( $res->{success} ) {
            $result{result} = 'failed to get parcel tracking info from the site';
            return \%result;
        }

        $content = Encode::encode( 'utf-8', Encode::decode( 'cp949', $res->{content} ) );
    }
    elsif ( my $wget = File::Which::which('wget') ) {
        my ( $stdin, $stdout, $stderr );
        my $pid = open3( $stdin, $stdout, $stderr, $wget, qw( -O - ), $self->uri )
            or die "cannot run $wget process: $!\n";

        waitpid( $pid, 0 );

        my $fetched = do { local $/; <$stdout> };
        $content = Encode::encode( 'utf-8', Encode::decode( 'cp949', $fetched ) );
    }
    else {
        $result{result} =
            'This version of OpenSSL has been compiled without SSLv2 support and there is no wget';
        return \%result;
    }

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

    my $prefix = '/html/body/div[2]/div[2]/div[2]/div[2]/';

    my $html1 = ( $tree->findnodes("$prefix/table") )[0];
    unless ($html1) {
        $result{result} = 'cannot find such parcel info';
        return \%result;
    }

    my $found      = ( $tree->findnodes("$prefix/table/tbody/tr/td[1]") )[0];
    my $found_text = $found ? $found->as_text : q{};
    my $not_found  = Encode::encode_utf8('해당운송장번호는 없습니다');
    if ( $found_text =~ m/$not_found/ ) {
        $result{result} = 'cannot find such parcel info';
        return \%result;
    }

    $result{from}   = $tree->findvalue("$prefix/table/tbody/tr/td[2]");
    $result{to}     = $tree->findvalue("$prefix/table/tbody/tr/td[4]");
    $result{result} = $self->_filter_text( $tree->findvalue("$prefix/table/tbody/tr/td[6]") );
    $result{htmls}  = [ $html1->as_HTML ];
    $result{descs}  = [ $result{result} ];

    return \%result;
}

sub _filter_text {
    my ( $self, $text ) = @_;

    $text =~ s/&nbsp;/ /gms;
    $text =~ s/(^\s+|\s+$)//gms;
    $text =~ s/ +/ /gms;

    return $text;
}

1;

#
# This file is part of Parcel-Track-KR-Dongbu
#
# This software is copyright (c) 2015 by Keedi Kim.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#

__END__

=pod

=encoding UTF-8

=head1 NAME

Parcel::Track::KR::Dongbu - Parcel::Track driver for the KG Dongbu Express (KG ëë¶íë°°)

=head1 VERSION

version 0.001

=head1 SYNOPSIS

    use Parcel::Track;

    # Create a tracker
    my $tracker = Parcel::Track->new( 'KR::Dongbu', '1234-5678-9012' );

    # ID & URI
    print $tracker->id . "\n";
    print $tracker->uri . "\n";
    
    # Track the information
    my $result = $tracker->track;
    
    # Get the information what you want.
    if ( $result ) {
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

L<KG Dongbu Express (KG 동부택배)|https://www.dongbups.com/>

=back

=for :stopwords cpan testmatrix url annocpan anno bugtracker rt cpants kwalitee diff irc mailto metadata placeholders metacpan

=head1 SUPPORT

=head2 Bugs / Feature Requests

Please report any bugs or feature requests through the issue tracker
at L<https://github.com/keedi/Parcel-Track-KR-Dongbu/issues>.
You will be notified automatically of any progress on your issue.

=head2 Source Code

This is open source software.  The code repository is available for
public review and contribution under the terms of the license.

L<https://github.com/keedi/Parcel-Track-KR-Dongbu>

  git clone https://github.com/keedi/Parcel-Track-KR-Dongbu.git

=head1 AUTHOR

김도형 - Keedi Kim <keedi@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Keedi Kim.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
