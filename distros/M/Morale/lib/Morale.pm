#
# Morale.pm
#
# A Perl module for dealing with morale files and calculating
# company morale.
#
# TODO: Change the calculation of company morale to a timed
# event, instead of doing it real-time, since it could take
# a while for large user sets and/or remote home directories.
#
# TODO: Or, at least cache the current results for N seconds,
# not going back to the source until that expires.
#
# Copyright (C) 1999-2001 Gregor N. Purdy. All rights reserved.
#

package Morale;

use strict;

BEGIN {
	use Exporter ();
	use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);

	$VERSION     = 0.002;
	@ISA         = qw(Exporter);
	@EXPORT      = qw(&get_morale &set_morale &calc_morale);
	%EXPORT_TAGS = ( );
	@EXPORT_OK   = qw(&morale_file);
}
use vars qw($top $my_scale $co_scale $bar $my_morale $co_morale);
use Carp;


my %morales;


#
# morale_file()
#

sub morale_file
{
	my ($user) = @_;
	my $dir;
	my @check;

	if (!defined($user)) { $user = (getpwuid($>))[0]; }

	$dir = (getpwnam($user))[7];
	
	push @check, "/var/morale/$user";
	push @check, "$dir/.morale";

	foreach (@check) { if (-r $_) { return $_; } }

	return "$dir/.morale";
}


#
# validate_morale()
#

sub validate_morale
{
	my ($morale) = @_;

	if (defined($morale)) {
		$morale =~ s/^\s*(.*)\s*$/$1/;

		if    (!($morale =~ m/^[0-9]+$/))        { undef $morale; }
		elsif (($morale < 0) or ($morale > 100)) { undef $morale; }
	}

	return $morale;
}


#
# set_morale()
#

sub set_morale
{
	my ($morale, $user) = @_;
	my $file = morale_file($user);

	$morale = validate_morale($morale);

	if (!defined($morale)) {
		system "rm -f $file";
		return;
	}

	if (!open(MORALE, ">$file")) {
		carp "Couldn't open file `$file' for writing.";
		return;
	}

	print MORALE "$morale\n";
	close MORALE;
}


#
# get_morale()
#
# Returns the morale for the given user, or the current user if none given.
#

sub get_morale
{
	my ($user) = @_;

	my $file = morale_file($user);
	my $morale;

	open MORALE, "<$file"
		or return undef;
	$morale = <MORALE>;
	close MORALE;

	chomp $morale;	

	return validate_morale($morale);
}


#
# get_all_morales()
#
# Returns the intializer for a hash of user-morale associations.
#

sub get_all_morales
{
	my $user;
	my @users;

	%morales = ( );

	setpwent();
	while ($user = getpwent) { push @users, $user; }
	endpwent();
	
	foreach $user (@users) {
#		print STDERR "$user: ";
		my $user_morale = get_morale($user);

		if (defined($user_morale)) {
#			print STDERR "$user_morale\n";
			$morales{$user} = $user_morale;
		} else {
#			print STDERR "<undef>\n";
		}
	}

	return %morales;
}


#
# calc_morale()
#

sub calc_morale
{
	my $total_morale = 0;
	my $count_morale = 0;

	get_all_morales();

	foreach (sort keys %morales) {
#		print STDERR "$_: $morales{$_}\n";
		$total_morale += $morales{$_};
		$count_morale ++;
	}

	if ($count_morale < 1) { return undef; }
	else                   { return $total_morale / $count_morale; }
}


#
# Return a true value:
#

1;


#
# End of file.
#

=pod


=head1 NAME

Morale - Perl module for managing individual and calculating group morale.


=head1 SYNOPSIS

    use Morale;
    set_morale($morale, $user); # Named user
    set_morale($morale);        # Current user
    get_morale($user);          # Named user
    get_morale();               # Current user
    calc_morale();
	morale_file($user);         # Named user
	morale_file();              # Current user


=head1 DESCRIPTION

This module exists in its current form primarily to support the tkmorale
program. See that program for example usage.


=head1 HISTORICAL NOTE

This section contributed by E. Denning ``Denny'' Dahl.

1999-06-24

I'll never forget my interview at Thinking Machines. It took place 
December of 1987, and I remember the trek from the Royal Sonesta 
through the construction zone that was the east end of Cambridge, 
in the snow and mud past the Athenaeum Building to the Carter Ink 
building which housed TMC. Not that we were ever supposed to 
abbreviate Thinking Machines Corporation to TMC, but I digress.

The salient point about the interview is that I'd never come across 
such a bright, enthusiastic and motivated bunch of people before. 
I had worked in high energy physics and then neural networks, and 
had come across plenty of people who were off the charts in terms 
of intelligence. But these people at TMC were also having fun! 
Folks had toys in their offices, they had hot-wired matrix boards, 
they were doing object technology, they knew what Ramsey theory 
was, and they had the coolest looking box on the block.

After I joined, I was one of the people who had to answer the 
question "What are all the blinking lights for?". Every time 
we heard the question, we would give a different answer. Sometimes 
it was a diagnostics hack, sometimes a performance feedback device, 
sometimes purely a marketing ploy. But the blinking red lights on 
the sides on the CM-2 captured the spirit of the place. It was like 
a Christmas tree!

We even have a picture of my two-year old daughter in an angelic 
little dress reaching out to touch the side of the big black cube. 
Almost a comic riff on Kubrick's ape and monolith image. But the 
point you can see I'm trying to make is that I and practically 
everyone else who worked at Thinking Machines had a deep love for 
what we were doing there. We were trying to invent a new paradigm 
for computation. That meant new hardware, new operating systems, 
new languages, new everything. What could be more fun?

This build-up made the let-down that much more painful. When I 
joined, the company had around 150 people. It grew to more than 
500 before the structural problems really became evident. And 
evident is a relative term. I am sure that everyone who worked 
there had a different impression of the beginning of the end, and 
we all had different threshholds for holding on to our shared 
belief that we could change the world. But the cracks started, 
and began to widen, and eventually became too big to ignore.

So morale started going south. I was concerned, and of course 
always up for learning a little new technology and doing some 
inspired hacking, so I decide that Tcl & Tk would be a good 
vehicle for my latest greatest idea: Xmorale.

The notion was to build a wicked simple GUI that had a single 
slider to allow the user to input his or her morale, along with 
a submit button, and a second slider to show the company average 
morale. After I got conversant with Tcl & Tk (not too long) I 
hacked together Xmorale. Perhaps I could find the source code 
if I did enough detective work, but the essential spirit of the 
code was quite simple.

I used a .morale file in everyone's home directory to store each 
individual's contribution to the global company morale. Each 
.morale file contained a randomly generated but unique key, and 
the global company morale table just contained entries that mapped 
key values to morale values. The security was not ultra-tight. 
Each person's .morale file was permission 600, but of course 
anyone with root privileges could figure out what your personal 
morale was.

At any rate, the idea took off like wildfire. Within a few days 
of release, a significant fraction of TMC'ers had submitted their 
morales. Other hackers took up the idea and developed tools to 
record the company morale automatically and produce time series 
graphs. There were refinements and discussions and FAQ's and it 
was a great time.

Of course, the most gratifying aspect of Xmorale is that it made 
the company management very uncomfortable. There is nothing like 
having a staff meeting, and seeing the global company morale drop 
precipitously in the hour following the staff meeting to let you 
know how you are doing. So needless to say, there was vague pressure 
to discontinue the service. But once an idea like this is born, 
you cannot suppress it. This was social engineering at its finest.

I wish I could say that Xmorale had a real impact on what happened 
to TMC. Who knows? Maybe things would have been slightly different 
without it. But after entering Chapter 11, TMC finally emerged a 
far different and smaller beast. Recently it has been sold to 
Oracle. And I rather doubt Larry E. would take kindly to the notion 
of a database storing a time history of Xmorale, hour by hour, at 
Oracle. But you never know...

Here I thought this amusing hack would rest, until I had lunch one day 
with one Gregor Purdy, erstwhile consultant and man about town. I told 
him about Xmorale, and within 24 hours he had implemented a version 
completely from scratch using late 1990's technology, by which I mean 
Perl. Since I view this hack to be a truly subversive piece of 
software, I can only say that I hope it spreads as far and wide as possible. 
Deploy this at your own place of work, and then stand back to admire 
the consequences!


=head1 AUTHOR

Gregor N. Purdy E<lt>gregor@focusresearch.comE<gt>


=head1 COPYRIGHT

Copyright (C) 1999-2001 Gregor N. Purdy. All rights reserved.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.


=cut

#
# End of file.
#

