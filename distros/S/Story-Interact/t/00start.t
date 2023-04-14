=pod

=encoding utf-8

=head1 PURPOSE

Print version numbers, etc.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2023 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use Test2::V0;

my @modules = qw(
	Carp
	DBI
	DBD::SQLite
	Exporter::Shiny
	List::Util
	match::simple
	Module::Runtime
	Moo
	namespace::clean
	Term::Choose
	Text::Wrap
	Types::Common
	Types::Path::Tiny
	URI::Query
	String::Tagged::Markdown
	String::Tagged::Terminal
	Test2::V0
	Test2::Tools::Spec
	Test2::Require::AuthorTesting
	Test2::Require::Module
);

diag "\n####";
for my $mod ( sort @modules ) {
	eval "require $mod;";
	diag sprintf( '%-20s %s', $mod, $mod->VERSION );
}
diag "####";

pass;

done_testing;

