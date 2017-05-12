package Mojolicious::Plugin::SemanticUIPageNavigator;
use Mojo::Base 'Mojolicious::Plugin';
use POSIX( qw/ceil/ );
use Mojo::DOM;
use Mojo::ByteStream 'b';
use Modern::Perl;

our $VERSION = 0.03;
# ABSTRACT: Mojolicious::Plugin::SemanticUIPageNavigator


sub register{
  my ($self, $app, $args) = @_;
  $args ||={};

  $app->helper( page_navigator => sub{
    my ( $self, $actual, $count, $opts ) = @_;
    $count = ceil($count);
    return "" unless $count > 1;
    $opts = {} unless $opts;
    my $round = $opts->{round} || 3;
    my $param = $opts->{param} || 'p';
    my $outer = $opts->{outer} || 2;
    my @current = ($actual - $round .. $actual + $round );
    my @first = ( $round > $actual ? (1 .. $round * 3) : (1..$outer) );
    my @tail = ( $count - $round < $actual
      ? ($count - $round * 2 + 1 .. $count)
      : ($count - $outer + 1 .. $count)
    );
    my @ret = ();
    my $last = undef;
    foreach my $number( sort { $a <=> $b} @current, @first, @tail ){
      next if $last && $last == $number;
      next if $number <= 0 ;
      last if $number > $count;
      push @ret, ".." if( $last && $last + 1 != $number );
      push @ret, $number;
      $last = $number;
    }
    my $dom = Mojo::DOM->new('<div class="pagination_outer"><div class="pagination_inner"></div></div>');
    $dom->at('.pagination_outer')->attr({style => "margin: 10px auto; text-align: center"});
    $dom->at('.pagination_inner')->append_content('<a class="semantic_pagination_1">首页</a><a class="semantic_pagination_2">上一页</a>');
    $dom->at('.pagination_inner')->attr({class => 'ui pagination menu'});
    $dom->at(".semantic_pagination_1")->attr( {class => 'item', href => $self->url_for->clone->query($param => 1)} );
    $dom->at(".semantic_pagination_2")->attr( {class => 'item', href => $self->url_for->clone->query($param => $actual - 1)} );
    for my $number ( @ret ){
      if( $number eq '..'){
        $dom->at('.pagination')->append_content('<a class="item">..</a>');
      }else {
        my $tmp_class = "se-pa-a$number";
        $dom->at(".pagination")->append_content("<a class = $tmp_class >$number</a>");
        my $real_class = $number eq $actual ? 'active teal item' : 'item';
        $dom->at(".$tmp_class")->attr( {class => $real_class, href => $self->url_for->clone->query($param => $number) } );
      }
    }
    $dom->at('.pagination')->append_content('<a class="last1">下一页</a><a class="last2">末页</a>');
    $dom->at(".last1")->attr( {class => 'item', href => $self->url_for->clone->query($param => $actual + 1 > $count ? $count : $actual + 1 ) } );
    $dom->at(".last2")->attr( {class => 'item', href => $self->url_for->clone->query($param => $count)} );
    return b($dom);
  });
}

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Mojolicious::Plugin::SemanticUIPageNavigator - Mojolicious::Plugin::SemanticUIPageNavigator

=head1 VERSION

version 0.0.3

=head1 SYNOPSIS

  # Mojolicious::Lite
  plugin 'SemanticUIPageNavigator';

  # Mojolicious
  $self->plugin( 'SemanticUIPageNavigator');

=head1 DESCRIPTION

L<Mojolicious::Plugin::SemanticUIPageNavigator> generates a page navigation bar based on
SemanticUI framework, just like
首页 上一页 1 2 ... 11 12 13 14 15 ... 85 86 下一页 末页

=head1 NAME

Mojolicious::Plugin::SemanticUIPageNavigator - Page Navigator plugin for Mojolicious,
which is dependent on SemanticUI front-end framework. This module is derived from
L<Mojolicious::Plugin::PageNavigator> and L<Mojolicious::Plugin::BootstrapPagination>

=head1 HELPERS

=head2 page_navigator

  %=  page_navigator( $current_page, $total_pages, $opts );

=head3 Options

Options is a optional ref hash.

  %= page_navigator( $current_page, $total_pages,{
      round => 2,
      outer => 2,
      param => 'page',
    });

=over 2

=item round

Number of pages around the current page. Default: 3.

=item outer

Number of outer window pages (first and last pages). Default: 2.

=item param

Name of param for query url. Default: 'p'

=back

=head1 SEE ALSO

L<Mojolicious::Plugin::BootstrapPagination> ande L<Mojolicious::Plugin::PageNavigator>

=head1 Repository

=head1 COPYRIGHT

Copyright (C) Yan Xueqing

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

yanxq <yanxueqing621@163.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by BerryGenomics.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
