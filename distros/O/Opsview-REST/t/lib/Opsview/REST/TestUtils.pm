package Opsview::REST::TestUtils;

use strict;
use warnings;

require Exporter;
our @ISA = qw/Exporter/;
our @EXPORT = qw/
    get_opsview get_opsview_authtkt test_urls get_random_name get_random_ip
/;

use Opsview::REST;

use Test::More;
use Test::Exception;
use Test::Deep;

sub get_opsview {
    my ($url, $user, $pass, %opts) = 
        (qw( http://localhost/rest admin initial ));

    return Opsview::REST->new(
        base_url => $ENV{OPSVIEW_REST_URL}  || $url,
        user     => $ENV{OPSVIEW_REST_USER} || $user,
        pass     => $ENV{OPSVIEW_REST_PASS} || $pass,
        %opts
    );
}

sub get_opsview_authtkt {
    my ($url, $user, $secret) = (qw(
        http://localhost/rest admin  shared-secret-please-change
    ));

    my $ticket = $ENV{OPSVIEW_REST_AUTHTKT};
    unless (defined $ticket) {
        require Apache::AuthTkt;
        $ticket = Apache::AuthTkt->new(
            secret      => $ENV{OPSVIEW_REST_AUTHTKT_SECRET} || $secret,
            digest_type => 'MD5',
        )->ticket(
            uid     => $user,
            ip_addr => $ENV{OPSVIEW_REST_AUTHTKT_IP} || '127.0.0.1',
        );
    }

    return Opsview::REST->new(
        base_url => $ENV{OPSVIEW_REST_URL}  || $url,
        auth_tkt => $ticket,
        user     => $ENV{OPSVIEW_REST_USER} || $user,
    );
}

sub test_urls {
    my ($class, @tests) = @_;
    for (@tests) {
        if ($_->{die}) {
            dies_ok { $class->new(@{ $_->{args} }); } $_->{die};
        } elsif ($_->{url}) {
            my @args = @{ $_->{args} };
            my $obj = $class->new(@args);

            shift @args if (scalar @args & 1);
            my @r = %{ $obj->uri->query_form_hash };
            cmp_bag(\@r, \@args, $_->{url});
        } elsif ($_->{path}) {
            my @args = @{ $_->{args} };
            my $obj = $class->new(@args);

            my @r = $obj->uri->path_segments;
            @r = splice @r, 2;
            cmp_bag(\@r, \@args, $_->{url});
        } else {
            die "Don't know how to test this";
        }
    };
}

sub get_random_name {
    require String::Random;
    my $sr = String::Random->new;
    return $sr->randregex('\w{8}');
}

sub get_random_ip {
    return join(".", map { int(rand(255)) } (1..4));
}
1;

