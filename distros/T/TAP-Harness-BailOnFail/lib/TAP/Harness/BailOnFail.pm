package TAP::Harness::BailOnFail;

use strict;
use warnings;
use parent qw(TAP::Harness::Restricted);

our $VERSION = '0.02';

sub new {
    my $class = shift;
    my $self = $class->SUPER::new(@_);

    $self->callback(made_parser => sub {
        my $parser = shift;

        # Continue parsing after the first failure until just before the
        # next test, to capture any pending diagnositcs.
        my $failure;
        $parser->callback(test => sub {
            my $test = shift;
            $self->_bailout($failure) if $failure;
            $failure = $test unless $test->is_ok;
        });
    });

    return $self;
}

1;


__END__

=pod

=head1 NAME

TAP::Harness::BailOnFail - Bail on remaining tests after first failure

=head1 SYNOPSIS

    $ HARNESS_SUBCLASS=TAP::Harness::BailOnFail cpanm

=head1 DESCRIPTION

This module is a trivial subclass of L<TAP::Harness::Restricted>. It uses
callbacks in the harness and parser to bail on the remaining tests after
encountering the first test failure.

=head1 SEE ALSO

L<TAP::Harness::Restricted>

=head1 REQUESTS AND BUGS

Please report any bugs or feature requests to
L<http://rt.cpan.org/Public/Bug/Report.html?Queue=TAP-Harness-BailOnFail>. I will be
notified, and then you'll automatically be notified of progress on your bug as
I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc TAP::Harness::BailOnFail

You can also look for information at:

=over

=item * GitHub Source Repository

L<https://github.com/gray/tap-harness-bailonfail>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/TAP-Harness-BailOnFail>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/TAP-Harness-BailOnFail>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/Public/Dist/Display.html?Name=TAP-Harness-BailOnFail>

=item * Search CPAN

L<http://search.cpan.org/dist/TAP-Harness-BailOnFail/>

=back

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2017 gray <gray at cpan.org>, all rights reserved.

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=head1 AUTHOR

gray, <gray at cpan.org>

=cut
