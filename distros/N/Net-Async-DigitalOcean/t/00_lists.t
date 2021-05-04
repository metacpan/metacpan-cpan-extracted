use strict;
use warnings;

use Test::More;
use Test::Exception;

use Data::Dumper;
$Data::Dumper::Indent = 1;

my $warn = shift @ARGV;
unless ($warn) {
    close STDERR;
    open (STDERR, ">/dev/null");
    select (STDERR); $| = 1;
}

use constant DONE => 1;

use JSON;
use HTTP::Status qw(:constants);

use IO::Async::Loop;
my $loop = IO::Async::Loop->new;

use Net::Async::DigitalOcean;

# $ENV{DIGITALOCEAN_API} //= 'http://0.0.0.0:8080/';

eval {
    Net::Async::DigitalOcean->new( loop => $loop, endpoint => undef );
}; if ($@) {
    plan skip_all => 'no endpoint defined ( e.g. export DIGITALOCEAN_API=http://0.0.0.0:8080/ )';
    done_testing;
}

{ # initalize and reset server state
    my $do = Net::Async::DigitalOcean->new( loop => $loop, endpoint => undef );
    eval {
	$do->meta_reset->get;
    }
}

if (DONE) {
    my $AGENDA = q{images: };

    my $do = Net::Async::DigitalOcean->new( loop => $loop, endpoint => undef );
#     $do->start_actionables( 2 );

    my $f = $do->images;
    isa_ok($f, 'IO::Async::Future', $AGENDA.'first future');

    my $page_size = 6;
    my $page = 0;
    do {
	(my $l, $f) = $f->get;
	isa_ok($f, 'IO::Async::Future', $AGENDA.'followup future') if defined $f;
#warn "list ", Dumper $l;
	if ($page == 0) {
	    ok (! defined $l->{links}->{first}, $AGENDA.'no first link');
	} else {
	    like ($l->{links}->{first}, qr/page=0/, $AGENDA.'first link');
	}
	$page++;
	like ($l->{links}->{next}, qr/$page/, $AGENDA.'next link') if $l->{links}->{next};
	my $s = $l->{meta}->{total}; my $last = int (($s-1) / $page_size);
	like ($l->{links}->{last}, qr/$last/, $AGENDA.'last link') if $l->{links}->{last};
    } while (defined $f);

#-- convenience
    $f = $do->images_all;
    isa_ok($f, 'IO::Async::Future', $AGENDA.'first future');
    my $l = $f->get;
#    is (scalar @{ $l->{images} }, $l->{meta}->{total}, $AGENDA.'all images');
    ok(scalar @$l > 10, $AGENDA.'all images');
#    warn "result ".Dumper $l;

#-- filtered
    $l = $do->images_all(type => 'distribution')->get; # $l = $l->{images};
    ok(scalar @$l > 5, $AGENDA.'various distributions');
#    ok(! (scalar grep { $_->{distribution} !~ /ubuntu|debian|fedora|freebsd|rancher|centos/i} @$l ), $AGENDA.'faked distributions' );
#warn "result ".Dumper [ map { $_ } @$l ]; exit;

    $l = $do->images_all(type => 'application')->get; # $l = $l->{images};
    ok(scalar @$l > 5, $AGENDA.'various applications');
#    ok(! (scalar grep { $_->{distribution} =~ /ubuntu|debian|fedora/i} @$l ), $AGENDA.'faked applications' );

    $l = $do->images_all(tag_name => 'something')->get; # $l = $l->{images};
    ok(! (scalar @$l ), $AGENDA.'no tagged images' );

    $l = $do->images_all(private => 'true')->get; # $l = $l->{images};
    ok(! (scalar @$l ), $AGENDA.'no private images' );
#warn Dumper $l;
}

if (DONE) {
    my $AGENDA = q{sizes: };

    {
	my $do = Net::Async::DigitalOcean->new( loop => $loop, endpoint => undef );

	my $f = $do->sizes;
	isa_ok($f, 'IO::Async::Future', $AGENDA.'future');
	my $json = $f->get;
#warn Dumper $json;
	ok ( (scalar @{ $json->{sizes} }) > 3, $AGENDA.'JSON sizes reasonable');
	map { ok ( exists $_->{slug}, $AGENDA.'JSON fields reasonable' ) } @{ $json->{sizes} };
	is ($json->{meta}->{total}, (scalar @{ $json->{sizes} }), $AGENDA.'total');
    }
    {
	my $do = Net::Async::DigitalOcean->new( loop => $loop, endpoint => 'http://0.0.0.0:8889/' );
	throws_ok {
	    $do->sizes->get;
	} qr/refused/, $AGENDA.'connection problems';

    }
}

if (DONE) {
    my $AGENDA = q{regions: };

    my $do = Net::Async::DigitalOcean->new( loop => $loop, endpoint => undef );

    my $f = $do->regions;
#warn $f;
    isa_ok($f, 'IO::Async::Future', $AGENDA.'future');
    my $json = $f->get;
    ok ( (scalar @{ $json->{regions} }) > 3, $AGENDA.'JSON regions reasonable');
    map { ok ( exists $_->{slug}, $AGENDA.'JSON fields reasonable' ) } @{ $json->{regions} };
    is ($json->{meta}->{total}, (scalar @{ $json->{regions} }), $AGENDA.'total');
#warn Dumper $json;
}

done_testing;

__END__
