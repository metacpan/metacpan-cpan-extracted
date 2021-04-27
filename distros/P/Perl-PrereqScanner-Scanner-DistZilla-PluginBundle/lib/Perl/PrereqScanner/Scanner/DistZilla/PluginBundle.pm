# ABSTRACT: scan for required plugins in Dist::Zilla plugin bundles

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

package Perl::PrereqScanner::Scanner::DistZilla::PluginBundle;
$Perl::PrereqScanner::Scanner::DistZilla::PluginBundle::VERSION = '0.001';
use v5.18.0;
use strict;
use warnings;
use feature 'lexical_subs';
no warnings 'experimental::lexical_subs';
use namespace::autoclean;
use Moose;

with 'Perl::PrereqScanner::Scanner';

#pod =head1 DESCRIPTION
#pod
#pod This scanner will look for the following indicators:
#pod
#pod =begin :list
#pod
#pod * calls to the C<add_bundle> method
#pod
#pod * calls to the C<add_plugins> method
#pod
#pod =end :list
#pod
#pod Currently this only works for plugin bundles using the
#pod C<Dist::Zilla::Role::PluginBundle::Easy> role.
#pod
#pod =cut

my $is_quote = sub {
    my ($self) = @_;
    $self->isa('PPI::Token::Quote') ||
	$self->isa('PPI::Token::QuoteLike::Words');
};

my $quote_contents = sub {
    my ($self) = @_;
    return $self->string if $self->isa('PPI::Token::Quote');
    return $self->literal
	if $self->isa('PPI::Token::QuoteLike::Words');
    return;
};

