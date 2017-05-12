#!/usr/bin/perl
# ABSTRACT: bullet-proof rsync wrapper
# PODNAME: bprsync.pl
use strict;
use warnings;

use Sys::Bprsync::Cmd;

my $Cmd = Sys::Bprsync::Cmd::->new();
$Cmd->run();

exit 1;

__END__

=pod

=encoding UTF-8

=head1 NAME

bprsync.pl - bullet-proof rsync wrapper

=head1 NAME

bprsync - bullet-proof rsync wrapper

=head1 AUTHOR

Dominik Schulz <dominik.schulz@gauner.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Dominik Schulz.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
