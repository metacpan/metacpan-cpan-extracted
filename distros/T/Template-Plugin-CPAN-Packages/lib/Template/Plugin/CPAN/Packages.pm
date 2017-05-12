package Template::Plugin::CPAN::Packages;

use strict;
use warnings;
use Parse::CPAN::Packages;


our $VERSION = '0.03';


use base 'Template::Plugin';


sub new {
    my ($class, $context, $packages_file) = @_;

    bless {
         _CONTEXT       => $context,
         packages_file  => $packages_file,
         packages       => Parse::CPAN::Packages->new($packages_file),
    }, $class;
}


sub get_primary_package {
    my ($self, $dist) = @_;

    # Only take those packages whose names start with the equivalent of the
    # dist, i.e., for Foo-Bar, only use Foo::Bar and packages below that.

    (my $base_pkg = $dist->dist) =~ s/-/::/g;

    my @packages = @{ $dist->packages || [] };

    unless (@packages) {
        warn sprintf "dist [%s] doesn't contain any packages?\n", $dist->dist;
        return;
    }

    my @dist_packages =
        sort { length($a) <=> length($b) }
        grep { index($_, $base_pkg) == 0 }
        map  { $_->package }
        @packages;

    unless (@dist_packages) {
        my $other_package = $packages[0]->package;
        warn sprintf
            "couldn't get primary package for dist [%s], using [%s]\n",
            $dist->dist, $other_package;
        return $other_package;
    }

    $dist_packages[0];
}


sub bundle_for_author {
    my ($self, $args) = @_;

    defined $args->{cpanid} || die "bundle_for_author(): need 'cpanid' key\n";

    my @unwanted;
    if (exists $args->{unwanted}) {
        @unwanted = ref $args->{unwanted} eq 'ARRAY'
            ? @{ $args->{unwanted} }
            : ($args->{unwanted});
    }

    my %req;

    for my $dist ($self->{packages}->distributions) {
        next unless $dist->cpanid eq $args->{cpanid};
        $req{ $self->get_primary_package($dist) } = 1;
    }

    delete $req{$_} for @unwanted;
    join "\n\n" => sort keys %req;
}


sub bundle_by_dist_prefix {
    my ($self, $args) = @_;

    defined $args->{prefix} ||
        die "bundle_by_dist_prefix(): need 'prefix' key\n";

    my @unwanted;
    if (exists $args->{unwanted}) {
        @unwanted = ref $args->{unwanted} eq 'ARRAY'
            ? @{ $args->{unwanted} }
            : ($args->{unwanted});
    }

    my %req;

    for my $dist ($self->{packages}->distributions) {
        my $name = $dist->dist;
        next unless $name;
        next if index($name, 'Bundle') != -1;
        next unless index($name, $args->{prefix}) == 0;
        $req{ $self->get_primary_package($dist) } = 1;
    }

    delete $req{$_} for @unwanted;
    join "\n\n" => sort keys %req;
}


1;


__END__



=head1 NAME

Template::Plugin::CPAN::Packages - Template plugin to help generate CPAN bundles

=head1 SYNOPSIS

in Bundle::MARCEL:

    =head1 CONTENTS

    [%
        USE c = CPAN.Packages
            '/Users/marcel/mirrors/minicpan/modules/02packages.details.txt.gz';
        c.bundle_for_author(
            'cpanid'   => 'MARCEL',
            'unwanted' => [ 'Class::Factory::Patched' ]
        );
    %]


=head1 DESCRIPTION

This is a plugin for the L<Template> Toolkit that you can use to generate CPAN
bundles. It works together with L<Pod::Generated>. Use it as shown in the
synopsis.

When you instantiate the plugin, you have to pass the name of the
C<02packages.details.txt.gz> file. You might find it in your C<~/.cpan>
directory or in your L<CPAN::Mini> mirror, if you keep one.

=head1 METHODS

=over 4

=item bundle_for_author

Creates the contents of a bundle for all the distributions an author using his
unique CPAN ID. A bundle requires module names - e.g., C<Text::Pipe> -, not
distribution names - e.g., C<Text-Pipe> -, however, so for each distribution,
the I<primary> module from that distribution is listed - that is the
module with the shortest name.

Takes named arguments. The following keys are recognized:

=over 4

=item cpanid

The CPAN ID of the author whose bundle you would like to create. For example,
my CPAN ID is C<MARCEL>.

=item unwanted

A single string or a reference to a list of strings of modules, and therefore,
distributions, that should not be included in the list. This might be useful
if an earlier version of one of your distributions included a module but newer
ones don't. The old module will still be indexed, so it would be picked up by
this method.

=back

=item bundle_by_dist_prefix

Creates the contents of a bundle for all the distributions whose name starts
with a given prefix. A bundle requires module names - e.g., C<Text::Pipe> -,
not distribution names - e.g., C<Text-Pipe> -, however, so for each
distribution, the I<primary> module from that distribution is listed -
that is the module with the shortest name.

Takes named arguments. The following keys are recognized:

=over 4

=item prefix

All distributions with the given prefix are included. Note that this is a
distribution name prefix - e.g., C<Text-Pipe> -, not a module name prefix -
e.g., C<Text::Pipe>.

=item unwanted

A single string or a reference to a list of strings of modules, and therefore,
distributions, that should not be included in the list.

=back

=back

=head1 TAGS

If you talk about this module in blogs, on del.icio.us or anywhere else,
please use the C<templateplugincpanpackages> tag.

=head1 VERSION 
                   
This document describes version 0.03 of L<Template::Plugin::CPAN::Packages>.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
C<<bug-template-plugin-cpan-packages@rt.cpan.org>>, or through the web interface at
L<http://rt.cpan.org>.

=head1 INSTALLATION

See perlmodinstall for information and options on installing Perl modules.

=head1 AVAILABILITY

The latest version of this module is available from the Comprehensive Perl
Archive Network (CPAN). Visit <http://www.perl.com/CPAN/> to find a CPAN
site near you. Or see <http://www.perl.com/CPAN/authors/id/M/MA/MARCEL/>.

=head1 AUTHOR

Marcel GrE<uuml>nauer, C<< <marcel@cpan.org> >>

=head1 COPYRIGHT AND LICENSE

Copyright 2007-2008 by Marcel GrE<uuml>nauer

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.


=cut

