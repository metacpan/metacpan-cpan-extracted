package Monitoring::Spooler::Transport;
$Monitoring::Spooler::Transport::VERSION = '0.05';
BEGIN {
  $Monitoring::Spooler::Transport::AUTHORITY = 'cpan:TEX';
}
# ABSTRACT: baseclass for any transport plugin

use 5.010_000;
use mro 'c3';
use feature ':5.10';

use Moose;
use namespace::autoclean;

# use IO::Handle;
# use autodie;
# use MooseX::Params::Validate;
# use Carp;
# use English qw( -no_match_vars );
# use Try::Tiny;

# extends ...
# has ...
# with ...
with 'Log::Tree::RequiredLogger';
# initializers ...

# your code here ...
sub provides {
    # we don't provide any type
    return;
}

sub run {
    return;
}

sub _clean_number {
    my $self = shift;
    my $number = shift;

    # strip all non-number chars
    $number =~ s/\D//g;

    # TODO i18n/l10n
    # make sure to use the country prefix for germany
    $number =~ s/^01/491/;
    # never prefix country with 00
    $number =~ s/^00491/491/;

    return $number;
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Monitoring::Spooler::Transport - baseclass for any transport plugin

=head1 SYNOPSIS

    package Monitoring::Spooler::Transport::Subclass;
    use Moose;
    extends 'Monitoring::Spooler::Transport';
    ...

=head1 DESCRIPTION

This is the base class for all transport plugins.

=head1 METHODS

=head2 provides

Given a media type (text, phone or smth. else) this must return a true value
if this plugin supports this type.

=head2 run

If this plugin is chosen to be run, this sub is invoked with two arguments:
the destination number and
some payload (i.e. the message for Text plugins)

=head1 NAME

Monitoring::Spooler::Transport - Transport Plugin baseclass

=head1 ADDING NEW TRANSPORTS

Transports must subclass this class (or use dirty perl magic)
to pass the type constraints defined in the command classes
(they check for isa(Monitoring::Spooler::Transpport)).

Implementors must override provides and run subs.

At the moment there are two types of media being handled by the transports
with the possibility of adding more. These are text and phone.

The method run will always receive the destination number and optionally an message.

Text plugins MAY decline and return false without a message being passed while
phone plugins SHOULD NOT return false without a message and fall back to using
some default value.

The escalation handling is done withing Monitoring::Spooler::Cmd::SendingCommand and it's
subclasses. Don't care about that inside the transport. Just deliver the message
passed and return true on success or false on error.

Transport plugins may die or raise an exception on error. Those are caught and logged.

Please see the perldoc of Monitoring::Spooler::Cmd::SendingCommand for an explaination
of the control flow and escalation handling.

=head1 AUTHOR

Dominik Schulz <tex@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Dominik Schulz.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
