package Sub::PatternMatching;

use 5.006;
use strict;
use warnings;
use Carp;
use Params::Validate qw/:all/;

require Exporter;

our $VERSION = '1.04';

our @ISA = qw(Exporter);

our %EXPORT_TAGS = (
    'all' => [
        qw(
          patternmatch
          )
    ]
);

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
  patternmatch
);

sub patternmatch {
    my @patterns = validate_with(
        params => \@_,
        spec   => [
            { type => HASHREF | ARRAYREF },
            { type => CODEREF },
            (
                ( { type => HASHREF | ARRAYREF }, { type => CODEREF } ) x
                  int( ( @_ - 2 ) / 2 )
            ),
            { type => CODEREF, optional => 1 }
        ],
        called => 'Sub::PatternMatching::patternmatch',
    );

    my $default;
    if ( @patterns % 2 ) {
        $default = pop @patterns;
    }
    else {
        $default = sub {
            croak "Unmatched parameter pattern passed "
              . "to patternmatched subroutine";
        };
    }

    my $f = sub {
        local $@;
        my $to_execute = $default;
        foreach my $i ( 0 .. @patterns / 2 - 1 ) {
            my $pat = $patterns[ $i * 2 ];
            if ( ref($pat) eq 'ARRAY' ) {
                eval { validate_pos( @_, @$pat ); };
                next if $@;
                $to_execute = $patterns[ $i * 2 + 1 ];
                last;
            }
            else {    # HASH
                eval { validate( @_, $pat ); };
                next if $@;
                $to_execute = $patterns[ $i * 2 + 1 ];
                last;
            }
        }
        goto &$to_execute;
    };

    return $f;
}

1;
__END__

=head1 NAME

Sub::PatternMatching - Functional languages' Pattern Matching for Perl subs

=head1 SYNOPSIS

  use Sub::PatternMatching;
  
  my $code_ref = patternmatch( pattern => sub {code}, ... );
  *NamedRoutine = patternmatch( more_patterns => sub{code}, ... );

  NamedRoutine( ...arguments to do pattern matching on... );
  $code_ref->( ...arguments to do pattern matching on... );

=head1 DESCRIPTION

Sub::PatternMatching implements "Pattern Matching," a programming idiom
often found in functional languages like Haskell or OCaml. Pattern Matching
refers to functions that do different things for different arguments.
It is often referred to as polymorphism as well.

The syntax is currently a bit convoluted taking away much from the benefit of
readability by replacing nested if-else constructs with pattern matching.
This is supposed to be fixed in a later release, but maintaining
backward-compatibility.

To construct a pattern matching subroutine, you assign the result of a call
to the C<patternmatch()> subroutine that is exported by the module to a
scalar or symbol table entry. C<patternmatch()> returns an anonymous
function.

The arguments to C<patternmatch()> are expected to be pairs of array or hash
references and code references like this:

  C<[ ...pattern... ] => sub { ...implementation... }>
  or
  C<{ ...pattern... } => sub { ...implementation... }>

If the pattern applies to the function arguments, the corresponding code
reference will be called with the original arguments.

=head2 PATTERNS

The patterns are evaluated in the order they were passed to the
C<patternmatch()> routine. The first that matches determines the code to
execute. Pattern evaluation is implemented using the Params::Validate module.
The syntax for a function with positional parameters is basically:

  [{conditions for param1}, {conditions for param2}, ...] => sub {...},
  [{conditions for param1}, {conditions for param2}, ...] => sub {...},
  ...

The conditions are defined exactly as you would specify conditions for
positional parameters of a subroutine using Params::Validate's
C<validate_pos()> routine. (So read the docs for that module right now.)

Similarily, patterns for named arguments are specified as follows:

  { paramname1 => {conditions for param1}, paramname2 =>... } => sub {...},
  { paramname1 => {conditions for param1}, paramname2 =>... } => sub {...},

Here, of course, the order of the parameters doesn't matter because we're
dealing with named parameters. Again, conditions are specified just as if
you were dealing with Params::Validate directly.

Please have a look at the examples section below.

There is one exception to the rule of supplying
C<[pattern] => sub{ implementation }> pairs: If, at the end of the
list of pattern pairs, you supply a single code ref, that routine will be
used as the default handler for unmatched parameters. By default, the
patternmatched subroutine will throw a fatal error when unmatched parameters
are passed in.

=head2 EXPORT

By default, the module exports the 'patternmatch' subroutine.

=head1 EXAMPLES

=head2 Example 1

If you just wanted to do different things for different numbers of arguments,
you could, for example do something like the following: (incomplete code)

  *function = pattermatch(
    [ 1           ] => sub { ... actions for one argument ... },
    [ 1, 1        ] => sub { ... actions for two arguments ... },
    [ 1, 1, 1, 0  ] => sub { ... actions for three or four args ... },
    ...
    [ (1) x $n    ] => sub { ... actions for $n arguments ... },
    ...
    [ (1) x @_    ] => sub { ... arbitrary number of arguments ... },
  );

=head2 Example 2

