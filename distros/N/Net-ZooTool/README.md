NAME
    OO Perl interface to the ZooTool API: zootool.com

USAGE
    my $zoo = Net::ZooTool->new({ apikey   => $config{apikey} });

    my $weekly_popular = $zoo->item->popular({ type => "week" });

    # Info about a specific item
    print Dumper($zoo->item->info({ uid => "6a80z" }));

    # Examples with authenticated calls
    my $auth_zoo = Net::ZooTool->new(
        {
            apikey   => $config{apikey},
            user     => $config{user},
            password => $config{password},
        }
    );

    my $data = $auth_zoo->user->validate({ username => $config{user}, login => 'true' });
    print Dumper($data);

    # In some methods authentication is optional.
    # Public items only
    my $public_items = $auth_zoo->user->items({ username => $config{user} });
    # Include also your private items
    my $all_items = $auth_zoo->user->items({ username => $config{user}, login => 'true' });

DEPENDENCIES
- Moose
- JSON::XS;
- Digest::SHA1
- WWW::Curl::Easy;

VERSION
    version 0.003

AUTHOR
    Josep Roca <quelcomgmail.com>
