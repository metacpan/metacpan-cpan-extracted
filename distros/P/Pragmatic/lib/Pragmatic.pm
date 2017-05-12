package Pragmatic;

require 5.001; # ??
require Exporter;

use strict;
use vars qw (@ISA $VERSION);

@ISA = qw (Exporter);

# The package version, both in 1.23 style *and* usable by MakeMaker:
$VERSION = '1.7';
my $rcs = '$Id: Pragmatic.pm 164 2005-03-15 21:42:20Z binkley $' ;


sub import ($) {
  my $package = shift;

  return $package->export_to_level (1, $package, @_)
    if $package eq __PACKAGE__;

  my $warn = sub (;$) {
    require Carp;
    local $Carp::CarpLevel = 2; # relocate to calling package
    Carp::carp (@_);
  };

  my $die = sub (;$) {
    require Carp;
    local $Carp::CarpLevel = 2; # relocate to calling package
    Carp::croak (@_);
  };

  my @imports = grep /^[^-]/, @_;
  my @pragmata = map { substr($_, 1); } grep /^-/, @_;

  # Export first, for side-effects (e.g., importing globals, then
  # setting them with pragmata):
  $package->export_to_level (1, $package, @imports)
    if @imports;

  for (@pragmata) {
    no strict qw (refs);

    my ($pragma, $args) = split /=/, $_;
    my (@args) = split /,/, $args || '';

    exists ${"$package\::PRAGMATA"}{$pragma}
      or &$die ("No such pragma '$pragma'");

    if (ref ${"$package\::PRAGMATA"}{$pragma} eq 'CODE') {
      &{${"$package\::PRAGMATA"}{$pragma}} ($package, @args)
	or &$warn ("Pragma '$pragma' failed");

      # Let inheritance work for barewords:
    } elsif (my $ref = $package->can
	     (${"$package\::PRAGMATA"}{$pragma})) {
      &$ref ($package, @args)
	or &$warn ("Pragma '$pragma' failed");

    } else {
      &$die ("Invalid pragma '$pragma'");
    }
  }
}

1;


__END__


=head1 NAME

Pragmatic - Adds pragmata to Exporter

=head1 SYNOPSIS

In module MyModule.pm:

  package MyModule;
  require Pragmatic;
  @ISA = qw (Pragmatic);

  %PRAGMATA = (mypragma => sub {...});

In other files which wish to use MyModule:

    use MyModule qw (-mypragma); # Execute pragma at import time
    use MyModule qw (-mypragma=1,2,3); # Pass pragma argument list

=head1 DESCRIPTION

B<Pragmatic> implements a default C<import> method for processing
pragmata before passing the rest of the import to B<Exporter>.

Perl automatically calls the C<import> method when processing a
C<use> statement for a module. Modules and C<use> are documented
in L<perlfunc> and L<perlmod>.

(Do not confuse B<Pragmatic> with I<pragmatic modules>, such as
I<less>, I<strict> and the like.  They are standalone pragmata, and
are not associated with any other module.)

=head2 Using Pragmatic Modules

Using Pragmatic modules is very simple.  To invoke any
particular pragma for a given module, include it in the argument list
to C<use> preceded by a hyphen:

    use MyModule qw (-mypragma);

C<Pragmatic::import> will filter out these arguments, and pass the
remainder of the argument list from the C<use> statement to
C<Exporter::import> (actually, to C<Exporter::export_to_level> so that
B<Pragmatic> is transparent).

If you want to pass the pragma arguments, use syntax similar to that
of the I<-M> switch to B<perl> (see L<perlrun>):

    use MyModule qw (-mypragma=abc,1,2,3);

If there are any warnings or fatal errors, they will appear to come
from the C<use> statement, not from C<Pragmatic::import>.

=head2 Writing Pragmatic Modules

