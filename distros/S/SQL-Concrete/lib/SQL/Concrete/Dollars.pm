use 5.006;
use strict;
use warnings;

package SQL::Concrete::Dollars;
$SQL::Concrete::Dollars::VERSION = '1.003';
# ABSTRACT: use SQL::Concrete with dollar placeholders

use SQL::Concrete ':noncore';
BEGIN { our @ISA = 'SQL::Concrete' } # inherit import()

sub sql_render { SQL::Concrete::Renderer::Dollars->new->render( @_ ) }

package SQL::Concrete::Renderer::Dollars;
$SQL::Concrete::Renderer::Dollars::VERSION = '1.003';
BEGIN { our @ISA = 'SQL::Concrete::Renderer' }

sub render {
	my $self = shift;
	local $self->{'placeholder_id'} = 0;
	$self->SUPER::render( @_ );
}

sub render_bind {
	my $self = shift;
	push @{ $self->{'bind'} }, $_[0];
	'$'.++$self->{'placeholder_id'};
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SQL::Concrete::Dollars - use SQL::Concrete with dollar placeholders

=head1 VERSION

version 1.003

=head1 SYNOPSIS

 use SQL::Concrete::Dollars ':all';

=head1 DESCRIPTION

This module is just like L<SQL::Concrete>, except that automatically generated
placeholders will use numbered placeholder syntax instead of the more common
question mark syntax (i.e. C<$, $2, $3> instead of C<?, ?, ?>).

If for some reason you wish to use both forms and want to be able to choose on
a per-query basis, you can export C<sql_render> from this module with a prefix:

 use SQL::Concrete ':all';
 use SQL::Concrete::Dollars _prefix => 'pg', ':core';
 
 # you can now use either sql_render or pgsql_render
 # depending on the form of placeholders you want

For all further details, please refer to the L<SQL::Concrete> documentation.

=head1 AUTHOR

Aristotle Pagaltzis <pagaltzis@gmx.de>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Aristotle Pagaltzis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
