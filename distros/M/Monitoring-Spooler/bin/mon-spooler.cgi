#!/usr/bin/perl
# ABSTRACT: the monitoring spooler frontend cgi endpoint
# PODNAME: mon-spooler.cgi
use strict;
use warnings;

use Plack::Loader;

my $app = Plack::Util::load_psgi('mon-spooler.psgi');
Plack::Loader::->auto->run($app);

__END__

=pod

=encoding utf-8

=head1 NAME

mon-spooler.cgi - the monitoring spooler frontend cgi endpoint

=head1 AUTHOR

Dominik Schulz <tex@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Dominik Schulz.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
