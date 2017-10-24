package PPIx::EditorTools::ReturnObject;
our $AUTHORITY = 'cpan:YANICK';
# ABSTRACT: Simple object to return values from PPIx::EditorTools
$PPIx::EditorTools::ReturnObject::VERSION = '0.20';
use 5.008;
use strict;
use warnings;
use Carp;


sub new {
	my $class = shift;
	return bless {@_}, ref($class) || $class;
}

sub element {
	my ($self) = @_;

	# If element is a code ref, run the code once then cache the
	# result
	if (    exists $self->{element}
		and ref( $self->{element} )
		and ref( $self->{element} ) eq 'CODE' )
	{
		$self->{element} = $self->{element}->(@_);
	}

	return $self->{element};
}

sub ppi {
	my ( $self ) = @_;

	# $self->{ppi} = $doc if $doc;    # TODO: and isa?

	return $self->{ppi} if $self->{ppi};

	if ( $self->{code} ) {
		my $code = $self->{code};
		$self->{ppi} = PPI::Document->new( \$code );
		return $self->{ppi};
	}

	return;
}

sub code {
	my ( $self ) = @_;

	# $self->{code} = $doc if $doc;

	return $self->{code} if $self->{code};

	if ( $self->{ppi} ) {
		$self->{code} = $self->{ppi}->serialize;
		return $self->{code};
	}

	return;
}

1;

=pod

=encoding UTF-8

=head1 NAME

PPIx::EditorTools::ReturnObject - Simple object to return values from PPIx::EditorTools

=head1 VERSION

version 0.20

=head1 SYNOPSIS

  my $brace = PPIx::EditorTools::FindUnmatchedBrace->new->find(
        code => "package TestPackage;\nsub x { 1;\n"
      );
  my $location = $brace->element->location;
  my $ppi      = $brace->element->ppi;

=head1 DESCRIPTION

Retuning a simple C<PPI::Element> from many of the C<PPIx::EditorTools>
methods often results in the loss of the overall context for that element.
C<PPIx::EditorTools::ReturnObject> provides an object that can be passed
around which retains the overall context.

For example, in C<PPIx::EditorTools::FindUnmatchedBrace> if the unmatched
brace were returned by its C<PPI::Structure::Block> the containing
C<PPI::Document> is likely to go out of scope, thus the C<location>
method no longer returns a valid location (rather it returns undef).
Using the C<ReturnObject> preserves the C<PPI::Document> and the containing
context.

=head1 METHODS

=over 4

=item new()

Constructor which should be used by C<PPIx::EditorTools>. Accepts the following
named parameters:

=over 4

=item ppi

A C<PPI::Document> representing the (possibly modified) code.

=item code

A string representing the (possibly modified) code.

=item element

A C<PPI::Element> or a subclass thereof representing the interesting element.

=back

=item ppi

Accessor to retrieve the C<PPI::Document>. May create the C<PPI::Document>
from the $code string (lazily) if needed.

=item code

Accessor to retrieve the string representation of the code. May be retrieved
from the C<PPI::Document> via the serialize method (lazily) if needed.

=back

=head1 SEE ALSO

C<PPIx::EditorTools>, L<App::EditorTools>, L<Padre>, and L<PPI>.

=head1 AUTHORS

=over 4

=item *

Steffen Mueller C<smueller@cpan.org>

=item *

Mark Grimes C<mgrimes@cpan.org>

=item *

Ahmad M. Zawawi <ahmad.zawawi@gmail.com>

=item *

Gabor Szabo  <gabor@szabgab.com>

=item *

Yanick Champoux <yanick@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017, 2014, 2012 by The Padre development team as listed in Padre.pm..

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__END__


# Copyright 2008-2009 The Padre development team as listed in Padre.pm.
# LICENSE
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl 5 itself.
