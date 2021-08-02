
=head1 DESCRIPTION

This tests the pager components

=cut

use Mojo::Base -strict;
use Test::More;
use Test::Mojo;
use Mojolicious;

my %common_selectors = (
    Bootstrap4 => {
        pager_elem => 'ul.pagination',
        prev_elem => 'ul.pagination li:first-child a',
        prev_elem_disabled => 'ul.pagination li:first-child span',
        next_elem => 'ul.pagination li:last-child a',
        next_elem_disabled => 'ul.pagination li:last-child span',
    },
    Bulma => {
        pager_elem => 'nav.pagination',
        prev_elem => 'nav.pagination a.pagination-previous',
        prev_elem_disabled => 'nav.pagination a.pagination-previous[disabled]',
        next_elem => 'nav.pagination a.pagination-next',
        next_elem_disabled => 'nav.pagination a.pagination-next[disabled]',
    },
);

subtest 'Bootstrap4 pager' => \&test_pager,
    'Bootstrap4',
    template => 'moai/pager',
    %{ $common_selectors{ Bootstrap4 } },
    has_pages => 1,
    first_elem => 'ul.pagination li:nth-child(2) > :first-child',
    current_elem => 'ul.pagination li.active span',
    ;

subtest 'Bootstrap4 pager (mini)' => \&test_pager,
    'Bootstrap4',
    template => 'moai/pager/mini',
    %{ $common_selectors{ Bootstrap4 } },
    ;

subtest 'Bulma pager' => \&test_pager,
    'Bulma',
    template => 'moai/pager',
    %{ $common_selectors{ Bulma } },
    has_pages => 1,
    first_elem => 'nav.pagination ul.pagination-list li:first-child a.pagination-link',
    current_elem => 'nav.pagination ul.pagination-list li a.is-current',
    ;

subtest 'Bulma pager (mini)' => \&test_pager,
    'Bulma',
    template => 'moai/pager/mini',
    %{ $common_selectors{ Bulma } },
    ;

done_testing;

sub test_pager {
    my ( $lib, %attr ) = @_;
    my $url = "/$attr{template}";

    my $app = Mojolicious->new;
    $app->plugin( Moai => [ $lib ] );
    $app->routes->get( '/*moai_x_template' )->to( cb => sub {
        my ( $c ) = @_;
        $c->stash( template => $c->param('moai_x_template') );
        $c->stash( map { $_ => $c->param( $_ ) } @{ $c->req->params->names } );
        $c->render;
    } );
    my $t = Test::Mojo->new( $app );

    $t->get_ok( $url, form => { id => 'mypager', current_page => 3, total_pages => 5 } )
      ->status_is( 200 )
      ->or( sub { diag 'Error: ', shift->tx->res->dom->at( '#error,#routes' ) } )
      ->element_exists( $attr{pager_elem}, 'pagination ul exists' )
      ->element_exists( $attr{pager_elem} . '#mypager', 'pagination id is correct' )
      ->element_exists(
        $attr{prev_elem} . "[href^=$url]" . '[href*=page=2]',
        'previous link exists and href is correct',
      )
      ->or( sub { diag shift->tx->res->dom->at( $attr{prev_elem} ) } )
      ->text_like( $attr{prev_elem}, qr{^\s*Previous\s*$}, 'previous link text correct' )
      ->element_exists(
        $attr{next_elem} . "[href^=$url]" . '[href*="page=4"]',
        'next link exists and href is correct',
      )
      ->or( sub { diag shift->tx->res->dom->at( $attr{next_elem} ) } )
      ->text_like( $attr{next_elem}, qr{^\s*Next\s*$}, 'next link text correct' )
      ;

    if ( $attr{ has_pages } ) {
        $t->element_exists(
            $attr{first_elem} . "[href^=$url]" . '[href*="page=1"]',
            '1st page link exists and href is correct',
          )
          ->or( sub { diag shift->tx->res->dom->at( $attr{first_elem} ) } )
          ->text_like( $attr{first_elem}, qr{^\s*1\s*$}, '1st page link text correct' )
          ->element_exists(
            $attr{ current_elem },
            'a current page exists',
          )
          ->or( sub { diag shift->tx->res->dom->at( $attr{current_elem} ) } )
          ->text_like( $attr{ current_elem }, qr{^\s*3\s*$}, 'current page text correct (3)' )
        ;
    }

    $t->get_ok( $url, form => { current_page => 1, total_pages => 5 } )
      ->status_is( 200 )
      ->or( sub { diag 'Error: ', shift->tx->res->dom->at( '#error,#routes' ) } )
      ->element_exists(
        $attr{prev_elem_disabled},
        'previous link is disabled',
      )
      ->or( sub { diag shift->tx->res->dom->at( $attr{prev_elem_disabled} ) } )
      ->text_like( $attr{prev_elem_disabled}, qr{^\s*Previous\s*$}, 'previous link text correct' )

      ->get_ok( $url, form => { current_page => 5, total_pages => 5 } )
      ->status_is( 200 )
      ->or( sub { diag 'Error: ', shift->tx->res->dom->at( '#error,#routes' ) } )
      ->element_exists(
        $attr{next_elem_disabled},
        'next link is disabled',
      )
      ->or( sub { diag shift->tx->res->dom->at( $attr{next_elem_disabled} ) } )
      ->text_like( $attr{next_elem_disabled}, qr{^\s*Next\s*$}, 'next link text correct' )
      ;

    # Defaults to first page
    $t->get_ok( $url, form => { total_pages => 5 } )
      ->status_is( 200 )
      ->or( sub { diag 'Error: ', shift->tx->res->dom->at( '#error,#routes' ) } )
      ->element_exists(
        $attr{prev_elem_disabled},
        'previous link is disabled',
      )
      ->or( sub { diag shift->tx->res->dom->at( $attr{prev_elem_disabled} ) } )
      ->text_like( $attr{prev_elem_disabled}, qr{^\s*Previous\s*$}, 'previous link text correct' )
      ;
    if ( $attr{has_pages} ) {
        my $dom = $t->tx->res->dom;
        is $dom->at( $attr{ first_elem } ), $dom->at( $attr{ current_elem } ),
            'first page is current page by default';
    }
}
