package Module::Build::Pluggable::ReadmeMarkdownFromPod;
use strict;
use warnings;
use 5.010001;
our $VERSION = '0.04';

use parent qw/Module::Build::Pluggable::Base/;
use Class::Accessor::Lite (
    ro => [qw/filename clean/],
);

sub HOOK_configure {
    my ($self) = @_;
    $self->build_requires('Pod::Markdown' => 0);
}

sub HOOK_build {
    my ($self) = @_;
    require Pod::Markdown;

    my $src = $self->filename || $self->builder->dist_version_from;
    unless ($src) {
        die "Missing filename for ReadmeMarkdownFromPod";
    }

    $self->log_info("Writing README.mkdn\n");

    if (-f 'README.mkdn') {
        my $perm = (stat 'README.mkdn')[2] & oct('7777');
        chmod($perm | oct('600'), 'README.mkdn');
        _write_file($src);
        chmod($perm, 'README.mkdn'); # restore permission
    } else {
        _write_file($src);
    }

    if ($self->clean) {
        $self->add_to_cleanup('README.mkdn');
    }
}

sub _write_file {
    my ($src) = @_;
    my $parser = Pod::Markdown->new();
    $parser->parse_from_file($src);
    open my $fh, '>', 'README.mkdn' or die "Cannot open README.mkdn: $!\n";
    print {$fh} $parser->as_markdown;
    close $fh;
}

1;
__END__

=encoding utf8

=head1 NAME

Module::Build::Pluggable::ReadmeMarkdownFromPod - Make README.mkdn from POD.

=head1 SYNOPSIS

    use Module::Build::Pluggable (
        'ReadmeMarkdownFromPod',
    );

=head1 DESCRIPTION

This plugin generates README.mkdn from pod file.

=head1 OPTIONS

=over 4

=item filename

    use Module::Build::Pluggable (
        'ReadmeMarkdownFromPod' => {
            filename => 'lib/Foo.pod'
        },
    );

You can specify the source pod filename. If you don't specify the filename, this plugin uses dist_version_from file.

=item clean (Default: 0)

If you set this flag as true value, this plugin adds README.mkdn to cleanup file list.

=back

=head1 AUTHOR

Tokuhiro Matsuno E<lt>tokuhirom AAJKLFJEF@ GMAIL COME<gt>

And this module is based on L<Module::Install::ReadmeMarkdownFromPod>

=head1 SEE ALSO

L<Module::Build::Pluggable>, L<Module::Build>, L<Module::Install::ReadmeMarkdownFromPod>

=head1 LICENSE

Copyright (C) Tokuhiro Matsuno

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
