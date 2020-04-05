
=head1 DESCRIPTION

This tests the menu navbar

=cut

use Mojo::Base -strict;
use Test::More;
use Test::Mojo;
use Mojolicious;

subtest 'Bootstrap4' => \&test_navbar, 'Bootstrap4',
    navbar_elem => 'nav.navbar',
    brand_elem => '.navbar-brand',
    menu_elem => '.navbar-nav',
    menu_item_elem => 'a.nav-item:nth-child(%d)',
    collapse_elem => '.navbar-collapse',
    toggle_elem => '.navbar-toggler',
    fixed_top => 'nav.navbar.fixed-top',
    fixed_bottom => 'nav.navbar.fixed-bottom',
    sticky_top => 'nav.navbar.sticky-top',
    ;

# XXX
subtest 'Bulma' => \&test_navbar, 'Bulma',
    navbar_elem => 'nav.navbar',
    brand_elem => '.navbar-brand .navbar-item:first-child',
    menu_elem => '.navbar-start',
    menu_item_elem => 'a.navbar-item:nth-child(%d)',
    collapse_elem => '.navbar-menu',
    toggle_elem => '.navbar-burger',
    fixed_top => 'nav.navbar.is-fixed-top',
    fixed_bottom => 'nav.navbar.is-fixed-bottom',
    sticky_top => 'nav.navbar[style*="position: sticky"]',
    # Bulma does not have JavaScript
    ;

done_testing;

sub test_navbar {
    my ( $lib, %attr ) = @_;
    my %test_args;

    my $app = Mojolicious->new;
    $app->plugin( Moai => [ $lib ] );
    for my $path ( qw( home about contact ) ) {
        $app->routes->get( '/' . $path )->name( $path );
    }
    $app->routes->get( '/*template' )->to( cb => sub {
        my ( $c ) = @_;
        $c->stash( %test_args );
        $c->render;
    } );
    my $t = Test::Mojo->new( $app );

    %test_args = (
        id => 'main',
        brand => [ 'My Brand' => 'home' ],
        class => {
            navbar => 'mynav',
        },
        menu => [
            [ 'Home', 'home' ],
            [ 'About', 'about' ],
            [ 'Contact', 'contact' ],
        ],
    );

    $t->get_ok( '/moai/menu/navbar' )
      ->status_is( 200 )
      ->or( sub { diag 'Error: ', shift->tx->res->dom->at( '#error,#routes' ) } )
      # Main element
      ->element_exists(
          $attr{navbar_elem},
          'navbar element exists with correct class',
      )
      ->element_exists(
          $attr{navbar_elem} . '#main',
          'navbar element has correct id',
      )
      ->element_exists(
          $attr{navbar_elem} . '.mynav',
          'navbar element has extra classes',
      )
      # Menu items
      ->element_exists( $attr{ menu_elem }, 'nav menu exists' )
      ->text_like(
        join( ' ', $attr{ menu_elem }, sprintf $attr{ menu_item_elem }, 1 ),
        qr{^\s*Home\s*$},
        'first menu item text correct',
      )
      ->attr_is(
        join( ' ', $attr{ menu_elem }, sprintf $attr{ menu_item_elem }, 1 ),
        href => '/home',
        'first menu item href correct',
      )
      ->text_like(
        join( ' ', $attr{ menu_elem }, sprintf $attr{ menu_item_elem }, 2 ),
        qr{^\s*About\s*$},
        'second menu item text correct',
      )
      ->attr_is(
        join( ' ', $attr{ menu_elem }, sprintf $attr{ menu_item_elem }, 2 ),
        href => '/about',
        'second menu item href correct',
      )
      ->text_like(
        join( ' ', $attr{ menu_elem }, sprintf $attr{ menu_item_elem }, 3 ),
        qr{^\s*Contact\s*$},
        'third menu item text correct',
      )
      ->attr_is(
        join( ' ', $attr{ menu_elem }, sprintf $attr{ menu_item_elem }, 3 ),
        href => '/contact',
        'third menu item href correct',
      )
      # Brand
      ->element_exists( $attr{brand_elem}, 'brand element exists' )
      ->text_like( $attr{brand_elem}, qr{^\s*My Brand\s*$}, 'brand element text correct' )
      ->attr_is(
        $attr{brand_elem},
        href => '/home',
        'brand element href correct',
      )
      # Responsive
      ->element_exists(
        join( ' ', @attr{qw( navbar_elem collapse_elem menu_elem )} ),
        'Nav menu is in responsive collapsible element',
      )
      ->element_exists(
        $attr{ navbar_elem } . ' ' . $attr{toggle_elem},
        'Nav menu has responsive toggle button',
      )
      ;

    delete $test_args{ brand };
    $t->get_ok( '/moai/menu/navbar' )
      ->status_is( 200 )
      ->or( sub { diag 'Error: ', shift->tx->res->dom->at( '#error,#routes' ) } )
      ->element_exists( $attr{navbar_elem}, 'navbar element exists with correct class' )
      ->element_exists_not( $attr{ brand_elem }, 'brand element does not exist' )
      ->or( sub { diag 'Error: ', shift->tx->res->dom->at( $attr{navbar_elem } ) } )
      ;

    $test_args{ position } = 'fixed-top';
    $t->get_ok( '/moai/menu/navbar' )
      ->status_is( 200 )
      ->or( sub { diag 'Error: ', shift->tx->res->dom->at( '#error,#routes' ) } )
      ->element_exists(
        $attr{ fixed_top },
        'navbar element exists with correct class (fixed top)',
      )
      ->or( sub { diag shift->tx->res->dom->at( $attr{navbar_elem} ) } )
      ->element_exists_not( $attr{ brand_elem }, 'brand element does not exist' )
      ->or( sub { diag 'Error: ', shift->tx->res->dom->at( $attr{navbar_elem } ) } )
      ;

    $test_args{ position } = 'fixed';
    $t->get_ok( '/moai/menu/navbar' )
      ->status_is( 200 )
      ->or( sub { diag 'Error: ', shift->tx->res->dom->at( '#error,#routes' ) } )
      ->element_exists(
        $attr{ fixed_top },
        'navbar element exists with correct class (fixed is fixed top)',
      )
      ;

    $test_args{ position } = 'fixed-bottom';
    $t->get_ok( '/moai/menu/navbar' )
      ->status_is( 200 )
      ->or( sub { diag 'Error: ', shift->tx->res->dom->at( '#error,#routes' ) } )
      ->element_exists(
        $attr{ fixed_bottom },
        'navbar element exists with correct class (fixed bottom)',
      )
      ->or( sub { diag shift->tx->res->dom->at( $attr{navbar_elem} ) } )
      ;

    # position sticky-top
    $test_args{ position } = 'sticky-top';
    $t->get_ok( '/moai/menu/navbar' )
      ->status_is( 200 )
      ->or( sub { diag 'Error: ', shift->tx->res->dom->at( '#error,#routes' ) } )
      ->element_exists(
        $attr{ sticky_top },
        'navbar element exists with correct class (sticky top)',
      )
      ;

    $test_args{ position } = 'sticky';
    $t->get_ok( '/moai/menu/navbar' )
      ->status_is( 200 )
      ->or( sub { diag 'Error: ', shift->tx->res->dom->at( '#error,#routes' ) } )
      ->element_exists(
        $attr{ sticky_top },
        'navbar element exists with correct class (sticky is sticky top)',
      )
      ->or( sub { diag shift->tx->res->dom->at( $attr{navbar_elem} ) } )
      ;
}
