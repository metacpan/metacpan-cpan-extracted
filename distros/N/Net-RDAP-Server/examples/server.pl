#!perl
use Net::RDAP::Server;
use constant ABOUT_URL => 'https://about.rdap.org';
use strict;
use warnings;

my $server = Net::RDAP::Server->new;

$server->set_handler('GET',  'help',   \&get_help);
$server->set_handler('HEAD', 'help',   \&head_help);
$server->set_handler('GET',  'domain', \&get_domain);
$server->set_handler('HEAD', 'domain', \&head_domain);

$server->run;

sub head_help {
    $_[0]->code(200);
    $_[0]->message('OK');
}

sub get_help {
    my $response = shift;

    $response->ok;

    $response->content({
        rdapConformance => [q{rdap_level_0}],
        notices => [
            {
                title => 'More Information',
                description => [ 'For more information, see '.ABOUT_URL.'.'],
                links => [
                    {
                        rel => 'related',
                        href => ABOUT_URL,
                        value => ABOUT_URL,
                    }
                ],
            }
        ]
    });
}

sub head_domain { shift->ok }

sub get_domain {
    my $response = shift;

    my $now = DateTime->now;

    $response->ok;

    $response->content({
        objectClassName => q{domain},
        ldhName => $response->request->object,
    });
}
