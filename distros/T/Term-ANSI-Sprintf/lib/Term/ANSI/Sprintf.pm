package Term::ANSI::Sprintf;

use 5.006;
use strict;
use warnings;

our $VERSION = '0.04';

use base 'Import::Export';

our %EX = (
	sprintf => [qw/all/]
);

require XSLoader;
XSLoader::load("Term::ANSI::Sprintf", $VERSION);

sub _sprintf {
	my ($self, $str, @params) = @_;
	return CORE::sprintf($str, @params);
}

1;

__END__

=head1 NAME

Term::ANSI::Sprintf - sprintf with ANSI colors

=head1 VERSION

Version 0.04

=head1 SYNOPSIS

	use Term::ANSI::Sprintf qw/sprintf/;

	print sprintf("%italic%blue %underline%red", "Hello", "World"),


=head1 EXPORT

=head2 sprintf

	%bold
	%italic
	%underline

        %black
        %red
        %green
        %yellow
        %blue
        %magento
        %cyan
        %white

        %bright_black
        %bright_red
        %bright_green
        %bright_yellow
        %bright_blue
        %bright_magento
        %bright_cyan
        %bright_white

        %black_on_red
        %black_on_green
        %black_on_yellow
        %black_on_blue
        %black_on_magento
        %black_on_cyan
        %black_on_white
        %black_on_bright_red
        %black_on_bright_green
        %black_on_bright_yellow
        %black_on_bright_blue
        %black_on_bright_magento
        %black_on_bright_cyan
        %black_on_bright_white

	%red_on_black
	...

	sprintf("%blue_on_bright_yellow %black_on_bright_red", "Hello", "World");

=head1 AUTHOR

LNATION, C<< <email at lnation.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-term-ansi-sprintf at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Term-ANSI-Sprintf>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Term::ANSI::Sprintf

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Term-ANSI-Sprintf>

=item * CPAN Ratings

L<https://cpanratings.perl.org/d/Term-ANSI-Sprintf>

=item * Search CPAN

L<https://metacpan.org/release/Term-ANSI-Sprintf>

=back

=head1 ACKNOWLEDGEMENTS

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2024 by LNATION.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut

1; # End of Term::ANSI::Sprintf
