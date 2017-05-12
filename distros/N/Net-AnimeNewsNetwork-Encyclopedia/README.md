# NAME

Net::AnimeNewsNetwork::Encyclopedia - Client library of the AnimeNewsNetwork Encyclopedia API

# SYNOPSIS

    use Net::AnimeNewsNetwork::Encyclopedia;
    

    my $ann = Net::AnimeNewsNetwork::Encyclopedia->new();
    $ann->get_reports(id => 155, type => 'anime');
    $ann->get_details(anime => 4658);

# DESCRIPTION

Net::AnimeNewsNetwork::Encyclopedia is a simple client library of the AnimeNewsNetwork Encyclopedia API. 

[http://www.animenewsnetwork.com/encyclopedia/api.php](http://www.animenewsnetwork.com/encyclopedia/api.php)

# LICENSE

Copyright (C) Ryosuke IWANAGA.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

Ryosuke IWANAGA <riywo.jp@gmail.com>
