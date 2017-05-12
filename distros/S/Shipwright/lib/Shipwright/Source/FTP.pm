package Shipwright::Source::FTP;

use warnings;
use strict;

use Shipwright::Source::Compressed;
use File::Spec::Functions qw/catfile/;

use base qw/Shipwright::Source::Base/;
use Shipwright::Util;

=head2 run

=cut

sub run {
    my $self = shift;
    $self->log->info( "preparing to run source: " . $self->source );
    if ( $self->_run ) {
        my $compressed =
          Shipwright::Source::Compressed->new( %$self, _no_update_url => 1 );
        $compressed->run();
    }
}

=head2 _cmd

=cut

sub _run {
    my $self   = shift;
    my $source = $self->source;
    my $file;
    if ( $source =~ m{.*/(.+\.(tar\.gz|tgz|tar\.bz2))$} ) {
        $file = $1;
        $self->_update_url( $self->just_name($file), $source );
        my $src_dir = $self->download_directory;
        mkdir $src_dir unless -e $src_dir;
        $self->source( catfile( $src_dir, $file ) );
        $self->_lwp_get($source);
    }
    else {
        confess_or_die "invalid source: $source";
    }
}

1;

__END__

=head1 AUTHOR

sunnavy  C<< <sunnavy@bestpractical.com> >>


=head1 LICENCE AND COPYRIGHT

Copyright 2007-2015 Best Practical Solutions.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.
