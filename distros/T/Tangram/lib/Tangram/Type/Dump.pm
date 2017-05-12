
package Tangram::Type::Dump;

=head1 NAME

Tangram::Type::Dump - Handy functions for Pixie-like dumping of data

=head1 SYNOPSIS

  use Tangram::Type::Dump qw(flatten unflatten UNflatten nuke);

  use YAML qw(freeze thaw); # for instance

  my $frozen = freeze flatten($storage, $structure);

  # optional - remove circular references from flattened
  # structure so that it is freed up properly.
  nuke $frozen;

  # save frozen somewhere...

  # restore, but don't load objects straight away
  my $reconstituted = unflatten($storage, thaw $frozen);

  # restore, loading objects immediately
  my $original = UNflatten($storage, $frozen);

  # Alternative, quickly marshall a structure for saving
  my $structure;
  flatten($storage, $structure);
  # ... do something with it ...

  # restore to former glory; note that Tangram's cache will
  # prevent unnecessary DB access.
  unflatten($storage, $structure);

=head1 DESCRIPTION

This module contains functions for traversing data structures which
are I<not> Tangram-registered objects, and replacing all the Tangram
objects found with `Mementos'.

When a similar data structure is fed back into the reversal function,
the mementos are filled with on-demand references to the real objects.

All these functions operate B<in place> for maximum efficiency.

=cut

use Exporter;
use vars qw(@ISA @EXPORT @EXPORT_OK);
use strict;
BEGIN {
    @ISA=qw(Exporter);
    @EXPORT_OK=qw(scan flatten unflatten expand nuke);
}

use Set::Object qw(blessed reftype refaddr);
#use Tangram::Info qw(dispel_overload);
use Carp;

use constant DEBUG => 0;
sub debug { print STDERR __PACKAGE__
		."[line ".((caller())[2])."]: @_\n" if DEBUG }

=head1 FUNCTIONS

=over

=item B<flatten($storage, $structure)>

Traverses the structure B<$structure>, and replaces all the known (ie,
already inserted) Tangram objects with references to them

=cut

sub flatten {
    my $storage = shift;
    blessed $storage && $storage->isa("Tangram::Storage")
	or croak 'usage: flatten($storage, $structure)';

    my $structure = shift;
    ref $structure or return $structure;
    debug "flatten($structure)";

    # check for Tangram objects, replace them with mementos
    my @obj_stack = $structure;
    my $seen = Set::Object->new(@obj_stack);

    my $check = sub {
	if (my $x = tied $_[0] ) {
	    if ( $x->isa("Tangram::Lazy::Ref") ) {
		# FIXME - code path not covered by test suite
		my ($id,$cid) = $storage->split_id($x->id);
		$id.=",$cid";
		#@$x = ();
		#untie $_[0];
		$_[0] = bless \$id, "Tangram::Memento";
	    } else {
		# ignore; the user's problem :)
	    }
	} else {
	    if ( ref $_[0] ) {
		if (blessed $_[0] and
		    my $id = $storage->id_maybe_insert($_[0])) {

		    ($id,my $cid) = $storage->split_id($id);
		    $id.=",$cid";
		    $_[0] = bless \$id, "Tangram::Memento";

		} elsif ( blessed $_[0] && $_[0]->isa("Set::Object") ) {

		    # FIXME - use Pixie complicity functions to solve this for
		    # the general case.
		    my @objects = $_[0]->members;
		    $_[0]->DESTROY;                 # arrr!
		    ${$_[0]} = \@objects;

		    # then re-bless it
		    bless $_[0], "Tangram::Memento::Set";
		    push @obj_stack, ${ $_[0] };

		} elsif ($seen->insert($_[0])) {
		    push @obj_stack, $_[0]
		}
	    }
	}
    };

    while (my $obj = shift @obj_stack) {

	if (reftype $obj eq "HASH") {

	    while (my $key = each %$obj) {
		$check->($obj->{$key});
	    }

	} elsif (reftype $obj eq "ARRAY") {

	    for my $i (0..$#$obj) {
		$check->($obj->[$i]);
	    }

	} elsif (reftype $obj eq "CODE") {

	    die "CODE references unsafe";

	} elsif ( reftype $obj eq "SCALAR"
		  or reftype $obj eq "REF" ) {

	    # better hope it's not a ref to a C data structure :)
	    $check->($$obj);
	}
    }

    use Data::Dumper;
    (DEBUG > 1) && debug("flattened to: ".Dumper($structure));
}

=item B<unflatten($storage, $structure)>

Performs the logical opposite of B<flatten>, but only insofar as a
`normal' user is concerned.  `Normal' users, of course, don't care
that the data structure is being loaded from the database as they use
it :).

=cut

use Data::Lazy 0.6;

sub unflatten {
    my $storage = shift;
    blessed $storage && $storage->isa("Tangram::Storage")
	or croak 'usage: unflatten($storage, $structure)';

    my $structure = shift;
    ref $structure or return $structure;

    debug "un-flatten $structure";

    # look for mementos, replace them with on-demand references
    my @obj_stack = $structure;
    my $seen = Set::Object->new(@obj_stack);

    my $check = sub {
	if ( tied $_[0] and tied($_[0]) =~ m/^Tangram::Lazy::Ref/ ) {
	    # already a demand paged reference - ignore
	} else {
	    if ( blessed $_[0] and $_[0]->isa("Tangram::Memento") ) {

		my ($id, $cid) = ${$_[0]} =~ m{(\d+),(\d+)};
		$id = $storage->combine_ids($id,$cid);

		(DEBUG>1) && debug "setting up Lazy::Ref($id)";

		if ( defined($storage->{objects}{$id}) ) {
		    $_[0] = $storage->{objects}{$id};
		} else {
		    tie $_[0], 'Tangram::Lazy::Ref',
			$storage, undef, \$_[0], $id;
		}

	    } elsif ( blessed $_[0] and $_[0]->isa("Tangram::Memento::Set") ) {

		my @members = @{${$_[0]}};
		tie $_[0], "Data::Lazy",
		    sub {
			my $x = Set::Object->new(@members);
			@members=();
			$x;
		    }, \$_[0];

		push @obj_stack, \@members;

	    } elsif (ref $_[0] && $seen->insert($_[0])) {
		push @obj_stack, $_[0];
	    }
	}
    };

    while (my $obj = shift @obj_stack) {

	if (reftype $obj eq "HASH") {
	    while (my $key = each %$obj) {
		$check->($obj->{$key});
	    }
	} elsif (reftype $obj eq "ARRAY") {
	    for my $i (0..$#$obj) {
		$check->($obj->[$i]);
	    }
	} elsif (reftype $obj eq "CODE") {
	    # ignore..

	} elsif (reftype $obj eq "SCALAR" or
		 reftype $obj eq "REF") {

	    $check->($$obj) if ref $$obj;
	}
    }

    return $structure;
}


1;

__END__

=back

=head1 BUGS

Should this module just be an extension to Tangram::Storage ?

=head1 AUTHOR

Sam Vilain, samv@cpan.org.  All rights reserved.  This code is free
software; you can use and/or modify it under the same terms as Perl
itself.

=cut

