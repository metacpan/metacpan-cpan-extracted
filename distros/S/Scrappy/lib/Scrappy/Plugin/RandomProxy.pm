package Scrappy::Plugin::RandomProxy;

BEGIN {
    $Scrappy::Plugin::RandomProxy::VERSION = '0.94112090';
}

use Moose::Role;

has proxy_address => (
    is  => 'rw',
    isa => 'Str'
);

has proxy_protocol => (
    is      => 'rw',
    isa     => 'Str',
    default => 'HTTP'
);

has proxy_list => (
    is      => 'rw',
    isa     => 'ArrayRef',
    default => sub { [] }
);

sub get_proxy_list {
    my $self = shift;

    # fetch list of HTTP proxies unless already gathered
    unless ($self->proxy_list) {

        # get a proxy from http://www.hidemyass.com/proxy-list/
        $self->user_agent->random_user_agent;

        # goto hidemyass.com
        $self->get('http://www.hidemyass.com/proxy-list/');

        # special post to get HTTP-80 proxies only
        my %headers = (
            'Content-Type' => 'application/x-www-form-urlencoded',
            'Referer'      => 'http://www.hidemyass.com/proxy-list/'
        );
        my $form = {
            'c[]' => [
                'United States',        'Indonesia',
                'China',                'Brazil',
                'Russian Federation',   'Iran, Islamic Republic of',
                'Germany',              'India',
                'Korea, Republic of',   'Kazakhstan',
                'Ukraine',              'Japan',
                'Colombia',             'Thailand',
                'Egypt',                'Taiwan',
                'Spain',                'Canada',
                'Argentina',            'Poland',
                'Czech Republic',       'Turkey',
                'South Africa',         'Venezuela',
                'France',               'Netherlands',
                'Peru',                 'Vietnam',
                'Mexico',               'Switzerland',
                'Bulgaria',             'Kenya',
                'Ecuador',              'Latvia',
                'Portugal',             'Slovakia',
                'Chile',                'Italy',
                'Denmark',              'Moldova, Republic of',
                'United Kingdom',       'Greece',
                'Norway',               'Israel',
                'Hungary',              'Nigeria',
                'Ireland',              'Australia',
                'Hong Kong',            'Finland',
                'Philippines',          'United Arab Emirates',
                'Ghana',                'Bangladesh',
                'Lebanon',              'Romania',
                'Syrian Arab Republic', 'Austria',
                'Sri Lanka',            'Serbia',
                'Sweden',               'Macau',
                'Iraq',                 'Malaysia',
                'Macedonia',            'Malta',
                'Jamaica',              'Niger',
                'Belarus',              'Bahamas',
                'Antarctica',           'Bosnia and Herzegovina',
                'Mozambique',           'Benin',
                'Grenada',              "Cote D'Ivoire",
                'Mauritania',           'Brunei Darussalam',
                'Ethiopia',             'Pakistan',
                'Chad',                 'Paraguay',
                'Puerto Rico',          'Cambodia',
                'Singapore',            'Guatemala',
                'Fiji',                 'Croatia',
                'Kuwait',               'Palestinian Territory',
                'Albania',              'Zimbabwe',
                'Bolivia',              'Maldives',
                'Luxembourg'
            ],
            'pr[]' => ['0'],
            'a[]'  => ['2', '3', '4'],
            p      => '80',
            pl     => 'on',
            s      => '0',
            o      => '0',
            pp     => '3',
            ac     => 'on',
            sortBy => 'date'
        };
        $self->post('http://www.hidemyass.com/proxy-list/', $form, %headers);

        my @proxies = ();
        my $rows    = $self->select('#proxylist-table tr.row')->data;

        foreach my $row (@{$rows}) {
            my $cols = $self->select('td', $row->{html})->data;
            my ($server, $port, $type) =
              ($cols->[1]->{text}, 80, $cols->[6]->{text});
            if ($type eq 'HTTP') {
                push @proxies, "$server:$port";
            }
        }

        $self->proxy_list([@proxies]);
        $self->log(
            "info",
            "Proxy list created from hidemyass.com",
            proxy_list => [@proxies]
        );
    }

    return $self;
}

sub use_random_proxy {
    my $self = shift;

    $self->get_proxy_list;

    # select and use a random a proxy
    my @proxies = @{$self->proxy_list};
    my $proxy   = $proxies[rand(@proxies)];

    $self->proxy_address($proxy);
    $self->proxy('http', 'http://' . $proxy . '/');
    $self->log("info", "Proxy has been set to $proxy using the HTTP protocol");

    return $self;
}

1;
