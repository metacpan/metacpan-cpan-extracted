package PAUSE::Packages::ReleaseIterator;
$PAUSE::Packages::ReleaseIterator::VERSION = '0.17';
use 5.8.1;
use Moo 1.006;
use PAUSE::Packages;
use PAUSE::Packages::Release;
use PAUSE::Packages::Module;
use JSON::MaybeXS;
use autodie 2.29;

has 'packages' =>
    (
        is      => 'ro',
        default => sub { return PAUSE::Packages->new(); },
    );

has 'well_formed' =>
    (
        is      => 'ro',
        default => sub { 0 },
    );

has _fh => ( is => 'rw' );

sub next_release
{
    my $self = shift;
    my @modules;
    my $fh;

    if (not defined $self->_fh) {
        open($fh, '<', $self->packages->path());
        my $inheader = 1;

        # Skip the header block at the top of the file
        while (<$fh>) {
            last if /^$/;
        }
        $self->_fh($fh);
    }
    else {
        $fh = $self->_fh;
    }

    RELEASE:
    while (1) {
        my $line = <$fh>;
        my @args;

        if (defined($line)) {
            chomp($line);
            my ($path, $json) = split(/\s+/, $line, 2);
            foreach my $entry (@{ decode_json($json) }) {
                my $module = PAUSE::Packages::Module->new(
                                name    => $entry->[0],
                                version => $entry->[1],
                             );
                push(@modules, $module);
            }
            @args = (modules => [@modules], path => $path);
            if ($self->well_formed) {
                my $distinfo = CPAN::DistnameInfo->new($path);
                next RELEASE unless defined($distinfo)
                                 && defined($distinfo->dist)
                                 && defined($distinfo->cpanid);
                push(@args, distinfo => $distinfo);
            }
            return PAUSE::Packages::Release->new(@args);
        } else {
            return undef;
        }
    }

    return undef;
}

1;