Writing Pragmatic modules with B<Pragmatic> is straight-forward.
First, C<require Pragmatic> (you could C<use> it instead, but it
exports nothing, so there is little to gain thereby).  Declare a
package global C<%PRAGMATA>, the keys of which are the names of the
pragmata and their corresponding values the code references to invoke.
Like this:

    package MyPackage;

    require Pragmatic;

    use strict;
    use vars qw (%PRAGMATA);

    sub something_else { 1; }

    %PRAGMATA =
      (first => sub { print "@_: first\n"; },
       second => sub { $SOME_GLOBAL = 1; },
       third => \&something_else,
       fourth => 'name_of_sub');

When a pragma is given in a C<use> statement, the leading hyphen is
removed, and the code reference corresponding to that key in
C<%PRAGMATA>, or a subroutine with the value's name, is invoked with
the name of the package as the first member of the argument list (this
is the same as what happens with C<import>).  Additionally, any
arguments given by the caller are included (see L<Using Pragmatic
Modules>, above).

=head1 EXAMPLES

=head2 Using Pragmatic Modules

=over

=item 1. Simple use:

  use MyModule; # no pragmas

  use MyModule qw (-abc); # invoke C<abc>

  use MyModule qw (-p1 -p2); # invoke C<p1>, then C<p2>

=item 2. Using an argument list:

  use MyModule qw (-abc=1,2,3); # invoke C<abc> with (1, 2, 3)

  use MyModule qw (-p1 -p2=here); # invoke C<p1>, then C<p2>
                                  # with (1, 2, 3)

=item 3. Mixing with arguments for B<Exporter>:

(Please see L<Exporter> for a further explanatation.)

  use MyModule ( ); # no pragmas, no exports

  use MyModule qw (fun1 -abc fun2); # import C<fun1>, invoke C<abc>,
                                    # then import C<fun2>

  use MyModule qw (:set1 -abc=3); # import set C<set1>, invoke C<abc>
                                  # with (3)

=back

=head2 Writing Pragmatic Modules

=over

=item 1. Setting a package global:

  %PRAGMATA = (debug => sub { $DEBUG = 1; });

=item 2. Selecting a method:

  my $fred = sub { 'fred'; };
  my $barney = sub { 'barney'; };

  %PRAGMATA =
    (fred => sub {
       local $^W = 0;
       *flintstone = $fred;
     },

     barney => sub {
       local $^W = 0;
       *flintstone = $barney;
     });

=item 3. Changing inheritance:

  %PRAGMATA = (super => sub { shift; push @ISA, @_; });

=item 4. Inheriting pragmata:

  package X;
  @ISA = qw(Pragmatic);
  %PRAGMATA = (debug => 'debug');
  $DEBUG = 0;

  sub debug { ${"$_[0]::DEBUG"} = 1; }

  package Y:
  @ISA = qw(X);
  %PRAGMATA = (debug => 'debug');
  $DEBUG = 0;

=back

=head1 SEE ALSO

L<Exporter>

B<Exporter> does all the heavy-lifting (and is a very interesting
module to study) after B<Pragmatic> has stripped out the pragmata from
the C<use>.

=head1 DIAGNOSTICS

The following are the diagnostics generated by B<Pragmatic>.  Items
marked "(W)" are non-fatal (invoke C<Carp::carp>); those marked "(F)"
are fatal (invoke C<Carp::croak>).

=over

=item No such pragma '%s'

(F) The caller tried something like "use MyModule (-xxx)" where there
was no pragma I<xxx> defined for MyModule.

=item Invalid pragma '%s'

(F) The writer of the called package tried something like "%PRAGMATA =
(xxx => not_a_sub)" and either assigned I<xxx> a non-code reference,
or I<xxx> is not a method in that package.

=item Pragma '%s' failed

(W) The pramga returned a false value.  The module is possibly in an
inconsisten state after this.  Proceed with caution.

=back

=head1 AUTHORS

B. K. Oxley (binkley) E<lt>binkley@alumni.rice.eduE<gt>

=head1 COPYRIGHT

  Copyright 1999-2005, B. K. Oxley.

This library is free software; you may redistribute it and/or modify
it under the same terms as Perl itself.

=head1 THANKS

Thanks to Kevin Caswick E<lt>KCaswick@wspackaging.comE<gt> for a great
patch to run under Perl 5.8.

=cut
