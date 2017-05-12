#!/usr/bin/perl
# ABSTRACT: Monitoring::Reporter PSGI web app
# PODNAME: mreporter-web.psgi
use strict;
use warnings;

use lib '../lib';

use Plack::Builder;
use File::ShareDir;
use Try::Tiny;
use Monitoring::Reporter::Web;

my $Frontend = Monitoring::Reporter::Web::->new();
my $app = sub {
    my $env = shift;

    return $Frontend->run($env);
};

my $static_path = $Frontend->config()->get('Monitoring::Reporter::StaticPath', { Default => 'share/res', });
if(!$static_path || !-d $static_path) {
    my $dist_dir;
    try {
        $dist_dir = File::ShareDir::dist_dir('Monitoring-Reporter');
    };
    if($dist_dir && -d $dist_dir) {
        $static_path = $dist_dir.'/res';
    }
}

builder {
    enable 'Plack::Middleware::Static',
        path => qr{/(img|js|css)/}, root => $static_path;
    $app;
};

__END__

=pod

=encoding utf-8

=head1 NAME

mreporter-web.psgi - Monitoring::Reporter PSGI web app

=head1 AUTHOR

Dominik Schulz <dominik.schulz@gauner.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Dominik Schulz.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
