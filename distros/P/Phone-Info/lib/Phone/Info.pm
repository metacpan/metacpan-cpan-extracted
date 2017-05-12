package Phone::Info;

use warnings;
use strict;
use Net::WhitePages;

=head1 NAME

Phone::Info - Fetches phone info.

=head1 VERSION

Version 0.0.1

=cut

our $VERSION = '0.0.1';


=head1 SYNOPSIS

Quick summary of what the module does.

Perhaps a little code snippet.

    use Phone::Info;

    my $pi = Phone::Info->new();
    ...

=head1 METHODS

=head2 new

=head3 args hash

=head4 token

This is the API key to use. Get one at "http://www.whitepages.com/".

If this is not defined $ENV{WHITEPAGESTOKEN} is used.

=cut

sub new {
	my %args;
	if(defined($_[1])){
		%args= %{$_[1]};
	}

	my $self={error=>undef, errorString=>''};
	bless $self;

	#get the token
	if (!defined($args{token})) {
		if (!defined($ENV{WHITEPAGESTOKEN})) {
			$self->{error}=1;
			$self->{errorString}='$args{token} is not defined and $ENV{WHITEPAGESTOKEN} is also not defined';
			warn('Phone-Info new:1: '.$self->{errorString});
			return $self;
		}
		$self->{token}=$ENV{WHITEPAGESTOKEN};
	}else {
		$self->{token}=$args{token};
	}

	#create the object
	$self->{wp}=Net::WhitePages->new(TOKEN =>$self->{token});
	if (!defined($self->{wp})) {
		$self->{error}=2;
		$self->{errorString}='Failed to create the Net::WhitePages object';
		warn('Phone-Info new:2: '.$self->{errorString});
		return $self;	
	}

	return $self;
}

=head2 find_person

For a deeper understanding of values, check the URL below.

http://developer.whitepages.com/docs/Methods/find_person

=head3 args hash

=head4 firstname

The first name to search for.

=head4 lastname

The last name to search for.

=head4 name

The name to search for.

=head4 house

The house number.

=head4 street

The street name to search.

=head4 city

The city to search.

=head4 state

The 2 letter state to search.

=head4 zip

The 5 or 9 digit zip code.

=head4 areacode

The phone area code to search.

=head4 metro

A boolean value determining if the search should be expanded to the metro areas.

    my $res=$pi->find_person(\%args);
    if($pi->{error}){
        print "Error!\n";
    }

=cut

sub find_person{
	my $self=$_[0];
	my %args;
	if(defined($_[1])){
		%args= %{$_[1]};
	}

	$self->errorblank;

	my $res = $self->{wp}->find_person(
									   firstname=>$args{firstname},
									   lastname=>$args{lastname},
									   house=>$args{house},
									   street=>$args{street},
									   city=>$args{city},
									   state=>$args{state},
									   zip=>$args{zip},
									   areacode=>$args{areacode},
									   metro=>$args{metro},
									   );

	if (!defined($res)) {
		$self->{error}=3;
		$self->{errorString}='Net::WhitePages->find_person errored. $res is not defined';
		warn('Phone-Info person:3: '.$self->{errorString});
		return undef;
	}

	if (!defined($res->{result})) {
		$self->{error}=3;
		$self->{errorString}='Net::WhitePages->find_person errored. $res->{result} is not defined';
		warn('Phone-Info person:3: '.$self->{errorString});
		return undef;
	}

	if (!defined($res->{result}{type})) {
		$self->{error}=3;
		$self->{errorString}='Net::WhitePages->find_person errored. $res->{result}{type} is not defined';
		warn('Phone-Info person:3: '.$self->{errorString});
		return undef;
	}

	if ($res->{result}{type} ne 'success') {
		$self->{error}=4;
		$self->{errorString}='Look up errored. $res->{result}{type} is not defined';
		warn('Phone-Info person:4: '.$self->{errorString});
		return undef;
	}

	return $res;
}

=head2 resFormat

Create a string from the results.

=head3 args hash

=head4 res

This is the returned search data.

=head4 format

This is the format string for each item. See the format section
for more information on this.

=head4 header

The header that will be attached at the top.

If this is not defined, it is created based on the format.

For no header, set this to ''.

This should also include a new line.

=head4 quote

If this is set to true, the fields will be quoted.

This defaults to true.

=head4 quotechar

This is the character that should be used for quoting.

