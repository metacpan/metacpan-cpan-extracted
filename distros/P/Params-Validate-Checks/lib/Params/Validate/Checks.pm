package Params::Validate::Checks;

=head1 NAME

Params::Validate::Checks - Named checks for use with Params::Validate

=head1 SYNOPSIS

  use Params::Validate::Checks qw<validate as>;

  sub random_insult
  {
    my %arg = validate @_,
    {
      name => {as 'string'},
      words => {as 'pos_int'},
      paragraphs => {as 'pos_int', default => 1},
    };

    # Do something with $arg{name}, $arg{words}, $arg{paragraphs} ...
  }

=cut


use warnings;
use strict;

use Carp qw<croak>;

use base qw<Exporter>;

use Params::Validate qw<:all>;


our $VERSION = 0.01;


=head1 DESCRIPTION

L<Params::Validate> lets you precisely specify what are valid arguments to your
functions and methods, helping to catch errors sooner and make your programs
more robust.  But if multiple parameters (in either the same or different subs)
have the same spec it's tedious to have to repeat this.  So
C<Params::Validate::Checks> provides:

=over 2

=item *

standard, named checks for use in C<Params::Validate> specifications

=item *

a way of you defining more named checks for your own re-use

=back

=head2 Basic Use

Import C<validate> and C<as>, then read a function's arguments into a hash by
calling the C<validate> function.  Pass it C<@_> and a hash-ref specifying your
function's named parameters:

  sub total_price {
    my %arg = validate @_, {
      unit_price => {as 'pos_int'},
      quantity => {as 'pos_int'},
    };

Each key in the hash-ref is a parameter's name; the corresponding value is
specified in braces with C<as> followed by the name of the check to apply to
that parameter.

If all the checks pass then your hash will be populated with the supplied
arguments.

But if there's a problem with the arguments then your function will abort with
an appropriate error message.  This could happen in any of these situations:

=over 2

=item *

a compulsory argument is missing

=item *

an argument is supplied but its contents don't pass its check

=item *

an unexpected argument has been supplied

=back

=cut


# Since we've used all of Params::Validate we can re-export any of its
# functions, plus as which we've created:
our @EXPORT_OK = (@Params::Validate::EXPORT_OK, 'as');

# Export as by default, since it's the main purpose of this module:
our @EXPORT = (@Params::Validate::EXPORT, 'as');

# Make the Params::Validate tags work too; we have to do a deep copy of the tag
# we're changing, so that the original is left intact:
our %EXPORT_TAGS = %Params::Validate::EXPORT_TAGS;
$EXPORT_TAGS{all} = [@{$EXPORT_TAGS{all}}, 'as'];

# registered checks:
my %Check;


sub as
{
  my $name = shift;

  my $check = $Check{$name} or croak "Check $name isn't defined";

  # Each check is a hash-ref; dereference it, so that we're returning items
  # suitable for the caller to put in a hash, and send back to the caller any
  # additional options that they sent us (because syntactically it's less
  # hassle for them to send them here than distinguish them):
  (%$check, @_);
}


=head2 Standard Checks

These standard checks are supplied by this module:

=over

=item C<pos_int>

a positive integer, such as "42" (but not "0", "007", or "24A")

=item C<string>

a single-line string that isn't just whitespace, such as "yellow spog" (but not
"" or " ", nor anything with a line-break in it); note that unlike using
C<SCALAR> in C<Params::Validate> this does permit objects which stringify to an
appropriate value, such as C<Path::Class> objects

=back

Currently there's just those two because they're the only 'generic' checks
I've needed, but it's likely more will be added -- requests welcome!

For checks specific to a particular field it makes more sense to distribute
them in a separate module, especially when they depend on other modules; for
example L<Params::Validate::Checks::Net> contains some checks useful for
dealing with network-related things, such as domain names and IP addresses.  

=cut


{

  # Allow for tested arguments being undef:
  no warnings qw<uninitialized>;

  register
  (
    pos_int => qr/^[1-9]\d*\z/,

    string =>
    {
      callbacks =>
      {
        'not empty' => sub { $_[0] =~ /\S/ },
        'one line' => sub { $_[0] !~ /\n/ },
      },
    },
  );
}


=head2 More Advanced Use

All of L<Params::Validate>'s features and flexibility can be used, and for
convenience any of its functions can be imported via
C<Params::Validate::Checks>, so you don't need 2 C<use> lines.  (The C<:all>
tag imports everything C<Params::Validate> would plus C<as> from this module.)

You can add options to individual checks, such as C<optional> to make a
parameter optional:

  my %arg = validate @_,
  {
    forename => {as 'string'},
    middle_name => {as 'string', optional => 1},
    surname => {as 'string'},
  };

