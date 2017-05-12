# NAME

Reply::Plugin::DataDumperAutoEncode - format and decode results using Data::Dumper::AutoEncode

# SYNOPSIS

    ; in your .replyrc use following instead of [DataDumper]
    [DataDumperAutoEncode]

# DESCRIPTION

Reply::Plugin::DataDumperAutoEncode uses [Data::Dumper::AutoEncode](https://metacpan.org/pod/Data::Dumper::AutoEncode) to format and encode results.
Results of [Data::Dumper](https://metacpan.org/pod/Data::Dumper) has decoded string, it is hard to read for human. Using this plugin
instead of [Reply::Plugin::DataDumper](https://metacpan.org/pod/Reply::Plugin::DataDumper), results are automatically decoded and easy to read for human.

# METHODS

## enable\_auto\_encode()

enables auto encode. auto encode is enabled by default.

## disable\_auto\_encode()

disables auto encode

# SEE ALSO

[Reply::Plugin::DataDumper](https://metacpan.org/pod/Reply::Plugin::DataDumper), [Data::Dumper::AutoEncode](https://metacpan.org/pod/Data::Dumper::AutoEncode)

# LICENSE

Copyright (C) Takuya Tsuchida.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

Takuya Tsuchida <tsucchi@cpan.org>
