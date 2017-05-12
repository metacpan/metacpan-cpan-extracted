#!perl -w
# -*- coding: utf-8-unix; tab-width: 4; -*-
package Symbol::Values;

# Symbol::Values.pm
# ------------------------------------------------------------------------
# Revision: $Id: Values.pm,v 1.29 2005/08/27 17:24:03 kay Exp $
# Written by Keitaro Miyazaki<kmiyazaki@cpan.org>
# Copyright 2005 Keitaro Miyazaki All Rights Reserved.

# HISTORY
# ------------------------------------------------------------------------
# 2005-08-28 Version 1.07
#            - Make $@ untouched.
# 2005-08-10 Version 1.06
#            - Modefied test which failed on some platforms.
# 2005-08-07 Version 1.05
#            - Modefied test which failed on some platforms.
# 2005-08-05 Version 1.04
#            - Improved handling of name of special variables (e.g. "$:").
#            - Changed error/warning messages.
#            - More comments.
#            - Create new hash/array value if they were not in the glob
#              when the user accessed to them through hash/array method.
# 2005-08-04 Version 1.03
#            - Fixed the bug could not access to special variables.
# 2005-08-03 Version 1.0.2
#            - Changed "use 5.008" to "use 5.006".
# 2005-08-02 Version 1.01
#            - Fixed typo regarding to package name in POD document.
#            - Improved warning message handling by "use warnings::register".
#            - The "new" method will raise exception when invalid symbol name
#              was passed.
# 2005-07-31 Version 1.00
#            - Initial version.
#            - Rewrited as CPAN module.
# 2005-07-29 Wrote prototype of this module.

use 5.006;
use strict;
use warnings;
use warnings::register;
use Exporter;
use Carp;
use Symbol ();

