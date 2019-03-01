#!/usr/bin/perl
# PODNAME: tapper_reports_web_cgi.pl
# ABSTRACT: Tapper - web gui start script - cgi

use Catalyst::ScriptRunner;
Catalyst::ScriptRunner->run('Tapper::Reports::Web', 'CGI');

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

tapper_reports_web_cgi.pl - Tapper - web gui start script - cgi

=head1 SYNOPSIS

See L<Catalyst::Manual>

=head1 DESCRIPTION

Run a Catalyst application as a cgi script.

=head1 AUTHORS

=over 4

=item *

AMD OSRC Tapper Team <tapper@amd64.org>

=item *

Tapper Team <tapper-ops@amazon.com>

=back

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2019 by Advanced Micro Devices, Inc..

This is free software, licensed under:

  The (two-clause) FreeBSD License

=cut
