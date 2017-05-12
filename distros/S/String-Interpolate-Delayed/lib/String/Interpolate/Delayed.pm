use 5.008;
use strict;
use warnings;

package String::Interpolate::Delayed;

our $AUTHORITY = "cpan:TOBYINK";
our $VERSION   = "0.002";

our $WORKAROUND = 1;

use overload q[""] => "interpolated", fallback => 1;

use PadWalker ();
use PerlX::QuoteOperator ();
use String::Interpolate ();
use UNIVERSAL::ref;

sub import
{
	my $class = shift;
	my ($name) = @_;
	
	my $code = sub ($) {
		my $text = shift;
		bless \$text;
	};
	
	"PerlX::QuoteOperator"->new->import(
		$name || "delayed",
		{ -emulate => 'q', -with => $code },
		scalar caller,
	);
}

sub new
{
	my $class = shift;
	my ($text) = @_;
	
	bless \$text => $class;
}

sub uninterpolated
{
	my $self = shift;
	
	return $$self;
}

sub _clean
{
	my ($refs) = @_;
	+{ map {; substr($_, 1) => $refs->{$_} } keys %$refs };
}

sub interpolated
{
	my $self = shift;
	
	my $stri = "String::Interpolate"->new;
	
	if ($WORKAROUND) {
		# Workaround for bug in the ->pragma() accessor...
		$$stri->{pragmas} = 'import strict "vars";';
	}
	else {
		$$stri->pragma('import strict "vars";');
	}
	
	$stri->exec(
		_clean(PadWalker::peek_our 1),
		_clean(PadWalker::peek_my 1),
		grep(ref($_) eq 'HASH', @_),
	);
	return $stri->exec($$self);
}

sub ref
{
	return undef;
}

1 && __PACKAGE__
__END__

=head1 NAME

String::Interpolate::Delayed - delay string interpolation until you really want it

=head1 SYNOPSIS

   use strict;
   use warnings;
   use String::Interpolate::Delayed;
   
   my $str   = delayed "$role of the $thing";
   my $role  = "Lord";
   my $thing = [qw( Rings Flies Dance )]->[rand 3];
   
   print "$str\n";

=head1 DESCRIPTION

This module allows you to create strings which are interpolated, but not
immediately.

Running the code in the SYNPOSIS will print the name of one of my favourite
lords, even though at the time C<< $str >> was declared, the variables
C<< $role >> and C<< $thing >> had still not been declared!

=head2 Discussion

B<< How does this pass strictures? >> You might expect that the line which
declares C<< $str >> would trigger a compile-time error, as it refers to two
variables which don't exist. Fear not! C<< delayed >> is technically a
quote-like operator, not a function; the string following it is parsed by
Perl as an I<uninterpolated> string, even if it appears in double quotes.
We could equally have written:

   my $str = delayed/$role of the $thing/;

I prefer the double-quoted style because it fares better with syntax
highlighting.

B<< What is C<$str>? >> It's actually a blessed object, but it uses
L<UNIVERSAL::ref> to conceal this fact. (C<blessed> from L<Scalar::Util>
knows the truth though.)

B<< And it overloads stringification, right? >> By George! You've got it!
Yes, it overloads stringification and plays silly games with L<PadWalker>
and L<String::Interpolate>.

=head2 Methods

As mentioned above, strings with delayed interpolation are blessed objects.
As such, they have methods:

=over

=item C<< new($text) >>

Object-oriented way to create a string with delayed interpretation, bypassing
the C<< delayed >> quote-like operator.

   my $str = "String::Interpolate::Delayed"->new('$foo');

=item C<< interpolated >>

Retrieve the text as a Perl scalar string, performing interpolation.

The object overloads stringification to call this method. Passing a
hashref as a parameter, allows you to define additional variables:

   my $str   = delayed "The $thing in $place @description.\n";
   my $thing = "rain";
   
   print $str->interpolated({
      place       => \"Spain",
      description => [qw/ stays mainly on the plain /],
   });

=item C<< uninterpolated >>

Retrieve the text as a Perl scalar string, I<without> performing
interpolation.

=item C<< ref >>

Just returns C<< undef >>. This is for the benefit of L<UNIVERSAL::ref>.

=back

=head1 CAVEATS

=head2 Limitations on interpolation

Most variables, including lexical variables and "magic" variables (such as
C<< $1 >>, C<< $_ >>, etc) will work. There's one significant exception:
C<< @_ >>. This limitation is inherited from C<< String::Interpolate >>.

=head2 Danger, Will Robinson!!

Interpolated Perl strings can execute arbitrary code:

   my $str = "I think I might @{[ unlink '/etc/passwd' ]}";

This is a caveat with interpolated strings in Perl in general, however
String::Interpolate::Delayed makes it easier to fall into this trap, because
you might be tempted to load strings with delayed interpolation from an
untrusted external source and throw them at the OO constructor.

=head2 String::Interpolate

This module includes a workaround for a bug in String::Interpolate. If the
bug is fixed, the workaround may stop working. The workaround can be disabled
by setting

   $String::Interpolate::Delayed::WORKAROUND = 0;

=head1 BUGS

=head2 forkprove

Test suite fails when run using L<App::ForkProve>, but runs fine using
L<App::Prove>. I don't know what all that's about...

=head2 Bug tracker

Please report any other bugs to
L<http://rt.cpan.org/Dist/Display.html?Queue=String-Interpolate-Delayed>.

=head1 SEE ALSO

L<String::Interpolate>, L<PerlX::QuoteOperator>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2013 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

