package PPIx::EditorTools::Outline;
our $AUTHORITY = 'cpan:YANICK';
# ABSTRACT: Collect use pragmata, modules, subroutiones, methods, attributes
$PPIx::EditorTools::Outline::VERSION = '0.20';
use 5.008;
use strict;
use warnings;
use Carp;
use Try::Tiny;
use base 'PPIx::EditorTools';
use Class::XSAccessor accessors => {};

use PPI;

sub find {
	my ( $self, %args ) = @_;
	$self->process_doc(%args);

	my $ppi = $self->ppi;

	return [] unless defined $ppi;
	$ppi->index_locations;

	# Search for interesting things
	require PPI::Find;

	# TODO things not very discriptive
	my @things = PPI::Find->new(
		sub {

			# This is a fairly ugly search
			return 1 if ref $_[0] eq 'PPI::Statement::Package';
			return 1 if ref $_[0] eq 'PPI::Statement::Include';
			return 1 if ref $_[0] eq 'PPI::Statement::Sub';
			return 1 if ref $_[0] eq 'PPI::Statement';
		}
	)->in($ppi);

	# Define a flag indicating that further Method::Signature/Moose check should run
	my $check_alternate_sub_decls = 0;

	# Build the outline structure from the search results
	my @outline       = ();
	my $cur_pkg       = {};
	my $not_first_one = 0;
	foreach my $thing (@things) {
		if ( ref $thing eq 'PPI::Statement::Package' ) {
			if ($not_first_one) {
				if ( not $cur_pkg->{name} ) {
					$cur_pkg->{name} = 'main';
				}
				push @outline, $cur_pkg;
				$cur_pkg = {};
			}
			$not_first_one   = 1;
			$cur_pkg->{name} = $thing->namespace;
			$cur_pkg->{line} = $thing->location->[0];
		} elsif ( ref $thing eq 'PPI::Statement::Include' ) {
			next if $thing->type eq 'no';
			if ( $thing->pragma ) {
				push @{ $cur_pkg->{pragmata} }, { name => $thing->pragma, line => $thing->location->[0] };
			} elsif ( $thing->module ) {
				push @{ $cur_pkg->{modules} }, { name => $thing->module, line => $thing->location->[0] };
				unless ($check_alternate_sub_decls) {
					$check_alternate_sub_decls = 1
						if grep { $thing->module eq $_ } (
						'Method::Signatures',
						'MooseX::Declare',
						'MooseX::Method::Signatures',
						'Moose::Role',
						'Moose',
						);
				}
			}
		} elsif ( ref $thing eq 'PPI::Statement::Sub' ) {
			push @{ $cur_pkg->{methods} }, { name => $thing->name, line => $thing->location->[0] };
		} elsif ( ref $thing eq 'PPI::Statement' ) {

			# last resort, let's analyse further down...
			my $node1 = $thing->first_element;
			my $node2 = $thing->child(2);

			next unless defined $node2;

			# Tests for has followed by new line
			try {
				no warnings 'exiting'; # suppress warning Exiting eval via next
				if ( defined $node2->{content} ) {
					if ( $node2->{content} =~ /\n/ ) {
						next;
					}
				}
			};

			# Moose attribute declaration
			if ( $node1->isa('PPI::Token::Word') && $node1->content eq 'has' ) {

				# p $_[1]->next_sibling->isa('PPI::Token::Whitespace');
				$self->_Moo_Attributes( $node2, $cur_pkg, $thing );
				next;
			}

			# MooseX::POE event declaration
			if ( $node1->isa('PPI::Token::Word') && $node1->content eq 'event' ) {
				push @{ $cur_pkg->{events} }, { name => $node2->content, line => $thing->location->[0] };
				next;
			}
		}
	}

	if ($check_alternate_sub_decls) {
		$ppi->find(
			sub {
				$_[1]->isa('PPI::Token::Word') or return 0;
				$_[1]->content =~ /^(?:func|method|before|after|around|override|augment|class|role)\z/ or return 0;
				$_[1]->next_sibling->isa('PPI::Token::Whitespace') or return 0;
				my $sib_content = $_[1]->next_sibling->next_sibling->content or return 0;

				my $name = eval $sib_content;

				# if eval() failed for whatever reason, default to original trimmed original token
				$name ||= ( $sib_content =~ m/^\b(\w+)\b/ )[0];

				return 0 unless defined $name;

				# test for MooseX::Declare class, role
				if ( $_[1]->content =~ m/(class|role)/ ) {
					$self->_Moo_PkgName( $cur_pkg, $sib_content, $_[1] );
					return 1; # break out so we don't write Package name as method
				}

				push @{ $cur_pkg->{methods} }, { name => $name, line => $_[1]->line_number };

				return 1;
			}
		);
	}

	if ( not $cur_pkg->{name} ) {
		$cur_pkg->{name} = 'main';
	}

	push @outline, $cur_pkg;

	return \@outline;
}

