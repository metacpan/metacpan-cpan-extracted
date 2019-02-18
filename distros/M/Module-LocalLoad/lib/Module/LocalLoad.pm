package Module::LocalLoad;
use strict;
use warnings;
use vars qw($VERSION);
$VERSION = '0.176';

use Carp();
use File::Copy();
use File::Path();

my $PERL_HACK_LIB = $ENV{PERL_HACK_LIB};

sub import {
  my $who = (caller(1))[0];

  {
    no strict 'refs';
    *{"${who}::load"} = *load;

  }
}

sub load {
  my $module = shift or return;

  my $who = (caller(1))[0];

  if(!defined($PERL_HACK_LIB)) {
    Carp::croak("Environment variable \$PERL_HACK_LIB not set! Aborting.\n");
  }

  my $slashed_module = _colon_to_slash( $module );

  if(! -d "$PERL_HACK_LIB/$slashed_module") {
    File::Path::make_path("$PERL_HACK_LIB/$slashed_module")
      or Carp::croak("Cant mkdir $PERL_HACK_LIB/$slashed_module: $!\n");
  }

  my $found_pm;
  for my $dir_in_inc(@INC) {
    if($dir_in_inc eq $PERL_HACK_LIB) {
      next;
    }
    if( -f "$dir_in_inc/$slashed_module.pm") {
      $found_pm = "$dir_in_inc/$slashed_module.pm";
      last;
    }
  }

  if(!defined($found_pm)) {
    Carp::croak("Could not find $module in \@INC\n");
  }

  if(! -f "$PERL_HACK_LIB/$slashed_module.pm") {
    File::Copy::copy($found_pm, "$PERL_HACK_LIB/$slashed_module.pm")
      or Carp::croak(
      "Can not copy $found_pm to $PERL_HACK_LIB/$slashed_module.pm: $!"
    );
  }

  unshift(@INC, $PERL_HACK_LIB) unless $INC[0] eq $PERL_HACK_LIB;

  eval "require $module";
  $@ ? Carp::croak("Error loading $module: $@\n") : return 1;
}


sub _colon_to_slash { return join('/', split(/::/, shift)) }


1;

__END__


=pod

=head1 NAME

Module::LocalLoad - create and use a local lib/ for globally installed modules

=head1 SYNOPSIS

  use Module::LocalLoad;

  my $module = 'Term::ANSIColor';
  load($module) and printf("%s v%s loaded\n", $module, $module->VERSION);

=head1 DESCRIPTION

You're debugging your code, and it's still failing even though you're doing
everything right. You might have misinterpreted the documentation for some
module you're using, or perhaps it's not doing what it says it should.

Time to take a peek at the inner guts of said module. Change a few things, and
see if your problem goes away.

Changing code in a globally installed module is not such a great idea. Sometimes
it's not even possible.

This module will help you set up a temporary local lib/ for the modules that you
are working on right now. See the L</EXAMPLES> section.

=head1 EXPORTS

=head2 load( $package )

When load() is called with a valid, globally installed package name several
things happen. First, we check if the environment variable C<PERL_HACK_LIB> is
defined and points to a directory that'll be our new lib/.
If it isnt, we croak, announcing that it needs to be set.

If the directory already contains a copy of the module, we go ahead and load it.
We don't want our changes to be overwritten everytime we load the module.

Otherwise, we copy the module, if existing in C<@INC>, to C<PERL_HACK_LIB>,
modify C<@INC> so that C<PERL_HACK_LIB> comes first, and loads it.

=head1 EXAMPLES

You want to muck around in the inner workings of the IO::File module.

  # load.pl
  use Module::LocalLoad;

  my $m = 'Term::ANSIColor';
  (my $f = $m) =~ s{::}{/}g;
  $f .= '.pm';

  load($m) and printf("%s v%s loaded - %s\n", $m, $m->VERSION, $INC{$f.});

This will produce something like:

  Term::ANSIColor v3.00 loaded - /tmp/Term/ANSIColor.pm

Next up, go make some changes to /tmp/Term/ANSIColor.pm .
Notice the version number reported from ->VERSION:

  vim /tmp/Term/ANSIColor.pm
  perl load.pl

  Term::ANSIColor v3.00_042 loaded - /tmp/Term/ANSIColor.pm

=head1 ENVIRONMENT

=over 4

=item PERL_HACK_LIB

=back

Where the temporary lib should be set up.

=head1 AUTHOR

    \ \ | / /
     \ \ - /
      \ | /
      (O O)
      ( < )
      (-=-)

  Magnus Woldrich
  CPAN ID: WOLDRICH
  m@japh.se
  http://japh.se

=head1 CONTRIBUTORS

None required yet.

=head1 COPYRIGHT

Copyright 2011 the B<Module::LocalLoad> L</AUTHOR> and L</CONTRIBUTORS> as
listed above.

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

# vim: set ts=2 et sw=2:
