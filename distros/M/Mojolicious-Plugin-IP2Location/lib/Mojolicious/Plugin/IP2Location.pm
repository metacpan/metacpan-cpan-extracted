package Mojolicious::Plugin::IP2Location;

our $VERSION = '0.001001'; # VERSION

use Mojo::Base 'Mojolicious::Plugin';
use Geo::IP2Location::Lite;

my %Province_Map = (
    'Alberta'                   => 'AB',
    'British Columbia'          => 'BC',
    'Manitoba'                  => 'MB',
    'New Brunswick'             => 'NB',
    'Newfoundland and Labrador' => 'NL',
    'Northwest Territories'     => 'NT',
    'Nova Scotia'               => 'NS',
    'Nunavut'                   => 'NU',
    'Ontario'                   => 'ON',
    'Prince Edward Island'      => 'PE',
    'Quebec'                    => 'QC',
    'Saskatchewan'              => 'SK',
    'Yukon Territory'           => 'YT',
);

sub register {
    my ($self, $app) = @_;

    state $geo_ip = Geo::IP2Location::Lite->open(
        $app->config('ip2location')
    );

    $app->helper(
        geoip_region=> sub {
            my $c = shift;

            my $is_debug_ip
            = $c->app->mode eq 'development' && $c->param('DEBUG_GEOIP');

            return $c->session('gip_r')
                if not $is_debug_ip and length $c->session('gip_r');

            my $ip = $is_debug_ip
                ? $c->param('DEBUG_GEOIP') : $c->tx->remote_address;

            $c->session(
                gip_r => $Province_Map{ $geo_ip->get_region( $ip ) } // '00'
            );
            return $c->session('gip_r');
        },
    );
}

1;

__END__

=encoding utf8

=for stopwords scalarref RULESETS rulesets subref ruleset

=head1 NAME

Mojolicious::Plugin::IP2Location - Mojolicious wrapper around Geo::IP2Location::Lite

=head1 SYNOPSIS

    #!/usr/bin/env perl

    use Mojolicious::Lite;

    plugin 'IP2Location';

=head1 DESCRIPTION

L<Mojolicious> plugin wrapper for L<Geo::IP2Location::Lite>

=for html  <div style="display: table; height: 91px; background: url(http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/section-warning.png) no-repeat left; padding-left: 120px;" ><div style="display: table-cell; vertical-align: middle;">

This module is released as is to support the release of another
distribution. Proper docs and tests will follow soon.
B<The interface WILL change.>

=for html  </div></div>

=head1 SEE ALSO

L<Geo::IP2Location::Lite>, L<Geo::IP2Location>,
L<http://lite.ip2location.com/database-ip-country-region-city>

=for html <div style="background: url(http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/hr.png);height: 18px;"></div>

=head1 REPOSITORY

=for html  <div style="display: table; height: 91px; background: url(http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/section-github.png) no-repeat left; padding-left: 120px;" ><div style="display: table-cell; vertical-align: middle;">

Fork this module on GitHub:
L<https://github.com/zoffixznet/Mojolicious-Plugin-IP2Location>

=for html  </div></div>

=head1 BUGS

=for html  <div style="display: table; height: 91px; background: url(http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/section-bugs.png) no-repeat left; padding-left: 120px;" ><div style="display: table-cell; vertical-align: middle;">

To report bugs or request features, please use
L<https://github.com/zoffixznet/Mojolicious-Plugin-IP2Location/issues>

If you can't access GitHub, you can email your request
to C<bug-Mojolicious-Plugin-IP2Location at rt.cpan.org>

=for html  </div></div>

=head1 AUTHOR

=for html  <div style="display: table; height: 91px; background: url(http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/section-author.png) no-repeat left; padding-left: 120px;" ><div style="display: table-cell; vertical-align: middle;">

=for html   <span style="display: inline-block; text-align: center;"> <a href="http://metacpan.org/author/ZOFFIX"> <img src="http://www.gravatar.com/avatar/328e658ab6b08dfb5c106266a4a5d065?d=http%3A%2F%2Fwww.gravatar.com%2Favatar%2F627d83ef9879f31bdabf448e666a32d5" alt="ZOFFIX" style="display: block; margin: 0 3px 5px 0!important; border: 1px solid #666; border-radius: 3px; "> <span style="color: #333; font-weight: bold;">ZOFFIX</span> </a> </span>

=for html  </div></div>

=head1 LICENSE

You can use and distribute this module under the same terms as Perl itself.
See the C<LICENSE> file included in this distribution for complete
details.

=cut