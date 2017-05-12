package SOOT;
use 5.008001;
use strict;
use warnings;
use Carp 'croak';

our $VERSION = '0.17';

use Alien::ROOT;
use vars '$Alien';
BEGIN {
  $Alien = Alien::ROOT->new;
  if (not $Alien->installed) {
    Carp::croak(
      "Alien::ROOT could not detect an installation of the ROOT library"
    );
  } elsif ($Alien->features !~ /\bexplicitlink\b/) {
    Carp::croak(
      "The version of ROOT that was found was not built with the"
      . " --explicitlink option, which is required for SOOT"
    );
  }
  $Alien->setup_environment;
}

use base 'Exporter';
use SOOT::Constants;
use TObject; # needs to happen before XSLoader
use TArray;
use TClass;

our %EXPORT_TAGS = (
  'globals' => [ qw(
    $gApplication $gSystem $gRandom $gROOT
    $gDirectory $gStyle $gPad $gBenchmark
    $gEnv
    $gVirtualX
    $gHistImagePalette $gWebImagePalette
  ) ],
  'constants' => \@SOOT::Constants::Names,
  'functions' => [qw( Load UpdateClasses Run )],
);
use vars @{$EXPORT_TAGS{globals}};

our @EXPORT_OK = map {@$_} values %EXPORT_TAGS;
$EXPORT_TAGS{all} = \@EXPORT_OK;

our @EXPORT;

require XSLoader;
XSLoader::load('SOOT', $VERSION);

sub AUTOLOAD {
    # This AUTOLOAD is used to 'autoload' constants from the constant()
    # XS function.

    my $constname;
    our $AUTOLOAD;
    ($constname = $AUTOLOAD) =~ s/.*:://;
    croak "&SOOT::constant not defined" if $constname eq 'constant';
    my ($error, $val) = constant($constname);
    if ($error) { croak $error; }
    {
        no strict 'refs';
        # Fixed between 5.005_53 and 5.005_61
#XXX    if ($] >= 5.00561) {
#XXX        *$AUTOLOAD = sub () { $val };
#XXX    }
#XXX    else {
            *$AUTOLOAD = sub { $val };
#XXX    }
    }
    goto &$AUTOLOAD;
}

sub Run { $SOOT::gApplication->Run() }

sub Load {
  shift if @_ and defined $_[0] and $_[0] eq 'SOOT';
  Carp::croak("Usage: SOOT->Load(classname, classname2, ...)")
    if not @_;

  my $new = 0;
  foreach my $class (@_) {
    no strict 'refs';
    no warnings 'once';
    next if defined ${"${class}::isROOT"};
    GenerateROOTClass($class);
  }
  
  return $new;
}

sub UpdateClasses {
  shift if @_ and defined $_[0] and $_[0] eq 'SOOT';
  Carp::croak("Usage: SOOT->UpdateClasses()")
    if @_;
  GenerateClassStubs();
  return 1;
}

# For some reason, the normal gBenchmark from XS will segfault on first use.
# Thus we initialize it here...
use vars '$gBenchmark';
$gBenchmark = TBenchmark->new;


1;
__END__

=head1 NAME

SOOT - Use ROOT from Perl

=head1 SYNOPSIS

  use SOOT ':all';
  # more to follow

=head1 DESCRIPTION

SOOT is a Perl extension for using the ROOT library. It is very similar
to the Ruby-ROOT or PyROOT extensions for their respective languages.
Specifically, SOOT was implemented after the model of Ruby-ROOT.

Please note that SOOT is to be considered highly experimental at this point.
It uses a very dynamic approach to wrapping a very large and quickly
evolving library. Due to the dynamic nature (using the CInt introspection),
SOOT is able to handle most of the ROOT classes without explicitly
wrapping them. Some things are expected to not work because not enough
information about the API can be obtained automatically. Let me know
what you need and what is giving you problems and we'll work out a solution.

In order to install and use SOOT, you need a configured ROOT library.
In particular, it is necessary that the F<root-config> tool be executable
and findable via your C<PATH> environment variable. Alternatively, you
may set the C<ROOTSYS> environment variable. Please refer to the ROOT
manual for details.

=head2 Exports

By default, using SOOT does not export anything into your namespace.
You may choose to import the various ROOT-related global variables
and/or constants into your namespace either by explicitly listing them
as arguments to C<use SOOT> or by importing the C<:globals>,
C<:constants>, or C<:all> tags:

  use SOOT ':all';
  # you now have $gApplication, $gSystem, kWhite etc

  use SOOT qw($gApplication $gSystem);
  # you now have only $gApplication and $gSystem
  # you always have $SOOT::gApplication, etc!

  use SOOT qw(kRed kDotted);
  my $graph = TGraph->new(3);
  $graph->SetLineColor(kRed);
  $graph->SetLineStyle(kDotted);

The list of currently supported globals is:

  $gApplication $gSystem $gRandom $gROOT
  $gDirectory   $gStyle  $gPad    $gBenchmark
  $gEnv
  $gVirtualX
  $gHistImagePalette $gWebImagePalette

