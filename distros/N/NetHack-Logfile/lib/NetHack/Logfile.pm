package NetHack::Logfile;
our $VERSION = '1.00';

use strict;
use warnings;
use Carp 'croak';
use NetHack::Logfile::Entry;

use Sub::Exporter -setup => {
    exports => [qw(read_logfile parse_logline write_logfile)],
};

sub read_logfile {
    my $filename = @_ ? shift : "logfile";
    my @entries;

    open my $handle, '<', $filename
        or croak "Unable to open $filename for reading: $!";

    while (<$handle>) {
        push @entries, parse_logline($_);
    }

    close $handle
        or croak "Unable to close $filename handle: $!";

    return @entries;
}

sub parse_logline { NetHack::Logfile::Entry->new_from_line(shift) }

sub write_logfile {
    my $entries  = shift;
    my $filename = shift || 'logfile';

    open my $handle, '>', $filename
        or croak "Unable to open $filename for writing: $!";

    for (@$entries) {
        print { $handle } $_->as_line . "\n";
    }

    close $handle
        or croak "Unable to close $filename handle: $!";

    return;
}

1;

__END__

=head1 NAME

NetHack::Logfile - Parse and create NetHack logfiles

=head1 VERSION

version 1.00

=head1 SYNOPSIS

    use NetHack::Logfile ':all';

    my @entries = read_logfile("logfile");
    @entries = sort { $b->score <=> $a->score } @entries;
    splice(@entries, 2000);
    write_logfile(\@entries, "high-scores");

    say $entries[0]->as_line;

=head1 DESCRIPTION

This module provides an easy way to read NetHack logfiles. You can also create
logfiles.

This module's interface changed drastically from C<0.01> to C<1.00>.

Currently, NetHack versions 3.2.0 through 3.4.3 are supported. If you desire
support for an older version, please open up a ticket on rt.cpan.org with some
logfile entries for these older versions.

=head1 FUNCTIONS

=head2 read_logfile

Takes a file (default name: F<logfile>) and parses it as a logfile. If any IO
error occurs in reading the file, an exception is thrown. If any error occurs
in parsing a logline, an exception is thrown.

This returns entries of class L<NetHack::Logfile::Entry>. See that module for
more information.

=head2 parse_logline

Shortcut for L<NetHack::Logfile::Entry/new_from_line>.

=head2 write_logfile

Takes an arrayref of L<NetHack::Logfile::Entry> objects and a filename (default
name: F<logfile>). If any IO error occurs, it will throw an exception.

Returns no useful value.

=head1 AUTHOR

Shawn M Moore, C<sartak@gmail.com>

=cut