The default is '"'.

    my $res=$pi->person(\%args);
    if($pi->{error}){
        print "Error!\n";
    }
    $pi->resFormat({
                    res=>$res,
                    format=>$format,
                    header=>$header,
                    seperator=>',',
                    quote=>1,
                    quotechar=>'"',
                    });
    if($pi->{error}){
        print "Error!\n";
    }

=cut

sub resFormat{
	my $self=$_[0];
	my %args;
	if(defined($_[1])){
		%args= %{$_[1]};
	}

	$self->errorblank;

	if (!defined($args{res})) {
		$self->{error}=4;
		$self->{errorString}='No search results passed';
		warn('Phone-Info resFormat:4: '.$self->{errorString});
		return undef;
	}

	#the format to use for printing it out
	if (!defined($args{format})) {
		$args{format}='firstname,middlename,lastname,phone,house,street,city,state,zip';
	}

	#if headers should be printed or not
	if (!defined($args{header})) {
		$args{header}=$args{format}."\n";
		$args{header}=~s/\,/ \, /g;
	}

	#what seperates the various fields
	if (!defined($args{seperator})) {
		$args{seperator}=" , ";
	}

	#the character to use for quotes
	if (!defined($args{quotechar})) {
		$args{quotechar}='"';
	}

	#default to quoting
	if (!defined($args{quote})) {
		$args{quote}=1;
	}

	#the string that will be returned
	my $toreturn=$args{header};

	my @format=split(/,/, $args{format});

	#put it together
	my $int=0;
	while (defined( $args{res}->{listings}[$int] )) {
		my $fint=0;

		#put the line together
		while (defined( $format[$fint] )) {
			my $data;
			if ($format[$fint] eq 'firstname') {
				$data=$args{res}->{listings}[$int]{people}[0]{firstname};
			}

			if ($format[$fint] eq 'middlename') {
				$data=$args{res}->{listings}[$int]{people}[0]{middlename};
			}

			if ($format[$fint] eq 'lastname') {
				$data=$args{res}->{listings}[$int]{people}[0]{lastname};
			}

			if ($format[$fint] eq 'phone') {
				$data=$args{res}->{listings}[$int]{phonenumbers}[0]{fullphone};
			}

			if ($format[$fint] eq 'house') {
				$data=$args{res}->{listings}[$int]{address}{house};
			}

			if ($format[$fint] eq 'street') {
				$data=$args{res}->{listings}[$int]{address}{street};
			}

			if ($format[$fint] eq 'city') {
				$data=$args{res}->{listings}[$int]{address}{city};
			}

			if ($format[$fint] eq 'state') {
				$data=$args{res}->{listings}[$int]{address}{state};
			}

			if ($format[$fint] eq 'zip') {
				$data=$args{res}->{listings}[$int]{address}{zip};
			}

			if (!defined($data)) {
				$data='';
			}

			if ($args{quote}) {
				$data=$args{quotechar}.$data.$args{quotechar};
			}

			#append the data to what is to be returned
			$toreturn=$toreturn.$data;

			#if it is at the end, don't append the seperator
			if ($fint ne $#format) {
				$toreturn=$toreturn.$args{seperator};
			}

			$fint++;
		}

		#stick a new line on before starting another line
		$toreturn=$toreturn."\n";

		$int++;
	}

	return $toreturn;
}

=head2 reverse_address

This finds related phone number based on their address.

See the link below for more information.

http://developer.whitepages.com/docs/Methods/reverse_address

=head3 args hash

=head4 apt

The apt to search for.

=head4 house

The house number searched to search for. This can be
number take a range, "100-200".

=head4 city

The city to search.

=head4 state

The state to search.

=head4 zip

The sip code to search.

=head4 areacode

This is the area code to search.

    my $res=$pi->reverse_address(\%args);
    if($pi->{error}){
        print "Error!\n";
    }

=cut

