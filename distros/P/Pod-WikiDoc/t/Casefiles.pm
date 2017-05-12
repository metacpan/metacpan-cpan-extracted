package Casefiles;
use strict;
use warnings;
use Carp;
use File::Find 1;
use File::Basename qw(basename);
use Test::More;

# Get optional test support
eval "use Test::Differences";
my $HAVE_DIFF = $@ eq '' ? 1 : 0;

#--------------------------------------------------------------------------#
# new
#--------------------------------------------------------------------------#

sub new {
    my ($class, $data_dir) = @_;

    # Verify directory
    croak "Error: Couldn't read data directory"
        if ( ! ( -e $data_dir && -r $data_dir ) );

    # create blesed object
    return bless { DATA_DIR => $data_dir }, $class;
}

#--------------------------------------------------------------------------#
# data_dir - accessor
#--------------------------------------------------------------------------#

sub data_dir { return $_[0]->{DATA_DIR} }

#--------------------------------------------------------------------------#
# files() - Return list of files
#--------------------------------------------------------------------------#

sub files {
    my ($self) = shift;
    my @case_files;

    my $options = { 
        wanted => sub {
            return if -d $File::Find::name;
            push @case_files, $File::Find::name;
        },
        no_chdir => 1,
    };

    File::Find::finddepth( $options, $self->data_dir );

    return @case_files;
}

#--------------------------------------------------------------------------#
# run_tests() - Run test for each case file
#--------------------------------------------------------------------------#

sub run_tests {
    my ($self, $filter) = @_;
    
    my @case_files = $self->files();

    if ( not Test::More->builder->has_plan ) {
        plan tests => scalar @case_files;
    }

    for my $case ( sort @case_files ) {
        open my $fh, "<", $case 
            or die "Couldn't open file $case";
        my $raw_data = do { local $/; <$fh> };
        my ($input, $expected) = split /^#-+#\n/ms, $raw_data;
        my $got = $filter->( $input );
        if ( $HAVE_DIFF ) {
            eq_or_diff( $got, $expected, basename( $case) );
        }
        else {
            is( $got, $expected, basename( $case ) );
        }
    }

}

1;
