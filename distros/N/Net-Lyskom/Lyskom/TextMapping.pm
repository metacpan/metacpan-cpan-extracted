package Net::Lyskom::TextMapping;
use base qw{Net::Lyskom::Object};
use strict;
use warnings;

use Net::Lyskom::Util qw{:all};

=head1 NAME

Net::Lyskom::TextMapping - represents a text_mapping

=head1 SYNOPSIS

  $global_no = $obj->global(4711);

@globals = $obj->global_text_numbers;

@locals = $obj->local_text_numbers;

=head1 DESCRIPTION

Holds information on mappings between local and global text numbers for
a conference.

=head2 Methods

=over

=item ->range_begin()

Returns the first local text number that this mapping has information on.

=item ->range_end()

Returns the first local text number that this mapping does B<not> hold
information on.

=item ->later_texts_exist()

Returns true if the conference has local numbers beyond those detailed
in this mapping.

=item ->global($no)

Takes a local text number and returns the corresponding global text number,
or undef if the local number is nonexistant (or just not included in this
mapping).

=item ->local_text_numbers()

Returns a list of all local text numbers in this mapping, in strictly
ascending order.

=item ->global_text_numbers()

Returns a list of all global text numbers in this mapping, in ascending
B<local> number order.

=back

=cut

sub range_begin {my $s = shift; return $s->{range_begin}};
sub range_end {my $s = shift; return $s->{range_end}};
sub later_texts_exist {my $s = shift; return $s->{later_texts_exist}};

sub global {
    my $s = shift;

    return $s->{_l2ghash}{$_[0]};
}

sub local_text_numbers {
    my $s = shift;

    return sort {$a <=> $b} keys %{$s->{_l2ghash}};
}

sub global_text_numbers {
    my $s = shift;

    return map {$s->{_l2ghash}{$_}} sort {$a <=> $b} keys %{$s->{_l2ghash}};
}


sub new_from_stream {
    my $s = {};
    my $class = shift;
    my $ref = shift;
    my @pairs;

    $class = ref($class) if ref($class);
    bless $s,$class;

    $s->{range_begin} = shift @{$ref};
    $s->{range_end} = shift @{$ref};
    $s->{later_texts_exist} = shift @{$ref};

    if (shift @{$ref}) {
	# true, so it's a TextList
	my $local_no = shift @{$ref};
	my @texts = parse_array_stream(sub{shift @{$_[0]}},$ref);
	foreach (@texts) {
	    push @pairs,[$local_no,$_] if $_;
	    $local_no++;
	}
    } else {
	# false, so it's an ARRAY of TextNumberPair
	@pairs = parse_array_stream(sub{[shift @{$_[0]},shift @{$_[0]}]},$ref);
    }

    foreach (@pairs) {
	$s->{_l2ghash}{$_->[0]} = $_->[1]
    }

    return $s;
}

1;
