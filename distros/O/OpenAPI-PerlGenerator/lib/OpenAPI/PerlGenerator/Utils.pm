package OpenAPI::PerlGenerator::Utils 0.01;
use 5.020;
use experimental 'signatures';

use Exporter 'import';
use Perl::Tidy;
use File::Basename;
use File::Path 'make_path';

our @EXPORT_OK = (qw(tidy update_file));

sub tidy( $source ) {
    my $formatted = $source;
    Perl::Tidy::perltidy(
        source      => \$source,
        destination => \$formatted,
        argv        => [ '--no-memoize' ],
    ) or $source = $formatted;
    return $formatted;
}

=head2 C<< update_file >>

  update_file( filename => $package->{filename},
               output_directory => $output_directory,
               keep_existing => (!!($package->{package} =~ /\bClient\z/)),
               content => $package->{source},
  );

=cut

sub update_file( %options ) {
    my $filename = delete $options{ filename }
        or die "Need a filename to create/update";
    my $output_directory = delete $options{ output_directory } // '.';
    my $force = delete $options{ force };
    $filename = "$output_directory/$filename";
    my $new_content = delete $options{ content };
    my $keep_existing = $options{ keep_existing };
    my $encoding = $options{ encoding } // ':raw:encoding(UTF-8)';

    my $content = '';
    if( -f $filename ) {
        if( $keep_existing ) {
            return if $keep_existing and not $force;
        }

        open my $fh, "<$encoding", $filename
            or die "Couldn't read '$filename': $!";
        local $/;
        $content = <$fh>;
    };

    if( $content ne $new_content ) {
        make_path( dirname $filename ); # just to be sure
        if( open my $fh, ">$encoding", $filename ) {
            print $fh $new_content;
        } else {
            warn "Couldn't (re)write '$filename': $!";
        };
    };
}

1;
__END__

=head1 REPOSITORY

The public repository of this module is
L<https://github.com/Corion/OpenAPI-PerlGenerator>.

=head1 SUPPORT

The public support forum of this module is L<https://perlmonks.org/>.

=head1 BUG TRACKER

Please report bugs in this module via the Github bug queue at
L<https://github.com/Corion/OpenAPI-PerlGenerator/issues>

=head1 AUTHOR

Max Maischein C<corion@cpan.org>

=head1 COPYRIGHT (c)

Copyright 2024- by Max Maischein C<corion@cpan.org>.

=head1 LICENSE

This module is released under the Artistic License 2.0.

=cut
