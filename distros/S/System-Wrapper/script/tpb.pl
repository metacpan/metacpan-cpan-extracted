#!/usr/bin/env perl

use warnings;
use strict;
use Data::Dumper;
use Carp;
use Getopt::Long;
use Pod::Usage;
use version; our $VERSION = qv('0.0.1');

GetOptions(
    \%ARGV,
    'input|i=s', 'output|o=s', 'error|e=s',
    'size|s=i', 'name|n=s', 'type|t=s',
    _meta_options( \%ARGV ),
)
and $ARGV{input} or @ARGV or $ARGV{size}
or pod2usage( -verbose => 1 );

my ( $INH, $OUTH, $ERRH ) = _prepare_io( \%ARGV, \@ARGV );

my ($name, $input_size) = (@ARGV{qw/name size/});

$ARGV{type} ||= 'raw';
$input_size ||= 0;

if (@ARGV) {
    $input_size += -s $_ for @ARGV;
}

my %dispatch = (
    raw => \&_cat_raw,
    tpb => \&_cat_tpb,
);

if (@ARGV) {
    while (my $file = shift @ARGV) {
        open $INH, q{<}, $file or die qq{Cant read $file: $!};
        $dispatch{$ARGV{type}}->( $INH, $OUTH, $ERRH, $name, $input_size );
    }
}
else {
    $dispatch{$ARGV{type}}->( $INH, $OUTH, $ERRH, $name, $input_size );
}
close $INH;
close $OUTH;


sub _cat_raw {
    my ($inh, $outh, $errh, $name, $input_size) = @_;

    my $BUFFER_SIZE = 4096;
    my $UPDATE_PROB = 1/1000;
    my $buffer      =  q{};
    my $total_read  = 0;

    my @byte_units = qw/B kiB MiB GiB TiB PiB/;
    my $size_modifier = 1;

    $input_size /= 1024
    and $size_modifier *= 1024
    and shift @byte_units
    until $input_size < 1024;

    my @time_units = qw/s m h/;

    my $rate = 0;

    use Time::HiRes qw(time);
    my $start = time;

    while (my $read = sysread $inh, $buffer, $BUFFER_SIZE) {

        if (syswrite $outh, $buffer) {

            next unless -t $errh;

            $total_read += $read;

            unless (int rand 1/$UPDATE_PROB) {
                
                my $current = Time::HiRes::time - $start;

                $rate = ($total_read / $size_modifier) / ($current);

                $current /= 60 ** (3 - @time_units);
                
                $current /= 60 and shift @time_units
                until $current < 60;

                printf $errh "\r%s: [ %.2f/%.2f%s ] %.2f/%.2f%s (%.2f%s/%s) ",
                $name          || 'progress',
                $total_read / $size_modifier,
                $input_size,
                $byte_units[0] || 'units',
                $current,
                $rate ? $input_size / $rate : 0,
                $time_units[0] || 'units',
                $rate,
                $byte_units[0] || 'units',
                $time_units[0] || 'units',
            }

        }
    }
    print $errh "\n";
}


sub _cat_tpb {
    my ($inh, $outh, $errh, $name, $input_size) = @_;

    eval {require Term::ProgressBar;};
    die "$0: '--type tpb' requires Term::ProgressBar to be installed" if $@;
    die "$0: '--type tpb' requires input size to be given via '-s INT' if monitoring STDIN";

    my $progress = Term::ProgressBar->new( {
        name  => $name || 'progress',
        count => $input_size,
        ETA   => 'linear',
        fh    => \$errh,
    } );

    my $BUFFER_SIZE = 4096;
    my $UPDATE_PROB = 1/2;
    my $next_update = 0;
    my $total_read  = 0;
    my $buffer      =  q{};

    while (my $read = sysread $inh, $buffer, $BUFFER_SIZE) {

        if (syswrite $outh, $buffer) {
            $total_read += $read;
            $next_update = $progress->update($total_read)
            if $total_read >= $next_update;
        }
    }
    $progress->update($input_size)
    if $input_size >= $next_update;
}


