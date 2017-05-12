package MooseX::ErrorHandling;
$MooseX::ErrorHandling::VERSION = '0.2';
use strict;
use warnings;
use Module::Runtime qw(use_package_optimistically);
use Moose::Util qw(add_method_modifier);
use base 'Exporter';

our @EXPORT = qw(whenMooseThrows insteadDo);


=head1 NAME

MooseX::ErrorHandling - Monkey Patch Moose's Errors

=head1 VERSION

version 0.2

=head1 SYNOPSIS

    whenMooseThrows CanOnlyConsumeRole => insteadDo {
        My::Exception->new(
            error => $_->message
        );
    };

=head1 DESCRIPTION

This module is an attempt to monkey patch the way Moose handles errors.
Currently Moose throws a number of different exception objects for different
errors.  If you're trying to replace an existing object system with Moose,
suddenly your errors could be very different.

=head1 An Important Disclamer

This module is almost certainly a bad idea, and I'm fairly sure I'm going to
regret putting it on cpan.

=cut

sub whenMooseThrows ($$) {
    my ($type, $cb) = @_;

    # first make sure the exception class is loaded, as we're about to monkey
    # around in it.
    my $exception_class = "Moose::Exception::$type";
    use_package_optimistically($exception_class);

    add_method_modifier($exception_class, 'around', [new => sub {
        my ($orig, $class, @args) = @_;
        local $_ = $class->$orig(@args);
        return $cb->();
    }]);
}

sub insteadDo (&) {
    return shift;
}

=head1 TODO

=over 2

=item *

Figure out a sane way to do this.

=back

=head1 AUTHORS

    Chris Reinhardt
    crein@cpan.org

=head1 COPYRIGHT

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=head1 SEE ALSO

L<Moose>, perl(1)

=cut


1;
__END__
