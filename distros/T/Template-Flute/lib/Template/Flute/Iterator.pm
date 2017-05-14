package Template::Flute::Iterator;

use strict;
use warnings;

=head1 NAME

Template::Flute::Iterator - Generic iterator class for Template::Flute

=head1 SYNOPSIS

    $cart = [{isbn => '978-0-2016-1622-4',
              title => 'The Pragmatic Programmer',
              quantity => 1},
             {isbn => '978-1-4302-1833-3',
              title => 'Pro Git',
              quantity => 1},
            ];

    $iter = new Template::Flute::Iterator($cart);

    print "Count: ", $iter->count(), "\n";

    while ($record = $iter->next()) {
	    print "Title: ", $record->title(), "\n";
    }

    $iter->reset();

    $iter->seed({isbn => '978-0-9779201-5-0',
                 title => 'Modern Perl',
                 quantity => 10});

=head1 CONSTRUCTOR

=head2 new

Creates a Template::Flute::Iterator object. The elements of the
iterator are hash references. They can be passed to the constructor
as array or array reference.

=cut

# Constructor
sub new {
	my ($proto, @args) = @_;
	my ($class, $self);
	
	$class = ref($proto) || $proto;

	$self = {};
	
	bless $self, $class;

	$self->seed(@args);

	return $self;
}

=head1 METHODS

=head2 next

Returns next record or undef.

=cut

sub next {
	my ($self) = @_;


	if ($self->{INDEX} <= $self->{COUNT}) {
		return $self->{DATA}->[$self->{INDEX}++];
	}
	
	return;
};

=head2 count

Returns number of elements.

=cut
	
sub count {
	my ($self) = @_;

	return $self->{COUNT};
}

=head2 reset

Resets iterator.

=cut

# Reset method - rewind index of iterator
sub reset {
	my ($self) = @_;

	$self->{INDEX} = 0;

	return $self;
}

=head2 seed

Seeds iterator.

=cut

sub seed {
	my ($self, @args) = @_;

	if (ref($args[0]) eq 'ARRAY') {
		$self->{DATA} = $args[0];
	}
	else {
		$self->{DATA} = \@args;
	}

	$self->{INDEX} = 0;
	$self->{COUNT} = scalar(@{$self->{DATA}});

	return $self->{COUNT};
}

=head2 sort

Sorts records of the iterator.

Parameters are:

=over 4

=item $sort

Field used for sorting.

=item $unique

Whether results should be unique (optional).

=back

=cut
    
sub sort {
    my ($self, $sort, $unique) = @_;
    my (@data, @tmp);

    @data = sort {lc($a->{$sort}) cmp lc($b->{$sort})} @{$self->{DATA}};

    if ($unique) {
        my $sort_value = '';

        for my $record (@data) {
            next if $record->{$sort} eq $sort_value;
            $sort_value = $record->{$sort};
            push (@tmp, $record);
        }

        $self->{DATA} = \@tmp;
    }
    else {
        $self->{DATA} = \@data;
    }
}

=head1 AUTHOR

Stefan Hornburg (Racke), <racke@linuxia.de>

=head1 LICENSE AND COPYRIGHT

Copyright 2010-2014 Stefan Hornburg (Racke) <racke@linuxia.de>.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=head1 SEE ALSO

L<Template::Flute::Iterator::JSON>

=cut

1;
