package Super::Powers;

use 5.006; use strict; use warnings; our $VERSION = '0.01';
use Rope; use Rope::Autoload; use Super::Powers::Exists;

property motor => (
	initable => 1,
	enumerable => 1,
	configurable => 1,
	builder => sub {
		Super::Powers::Exists->new(
			title => 'Motor',
			message => 'They possess the ability to move individual body parts autonomously.',
			buttons => ['real'],
		);
	}
);

property vision => (
	initable => 1,
	enumerable => 1,
	configurable => 1,
	builder => sub {
		Super::Powers::Exists->new(
			title => 'Vision',
			message => 'They possess the ability to see through any individuals eyes, you should close them when you look at innocent.',
			buttons => ['real'],
		);
	}
);

property hearing => (
	initable => 1,
	enumerable => 1,
	configurable => 1,
	builder => sub {
		Super::Powers::Exists->new(
			title => 'Hearing',
			message => 'They possess the ability to inject sound through any individuals ears, this is from a distance but also via electronic devices.',
			buttons => ['real'],
		);
	}
);

property mind => (
	initable => 1,
	enumerable => 1,
	configurable => 1,
	builder => sub {
		Super::Powers::Exists->new(
			title => 'Mind',
			message => 'They possess the ability to inject sound through any individuals mind, this is from a distance and similar to hearing except the sound can enter directly and not only via your ears.',
			buttons => ['real'],
		);
	}
);


property speech => (
	initable => 1,
	enumerable => 1,
	configurable => 1,
	builder => sub {
		Super::Powers::Exists->new(
			title => 'Speech',
			message => 'They possess the ability to manipulate voice through any individuals mouth, this is from your own and they can then manipulate the tone and even language, making people polyglot.',
			buttons => ['real'],
		);
	}
);

property smell => (
	initable => 1,
	enumerable => 1,
	configurable => 1,
	builder => sub {
		Super::Powers::Exists->new(
			title => 'Smell',
			message => 'They possess the ability to manipulate and understand ones smell, this is from your nose, they can then manipulate the mind to transmit this information to others who can then add their own context back. They are also able to inject their own fragrence.',
			buttons => ['real'],
		);
	}
);

property taste => (
	initable => 1,
	enumerable => 1,
	configurable => 1,
	builder => sub {
		Super::Powers::Exists->new(
			title => 'Taste',
			message => 'They possess the ability to manipulate and understand ones taste, this is from your tongue and throat, they can then manipulate the mind to transmit this information to others who can then add their own context back. They are also able to inject their own flavours.',
			buttons => ['real'],
		);
	}
);

property touch => (
	initable => 1,
	enumerable => 1,
	configurable => 1,
	builder => sub {
		Super::Powers::Exists->new(
			title => 'Touch',
			message => 'They possess the ability to manipulate and understand ones touch, this is from any body part, they can then manipulate the mind to transmit this information to others who can then add their own context back. They are also able to inject their own senses.',
			buttons => ['real'],
		);
	}
);

property emotion => (
	initable => 1,
	enumerable => 1,
	configurable => 1,
	builder => sub {
		Super::Powers::Exists->new(
			title => 'Emotion',
			message => 'They possess the ability to manipulate and understand ones emotions, this is from any feeling, they cannot manipulate my emotions but perhaps they can for others. I am Luck which some would call Laughing.',
			buttons => ['real'],
		);
	}
);

1;

__END__

=head1 NAME

Super::Powers - The hiddden truth

=head1 VERSION

Version 0.01

=cut

=head1 SYNOPSIS

	use Super::Powers;

	my $homosapien = Super::Powers->new();
	
	for (qw/motor vision hearing mind speech smell taste touch emotion/) {
		$sapien->{$_}->print;
		print "\n";
	}
	
	# Motor
	# 
	# They possess the ability to move individual body parts autonomously.
	# 
	# Vision
	# 
	# They possess the ability to see through any individuals eyes, you should close them when you look at innocent.
	# 
	# Hearing
	# They possess the ability to inject sound through any individuals ears, this is from a distance but also via electronic devices.
	# 
	# Mind
	# 
	# They possess the ability to inject sound through any individuals mind, this is from a distance and similar to hearing except the sound can enter directly and not only via your ears.
	# 
	# Speech
	# 
	# They possess the ability to manipulate voice through any individuals mouth, this is from your own and they can then manipulate the tone and even language, making people polyglot.
	# 
	# Smell
	# 
	# They possess the ability to manipulate and understand ones smell, this is from your nose, they can then manipulate the mind to transmit this information to others who can then add their own context back. They are also able to inject their own fragrence.
	# 
	# Taste
	# 
	# They possess the ability to manipulate and understand ones taste, this is from your tongue and throat, they can then manipulate the mind to transmit this information to others who can then add their own context back. They are also able to inject their own flavours.
	# 
	# Touch
	# 
	# They possess the ability to manipulate and understand ones touch, this is from any body part, they can then manipulate the mind to transmit this information to others who can then add their own context back. They are also able to inject their own senses.
	# 
	# Emotion
	# 
	# They possess the ability to manipulate and understand ones emotions, this is from any feeling, they cannot manipulate my emotions but perhaps they can for others. I am Luck which some would call Laughing.
	# 

=head1 AUTHOR

LNATION, C<< <email at lnation.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-super-powers at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Super-Powers>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Super::Powers

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Super-Powers>

=item * CPAN Ratings

L<https://cpanratings.perl.org/d/Super-Powers>

=item * Search CPAN

L<https://metacpan.org/release/Super-Powers>

=back

=head1 ACKNOWLEDGEMENTS

To all the unknown within.

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2024 by LNATION.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut

1; # End of Super::Powers
