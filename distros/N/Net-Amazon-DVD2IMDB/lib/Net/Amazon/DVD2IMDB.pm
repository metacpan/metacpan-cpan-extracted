package Net::Amazon::DVD2IMDB;

use LWP::Simple;
use Net::Amazon;
use Net::Amazon::Request::Keyword;

our $VERSION = 0.03;

sub new {
  my $ref = shift;
  my $class = ref( $ref ) || $ref;

  my $self = bless {
    token => undef,
    amazon => undef,
    @_
  }, $class;

  die "Amazon Token Required" unless ( $self->{token} );

  $self->{amazon} = new Net::Amazon( token => $self->{token} );

  return $self;
}

sub convert {
  my ( $self, @titles ) = @_;
  return $self->asin2imdb( $self->dvd2asin( @titles ) );
}

sub dvd2asin {
  my ( $self, @titles ) = @_;

  @titles = map {
    my $asin = undef;
    my $r = Net::Amazon::Request::Keyword->new( keyword => $_, mode => 'dvd' );
    my $resp = $self->{amazon}->request( $r );

    if( $resp->is_success() ) { 
      foreach my $item ( $resp->properties ) {
        $asin ||= $item->Asin();
      }
    }

    $asin;
  } @titles;

  wantarray ? @titles : $titles[0];
}

sub asin2imdb {
  my ( $self, @asin ) = @_;

  @asin = map { 
    my @found;
    my $page = get( "http://www.amazon.com/exec/obidos/ASIN/$_" );

    while ( $page =~ /imdb.*?\?(\d+)/ig ) {
      push( @found, $1 );
    }

    [ @found ];
  } @asin;

  wantarray ? @asin : $asin[0];
}
1;

__END__
=pod

=head1 NAME

Net-Amazon-DVD2IMDB - Use Amazon to convert a DVD title to an IMDB movie id.

=head1 DESCRIPTION

This is a module that uses Net::Amazon and LWP to acquire the associated IMDB id for a DVD. The way this is done is by using the Amazon API to first search for a DVD (by title) and find the most appropriate ASIN. The results from this are plugged into a method which scrapes the associated Amazon product page, looking for a mention of a particular movie ID (one DVD can have multiple movies associated with it). Due to the second part of this script, it's not entirely 'legit' in the eyes of Amazon, but until they make IMDB id available in their API, this is the best that we can do.

=head1 SYNOPSIS

    # This script takes a DVD title from the command line, looks it
    # up using this script, and returns the associated IMDB ID(s).

    my $token = 'AMAZONTOKEN';
    my $title = join( ' ', @ARGV );

    use Net::Amazon::DVD2IMDB;

    my $ua = new Net::Amazon::DVD2IMDB( token => $token );

    print map { "$_\n" } @{$ua->convert( $title )};
    
=over 4

=item B<new>

    my $dvd2imdb = new Net::Amazon::DVD2IMDB( token => 'AMAZONTOKEN' );
    
Instantiates an object with which to perform the search. Requires a valid Amazon developer token.

=item B<convert>

    $dvd2imdb->convert( 'DVD Title 1', 'DVD Title 2', ... );
    
Takes in an array of DVD titles and returns an array of IMDB ids (see B<asin2imdb> for more information on the output format).

=item B<dvd2asin>

    $dvd2imdb->dvd2asin( 'DVD Title 1', 'DVD Title 2', ... );
    
Takes in an array of DVD titles and returns an array of the most appropriate Amazon Product IDs for each DVD.

=item B<asin2imdb>

    $dvd2imdb->asin2imdb( 'ASIN or SKU 1', 'ASIN or SKU 2', ... );
    
Takes in an array of Amazon Product IDs OR SKU product numbers and returns an array of IMDB ID arrays. The structure of the returned data could look something like this:

    (
        [ 'IMDB ID 1' ],
        [ 'IMDB ID 2', 'IMDB ID 3' ]
    );
    
=back

=head1 AUTHOR

<a href="http://ejohn.org/">John Resig</a> E<lt>jeresig@gmail.comE<gt>

=head1 DISCLAIMER

This application utilitizes screen-scraping techniques, which are very fickle and susceptable to changes (on the part of Amazon). If Amazon decides to changet their site, this module may no longer work.

=head1 COPYRIGHT

Copyright 2004 John Resig.Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

=cut
