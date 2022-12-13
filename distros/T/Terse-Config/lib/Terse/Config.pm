package Terse::Config;

use 5.006;
use strict;
use warnings;
our $VERSION = '0.01';

1;

__END__

=head1 NAME

Terse::Config - Terse configs

=head1 VERSION

Version 0.01

=cut

=head1 SYNOPSIS

	package MyApp::Plugin::Config;

	use base 'Terse::Plugin::Config::YAML';

	1;

	$terse->plugin('config')->find('path/to/key');
	$terse->plugin('config')->data->path->to->key;

=head1 AUTHOR

LNATION, C<< <email at lnation.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-terse-config at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Terse-Config>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Terse::Config


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Terse-Config>

=item * CPAN Ratings

L<https://cpanratings.perl.org/d/Terse-Config>

=item * Search CPAN

L<https://metacpan.org/release/Terse-Config>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2022 by LNATION.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)


=cut

1; # End of Terse::Config
