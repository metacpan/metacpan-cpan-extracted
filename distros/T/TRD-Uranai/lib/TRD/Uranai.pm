package TRD::Uranai;

use warnings;
use strict;
use LWP::UserAgent;
use Jcode;

=head1 NAME

TRD::Uranai - Today's Uranai Count down.

=head1 VERSION

Version 0.0.2

=cut

our $VERSION = '0.0.2';


=head1 SYNOPSIS

Quick summary of what the module does.

Perhaps a little code snippet.

    use TRD::Uranai;

    my $uranai = TRD::Uranai::get( 'sjis' );
    TRD::Uranai::dump( $uranai );

=head1 EXPORT

A list of functions that can be exported.  You can delete this section
if you don't export anything, such as for a purely object-oriented module.

=head1 FUNCTIONS

=head2 get

    get today's uranai count down data.

data
    'count' => 12,
    'month' => '08',
    'day' => '01',
    'ranking' => [
        {
            'rank' => '01',
            'image' => 'item/conste_sagittarius.gif',
            'star' => 'いて座',
            'text' => '大活躍',
            'lucky' => [
                {
                    'lucky' => 'カジュアルな服を着る',
                },
            ],
        },
    ],

=cut
#========================================================================
sub get {
	my $encode = (@_) ? shift : 'sjis';
	my $contents = &TRD::Uranai::getPage();
	my $uranai = &TRD::Uranai::parseContents( $contents, $encode );

	$uranai;
}

=head2 dump

=cut
#========================================================================
sub dump {
	my $uranai = shift;

	print "count=". $uranai->{'count'}. "\n";
	print "month=". $uranai->{'month'}. "\n";
	print "day=". $uranai->{'day'}. "\n";
	foreach my $ranking ( @{$uranai->{'ranking'}} ){
		print "\trank=". $ranking->{'rank'}. "\n";
		print "\timage=". $ranking->{'image'}. "\n";
		print "\tstar=". $ranking->{'star'}. "\n";
		print "\ttext=". $ranking->{'text'}. "\n";
		foreach my $lucky ( @{$ranking->{'lucky'}} ){
			print "\t\tlucky=". $lucky->{'lucky'}. "\n";
		}
		print "\n";
	}
}

=head2 parseContents

=cut
#========================================================================
sub parseContents {
	my $contents = shift;
	my $encode = shift;
	my $uranai;
	my $cnt = 0;

	if( $contents=~m#class="day">(\d+)月(\d+)日</td># ){
		$uranai->{'month'} = $1;
		$uranai->{'day'} = $2;
	}
	my @ranks;
	push( @ranks, [$1, $2] ) while( $contents=~s/<table width="306" height="\d+" border="0" cellpadding="0" cellspacing="0" background="item\/rank(\d+)\.gif">(.*?)<\/table>//is );

	foreach my $row ( @ranks ){
		my $item;
		my( $rank, $part ) = @{$row};
		$item->{'rank'} = $rank;
		if( $part=~s# valign="top"><img src='(.+?)' alt='(.+?)' hspace='3'## ){
			$item->{'image'} = $1;
			my $star = $2;
			$star = Jcode::convert( $star, $encode, 'euc' );
			$item->{'star'} = $star;
		} elsif( $part=~s# valign="top"><span class="text"><img src='(.+?)' alt='(.+?)' hspace='3'## ){
			$item->{'image'} = $1;
			my $star = $2;
			$star = Jcode::convert( $star, $encode, 'euc' );
			$item->{'star'} = $star;
		}
		if( $part=~s# class="text">(.+?)</td>## ){
			my $text = $1;
			$text = Jcode::convert( $text, $encode, 'euc' );
			$item->{'text'} = $text;
		}
		while( $part=~s# class="lucky">(.+?)</td>## ){
			my $l = $1;
			$l = Jcode::convert( $l, $encode, 'euc' );
			my $lucky = {'lucky' => $l };
			push( @{$item->{'lucky'}}, $lucky );
		}

		push( @{$uranai->{'ranking'}}, $item );

		$cnt += 1;
	}

	$uranai->{'count'} = $cnt;

	$uranai;
}

=head2 getPage

=cut
#========================================================================
sub getPage {
	my $retval = '';
	my $url = 'http://www.fujitv.co.jp/meza/uranai/index.html';
	my $ua = LWP::UserAgent->new;
	$ua->agent( 'Mozilla' );
	my $request = HTTP::Request->new( GET=>$url );
	my $res = $ua->request( $request );
	if( $res->is_success ){
		$retval = Jcode::convert( $res->content, 'euc', 'sjis' );
	}

	$retval;
}

=head1 AUTHOR

Takuya Ichikawa, C<< <trd.ichi at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-trd-uranai at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=TRD-Uranai>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc TRD::Uranai


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=TRD-Uranai>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/TRD-Uranai>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/TRD-Uranai>

=item * Search CPAN

L<http://search.cpan.org/dist/TRD-Uranai>

=back


=head1 ACKNOWLEDGEMENTS


=head1 COPYRIGHT & LICENSE

Copyright 2008 Takuya Ichikawa, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

1; # End of TRD::Uranai
