package String::Unique;

use warnings;
use strict;
use Carp;
use Data::Dumper;
use Digest::MD5 qw(md5_base64);

use constant DEBUG => 0;

=head1 NAME

String::Unique - A source of deterministic pseudorandom strings [DPS]. Objects 
of this class will generate a series of DPS of a set length for a set 2 char
'salt' [similar to UNIX crypt's salt] and resettable string that is 
assumed to be a date string [although this is not enforced].

Note that if the date string is changed, the object resets itself and begins
to generate a new series for the new date string.


=head1 VERSION

Version 1.10

=cut

our $VERSION = '1.10';

=head1 SYNOPSIS

    use String::Unique;

    my $dayrefs = String::Unique->new({characterCount => 11, salt => 'AT',});
    my $string = $dayrefs->getStringByIndex(9999);
    ...

=cut

{    # OO closure block

    my %charCount_of;
    my %salt_of;
    my %dateStructure_of;

=pod

=head1 METHODS

=head2 new

Class constructor new

Requires a hash ref containing a salt, string length and date

=cut

    sub new {
        my ( $class, $parms ) = @_;
        if (DEBUG) {
            print STDERR "String::Unique::new($class,)\n    ";
            print STDERR Dumper($parms), "\n\n";
        }
        croak('A 2 character salt is required for object of this class')
          unless ( exists( $parms->{salt} )
            && ( $parms->{salt} =~ m{ \A \w \w \z }xms ) );
        croak('A starting date is required for object of this class')
          unless ( exists( $parms->{date} ) );
        croak(
            'characterCount is a required paramater for objects of this class')
          unless ( exists( $parms->{characterCount} )
            && $parms->{characterCount} );
        $parms->{characterCount} =~ s{ [^\d] }{}xmsg;  # only the digits, please
        croak('Parameter characterCount must be numeric')
          unless ( $parms->{characterCount} );
        croak(  'Cowardly refusing to create a generator '
              . 'producing less than 6 charactor strings' )
          if ( $parms->{characterCount} < 6 );
        my $self = bless \do { my $fly_wieght }, $class;
        my $ident = $self->ident();
        $salt_of{$ident}      = $parms->{salt};
        $charCount_of{$ident} = $parms->{characterCount};

        $self->_initializeDay( $parms->{date} );
        if (DEBUG && DEBUG > 2) {
            print STDERR Dumper($self), "\n\n";
            print STDERR Dumper( \%dateStructure_of ),;
        }
        return $self;
    }

=pod

=head2 reset

Reset the day structure for date. 

=cut

    sub reset {
        my ( $self, $date ) = @_;
        if (DEBUG) {
            print STDERR "String::Unique::reset(\$self, $date, ";
            print STDERR ")\n";
        }
	
	return $self->_initializeDay($date);
    }

=pod

=head2 getStringByIndex

Return the unique string in the [index] sequence for the given date or today is date 
is not supplied. This seldom used class method is optimized for memory not speed.


=cut

    sub getStringByIndex {
        my ( $self, $index, $date ) = @_;
        if (DEBUG) {
            print STDERR "String::Unique::getStringByIndex(\$self, $index, ";
            print STDERR "$date" if defined $date;
            print STDERR ")\n";
        }
        my $ident = $self->ident();

        if ( !exists $dateStructure_of{$ident}->{$date} ) {
            $self->_initializeDay($date);
        }
        my $daystruct = $dateStructure_of{$ident}->{$date};
        if (DEBUG && DEBUG > 2) {
            print STDERR "DATE: $date\n";
            print STDERR "\%dateStructure_of:", Dumper( \%dateStructure_of ),
              "\n";
            print STDERR "daystruct:", Dumper($daystruct), "\n\n";
        }
        while ( $daystruct->{INDEX} <= $index ) {
            $self->_newUniqueString($date);
        }

        # This is a wastefull sequential search for the index value
	eval {keys %{ $daystruct->{STRINGS} }} ; # RESET the iterator!
        while ( my ( $key, $value ) = each %{ $daystruct->{STRINGS} } ) {
#	    print STDERR "\$key => $key, \$value => $value, \$index => $index\n";
            if ( $index == $value ) {
                return $key;
            }
        }
        croak "INDEX failure ", Dumper $daystruct;
        return;
    }

=pod

=head2 getIndexByString 

Return  [index] for the unique string in the sequence for the given dat. This seldom used class method is optimized for memory not speed.


=cut

    sub getIndexByString {
        my ( $self, $parms) = @_;
        if (DEBUG) {
            print STDERR "String::Unique::getIndexByString(\$self,\n";
            print STDERR Dumper($parms);
            print STDERR "\n)\n";
        }

	return unless(
		      exists $parms->{target} && $parms->{target}
		      && exists $parms->{max} && $parms->{max}
		      && exists $parms->{date} && $parms->{date}
		      );

	my $index;
	my $target = $parms->{target};
	my $maxIndex = $parms->{max};
	my $date = $parms->{date};
        my $ident = $self->ident();

        if ( !exists $dateStructure_of{$ident}->{$date} ) {
            $self->_initializeDay($date);
        }
        my $daystruct = $dateStructure_of{$ident}->{$date};
        if (DEBUG && DEBUG > 2) {
            print STDERR "DATE: $date\n";
            print STDERR "\%dateStructure_of:", Dumper( \%dateStructure_of ),
              "\n";
            print STDERR "daystruct:", Dumper($daystruct), "\n\n";
        }
	eval {keys %{$daystruct->{STRINGS}};};  #Reset the iterator
	while (my($str,$ndx) = each %{$daystruct->{STRINGS}}) {
	    if($str eq $target) {
		return $ndx;
	    }
	}
        while ( $daystruct->{INDEX} < $maxIndex) {
            if ($self->getNextString($date) eq $target) {
		return ($daystruct->{INDEX} -1);
	    };
        }

        # This is a wastefull sequential search for the index value
        if (DEBUG) {
	    carp "INDEX failure ", Dumper $daystruct;
	}
        return;
    }

=pod

=head2 getNextString 

The primary method of this class. In scalar context returns the next entry in the 
daily queue of pseudorandom strings, in list context returns the next entry and 
the  day of year as a 3 digit string ie '012' == January 13th.

=cut

    sub getNextString {
        my ( $self, $date ) = @_;
        if (DEBUG && DEBUG > 1) {
            print STDERR "String::Unique::getNextString($self, $date)\n";
        }
        my $ident = $self->ident();
        if ( !exists $dateStructure_of{$ident}->{$date} ) {
            my @keys = keys %{ $dateStructure_of{$ident} };
            for my $key (@keys) {
                delete $dateStructure_of{$ident}->{$key};
            }
            $self->_initializeDay($date);
        }
        return $self->_newUniqueString($date);
    }

=pod

=head2 _initializeDay

Private class method; sets up the queue for date $datestring

=cut

    sub _initializeDay {
        my ( $self, $datestring ) = @_;
        if (DEBUG) {
            print STDERR "String::Unique::_initializeDay(\$self,$datestring)\n";
        }
        my $ident = $self->ident();
	for my $ds (keys %{$dateStructure_of{$ident}}) {
	    delete $dateStructure_of{$ident}->{$ds};
	}

# Every date format string supplied generates a date structure
# which is a hash ref.
# The fields of this hash are as follows:
# SEED    => the actual date string supplied, as formatted.
# OFFSET  => the number of times we have called md5_base64 
#            for this sequence
# INDEX   => the number of the current string in the sequence
# STRINGS => a hash of the strings generated to the resepctive INDEX

        $dateStructure_of{$ident}->{$datestring} = {
            SEED    => $datestring,
            OFFSET  => 0,
            INDEX   => 0,
            STRINGS => {},
        };
    }

=pod

=head2 _newUniqueString

Private class method; returns the next unique string in date: $datstring-s Queue

=cut

    sub _newUniqueString {
        my ( $self, $datestring ) = @_;
        if (DEBUG && DEBUG > 1) {
            print STDERR "String::Unique::_newUniqueString(\$self,$datestring)\n";
        }
        my $ident = $self->ident();
        croak "Request for string from non-initialized date"
          unless ( exists $dateStructure_of{$ident}->{$datestring} );
        my $daystruct = $dateStructure_of{$ident}->{$datestring};
        my $canidate  = $self->_randCharString($datestring);

# This while loop is what makes entries in this series 'Unique'.
        while ( exists $daystruct->{STRINGS}->{$canidate} ) {
            $canidate = $self->_randCharString($datestring);
        }
        $daystruct->{STRINGS}->{$canidate} = $daystruct->{INDEX};
        $daystruct->{INDEX}++;
        return $canidate;
    }

=pod

=head2 _randCharString

Private class method; returns a candidate string

=cut

    sub _randCharString {
        my ( $self, $datestring ) = @_;
        if (DEBUG && DEBUG > 1) {
            print STDERR "String::Unique::_randCharString(\$self,$datestring)\n";
        }
        my $ident = $self->ident();
        croak "Request for string from non-initialized date"
          unless ( exists $dateStructure_of{$ident}->{$datestring} );
        my $daystruct = $dateStructure_of{$ident}->{$datestring};
        my $rv = q{};    # Empty string to start
        while ( length $rv < $charCount_of{$ident} ) {
            $rv .=
              md5_base64( $salt_of{$ident}
                  . sprintf( "%07d", $daystruct->{OFFSET}++ )
                  . $daystruct->{SEED} );
            $rv =~ s{ [a-z+\/] }{}xmsg;
        }
#	print STDERR  "\n\$charCount_of{\$ident} => $charCount_of{$ident}\n";
        $rv = substr( $rv, 0, $charCount_of{$ident} );
        if (DEBUG && DEBUG > 1) {
            print STDERR "   _randCharString returns $rv\n";
        }
        return $rv;
    }

=pod

=head2 ident
Class method ident returns a string that uniquely identifies the object supplied

=cut

    sub ident {
        my ($self) = @_;
        if (DEBUG && DEBUG > 2) {
            print STDERR "String::Unique::ident(\$self)\n";
            print STDERR "$self\n";
        }
        return unless defined $self;
        my $ident = "$self";

        if (
            $ident =~ s{ \A [\w\=\:]+ \( 0x ([0-9a-f]+) \) .* \z}
                       {$1}xms
          )
        {
            return $ident;
        }
        return;
    }

sub dump {
        my ($self) = @_;
        my $ident = $self->ident();
	my $rv = {
	    charCount_of  =>  $charCount_of{$ident},
	    salt_of =>  $salt_of{$ident},
	    dateStructure_of => $dateStructure_of{$ident},
	};
        return $rv;
    }



    sub DESTROY {
        my ($self) = @_;
        my $ident = $self->ident();
        delete $charCount_of{$ident};
        delete $salt_of{$ident};
        delete $dateStructure_of{$ident};
        return 1;
    }


}

=head1 AUTHOR

 Christian Werner Sr, << <saltbreez@cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-string-unique at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=String-Unique>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc String::Unique


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=String-Unique>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/String-Unique>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/String-Unique>

=item * Search CPAN

L<http://search.cpan.org/dist/String-Unique/>

=back

=head1 ACKNOWLEDGEMENTS

This module was adopted from the module Unique by the same author,
developed for Wells Fargo, see license and copyright

=head1 COPYRIGHT & LICENSE

Copyright 2007,2008 Wells Fargo, all rights reserved.
Copyright 2011 Christian Werner Sr.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;    # End of String::Unique
