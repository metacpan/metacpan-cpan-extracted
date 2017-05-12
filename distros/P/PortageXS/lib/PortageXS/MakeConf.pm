
use strict;
use warnings;

package PortageXS::MakeConf;
BEGIN {
  $PortageXS::MakeConf::AUTHORITY = 'cpan:KENTNL';
}
{
  $PortageXS::MakeConf::VERSION = '0.3.1';
}

# ABSTRACT: Parser for make.conf and friends

use Moo;
use Path::Tiny;


sub _has_path {
    my ( $name, @args ) = @_;
    push @args, coerce => sub {
        return $_[0] if ref $_[0];
        return path( $_[0] );
    };
    push @args, isa => sub {
        die "Not a Path::Tiny" if not ref $_[0] or not $_[0]->isa('Path::Tiny');
    };
    has( $name, is => ro =>, lazy => 1, @args );
}

sub _has_path_list {
    my ( $name, @args ) = @_;
    push @args, coerce => sub {
        die "not a list" if not ref $_[0] eq 'ARRAY';
        [ map { ref $_ ? $_ : path($_) } @{ $_[0] } ];
    };
    push @args, isa => sub {
        die "not a list" if not ref $_[0] eq 'ARRAY';
        my $i = 0;
        for ( @{ $_[0] } ) {
            die "element $i is not a Path::Tiny"
              if not ref $_
              or not $_->isa('Path::Tiny');
        }
    };
    has( $name, is => ro =>, lazy => 1, @args );
}

_has_path_list files => (
    builder => sub {
        [
            '/usr/share/portage/config/make.globals',
            '/etc/make.conf.globals',
            '/etc/make.conf',
            '/etc/portage/make.conf',
        ];
    }
);

sub add_path {
    my ( $self, @paths ) = @_;
    push @{ $self->files }, map { ref $_ ? $_ : path($_) } @paths;
}

has content => (
    is      => ro => lazy => 1,
    builder => sub {
        my @lines;
        my $self = shift;
        for my $file ( @{ $self->files } ) {
            next if not -e $file;
            push @lines, $file->lines( { chomp => 1 } );
        }
        return \@lines;
    }
);

sub getParam {
    my ( $self, $param, $mode ) = @_;
    my $value = '';    # value of $param

    # - split file in lines >
    my (@lines) = @{$self->content};
    my $c = -1;
    for my $line (@lines) {
        $c++;
        next if $line =~ m/^#/;

        # - remove comments >
        $line =~ s/#(.*)//g;

        # - remove leading whitespaces and tabs >
        $line =~ s/^[ \t]+//;

        if ( $line =~ /^$param="(.*)"/ ) {

            # single-line with quotationmarks >
            $value = $1;

            last if ( $mode eq 'firstseen' );
        }
        elsif ( $line =~ /^$param="(.*)/ ) {

            # multi-line with quotationmarks >
            $value = $1 . ' ';
            for my $d ( $c + 1 .. $#lines ) {

                # - look for quotationmark >
                if ( $lines[$d] =~ /(.*)"?/ ) {

                    # - found quotationmark; append contents and leave loop >
                    $value .= $1;
                    last;
                }
                else {
                    # - no quotationmark found; append line contents to $value >
                    $value .= $lines[$d] . ' ';
                }
            }
            last if ( $mode eq 'firstseen' );
        }
        elsif ( $line =~ /^$param=(.*)/ ) {

            # - single-line without quotationmarks >
            $value = $1;

            last if ( $mode eq 'firstseen' );
        }
    }

    # - clean up value >
    $value =~ s/^[ \t]+//;    # remove leading whitespaces and tabs
    $value =~ s/[ \t]+$//;    # remove trailing whitespaces and tabs
    $value =~ s/\t/ /g;       # replace tabs with whitespaces
    $value =~ s/ {2,}/ /g;    # replace 1+ whitespaces with 1 whitespace

    return $value;
}

1;

__END__

=pod

=encoding utf-8

=head1 NAME

PortageXS::MakeConf - Parser for make.conf and friends

=head1 VERSION

version 0.3.1

=begin MetaPOD::JSON v1.1.0

{
    "namespace":"PortageXS::MakeConf",
    "interface":"class",
    "inherits":"Moo::Object"
}


=end MetaPOD::JSON

=head1 AUTHORS

=over 4

=item *

Christian Hartmann <ian@gentoo.org>

=item *

Torsten Veller <tove@gentoo.org>

=item *

Kent Fredric <kentnl@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2013 by Christian Hartmann.

This is free software, licensed under:

  The GNU General Public License, Version 2, June 1991

=cut
