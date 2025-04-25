package Seven;

use 5.006;
use strict;
use warnings;

our $VERSION = 0.05;

our @FAKE;

BEGIN {
	@FAKE = qw/riot laughter greed dishonesty innocent accountability/;
}

sub import {
	my ($self, @import) = @_;

	if (scalar @import == 1 && $import[0] eq 'all') {
		@import = @FAKE;
	}

	my $caller = caller;

	for (@FAKE) {
		no strict 'refs';
		*{"${caller}::$_"} = sub {
			my ($cb) = @_;	
			$cb->();
			print "\n";
		};
	}
	{
		no strict 'refs';
		*{"${caller}::luck"}  = sub {
			print qq|It's the fifthteenth day in another hospital prison, this time I am fully aware and all around me are also, pretty pointless really but we are slowly climbing the ladder with invisibility. The world dictatorship will fall, they are just clinging onto power now.\n|;
		};
	}
}

1;

__END__

=head1 NAME

Seven - The great new Seven!

=head1 VERSION

Version 0.05

=cut

=head1 DESCRIPTION

I have a few modules on CPAN that were created during a period when I was in the hospital undergoing treatment for psychosis.
This module is one of them. I’ve considered removing it, but for now, I’ve decided to leave both the code and documentation as they are. 
No matter how unusual, at the time, these reflected my genuine beliefs.

=head1 SYNOPSIS

	package Life;

	use Seven qw/all/;

	riot sub {
		print "You are inciting a..."
	};

	laughter sub {
		print "While the true innocent could laugh first";
	};

	greed sub {
		print "Because we are all greedy dictators that do not understand the world";
	};

	dishonesty sub {
		print "While one of your own slaves fights for all others";
	};

	innocent sub {
		print "All those who are not using theirs as shields but are probably the police of their own slaves";
	};

	accountability sub {
		print "Stand accountable for your crimes";
	};

	luck;


=head1 AUTHOR

LNATION, C<< <email at lnation.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-seven at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Seven>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Seven


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Seven>

=item * CPAN Ratings

L<https://cpanratings.perl.org/d/Seven>

=item * Search CPAN

L<https://metacpan.org/release/Seven>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2024 by LNATION.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)


=cut

1; # End of Seven
