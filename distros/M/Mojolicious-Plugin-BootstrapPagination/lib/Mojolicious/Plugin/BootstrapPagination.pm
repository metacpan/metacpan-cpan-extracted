package Mojolicious::Plugin::BootstrapPagination;
use Mojo::Base 'Mojolicious::Plugin';
use POSIX( qw/ceil/ );
use Mojo::ByteStream 'b';

use strict;
use warnings;

our $VERSION = "0.13";

# Homer: Well basically, I just copied the plant we have now.
#        Then, I added some fins to lower wind resistance.  
#        And this racing stripe here I feel is pretty sharp.
# Burns: Agreed.  First prize!
sub  register{
  my ( $self, $app, $args ) = @_;
  $args ||= {};

  $app->helper( bootstrap_pagination => sub{
      my ( $self, $actual, $count, $opts ) = @_;

      my $localize = ( $opts->{localize} || $args->{localize} ) ?
          ( $opts->{localize} || $args->{localize} ) : undef;

      $count = ceil($count);
      return "" unless $count > 1;
      $opts = {} unless $opts;
      my $round = $opts->{round} || $args->{round} || 4;
      my $param = $opts->{param} || $args->{param} || "page";
      my $class = $opts->{class} || $args->{class} || "";
      if ($class ne ""){
          $class = " " . $class;
      }
      my $outer = $opts->{outer} || $args->{outer} || 2;
      my $query = exists $opts->{query} ? $opts->{query} : $args->{query} || "";
      my $start = $opts->{start} // $args->{start} // 1;
      my @current = ( $actual - $round .. $actual + $round );
      my @first   = ($start.. $start + $outer - 1);
      my @tail    = ( $count - $outer + 1 .. $count );
      my @ret = ();
      my $last = undef;
      foreach my $number( sort { $a <=> $b } @current, @first, @tail ){
        next if ( $last && $last == $number && $start > 0 ) || ( defined $last && $last == $number && $start == 0 );
        next if ( $number <= 0 && $start > 0) || ( $number < 0 && $start == 0 );
        last if ( $number > $count && $start > 0 ) || ( $number >= $count && $start == 0 );
        push @ret, ".." if( $last && $last + 1 != $number );
        push @ret, $number;
        $last = $number;
      }
      my $html = "<ul class=\"pagination$class\">";
      if( $actual == $start ){
        $html .= "<li class=\"disabled\"><a href=\"#\" >&laquo;</a></li>";
      } else {
        $html .= "<li><a href=\"" . $self->url_with->query( [$param => $actual - 1] ) . $query . "\" >&laquo;</a></li>";
      }
      my $last_num = -1;
      foreach my $number( @ret ){
        my $show_number = $start > 0 ? $number : ( $number =~ /\d+/ ? $number + 1 : $number );

        if ( $localize ) {
            $show_number = $localize->($self, $show_number);
        }

        if( $number eq ".." && $last_num < $actual ){
          my $offset = ceil( ( $actual - $round ) / 2 ) + 1 ;
          $html .= "<li><a href=\"" . $self->url_with->query( [$param => $start == 0 ? $offset + 1 : $offset] ) . $query ."\" >&hellip;</a></li>";
        }
        elsif( $number eq ".." && $last_num > $actual ) {
          my $back = $count - $outer + 1;
          my $forw = $round + $actual;
          my $offset = ceil( ( ( $back - $forw ) / 2 ) + $forw );
          $html .= "<li><a href=\"" . $self->url_with->query( [$param => $start == 0 ? $offset + 1 : $offset] ) . $query ."\" >&hellip;</a></li>";
        } elsif( $number == $actual ) {
          $html .= "<li class=\"active\"><span>$show_number</span></li>";
        } else {
          $html .= "<li><a href=\"" . $self->url_with->query( [$param => $number] ) . $query ."\">$show_number</a></li>";
        }
         $last_num = $number;
      }
      if( $actual == $count ){
        $html .= "<li class=\"disabled\"><a href=\"" . $self->url_with->query( [$param => $actual + 1] ) . $query . "\" >&raquo;</a></li>";
      } else {
        $html .= "<li><a href=\"" . $self->url_with->query( [$param => $actual + 1] ) . $query . "\" >&raquo;</a></li>";
      }
      $html .= "</ul>";
      return b( $html );
    } );

}

1;
__END__

=encoding utf-8

=head1 NAME

Mojolicious::Plugin::BootstrapPagination - Page Navigator plugin for Mojolicious
This module has derived from L<Mojolicious::Plugin::PageNavigator>

=head1 SYNOPSIS

  # Mojolicious::Lite
  plugin 'bootstrap_pagination'

  # Mojolicious
  $self->plugin( 'bootstrap_pagination' );

=head1 DESCRIPTION

L<Mojolicious::Plugin::BootstrapPagination> generates standard page navigation bar, like 
  
<<  1  2 ... 11 12 13 14 15 ... 85 86 >>

=head1 HELPERS

=head2 bootstrap_pagination

  %= bootstrap_pagination( $current_page, $total_pages, $opts );

=head3 Options

Options is a optional ref hash.

  %= bootstrap_pagination( $current_page, $total_pages, {
      round => 4,
      outer => 2,
      query => "&id=$id",
      start => 1,
      class => 'pagination-lg',
      param => 'page' } );

=over 1

=item round

Number of pages around the current page. Default: 4.

=item outer

Number of outer window pages (first and last pages). Default 2.

=item param

Name of param for query url. Default: 'page'

=item query

Additional query string to url. Optional.

=item start

Start number for query string. Default: 1. Optional.

=back

=head1 INTERNATIONALIZATION

If you want to use internationalization (I18N), you can pass a code reference via I<localize>.

  plugin 'bootstrap_pagination' => {
    localize => \&localize,
  };
  
  sub localize {
    my ($number) = @_;
  
    my %trans = (
      1 => 'one',
      2 => 'two',
      6 => 'six',
      7 => 'seven',
      8 => 'eight',
      9 => 'nine',
     10 => 'ten',
     11 => 'eleven',
     12 => 'twelve',
     13 => 'thirteen',
     14 => 'fourteen',
     15 => 'fifteen',
    );
  
    return $trans{$number};
  }

This will print the words instead of the numbers.

=head1 SEE ALSO

L<Mojolicious>, L<Mojolicious::Guides>, L<http://mojolicio.us>,L<Mojolicious::Plugin::PageNavigator>.

=head1 Repository

https://github.com/dokechin/Mojolicious-Plugin-BootstrapPagination

=head1 LICENSE

Copyright (C) dokechin.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

dokechin E<lt>E<gt>

=head1 CONTRIBUTORS

Andrey Chips Kuzmin <chipsoid@cpan.org>

=cut

