package Stancer::Core::Iterator::Dispute;

use 5.020;
use strict;
use warnings;

# ABSTRACT: Iterate through disputes
our $VERSION = '1.0.3'; # VERSION

use Stancer::Dispute;

use Moo;

extends 'Stancer::Core::Iterator';

use namespace::clean;


sub _create_element {
    my ($class, @args) = @_;

    return Stancer::Dispute->new(@args);
}

sub _element_key {
    return 'disputes';
}


sub search {
    my ($class, @args) = @_;
    my $data;
    my $params = {};

    if (scalar @args == 1) {
        $data = $args[0];
    } else {
        $data = {@args};
    }

    $params->{created} = $class->_search_filter_created($data) if defined $data->{created};
    $params->{created_until} = $class->_search_filter_created_until($data) if defined $data->{created_until};
    $params->{limit} = $class->_search_filter_limit($data) if defined $data->{limit};
    $params->{start} = $class->_search_filter_start($data) if defined $data->{start};

    return $class->SUPER::search($params);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Stancer::Core::Iterator::Dispute - Iterate through disputes

=head1 VERSION

version 1.0.3

=head1 DESCRIPTION

You should not use this class directly.

This module is an internal class, regrouping method for every API object list.

=head1 METHODS

=head2 C<< Stancer::Core::Iterator::Dispute->new(I<$sub>) : I<self> >>

Create a new iterator.

A subroutine, C<$sub> is mandatory, it will be used on every iteration.

=head2 C<< $iterator->next() : I<Dispute>|I<undef> >>

Return the next dispute object or C<undef> if no more element to iterate.

=head2 C<< Stancer::Core::Iterator::Dispute->search(I<%terms>) : I<self> >>

=head2 C<< Stancer::Core::Iterator::Dispute->search(I<\%terms>) : I<self> >>

You may use L<Stancer::Dispute/list> instead.

=head1 USAGE

=head2 Logging



We use the L<Log::Any> framework for logging events.
You may tell where it should log using any available L<Log::Any::Adapter> module.

For example, to log everything to a file you just have to add a line to your script, like this:
    #! /usr/bin/env perl
    use Log::Any::Adapter (File => '/var/log/payment.log');
    use Stancer::Core::Iterator::Dispute;

You must import C<Log::Any::Adapter> before our libraries, to initialize the logger instance before use.

You can choose your log level on import directly:
    use Log::Any::Adapter (File => '/var/log/payment.log', log_level => 'info');

Read the L<Log::Any> documentation to know what other options you have.

=cut

=head1 SECURITY

=over

=item *

Never, never, NEVER register a card or a bank account number in your database.

=item *

Always uses HTTPS in card/SEPA in communication.

=item *

Our API will never give you a complete card/SEPA number, only the last four digits.
If you need to keep track, use these last four digit.

=back

=cut

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<https://gitlab.com/wearestancer/library/lib-perl/-/issues> or by email to
L<bug-stancer@rt.cpan.org|mailto:bug-stancer@rt.cpan.org>.

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

Joel Da Silva <jdasilva@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018-2024 by Stancer / Iliad78.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
