[![Build Status](https://travis-ci.org/tsucchi/p5-Otogiri-Plugin-Count.svg?branch=master)](https://travis-ci.org/tsucchi/p5-Otogiri-Plugin-Count) [![Coverage Status](https://img.shields.io/coveralls/tsucchi/p5-Otogiri-Plugin-Count/master.svg?style=flat)](https://coveralls.io/r/tsucchi/p5-Otogiri-Plugin-Count?branch=master)
# NAME

Otogiri::Plugin::Count - Otogiri plugin to count rows in database.

# SYNOPSIS

    use Otogiri;
    use Otogiri::Plugin;
    my $db = Otogiri->new( connect_info => [ ... ] );
    $db->load_plugin('Count');
    my $count = $db->count('some_table'); # SELECT COUNT(*) FROM some_table

    my $count2 = $db->count('some_table', 'column1', { group_id => 123 }); # SELECT COUNT(column1) WHERE group_id=123
    my $count3 = $db->count('some_table', { group_id => 123 });            # SELECT COUNT(*) WHERE group_id=123

# DESCRIPTION

Otogiri::Plugin::Count is plugin for [Otogiri](https://metacpan.org/pod/Otogiri) to count database rows.

# LICENSE

Copyright (C) Takuya Tsuchida.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

Takuya Tsuchida <tsucchi@cpan.org>
