#!/usr/bin/perl
# ABSTRACT: rsync based backup script
# PODNAME: revobackup.pl
use strict;
use warnings;

use Sys::RevoBackup::Cmd;

my $Cmd = Sys::RevoBackup::Cmd::->new();
$Cmd->run();

exit 1;

__END__

=pod

=encoding UTF-8

=head1 NAME

revobackup.pl - rsync based backup script

=head1 NAME

revobackup - rsync based backup

=head1 AUTHOR

Dominik Schulz <dominik.schulz@gauner.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Dominik Schulz.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
