package ShipIt::Step::ChangePodVersion;

use strict;
use base 'ShipIt::Step';
use ShipIt::Util qw(slurp write_file);
use File::Find::Rule;

our $VERSION = '0.04';
$VERSION = eval $VERSION;

################################################################################
sub init {
    my ($self, $conf) = @_;
    my $all_from_config = $conf->value("ChangePodVersion.all");
    $self->{change_pod_version_all} = defined $all_from_config ? $all_from_config : 1;
}


################################################################################
# no check for dry run, because nothing gets destroyed
sub run {
    my ($self, $state) = @_;

    $state->pt->current_version; #should create $self->{ver_from} for us
    my $new_version = $state->version;

    # change Distribution Module
    my $dist_file = $state->pt->{ver_from};
    die "no file for distribution found", $self->{ver_from} unless ($dist_file);
    my $changed_file = $self->_change_pod_version(slurp($dist_file), $new_version);
    write_file($dist_file, $changed_file);

    # change other modules
    if ($self->{change_pod_version_all}) {
        for my $module ( File::Find::Rule->name('*.pm')->in('lib') ) {
            next if ($module eq $dist_file); # already treated
            my $version = $self->_version_from_file($module);
            next unless (defined $version && length $version);

            my $changed_module = $self->_change_pod_version(slurp($module), $version);
            write_file($module, $changed_module);
        }
    }


    return 1;

}

################################################################################
# Copied from ProjectType::Perl, which operates only on $self->{ver_from}
# Copied again from ShipIt::Step::CheckVersionsMatch
sub _version_from_file
{
    my $self = shift;
    my $file = shift;

    open my $fh, '<', $file
        or die "Failed to open $file: $!\n";

    while (<$fh>) {
        return $2 if /\$VERSION\s*=\s*([\'\"])(.+?)\1/;
    }
}

################################################################################
sub _change_pod_version {
    my ($self, $file_content, $new_version) = @_;

    # if we find a VERSION section, we change version, otherwise add one
    if ($file_content =~ /^=head\d VERSION/m) {

        # replace version
        if ($file_content !~ s/(^=head\d VERSION[^\d=]*)[\d._]+/$1$new_version/sm) {
            die ('there is a POD VERSION section, but the version cannot be parsed');
        }

    } else {

        my $version = "=head1 VERSION\n\n$new_version\n\n";
        # add it after NAME section, everybody has one, right?
        if ($file_content !~ s/(^=head\d NAME.*?(?=^=))/$1$version/sm) {
            die ('trying to add a POD VERSION section after NAME Section, but there is none');
        }

    }

    return $file_content;
}

1;

=head1 NAME

ShipIt::Step::ChangePodVersion - Keep VERSION in your Pod in sync with $VERSION

=head1 VERSION

Version 0.04

=begin readme

=head1 INSTALLATION

To install this module, run the following commands:

    perl Build.PL
    ./Build
    ./Build test
    ./Build install

=end readme

=head1 SYNOPSIS

Just add it to the ShipIt config, maybe after the ChangeVersion-Step

    steps = FindVersion, ChangeVersion, ChangePodVersion, CheckChangeLog, ...

And make sure you have a VERSION or at least a NAME section in your Pod.

    =head1 VERSION

    version 123

=head1 DESCRIPTION

This is a Step for ShipIt to keep your Pod VERSION in sync with your $VERSION.
If a VERSION section is discovered in your Pod, it is tried to find and replace
numbers or "." or "_" within this section with your new version.

You can write whatever you want before your version-number, but make sure it
does not contain numbers or "." or "_".

In case no VERSION section is found, a VERSION section is created after the
NAME section. If no NAME section is found, we die.

By default all your modules' Pod VERSION sections are updated to the files'
$VERSION. Add ChangePodVersion.all to your shipit config and set it to 0 to
change only the Pod of your distribution package.

In case no $VERSION is found in your package, we don't die, but continue with
other packages.

=head1 CONFIG

=head2 ChangePodVersion.all

B<DEFAULT> 1

Set this config value to 0 to deactivate VERSION Changes for all your dists
modules. Only the dist-packages' Pod VERSION will be changed then.

=head1 WARNING

The code to change all Modules' Pod VERSION is not automatically tested yet,
because it is hard to write tests for it. I use it with HTTP::Exception now and
didn't notice any problems, although automatic testing is better than having not
experienced any problems. If you encounter problems, just deactivate it with
ChangePodVersion.all = 0 and drop me an email.

=head1 AUTHOR

Thomas Mueller, C<< <tmueller at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-shipit-step-changepodversion at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=ShipIt-Step-ChangePodVersion>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc ShipIt::Step::ChangePodVersion


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=ShipIt-Step-ChangePodVersion>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/ShipIt-Step-ChangePodVersion>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/ShipIt-Step-ChangePodVersion>

=item * Search CPAN

L<http://search.cpan.org/dist/ShipIt-Step-ChangePodVersion/>

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2010 Thomas Mueller.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut
