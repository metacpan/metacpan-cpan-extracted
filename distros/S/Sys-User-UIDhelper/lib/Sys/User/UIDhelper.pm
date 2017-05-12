package Sys::User::UIDhelper;

use warnings;
use strict;

=head1 NAME

Sys::User::UIDhelper - Helps for locating free UIDs.

=head1 VERSION

Version 0.0.1

=cut

our $VERSION = '0.0.1';


=head1 SYNOPSIS

This finds a 

    use Sys::User::UIDhelper;

    #implements it with the default values
    my $foo = Sys::User::UIDhelper->new();

    #sets the min to 0 and the max to 4000
    my $foo = Sys::User::UIDhelper->new({max=>'0', min=>'4000'});

    #finds the first free one
    my $first = $foo->firstfree();
    if(defined($first)){
        print $first."\n";
    }else{
        print "not found\n";
    }

    #finds the first last one
    my $last = $foo->lastfree();
    if(defined($last)){
        print $last."\n";
    }else{
        print "not found\n";
    }


=head1 EXPORT


=head1 FUNCTIONS

=head2 new

This initiates the module. It accepts one arguement, a hash. Please See below
for accepted values.

=head3 min

The minimum UID.

=head3 max

The maximum UID.

=cut

sub new {
	my %args;
	if(defined($_[1])){
		%args= %{$_[1]};
	};

	my $self={error=>undef, set=>undef};
	bless $self;

	#set default max
	#this number is based on FreeBSD
	$self->{max}=32767;
	if (defined($args{max})) {
		$self->{max}=$args{max};
	}

	#this is choosen as on most systems 1000 is the general base for
	#new users
	$self->{min}=1000;
	if (defined($args{min})) {
		$self->{min}=$args{min};
	}

	return $self;
}

=head2 firstfree

This finds the first free UID. If it returns undef, no free ones were found.

=cut

sub firstfree {
	my $self=$_[0];
	
	my $int=$self->{min};
	while ( $int <= $self->{max}) {
		if (!getpwuid($int)) {
			return $int
		}

		$int++;
	}

	return undef;
}

=head2 lastfree

This finds the first last UID. If it returns undef, no free ones were found.

=cut

sub lastfree {
	my $self=$_[0];

	my $int=$self->{max};
	while ( $int >= $self->{min}) {
		if (!getpwuid($int)) {
			return $int
		}

		$int--;
	}

	return undef;
}

#=head2 errorBlank
#
#A internal function user for clearing an error.
#
#=cut
#
#blanks the error flags
#sub errorBlank{
#	my $self=$_[0];
#
#	#error handling
#	$self->{error}=undef;
#	$self->{errorString}="";
#
#	return 1;
#};

=head1 Todo

Implement various backends for system, LDAP, and passwd.

=head1 AUTHOR

Zane C. Bowers, C<< <vvelox at vvelox.net> >>

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

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Sys-User-UIDhelper>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Sys-User-UIDhelper>

=item * Search CPAN

L<http://search.cpan.org/dist/Sys-User-UIDhelper>

=back


=head1 ACKNOWLEDGEMENTS


=head1 COPYRIGHT & LICENSE

Copyright 2008 Zane C. Bowers, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

1; # End of Sys::User::UIDhelper
