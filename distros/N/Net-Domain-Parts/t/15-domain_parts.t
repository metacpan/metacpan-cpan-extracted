#!perl
use 5.006;
use strict;
use warnings;
use Data::Dumper;
use Test::More;

use Net::Domain::Parts;

# Top-level
{
    # No subdomain, single TLD
    {
        my $dns = 'greenrope.com';
        my @a = domain_parts($dns);
        is $a[0], undef, "$dns has no subdomain ok";
        is $a[1], $dns, "$dns domain is $dns ok";
        is $a[2], 'com', "$dns TLD is 'com' ok";
    }

    # Multi subdomains, co.uk TLD
    {
        my $dns = 'this.that.other.co.uk';
        my @a = domain_parts($dns);
        is $a[0], 'this.that', "$dns has proper subdomain ok";
        is $a[1], 'other.co.uk', "$dns has proper domain ok";
        is $a[2], 'co.uk', "$dns has proper TLD ok";
    }

    # No subdomains, co.uk TLD
    {
        my $dns = 'other.co.uk';
        my @a = domain_parts($dns);
        is $a[0], undef, "$dns has proper subdomain ok";
        is $a[1], 'other.co.uk', "$dns has proper domain ok";
        is $a[2], 'co.uk', "$dns has proper TLD ok";
    }

    # No subdomain, hokuto.yamanashi.jp TLD
    {
        my $dns = 'test.hokuto.yamanashi.jp';
        my @a = domain_parts($dns);
        is $a[0], undef, "$dns has proper subdomain ok";
        is $a[1], 'test.hokuto.yamanashi.jp', "$dns has proper domain ok";
        is $a[2], 'hokuto.yamanashi.jp', "$dns has proper TLD ok";
    }

    # Subdomain, hokuto.yamanashi.jp TLD
    {
        my $dns = 'hello.test.hokuto.yamanashi.jp';
        my @a = domain_parts($dns);
        is $a[0], 'hello', "$dns has proper subdomain ok";
        is $a[1], 'test.hokuto.yamanashi.jp', "$dns has proper domain ok";
        is $a[2], 'hokuto.yamanashi.jp', "$dns has proper TLD ok";
    }

    # Subdomain, hokuto.yamanashi.jp TLD with additional TLD
    {
        my $dns = 'hello.test.hokuto.yamanashi.jp.ca';
        my @a = domain_parts($dns);
        is $a[0], 'hello.test.hokuto.yamanashi', "$dns has proper subdomain ok";
        is $a[1], 'jp.ca', "$dns has proper domain ok";
        is $a[2], 'ca', "$dns has proper TLD ok";
    }

    # Domain not found
    {
        my $dns = 'asdf.asdf';
        my @a = domain_parts($dns);
        is $a[0], undef, "$dns subdomain is undef ok";
        is $a[1], undef, "$dns domain is undef ok";
        is $a[2], undef, "$dns TLD is undef ok";
    }

    # Invalid domain
    {
        my $bad_domain_ok = eval {
            domain_parts('asdf');
            1;
        };

        is $bad_domain_ok, undef, "dns_parts() croaks on invalid domain";
        like $@, qr/invalid/, "...and error is sane."
    }

    # No domain
    {
        my $no_domain_ok = eval {
            domain_parts();
            1;
        };

        is $no_domain_ok, undef, "dns_parts() croaks on no domain param";
        like $@, qr/sent in/, "...and error is sane."
    }

}

done_testing();