use base 'Exporter';
our %EXPORT_TAGS = ( 'all' => [ qw(
    symbol
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );


our $VERSION = '1.07';
our $REVISION = '$Id: Values.pm,v 1.29 2005/08/27 17:24:03 kay Exp $';

=head1 NAME

Symbol::Values - Provides consistent accessing interface to values of symbol.

=head1 SYNOPSIS

  use Symbol::Values 'symbol';
  
  sub my_code { print "in original 'my_code'.\n" }
  
  # Get code object in symbol "my_code".
  my $orig_code = symbol("my_code")->code;
  
  my $wrapper = sub {
      print "before original 'my_code'.\n";
      $orig_code->();
      print "after original 'my_code'.\n";
  };
  
  # Set code object in symbol "my_code".
  symbol("my_code")->code = $wrapper;
  
  my_code(); # => before original 'my_code'.
             #    in original 'my_code'.
             #    after original 'my_code'.

=head1 DESCRIPTION

=head2 OBJECTIVE

I've been feeling that glob notation of perl is little bit funny.

One problem is that it lacks consistency in the way of 
fetching/storing values of a symbol.

See examples below.

  $code_ref = *name{CODE};    # Getting code object.
                              # This is obvious.
  
  *name{CODE} = $code_ref;    # Setting code object.
                              # THIS CODE DOES NOT WORK!!
  
  
  *name = $code_ref;          # This code works...
                              # Isn't it funny?

The other problem is readability of the code.

I think that inconsistency of the glob notation is making readability
of the code little bit difficult.

Therefore I wrote this module to provide alternative way of accessing
to the values of a symbol.

By using this module, above examples can be wrote as below.

  use Symbol::Values;
  my $sym = Symbol::Values->new('name');
  
  $code_ref = $sym->code;    # Getting code object.
  
  $sym->code = $code_ref;    # Setting code object.

I hope this module makes your code more readable.

=head2 METHODS

=over 4

=cut


=item $obj = CLASS->new($symbol_name_or_glob);

Constructor. You can pass name of symbol like "my_var" or
glob like *my_var as argument.

If the passed argument(glob or name of symbol) was not qualified
by package name, it will be qualified by current package name.

  package main;
  use Symbol::Values;
  
  our $a = 1;
  my $obj;
  
  $obj = Symbol::Values->new('a');       # name of symbol.
  $obj = Symbol::Values->new('main::a'); # same as above.
  $obj = Symbol::Values->new(*a);        # glob.
  $obj = Symbol::Values->new(*main::a);  # same as above.

There is alternative way of using "new" method:

  use Symbol::Values 'symbol';
  
  my $obj = symbol($symbol_name_or_glob);

This function "symbol" is not exported by default, so if you prefer to use
this syntactic sugar, you should import it explicitly.

=cut

sub new {
	if ($_[0] eq __PACKAGE__) {
		shift @_;
	}
	my $glob_or_sym = $_[0];
	my $r_glob;
	
	# no argument
	if (! $glob_or_sym) {
		$r_glob = Symbol::gensym();

		
	# glob was passed
	} elsif (ref(\$glob_or_sym) eq 'GLOB') {
		$r_glob = \$_[0];

	# name was passed
	} else {
		
		$glob_or_sym =~ m/\*?(?:(.*)::)?(.+)$/o;
		my $pkg  = $1;
		my $name = $2;
		
		unless ($pkg) {
			$pkg = (caller(0))[0];
		}
		
		
		my $new_symbol = 0;
		{
			no strict 'refs';

			# try to get the glob from symbol table
			$r_glob = exists ${"${pkg}::"}{$name}
				? \${"${pkg}::"}{$name} : undef;
			
			# create new name if it is not name of special variable.
			unless ($r_glob) {
				my $orig_exp = $@;
				$r_glob = eval "package $pkg; \\\*{$name}";
				$@ = $orig_exp;
				$new_symbol = 1 if exists ${"${pkg}::"}{$name};
			}
		}
		
		# Fatal error
		unless(defined $r_glob) {
			croak "Invalid name name \"$glob_or_sym\": possible typo";
		}
		
		# warn if new symbol
		if ($new_symbol) {
			warnings::warnif "Name \"${pkg}::${name}\" created: possible typo";
		}
	}
	
	bless [$r_glob]
}

*symbol = \&new;

=item $scalar_ref = $obj->scalar_ref;

Get scalar object in the symbol.

You can also assign new scalar object to a symbol.

  my $new_value = "something new";
  $obj->scalar_ref = \$new_value;

=cut

sub scalar_ref : lvalue {
	my $r_glob = $_[0]->[0];
	my $ret;
	tie $ret, '__TiedSymbol_Scalar', $r_glob;
	$ret
}

=item $scalar = $obj->scalar;

Get scalar value in the symbol.

You can also assign new scalar value to a symbol.

  my $new_value = "something new";
  $obj->scalar = $new_value;

=cut

sub scalar : lvalue {
	${$_[0]->scalar_ref}
}


=item $array_ref = $obj->array_ref;

Get array object in the symbol.

You can also assign new array object to a symbol.

  my @new_value = ("something", "new");
  $obj->array_ref = \@new_value;

=cut

sub array_ref : lvalue {
	my $r_glob = $_[0]->[0];
	my $ret;
	tie $ret, '__TiedSymbol_Array', $r_glob;
	$ret
}

=item @array = $obj->array;

Get array value in the symbol as reference.

You can also assign new array value to a symbol.

  my @new_value = ("something", "new");
  ($obj->array) = @new_value;

NOTE: You have to call array method in list context when you assign
new value.

=cut

sub array : lvalue {
	my $r_glob = $_[0]->[0];
	my $ret;

	# create new array value if not exists.
	unless (defined $_[0]->array_ref) {
		my @new;
		$_[0]->array_ref = \@new;
		*{$r_glob} =~ /^\*(.*)$/;
		my $name = $1;
		warnings::warnif('Symbol::Values',
						 "New array \"\@${name}\" created: possible typo");
	}

	tie $ret, '__TiedSymbol_Constant', scalar @{$_[0]->array_ref} unless wantarray;
	
	*{$r_glob} = [] unless defined *{$r_glob}{ARRAY};
	
	wantarray ? @{$_[0]->array_ref} : $ret
}

=item $hash_ref = $obj->hash_ref;

Get hash object in the symbol.

You can also assign new hash object to a symbol.

  my %new_value = ("something" => "new");
  $obj->hash_ref = \%new_value;

=cut

sub hash_ref : lvalue {
	my $r_glob = $_[0]->[0];
	my $ret;
	tie $ret, '__TiedSymbol_Hash', $r_glob;
	$ret
}

=item %hash = $obj->hash;

Get hash value in the symbol.

You can also assign new hash value to a symbol.

  my %new_value = ("something" => "new");
  ($obj->hash) = %new_value;

NOTE: You have to call hash method in list context when you assign
new value.

=cut

sub hash : lvalue {
	my $r_glob = $_[0]->[0];
	my $ret;
	
	# create new hash value if not exists.
	unless (defined $_[0]->hash_ref) {
		my %new;
		$_[0]->hash_ref = \%new;
		*{$r_glob} =~ /^\*(.*)$/;
		my $name = $1;
		warnings::warnif('Symbol::Values',
						 "New hash \"\%${name}\" created: possible typo");
	}

	tie $ret, '__TiedSymbol_Constant', scalar %{$_[0]->hash_ref} unless wantarray;

	*{$r_glob} = {} unless defined *{$r_glob}{HASH};
	
	wantarray ? %{$_[0]->hash_ref} : $ret
}

=item $code = $obj->code;

Get code object in the symbol as reference.

  use Symbol::Values 'symbol';
  
  sub my_func {
     print "my_func called.\n";
  }
  
  my $sub = symbol('my_func')->code;  # my $sub = \&my_func;
  $sub->(); # => my_func called.

You can also assign new code object to a symbol.

  symbol('my_func')->code = sub { print "modified code called.\n" };
  
  my_func(); # => modified code called.
  $sub->();  # => my_func called.

=cut

sub code : lvalue {
	my $r_glob = $_[0]->[0];
	my $ret;
	tie $ret, '__TiedSymbol_Code', $r_glob;
	$ret
}

=item $io = $obj->io;

Get IO object in the symbol.

You can also assign new io object to a symbol.

  use Symbol;
  
  my $obj = Symbol::Values->new('io_sym');
  my $io_obj = geniosym();
  $obj->io = $io_obj;

=cut

sub io : lvalue {
	my $r_glob = $_[0]->[0];
	my $ret;
	tie $ret, '__TiedSymbol_IO', $r_glob;
	$ret
}

=item $glob = $obj->glob;

Get glob object in the symbol.

You can also assign new glob object to a symbol.

  use Symbol::Values 'symbol';
  
  our $var1 = 1;
  our $var2 = 2;
  symbol('var2')->glob = symbol('var1')->glob; # *var2 = *var1
  print "$var2\n"; # => 2

=cut

sub glob : lvalue {
	my $r_glob = $_[0]->[0];
	my $ret;
	tie $ret, '__TiedSymbol_Glob', $r_glob;
	$ret
}

=item $format = $obj->format;

Get format object in the symbol.

You can also assign new format object to a symbol.

  format my_fmt1 =
   ......
  .
  
  # alternate way of '*my_fmt2 = *my_fmt1{FORMAT}'.
  symbol('my_fmt2')->format = symbol('my_fmt1')->format;

=cut

sub format : lvalue {
	my $r_glob = $_[0]->[0];
	my $ret;
	tie $ret, '__TiedSymbol_Format', $r_glob;
	$ret
}

=back

=head1 EXPORT

None by default.

=head1 BUGS/LIMITATIONS

=over 4

=item Speed

The cost of getting consistency of notation and readability is time.
So if the response is very important problem of your project, please consider
to use funny glob notation.

=item Taste

If you're loving default glob notation, just ignore this module.

=back

=head1 SEE ALSO

=over 4

=item perlref

Generic information about symbol table mechanism in perl.

=item Hook::LexWrap

If you want to override some existing functions/methods,
it is very nice idea to consult "Hook::LexWrap".

=item t/Symbol-Values.t

Test file "t/Symbol-Values.t" in the distribution of this module -- This file provides you some example of usage.

=back

=head1 AUTHOR

Keitaro Miyazaki, E<lt>kmiyazaki@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005 by Keitaro Miyazaki

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.


=cut


#*************************************************************************
#
# Subcontractors
#
#*************************************************************************


#-------------------------------------------------------------------------
# Base class
#-------------------------------------------------------------------------
package __TiedSymbol;

use Tie::Scalar;
use Carp;

use base ("Tie::Scalar");

sub TIESCALAR {
	my ($class, $r_glob) = @_;
	
	# field 'slot' must be specified in sublcass.
	my $self = {
				r_glob => $r_glob,
			   };

	bless $self, $class;
}

sub DESTROY {
}

sub FETCH {
	my $self = shift;
	my $slot = shift;
	my $r_glob = $self->{r_glob};
	
	my $ret;
	
	no strict 'refs';
	$ret = *{$r_glob}{$self->{slot}};
	use strict 'refs';
	
	$ret
}

sub STORE {
	# Should be overridden in subclass
}

#-------------------------------------------------------------------------
# SCALAR
#-------------------------------------------------------------------------
package __TiedSymbol_Scalar;
use base ("__TiedSymbol");
use Carp;

sub TIESCALAR {
	my $class = shift;
	my $self = $class->SUPER::TIESCALAR(@_);
	$self->{slot} = 'SCALAR';
	$self
}

sub STORE {
	my $self = shift;
	my $new_val = shift;
	
	my $r_glob = $self->{r_glob};
	
	if (ref(\$new_val) eq "GLOB") {
		$new_val = *{$new_val}{SCALAR};
	}
	
	if (defined($new_val) && (ref($new_val) ne 'SCALAR')) {
		croak "Can't assign non scalar object to value of scalar_ref";
	}

	no strict 'refs';
	no warnings;
	if (defined $new_val) {
		*{$r_glob} = $new_val;

	} else {
		undef ${*{$r_glob}{SCALAR}};
	}
	use warnings;
	use strict 'refs';

	$new_val
}

#-------------------------------------------------------------------------
# ARRAY
#-------------------------------------------------------------------------
package __TiedSymbol_Array;
use base ("__TiedSymbol");
use Carp;

sub TIESCALAR {
	my $class = shift;
	my $self = $class->SUPER::TIESCALAR(@_);
	$self->{slot} = 'ARRAY';
	$self
}

sub STORE {
	my $self = shift;
	my $new_val = shift;

	my $r_glob = $self->{r_glob};
	
	if (ref(\$new_val) eq "GLOB") {
		$new_val = *{$new_val}{ARRAY};
	}

	if (defined($new_val) && (ref($new_val) ne 'ARRAY')) {
		croak "Can't assign non array object to value of array_ref";
	}

	no strict 'refs';
	no warnings;
	if (defined $new_val) {
		*{$r_glob} = $new_val;
	} else {
		undef @{*{$r_glob}{ARRAY}};
	}
	use warnings;
	use strict 'refs';

	$new_val
}

#-------------------------------------------------------------------------
# HASH
#-------------------------------------------------------------------------
package __TiedSymbol_Hash;
use base ("__TiedSymbol");
use Carp;

sub TIESCALAR {
	my $class = shift;
	my $self = $class->SUPER::TIESCALAR(@_);
	$self->{slot} = 'HASH';
	$self
}

sub STORE {
	my $self = shift;
	my $new_val = shift;

	my $r_glob = $self->{r_glob};
	
	if (ref(\$new_val) eq "GLOB") {
		$new_val = *{$new_val}{HASH};
	}

	if (defined($new_val) && (ref($new_val) ne 'HASH')) {
		croak "Can't assign non hash object to value of symbol_hash_ref";
	}

	no strict 'refs';
	no warnings;
	if (defined $new_val) {
		*{$r_glob} = $new_val;
	} else {
		undef %{*{$r_glob}{HASH}};
	}
	use warnings;
	use strict 'refs';

	$new_val
}

#-------------------------------------------------------------------------
# CODE
#-------------------------------------------------------------------------
package __TiedSymbol_Code;
use base ("__TiedSymbol");
use Carp;

sub TIESCALAR {
	my $class = shift;
	my $self = $class->SUPER::TIESCALAR(@_);
	$self->{slot} = 'CODE';
	$self
}

sub STORE {
	my $self = shift;
	my $new_val = shift;

	my $r_glob = $self->{r_glob};
	
	if (ref(\$new_val) eq "GLOB") {
		$new_val = *{$new_val}{CODE};
	}

	if (defined($new_val) && (ref($new_val) ne 'CODE')) {
		croak "Can't assign non code object to value of code";
	}

	no strict 'refs';
	no warnings;
	if (defined $new_val) {
		*{$r_glob} = $new_val;
	} else {
		undef &{$r_glob};
	}
	use warnings;
	use strict 'refs';

	$new_val
}

#-------------------------------------------------------------------------
# IO
#-------------------------------------------------------------------------
package __TiedSymbol_IO;
use base ("__TiedSymbol");
use Carp;

sub TIESCALAR {
	my $class = shift;
	my $self = $class->SUPER::TIESCALAR(@_);
	$self->{slot} = 'IO';
	$self
}

sub STORE {
	my $self = shift;
	my $new_val = shift;

	my $r_glob = $self->{r_glob};
	
	if (ref(\$new_val) eq "GLOB") {
		$new_val = *{$new_val}{IO};
	}

	my $orig_exp = $@;
	if (defined($new_val) && ! eval { $new_val->isa('IO') }) {
		$@ = $orig_exp;
		croak "Can't assign non io object to value of io";
	}

	no strict 'refs';
	no warnings;
	if (defined $new_val) {
		*{$r_glob} = $new_val;
		
	} else {
		croak "Can't assign value \"undef\" to value of io.\n";
	}
	use warnings;
	use strict 'refs';

	$new_val
}

#-------------------------------------------------------------------------
# Format
#-------------------------------------------------------------------------
package __TiedSymbol_Format;
use base ("__TiedSymbol");
use Carp;

sub TIESCALAR {
	my $class = shift;
	my $self = $class->SUPER::TIESCALAR(@_);
	$self->{slot} = 'FORMAT';
	$self
}

sub STORE {
	my $self = shift;
	my $new_val = shift;

	my $r_glob = $self->{r_glob};
	
	if (ref(\$new_val) eq "GLOB") {
		$new_val = *{$new_val}{FORMAT};
	}

	if (defined($new_val) && !(ref($new_val) eq 'FORMAT')) {
		croak "Can't assign non format object to value of format";
	}

	no strict 'refs';
	no warnings;
	if (defined $new_val) {
		*{$r_glob} = $new_val;
		
	} else {
		croak "Can't assign value \"undef\" to value of format.\n";
	}
	use warnings;
	use strict 'refs';

	$new_val
}

#-------------------------------------------------------------------------
# GLOB
#-------------------------------------------------------------------------
package __TiedSymbol_Glob;
use base ("__TiedSymbol");
use Carp;

sub TIESCALAR {
	my $class = shift;
	my $self = $class->SUPER::TIESCALAR(@_);
	$self->{slot} = 'GLOB';
	$self
}

sub FETCH {
	my $self = shift;
	
	my $ret = $self->SUPER::FETCH(@_);
	
	*$ret
}

sub STORE {
	my $self = shift;
	my $new_val = $_[0];

	my $r_glob = $self->{r_glob};
	
	if (defined($new_val) && (ref(\$new_val) ne 'GLOB')) {
		croak "Can't assign non glob object to value of glob";
	}

	no strict 'refs';
	if (defined $new_val) {

		*{$r_glob} = \$_[0];

	} else {
		undef *{$r_glob};
	}
	use strict 'refs';

	$new_val
}

package __TiedSymbol_Constant;

use Tie::Scalar;
use Carp;

use base ("Tie::Scalar");

sub TIESCALAR {
	my ($class, $value) = @_;
	bless \$value, $class;

}

sub DESTROY {
}

sub FETCH {
	my $r_value = shift;
	$$r_value
}

sub STORE {
	croak "Can't modify list value in scalar context";
}

1