sub _meta_options {
    my ($opt) = @_;

    return (
        'quiet'     => sub { $opt->{quiet}   = 1;          $opt->{verbose} = 0 },
        'verbose:i' => sub { $opt->{verbose} = $_[1] // 1; $opt->{quiet}   = 0 },
        'version'   => sub { pod2usage( -sections => ['VERSION', 'REVISION'],
                                        -verbose  => 99 )                      },
        'license'   => sub { pod2usage( -sections => ['AUTHOR', 'COPYRIGHT'],
                                        -verbose  => 99 )                      },
        'usage'     => sub { pod2usage( -sections => ['SYNOPSIS'],
                                        -verbose  => 99 )                      },
        'help'      => sub { pod2usage( -verbose  => 1  )                      },
        'manual'    => sub { pod2usage( -verbose  => 2  )                      },
    );
}

sub _prepare_io {
    my ($opt, $argv) = @_;

    my ($INH, $OUTH, $ERRH);
    
    # If user explicitly sets -i, put the argument in @$argv
    unshift @$argv, $opt->{input} if exists $opt->{input};

    # Allow in-situ arguments (equal input and output filenames)
    if (    exists $opt->{input} and exists $opt->{output}
               and $opt->{input} eq $opt->{output} ) {
        open $INH, q{<}, $opt->{input}
            or croak "Can't read $opt->{input}: $!";
        unlink $opt->{output};
    }
    else { $INH = *STDIN }

    # Redirect STDOUT to a file if so specified
    if ( exists $opt->{output} and q{-} ne $opt->{output} ) {
        open $OUTH, q{>}, $opt->{output}
            or croak "Can't write $opt->{output}: $!";
    }
    else { $OUTH = *STDOUT }

    # Log STDERR if so specified
    if ( exists $opt->{error} and q{-} ne $opt->{error} ) {
        open $ERRH, q{>}, $opt->{error}
            or croak "Can't write $opt->{error}: $!";
    }
    elsif ( exists $opt->{quiet} and $opt->{quiet} ) {
        use File::Spec;
        open $ERRH, q{>}, File::Spec->devnull
            or croak "Can't write $opt->{error}: $!";
    }
    else { $ERRH = *STDERR }

    return ( $INH, $OUTH, *STDERR = $ERRH );
}

__DATA__


__END__

=head1 NAME

 tpb.pl - Progress Viewer

=head1 SYNOPSIS

 tpb.pl [OPTION]... [[-i] FILE]...

=head1 DESCRIPTION

 Concatenate input to output with progress bar 

=head1 OPTIONS

 -n, --name        <string>     name of progress (useful when nesting multiple instances of tpb.pl)
 -s, --size        <integer>    size of input in bytes (ignored when not reading STDIN)
 -t, --type        <string>     'raw' (simple byte count and timing) or 'tpb' (Term::ProgressBar::Simple) ('tpb')
 -i, --input       <string>     input filename                           (STDIN)
 -o, --output      <string>     output filename                          (STDOUT)
 -e, --error       <string>     output error filename                    (STDERR)
     --verbose     [integer]    print increasingly verbose error messages
     --quiet                    print no diagnostic or warning messages
     --version                  print current version
     --license                  print author's contact and copyright information
     --help                     print this information
     --manual                   print the plain old documentation page

=head1 VERSION

 0.0.1

=head1 REVISION

 $Rev: $:
 $Author: $:
 $Date: $:
 $HeadURL: $:
 $Id: $:

=head1 AUTHOR

 Pedro Silva <pedros@berkeley.edu/>
 Zilberman Lab <http://dzlab.pmb.berkeley.edu/>
 Plant and Microbial Biology Department
 College of Natural Resources
 University of California, Berkeley

=head1 COPYRIGHT

 This program is free software: you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation, either version 3 of the License, or
 (at your option) any later version.

 This program is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.

 You should have received a copy of the GNU General Public License
 along with this program. If not, see <http://www.gnu.org/licenses/>.

=cut