The following example implements a simple-minded data structure dumper that
can deal with arbitrarily nested hashes, arrays, and scalars.

  use strict;
  use warnings;
  use Sub::PatternMatching;
  use Params::Validate qw/:all/;
  
  my $simple_dumper;
  $simple_dumper = patternmatch(
    [{ type => HASHREF }] => 
      sub {
             "HASH {\n"
             . join(",\n", map {
                                 "$_: "
                                 . $simple_dumper->($_[0]{$_})
                           } keys %{$_[0]}
                   )
             . "\n}"
      },
    [{ type => ARRAYREF }] => 
      sub {
             "ARRAY [\n"
             . join(",\n",
                     map { $simple_dumper->($_) } @{$_[0]}
                   )
             . "\n]"
      },
    [{ type => SCALAR }] => sub {"SCALAR ($_[0])"},
  );
  
  print $simple_dumper->([{foo => 'bar'}, 'a', [1..3]]);

=head2 Example 3

This, admittedly more involved, example demostrates a functional style
set of algebraic operators and a routine that can derive simple
algebraic formulae:

  use strict;
  use warnings;
  use lib 'lib';
  use Sub::PatternMatching 'patternmatch';
  use Params::Validate qw/:all/;
  no warnings 'once';
  
  my $stringifier = sub {
      my $obj = shift;
      my $str = ref($obj);
      if (@$obj) {
          $str .= '( '
            . join( ', ', map { ref($_) ? $_->stringify : "$_" } @$obj ) . ' )';
      }
      return $str;
  };
  my $printer = sub { print shift()->stringify, "\n" };
  *Product::stringify    = $stringifier;
  *Quotient::stringify   = $stringifier;
  *Sum::stringify        = $stringifier;
  *Difference::stringify = $stringifier;
  *Constant::stringify   = $stringifier;
  *X::stringify          = $stringifier;
  *Product::show         = $printer;
  *Quotient::show        = $printer;
  *Sum::show             = $printer;
  *Difference::show      = $printer;
  *Constant::show        = $printer;
  *X::show               = $printer;
  
  sub Product    ($$) { bless [ @_[ 0, 1 ] ] => 'Product'    }
  sub Quotient   ($$) { bless [ @_[ 0, 1 ] ] => 'Quotient'   }
  sub Sum        ($$) { bless [ @_[ 0, 1 ] ] => 'Sum'        }
  sub Difference ($$) { bless [ @_[ 0, 1 ] ] => 'Difference' }
  sub Constant   ($)  { bless [ $_[0]      ] => 'Constant'   }
  sub X          ()   { bless [            ] => 'X'          }
  
  *::derive = patternmatch(
      [ { isa => 'Constant'   } ] => sub { Constant 0 },
      [ { isa => 'X'          } ] => sub { Constant 1 },
      [ { isa => 'Sum'        } ]
          => sub {
	        my ( $l, $r ) = @{ $_[0] };
                Sum( derive($l), derive($r) );
             },
      [ { isa => 'Difference' } ]
          => sub {
                my ( $l, $r ) = @{ $_[0] };
                Difference derive($l), derive($r);
             },
      [ { isa => 'Product'    } ]
          => sub {
                my ( $l, $r ) = @{ $_[0] };
                Sum
	          Product( derive($l), $r ),
                 Product( derive($r), $l );
             }, 
      [ { isa => 'Quotient'   } ]
          => sub {
                my ( $l, $r ) = @{ $_[0] };
                Quotient
                Difference(
                  Product( derive($l), $r ),
                  Product( derive($r), $l )
                ),
                Product( $r, $r );
             },
  );
  
  my $function = Product Constant 5, X;
  
  print "We'll derive this: ";
  $function->show;
  print "\nThe derivative of the above is computed to:\n";
  
  derive($function)->show;

=head1 CAVEATS

Functional languages' compilers usually optimize away the pattern matching
overhead of evaluating the conditions for every call until a matching
condition is found. This is mostly possible because of their static typing
system which Perl proudly lacks. Therefore, using this module for pattern
matching currently takes an I<O(n)> performance hit for every call to the
patternmatching function. I<n> is the number of branches, sets of conditions.
Note that if you would implement your function with a giant if-elsif-else
construct, you would end up with I<O(n)> as well.

=head1 SUBROUTINES

This is a list of public subroutines.

=over 2

=item patternmatch

This subroutine creates (and returns) a new patternmatched function. Please
refer to the section L<PATTERNS> for details on the syntax of patterns.

  *functionname = patternmatch( PATTERN1, PATTERN2, ... );

=back

=head1 AUTHOR

Steffen Mueller, E<lt>pattern-module at steffen-mueller dot netE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2004-2006 Steffen Mueller

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=head1 SEE ALSO

Current versions of this module may be found on http://steffen-mueller.net or
CPAN.

Please send your suggestions, inquiries, and feedback to pattern-module
at steffen-mueller dot net. Bug reports should use RT or be mailed to
bug-Sub-PatternMatching@rt.cpan.org

L<Params::Validate>

=cut
