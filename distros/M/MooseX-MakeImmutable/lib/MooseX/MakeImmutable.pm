package MooseX::MakeImmutable;

use warnings;
use strict;

=head1 NAME

MooseX::MakeImmutable - A convenient way to make many Moosen immutable (or mutable) in one shot

=head1 VERSION

Version 0.02

=cut

our $VERSION = '0.02';

=head1 SYNOPSIS

    package MyPackage;

    use Moose;
    use MooseX::MakeImmutable;

    ...

    MooseX::MakeImmutable->lock_down;
    # MyPackage and any subdordinate Moose classes are made immutable
    # Use MooseX::MakeImmutable->open_up to do the opposite

You can also make classes im/mutable with fine-grained control:

    use MooseX::MakeImmutable;

    ...

    my $manifest = <<_MANIFEST_;

        My::Moose::Hierarchy::Alpha
        My::Moose::Hierarchy::Bravo
        My::Moose::Hierarchy::Charlie

         # Comments (lines leading with a pound) and blank lines are ignored by the finder
        My::Moose::Hierarchy::Delta::*
            # Not strict about leading/trailing whitespace either
         My::Moose::Hierarchy::Epsilon::+

    _MANIFEST_

    MooseX::MakeImmutable->make_immutable($manifest);

    # The above code has the following effects:
    #
    # ::Alpha, ::Bravo, and ::Charlie are now immutable (if they exist)
    #
    # Every Moose::Object under the Delta:: namespace is now immutable
    #   (although ::Delta, if a Moose::Object, IS still mutable)
    #
    # Every Moose::Object under the Epsilon:: namespace, including
    #   ::Epsilon is now mutable

    # You can also use MooseX::MakeImmutable to make something mutable again:
    MooseX::MakeImmutable->make_mutable("My::Moose::Hierarchy::Epsilon::+")

=head1 DESCRIPTION

MooseX::MakeImmutable is a tool for loading every Moose::Object within a hierarchy and making each immutable/mutable. It uses L<Module::Pluggable> for searching and will load both inner and .pm packages.

In a nutshell, if you add a Moose-based package to your object hierarchy, then MooseX::MakeImmutable, given a proper manifest, will pick it up and mark it im/mutable (without you having to manually write-out the new package).

NOTE: The name "MakeImmutable" is a bit of a misnomer, since this package can both make_immutable AND make_mutable. However, 90% of the time, you'll probably be using ->make_immutable

=head2 Writing a MooseX::MakeImmutable::Finder manifest

A manifest consists of one package per line

For each line, leading and trailing whitespace is stripped