The list of currently exported functions:

  Load(className, className2,...)
  UpdateClasses()
  Run()

=head1 JUMP-START FOR C++-ROOT USERS

This section outlines the differences between using
ROOT from C++ or from Perl via SOOT. If in doubt, the two
should behave the same, but there are a few subtle differences
that a user must be aware of and these should be documented
here. If not, it's a bug. 

Note about terminology: When referring to a ROOT object,
the underlying C++, TObject-derived object is meant.
If the document mentions SOOT objects, that is the Perl-level
wrapper object.

=head2 Memory Management

ROOT has a fairly complex idea of object ownership which is
documented in its own section of the
L<Users Manual|http://root.cern.ch/drupal/content/users-guide>.
SOOT tries to implement a relatively simple and consistent
memory management:

Any object that was created with a constructor is SOOT's
responsibility to clean up. All other objects are, by default,
not freed by SOOT. That means for objects created with C<new()>,
the memory of the underlying ROOT object will be freed when
the last Perl-side reference to it goes out of scope.
SOOT implements its own reference counting "garbage collection"
in that you can create copies of SOOT objects that refer to
the same underlying ROOT object and there will be double-freed memory.
Examples:

  sub test {
    my $graph = TGraph->new(2, [0., 1.], [3., 5.]);
    SCOPE: {
      my $axis = $graph->GetXaxis();
      my $otheraxis = $graph->GetXaxis();
      # $axis and $otheraxis are really the same TObject underneath
    }
    # $axis and $otheraxis cease to exist, but don't free their TAxis
    # objects because that would create a segmentation fault.
  }
  test();
  # $graph won't exist here due to my's lexical scoping.
  # $graph will free the memory of the underlying TGraph*!
  # This also frees the TAxis and other sub-structures of the graph.

Sometimes, this behaviour is not what you want. You can usually work
around any problems by keeping references to objects around so that
they're not freed earlier than you would like. Alternatively, you can
manually mark objects as being owned by ROOT or SOOT:

  # doesn't work because $cv goes out of scope
  sub draw_histogram {
    my $hist = shift;
    my $cv = TCanvas->new("cv", "Awesome plot");
    # style histogram and canvas here...
    $hist->Draw();
  }
  my $histogram = ...
  draw_histogram($histogram);
  # $cv out of scope!

  # Workaround 1: Pass around references.
  sub draw_histogram2 {
    my $hist = shift;
    my $cv = TCanvas->new("cv", "Awesome plot");
    $hist->Draw();
    return $cv;
  }
  my $histogram = ...
  my $canvas = draw_histogram($histogram);

  # Workaround 2: Mark canvas object as global
  sub draw_histogram3 {
    my $hist = shift;
    my $cv = TCanvas->new("cv", "Awesome plot")->keep;
    $hist->Draw();
  }
  my $histogram = ...
  draw_histogram($histogram);
  # $cv is gone, but the TCanvas is held by ROOT.
  # If necessary, you can get it again via $gROOT:
  my $same_cv = $gROOT->FindObject('cv');
  # ...
  # Later, you can manually delete an object:
  $same_cv->delete; # deletes the UNDERLYING ROOT object, too!

The above examples introduce three methods for manual memory management that
are useful enough to highlight them again: C<keep()> marks a SOOT object
as a global, that is, ROOT will hold on to the underlying TObject even if
all SOOT references to it have been garbage collected. C<keep()> will
return the same SOOT object it was called on, for convenience.

In order to gain access to a ROOT object that is no longer accessible via
SOOT, you can use the usual C<FindObject('name')> method of the C<TROOT>
class via the C<$gROOT> (or C<$SOOT::gROOT>) global. This highlights
an important detail about the ROOT wrapper: C<FindObject> returns a generic
C<TObject*>. In C++, you would cast it into a C<TCanvas*>:

  TCanvas* same_cv = (TCanvas*)gROOT->FindObject('cv');

In the context of SOOT, explicit casting is usually not necessary. In the
rare case where it is, it is done with the C<as('Typename')> method:

  my $same_cv = $gROOT->FindObject('cv')->as('TCanvas');

C<as('Typename')> returns a copy of the SOOT object it is called on with a new type
(not a copy of the ROOT object, just of the SOOT wrapper).
Finally, the C<delete()> method forcefully deletes a ROOT object and all of
its SOOT wrappers. It is possible to use this to crash the program, so beware and
use it sparingly.

=head2 Object Behaviour

Some operations are overloaded for all SOOT objects. Currently,
you can use the C<==> comparison to check whether two SOOT objects
refer to the same ROOT object:

  my $graph1 = TGraph->new(2, [1., 2.], [3., 4.]);
  my $graph2 = TGraph->new(1, [4.], [8.2]);
  my $g1_copy = $graph1; # actually a shallow copy...
  
  say '$graph1 and $g1_copy are the same'
    if $graph1 == $g1_copy;
  
  say '$graph1 and $graph2 are the same'
    if $graph1 == $graph2;

