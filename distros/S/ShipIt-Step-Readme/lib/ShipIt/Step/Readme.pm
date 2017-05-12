package ShipIt::Step::Readme;

use strict;
use Pod::Readme;
use ShipIt::Util qw(slurp write_file);

use base 'ShipIt::Step';

our $VERSION = '0.03';
$VERSION = eval $VERSION;

################################################################################
# no check for dry run, because we quit anyway if we encounter an
# INSTALL / INSTALLATION section in Pod
sub run {
    my ($self, $state) = @_;
    $state->pt->current_version; #should create $self->{ver_from} for us

    # change Distribution Module
    my $dist_file = $state->pt->{ver_from};
    die "no file for distribution found", $self->{ver_from} unless ($dist_file);

    my $dist_content = slurp($dist_file);
    if ($dist_content !~ /^=head1 INSTALL/mi) {
        $dist_content = $self->_add_install_instructions($dist_content);
        write_file($dist_file, $dist_content);
    }

    my $parser = Pod::Readme->new();
    $parser->parse_from_file($dist_file, 'README');

    return 1;
}

################################################################################
# put into extra sub made testing easier
sub _add_install_instructions {
    my ($self, $dist_content) = @_;
    my $install = $self->_get_instructions;
    return $dist_content if ($dist_content =~ s/(^=head\d VERSION.*?(?=^=))/$1$install/sm);
    return $dist_content if ($dist_content =~ s/(^=head\d NAME.*?(?=^=))/$1$install/sm);
    die ('trying to add pod Install section after VERSION or NAME Section, but there is none');
}

################################################################################
sub _build_instructions () {q~
    perl Build.PL
    ./Build
    ./Build test
    ./Build install
~;}

################################################################################
sub _make_instructions () {q~
    perl Makefile.PL
    make
    make test
    make install
~;}

################################################################################
sub _get_instructions {
    my ($self) = @_;
    my $instructions;
    if (-e 'Build.PL') {
        $instructions = $self->_build_instructions ;
    } elsif (-e 'Makefile.PL') {
        $instructions = $self->_make_instructions;
    } else {
        die ('only Build.PL and Makefile.PL are supported, but none was found');
    }

    # little bit awkward, but Pod-Parsers don't check for Pod inside strings
    my $pod  = "=begin readme\n\n";
    $pod    .= "=head1 INSTALLATION\n\n";
    $pod    .= "To install this module, run the following commands:\n";
    $pod    .= "$instructions\n";
    $pod    .= "=end readme\n\n";

    return $pod;
}

1;

=head1 NAME

ShipIt::Step::Readme - Automatically create README for your Perl Package before releasing

=head1 VERSION

Version 0.03

=begin readme

=head1 INSTALLATION

To install this module, run the following commands:

    perl Build.PL
    ./Build
    ./Build test
    ./Build install

=end readme

=head1 SYNOPSIS

Just add it to the ShipIt config, after all steps, that edit Pod, because
the README file is generated from the Pod of the distris' main file.

    steps = FindVersion, ChangeVersion, ChangePodVersion, Readme, ...

And make sure you have a VERSION or a NAME section in your Pod. The README pod,
which is not visible on CPAN, is added after any of them.

=head1 DESCRIPTION

This ShipIt::Step autogenerates a README-file from your distris' main package.

Therefore it adds a Pod INSTALLATION section, but only if it does not exist yet.
It contains installation instructions, for either an installation via ./Build or
an installation via make, depending on the existence of a Build.PL or a
Makefile.PL. If neither is found, we die.

The Pod INSTALLATION section is added after the Pod VERSION section, or in case
it does not exist, after the Pod NAME section. If neither is found, we die.
This section won't be visible on CPAN, and will only appear in your README.

B<Run this after any ShipIt::Step, that edits Pod.> For example
L<ShipIt::Step::ChangePodVersion> does that to add a Pod VERSION section
to your module. Otherwise the changes made won't be reflected in your README.

=head1 CONFIG

Nothing to configure. Drop me an EMail if you have any wishes for configuration.

=head1 WARNING

This is not really tested with distris, which dont't use Build.PL. But from
a logic point of view, there shouldn't be any problem. However, contact me if
you encounter any problems.

=head1 AUTHOR

Thomas Mueller, C<< <tmueller at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-shipit-step-readme at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=ShipIt-Step-Readme>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc ShipIt::Step::Readme


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=ShipIt-Step-Readme>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/ShipIt-Step-Readme>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/ShipIt-Step-Readme>

=item * Search CPAN

L<http://search.cpan.org/dist/ShipIt-Step-Readme/>

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2010 Thomas Mueller.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut