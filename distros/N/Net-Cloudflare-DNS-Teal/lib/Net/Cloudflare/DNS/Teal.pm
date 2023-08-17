package Net::Cloudflare::DNS::Teal;

our $VERSION = '0.05';

use 5.006;
use strict;
use warnings;

use Net::Cloudflare::DNS;

# Initialize from environment variables
sub new_from_env {
    my $class = shift;

    my %args = ();

    my $fails = 0;
    my @keys = qw(CLOUDFLARE_ZONE_ID CLOUDFLARE_API_TOKEN CLOUDFLARE_TEAL CLOUDFLARE_GREEN CLOUDFLARE_BLUE);
    for my $key (@keys) {
        if (not defined $ENV{$key}) { print "$key is not set\n"; $fails++; } 
    }
    die "Missing environment variables" if $fails;

    $args{teal} = $ENV{CLOUDFLARE_TEAL};
    $args{blue} = $ENV{CLOUDFLARE_BLUE};
    $args{green} = $ENV{CLOUDFLARE_GREEN};
    my $dns = Net::Cloudflare::DNS->new(api_token=>$ENV{CLOUDFLARE_API_TOKEN}, zone_id=>$ENV{CLOUDFLARE_ZONE_ID});
    $args{dns} = $dns;
    bless \%args, $class;
}

# Initialize from parameters passed to new
sub new {
    my $class = shift;

    my %args = @_;

    my $dns = Net::Cloudflare::DNS->new(api_token=>$args{api_token}, zone_id=>$args{zone_id});
    $args{dns} = $dns;
    bless \%args, $class;
}

# Return live URL
# e.g. "blue.example.com"
sub get_live {
    my $self = shift;

    my $teal = $self->{teal};
    my $blue = $self->{blue};
    my $green = $self->{green};
    my $dns = $self->{dns};

    my $res = $dns->get_records(name=>$teal, type=>'CNAME');
    my $live = $res->{result}->[0]->{content};

    return $live;
}

# Return live color 
# e.g. "blue" 
sub get_live_color {
    my $self = shift;

    my $blue = $self->{blue};
    my $green = $self->{green};

    my $url = $self->get_live();
    return "blue" if ($url eq $blue);
    return "green" if ($url eq $green); 
    # Live is not blue nor green
    return ""; 
}

# Return dormant URL
# e.g. "green.example.com"
sub get_dormant {
    my $self = shift;

    my $teal = $self->{teal};
    my $blue = $self->{blue};
    my $green = $self->{green};
    my $dns = $self->{dns};

    my $res = $dns->get_records(name=>$teal, type=>'CNAME');
    my $live = $res->{result}->[0]->{content};
    my $dormant = $live eq $blue ? $green : $blue; # Actually, both seems dormants (correct init?)

    return $dormant;
}

# Return dormant color
# e.g. "green"
sub get_dormant_color {
    my $self = shift;

    my $blue = $self->{blue};
    my $green = $self->{green};

    my $url = $self->get_dormant();
    return "blue" if ($url eq $blue);
    return "green" if ($url eq $green);
}

# Change target of your entrypoint 
# example.com IN CNAME blue.example.com (or blue.example.pages.dev in case of Cloudflare Pages)
# teal...
# example.com IN CNAME green.example.com (or green.example.pages.dev in case of Cloudflare Pages)
# blue and green stay unchanged, but live and dormant are!
# If your DNS records are proxied (high chance they are), the DNS changes is effective instantly
sub teal {
    my $self = shift;

    my $teal = $self->{teal};
    my $dns = $self->{dns};

    my $res = $dns->get_records(name=>$teal, type=>'CNAME');
    my $erid = $res->{result}->[0]->{id};
    print "live was " . $self->get_live_color() . " (" . $self->get_live() . ")\n";
    $dns->update_record($erid, type=>"CNAME", name=>$teal, content=>$self->get_dormant(), proxied=>\1);
    print "live is now " . $self->get_live_color() . " (" . $self->get_live() . ")\n";
    print "(dormant is " . $self->get_dormant() . ")\n";
}

=head1 NAME

Net::Cloudflare::DNS::Teal - Makes your Blue/Green deployments in Cloudflare easy!

This module is intended to be used for managing Blue/Green deployments in Cloudflare DNS.

It's compatible with Cloudflare Pages, but can be used for wider range of use cases.
(but then think about using a Cloudflare Load Balancer)

Typical use of this module is:

First retrieve dormant to deploy new version of a website/service.

Second, do your tests and/or some canary testing.

Third, replace live version using C<teal()>.

This module comes with small scripts for ease of command line use (e.g. in CircleCI or GitHub Actions)

When used with Cloudflare Pages, don't use custom domains as blue and green values (but directly the *.pages.dev,
e.g. blue.example.pages.dev) as pointing custom domains to another custom domains is not possible.


As of today, this module is NOT production ready.


=head1 VERSION

Version 0.05

=cut



=head1 SYNOPSIS

Net::Cloudflare::DNS::Teal makes your Blue/Green deployments in Cloudflare easy!

Demo

    my $teal = Net::Cloudflare::DNS::Teal->new(zone_id    => $ENV{CLOUDFLARE_ZONE_ID},
                                               api_token  => $ENV{CLOUDFLARE_API_TOKEN},
                                               teal       => $ENV{CLOUDFLARE_TEAL},
                                               blue       => $ENV{CLOUDFLARE_BLUE},
                                               green      => $ENV{CLOUDFLARE_GREEN}
                                              ); 
    # OR
    my $teal = Net::Cloudflare::DNS::Teal->new_from_env(); # Will use environment variables

    my $live = $teal->get_live();
    my $live_color = $teal->get_live_color();
    my $dormant = $teal->get_dormant();
    my $dormant_color = $teal->get_dormant_color();
    $teal->teal();
    ...

=head1 AUTHOR

Thibault DUPONCHELLE, C<< <thibault.duponchelle at gmail.com> >>


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2023 by Thibault DUPONCHELLE.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)


=cut

1; # End of Net::Cloudflare::DNS::Teal