or C<default>, which makes it optional to the caller but ensures your hash
always has a value for it:

  my %arg = validate @_,
  {
    colour => {as 'string', default => 'red'},
    quantity => {as 'pos_int', default => 99},
  };

You can mix named checks with 'one off' checks that are defined directly using
C<Params::Validate> syntax:

  my %arg = validate @_,
  {
    quantity => {as 'pos_int', default => 1},
    product_code => {regex => qr/^[DOSW]\d{4}\z/},
  };

You can use C<validate_pos> to validate positional parameters:

  use Params::Validate::Checks qw<validate_pos as>;
  my ($x, $y) = validate_pos @_, {as 'pos_int'}, {as 'pos_int', default => 0};

For details of these features and more, see L<Params::Validate>.

=head2 Defining New Checks

It's simple to define a new check, just call
C<Params::Validate::Checks::register> with the name and functionality of the
check.  This can be specified as a pattern:

  Params::Validate::Checks::register sort_code => qr/^\d\d-\d\d-\d\d\z/;

or a function to do the checking; the function is invoked each time an argument
is being checked, with the argument passed as a parameter:

  Params::Validate::Checks::register postcode => \&valid_postcode;

or as a hash-ref of a C<Params::Validate> spec:

  Params::Validate::Checks::register template => {isa => 'Template'};

While you can do this in the same file that's using the checks, the intention
is to create libraries of checks -- you can put checks for things like product
codes, office identifiers, and internal hostnames in a library for your
organization.  And checks for 'generic' things like e-mail addresses,
postcodes, country codes, CSS colours, and so on can be put in modules
contributed to Cpan.

Note C<register> isn't exported (because creating checks should be rarer than
using them), but you can define multiple checks in a single call, so a library
of checks can -- in its entirety -- be as simple as:

  package PopCorp::Params::Validate::Checks;
  use Params::Validate::Checks;

  Params::Validate::Checks::register
    playing_card => qr/^(?:[A2-9JQK]|10)[CDHS]\z/,
    room_number => qr/^[0-2]\.[1-9]\d*\z/,
    palindrome => sub { $_[0] eq reverse $_[0] };

C<register> returns a true value, so it's valid to call it as the last thing in
a package, as in the above example.

=cut


sub register
{

  # For each check provided turn it into a hash suitable for using directly in
  # a Params::Validate specification:
  while (@_)
  {
    my $name = shift;
    my $test = shift or croak "Registering $name failed: no check specified";

    warn "Overwriting existing check for $name" if $Check{$name};

    my $type = ref $test || 'scalar';

    my $check;

    # If we've been given a hash-ref then presume it's already what's required:
    if ($type eq 'HASH')
    {
      $check = $test;
    }

    # For convenience allow patterns to be specified directly, so wrap them
    # appropriately:
    elsif ($type eq 'Regexp')
    {
      $check = {regex => $test};
    }
    
    # Ditto for subs; these need names (to use in the error message), so re-use
    # this check's name:
    elsif ($type eq 'CODE')
    {
      $check = {callbacks => {$name => $test}};
    }

    else
    {
      croak "Unrecognized check type passed for $name: $type";
    }

    $Check{$name} = $check;
  }

  # Ensure it's OK to use this as the only (and therefore last) thing in a
  # module:
  1;
}


=head1 FUTURE PLANS

More checks, such as for other sorts of numbers, are likely to be added as uses
for them are encountered.

And I suspect it'll be useful to add a way of defining a check as a list of
permitted values.

=head1 CAVEATS

This module is still in its infancy; it's possible that development based on
experience of using it will require making backwards-incompatible changes to
its interface.

Currently there is a global list of all registered checks, so it isn't possible
for two different libraries (used non-overlappingly) to declare different
checks with the same name.

=head1 SEE ALSO

=over 2

=item *

L<Params::Validate>, which provides most of the functionality here

=item *

L<Params::Validate::Checks::Net>, for an example of creating a library of
additional checks

=item *

Alternative modules for checking parameters, with different syntaxes:
L<Params::Check> and L<Params::Util>

=back

=head1 CREDITS

Written and maintained by Smylers <smylers@cpan.org>

Thanks to Aaron Crane for help with the design, and Ovid for spotting a bug.
And of course thank you to Dave Rolsky for creating C<Params::Validate>.

=head1 COPYRIGHT & LICENCE

Copyright 2006-2008 by Smylers.

This library is software libre; you may redistribute it and modify it under the
terms of any of these licences:

=over 2

=item *

L<The GNU General Public License, version 2|perlgpl>

=item *

The GNU General Public License, version 3

=item *

L<The Artistic License|perlartistic>

=item *

The Artistic License 2.0

=back

=cut


1;
