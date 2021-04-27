# ABSTRACT: scan for required plugins in Pod::Weaver plugin bundles

######################################################################
# Copyright (C) 2021 Asher Gordon <AsDaGo@posteo.net>                #
#                                                                    #
# This program is free software: you can redistribute it and/or      #
# modify it under the terms of the GNU General Public License as     #
# published by the Free Software Foundation, either version 3 of     #
# the License, or (at your option) any later version.                #
#                                                                    #
# This program is distributed in the hope that it will be useful,    #
# but WITHOUT ANY WARRANTY; without even the implied warranty of     #
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU   #
# General Public License for more details.                           #
#                                                                    #
# You should have received a copy of the GNU General Public License  #
# along with this program. If not, see                               #
# <http://www.gnu.org/licenses/>.                                    #
######################################################################

package Perl::PrereqScanner::Scanner::PodWeaver::PluginBundle;
$Perl::PrereqScanner::Scanner::PodWeaver::PluginBundle::VERSION = '0.001';
use v5.18.0;
use strict;
use warnings;
use feature 'lexical_subs';
no warnings 'experimental::lexical_subs';
use namespace::autoclean;
use Moose;
use Pod::Weaver::Config::Assembler;

with 'Perl::PrereqScanner::Scanner';

#pod =head1 DESCRIPTION
#pod
#pod This scanner will look for the following indicators:
#pod
#pod =begin :list
#pod
#pod * array references of three elements, with the third being a hash
#pod   reference
#pod
#pod =end :list
#pod
#pod This isn't perfect, but it's not really practical to be much better
#pod without actually running the code.
#pod
#pod =cut

# Look for the first quoted string, possibly entering lists and
# expressions.
my sub find_quote;
sub find_quote {
    foreach my $element (@_) {
	return $element->string if $element->isa('PPI::Token::Quote');
	if ($element->isa('PPI::Token::Word')) {
	    my $next = $element->snext_sibling;
	    return $element->literal if defined $next &&
		$next->isa('PPI::Token::Operator') && $next eq '=>';
	}
	my $str = find_quote $element->children
	    if $element->isa('PPI::Structure::List') ||
	    $element->isa('PPI::Statement::Expression');
	return $str if defined $str;
    }
    return;
}

sub scan_for_prereqs {
    my ($self, $ppi_doc, $req) = @_;

    my @nodes = grep { ($_->braces // '') eq '[]' }
	@{$ppi_doc->find('PPI::Structure::Constructor')};
    foreach my $node (@nodes) {
	my @elements = $node->schildren;
	@elements = $elements[0]->schildren if @elements == 1 &&
	    $elements[0]->isa('PPI::Statement');

	# Group the elements together as they appear in the list.
	my @groups = [];
	foreach my $element (@elements) {
	    if ($element->isa('PPI::Token::Operator') &&
		$element =~ /^(?:,|=>)$/) {
		push @groups, [];
	    }
	    else {
		push @{$groups[-1]}, $element;
	    }
	}

	# Make sure there are three elements, and that the last is a
	# hash reference.
	next unless @groups == 3;
	my (undef, $plugin, $options) = @groups;
	return unless @$options == 1;
	($options) = @$options;
	return unless
	    $options->isa('PPI::Structure::Constructor') &&
	    ($options->braces // '') eq '{}';

	# Look for the first quoted string.
	my $name = find_quote @$plugin;
	if (defined $name) {
	    $name =
		Pod::Weaver::Config::Assembler->expand_package($name);
	    $req->add_minimum($name => 0)
	}
	else {
	    ($node) = @$plugin if @$plugin;
	    my ($file, $line) = map $node->$_,
		qw(logical_filename logical_line_number);
	    my $msg = 'Invalid plugin specification';
	    $msg .= ' at' if defined ($file // $line);
	    $msg .= " $file" if defined $file;
	    $msg .= " line $line" if defined $line;
	    $msg .= "\n";
	    warn $msg;
	}
    }
}

__END__

=pod

=encoding UTF-8

=head1 NAME

Perl::PrereqScanner::Scanner::PodWeaver::PluginBundle - scan for required plugins in Pod::Weaver plugin bundles

=head1 VERSION

version 0.001

=head1 DESCRIPTION

This scanner will look for the following indicators:

=over 4

=item *

array references of three elements, with the third being a hash reference

=back

This isn't perfect, but it's not really practical to be much better
without actually running the code.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<https://rt.cpan.org/Public/Dist/Display.html?Name=Perl-PrereqScanner-Scanner-DistZilla-PluginBundle>
or by email to
L<bug-Perl-PrereqScanner-Scanner-DistZilla-PluginBundle@rt.cpan.org|mailto:bug-Perl-PrereqScanner-Scanner-DistZilla-PluginBundle@rt.cpan.org>.

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

Asher Gordon <AsDaGo@posteo.net>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2021 Asher Gordon <AsDaGo@posteo.net>

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or (at
your option) any later version.

This program is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program. If not, see <http://www.gnu.org/licenses/>.

=cut