Lines that are blank or begin with a pound (#) are skipped

A package with a trailing ::* IS NOT made im/mutable, but every package under that namespace is

A package with a trailing ::+ or :: IS made im/mutable, along with every package under that namespace

=head1 METHODS

=head2 MooseX::MakeImmutable->lock_down( [ package => <package> ], ... )

Make everything immutable from <package> on downward

If <package> is not specified, then the package will be gotten from caller. This means you can do something like:

    package MyPackage;

    use Moose;
    use MooseX::MakeImmutable;

    ...

    MooseX::MakeImmutable->lock_down;
    # Effectively the same as MooseX::MakeImmutable->make_immutable('MyPackage::+');

Any remaining arguments will be passed through to ->make_immutable

=head2 MooseX::MakeImmutable->open_up( [ package => <package> ], ... )

Make everything mutable from <package> on downward

If <package> is not specified, then the package will be gotten from caller. This means you can do something like:

    package MyPackage;

    use Moose;
    use MooseX::MakeImmutable;

    ...

    MooseX::MakeImmutable->open_up;
    # Effectively the same as MooseX::MakeImmutable->make_mutable('MyPackage::+');

Any remaining arguments will be passed through to ->make_mutable

=cut

=head2 MooseX::MakeImmutable->freeze( <manifest>, ... )

=head2 MooseX::MakeImmutable->make_immutable( <manifest>, ... )

Create a finder from <manifest> and make each found Moose::Object immutable

Any extra passed-in options will be forwarded to ->meta->make_immutable(...) excepting C<include_inner> and C<exclude>, which are used to configure the finder.

C<freeze> is an alias for C<make_immutable>

=head2 MooseX::MakeImmutable->thaw( <manifest>, ... )

=head2 MooseX::MakeImmutable->make_mutable( <manifest>, ... )

Create a finder from <manifest> and make each found Moose::Object mutable

Any extra passed-in options will be forwarded to ->meta->make_mutable(...) excepting C<include_inner> and C<exclude>, which are used to configure the finder.

C<thaw> is an alias for C<make_mutable>

=head2 MooseX::MakeImmutable->finder( ... )

Create and return a MooseX::MakeImmutable::Finder object

The returned object uses L<Module::Pluggable> to scan the specified namespace(s) for potential Moose objects. It accepts the following options:

    manifest            The finder manifest, described above

    include_inner       If true, then the finder will "find" inner Moose packages. On by default

    exclude             A list where each item is one of:

                        * A package name to be excluded (string)
                        * A regular expression that matches if a package should be excluded 
                        * A CODE block returning true if a package should be excluded (the package name is passed in as the first argument)

=cut

use MooseX::MakeImmutable::Finder;
use Scalar::Util qw/blessed/;
use Carp::Clan qw/^MooseX::MakeImmutable/;

sub lock_down {
    my $class = shift;
    my %given = @_;

    my $package = delete $given{package}; 
    ($package) = caller unless defined $package;
    croak "Can't lock down main::" if $package eq "main"; # Moose doesn't, why should we?
    my $manifest = "${package}::+";
    $class->make_immutable($manifest, %_);
}

sub open_up {
    my $class = shift;
    my %given = @_;

    my $package = delete $given{package}; 
    ($package) = caller unless defined $package;
    croak "Can't open up main::" if $package eq "main"; # Moose doesn't, why should we?
    my $manifest = "${package}::+";
    $class->make_mutable($manifest, %_);
}

sub finder {
    my $class = shift;
    my $finder = MooseX::MakeImmutable::Finder->new(@_);
    return $finder;
}

sub _given_finder {
    my $class = shift;
    my $given = shift;

    my %finder;
    exists $given->{$_} and $finder{$_} = delete $given->{$_} for qw/include_inner exclude/;
    my $finder = delete $given->{finder};

    # If finder is already blessed... then just ignore manifest => ... and use the given finder
    $finder = $class->finder((ref $finder eq "HASH" ? %$finder : ()), %finder, @_) unless blessed $finder;

    return $finder;
}

sub make_immutable {
    my $class = shift;
    my $manifest = shift;
    my %given = @_;

    my $finder = $class->_given_finder(\%given, manifest => $manifest);

    $_->meta->make_immutable(%given) for $finder->found;
}

sub freeze {
    return shift->make_immutable(@_);
}

sub make_mutable {
    my $class = shift;
    my $manifest = shift;
    my %given = @_;

    my $finder = $class->_given_finder(\%given, manifest => $manifest);

    $_->meta->make_mutable(%given) for $finder->found;
}

sub thaw {
    return shift->make_immutable(@_);
}

=head1 SEE ALSO

L<Moose>

=head1 AUTHOR

Robert Krimen, C<< <rkrimen at cpan.org> >>

=head1 SOURCE

You can contribute or fork this project via GitHub:

L<http://github.com/robertkrimen/moosex-makeimmutable/tree/master>

    git clone git://github.com/robertkrimen/moosex-makeimmutable.git MooseX-MakeImmutable

=head1 BUGS

Please report any bugs or feature requests to C<bug-moosex-mutate at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=MooseX-MakeImmutable>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc MooseX::MakeImmutable


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=MooseX-MakeImmutable>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/MooseX-MakeImmutable>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/MooseX-MakeImmutable>

=item * Search CPAN

L<http://search.cpan.org/dist/MooseX-MakeImmutable>

=back


=head1 ACKNOWLEDGEMENTS


=head1 COPYRIGHT & LICENSE

Copyright 2008 Robert Krimen, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

1; # End of MooseX::MakeImmutable
