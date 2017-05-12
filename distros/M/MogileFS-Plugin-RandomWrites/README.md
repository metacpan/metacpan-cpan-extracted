# NAME

MogileFS::Plugin::RandomWrites - Mogile plugin to distribute files evenly

# SYNOPSIS

In mogilefsd.conf

    plugins = RandomWrites

    mogadm --trackers=$MOGILE_TRACKER class modify <domain> <class> --replpolicy=MultipleHostsRandom\(2\)

# DESCRIPTION

This plugin cause MogileFS to distribute writes to a random device, rather than
concentrating on devices with the most space free.

# SEE ALSO

[MogileFS::Server](http://search.cpan.org/search?mode=module&query=MogileFS::Server)

# AUTHOR

Dave Lambley, <davel@state51.co.uk>

# COPYRIGHT AND LICENSE

Copyright (C) 2012 by Dave Lambley

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.1 or,
at your option, any later version of Perl 5 you may have available.

