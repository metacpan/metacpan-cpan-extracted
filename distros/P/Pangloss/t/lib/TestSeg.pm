package TestSeg;

use strict;
use warnings;

use Test::More;

use OpenFrame::Request;
use Pipeline::Segment::Tester;

use base qw( Exporter );
our @EXPORT_OK = qw( &test_and_get_view &test_request_setter
		     &test_seg &test_request_decliner );

sub test_seg {
    my $pt = new Pipeline::Segment::Tester();
    my $prod = $pt->test( @_ );
    return wantarray ? ($pt, $prod) : $pt;
}

sub test_and_get_view {
    my $pt = test_seg( @_ );
    return $pt->pipe->store->get('Pangloss::Application::View');
}

sub test_request_setter {
    my $class = shift;
    my $key   = shift;

    if (use_ok($class)) {
	my $req  = OpenFrame::Request->new->arguments({});
	my $seg  = $class->new;
	my ($pt, $prod) = test_seg( $seg, $req );
	ok( $req->arguments->{$key}, " sets $key" );
    }
}

sub test_request_decliner {
    my %args = @_;
    if (use_ok($args{class})) {
	my $seg = $args{class}->new;
	my $req = OpenFrame::Request->new;
	my ($pt, $prod) = test_seg( $seg, $req->arguments( $args{on} ) );
	unlike( $prod, qr/declined/, ' on' );
	($pt, $prod) = test_seg( $seg, $req->arguments( $args{off} ) );
	like( $prod, qr/declined/, ' off' );
    }
}

1;
