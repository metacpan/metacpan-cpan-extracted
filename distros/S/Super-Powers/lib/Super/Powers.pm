package Super::Powers;

use 5.006; use strict; use warnings; our $VERSION = '0.02';
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
			message => "They have the capability to perceive through another's eyes; you ought to shut them when you gaze upon the innocent.",
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
			message => "They have the power to transmit sound through anyone's ears, remotely and also through electronic devices.",
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
			message => "TThey have the capability to implant sound directly into any individual's mind, remotely and bypassing the ears, akin to hearing but with the sound entering directly",
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
			message => "They have the power to control voices through any person's mouth, enabling them to manipulate tone and language, thereby making individuals polyglots.",
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
			message => "They can manipulate and comprehend one's sense of smell, originating from the nose. They can then manipulate the mind to transmit this information to others, who can then interpret it with their own context. Additionally, they have the ability to introduce their own fragrance into the mix.",
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
			message => "They have the power to manipulate and comprehend one's sense of taste, originating from the tongue and throat. They can then manipulate the mind to transmit this information to others, who can then interpret it with their own context. Moreover, they can introduce their own flavors into the experience.",
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
			message => "They possess the capacity to manipulate and comprehend one's sense of touch, originating from any part of the body. They can then manipulate the mind to transmit this information to others, who can then interpret it with their own context. Furthermore, they can introduce their own sensations into the experience.",
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

Version 0.02

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
	# They have the capability to perceive through another's eyes; you ought to shut them when you gaze upon the innocent.
	# Hearing
	# 
	# They have the power to transmit sound through anyone's ears, remotely and also through electronic devices.
	# 
	# Mind
	# 
	# TThey have the capability to implant sound directly into any individual's mind, remotely and bypassing the ears, akin to hearing but with the sound entering directly
	# 
	# Speech
	# 
	# They have the power to control voices through any person's mouth, enabling them to manipulate tone and language, thereby making individuals polyglots.
	# 
	# Smell
	# 
	# They can manipulate and comprehend one's sense of smell, originating from the nose. They can then manipulate the mind to transmit this information to others, who can then interpret it with their own context. Additionally, they have the ability to introduce their own fragrance into the mix.
	# 
	# Taste
	# 
	# They have the power to manipulate and comprehend one's sense of taste, originating from the tongue and throat. They can then manipulate the mind to transmit this information to others, who can then interpret it with their own context. Moreover, they can introduce their own flavors into the experience.
	# 
	# Touch
	# 
	# They possess the capacity to manipulate and comprehend one's sense of touch, originating from any part of the body. They can then manipulate the mind to transmit this information to others, who can then interpret it with their own context. Furthermore, they can introduce their own sensations into the experience.
	# 
	# Emotion
	# 
	# They possess the ability to manipulate and understand ones emotions, this is from any feeling, they cannot manipulate my emotions but perhaps they can for others. I am Luck which some would call Laughing.

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
