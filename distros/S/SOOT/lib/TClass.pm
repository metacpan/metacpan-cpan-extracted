package # hide from PAUSE
  TClass;
use strict;
use warnings;

sub soot_method_complete {
  my $self = shift;
  my $stub = shift;
  my $exact = shift;
  my $candidates = $self->_soot_method_complete_internal(defined($stub) ? $stub : "", 0, $exact ? 1 : 0);

  my @rv;
  foreach my $cand (@$candidates) {
    next unless $cand =~ s/^(\S+)\s+((?:\w+::)+)(\w+)\(//;
    my ($ret_type, $class, $methname) = ($1, $2, $3);
    $class =~ s/::$//;
    chop($cand); # closing paren

    my $struct = {
      class => $class, method => $methname, return_type => $ret_type,
      parameters => [],
    };
    push @rv, $struct;

    my @ps = split /,/, $cand;
    my $params = $struct->{parameters};
    foreach my $p (@ps) {
      $p =~ /^(.*\S)\s+(\S+)$/
        or die "Invalid parameter spec (or faulty parse attempt): '$p'";
      my ($t, $n) = ($1, $2);
      ($n, my $def) = split /=/, $n, 2;
      push @$params, [$t, $n, defined($def) ? ($def) : () ];
    }
  }
  return @rv;
}

sub soot_method_complete_proto_str {
  my $self = shift;
  my $stub = shift;
  my $exact = shift;
  my $candidates = $self->_soot_method_complete_internal(defined($stub) ? $stub : "", 0, $exact ? 1 : 0);
  return @$candidates;
}

sub soot_method_complete_name {
  my $self = shift;
  my $stub = shift;
  my $exact = shift;
  my $candidates = $self->_soot_method_complete_internal(defined($stub) ? $stub : "", 1, $exact ? 1 : 0);
  return @$candidates;
}

1;

__END__

=head1 NAME

TClass - ROOT's TClass introspection interface with SOOT extensions

=head1 SYNOPSIS

  use SOOT ':all';
  # Make a ROOT object:
  my $hist = TH1D->new("name", "title", 100, 0., 1.);
  my $class = $hist->Class(); # this is a TClass
  # ... introspect here ...

=head1 DESCRIPTION

C<TClass> is the ROOT meta-class representing introspective information about
a ROOT class. Its SOOT wrapper provides all the usual ROOT interfaces with some
Perl-specific helper methods added for convenience.

This document only describes the added SOOT-specific methods. For the rest, please
refer to the ROOT reference manual.

=head1 METHODS

=head2 soot_method_complete_name

Takes two parameters: A stub of the method name to search for, and a boolean
indicating whether to match the exact method name (true) or it's start (false, default).

Returns a list of method names in the class represented by the current TClass
object that start with the provided string (or that are exactly the same as the
provided string if the second parameter is true).

Example:

  my $hist = TH1D->new("name", "title", 100, 0., 1.);
  my $class = $hist->Class(); # this is a TClass
  my @possibilities = $class->soot_method_complete_name('Fi');
  # @possibilities is now:
  # qw(Fill FillN FindBin FindFixBin FindObject FitOptionsMake
  #    FillBuffer FillRandom FindFirstBinAbove FindLastBinAbove Fit FitPanel)
  @possibilities = $class->soot_method_complete_name('Fill', 1);
  # now: qw(Fill) since only that matches exactly.

=head2 soot_method_complete_proto_str

Takes two parameters: A stub of the method name to search for, and a boolean
indicating whether to match the exact method name (true) or it's start (false, default).

Returns a list of strings that are the C++ prototypes of different possible completions
of the provided method name. This works much the same as C<soot_method_complete_name>,
except it returns the full method prototype instead of just the method name(s).

=head2 soot_method_complete

The most generic of the C<soot_method_complete*> methods, it also takes two parameters:
the start of a method name and a flag indicating whether it's an exact method name match.

It returns an array reference of structures that describe the method prototype. This is
best explained with an example.

  my $class = TH1D->new->Class;
  my @protos = $class->soot_method_complete('FillRandom', 1);

  @protos = (
    {
      class       => 'TH1',
      method      => 'FillRandom',
      parameters  => [
        [ 'const char* fname' ],
        [ 'Int_t', 'ntimes', 5000 ]
      ],
      return_type => 'void'
    },
    {
      class       => 'TH1',
      method      => 'FillRandom',
      parameters  => [
        [ 'TH1*', 'h' ],
        [ 'Int_t', 'ntimes', 5000 ]
      ],
      return_type => 'void'
    }
  )

NB: This example neatly shows how C++ parameter-type based method polymorphism
can result in having multiple C++ methods covered by the same Perl level
method (here: C<FillRandom>). SOOT will guess the parameter types and call the
right method for you when you call C<FillRandom> on a C<TH1>.

For each matching method in the class, a hash reference is returned. Such a hash
will contain the class name where the method was originally defined as the C<class>
slot of the hash, the full name of the method that was matched as the C<method>
slot, the name of the C++ return type as the C<return_type> slot, and finally,
an array reference of method parameters as the C<parameters> slot.

Each parameter is itself described as an array reference containing two or
three elements. The first is the C++ type of the parameter, the second is the name
of the parameter, and the optional third is a default value of the parameter.

=head1 CAVEATS

The method completion works on a C++ level and considers only the ROOT methods,
not additional SOOT, Perl-level methods. This means that for example, you can't
auto-complete the C<soot_method_complete> method of a C<TClass> object itself.

This could be partially fixed by looking at the Perl stash and C<@ISA> for the
respective class, but that's currently considered overkill.

=head1 SEE ALSO

L<SOOT> is the main ROOT-wrapper module and has most of the user documentation.

=head1 AUTHOR

Steffen Mueller, E<lt>smueller@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010, 2011 by Steffen Mueller

SOOT, the Perl-ROOT wrapper, is free software; you can redistribute it and/or modify
it under the same terms as ROOT itself, that is, the GNU Lesser General Public License.
A copy of the full license text is available from the distribution as the F<LICENSE> file.

=cut

