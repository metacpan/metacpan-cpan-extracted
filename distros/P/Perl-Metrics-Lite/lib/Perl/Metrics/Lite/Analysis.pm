package Perl::Metrics::Lite::Analysis;
use strict;
use warnings;

use Carp qw(confess);
use Perl::Metrics::Lite::Analysis::Util;

our $VERSION = '0.092';

my %_ANALYSIS_DATA = ();
my %_FILES         = ();
my %_FILE_STATS    = ();
my %_MAIN          = ();
my %_SUBS          = ();

sub new {
    my ( $class, $analysis_data ) = @_;
    if (!Perl::Metrics::Lite::Analysis::Util::is_ref(
            $analysis_data, 'ARRAY'
        )
        )
    {
        confess 'Did not supply an arryref of analysis data.';
    }
    my $self = {};
    bless $self, $class;
    $self->_init($analysis_data);    # Load object properties
    return $self;
}

sub files {
    my ($self) = @_;
    return $_FILES{$self};
}

sub data {
    my $self = shift;
    return $_ANALYSIS_DATA{$self};
}

sub file_count {
    my $self = shift;
    return scalar @{ $self->files };
}

sub file_stats {
    my $self = shift;
    return $_FILE_STATS{$self};
}

sub main_stats {
    my $self = shift;
    return $_MAIN{$self};
}

sub subs {
    my ($self) = @_;
    return $_SUBS{$self};
}

sub sub_stats {
    my $self      = shift;
    my $sub_stats = {};
    foreach my $sub (@{ $self->subs || []}) {
        $sub_stats->{$sub->{path}} ||= [];
        push @{$sub_stats->{$sub->{path}}}, $sub ;
    } 
    return $sub_stats;
}

sub sub_count {
    my $self = shift;
    return scalar @{ $self->subs };
}

sub _init {
    my ( $self, $file_objects ) = @_;
    $_ANALYSIS_DATA{$self} = $file_objects;

    my @all_files  = ();
    my @packages   = ();
    my $lines      = 0;
    my @subs       = ();
    my @file_stats = ();
    my %main_stats = ( lines => 0 );

    foreach my $file ( @{ $self->data() } ) {
        $lines += $file->lines();
        $main_stats{lines} += $file->main_stats()->{lines};
        push @all_files, $file->path();
        push @file_stats,
            { path => $file->path, main_stats => $file->main_stats };
        push @packages, @{ $file->packages };
        push @subs,     @{ $file->subs };
    }

    $_FILE_STATS{$self} = \@file_stats;
    $_FILES{$self}      = \@all_files;
    $_MAIN{$self}       = \%main_stats;
    $_SUBS{$self}       = \@subs;
    return 1;
}

1;
__END__

=head1 NAME

Perl::Metrics::Lite::Analysis - Contains anaylsis results.

=head1 SYNOPSIS

This is the class of objects returned by the I<analyze_files>
method of the B<Perl::Metrics::Lite> class.

Normally you would not create objects of this class directly, instead you
get them by calling the I<analyze_files> method on a B<Perl::Metrics::Lite>
object.

=head1 VERSION

This is VERSION 0.092

=head1 DESCRIPTION


=head1 USAGE

=head2 new

  $analysis = Perl::Metrics::Lite::Analsys->new( \@file_objects )

Takes an arrayref of B<Perl::Metrics::Lite::Analysis::File> objects
and returns a new Perl::Metrics::Lite::Analysis object.

=head2 data

The raw data for the analysis. This is the arrayref you passed
as the argument to new();

=head2 files

Arrayref of file paths, in the order they were encountered.

=head2 file_count

How many Perl files were found.

=head2 lines

Total lines in all files, excluding comments and pod.

=head2 main_stats

Returns a hashref of data based the I<main> code in all files, that is,
on the code minus all named subroutines.

  {
    lines             => 723,
  }

=head2 file_stats

Returns an arrayref of hashrefs, each entry is for one analyzed file,
in the order they were encountered. The I<main_stats> slot in the hashref
is for all the code in the file B<outside of> any named subroutines.

   [
      {
        path => '/path/to/file',
        main_stats => {
                        lines             => 23,
                        path              => '/path/to/file',
                        name              => '{code not in named subroutines}',
                       },
        },
        ...
   ]

=head2 sub_stats

Returns an hashref of subroutine metrics, each entry is for one analyzed file.


=head2 packages

Arrayref of unique packages found in code.

=head2 package_count

How many unique packages found.

=head2 subs

Array ref containing hashrefs of all named subroutines,
in the order encounted.

Each hashref has the structure:

    {
         'lines' => 19,
         'line_number' => 5,
         'mccabe_complexity' => 6,
         'name' => 'databaseRecords',
         'path' => '../path/to/File.pm',
    }

=head2 sub_count

How many subroutines found.


=head1 BUGS AND LIMITATIONS

None reported yet ;-)

=head1 DEPENDENCIES

=over 4

=item L<Readonly>

=item L<Statistics::Basic>

=back

=head1 SUPPORT

Via github

=head2 Disussion Forum

http://www.cpanforum.com/dist/Perl-Metrics-Lite

=head2 Bug Reports

http://rt.cpan.org/NoAuth/Bugs.html?Dist=Perl-Metrics-Lite

=head1 AUTHOR

Dann <techmemo {at} gmail.com>

=head1 SEE ALSO

L<Perl::Metrics>
L<Perl::Metrics::Simple>

=cut