# Warn at the position of a certain element.
my sub warn_at {
    my ($element, $msg) = @_;
    unless ($msg =~ /\n$/) {
	my ($file, $line) = map $element->$_,
	    qw(logical_filename logical_line_number);
	$msg .= ' at' if defined ($file // $line);
	$msg .= " $file" if defined $file;
	$msg .= " line $line" if defined $line;
	$msg .= "\n";
    }
    warn $msg;
}

# Handle expressions and remove commas and fat arrows.
my sub process_list {
    @_ = $_[0]->schildren if @_ == 1 && $_[0]->isa('PPI::Statement');
    grep { ! ($_->isa('PPI::Token::Operator') && /^(?:,|=>)$/) } @_;
}

# Return an actual hash from a parsed hash in PPI form.
my sub process_hash {
    my %hash;
    @_ = $_[0]->schildren if @_ == 1 && $_[0]->isa('PPI::Statement');

    my (@name, $value);
    my $processing = 'name';
    foreach my $element (@_) {
	if ($element->isa('PPI::Token::Operator') &&
	    $element =~ /^(?:,|=>)$/) {
	    if ($processing eq 'name') {
		$processing = 'value';
		my @this_name = @name;
		@name = ();

		my $allow_bareword = $element eq '=>';
		my $msg = "Hash key (@this_name) is not a string";
		$msg .= ' or bareword' if $allow_bareword;
		unless (@this_name == 1) {
		    warn_at $element, $msg;
		    next;
		}

		my ($name) = @this_name;
		if ($name->isa('PPI::Token::Quote')) {
		    $name = $name->string;
		}
		elsif ($name->isa('PPI::Token::Word')) {
		    unless ($allow_bareword) {
			warn_at $element, $msg;
			next;
		    }
		    $name = $name->literal;
		}
		else {
		    warn_at $element, $msg;
		    next;
		}

		$value = $hash{$name} = [];
	    }
	    else { # processing value
		$processing = 'name';
		undef $value;
	    }
	}
	else { # not an operator
	    if ($processing eq 'name') {
		push @name, $element;
	    }
	    else { # processing value
		push @$value, $element if defined $value;
	    }
	}
    }

    return %hash;
}

my sub get_bundle_pkg {
    my ($bundle) = @_;
    $bundle =~ s/^\@?/Dist::Zilla::PluginBundle::/r;
}

my %prefixes = (
    '='	=> '',
    '%'	=> 'Dist::Zilla::Stash::',
    ''	=> 'Dist::Zilla::Plugin::',
);
my $prefixes = join '|', map quotemeta, sort keys %prefixes;

my sub get_plugin_pkg {
    my ($plugin) = @_;
    $plugin =~ s/^($prefixes)/$prefixes{$1}/r;
}

# Plugin bundles that use other plugin bundles specified by
# options. TODO: Maybe add more of these.
my %parent_bundles = (
    Filter => sub {
	my ($opts_element, %opts) = @_;
	my ($bundle, $version) = @opts{qw(-bundle -version)};
	return unless defined $bundle;

	unless (@$bundle == 1) {
	    warn_at $bundle->[0] // $opts_element,
		'No bundle given for -bundle key';
	    return;
	}
	($bundle) = @$bundle;
	unless ($bundle->isa('PPI::Token::Quote')) {
	    warn_at $bundle, 'Bundle is not a quoted string';
	    return;
	}
	$bundle = $bundle->string;

	if (defined $version) {
	    unless (@$version == 1) {
		warn_at $version->[0] // $opts_element,
		    'No version given for -version key';
		return;
	    }
	    ($version) = @$version;
	    if ($version->isa('PPI::Token::Quote')) {
		$version = $version->string;
	    }
	    elsif ($version->isa('PPI::Token::Number')) {
		$version = $version->literal;
	    }
	    else {
		warn_at $version, 'Version is not a quoted string or number';
		return;
	    }
	}

	return [$bundle => $version];
    }
);
$parent_bundles{"Dist::Zilla::PluginBundle::$_"} = delete $parent_bundles{$_}
    foreach keys %parent_bundles;

# Get plugins from an argument to add_plugins().
my sub get_plugins {
    my ($arg) = @_;
    return [$arg->$quote_contents] if $arg->$is_quote;
    if ($arg->isa('PPI::Structure::Constructor')) {
	return 'not an array reference'
	    unless ($arg->braces // '') eq '[]';
	return 'array reference is empty'
	    unless my ($plugin, $opts) = process_list $arg->schildren;
	return [($plugin->$quote_contents)[0]] if $plugin->$is_quote;
	return [$plugin->literal] if $plugin->isa('PPI::Token::Word');
	return 'first element of array reference ' .
	    'is not word or quoted string';
    }
    return 'not a quoted string or anonymous array reference';
}

# Valid tokens and the subroutines to process their arguments.
my %tokens = (
    add_bundle	=> sub {
	my ($req, $bundle, $opts) = @_;

	return 'no arguments' unless defined $bundle;

	my $name;
	if ($bundle->isa('PPI::Token::Word')) {
	    $name = $bundle->literal;
	}
	elsif ($bundle->isa('PPI::Token::Quote')) {
	    $name = $bundle->string;
	}
	else {
	    return [$bundle, "first argument ($bundle) not a " .
		    'bareword or quoted string'];
	}
	$name = get_bundle_pkg $name;

	$req->add_minimum($name => 0);

	# Get the plugin bundles used by this one, if any.
	return unless my $get_children = $parent_bundles{$name};

	my %opts;
	if ($opts->isa('PPI::Structure::Constructor') &&
	    ($opts->braces // '') eq '{}') {
	    %opts = process_hash $opts->schildren;
	}
	else {
	    warn_at $opts, 'Not an anonymous hash reference';
	}

	foreach ($get_children->($opts, %opts)) {
	    my ($name, $version) = ref eq 'ARRAY' ? @$_ : $_;
	    $name = get_bundle_pkg $name;
	    $version //= 0;
	    $req->add_minimum($name => $version);
	}

	return;
    },

    add_plugins	=> sub {
	my $req = shift;
	$req->add_minimum((get_plugin_pkg $_) => 0) foreach map {
	    my $arg = $_[$_];
	    my $ret = get_plugins $arg;
	    return [$arg, "argument $_ ($arg): $ret"]
		unless ref $ret eq 'ARRAY';
	    @$ret;
	} 0 .. $#_;
	return;
    },
);

sub scan_for_prereqs {
    my ($self, $ppi_doc, $req) = @_;

    foreach my $node (@{$ppi_doc->find('Statement')}) {
	my @children = $node->schildren;
	my $found_arrow;
	until ($found_arrow || ! @children) {
	    my $op = shift @children;
	    $found_arrow = $op->isa('PPI::Token::Operator') &&
		$op eq '->';
	}
	next unless $found_arrow;

	next unless my $name = shift @children;
	next unless my $add = $tokens{$name};

	my ($args) = @children;
	my $err;
	if (defined $args && $args->isa('PPI::Structure::List')) {
	    $err = $add->($req, process_list $args->schildren);
	}
	else {
	    $err = 'no arguments';
	}

	if (defined $err) {
	    ($node, $err) = @$err if ref $err eq 'ARRAY';
	    warn_at $node, "Cannot parse call to $name: $err";
	}
    }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Perl::PrereqScanner::Scanner::DistZilla::PluginBundle - scan for required plugins in Dist::Zilla plugin bundles

=head1 VERSION

version 0.001

=head1 DESCRIPTION

This scanner will look for the following indicators:

=over 4

=item *

calls to the C<add_bundle> method

=item *

calls to the C<add_plugins> method

=back

Currently this only works for plugin bundles using the
C<Dist::Zilla::Role::PluginBundle::Easy> role.

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