sub reverse_address{
	my $self=$_[0];
	my %args;
	if(defined($_[1])){
		%args= %{$_[1]};
	}

	$self->errorblank;

	my $res = $self->{wp}->reverse_address(
										   apt=>$args{apt},
										   house=>$args{house},
										   city=>$args{city},
										   state=>$args{state},
										   zip=>$args{zip},
										   areacode=>$args{areacode},
										   street=>$args{street}
										   );

	if (!defined($res)) {
		$self->{error}=3;
		$self->{errorString}='Net::WhitePages->reverse_address errored. $res is not defined';
		warn('Phone-Info reverse_address:3: '.$self->{errorString});
		return undef;
	}

	if (!defined($res->{result})) {
		$self->{error}=3;
		$self->{errorString}='Net::WhitePages->find_address errored. $res->{result} is not defined';
		warn('Phone-Info reverse_address:3: '.$self->{errorString});
		return undef;
	}

	if (!defined($res->{result}{type})) {
		$self->{error}=3;
		$self->{errorString}='Net::WhitePages->find_address errored. $res->{result}{type} is not defined';
		warn('Phone-Info reverse_address:3: '.$self->{errorString});
		return undef;
	}

	if ($res->{result}{type} ne 'success') {
		$self->{error}=4;
		$self->{errorString}='Look up errored. $res->{result}{type} is not defined';
		warn('Phone-Info reverse_address:4: '.$self->{errorString});
		return undef;
	}

	return $res;
}

=head2 reverse_phone

This finds related addresses based on a phone number.

See the link below for more information.

http://developer.whitepages.com/docs/Methods/reverse_phone

=head3 args hash

=head4 phone

This is the phone number to look up.

    my $res=$pi->reverse_phone(\%args);
    if($pi->{error}){
        print "Error!\n";
    }

=cut

sub reverse_phone{
	my $self=$_[0];
	my %args;
	if(defined($_[1])){
		%args= %{$_[1]};
	}

	$self->errorblank;

	if (!defined($args{phone})) {
		$self->{error}=5;
		$self->{errorString}='No phone number specified. Please define $args{phone}';
		warn('Phone-Info reverse_phone:5: '.$self->{errorString});
		return undef;
	}

	my $res = $self->{wp}->reverse_phone(
										 phone=>$args{phone},
										 );
	
	if (!defined($res)) {
		$self->{error}=3;
		$self->{errorString}='Net::WhitePages->reverse_phone errored. $res is not defined';
		warn('Phone-Info reverse_phone:3: '.$self->{errorString});
		return undef;
	}

	if (!defined($res->{result})) {
		$self->{error}=3;
		$self->{errorString}='Net::WhitePages->reverse_phone errored. $res->{result} is not defined';
		warn('Phone-Info reverse_phone:3: '.$self->{errorString});
		return undef;
	}

	if (!defined($res->{result}{type})) {
		$self->{error}=3;
		$self->{errorString}='Net::WhitePages->reverse_phone errored. $res->{result}{type} is not defined';
		warn('Phone-Info reverse_phone:3: '.$self->{errorString});
		return undef;
	}

	if ($res->{result}{type} ne 'success') {
		$self->{error}=4;
		$self->{errorString}='Look up errored. $res->{result}{type} is not defined';
		warn('Phone-Info reverse_phone:4: '.$self->{errorString});
		return undef;
	}

	return $res;
}

=head2 errorblank

This blanks the error storage and is only meant for internal usage.

It does the following.

    $self->{error}=undef;
    $self->{errorString}="";

=cut

#blanks the error flags
sub errorblank{
	my $self=$_[0];

	$self->{error}=undef;
	$self->{errorString}="";

	return 1;
}

=head1 ERROR CODES

=head2 1

$args{token} is not defined and $ENV{WHITEPAGESTOKEN} is also not defined.

=head2 2

Failed to create the Net::WhitePages object.

=head2 3

find_person errored.

=head2 4

No search results passed.

=head2 5

No phone number specified.

=head1 FORMAT STRING

This is a comma seperated string comprised of various items listed below.

This string sould not include any spaces or etc.

=head2 firstname

The first name of the first person found listed for the number.

=head2 middlename

The middle name for the first person found listed for the number.

=head2 lastname

The last name for the first person found listed for the number.

=head2 phone

The phone number.

=head2 house

The house number for the address.

=head2 street

The street for the address.

=head2 city

The city the address is in.

=head2 state

The state the address is in.

=head2 zip

The zip code for the address.

=head1 AUTHOR

Zane C. Bowers, C<< <vvelox at vvelox.net> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-phone-info at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Phone-Info>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Phone::Info


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Phone-Info>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Phone-Info>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Phone-Info>

=item * Search CPAN

L<http://search.cpan.org/dist/Phone-Info/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 COPYRIGHT & LICENSE

Copyright 2009 Zane C. Bowers, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

1; # End of Phone::Info
