use 5.014;
use strict;
use warnings;

package Syntax::Keyword::Wielding;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.001001';

use Keyword::Declare;
use Import::Into;
use vars (); # yes, in 2025, we're using vars.pm!

sub import {
	
	# Prevent syntax error when _ is used outside wielding.
	vars->import::into( 1, qw/
		$____WIELDING_object
		$____WIELDING_method
		@____WIELDING_params
	/ );
	
	keyword wielding ( ScalarAccess $obj, '->' $arrow, QualIdent $callable, ParensList $parens, Block $block )
		{{{ do { my $____WIELDING_object = \ « $obj »; my $____WIELDING_method = qq[« quotemeta($callable) »]; my @____WIELDING_params = « $parens »; « $block » }; }}}
	keyword wielding ( ScalarAccess $obj, '->' $arrow, QualIdent $callable, Block $block )
		{{{ do { my $____WIELDING_object = \ « $obj »; my $____WIELDING_method = qq[« quotemeta($callable) »]; my @____WIELDING_params = (); « $block » }; }}}
	keyword wielding ( QualIdent $callable, ParensList $parens, Block $block )
		{{{ do { my $____WIELDING_object = undef; my $____WIELDING_method = \&«$callable»; my @____WIELDING_params = « $parens »; « $block » }; }}}
	keyword wielding ( QualIdent $callable, Block $block )
		{{{ do { my $____WIELDING_object = undef; my $____WIELDING_method = \&«$callable»; my @____WIELDING_params = (); « $block » }; }}}
	keyword wielding ( ScalarAccess $callable, '->' $arrow, ParensList $parens, Block $block )
		{{{ do { my $____WIELDING_object = undef; my $____WIELDING_method = «$callable»; my @____WIELDING_params = « $parens »; « $block » }; }}}
	keyword wielding ( Block $callable, Block $block )
		{{{ do { my $____WIELDING_object = undef; my $____WIELDING_method = sub { «$callable» }; my @____WIELDING_params = (); « $block » }; }}}
	
	keyword _ ( ParensList $parens )
		{{{ $____WIELDING_object ? ${$____WIELDING_object}->$____WIELDING_method(@____WIELDING_params, « $parens ») : $____WIELDING_method ? $____WIELDING_method->(@____WIELDING_params, « $parens ») : die('Used _ outside wielding block'); }}}
	keyword _ ( List $parens )
		{{{ $____WIELDING_object ? ${$____WIELDING_object}->$____WIELDING_method(@____WIELDING_params, « $parens ») : $____WIELDING_method ? $____WIELDING_method->(@____WIELDING_params, « $parens ») : die('Used _ outside wielding block'); }}}
}

sub unimport {
	unkeyword wielding;
}

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Syntax::Keyword::Wielding - adds a "wielding" keyword to make it easier to call the same function or method multiple times

=head1 SYNOPSIS

  my $play = Play->new;
  $play->add_line( "Bernado",   "Who's there?" );
  $play->add_line( "Francisco", "Nay, answer me! Stand and unfold yourself!" );
  $play->add_line( "Bernado",   "Long live the king!" );
  $play->add_line( "Francisco", "Bernardo?" );
  $play->add_line( "Bernado",   "He." );
  $play->add_line( "Francisco", "You come most carefully upon your hour." );

It gets repetitive, right?

  my $play = Play->new;
  wielding $play->add_line {
    my $b = 'Bernado';
    my $f = 'Francisco';
    _ $b => "Who's there?";
    _ $f => "Nay, answer me! Stand and unfold yourself!";
    _ $b => "Long live the king!";
    _ $f => "Bernardo?";
    _ $b => "He.";
    _ $f => "You come most carefully upon your hour.";
  }

=head1 DESCRIPTION

The C<wielding> keyword takes a template method call or function call followed
by a block. It executes the block, but within the block, a C<_> keyword (yes,
we're using a plain underscore as a keyword) will be expanded to that method
call or function call.

Technically as C<_> is parsed as a statement like C<if>, it doesn't need to be
followed by a semicolon, so the example in the L</SYNOPSIS> can be written as:

  my $play = Play->new;
  wielding $play->add_line {
    my $b = 'Bernado';
    my $f = 'Francisco';
    _ $b => "Who's there?"
    _ $f => "Nay, answer me! Stand and unfold yourself!"
    _ $b => "Long live the king!"
    _ $f => "Bernardo?"
    _ $b => "He."
    _ $f => "You come most carefully upon your hour."
  }

Leading arguments to the function can be curried:

  my $play = Play->new;
  wielding $play->add_line("Bernardo") {
    _ "Who's there?"
  };


The template method call or function call can be written in any of the
following styles:

=over

=item *

Simple method call:

  wielding $object->method {
    _ @args;
  }

=item *

Method call with curried arguments:

  wielding $object->method(@args) {
    _ @moreargs;
  }

=item *

Simple function call:

  wielding func {
    _ @args;
  }

=item *

Function call with curried arguments:

  wielding func(@args) {
    _ @moreargs;
  }

=item *

Fully-qualified function call:

  wielding Some::Package::func {
    _ @args;
  }

=item *

Fully-qualified function call with curried arguments:

  wielding Some::Package::func(@args) {
    _ @moreargs;
  }

=item *

Coderef:

  my $callback = sub { ... };
  wielding $callback->() {
    _ @args;
  }

Note that the C<< ->() >> is required.

=item *

Coderef with curried arguments:

  my $callback = sub { ... };
  wielding $callback->(@args) {
    _ @moreargs;
  }

=item *

Code block:

  wielding { @args = @_; ... } {
    _ @args;
  }

Internally the block is just wrapped in a C<< sub { ... } >>, so C<return>
will return from the code block.

=back

Because C<_> is always taken to be the start of a statement, you cannot use
it as part of an expression:

  wielding func() {
    my $x = _ @args;
  }

However, you can wrap it in a C<< do {...} >> block:

  wielding func() {
    my $x = do { _ @args };
  }

Similarly, C<wielding> cannot be used as part of an expression, but is a
whole statement. Again, wrapping it in C<< do {...} >> is a workaround.

This is a limitation of the underlying keyword declaration mechanism used
by this module.

=head1 BUGS

Please report any bugs to
L<https://github.com/tobyink/p5-syntax-keyword-wielding/issues>.

=head1 SEE ALSO

I can't think of any module weird enough to consider being related to this.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2025 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

