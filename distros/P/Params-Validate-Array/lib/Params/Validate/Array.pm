package Params::Validate::Array;

use 5.008008;
use strict;
use warnings;

use base qw( Exporter );

use vars qw($VERSION @EXPORT @EXPORT_OK %EXPORT_TAGS $DOC);

our $VERSION = '0.03';

use Params::Validate ();
use Carp qw(confess);

# copy Params::Validate's EXPORT* constants
@EXPORT = @Params::Validate::EXPORT;
@EXPORT_OK = @Params::Validate::EXPORT_OK;
%EXPORT_TAGS = %Params::Validate::EXPORT_TAGS;

sub import {
  # import all of P::V except validate() and validation_options()
  Params::Validate->import(
      grep { $_ ne 'validate' and
             $_ ne 'validation_options' } @Params::Validate::EXPORT_OK
  );

  # now export all that P::V would have exported
  __PACKAGE__->export_to_level(1, @_);
}

Params::Validate::validation_options(stack_skip => 2);

sub validate(\@$) {
  my $a = $_[0];

  my $spec = $_[1];

  return Params::Validate::validate(@$a, $spec)
    unless ref $spec eq 'ARRAY';

  confess "validate(): odd number of args in specification"
    if @$spec % 2;

  # get the "keys", the 0th, 2nd, 4th, ... values of the @$spec array
  my $i = 1;
  my @keys = grep { $i++ % 2 } @$spec;

  return @{Params::Validate::validate(@$a, { @$spec } )}{@keys};
}

sub validation_options {
  my %opts = @_;

  #print "validation_options() ", join(', ', ( caller(0) )[0,3] ), "\n";
  #map { print "$_ => ", $opts{$_} || 'NULL', "\n"} keys %opts;


  $opts{stack_skip}++ if exists $opts{stack_skip};

  Params::Validate::validation_options(%opts);
}

1;

=head1 NAME

Params::Validate::Array - provide an alternative version of Param::Validate's
C<validate()> function which will return parameters as a list.

=head1 VERSION

Version 0.03

=head1 SYNOPSIS

This module's C<validate()> function is a replacement for the Params::Validate
module's C<validate()> function, returning the arguments as a list,
and not a hash as Params::Validate::validate() does.

This replacement C<validate()> requires the argument descriptor to be an array
reference, not a hash reference as in Params::Validate::validate().

=head1 Examples:

  use Params::Validate::Array qw(SCALAR ARRAYREF validate ...);

  sub foo1 {
    my ($a, $b, $c) = validate( @_,
              # note the arrayref, not a hashref as in Params::Validate
              [ a => 1,   #  types of a, b, & c are 
                b => 0,   #+ unspecified. a is mandatory,
                c => 0,   #+ b & c optional
              ]
    );

    print "a = $a\n";
    print "b = ", $b // "undefined", "\n";
    print "c = ", $c // "undefined", "\n";
  }

  foo1(a => 'hello', c => 'there');
  # prints:
  #  a = hello
  #  b = undefined
  #  c = there

  foo1(b => 1, c => 'foo');
  # throws error:
  #   "Mandatory parameter 'a' missing in call to main::foo1 ..."

  }

  sub foo2 {
    my ($x, $y) = validate( @_,
          # arrayref, not hashref
          [ x => {type => HASHREF, optional => 1},  #  hashref 'x' is optional,
            y => {type => SCALAR                },  #+ scalar 'y' mandatory
          ]
     );

    $x->{$y} = 'foo'
      if defined $x;
  }

Note that if this module's C<validate()> function is called with
a hashref argument descriptor, the behaviour reverts to that of
Params::Validate::validate():

  use Params::Validate::Array qw(SCALAR HASHREF validate);

  sub foo3 {
    my %arg = validate( @_,
              # Note hashref
              { x => {type => HASHREF, optional => 1}, 
                y => {type => SCALAR                },
              }
    );

    print "y arg is ", $arg{y}, "\n";
    ...
  }


=head1 EXPORT

Params::Validate::Array exports everything that Params::Validate
does, including C<validate()> and C<validate_pos()> by default. The
functions C<validate_with()> and C<validation_options()> as well as
constants C<SCALAR>, C<ARRAYREF>, etc are also available for export. See
L<Params::Validate> for details.

Only the behaviour of C<validate()> is changed, and only when the argument
descriptor is an arrayref. All other routines are identical to those in
Params::Validate (Except for C<validation_options()> which will increment any stack_skip => ...
argument to hide the extra layer of call stack).

=head1 SUBROUTINES/METHODS

B<my @args = validate(@_, [ I<descriptor> ]);>

In contrast to the C<validate()> subroutine in L<Params::Validate>,
which is called as:

  my %args = validate(@_, { ... } );

(where the hashref argument C<{...}> is a descriptor for the subroutine
arguments to be validated), the C<Params::Validate::Array::validate()>
subroutine in this package is called as

  my ($arg1, $arg2, ...) = validate(@_, [ ... ] );

where the contents of the descriptor C<[...]> are identical to those in the 
hashref descriptor C<{...}> of the Params::Validate call.

In fact Params::Validate::Array::validate() is little more than a wrapper, and
uses Params::Validate::validate() to do all the hard work.

=head1 AUTHOR

Sam Brain, C<< <samb at stanford.edu> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-test at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Test>.  I will be
notified, and then you'll automatically be notified of progress on your
bug as I make changes.

=head1 ACKNOWLEDGEMENTS

Thanks to Dave Rolsky for the L<Params::Validate> and
L<MooseX::Params::Validate> modules, whose perl code and test suites I plagiarized
shamelessly for this module.

=head1 LICENSE AND COPYRIGHT

Copyright 2011 Sam Brain.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

##### SUBROUTINE INDEX #####
#                          #
#   gen by index_subs.pl   #
#   on 14 Mar 2014 21:53   #
#                          #
############################


####### Packages ###########

# Params::Validate::Array ..................... 1
#   foo1 ...................................... 2
#   foo2 ...................................... 2
#   foo3 ...................................... 3
#   import .................................... 1
#   validate .................................. 1
#   validation_options ........................ 1

