package Mojo::Ecrawler;

use Mojo::UserAgent;
use 5.010;
use Encode qw(decode encode decode_utf8 encode_utf8);
use Mojo::IOLoop;
use strict;
use warnings;

our @ISA    = qw(Exporter);
our @EXPORT = qw(geturlcontent getdiv gettext);

=encoding utf8

=head1 NAME

Mojo::Ecrawler - A Eeay crawler for html page!

=head1 VERSION

Version 0.04

=cut

our $VERSION = '0.05';

=head1 SYNOPSIS

    use Mojo::Ecrawler;
    $lurl='http://www.oschina.net';
    $re1="div.TodayNews";#scope tag
    $re2="li a";# line tag

   my $pcontent=geturlcontent($lurl);
   my $pcout=getdiv($pcontent,$re1,$re2);
   print $pcout;
    ...

=head1 EXPORT

=head2  getulcontent()

Using Mojo::UserAgent to get the page content。
 
 IN: $url,the page's url.
 OUT:Mojo dom object .

=head2  getdiv()

Get content of  filter using Mojo:DOM

 IN:1,Mojo dom object;
    2,$re1: scope tag(div.xxx div#xxx div xx ..).
    3,$rel: line tag(a hi ..)；

 OUT: the final content. 

=cut

my $DEBUG = 0;
my $host;
sub geturlcontent {
    my $url = shift;
       $host= $1 if $url=~/(http:\/\/[^\/]*)\//;
   my $ua= Mojo::UserAgent->new;
      $ua->transactor->name( 'Mozilla/5.0 (Macintosh; '
          . 'Intel Mac OS X 10_8_5) AppleWebKit/537.36 '
          . '(KHTML, like Gecko) Chrome/29.0.1547.76 Safari/537.36' ); 
   my $recontent;
   my $result = ( $ua->get($url) );
    return $result->res->dom;
}

sub getfile {
my ($url,$filename) = @_;
my $ua = Mojo::UserAgent->new;
   $ua->transactor->name( 'Mozilla/5.0 (Macintosh; '
          . 'Intel Mac OS X 10_8_5) AppleWebKit/537.36 '
          . '(KHTML, like Gecko) Chrome/29.0.1547.76 Safari/537.36' );
my $tx = $ua->get($url);
$tx->res->content->asset->move_to($filename);
}

sub getdiv {

    my ( $dom, $re1, $re2, $ind ) = @_;
    my $recontent;
    my @div = $dom->find($re1)->each;
    for (@div){

    $recontent .= getndiv( $_, $re2, $ind ) if getndiv( $_, $re2, $ind );

    }
    print "DEBUG:getndiv()\::OUT:\n", $recontent if $DEBUG;
    return $recontent;
}

sub getndiv {

    #my $DEBUG=1;
    my ( $st, $re, $ind ) = @_;
    my $ndom = gmyc($st);
    my @ndiv = $ndom->find($re)->each;
    my $nrecontent;
    for (@ndiv) {
        $nrecontent .= $_->content;
        my $surl=$_->attr->{href} if $ind;
       #    $surl =  $host.$surl  unless $surl=~/https?:/;
        $nrecontent .= " ".$surl if $surl;
        $nrecontent .= "\n";
    }
    print "DEBUG:getndiv()\::OUT:\n", $nrecontent if $DEBUG;
    return $nrecontent;

}

sub oplink {
...


}
sub gettext {

    my ( $st, $re ) = @_;
    my $ndom       = gmyc($st);
    my $nrecontent = $ndom->all_text;
   
    $nrecontent .= "\n";
    print "DEBUG:getndiv()\::OUT:\n", $nrecontent if $DEBUG;
    return $nrecontent;

}

sub gmyc {

    my ( $c, $s ) = @_;
    my $dom = $s ? Mojo::DOM->new($c)->at($s) : Mojo::DOM->new($c);
    return $dom;

}

=head1 AUTHOR

ORANGE, C<< <bollwarm at ijz.me> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-mojo-ecrawler at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Mojo-Ecrawler>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Mojo::Ecrawler


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Mojo-Ecrawler>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Mojo-Ecrawler>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Mojo-Ecrawler>

=item * Search CPAN

L<http://search.cpan.org/dist/Mojo-Ecrawler/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2016 ORANGE.

This program is released under the following license: Perl


=cut

1;    # End of Mojo::Ecrawler
