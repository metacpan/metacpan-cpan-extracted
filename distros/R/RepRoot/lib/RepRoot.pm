package RepRoot;

use File::Spec;
use FindBin  qw( $RealBin );

use strict;
use warnings;

our $VERSION = '0.02';

BEGIN {

    # figure out full absolute path of executable and split into components
    my ( $volume, $directories, $file ) = File::Spec->splitpath( $RealBin, 1 );
    my @directories = File::Spec->splitdir( $directories );

    # keep searching up the path till you hit root or find the .reproot file
    while ( @directories ) {
        # assemble next possible .reproot path
        my $reproot_file = File::Spec->catpath( $volume, File::Spec->catdir( @directories ), '.reproot' );

        # check for existence of .reproot file
        if ( -e $reproot_file ) {

            # we found the root!
            $RepRoot::ROOT = File::Spec->catpath( $volume, File::Spec->catdir( @directories ) );

            # if the file has a non-zero size, execute it
            if ( -s $reproot_file ) {
                unless ( my $return = do $reproot_file ) {
                    die "couldn't parse $reproot_file: $@" if $@;
                    die "couldn't do $reproot_file: $!"    unless defined $return;
                    die "couldn't run $reproot_file"       unless $return;
                }
            }

            # we're done!
            last;
        }

        # didn't find it; move up a level and try again
        pop( @directories );
    }

    # throw exception if no .reproot file found
    die "couldn't find repository root (indicated by existence of '.reproot' file)" unless defined $RepRoot::ROOT;

}

1;

__END__

=pod

=head1 NAME

RepRoot - the simplest way to find the root directory of your source code repository

=head1 VERSION

Version 0.02

=head1 SYNOPSIS

In the root of your source code repository:

    touch .reproot

In your perl script:

    use RepRoot;

    my $schema = "$RepRoot::ROOT/data/sql/schema.sql";
    ...

=head1 DESCRIPTION

When RepRoot is first loaded, it determines which directory your script lives in
and looks in there for a file named .reproot.  If it doesn't find it there, it
will search up the path, one level at a time, until it finds it or errors out.
When the .reproot file is found, the C<$RepRoot::ROOT> variable is set to that
path.

Additionally, if the .reproot file is more than 0 bytes, the file's contents
will be excuted using the perl C<do> function, allowing for additional custom
configuration (such as C<use lib> statements to add your repository libraries
to the perl include path).

NOTE: RepRoot uses the $RealBin value from the FindBin module, which reports
the canonical path (all symlinks are resolved to their targets).  Since you
shouldn't have symlinks inside your codebase, and RepRoot shouldn't have to
explore outside your codebase, this shouldn't bother most people.

=head1 BUT WHY?

Let's look at a typical scenario where RepRoot would be useful.

Your company has a source code repository with a fairly standard layout:

    > find project_x/
    project_x/bin/
    project_x/bin/foo.pl
    project_x/data/
    project_x/data/sql/
    project_x/data/sql/schema.sql
    project_x/docs/
    project_x/lib/
    project_x/lib/perl/
    project_x/lib/perl/MyCustomLib.pm

You have some custom perl libraries under lib/perl/, some perl scripts under bin/, and a
file containing your database schema in data/sql/schema.sql.

In order to access the perl libraries you have to include something like this at the top
of every perl script:

    use lib "../lib/perl";

Similar problem is you want to access the schema file:

    my $schema_file = "../data/sql/schema.sql";

The problems are:

 - it's ugly
 - the path is relative and depends on where the script lies within the repository,
   which means it must be updated if the script is moved

You can use RepRoot to solve the problem by doing the following:

1) create a .reproot file in the root of the repository (in the hypothetical
case, that would be directly under project_x/)

2) add some code to .reproot to include the path to your custom perl libs:

    use lib "$RepRoot::ROOT/lib/perl";
    1;

3) use RepRoot in your perl scripts:

    use RepRoot;
    use MyCustomLib;
    my $schema_file = "$RepRoot::ROOT/data/sql/schema.sql";

Don't forget that if you include anything at all in .reproot (if filesize > 0 bytes),
the contents will be executed, and the last value must be true or it will fail.  So,
just like when you write a perl module, make sure to stick a "1;" on a line by itself
at the end.

=head1 AUTHOR

Written by Ofer Nave E<lt>ofer@netapt.comE<gt>.
Sponsered by Shopzilla, Inc. (formerly BizRate.com).

=head1 BUGS

Please report any bugs or feature requests to
C<bug-reproot at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=RepRoot>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc RepRoot

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/RepRoot>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/RepRoot>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=RepRoot>

=item * Search CPAN

L<http://search.cpan.org/dist/RepRoot>

=back

=head1 COPYRIGHT & LICENSE

Copyright 2006 by Shopzilla, Inc, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See F<http://www.perl.com/perl/misc/Artistic.html>

=cut