########
# Composed Method, internal, Moose Attributes
# cleans moose attributes up, and single lines them.
# only runs if PPI finds has
# prefix all vars with ma_ otherwise same name
########
sub _Moo_Attributes {
	my ( $self, $ma_node2, $ma_cur_pkg, $ma_thing ) = @_;

	my $line_num = $ma_thing->location->[0];

	if ( $ma_node2->content =~ /[\n|;]/ ) {
		return;
	}

	my $attrs = eval $ma_node2->content;

	# if eval() failed for whatever reason, default to original token
	$attrs ||= $ma_node2->content;

	if ( ref $attrs eq 'ARRAY' ) {
		map { push @{ $ma_cur_pkg->{attributes} }, { name => $_, line => $line_num, } }
			grep {defined} @{$attrs};

	} else {

		push @{ $ma_cur_pkg->{attributes} },
			{
			name => $attrs,
			line => $line_num,
			};
	}
	return;
}

########
# Composed Method, internal, Moose Pakage Name
# write first Class or Role as Package Name if none
# prefix all vars with mpn_ otherwise same name
########
sub _Moo_PkgName {
	my ( $self, $mpn_cur_pkg, $mpn_sib_content, $mpn_ppi_tuple ) = @_;
	if ( $mpn_cur_pkg->{name} ) { return 1; } # break if we have a pkg name
	                                          # add to outline
	$mpn_cur_pkg->{name} = $mpn_sib_content;            # class or role name
	$mpn_cur_pkg->{line} = $mpn_ppi_tuple->line_number; # class or role location
	return 1;
}

1;

=pod

=encoding UTF-8

=head1 NAME

PPIx::EditorTools::Outline - Collect use pragmata, modules, subroutiones, methods, attributes

=head1 VERSION

version 0.20

=head1 SYNOPSIS

  my $outline = PPIx::EditorTools::Outline->new->find(
        code => "package TestPackage;\nsub x { 1;\n"
      );
 print Dumper $outline;

=head1 DESCRIPTION

Return a list of pragmatas, modules, methods, attributes of a C<PPI::Document>.

=head1 METHODS

=over 4

=item * new()

Constructor. Generally shouldn't be called with any arguments.

=item * find()

	find( ppi => PPI::Document $ppi )
or
	find( code => Str $code )

Accepts either a C<PPI::Document> to process or a string containing
the code (which will be converted into a C<PPI::Document>) to process.
Return a reference to a hash.

=back

=head2 Internal Methods

=over 4

=item * _Moo_Attributes

=item * _Moo_PkgName

=back

=head1 SEE ALSO

This class inherits from C<PPIx::EditorTools>.
Also see L<App::EditorTools>, L<Padre>, and L<PPI>.

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




# Copyright 2008-2012 The Padre development team as listed in Padre.pm.
# LICENSE
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl 5 itself.
