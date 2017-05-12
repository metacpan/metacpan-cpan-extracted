package Net::DVDProfiler::DVD;

sub new {
  my $ref = shift;
  my $class = ref( $ref ) || $ref;

  my $self = bless {
    title => undef,
    upc => undef,
    @_
  }, $class;

  return $self;
}

sub title {
  return $_[0]->{title};
}

sub upc {
  return $_[0]->{upc};
}
1;

__END__
=pod

=head1 NAME

Net-DVDProfiler-DVD - A simple object that represents a DVD on DVDProfiler.

=head1 DESCRIPTION

A simple object that represents a DVD on DVDProfiler. This object will probably be only used by the Net::DVDProfiler module. The most important aspect of this module is its accessors, which you will need.

=head1 SYNOPSIS

    use Net::DVDProfiler::DVD;

    my $dvd = new Net::DVDProfiler::DVD(
        title => 'DVD Title',
        upc => 'UPC Symbol'
    );
    
    print $dvd->title() . "\n";
    
=over 4

=item B<new>

    my $dvd = new Net::DVDProfiler::DVD();
    
Instantiates an object with which to perform further requests. This method will probably not be used.

=item B<title>

    $dvd->title();
    
Returns the title of the DVD.

=item B<upc>

    $dvd->upc();
    
Returns the upc of the DVD.

=back

=head1 AUTHOR

<a href="http://ejohn.org/">John Resig</a> E<lt>jeresig@gmail.comE<gt>

=head1 DISCLAIMER

This application utilitizes screen-scraping techniques, which are very fickle and susceptable to changes.

=head1 COPYRIGHT

Copyright 2005 John Resig.Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

=cut
