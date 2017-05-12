package Sub::Usage;

# Copyright (C) 2002 Trabas. All rights reserved.
#
# This program is free software. You may freely use it, modify
# and/or distribute it under the same term as Perl itself.
#
# $Revision: 1.1.1.1 $
# $Date: 2002/02/26 00:11:27 $

=head1 NAME

Sub::Usage - Issue subroutine/method usage

=head1 SYNOPSIS

  use Sub::Usage;

  sub turn_on {
      @_ >= 2 or usage 'NAME, COLOR [, INTENSITY]';
      # sub continues
  }

=cut

use 5.006;
use strict;
use warnings;
use Carp qw(confess cluck);
require Exporter;

=head1 EXPORT

Only the C<usage> function is exported by default. You may optionally
import the C<warn_hard> and C<warn_soft> functions or use the tag B<:all>
to import all available symbols. C<parse_fqpn> will only be imported if it
is explicitly requested; it is not included in the B<:all> tag.

=cut

our @ISA         = qw(Exporter);
our %EXPORT_TAGS = ('all' => [qw(usage warn_hard warn_soft)]);
our @EXPORT_OK   = (@{$EXPORT_TAGS{'all'}}, 'parse_fqpn');
our @EXPORT      = qw(usage);
our $VERSION     = '0.03';

sub _usage {
	my($caller, $arg, $prefix) = @_;
	unless ($caller) {
		$caller = parse_fqpn((caller 1)[3]);
		confess __PACKAGE__,
		        "::$caller() must be called from a method or subroutine";
	}

	my $usage = parse_fqpn($caller);
	$usage = "$prefix\->$usage" if defined $prefix;
	$arg = '' unless defined $arg;
	$usage .= "($arg)";
	return "usage: $usage";
}

=head1 ABSTRACT

B<Sub::Usage> provides functions to issue the usage of subroutines
or methods from inside the stub. The issued usage is part of the
error message or warning when the subroutine in question is called
with inappropriate parameters.

=head1 DESCRIPTION

B<Sub::Usage> provides functions to display usage of subroutines
or methods from inside the stub. Some people like to check the
parameters of the routine. For example,

  # turn_on(NAME, COLOR [, INTENSITY])
  sub turn_on {
      @_ >= 2 or die "usage: turn_on(NAME, COLOR [, INTENSITY])\n";
      # the process goes on
  }

With the C<usage> function (exported by default), you can achieve the same
results (and more) without having to remember the subroutine name.

  use Sub::Usage;

  sub turn_on {
      @_ >= 2 or usage 'NAME, COLOR [, INTENSITY]';
      # process goes on
  }

=over 8

=item B<usage()>

The C<usage> function makes use of the built-in C<caller> function to
determine the subroutine name. When, for example, C<turn_on> is called
with inappropriate parameters, C<usage> will terminate the program with
backtrace information and print an error message like the following:

      usage: turn_on(NAME, COLOR [, INTENSITY])

If C<turn_on> is a method, a prefix can be added to indicate whether
it is being called as an object method or a class method.

  package Light::My::Fire;
  use Sub::Usage;


  sub turn_on {
      @_ >= 3 or usage 'NAME, COLOR [, INTENSITY]', '$light';
      # process goes on
  }

or,

  sub turn_on {
      @_ >= 3 or usage 'NAME, COLOR [, INTENSITY]', __PACKAGE__;
      # process goes on
  }

The error message will then be either:

  usage: $light->turn_on(NAME, COLOR [, INTENSITY])

or,

  usage: Light::My::Fire->turn_on(NAME, COLOR [, INTENSITY])

=cut

sub usage { confess _usage((caller 1)[3], @_) }

=pod

=item B<warn_hard>

=item B<warn_soft>

The C<warn_hard> and C<warn_soft> functions are similar to C<usage>, but
they don't die. Instead, as the their names suggest, they only warn
about the problem and return undef. This can be handy for having the
subroutine print the error message and return immediately in one
step.

  sub turn_off {
      @_ >= 2 or return warn_hard('NAME', '$light');
      # process goes on
  }

The difference between the two is that C<warn_soft> only works when
B<$^W> holds true, while C<warn_hard> always works regardless of the
value of B<$^W>.

=cut

sub warn_hard   {
	cluck _usage((caller 1)[3], @_);
	return;
}

sub warn_soft   {
	cluck _usage((caller 1)[3], @_) if $^W;
	return;
}

=pod

=item B<parse_fqpn>

The C<parse_fqpn> function is called internally. It takes a string that
contains a fully qualified package name and returns pieces of the name.
It can also accept numeric parameters that determine what it returns.

By default, it will just return the last part of the name, which is the
subroutine name in this case. Of course it doesn't know whether it's
really a subroutine name or another name from the symbol table, or even
just garbage.

  # get subroutine name: usage()
  my $sub = parse_fqpn('Sub::Usage::usage');

  # get the package name: Sub::Usage
  my $sub = parse_fqpn('Sub::Usage::usage', 1);

  # get both the package and sub name
  my($pack, $sub) = parse_fqpn('Sub::Usage::usage', 2);

  # get all pieces
  my(@parts) = parse_fqpn('Sub::Usage::usage', 3);

=cut

sub parse_fqpn {
	my($sub, $how) = @_;
	confess 'usage: parse_fqpn( FQPN [, HOW] )' unless $sub;
	$sub =~ /(.*)::(.*)/;
	return $2      unless $how;
	return $1      if     $how == 1;
	return($1, $2) if     $how == 2;
	my @packs = split /::/, $1;
	return(@packs, $2);
}

=pod

=back

=head1 BUGS

The C<usage> function and friends should not be called from anywhere
outside subroutines or methods, such as the main space. It will die when
it detects such situation. For example:

  #!perl
  usage();

This will result in an error message such as:

  Sub::Usage::usage() must be called from a method or subroutine

Unfortunately, the underlying function relies too much on C<caller(1)>
to return the fourth element as subroutine name. But this is not the
situation in eval context, as documented in C<perldoc -f caller>. This
causes the C<usage> and friends behave unexpectedly.

The workaround is simply don't call them outside of subroutines or methods.
This is utility for the subs, after all :-)

=head1 AUTHOR

Hasanuddin Tamir E<lt>hasant@trabas.comE<gt>

=head1 COPYRIGHT

Copyright (C) 2002 Trabas.  All rights reserved.

This program is free software. You may freely use it, modify
and/or distribute it under the same term as Perl itself.

=head1 THANKS

I'd like to thank Matthew Sachs E<lt>matthewg@zevils.comE<gt> for his
patch on the POD and suggestion on renaming to Sub::Usage.

=head1 SEE ALSO

L<perl>.

=cut


1;
