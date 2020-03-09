
=head1 DESCRIPTION

This tests the default layout and all of its content sections.

=cut

use Mojo::Base -strict;
use Test::Mojo;
use Test::More;
use Mojolicious;

subtest 'Bootstrap4' => \&test_layout, 'Bootstrap4',
    { version => '4.0.1' },
    ;

subtest 'Bulma' => \&test_layout, 'Bulma',
    { version => '0.8.0' },
    ;

done_testing;

sub test_layout {
    my ( $lib, $conf, %attr ) = @_;
    my $app = Mojolicious->new;
    push @{ $app->renderer->classes }, 'main';
    $app->plugin( Moai => [ $lib, $conf ] );
    $app->routes->get( '/layout-extends-default', {
        layout => 'extends-default',
        template => 'content',
    } );

    $app->routes->get( '/layout-override-container', {
        layout => 'override-container',
        template => 'content',
    } );

    $app->routes->get( '/layout-override-main', {
        layout => 'override-main',
        template => 'content',
    } );

    my $t = Test::Mojo->new( $app );
    $t->get_ok( '/layout-extends-default' )->status_is( 200 )
      ->content_like( qr{<!-- head -->}, 'head content section exists' )
      ->content_like( qr{<!-- navbar -->}, 'navbar content section exists' )
      ->content_like( qr{<!-- hero -->}, 'hero content section exists' )
      ->content_like( qr{<!-- sidebar -->}, 'sidebar content section exists' )
      ->content_like( qr{<!-- footer -->}, 'footer content section exists' )
      ->content_like( qr{<!-- content -->}, 'content helper exists' )
      ;

    ; return;
    $t->get_ok( '/layout-override-main' )->status_is( 200 )
      ->content_like( qr{<!-- main -->}, 'main content section replaced' )
      ->element_exists( 'main', 'main element still exists' )
      ->content_like( qr{<!-- head -->}, 'head content section exists' )
      ->content_like( qr{<!-- navbar -->}, 'navbar content section exists' )
      ->content_like( qr{<!-- hero -->}, 'hero content section exists' )
      ->content_like( qr{<!-- sidebar -->}, 'sidebar content section exists' )
      ->content_like( qr{<!-- footer -->}, 'footer content section exists' )
      ->content_unlike( qr{<!-- content -->}, 'content helper replaced by main' )
      ;

    $t->get_ok( '/layout-override-container' )->status_is( 200 )
      ->content_like( qr{<!-- container -->}, 'container content section replaced' )
      ->content_like( qr{<!-- head -->}, 'head content section exists' )
      ->element_exists( 'header', 'header element still exists' )
      ->content_unlike( qr{<!-- navbar -->}, 'navbar content section replaced by header section' )
      ->content_unlike( qr{<!-- hero -->}, 'hero content section replaced by header section' )
      ->content_unlike( qr{<!-- sidebar -->}, 'sidebar content section replaced by container section' )
      ->content_like( qr{<!-- footer -->}, 'footer content section exists' )
      ->content_unlike( qr{<!-- content -->}, 'content helper replaced by container section' )

      ;
}

__DATA__
@@ content.html.ep
<!-- content -->

@@ layouts/extends-default.html.ep
% extends 'layouts/moai/default';
% content_for head => '<!-- head -->';
% content_for navbar => '<!-- navbar -->';
% content_for hero => '<!-- hero -->';
% content_for sidebar => '<!-- sidebar -->';
% content_for footer => '<!-- footer -->';
<!-- NOT SHOWN -->

@@ layouts/override-main.html.ep
% extends 'layouts/moai/default';
% content_for head => '<!-- head -->';
% content_for navbar => '<!-- navbar -->';
% content_for hero => '<!-- hero -->';
% content_for sidebar => '<!-- sidebar -->';
% content_for footer => '<!-- footer -->';
% content_for main => '<!-- main -->';
<!-- NOT SHOWN -->

@@ layouts/override-container.html.ep
% extends 'layouts/moai/default';
% content_for header => '<!-- header -->';
% content_for container => '<!-- container -->';
% content_for head => '<!-- head -->';
% content_for navbar => '<!-- navbar -->';
% content_for hero => '<!-- hero -->';
% content_for sidebar => '<!-- sidebar -->';
% content_for footer => '<!-- footer -->';
<!-- NOT SHOWN -->
