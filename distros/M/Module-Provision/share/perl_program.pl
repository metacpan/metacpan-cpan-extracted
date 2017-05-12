#!/usr/bin/env perl

use strict;
use warnings;

use English qw( -no_match_vars );
use FindBin qw( $Bin );
use File::Spec;

BEGIN {
   my $bind = $Bin; $bind =~ m{ \A ([^\$%&\*;<>\`|]+) \z }mx and $bind = $1;
   my $path = File::Spec->catfile( $bind, '[% prefix %]-localenv' );

   -f $path and (do $path or die $EVAL_ERROR || "Path ${path} not done\n");
}

use [% module %];

exit [% module %]->new_with_options( noask => 1 )->run;

__END__

=pod

=encoding utf-8

=head1 Name

[% program_name %] - [% abstract %]

=head1 Synopsis

=over 3

=item B<[% program_name %]> B<> I<>

I<Command line description>

=item B<[% program_name %]> B<-H> | B<-h> I<[method]> | B<-?>

Display man page / method help  / usage strings

=item B<[% program_name %]> B<list-methods>

Lists the methods available in this program

=back

=head1 Description

I<Program description>

=head1 Required arguments

=over 3

=item I<>

=back

=head1 Options

=over 3

=item B<-D>

Turn debugging on

=back

=head1 Diagnostics

Prints errors to stderr

=head1 Exit status

Returns zero on success, non zero on failure

=head1 Configuration

Uses the constructor's C<appclass> attribute to locate a configuration file

=head1 Dependencies

=over 3

=item L<Class::Usul>

=back

=head1 Incompatibilities

None

=head1 Bugs and limitations

Please report problems to
http://rt.cpan.org/NoAuth/Bugs.html?Dist=[% distname %]

=head1 Author

[% author %], C<< <[% author_email %]> >>

=head1 License and copyright

Copyright (c) [% copyright_year %] [% copyright %]

This is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

# Local Variables:
# mode: perl
# tab-width: 3
# End:
# vim: expandtab shiftwidth=3:
