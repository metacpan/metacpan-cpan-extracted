package Sys::User::UIDhelper;

use warnings;
use strict;

=head1 NAME

Sys::User::UIDhelper - Helps for locating free UIDs using getpwuid.

=head1 VERSION

Version 0.1.0

=cut

our $VERSION = '0.1.0';

=head1 SYNOPSIS

    use Sys::User::UIDhelper;

    # invokes it with the default values
    my $foo = Sys::User::UIDhelper->new();

    # sets the min to 2000 and the max to 4000
    my $foo = Sys::User::UIDhelper->new(min=>2000, max=>4000);

    # finds the first free one
    my $first = $foo->firstfree();
    if(defined($first)){
        print $first."\n";
    }else{
        print "not found\n";
    }

    # finds the last free one
    my $last = $foo->lastfree();
    if(defined($last)){
        print $last."\n";
    }else{
        print "not found\n";
    }


=head1 METHODS

=head2 new

This initiates the module. The following args are accepted.

    - min :: The UID to start with.
        - Default :: 1000

    - max :: The last UID in the range to check for.
        - Default :: 131068

The following is a example showing showing a new instance being created
that will start at 2000 and search up to 4000.

    my $foo = Sys::User::UIDhelper->new(min=>2000, max=>4000);

If any of the args are non-integers or min is greater than max, it will error.

=cut

sub new {
	my ( $blank, %args ) = @_;

	if ( !defined( $args{max} ) ) {
		$args{max} = 131068;
	}
	# this is choosen as on most systems 1000 is the general base for new
	if ( !defined( $args{min} ) ) {
		$args{min} = 1000;
	}

	# max sure the values we got passed are sane
	if ( $args{min} >= $args{max} ) {
		die( 'min, ' . $args{min} . ', is equal to or greater than max, ' . $args{max} . ',' );
	} elsif ( $args{min} !~ /^[0-9]+$/ ) {
		die( 'min, "' . $args{min} . '", is not numeric' );
	} elsif ( $args{max} !~ /^[0-9]+$/ ) {
		die( 'min, "' . $args{max} . '", is not numeric' );
	}

	my $self = {
		max => $args{max},
		min => $args{min},
	};
	bless $self;

	return $self;
} ## end sub new

=head2 first_free

This finds the first free UID. If it returns undef, no free ones were found.

=cut

sub first_free {
	my $self = $_[0];

	my $int = $self->{min};
	while ( $int <= $self->{max} ) {
		if ( !getpwuid($int) ) {
			return $int;
		}

		$int++;
	}

	return undef;
} ## end sub first_free

=head2 firstfree

An alias of firstfree to remain compatible with v. 0.0.1.

=cut

sub firstfree {
	return $_[0]->first_free;
}

=head2 last_free

This finds the first last UID. If it returns undef, no free ones were found.

=cut

sub last_free {
	my $self = $_[0];

	my $int = $self->{max};
	while ( $int >= $self->{min} ) {
		if ( !getpwuid($int) ) {
			return $int;
		}

		$int--;
	}

	return undef;
} ## end sub last_free

=head2 lastfree

An alias of lastfree to remain compatible with v. 0.0.1.

=cut

sub lastfree {
	return $_[0]->last_free;
}

=head1 AUTHOR

Zane C. Bowers-Hadley, C<< <vvelox at vvelox.net> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-sys-user-uidhelper at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Sys-User-UIDhelper>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Sys::User::UIDhelper


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Sys-User-UIDhelper>

=item * Search CPAN

L<https://metacpan.org/pod/Sys::User::UIDhelper>

=back


=head1 ACKNOWLEDGEMENTS


=head1 COPYRIGHT & LICENSE

Copyright 2023 Zane C. Bowers-Hadley, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

1;    # End of Sys::User::UIDhelper
