package Parcel::Track::KR::PostOffice;
# ABSTRACT: Parcel::Track driver for the ePOST Korea (우체국)

use utf8;

use Moo;

our $VERSION = '0.004';

with 'Parcel::Track::Role::Base';

use HTML::Selector::XPath;
use HTML::TreeBuilder::XPath;
use HTTP::Tiny;

#
# to support HTTPS
#
use IO::Socket::SSL;
use Mozilla::CA;
use Net::SSLeay;

our $URI =
    'https://trace.epost.go.kr/xtts/servlet/kpl.tts.common.svl.SttSVL?target_command=kpl.tts.tt.epost.cmd.RetrieveOrderConvEpostPoCMD&sid1=%s';
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

    my $http = HTTP::Tiny->new(
        agent      => $AGENT,
        verify_SSL => 1,
    );

    my $res = $http->get( $self->uri );
    unless ( $res->{success} ) {
        $result{result} = 'failed to get parcel tracking info from the site';
        return \%result;
    }

    #
    # http://stackoverflow.com/questions/19703341/disabling-html-entities-expanding-in-htmltreebuilder-perl-module
    #
    my $tree = HTML::TreeBuilder::XPath->new;
    $tree->ignore_unknown(0);
    $tree->no_expand_entities(1);
    $tree->attr_encoded(1);
    $tree->parse( $res->{content} );
    $tree->eof;

    my $prefix = '/html/body/div/div/div/div';

    my $html1 = ( $tree->findnodes("$prefix/table[1]") )[0];
    my $html2 = ( $tree->findnodes("$prefix/table[2]") )[0];
    my $html3 = ( $tree->findnodes("$prefix/form/table") )[0];
    unless ( $html1 && $html2 && $html3 ) {
        $result{result} = 'cannot find such parcel info';
        return \%result;
    }

    $result{from}   = $tree->findvalue("$prefix/table[1]/tbody/tr[1]/td[1]");
    $result{to}     = $tree->findvalue("$prefix/table[1]/tbody/tr[2]/td");
    $result{result} = sprintf( '%s %s',
        $tree->findvalue("$prefix/table[2]/tbody/tr/td[4]"),
        $tree->findvalue("$prefix/table[2]/tbody/tr/td[5]"),
    );

    $result{htmls} = [ $html1->as_HTML, $html2->as_HTML, $html3->as_HTML ];

    my @elements = $tree->findnodes("$prefix/form/table/tbody/tr");
    for my $e (@elements) {
        my $index = 0;
        my @tds   = $e->look_down(
            '_tag', 'td',
            sub {
                return if $index++ > 3;
                return 1;
            }
        );
        push(
            @{ $result{descs} },
            map {
                my $desc = $_;
                $desc =~ s/(^\s+|\s+$)//gms;
                $desc =~ s/ +/ /gms;
                $desc;
            } join( q{ }, map $_->as_text, @tds ),
        );
    }

    return \%result;
}

1;

#
# This file is part of Parcel-Track-KR-PostOffice
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

Parcel::Track::KR::PostOffice - Parcel::Track driver for the ePOST Korea (ì°ì²´êµ­)

=head1 VERSION

version 0.004

=head1 SYNOPSIS

    use Parcel::Track;

    # Create a tracker
    my $tracker = Parcel::Track->new( 'KR::PostOffice', '12345-6789-0123' );

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

L<ePOST Korea (우체국)|http://www.epost.go.kr>

=back

=for :stopwords cpan testmatrix url annocpan anno bugtracker rt cpants kwalitee diff irc mailto metadata placeholders metacpan

=head1 SUPPORT

=head2 Bugs / Feature Requests

Please report any bugs or feature requests through the issue tracker
at L<https://github.com/keedi/Parcel-Track-KR-PostOffice/issues>.
You will be notified automatically of any progress on your issue.

=head2 Source Code

This is open source software.  The code repository is available for
public review and contribution under the terms of the license.

L<https://github.com/keedi/Parcel-Track-KR-PostOffice>

  git clone https://github.com/keedi/Parcel-Track-KR-PostOffice.git

=head1 AUTHOR

김도형 - Keedi Kim <keedi@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Keedi Kim.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
