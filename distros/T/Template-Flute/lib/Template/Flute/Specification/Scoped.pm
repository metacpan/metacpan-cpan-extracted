package Template::Flute::Specification::Scoped;

use strict;
use warnings;

use Template::Flute::Specification;
use Config::Scoped;

=head1 NAME

Template::Flute::Specification::Scoped - Config::Scoped Specification Parser

=head1 SYNOPSIS

    $scoped = new Template::Flute::Specification::Scoped;

    $spec = $scoped->parse_file($specification_file);
    $spec = $scoped->parse($specification_text);

=head1 CONSTRUCTOR

=head2 new

Create a Template::Flute::Specification::Scoped object.

=cut

# Constructor

sub new {
	my ($class, $self);
	my (%params);

	$class = shift;
	%params = @_;

	$self = \%params;

	bless ($self, $class);
}

=head1 METHODS

=head2 parse [ STRING | SCALARREF ]

Parses text from STRING or SCALARREF and returns L<Template::Flute::Specification>
object in case of success.

=cut
	
sub parse {
	my ($self, $text) = @_;
	my ($scoped, $config);
	
	# create Config::Scoped parser and parse text
	$scoped = new Config::Scoped;

	if (ref($text) eq 'SCALAR') {
		$config = $scoped->parse(text => $$text);
	}
	else {
		$config = $scoped->parse(text => $text);
	}

	$self->{spec} = $self->create_specification($config);

	return $self->{spec};
}

=head2 parse_file FILENAME

Parses text from file FILENAME and returns L<Template::Flute::Specification>
object in case of success.

=cut

sub parse_file {
	my ($self, $file) = @_;
	my ($scoped, $config, $key, $value, %list);

	# create Config::Scoped parser and parse file
	$scoped = new Config::Scoped(file => $file);
	$config = $scoped->parse();

	$self->{spec} = $self->create_specification($config);

	return $self->{spec};
}

=head2 create_specification [ HASHREF ]

Takes a L<Config::Scoped> hash reference and returns a 
L<Template::Flute::Specification> object.  Mostly used for parse and 
parse_file methods.

=cut

sub create_specification {
	my ($self, $config) = @_;
	my ($spec, $scoped, $key, $value, %list, $encoding);

	# specification object
	$spec = new Template::Flute::Specification;

	if ($encoding = $config->{specification}->{encoding}) {
		$spec->encoding($encoding);
	}
	
	# lists
	while (($key, $value) = each %{$config->{list}}) {
		$value->{name} = $key;
		$list{$key} = $value;
	}

	# adding list tokens: params, separators, inputs and filters
	my ($list);

	for my $cname (qw/param input filter separator/) {
		while (($key, $value) = each %{$config->{$cname}}) {
			$list = delete $value->{list};
			$value->{name} = $key;
		
			if ($list) {
				if (exists $list{$list}) {
					push @{$list{$list}->{$cname}}, {%$value};
				}
				else {
					die "List missing for $cname $key.";
				}
			}
			else {
				die "No list assigned to $cname $key.";
			}
		}
	}

	# adding other tokens: values and i18n
	for my $cname (qw/value i18n/) {
		while (($key, $value) = each %{$config->{$cname}}) {
			$value->{name} = $key;

			if ($cname eq 'value') {
				$spec->value_add({value => $value});
			}
			elsif ($cname eq 'i18n') {
				$spec->i18n_add({i18n => $value});
			}
		}
	}

	while (($key, $value) = each %{$config->{list}}) {
		$spec->list_add({list => $value,
				 param => $value->{param},
				 separator => $value->{separator},
				 input => $value->{input},
				 filter => $value->{filter},
				});
	}

	return $spec;
}

=head2 error

Returns last error.

=cut

sub error {
	my ($self) = @_;

	if (@{$self->{errors}}) {
		return $self->{errors}->[0]->{error};
	}
}

sub _add_error {
	my ($self, @args) = @_;
	my (%error);

	%error = @args;
	
	unshift (@{$self->{errors}}, \%error);
}

=head1 AUTHOR

Stefan Hornburg (Racke), <racke@linuxia.de>

=head1 LICENSE AND COPYRIGHT

Copyright 2010-2016 Stefan Hornburg (Racke) <racke@linuxia.de>.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1;
