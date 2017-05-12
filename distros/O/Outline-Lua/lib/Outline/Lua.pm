package Outline::Lua;

use warnings;
use strict;

use Scalar::Util qw( looks_like_number );
use List::Util qw( first );

our $VERSION = '0.11';
our $TRUE    = Outline::Lua::Boolean->true;
our $FALSE   = Outline::Lua::Boolean->false;

require XSLoader;
XSLoader::load('Outline::Lua', $VERSION);

sub register_perl_func {
  my $self = shift;
  my %args = @_;

  $args{perl_func} = $args{func} if defined $args{func} and not defined $args{perl_func};

  defined $args{$_} or die "register_perl_func: required argument $_" for qw( perl_func );

  ($args{lua_name} = $args{perl_func}) =~ s/.*::// if not defined $args{lua_name};

  $self->_add_func( $args{lua_name},
                    \%args );
}

sub register_vars {
  my $self  = shift;

  my %args  = @_;

  while (my ($lua_name, $perl_var) = each %args) {
    $self->_add_var( $lua_name, $perl_var );
  }
}

sub run {
  my $self  = shift;

  $self->_run(@_);
}

sub _table_to_ref_p { # the p stands for perl to make it different from the XS one.
  my $want_array = shift;

  # Uhh ... what am I doing? Passing in pairs of stuff...
  # If we want an array, sort the keys and take the values;
  # if we want a hash, well, we have a hash.
  # OK here goes.
  my %gumpf = @_;

  if (my $keys = _try_lua_array(%gumpf)) {
    return $keys;
  }
  
  return \%gumpf unless $want_array;
  return [ @gumpf{ sort { _key_cmp($a, $b) } keys %gumpf } ];
}

sub _try_lua_array {
  my %hash = @_;
  return if( first { /\D/ } keys %hash );

  my @keys = sort { $a + 0 <=> $b + 0 } keys %hash;
  return if ($keys[0] != 1 or $keys[-1] != scalar @keys);

  return \@keys;
}

# Sort the keys numbers first in number order, then strings in string order
sub _key_cmp {
  my ($a, $b) = @_;

  return -1 if looks_like_number($a) and not looks_like_number($b);
  return  1 if looks_like_number($b) and not looks_like_number($a);

  return $a <=> $b if looks_like_number($a) and looks_like_number($b);
  return $a cmp $b; 

}

# The Boolean class is used to create $Outline::Lua::TRUE and 
# $Outline::Lua::FALSE. These are values specifically different from any other
# value in order that we can convert between Lua's boolean type and Perl's
# slightly more arbitrary truth concept.

package Outline::Lua::Boolean;

use overload (bool => sub { 
                shift->[0] ? 1 : "" 
              },
#              "==" => sub {
#                my ($lhs, $rhs) = @_;
#                return ($lhs && $rhs) || (!$lhs && !$rhs);
#              },
              fallback => 1,
);

sub true { bless [1], shift };

sub false { bless[ "" ], shift };

1;

__END__

=head1 NAME

Outline::Lua - Run Lua code from a string, rather than embedded.

=head1 VERSION

Version 0.10

=head1 DESCRIPTION

Register your Perl functions with Lua, then run arbitrary Lua
code.

=head1 SYNOPSIS


    use Outline::Lua;

    my $lua = Outline::Lua->new();
    $lua->register_perl_func(perl_func => 'MyApp::dostuff');

    if (my $error = $lua->run($lua_code)) {
      die $lua->errorstring;
    }
    else {
      my @return_vals = $lua->return_vals();
    }

=head1 TYPE CONVERSIONS

Since this module is designed to allow Perl code to be run from
Lua code (and not for Perl code to be able to call Lua functions),
type conversion happens in only one situation for each direction:

=over

=item 

Perl values are converted to Lua when you return them I<from> 
a Perl function, and when you I<register> them to your Lua object.

=item

Lua values are converted to Perl when you provide them as 
arguments I<to> a Perl function.

=back

Most Lua types map happily to Perl types. Lua has its own rules
about converting between types, with which you should be familiar.
Consult the Lua docs for these rules.

Outline::Lua, nevertheless, will try to help you on your way.

B<Note:> You should definitely read about Booleans because this is
the only place where it is not automagic.

=head2 Numbers and Strings

