package QuadPres::Config;
$QuadPres::Config::VERSION = '0.28.2';
use 5.016;
use strict;
use warnings;

use parent 'QuadPres::Base';

use Config::IniFiles ();
use Template         ();

__PACKAGE__->mk_acc_ref( [qw( base_path cfg )] );

sub _init
{
    my $self = shift;

    my %args = @_;

    my $base_path = $args{path} || ".";

    $self->base_path($base_path);

    my $cfg = Config::IniFiles->new( -file => "$base_path/quadpres.ini" );

    if ( !defined($cfg) )
    {
        die "Could not open the configuration file!";
    }

    $self->cfg($cfg);

    return 0;
}

sub _get_raw_val
{
    my $self = shift;
    return $self->cfg->val(@_);
}

sub _get_tt_driver
{
    return Template->new( {} );
}

sub _get_tt_vars
{
    my $vars = { 'ENV' => \%ENV, };

    return $vars;
}

sub _get_tt_val
{
    my ( $self, $section, $key, $value ) = @_;

    my $template = $self->_get_raw_val( $section, "tt_$key", $value );

    if ( !defined($template) )
    {
        return;
    }

    my $output = "";
    $self->_get_tt_driver()
        ->process( \$template, $self->_get_tt_vars(), \$output, );

    return $output;
}

sub get_val
{
    my $self = shift;

    # TODO : I'm assuming it's always scalar context here.
    my $tt_value = $self->_get_tt_val(@_);

    if ( defined($tt_value) )
    {
        return $tt_value;
    }
    else
    {
        return $self->_get_raw_val(@_);
    }
}

sub get_server_dest_dir
{
    my $self = shift;

    return $self->get_val( "quadpres", "server_dest_dir" );
}

sub get_setgid_group
{
    my $self = shift;

    return $self->get_val( "quadpres", "setgid_group" );
}

sub get_upload_path
{
    my $self = shift;

    return $self->get_val( "upload", "upload_path" );
}

sub get_upload_util
{
    my $self = shift;

    return $self->get_val( "upload", "util" );
}

sub get_upload_cmdline
{
    my $self = shift;

    return $self->get_val( "upload", "cmdline" );
}

sub get_version_control
{
    my $self = shift;

    return $self->get_val( "quadpres", "version_control" );
}

sub get_hard_disk_dest_dir
{
    my $self = shift;

    return $self->get_val( "hard-disk", "dest_dir" );
}

sub get_src_archive_path
{
    my $self = shift;

    return $self->get_val( "quadpres", "src_archive" );
}

1;

__END__

=pod

=encoding UTF-8

=head1 VERSION

version 0.28.2

=for :stopwords cpan testmatrix url bugtracker rt cpants kwalitee diff irc mailto metadata placeholders metacpan

=head1 SUPPORT

=head2 Websites

The following websites have more information about this module, and may be of help to you. As always,
in addition to those websites please use your favorite search engine to discover more resources.

=over 4

=item *

MetaCPAN

A modern, open-source CPAN search engine, useful to view POD in HTML format.

L<https://metacpan.org/release/QuadPres>

=item *

RT: CPAN's Bug Tracker

The RT ( Request Tracker ) website is the default bug/issue tracking system for CPAN.

L<https://rt.cpan.org/Public/Dist/Display.html?Name=QuadPres>

=item *

CPANTS

The CPANTS is a website that analyzes the Kwalitee ( code metrics ) of a distribution.

L<http://cpants.cpanauthors.org/dist/QuadPres>

=item *

CPAN Testers

The CPAN Testers is a network of smoke testers who run automated tests on uploaded CPAN distributions.

L<http://www.cpantesters.org/distro/Q/QuadPres>

=item *

CPAN Testers Matrix

The CPAN Testers Matrix is a website that provides a visual overview of the test results for a distribution on various Perls/platforms.

L<http://matrix.cpantesters.org/?dist=QuadPres>

=item *

CPAN Testers Dependencies

The CPAN Testers Dependencies is a website that shows a chart of the test results of all dependencies for a distribution.

L<http://deps.cpantesters.org/?module=QuadPres>

=back

=head2 Bugs / Feature Requests

Please report any bugs or feature requests by email to C<bug-quadpres at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/Public/Bug/Report.html?Queue=QuadPres>. You will be automatically notified of any
progress on the request by the system.

=head2 Source Code

The code is open to the world, and available for you to hack on. Please feel free to browse it and play
with it, or whatever. If you want to contribute patches, please send me a diff or prod me to pull
from your repository :)

L<https://github.com/shlomif/quad-pres>

  git clone https://github.com/shlomif/quad-pres.git

=head1 AUTHOR

Shlomi Fish <shlomif@cpan.org>

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<https://github.com/shlomif/quad-pres/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2019 by Shlomi Fish.

This is free software, licensed under:

  The MIT (X11) License

=cut
