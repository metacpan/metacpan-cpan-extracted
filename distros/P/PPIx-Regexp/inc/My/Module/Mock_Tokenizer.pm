package My::Module::Mock_Tokenizer;

use 5.006;

use strict;
use warnings;

use Carp;

our $VERSION = '0.060';

use constant ARRAY_REF	=> ref [];

sub new {
    my ( $class, %arg ) = @_;
    return bless \%arg, ref $class || $class;
}

sub capture {
    my ( $self ) = @_;
    ARRAY_REF eq ref $self->{capture}
	or return;
    return @{ $self->{capture} };
}

sub cookie {
    my ( $self, $cookie ) = @_;
    return $self->{cookie}{$cookie};
}

sub modifier_modify {}

sub __recognize_postderef {
    my ( $self ) = @_;
    return $self->{postderef};
}

1;

__END__

=head1 NAME

My::Module::Mock_Tokenizer - Mock tokenizer for t/*.t

=head1 SYNOPSIS

 use lib qw{ inc };
 
 use My::Module::Mock_Tokenizer;
 
 my $tokenizer = My::Module::Mock_Tokenizer->new();

=head1 DESCRIPTION

This Perl class is private to the C<PPIx-Regexp> package, and may be
modified or retracted without notice. Documentation is for the benefit
of the author.

It represents a mock tokenizer to be used in testing. It implements
those methods that the author finds useful.

=head1 METHODS

This class supports the following public methods:

=head2 new

 my $tokenizer = My::Module::Mock_Tokenizer->new();

This static method instantiates the tokenizer. In addition to the
invocant it takes arbitrary name/value pairs of arguments. These
arguments are made into a hash, and a blessed reference to this hash is
returned. The arguments are not validated, but may be used in methods as
documented below.

=head2 capture

 say "Capture: '$_'" for $tokenizer->capture();

If C<< $tokenizer->{capture} >> is an array reference, the contents of
the array are returned. Otherwise nothing is returned.

=head2 cookie

 my $cookie = $tokenizer->cookie( $name );

This method returns C<< $tokenizer->{cookie}{$name} >>. If you want to
specify a value for this, recall that cookies are code references.

=head2 modifier_modify

 $tokenizer->modifier_modify( i => 1 );

This method does nothing and returns nothing.

=head2 __recognize_postderef

 $tokenizer->__recognize_postderef()
     and say 'We recognize postfix dereferences';

This method returns the value of C<< $tokenizer->{postderef} >>.

=head1 SEE ALSO

L<PPIx::Regexp::Tokenizer|PPIx::Regexp::Tokenizer>

=head1 SUPPORT

This module is private to the C<PPIx-Regexp> package. It is unsupported
in the sense that the author reserves the right to modify or retract it
without prior appeoval. Bug reports filed via L<http://rt.cpan.org>, or
in electronic mail to the author will be accepted if they document a
problem with this module that results in spurious test results.

=head1 AUTHOR

Tom Wyant (wyant at cpan dot org)

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2015-2018 by Thomas R. Wyant, III

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl 5.10.0. For more details, see the full text
of the licenses in the directory LICENSES.

This program is distributed in the hope that it will be useful, but
without any warranty; without even the implied warranty of
merchantability or fitness for a particular purpose.

=cut

# ex: set textwidth=72 :
