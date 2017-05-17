package PAUSE::Permissions::EntryIterator;
$PAUSE::Permissions::EntryIterator::VERSION = '0.17';
use strict;
use warnings;

use Moo;
use PAUSE::Permissions::Entry;
use autodie;
use feature 'state';

has 'permissions' =>
    (
        is      => 'ro',
        # isa     => 'PAUSE::Permissions',
    );

sub next
{
    my $self        = shift;
    state $fh;

    if (not defined $fh) {
        open($fh, '<', $self->permissions->path);
        my $inheader = 1;

        # Skip the header block at the top of the file
        while (<$fh>) {
            last if /^$/;
        }
    }

    my $line = <$fh>;

    if (defined($line)) {
        chomp($line);
        my ($module, $user, $permission) = split(/,/, $line);
        return PAUSE::Permissions::Entry->new(module => $module, user => $user, permission => $permission);
    } else {
        return undef;
    }
}

1;
