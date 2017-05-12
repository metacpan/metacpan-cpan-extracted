#!/usr/bin/perl
# ABSTRACT: the monitoring spooler api plack endpoint
# PODNAME: mon-spooler-api.psgi
use strict;
use warnings;

use lib '../lib';

use Monitoring::Spooler::Web::API;

my $Frontend = Monitoring::Spooler::Web::API::->new();
my $app = sub {
    my $env = shift;

    return $Frontend->run($env);
};

__END__

=pod

=encoding utf-8

=head1 NAME

mon-spooler-api.psgi - the monitoring spooler api plack endpoint

=head1 AUTHOR

Dominik Schulz <tex@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Dominik Schulz.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
