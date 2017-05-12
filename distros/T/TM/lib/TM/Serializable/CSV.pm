package TM::Serializable::CSV;

use strict;
use warnings;

use Class::Trait 'base';
use Class::Trait 'TM::Serializable';

use Data::Dumper;


=pod

=head1 NAME

TM::Serializable::CSV - Topic Maps, trait for parsing (and later dumping) CSV stream

=head1 SYNOPSIS

   # 1) bare bones
   my $tm = .....;  # get a map from somewhere (can be empty)
   Class::Trait->apply ($tm, "TM::Serializable::CSV");

   use Perl6::Slurp;
   $tm->deserialize (slurp 'myugly.csv');

   # 2) exploiting the timed sync in/out mechanism
   my $tm = new TM::.... (url => 'file:myugly.csv'); # get a RESOURCEABLE map from somewhere
   $tm->sync_in;

=head1 DESCRIPTION

This trait provides parsing and dumping from CSV formatted text streams.

=head1 INTERFACE

=head2 Methods

=over

=item B<deserialize>

I<$tm>->deserialize (I<$text>)

This method consumes the text string passed in and interprets it as CSV formatted information. What topic
map information is generated, depends on the header line (the first line):

=over

=item

If the header line contains a field called C<association-type>, then all rows will be interpreted as
assertions. In that the remaining header fields (in that order) are interpreted as roles (role
types). For all rows in the CSV stream, the position where the C<association-type> field was is
ignored.  The other fields (in that order) are affiliated with the corresponding roles.

Example:

   association-type,location,bio-unit
   is-born,gold-coast,rumsti
   is-born,vienna,ramsti

Scoping cannot be controlled. Also all players and roles (obviously) are directly interpreted as
identifiers. Subject identifiers and locators are not (yet) implemented.

=item

If the header line contains a field called C<id>, then all further rows will be interpreted as topic
characteristics, with each topic on one line. The column position where the C<id> field in the
header is will be interpreted as toplet identifier.

All further columns will be interpreted according to the following:

=over

=item

If the header column is named C<name>, the values will be used as topic names.

=item

Otherwise if the value looks like a URI, an occurrence with that URI value will be be added to the topic.

=item

Otherwise an occurrence with a string value will be added to the topic.

=back

Example:

   name,id,location,homepage
   "Rumsti",rumsti,gold-coast,http://rumsti.com
   "Ramsti",ramsti,vienna,http://ramsti.com

=back

=cut

sub deserialize {
    my $self = shift;
    my $stream = shift;
    my %options = @_;

    $stream =~ s/\r//g;                                                                      # F...ing M$
    my @lines = split /\n/, $stream;

    use Text::CSV;
    my $csv = Text::CSV->new({ always_quote => 1 });

    #-- first line -------------------------
    $csv->parse (shift @lines); # and warn $csv->error_diag ();
    my @headers = map { s/ /-/g; $_ }                                                        # get rid of blanks, I hate blanks
                  $csv->fields();

    if (defined (my $pos = _find_and_kill (\@headers, 'association-type'))) {
	foreach my $line (@lines) {
	    $csv->parse ($line) ; #and warn  $csv->error_diag ();
	    my @players = $csv->fields();
	    my $type    = splice @players, $pos, 1;

	    if (my $p = $options{preprocess}) {                                              # if the application wants to modify the values before adding
		foreach my $i (0..$#players) {                                               # clumsily step through the player/header lists
		    $players[$i] = &$p ( $headers[$i], $players[$i] );                       # apply the change
		}
	    }
#	    warn "$type: ".Dumper (\@headers, \@players);
	    
	    $self->assert (
		Assertion->new (kind    => TM->ASSOC,
				type    => $type,
				scope   => 'us',
				roles   => \@headers,
				players => \@players)
		);
	}
	sub _find_and_kill {
	    my $roles = shift;
	    my $kill  = shift;
	    foreach my $i (0 .. $#$roles) {
		if ($roles->[$i] eq $kill) {
		    splice @$roles, $i, 1;  # remove that from the roles list, but ...
		    return $i;              # we memorize its position
		}
	    }
	    return undef;
	}
    } elsif (defined ($pos = _find_and_kill (\@headers, 'id'))) {
	foreach my $line (@lines) {
	    $csv->parse ($line) ; #and warn  $csv->error_diag ();
	    my @attrs = $csv->fields();
	    my $id    = splice @attrs, $pos, 1;

	    $self->internalize ($id);

	    use Regexp::Common qw /URI/;
	    use TM::Literal;
	    foreach my $i (0..$#attrs) {
		if (my $p = $options{preprocess}) {
		    eval {
			$attrs[$i] = &$p ( $headers[$i], $attrs[$i] );                    # user-defined transformation of the value
		    };
		    next if $@;                                                           # on die, we simply skip that attribute
		}

		if ($headers[$i] eq 'name') {
		    $self->assert (
			Assertion->new (kind    => TM->NAME,
					type    => 'name',
					scope   => 'us',
					roles   => [ 'topic', 'value'],
					players => [ $id,    new TM::Literal ($attrs[$i], TM::Literal->STRING)  ])
			);

		} elsif ($attrs[$i] =~ /$RE{URI}/) {
		    $self->assert (
			Assertion->new (kind    => TM->OCC,
					type    => $headers[$i],
					scope   => 'us',
					roles   => [ 'thing', 'value'],
					players => [ $id,  new TM::Literal ($attrs[$i], TM::Literal->URI) ])
			);

		} else {
		    $self->assert (
			Assertion->new (kind    => TM->OCC,
					type    => $headers[$i],
					scope   => 'us',
					roles   => [ 'thing', 'value'],
					players => [ $id,   new TM::Literal ($attrs[$i], TM::Literal->STRING) ])
			);
		}
	    }
	    
	}
    } else {
	die;
    }

}