This will print:

  $graph1 and $g1_copy are the same

=head2 Availability of ROOT Classes

By default, SOOT loads most of the available ROOT classes and
wraps them for use in Perl. If some class is not available,
you may try to load it as follows:

  SOOT::Load( qw(TSomeClass TAnotherClassILike) );

C<Load> will automatically try to load the specified classes' base
classes as well. In future, it might be extended to inspect the
class members and load any other ROOT classes that are part of its
interface.

If you want to use classes from a shared library that is not
loaded by default, everything should work if you do the following:

  $gSystem->Load('libGeom.so');
  $gSystem->Load('libGeomBuilder.so');
  SOOT::UpdateClasses(); # Bind ALL new classes

Alternatively you may bind only what you need:

  $gSystem->Load('libGeom.so');
  $gSystem->Load('libGeomBuilder.so');
  SOOT::Load('TGeoMaterial'); # or whatever

Updating all classes may be a relatively slow operation.
A third approach is using the special TSystem::LoadNUpddate method
which is not part of the normal ROOT interface:

  $gSystem->Load('libGeom.so');
  $gSystem->LoadNUpdate('libGeomBuilder.so');

C<LoadNUpdate()> will bind any new classes B<if> the library was loaded
successfully and wasn't loaded before.

=head2 Assorted Differences

A few ROOT classes have been wrapped explicitly in a way that makes them more
useful from a Perl point of view than simply providing the exact same interface
as in C++. These are briefly laid out here:

=head3 TArrayD, TArrayF, etc.

The constructors of the C<TArrayX> classes take an array reference
of values as parameter that is copied into the C<TArray>-object.
The C<GetArray()> method returns the data as a new array reference:

  my $ary = TArrayD->new([1.3, 2.5]);
  my $copy = $ary->GetArray(); # $copy is now [1.3, 2.5]

=head3 TRandom

C<TRandom::Rannor()> is called without arguments from Perl and returns two
random numbers instead of using references.

=head3 TExec

C<TExec> callbacks can handle both CINT callbacks and Perl callbacks:

  my $te = TExec->new("name", "Some::CINT::Callback()");
  $te->Exec();
  my $te2 = TExec->new("name2", sub {print "Perl says hi\n"});
  $te->Exec();

The same applies to the C<TPad::AddExec()> method, but in that case,
for each C<AddExec> call, we currently leak one C<SV*> pointing to
the Perl callback function.

=head1 FUNCTIONS

=head2 Load

Loads one or more ROOT classes and their base classes into Perl.
Virtually all ROOT classes should be loaded out of the box.
This function is only necessary if you load additional
shared libraries.

=head2 Run

Simple shortcut for C<<$SOOT::gApplication->Run()>>.
can be called as function or class method.

=head2 UpdateClasses

After loading non-standard shared libraries that provide ROOT-based classes,
it may be necessary to update the Perl-bindings for those classes. You may
either use C<Load()> if you know which exact classes you want to bind, or
you may call C<SOOT::UpdateClasses()> to check the whole ROOT class table
for classes that were previously not available to Perl.

=head1 INSTALLATION

Eventually, SOOT I<might> be shipped with ROOT. Until that happens,
you need to do the following: Set your ROOT paths as usual. Make sure
the F<root-config> program is available and executable via the C<PATH>.

Then build SOOT like any other CPAN module. To install a release from CPAN,
type:

  sudo cpan SOOT

To do so manually, do:

  tar -xzf SOOT-0.XX.tar.gz
  cd SOOT-0.XX
  perl Makefile.PL
  make
  make test
  (sudo make install)

Without installing, you may run the SOOT examples from the SOOT directory
where you just typed C<make> as follows:

  perl -Mblib examples/Hist/hstack.pl

The C<-Mblib> indicates that perl should preferably load modules from the
F<blib> (read: C<build-library>) directory of the current directory which
contains the uninstalled SOOT library.

B<NOTE:> At this point, SOOT requires a copy of ROOT that has been configured
with the C<--enable-explicitlink> option, which -- sadly -- isn't the default.

=head1 SEE ALSO

L<http://root.cern.ch>

L<SOOT::API> exposes some of the underlying SOOT-internals.

L<SOOT::Struct> allows for run-time creation/compilation of ROOT/C-level structs.
Structs created this way are available from Perl.

L<SOOT::App> implements a F<root.exe>/CInt-like front-end
using L<Devel::REPL>. It is not part of SOOT and is available
separately from CPAN.

=head1 ACKNOWLEDGMENTS

Eric Wilhelm and David Golden put up with my stupid questions about Module::Build
and always stayed civil and helpful. Thanks for that!

=head1 AUTHOR

Steffen Mueller, E<lt>smueller@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010, 2011 by Steffen Mueller

SOOT, the Perl-ROOT wrapper, is free software; you can redistribute it and/or modify
it under the same terms as ROOT itself, that is, the GNU Lesser General Public License.
A copy of the full license text is available from the distribution as the F<LICENSE> file.

=cut

