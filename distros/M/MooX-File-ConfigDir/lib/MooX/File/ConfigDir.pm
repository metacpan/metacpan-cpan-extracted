package MooX::File::ConfigDir;

use strict;
use warnings;

our $VERSION = "0.005";

use Carp qw/croak/;
use Scalar::Util qw(blessed);
use File::ConfigDir ();
use namespace::clean;

use Moo::Role;

has 'config_identifier' => (
    is => 'lazy',
);

sub _build_config_identifier { }

sub _fetch_file_config_dir
{
    my ( $self, $attr, $params ) = @_;
    croak "either \$self or \$params must be valid" unless blessed $self or "HASH" eq ref $params;
    my $app_name =
        blessed($self)                       ? $self->config_identifier
      : defined $params->{config_identifier} ? $params->{config_identifier}
      :                                        $self->_build_config_identifier($params);
    my @app_names = $app_name ? ($app_name) : ();
    my $sub       = File::ConfigDir->can($attr);
    my @dirs      = &{$sub}(@app_names);
    return \@dirs;
}

has singleapp_cfg_dir => (
    is      => 'ro',
    lazy    => 1,
    clearer => 1,
    builder => sub { [File::ConfigDir::singleapp_cfg_dir] },
);

my @file_config_dir_attrs = (
    qw(system_cfg_dir xdg_config_dirs desktop_cfg_dir),
    qw(core_cfg_dir site_cfg_dir vendor_cfg_dir ),
    qw(local_cfg_dir locallib_cfg_dir here_cfg_dir user_cfg_dir),
    qw(xdg_config_home config_dirs)
);

foreach my $attr (@file_config_dir_attrs)
{
    has $attr => (
        is      => 'ro',
        lazy    => 1,
        clearer => 1,
        builder => sub { my $self = shift; $self->_fetch_file_config_dir( $attr, @_ ) },
    );
}

=head1 NAME

MooX::File::ConfigDir - Moo eXtension for File::ConfigDir

=head1 SYNOPSIS

    my App;

    use Moo;
    with MooX::File::ConfigDir;

    1;

    package main;

    my $app = App->new();
    $app->config_identifier('MyProject');

    my @cfgdirs = @{ $app->config_dirs };

    # install support
    my $site_cfg_dir = $app->site_cfg_dir->[0];
    my $vendor_cfg_dir = $app->site_cfg_dir->[0];


=head1 DESCRIPTION

This module is a helper for easily find configuration file locations.
Whether to use this information for find a suitable place for installing
them or looking around for finding any piece of settings, heavily depends
on the requirements.

=head1 ATTRIBUTES

=head2 config_identifier

Allows to deal with a global unique identifier passed to the functions of
L<File::ConfigDir>. Using it encapsulates configuration files from the
other ones (eg. C</etc/apache2> vs. C</etc>).

C<config_identifier> can be initialized by specifying it as parameter
during object construction or via inheriting default builder
(C<_build_config_identifier>).

=head2 system_cfg_dir

Provides the configuration directory where configuration files of the
operating system resides. For details see L<File::ConfigDir/system_cfg_dir>.

=head2 desktop_cfg_dir

Provides the configuration directory where configuration files of the
desktop applications resides. For details see L<File::ConfigDir/desktop_cfg_dir>.

=head2 xdg_config_dirs

Alias for desktop_cfg_dir to support
L<XDG Base Directory Specification|http://standards.freedesktop.org/basedir-spec/basedir-spec-latest.html>

=head2 core_cfg_dir

Provides the configuration directory of the Perl5 core location.
For details see L<File::ConfigDir/core_cfg_dir>.

=head2 site_cfg_dir

Provides the configuration directory of the Perl5 sitelib location.
For details see L<File::ConfigDir/site_cfg_dir>.

=head2 vendor_cfg_dir

Provides the configuration directory of the Perl5 vendorlib location.
For details see L<File::ConfigDir/vendor_cfg_dir>.

=head2 singleapp_cfg_dir

Provides the configuration directory of C<$0> if it's installed as
a separate package - either a program bundle (TSM, Oracle DB) or
an independent package combination (eg. via L<pkgsrc|http://www.pkgsrc.org/>
For details see L<File::ConfigDir/singleapp_cfg_dir>.

=head2 local_cfg_dir

Returns the configuration directory for distribution independent, 3rd
party applications. For details see L<File::ConfigDir/local_cfg_dir>.

=head2 locallib_cfg_dir

Provides the configuration directory of the Perl5 L<local::lib> environment
location.  For details see L<File::ConfigDir/locallib_cfg_dir>.

=head2 here_cfg_dir

Provides the path for the C<etc> directory below the current working directory.
For details see L<File::ConfigDir/here_cfg_dir>.

=head2 user_cfg_dir

Provides the users home folder using L<File::HomeDir>.
For details see L<File::ConfigDir/user_cfg_dir>.

=head2 xdg_config_home

Returns the user configuration directory for desktop applications.
For details see L<File::ConfigDir/xdg_config_home>.

=head2 config_dirs

Tries to get all available configuration directories as described above.
Returns those who exists and are readable.
For details see L<File::ConfigDir/config_dirs>.

=head1 AUTHOR

Jens Rehsack, C<< <rehsack at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-MooX-File-ConfigDir at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=MooX-File-ConfigDir>.
I will be notified, and then you'll automatically be notified of progress
on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc MooX::File::ConfigDir

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=MooX-File-ConfigDir>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/MooX-File-ConfigDir>

=item * CPAN Ratings

L<http://cpanratings.perl.org/m/MooX-File-ConfigDir>

=item * Search CPAN

L<http://search.cpan.org/dist/MooX-File-ConfigDir/>

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2013-2015 Jens Rehsack.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1;
