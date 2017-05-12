package Module::Use::DB_FileLock;

use strict;
use vars qw($VERSION);

$VERSION = 0.04;


=head1 NAME

Module::Use::DB_FileLock

=head1 SYNOPSIS

use Module::Use (Logger => 'DB_FileLock', File => '/my/file'[, Flags => $flags, Mode => $mode]);

=head1 DESCRIPTION

C<Module::Use::DB_FileLock> provides a DB File data store for C<Module::Use> via C<Tie::DB_FileLock>.

=head1 OPTIONS

The values for the options correspond directly to the same values used with the C<Tie::DB_FileLock> object.

=over 4

=item File

This is the base for the DB filename.

=item Flags

This is a string representing the read-write mode of the DB file. 
The default value is O_CREAT | O_RDWR.  Since these need to be specified before
they are defined, C<Flags> are specified as strings: 
C<Flags => [qw(O_CREAT O_RDWR)]>.

=item Mode

This is a number representing the filesystem permissions of the DB file.  The default
is C<0660>.

=back

=head1 SEE ALSO

L<Module::Use>, L<Tie::DB_FileLock>.

=head1 AUTHOR

James G. Smith <jgsmith@jamesmith.com>

=head1 COPYRIGHT

Copyright (C) 2001 James G. Smith

Released under the same license as Perl itself.

=cut



package Module::Use;

use Tie::DB_FileLock;
use Carp;

package Module::Use;

sub log {
    my($self) = shift;

    my $file = $self -> {File} or croak "No DB file specified";
    my $flags= $self -> {Flags} || [ qw{O_CREAT O_RDWR} ];
    my $mode = $self -> {Mode} || 0660;

    $flags = eval(join("|", @{$flags}));

    my %hash;
    tie %hash, 'Tie::DB_FileLock', $file, $flags, $mode, $DB_BTREE;
    #croak $@ if $@;

    my $grow = $self -> {Grow} || 2;

    $hash{$_} += $grow for(@_);

    my @keys = grep { !defined $INC{$_} } keys %hash;
    my $decay = $self -> {Decay} || 1;

    $hash{$_} -= $decay for @keys;
    delete $hash{$_} for grep { $hash{$_} < 1 } @keys;
}

sub _query_modules {
    my($self) = shift;

    my $file = $self -> {File} || croak "No DB file specified";
    my $flags= $self -> {Flags} || [ qw(O_CREAT O_RDWR) ];
    my $mode = $self -> {Mode} || 0660;

    $flags = eval(join("|", @{$flags}));

    my %hash;
    eval(q{tie %hash, 'Tie::DB_FileLock', $file, $flags, $mode, $DB_BTREE});
    return { } if $@;

    return \%hash;
}

1;
