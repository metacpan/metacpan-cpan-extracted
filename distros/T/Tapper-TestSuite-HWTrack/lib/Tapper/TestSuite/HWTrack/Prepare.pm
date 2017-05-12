## no critic (RequireUseStrict)
package Tapper::TestSuite::HWTrack::Prepare;
BEGIN {
  $Tapper::TestSuite::HWTrack::Prepare::AUTHORITY = 'cpan:TAPPER';
}
{
  $Tapper::TestSuite::HWTrack::Prepare::VERSION = '4.1.1';
}
# ABSTRACT: Support package for Tapper::TestSuite::HWTrack

        use 5.010;

        use Moose;
        extends 'Tapper::Base';
        use File::ShareDir 'module_dir';
        use File::Temp     'tempdir';

        has src       => ( is => 'rw', default => sub { module_dir('Tapper::TestSuite::HWTrack')."/lshw" } );
        has dst       => ( is => 'rw', default => sub { tempdir( CLEANUP => 0 ) } );
        has exitcode  => ( is => 'rw', );
        has starttime => ( is => 'rw', );


        sub install {
                my ($self) = @_;

                my $src = $self->src;
                my $dst = $self->dst;
                my ($error, $msg);
                ($error, $msg) = $self->log_and_exec("rsync -a $src/ $dst/");
                return $msg if $error;

                ($error, $msg) = $self->log_and_exec("cd $dst; make ");
                return $msg if $error;
                return 0;
        }

1;

__END__
=pod

=encoding utf-8

=head1 NAME

Tapper::TestSuite::HWTrack::Prepare - Support package for Tapper::TestSuite::HWTrack

=head2 install

Prepare lshw executable

@return success - 0

@return error   - error string

=head1 AUTHOR

AMD OSRC Tapper Team <tapper@amd64.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2012 by Advanced Micro Devices, Inc..

This is free software, licensed under:

  The (two-clause) FreeBSD License

=cut

