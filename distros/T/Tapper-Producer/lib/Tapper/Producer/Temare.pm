## no critic (RequireUseStrict)
package Tapper::Producer::Temare;
our $AUTHORITY = 'cpan:TAPPER';
# ABSTRACT: produce preconditions via temare
$Tapper::Producer::Temare::VERSION = '5.0.1';
use Moose;
        use File::Temp 'tempfile';
        use YAML       'LoadFile';
        use Tapper::Config;
        use Try::Tiny;


        sub produce {
                my ($self, $job, $produce) = @_;

                my ($fh, $file) = tempfile( UNLINK => 1 );

                use Data::Dumper;
                my $temare_path=Tapper::Config->subconfig->{paths}{temare_path};

                $ENV{PYTHONPATH}="$temare_path/src";
                my $subject = $produce->{subject};
                my $bitness = $produce->{bitness};
                my $host =  $job->host->name;
                $ENV{TAPPER_TEMARE} = $file;
                my $cmd="$temare_path/temare subjectprep $host $subject $bitness";
                my $precondition = qx($cmd);
                if ($?) {
                        my $error_msg = "Temare error.\n";
                        $error_msg   .= "Error code: $?\n";
                        $error_msg   .= "Error message: $precondition\n";
                        die $error_msg;
                }

                my $config = try {LoadFile($file)} catch { die "Error occured while loading precondition $precondition:\n$_"};
                close $fh;
                unlink $file if -e $file;
                my $topic = $config->{subject} || 'Misc';
                return {
                        topic => $topic,
                        precondition_yaml => $precondition
                       };
        }

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Tapper::Producer::Temare - produce preconditions via temare

=head2 produce

Choose a new testrun from the test matrix, generate the required
external config files (e.g. svm file for xen, .sh files for KVM, ..).

@param Job object - the job we build a package for
@param hash ref   - producer precondition

@return success - hash ref containing list of new preconditions

@throws die()

=head1 AUTHOR

AMD OSRC Tapper Team <tapper@amd64.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2016 by Advanced Micro Devices, Inc..

This is free software, licensed under:

  The (two-clause) FreeBSD License

=cut
