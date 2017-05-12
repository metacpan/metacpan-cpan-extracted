package Net::DVDProfiler;

use LWP::UserAgent;
use Net::DVDProfiler::DVD;

our $VERSION = 0.03;

sub new {
  my $ref = shift;
  my $class = ref( $ref ) || $ref;

  my $self = bless {
    lwp => new LWP::UserAgent( cookie_jar => {} ),
    alias => undef,
    @_
  }, $class;

  die "DVDProfiler requires an alias." unless ( $self->{alias} );

  $self->{lwp}->get( 'http://www.dvdprofiler.com/mycollection.asp?alias=' . $self->{alias} );
  $self->{lwp}->get( 'http://www.dvdprofiler.com/mycollection.asp?acceptadult=true&alias=' . $self->{alias} );

  return $self;
}

sub getAll {
  return $_[0]->getList( 'A' );
}

sub getOwned {
  return $_[0]->getList( 'O' );
}

sub getOrdered {
  return $_[0]->getList( 'P' );
}

sub getWishlist {
  return $_[0]->getList( 'W' );
}

sub getList {
  my ( $self, $type ) = @_;

  my @upcs;
  my $page = $u->get( 'http://www.dvdprofiler.com/dvdpro/mycollection/styles/Default/list.asp?type=' . $type )->content();

  while ( $page =~ /id="([^"]*)".*?entry">(.*?)<\/A>/g ) {
    push( @upcs, new Net::DVDProfiler::DVD( upc => $1, title => $2 ) );
  }

  return @upcs;
}
1;

__END__
=pod

=head1 NAME

Net-DVDProfiler - Get the UPC numbers for your DVD collection, located on DVD Profiler.

=head1 DESCRIPTION

This is a module that uses LWP to connect to a remote DVDProfiler collection and acquire all available DVD UPC symbols. Once all the symbols have been acquired, they can then be plugged into another application, such as the module Net::Amazon::DVD2IMDB, to get all the IMDB IDs for the DVDs.

=head1 SYNOPSIS

    # Print out the names of all the movies in your DVD Profiler collection.

    use Net::DVDProfiler;

    my $ua = new Net::DVDProfiler( alias => 'YOURALIAS' );

    print map { $_->title() . "\n" } @{$ua->getAll()};
    
=over 4

=item B<new>

    my $ua = new Net::DVDProfiler( alias => 'YOURALIAS' );
    
Instantiates an object with which to perform further requests. Requires a valid user alias to be provided.

=item B<getAll>, B<getOwned>, B<getOrdered>, and B<getWishlist>

    $ua-getAll();
    
Returns an array of Net::DVDProfiler::DVD objects. Each of the objects have a title and upc method, which can be accessed to receive that information.

=back

=head1 AUTHOR

<a href="http://ejohn.org/">John Resig</a> E<lt>jeresig@gmail.comE<gt>

=head1 DISCLAIMER

This application utilitizes screen-scraping techniques, which are very fickle and susceptable to changes.

=head1 COPYRIGHT

Copyright 2005 John Resig.Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

=cut