=pod

=item B<serialize>

I<$tm>->serialize

[Since TM 1.53] This method serializes a fragment of a topic map into CSV. B<Which> fragment can be
controlled with the I<header line> and options (see constructor).

=over

=item C<header_line> (only for serialization)

This string contains a comma separated list (CSV parseable) of headings. If one of the headings is
C<association-type>, then the generated CSV content will contain associations only. Nothing else is
implemented yet. The other headings control which roles (and in which order) should be included in
the CSV content. If a particular role type has more than one player, then B<all> players are included.

B<NOTE>: As this is inconsistent, this will have to change.

=item C<type> (only for serialization)

If existing, then this controls which association type is to be taken.

=item C<baseuri> (only for serialization)

If existing and non-zero, the base URI of the map will remain in the identifiers. Otherwise it will
be removed.

=item C<specification>

If existing (and when selecting only associations), this specification will be interpreted in the
sense of C<asserts> (see L<TM>).

=back

=back

Example:

    $tm->serialize (header_line => 'association-type,location,bio-unit',
                    type        => 'is-born',
                    baseuri     => 0);

=cut

sub serialize {
    my $self    = shift;
    my $headers = shift;
    my %options = @_;

    my $bu = $self->baseuri; # we may need it later

    use Text::CSV;
    my $csv = Text::CSV->new();

    $csv->parse ($headers);
    my @headers = $csv->fields;

    my $content = ( join ",", @headers ) . "\n";
    if (grep { $_ eq 'association-type' } @headers) {
	my @as;
	if ($options{type}) {
	    @as = $self->match_forall (type => $self->tids ($options{type}));

	} elsif ($options{specification}) {
	    @as = $self->asserts (\ $options{specification});

	} else {
	    my $spec = \ '+associations';
	    @as = $self->asserts ($spec);
	}

	foreach my $a ( @as ) {
	    my @vs;
	    foreach my $h (@headers) {
		if ($h eq 'association-type') {
		    push @vs, $a->[TM->TYPE];
		} else {
		    push @vs, TM::get_players ($self, $a, $self->tids ($h));
		}
	    }
	    @vs = map { $_ =~ s/^$bu// ; $_ } @vs unless ($options{baseuri});
	    
	    $content .= (join ",", @vs) . "\n";
	}

    } else {
	die "not yet implemented";
    }
    return $content;
}

=pod

=back

=head1 SEE ALSO

L<TM>, L<TM::Serializable>

=head1 AUTHOR INFORMATION

Copyright 2010 Robert Barta.

This library is free software; you can redistribute it and/or modify it under the same terms as Perl
itself.  http://www.perl.com/perl/misc/Artistic.html

=cut

our $VERSION = 0.02;

1;