If you have an actual number you will get a number. If you have a
string that is a number, it will still be a string on the other
side. Basically, you should experience the same behaviour as in
Perl:

  sub ret_num {
    10.000;
  }
  sub ret_str {
    "foo";
  }
  sub ret_str_num {
    "10.000";
  }

  # register them, then ...

  $lua->run("a = ret_num()");     # a is 10.0
  $lua->run("b = ret_str()");     # b is "foo"
  $lua->run("c = ret_str_num()"); # c is "10.000"


=head2 Arrays and Hashes

Arrays and hashes are the same in Lua but not in Perl. Your
Perl arrayref or hashref will appear in Lua as a table.

If you return an array or hash it will be treated as a list,
as with in Perl, so it will be treated as multiple return
variables.

The other way,the module will attempt to detect whether your hash 
is a Lua array or not. To do this, it tests whether your hash keys
start at 1 and continue in unbroken integer sequence until they
stop. If they do, it is considered an array and you get an
array ref back.

Otherwise you get a hash ref back.

=head2 Booleans

Lua has a boolean type more explicitly than Perl does. Perl is
happy to take anything that is not false as true and have done
with.

Therefore, two Perl variables exist, C<$Outline::Lua::TRUE> and
C<$Outline::Lua::FALSE>. These can be used in any boolean context
and Perl will behave correctly (since operator 'bool' is 
overloaded). 

When a boolean-typed value is given to us from a Lua call it will
be converted to one of these and you can test it happily. This
has the side effect of allowing you to use it as a string or number
as well, using Perl's normal conventions.

When you wish to return a boolean-typed value back to Lua from
your Perl function, simply return $Outline::Lua::TRUE or
$Outline::Lua::FALSE and it will be converted back into a Lua
boolean.

Unfortunately this is a necessary evil because of Lua's true/false
typing. There is no reasonable way of knowing that you intended to
return a true or false value back to Lua because the Lua code gives
no clues as to what sort of variable is being assigned *to*: 
there is no context.

Lua is dynamic like Perl, so in some cases you might be able to 
expect it to Do The Right Thing. That, however, is up to Lua.

=head2 undef and nil

These two are functionally identical, or at least so much so that
they are converted between one another transparently.

=head2 Functions

Functions in Lua are equivalent to coderefs in Perl, but I just
haven't got around to implementing them yet.

=head1 EXPORT

Currently none.

=head1 FUNCTIONS

=head2 new

Create a new Outline::Lua object, with its own Lua environment.

Unlike many OO modules, this one has C<new> as a function, not
a class method:

  my $lua = Outline::Lua::new;

This is because it is XS and wrapping it was too much effort.

=head1 METHODS


=head2 register_perl_func

Register a Perl function by (fully-qualified) name into the Lua
environment. Currently upvalues and subrefs are not supported.

B<Args>

TODO: support a) upvalues, b) subrefs and c) an array of hashrefs.

=over

=item {perl_func|func} => string

The fully-package-qualified function to register with Lua.

=item lua_name => string

The name by which the function will be called within the Lua script.
Defaults to the unqualified name of the perl function.

=back

=head2 register_vars

Install variables into the Lua environment.

B<Args>

This method takes a hash, which is to be C<< lua_name => $perl_var >>.
The provided variable will then be converted to a Lua type and will
be available in your Lua code as C<lua_name>.

See above regarding type conversion (particularly booleans).

=head2 run

Run lua code! Currently, the return values from the Lua itself have
not been implemented, but that is a TODO so cut me some slack.

B<Args>

=over

=item $str

A string containing the Lua code to run.

=back

=head1 AUTHOR

Alastair Douglas, C<< <altreus at perl.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-outline-lua at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Outline-Lua>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 TODO

=over

=item Function prototypes

To give the converter a bit of a clue as to what we're trying to
convert to.

=item Always/sometimes/never array conversion

Part of the above, we can implicitly convert any hash into an array
if we want to.

=item Func refs

Registering a Perl funcref instead of a real function is possible
but I haven't got around to stealing it from Tassilo von Parseval
yet.

=item Return values from the Lua itself

Have not yet implemented the return value of the Lua code itself,
which is supposed to happen.

=back

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Outline::Lua


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Outline-Lua>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Outline-Lua>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Outline-Lua>

=item * Search CPAN

L<http://search.cpan.org/dist/Outline-Lua>

=back


=head1 ACKNOWLEDGEMENTS

Thanks or maybe apologies to Tassilo von Parseval, author of Inline::Lua.
I took a fair amount of conversion code from Inline::Lua, which module
is the whole reason I wrote this one in the first place: and I think
I'll be nicking a bit more too!

=head1 COPYRIGHT & LICENSE

Copyright 2009 Alastair Douglas, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.
