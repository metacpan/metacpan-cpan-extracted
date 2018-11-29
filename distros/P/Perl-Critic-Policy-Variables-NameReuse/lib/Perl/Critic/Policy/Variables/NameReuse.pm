package Perl::Critic::Policy::Variables::NameReuse;

use strict;
use warnings;

our $VERSION = 'v0.1.0';

use Perl::Critic::Utils qw(:severities :classification :ppi);
use parent 'Perl::Critic::Policy';

use constant EXPL => 'Using the same name for multiple types of variables can be confusing, e.g. %foo and $foo. Use different names for different variables.';

sub supported_parameters { () }
sub default_severity { $SEVERITY_LOW }
sub default_themes { () }
sub applies_to { 'PPI::Document' }

sub violates {
	my ($self, $elem) = @_;
	
	my @violations;
	my %seen;

	my $symbols = $elem->find('PPI::Token::Symbol') || [];
	foreach my $symbol (@$symbols) {
		next if $symbol->isa('PPI::Token::Magic'); # skip magic variables
		my $actual = $symbol->symbol;
		next if $actual =~ m/::/; # let's not concern ourselves with fully qualified package variables
		(my $name = $actual) =~ s/^[\$\@\%]// or next;
		next if $name eq 'INC' or $name eq 'ARGV';
		$seen{$name}{$actual} //= $symbol;
	}

	my $indexes = $elem->find('PPI::Token::ArrayIndex') || [];
	foreach my $symbol (@$indexes) {
		next if $symbol =~ m/::/; # let's not concern ourselves with fully qualified package variables
		(my $name = $symbol) =~ s/^\$\#// or next;
		next if $name =~ m/^\W$/; # skip magic variables
		next if $name eq 'INC' or $name eq 'ARGV';
		my $actual = '@' . $name;
		$seen{$name}{$actual} //= $symbol;
	}

	foreach my $name (keys %seen) {
		my $by_actual = $seen{$name};
		if (keys %$by_actual > 1) {
			my @sorted = sort { (($by_actual->{$a}->logical_line_number // 0) <=> ($by_actual->{$b}->logical_line_number // 0))
				|| (($by_actual->{$a}->visual_column_number // 0) <=> ($by_actual->{$b}->visual_column_number // 0)) } keys %$by_actual;
			push @violations, $self->violation("Reused variable name '$name' for '$_'", EXPL, $by_actual->{$_}) for @sorted;
		}
	}
	
	return @violations;
}

1;

=head1 NAME

Perl::Critic::Policy::Variables::NameReuse - Don't reuse names for different
types of variables

=head1 SYNOPSIS

  perlcritic --single-policy=Variables::NameReuse script.pl
  perlcritic --single-policy=Variables::NameReuse lib/

  # .perlcriticrc
  severity = 1
  only = 1
  [Variables::NameReuse]

=head1 DESCRIPTION

This policy checks for the existence of multiple variables with the same name
in a file. This can be confusing especially when accessing elements of
variables or using L<list or key-value slices|perldata/Slices>. For example,
the code could access both C<$foo> and C<$foo[0]> but these actually refer to
the unrelated variables C<$foo> and C<@foo>.

  my $foo = @foo;             # not ok
  my @bar = @bar{'a','b'};    # not ok
  my $count = @foo;           # ok
  my @values = @bar{'a','b'}; # ok

=head1 AFFILIATION

This policy has no affiliation.

=head1 CONFIGURATION

This policy is not configurable except for the standard options.  

=head1 BUGS

Report any issues on the public bugtracker.

=head1 AUTHOR

Dan Book <dbook@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Dan Book.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=head1 SEE ALSO

L<Perl::Critic::Policy::Variables::ProhibitReusedNames> - instead prohibits
redeclaring the same variable name across different scopes
