package t::cancel;

use strict;
use warnings;

use Test::More;
use Test::Deep;
use Test::FailWarnings;

use Net::Curl::Easy qw(:constants);

use Net::Curl::Promiser::Select;

my $promiser = Net::Curl::Promiser::Select->new();

{
    my @list;

    my $easy = _make_req();

    $promiser->add_handle($easy)->then(
        sub { push @list, [ res => @_ ] },
        sub { push @list, [ rej => @_ ] },
    );

    $promiser->cancel_handle($easy);

    my ($r, $w, $e) = $promiser->get_vecs();

    $promiser->process( $r, $w );

    ($r, $w, $e) = $promiser->get_vecs();

    cmp_deeply(
        [$r, $w, $e],
        array_each( none( re( qr<[^\0]> ) ) ),
        'no vecs are non-NUL',
    );

    is_deeply( \@list, [], 'promise remains pending' ) or diag explain \@list;
}

for my $fail_ar ( [0], ['haha'] ) {
    # diag "fail: " . (explain $fail_ar)[0];

    my @list;

    my $easy = _make_req();

    $promiser->add_handle($easy)->then(
        sub { push @list, [ res => @_ ] },
        sub { push @list, [ rej => @_ ] },
    );

    $promiser->fail_handle($easy, @$fail_ar);

    my ($r, $w, $e) = $promiser->get_vecs();

    $promiser->process( $r, $w );

    ($r, $w, $e) = $promiser->get_vecs();

    cmp_deeply(
        [$r, $w, $e],
        array_each( none( re( qr<[^\0]> ) ) ),
        'no vecs are non-NUL',
    );

    is_deeply(
        \@list,
        [ [ rej => $fail_ar->[0] ] ],
        'promise rejected',
    ) or diag explain \@list;
}

#----------------------------------------------------------------------

sub _make_req {
    my $easy = Net::Curl::Easy->new();
    $easy->setopt( CURLOPT_URL() => "http://example.com" );

    $_ = q<> for @{$easy}{ qw(_head _body) };
    $easy->setopt( CURLOPT_HEADERDATA() => \$easy->{'_head'} );
    $easy->setopt( CURLOPT_FILE() => \$easy->{'_body'} );

    return $easy;
}

done_testing;
