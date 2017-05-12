#!/usr/bin/env perl
#
# This file is part of Pod-Browser
#
# This software is Copyright (c) 2012 by Moritz Onken.
#
# This is free software, licensed under:
#
#   The (three-clause) BSD License
#
# PODNAME: pod_browser_cgi.pl
BEGIN { $ENV{CATALYST_ENGINE} ||= 'CGI' }

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../lib";
use Pod::Browser;

Pod::Browser->run;

1;

__END__
=pod

=head1 NAME

pod_browser_cgi.pl

=head1 VERSION

version 1.0.1

=head1 AUTHOR

Moritz Onken <onken@netcubed.de>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2012 by Moritz Onken.

This is free software, licensed under:

  The (three-clause) BSD License

=cut

