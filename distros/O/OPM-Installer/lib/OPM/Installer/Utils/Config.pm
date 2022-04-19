package OPM::Installer::Utils::Config;

# ABSTRACT: Read config file for OPM::Installer

use strict;
use warnings;

our $VERSION = '1.0.1'; # VERSION

use Carp qw(croak);
use File::Basename;
use File::HomeDir;
use File::Spec;
use Moo;

has rc_config => ( is => 'ro', lazy => 1, default => \&_rc_config );
has conf      => ( is => 'ro' );

sub _rc_config {
    my ($self) = @_;

    my $dot_file = File::Spec->catfile(
        File::HomeDir->my_home,
        '.opminstaller.rc'
    );

    if ( $self->conf && -f $self->conf ) {
        $dot_file = $self->conf;
    }
    elsif ( $self->conf ) {
        croak 'Config file ' . $self->conf . ' does not exist';
    }

    my %config;
    if ( -f $dot_file && open my $fh, '<', $dot_file ) {
        while ( my $line = <$fh> ) {
            chomp $line;
            next if $line =~ m{\A\s*\#};
            next if $line =~ m{\A\s*\z};

            my ($key, $value) = split /\s*=\s*/, $line;
            $key = lc $key;

            if ( $key eq 'repository' ) {
                push @{ $config{$key} }, $value;
            }
            elsif ( $key eq 'path' ) {
                if ( !File::Spec->file_name_is_absolute( $value ) ) {
                    my $dir = dirname $dot_file;
                    $value = File::Spec->rel2abs(
                        File::Spec->catdir( $dir, $value ),
                    );
                }

                $config{$key} = $value;
            }
            else {
                $config{$key} = $value;
            }
        }
    }

    return \%config;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

OPM::Installer::Utils::Config - Read config file for OPM::Installer

=head1 VERSION

version 1.0.1

=head1 SYNOPSIS

=head1 ATTRIBUTES

=over 4

=item * rc_config

=item * conf

=back

=head1 AUTHOR

Renee Baecker <reneeb@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Renee Baecker.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
