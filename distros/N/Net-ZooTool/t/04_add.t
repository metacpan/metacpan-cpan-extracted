use Test::More;

use Net::ZooTool;

BEGIN { use_ok( Config::General, qw/ParseConfig/ ); }

my $config_file = 'auth.conf';

SKIP:
{
    skip("I cannot run tests without $config_file", 3) unless -f $config_file;

    my %config = ParseConfig($config_file);

    my $zoo = Net::ZooTool->new(
        {
            apikey   => $config{apikey},
            user     => $config{user},
            password => $config{password},
        }
    );

=head2
    apikey (required)
    url (required)
    title (required)
    tags (optional) comma separated string of tags
    description (optional)
    referer (optional) must be a valid url
    public (optional) can be 'y' or 'n'
=cut

    my $new_item = $zoo->add(
        {
            url    => 'http://www.google.com',
            title  => 'Mynewsite',
            tags   => 'search engine google',
            public => 'n',
            login => 'true',
        }
    );

    is($new_item->{status}, 'success', 'Item added or already in the zoo');

    my $bad_item = $zoo->add(
        {
            title  => 'Mynewsite',
            tags   => 'search engine google',
            public => 'n',
            login  => 'true',
        }
    );

    is_deeply($bad_item, { msg => 'invalid url', status => 'error' }, 'No url provided');

    my $bad_item2 = $zoo->add(
        {
            url    => 'http://www.google.com',
            title  => 'Mynewsite',
            tags   => 'search engine google',
            public => 'n',
        }
    );

    is_deeply($bad_item2, { msg => 'invalid user', status => 'error' }, 'No login=true');
}

done_testing();
