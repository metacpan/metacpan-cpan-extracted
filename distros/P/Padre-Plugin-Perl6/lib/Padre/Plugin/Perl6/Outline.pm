package Padre::Plugin::Perl6::Outline;
BEGIN {
  $Padre::Plugin::Perl6::Outline::VERSION = '0.71';
}

# ABSTRACT: Perl 6 Outline background task

use strict;
use warnings;

use Params::Util ('_INSTANCE');
use Padre::Task  ();

our @ISA = 'Padre::Task';

sub new {
	my $self = shift->SUPER::new(@_);

	# Just convert the document to text for now.
	# Later, we'll suck in more data from the project and
	# other related documents to do syntax checks more awesomely.
	unless ( _INSTANCE( $self->{document}, 'Padre::Document' ) ) {
		die "Failed to provide a document to the syntax check task";
	}

	# Remove the document entirely as we do this,
	# as it won't be able to survive serialisation.
	my $document = delete $self->{document};
	$self->{tokens} = $document->{tokens};

	return $self;
}

sub run {
	my $self = shift;

	# Generate the outline
	$self->{data} = $self->find();

	return 1;
}

sub find {
	my $self = shift;

	my @outline = ();

	if ( $self->{tokens} ) {
		my $cur_pkg        = {};
		my @tokens         = @{ $self->{tokens} };
		my $symbol_type    = 'package';
		my $symbol_name    = '';
		my $symbol_line    = -1;
		my $symbol_suffix  = '';
		my $symbol_context = '';
		my $context        = 'GLOBAL';
		for my $htoken (@tokens) {
			my %token = %{$htoken};
			my $tree  = $token{tree};
			if ($tree) {
				my $buffer = $token{buffer};
				my $lineno = $token{lineno};
				if ( $tree
					=~ /package_declarator__S_\d+(class|grammar|module|package|role|knowhow|slang) package_def longname/
					)
				{

					# (classes, grammars, modules, packages, roles) or main are always parent nodes
					$symbol_type = $1;
					$symbol_name .= $buffer;
					$symbol_line = $lineno;
				} elsif ( $tree
					=~ /(package_declarator__S_\d+require module_name)|(statement_control__S_\d+use module_name)/ )
				{

					# require/use a module
					$symbol_type = "modules";
					$symbol_name .= $buffer;
					$symbol_line = $lineno;
				} elsif ( $tree =~ /routine_declarator__S_\d+sub routine_def deflongname/ ) {

					# a subroutine
					$symbol_type   = "methods";
					$symbol_suffix = " (subroutine)";
					$symbol_name .= $buffer;
					$symbol_line = $lineno;
				} elsif ( $tree =~ /routine_declarator__\w+_\d+method method_def (longname|$)/ ) {

					# a method
					if ( $buffer eq '!' ) {

						# private method...
						$symbol_suffix = " (private)";
					} elsif ( $buffer eq '^' ) {

						# class or .HOW method
						$symbol_suffix = " (class)";
					}
					$symbol_type = "methods";
					$symbol_name .= $buffer;
					$symbol_line = $lineno;
				} elsif ( $tree =~ /routine_declarator__\w+_\d+submethod method_def longname/ ) {

					# a submethod
					$symbol_type   = "methods";
					$symbol_suffix = " (submethod)";
					$symbol_name .= $buffer;
					$symbol_line = $lineno;
				} elsif ( $tree =~ /routine_declarator__\w+_\d+macro macro_def deflongname/ ) {

					# a macro
					$symbol_type   = "methods";
					$symbol_suffix = " (macro)";
					$symbol_name .= $buffer;
					$symbol_line = $lineno;
				} elsif ( $tree =~ /regex_declarator__\w+_\d+(regex|token|rule) regex_def deflongname/ ) {

					# a regex, token or rule declaration
					$symbol_type = "regexes";
					$symbol_name .= $buffer;
					$symbol_line = $lineno;
				} elsif ( $tree
					=~ /scope_declarator__\w+_\d+(our|my|has|state|constant) scoped declarator variable_declarator variable/
					)
				{

					# a start for an attribute declaration
					$symbol_type = "attributes";
					$symbol_name .= $buffer;
					$symbol_line   = $lineno;
					$symbol_suffix = $1;
				} else {
					if ( $symbol_name ne '' ) {
						if (   $symbol_type eq 'class'
							|| $symbol_type eq 'grammar'
							|| $symbol_type eq 'module'
							|| $symbol_type eq 'package'
							|| $symbol_type eq 'role'
							|| $symbol_type eq 'knowhow'
							|| $symbol_type eq 'slang' )
						{
							$context = $symbol_name;
							if ( not $cur_pkg->{name} ) {
								$cur_pkg->{name} = 'GLOBAL';
							}
							push @outline, $cur_pkg;
							$cur_pkg         = {};
							$cur_pkg->{name} = $symbol_name . " ($symbol_type)";
							$cur_pkg->{line} = $symbol_line;
						} else {
							if ( $symbol_type eq 'attributes' ) {
								if ( $symbol_name !~ /\./ ) {
									$symbol_suffix = " (private, $symbol_suffix)";
								} else {
									$symbol_suffix = " ($symbol_suffix)";
								}
							}
							$symbol_name .= $symbol_suffix;
							push @{ $cur_pkg->{$symbol_type} },
								{
								name => $symbol_name,
								line => $symbol_line,
								};
						}
						$symbol_type   = '';
						$symbol_name   = '';
						$symbol_line   = -1;
						$symbol_suffix = '';
					}
				}
			}
		}

		if ( not $cur_pkg->{name} ) {
			$cur_pkg->{name} = 'GLOBAL';
		}
		push @outline, $cur_pkg;

	}

	return \@outline;
}

1;



=pod

=head1 NAME

Padre::Plugin::Perl6::Outline - Perl 6 Outline background task

=head1 VERSION

version 0.71

=head1 SYNOPSIS

  # by default, the text of the current document
  # will be fetched as will the document's notebook page.
  my $task = Padre::Plugin::Perl6::Outline->new;
  $task->schedule;

=head1 DESCRIPTION

This class implements structure info gathering of Perl6 documents in
the background.
It inherits from L<Padre::Task::Outline>.
Please read its documentation!

=head1 SEE ALSO

This class inherits from L<Padre::Task::Outline> which
in turn is a L<Padre::Task> and its instances can be scheduled
using L<Padre::TaskManager>.

=head1 AUTHORS

=over 4

=item *

Ahmad M. Zawawi <ahmad.zawawi@gmail.com>

=item *

Gabor Szabo L<http://szabgab.com/>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Ahmad M. Zawawi.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__

