package Perlbal::Plugin::Expires;

use strict;
use warnings;

our $VERSION = '0.02';

use Perlbal;
use HTTP::Date;

sub load {
    my $class = shift;

    Perlbal::register_global_hook('manage_command.expires' => \&_config_expires);

    return 1;
}

sub register {
    my $class = shift;
    my ($svc) = @_;

    die "Expires plugin must run as web_server role\n"
        unless $svc && $svc->{role} eq 'web_server';

    $svc->register_hook(
        'Expires', 'modify_response_headers', sub { _set_expires($svc, @_) },
    );

    return 1;
}

sub unload {
    my $class = shift;
    
    Perlbal::unregister_global_hook('manage_command.expires');

    return 1;
}

sub unregister {
    my $class = shift;
    my ($svc) = @_;

    $svc->unregister_hooks('Expires');

    return 1;
}

sub _config_expires {
    my $mc = shift->parse(
        qr{^expires\s+(\w+)?\s*(default|[\w\-]+/[\w\-]+)\s*=\s*(\w+)\s+plus\s+(.+)$},
        "usage: Expires [service] <type> = <base> plus (<num> <unit>)+",
    );
    my ($service, $type, $base, $expires) = $mc->args;
    $service ||= $mc->{ctx}{last_created};

    return $mc->err("unknown base time string: $base")
        unless $base eq 'access' || $base eq 'now' || $base eq 'modification';

    my $sec = eval { _expires_to_sec($expires) }
        or return $mc->err($@);

    my $svc = Perlbal->service($service);
    my $config = $svc->{extra_config}->{__expires} ||= {};
    $config->{$type} = {
        base => $base,
        time => $sec,
        orig => $expires,
    };

    return $mc->ok;
}

sub _set_expires {
    my Perlbal::Service        $svc    = shift;
    my Perlbal::ClientHTTPBase $client = shift;
    my Perlbal::HTTPHeaders    $res    = $client->{res_headers} or return;

    return if $res->response_code ne '200';
    return unless exists $svc->{extra_config}{__expires};

    my $type    = $res->header('Content-Type') || 'default';
    my $config  = $svc->{extra_config}{__expires};
    my $expires = $config->{$type} || $config->{default}
        or return;

    my $base = _base_time($expires->{base}, $res->header('Last-Modified'));
    $res->header('Expires', HTTP::Date::time2str($base + $expires->{time}));

    0;
}

sub _base_time {
    my ($type, $last_modified) = @_;

    return ($type eq 'modification' && $last_modified)
         ? HTTP::Date::str2time($last_modified)
         : time
         ;
}

my %__unit2sec = (
    years   => 365 * 24 * 60 * 60,
    year    => 365 * 24 * 60 * 60,
    months  =>  31 * 24 * 60 * 60,
    month   =>  31 * 24 * 60 * 60,
    weeks   =>   7 * 24 * 60 * 60,
    week    =>   7 * 24 * 60 * 60,
    days    =>       24 * 60 * 60,
    day     =>       24 * 60 * 60,
    hours   =>            60 * 60,
    hour    =>            60 * 60,
    minutes =>                 60,
    minute  =>                 60,
    seconds =>                  1,
    second  =>                  1,
);

sub _expires_to_sec {
    my ($expires) = @_;

    my $sec = 0;
    my @a = split /\s+/, $expires;
    while (my ($num, $unit) = splice @a, 0, 2) {
        die "can't parse expires string: $expires\n"
            unless $num =~ /^\d+$/;
        die "unknown time unit '$unit' in '$expires'\n"
            unless exists $__unit2sec{$unit};
        $sec += $num * $__unit2sec{$unit};
    }

    return $sec;
}

sub dumpconfig {
    my $class = shift;
    my ($svc) = @_;

    my $expires = $svc->{extra_config}->{__expires} or return;

    my @config;
    while (my ($type, $expire) = each %$expires) {
        push @config, sprintf(qq{Expires $type = %s plug %s}, $expire->{base}, $expire->{orig});
    }

    return @config;
}

1;
__END__

=pod

=head1 NAME

Perlbal::Plugin::Expires - Apache mod_expires for Perlbal web server

=head1 SYNOPSIS

  LOAD Expires
  CREATE SERVICE web
      SET role    = web_server
      SET listen  = 127.0.0.1:8000
      SET docroot = /path/to/docs
      SET plugins = Expires
      Expires default   = access plus 1 day 12 hours
      Expires image/gif = access plus 10 years
  ENABLE web

=head1 DESCRIPTION

Perlbal::Plugin::Expires is the module to set Expires header to the response
of perlbal webserver the same way as Apache mode_expires.

=head1 CONFIGURATIONS

  Expires [service] <type> = <base> plus (<num> <unit>)+

=over 4

=item * service

You can specify service name explicitly to apply expires.
Default is last created service.

=item * type

Content-Type. Supported MIME Types on Perlbal web server are listed in $Perlbal::ClientHTTPBase::MimeType.

=item * base

B<access>, B<now> (same as access) or B<modification>.

=item * (num unit)+

Datetime string. B<num> should be integer value and B<unit> is one of

  * years
  * months
  * weeks
  * days
  * hours
  * minutes
  * seconds

Last 's' can be omiited.

e.g)

  * 10 years
  * 7 days 1 hour 30 minutes 45 seconds

=back

=head1 SEE ALSO

L<mod_expires|http://httpd.apache.org/docs/2.2/en/mod/mod_expires.html>

=head1 AUTHOR

Hiroshi Sakai E<lt>ziguzagu@cpan.orgE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
