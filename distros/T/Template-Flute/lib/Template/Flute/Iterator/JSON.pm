package Template::Flute::Iterator::JSON;

use strict;
use warnings;

use JSON;

use base 'Template::Flute::Iterator';

=head1 NAME

Template::Flute::Iterator::JSON - Iterator class for JSON strings and files

=head1 SYNOPSIS

    $json = q{[
        {"sku": "orange", "image": "orange.jpg"},
        {"sku": "pomelo", "image": "pomelo.jpg"}
    ]};

    $json_iter = Template::Flute::Iterator::JSON->new($json);

    $json_iter->next();

    $json_iter_file = Template::Flute::Iterator::JSON->new(file => 'fruits.json');

=head1 DESCRIPTION

Template::Flute::Iterator::JSON is a subclass of L<Template::Flute::Iterator>.

=head1 CONSTRUCTOR

=head2 new

Creates an Template::Flute::Iterator::JSON object from a JSON string.

The JSON string can be either passed as such or as scalar reference.

=cut

sub new {
	my ($class, @args) = @_;
	my ($json, $json_struct, $self, $key, $value);

	$self = {};
	
	bless ($self, $class);

	if (@args == 1) {
		# single parameter => JSON is passed as string or scalar reference
		if (ref($args[0]) eq 'SCALAR') {
			$json = ${$args[0]};
		}
		else {
			$json = $args[0];
		}

		$json_struct = from_json($json);
		$self->_seed_iterator($json_struct);
		
		return $self;
	}
	
	while (@args) {
		$key = shift(@args);
		$value = shift(@args);
		
		$self->{$key} = $value;
	}

	if ($self->{file}) {
		$json_struct = $self->_parse_json_from_file($self->{file});
		$self->_seed_iterator($json_struct);
	}
	else {
		die "Missing JSON file.";
	}
	
	return $self;
}

sub _seed_iterator {
    my ($self, $json_struct) = @_;

    if (exists $self->{selector}) {
        if (ref($self->{selector}) eq 'HASH') {
            my (@k, $key, $value);

            # loop through top level elements and locate selector
            if ((@k = keys %{$self->{selector}})) {
                $key = $k[0];
                $value = $self->{selector}->{$key};

                for my $record (@$json_struct) {
                    if (exists $record->{$key} 
                        && $record->{$key} eq $value) {
                        $self->seed($record->{$self->{children}});
                        return;
                    }
                }
            }

            return;
        }
        elsif ($self->{selector} eq '*') {
            # find all elements
            $self->seed($self->_tree($json_struct, $self->{children}, $self->{sort}));

            if ($self->{sort}) {
                $self->sort($self->{sort}, $self->{unique});
            }

            return;
        }

        # no matches for selector, seed iterator with empty list
        $self->seed();
        return;
    }
    
    $self->seed($json_struct);
}

sub _tree {
    my ($self, $json_struct, $children, $sort) = @_;
    my (@leaves);

    for my $record (@$json_struct) {
        if (exists $record->{$children}) {
            for my $child (@{$record->{$children}}) {
                push (@leaves, $child);
            }
        }
    }

    return \@leaves;
}

sub _parse_json_from_file {
	my ($self, $file) = @_;
	my ($json_fh, $json_struct, $json_txt);
	
	# read from JSON file
	unless (open $json_fh, '<', $file) {
		die "$0: failed to open JSON file $file: $!\n";
	}

	while (<$json_fh>) {
		$json_txt .= $_;
	}

	close $json_fh;

	# parse JSON
	$json_struct = from_json($json_txt);

	return $json_struct;
}

=head1 AUTHOR

Stefan Hornburg (Racke), <racke@linuxia.de>

=head1 LICENSE AND COPYRIGHT

Copyright 2011 Stefan Hornburg (Racke) <racke@linuxia.de>.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1;
