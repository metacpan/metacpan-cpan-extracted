package Perl::PrereqScanner::Scanner::DistBuild;
use strict;
use warnings;

our $VERSION = '0.002';

use Moo;
with 'Perl::PrereqScanner::Scanner';

sub scan_for_prereqs {
	my ($self, $ppi_doc, $requirements) = @_;

	# Moose-based roles / inheritance
	my @chunks =
		map  { [ $_->schildren ] }
		grep { $_->child(0)->literal =~ m{\A(?:load_module|load_extension)\z} }
		grep { $_->child(0)->isa('PPI::Token::Word') }
		@{ $ppi_doc->find('PPI::Statement') || [] };

	foreach my $hunk ( @chunks ) {
		my ($load_module, @arguments) = @$hunk;

		pop @arguments if @arguments > 1 && $arguments[-1]->isa('PPI::Token::Structure') && $arguments[-1]->content eq ';';

		if (@arguments == 1) {
			if ($arguments[0]->isa('PPI::Structure::List')) {
				@arguments = $arguments[0]->children;
			}
			if ($arguments[0]->isa("PPI::Statement::Expression")) {
				@arguments = $arguments[0]->children;
			}
		}

		my ($module_node, undef, $version_node) = grep { not $_->isa('PPI::Token::Whitespace') } @arguments;

		my ($module) = $module_node->string;

		if ($version_node) {
			$version_node->simplify if $version_node->can('simplify');
			my $version = $version_node->literal;
			$requirements->add_minimum($module, $version);
		} else {
			$requirements->add_minimum($module, 0);
		}
	}
}

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Perl::PrereqScanner::Scanner::DistBuild - scan for Dist::Build dependencies

=head1 DESCRIPTION

This scanner is intended for L<Dist::Build> planner files. It recognizes C<load_extension> calls and detects the appropriate module dependency.

=head1 AUTHOR

Leon Timmermans <fawaka@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2024 by Leon Timmermans.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
