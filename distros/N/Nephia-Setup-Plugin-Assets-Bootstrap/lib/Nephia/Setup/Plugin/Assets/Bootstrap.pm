package Nephia::Setup::Plugin::Assets::Bootstrap;
use 5.008005;
use strict;
use warnings;
use parent 'Nephia::Setup::Plugin';
use File::ShareDir ':ALL';
use File::Copy;
use File::Spec;

our $VERSION = "0.04";
our $ARCHIVE_FILENAME = 'bootstrap-2.3.2.zip';

sub fix_setup {
    my $self = shift;
    $self->setup->action_chain->append('Assets::Bootstrap' => \&_assets_bootstrap);
}

sub _assets_bootstrap {
    my ($setup, $context) = @_;
    my $dist = __PACKAGE__; 
    $dist =~ s/\:\:/\-/g;
    my $src = dist_file($dist, $ARCHIVE_FILENAME);
    my $dst = File::Spec->catfile($setup->approot, $ARCHIVE_FILENAME);
    copy($src, $dst);
    $setup->assets_archive($ARCHIVE_FILENAME, qw/static/);
}

1;
__END__

=encoding utf-8

=head1 NAME

Nephia::Setup::Plugin::Assets::Bootstrap - Deploy twitter-bootstrap(v.2.3.2) into your webapp

=head1 SYNOPSIS

    $ nephia-setup YourApp --plugins Assets::Bootstrap

=head1 DESCRIPTION

Nephia::Setup::Plugin::Assets::Bootstrap is setup task for Nephia::Setup that deploys twitter-bootstrap into your application.

=head1 LICENSE

Copyright (C) ytnobody.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

ytnobody E<lt>ytnobody@gmail.comE<gt>

=cut

