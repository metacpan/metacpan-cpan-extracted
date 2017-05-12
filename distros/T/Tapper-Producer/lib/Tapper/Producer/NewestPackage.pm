## no critic (RequireUseStrict)
package Tapper::Producer::NewestPackage;
our $AUTHORITY = 'cpan:TAPPER';
# ABSTRACT: produce preconditions via find latest changed file
$Tapper::Producer::NewestPackage::VERSION = '5.0.1';
use Moose;
        use YAML;

        use 5.010;

        use Tapper::Config;
        use File::stat;


        sub younger { stat($a)->mtime() <=> stat($b)->mtime() }


        sub produce {
                my ($self, $job, $produce) = @_;

                my $source_dir    = $produce->{source_dir};
                my @files = sort younger <$source_dir/*>;
                return {
                        error => 'No files found in $source_dir',
                       } if not @files;
                my $use_file = pop @files;

                my $nfs = Tapper::Config->subconfig->{paths}{prc_nfs_mountdir};
                die "$use_file not available to Installer" unless $use_file=~/^$nfs/;

                my $retval = [{
                               precondition_type => 'package',
                               filename => $use_file,
                              },];
                return {
                        precondition_yaml => Dump(@$retval),
                       };
        }

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Tapper::Producer::NewestPackage - produce preconditions via find latest changed file

=head2 younger

Comparator for files by mtime.

=head2 produce

Produce resulting precondition.

=head1 AUTHOR

AMD OSRC Tapper Team <tapper@amd64.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2016 by Advanced Micro Devices, Inc..

This is free software, licensed under:

  The (two-clause) FreeBSD License

=cut
