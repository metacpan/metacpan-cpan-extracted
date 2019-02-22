# NAME

String::ShortHostname - extracts the first field from an FQDN

# VERSION

version 1.000

# SYNOPSIS

This module will take a fully qualified domain name and return the first field which is normally the
short hostname (mostly equivalent to `hostname -s` on Linux).

    use String::ShortHostname;
    my $fqdn = 'testhost.example.com';
    my $hostname = short_hostname( $fqdn );
    print $hostname; 
    # prints 'testhost'

If an IPv4 address is passed to it, it will be returned verbatim. Otherwise the logic is simply to 
return everything before the first `.`.

Alternatively, it can be used in an OO way, but without much benefit:

    use String::ShortHostname;
    my $fqdn = 'testhost.example.com';
    my $short = String::ShortHostname->new( $fqdn );
    my $hostname = $short->hostname;
    print $hostname; 
    # prints 'testhost'

# BUGS/FEATURES

Please report any bugs or feature requests in the issues section of GitHub: 
[https://github.com/Q-Technologies/perl-String-ShortHostname](https://github.com/Q-Technologies/perl-String-ShortHostname). Ideally, submit a Pull Request.

# AUTHOR

Matthew Mallard <mqtech@cpan.org>

# COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by Matthew Mallard.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
