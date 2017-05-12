#!/usr/bin/perl
# ABSTRACT: the monitoring spooler api cgi endpoint
# PODNAME: mon-spooler-api.cgi
use strict;
use warnings;

use Plack::Loader;

my $app = Plack::Util::load_psgi('mon-spooler-api.psgi');
Plack::Loader::->auto->run($app);

__END__

=pod

=encoding utf-8

=head1 NAME

mon-spooler-api.cgi - the monitoring spooler api cgi endpoint

=head1 AUTHOR

Dominik Schulz <tex@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Dominik Schulz.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
