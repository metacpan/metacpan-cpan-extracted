package Module::Install::HTML5Manifest;
use strict;
use warnings;
use base qw(Module::Install::Base);
our $VERSION = '0.01';

use Data::Dumper;
use HTML5::Manifest;
use MIME::Base64 qw/ encode_base64 decode_base64 /;

sub html5_manifest {
    my($self, %args) = @_;
    $self->admin->copy_package('HTML5::Manifest', $INC{'HTML5/Manifest.pm'});

    if ($args{with_gzfile}) {
        eval "require IO::Compress::Gzip"; ## no critic
        $@ and die 'you should install IO::Compress::Gzip';
    }

    my $make_target = delete $args{make_target} || 'html5manifest';

    local $Data::Dumper::Indent = 0;
    my $base64 = encode_base64( Dumper( \%args ) );
    $base64 =~ s/[\r\n]//g;

    $self->Makefile->postamble(<<EOM);
$make_target:
\techo "ok"
\tperl -Mlib=inc -MModule::Install::HTML5Manifest -e 'Module::Install::HTML5Manifest->generate("$base64")'
EOM
}

sub generate {
    my($class, $base64) = @_;

    my $args = eval 'my ' . decode_base64($base64); ## no critic
    my $skipfile = delete $args->{manifest_skip};
    my $skip = [];

    if ($skipfile && -f $skipfile) {
        open my $fh, '<', $skipfile or die "Can't open file $skipfile: $!";
        while (<$fh>) {
            chomp;
            push @{ $skip }, qr{$_};
        }
    }

    my $generate_to = delete $args->{generate_to};

    my $manifest = HTML5::Manifest->new(
        use_digest => $args->{use_digest},
        htdocs     => $args->{htdocs_from},
        network    => $args->{network_list},
        skip       => $skip,
    );

    open my $to_fh, '>', $generate_to or die "Can't open file $generate_to: $!";
    print $to_fh $manifest->generate;
    close $to_fh;

    if ($args->{with_gzfile}) {
        require IO::Compress::Gzip;
        IO::Compress::Gzip::gzip($generate_to => "$generate_to.gz")
            or die "gzip failed: $IO::Compress::Gzip::GzipError\n";
    }
}

1;
__END__

=head1 NAME

Module::Install::HTML5Manifest - HTML5 application cache manifest file generator for Module::Install

=head1 SYNOPSIS

=head2 simple usage

in your Makefile.PL

    use Module::Install::HTML5Manifest;
    
    use inc::Module::Install;
    name 'Example';
    all_from 'lib/Example.pm';
    
    html5_manifest
        htdocs_from   => 'htdocs',
        manifest_skip => 'html5manifest.skip',
        generate_to   => 'example.manifest',
        with_gzfile   => 1, # create .gz file
        network_list  => [qw( /api /foo/bar.cgi )],
        use_digest    => 1,
        ;
    
    WriteAll;

in your html5manifest.skip

    \.txt$
    tmp/

run shell commands

    $ perl Makefile.PL
    $ make html5manifest
    $ cat example.manifest
    $ zcat example.manifest.gz

=head2 customize make file target
in your Makefile.PL

    use Module::Install::HTML5Manifest;
    
    use inc::Module::Install;
    name 'Example';
    all_from 'lib/Example.pm';
    
    html5_manifest
        make_target   => 'html5manifest_target1',
        htdocs_from   => 'htdocs',
        manifest_skip => 'html5manifest_target1.skip',
        generate_to   => 'target1.manifest',
        ;
    
    html5_manifest
        make_target   => 'html5manifest_target2',
        htdocs_from   => 'htdocs',
        manifest_skip => 'html5manifest_target2.skip',
        generate_to   => 'target2.manifest',
        ;
    
    WriteAll;

in your html5manifest1.skip

    \.txt$
    tmp/

run shell commands

    $ perl Makefile.PL
    $ make html5manifest_target1
    $ make html5manifest_target2
    $ cat target1.manifest
    $ cat target2.manifest

=head1 DESCRIPTION

Module::Install::HTML5Manifest is generate HTML5 application cache manifest file.

=head1 FUNCTION

=head2 html5_manifest(%args)

The following options can be specified and suitable HTML5 manifest file for your site can be generated.

I<%args> are:

=over

=item C<< make_target => $make_target >>

you can change make command target of making manifest file.

default value is 'html5manifest'.

=item C<< htdocs_from => $htdocs_path >>

root directory of a file included to manifest is specified.

=item C<< manifest_skip => $manifest_skip_file_path >>

The file path which saved the list of the file pattern excepted to manifest file is specified.

The file pattern excepted from C<$args{htdocs}> is described. It is the same work as C<MANIFEST.SKIP>.

=item C<< network_list => \@network_list >>

NETWORK: URL specified as section is specified in manifest file.

=item C<< generate_to => $output_manifest_file_path >>

The file path of manifest file created by the make command is specified.

=item C<< with_gzfile => $boolean >>

true is passed when making .gz file together with the file created by C<generate_to>.

In many cases, the transfer cost when sending a manifest file to a browser decreases.

=item C<< use_digest => $boolean >>

md5 checksum is created from all the contents of the file included in cache, and it writes in manifest file.
This is useful to updating detection of manifest file.

=back

=head1 AUTHOR

Kazuhiro Osawa E<lt>yappo {at} shibuya {dot} plE<gt>

=head1 SEE ALSO

L<HTML5::Manifest>, L<http://www.w3.org/TR/html5/offline.html>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
