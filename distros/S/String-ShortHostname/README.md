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
