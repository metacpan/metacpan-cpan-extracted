package MozRepl::Log;

use strict;
use warnings;

use base qw(Class::Accessor::Fast);

__PACKAGE__->mk_accessors(qw/levels/);

our %LEVELS = ();

{
    my @levels = qw/debug info warn error fatal/;

    for ( my $i = 0; $i < @levels; $i++ ) {
        my $name  = $levels[$i];
        my $level += $i;

        $LEVELS{$name} = $level;

        no strict 'refs';

        *{$name} = sub {
            my $self = shift;

            if ( $self->enable($level) ) {
                $self->log( uc($name), @_ );
            }
        };

        *{"is_$name"} = sub {
            my $self = shift;

            return ( $self->enable($level) ) ? 1 : 0;
        };
    }
}

=head1 NAME

MozRepl::Log - MozRepl logging class

=head1 VERSION

version 0.01

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

    use MozRepl;

    my $repl = MozRepl->new;
    $repl->setup;

    $repl->log->debug("Look! someone on that wall!");

=head1 METHODS

=head2 new(@levels)

Create instance.
If you want to limit log levels, then specify only levels to want to use.

    my $log = MozRepl::Log->new(qw/info error/);

=cut

sub new {
    my ($class, @levels) = @_;
    my $self  = $class->SUPER::new;

    $self->levels(
        [   @levels > 0
            ? grep { exists $LEVELS{$_} } map { lc($_) } @levels
            : keys %LEVELS
        ]
    );

    return $self;
}

=head2 enable($level)

Return whether the specified level is enabled or not.

=cut

sub enable {
    my ( $self, $level ) = @_;
    ( ( grep { $LEVELS{$_} == $level } @{ $self->levels } ) == 1 ) ? 1 : 0;
}

=head2 log($level, $messages)

Logging messege as specified level.

=cut

sub log {
    my $self = shift;
    my $level = shift;
    my @messages = map { split(/\n/, $_) } @_;

    my $message = @messages > 1 ? join("\n", "", @messages) : shift @messages;

    warn( sprintf( "[%s] %s\n", $level, $message ) );
}

=head2 debug($messeage)

Logging message as debug level.

=head2 info($messeage)

Logging message as info level.

=head2 warn($messeage)

Logging message as warn level.

=head2 error($messeage)

Logging message as error level.

=head2 fatal($messeage)

Logging message as fatl level.

=head2 is_debug()

Return whether the debug level is enabled or not.

=head2 is_info()

Return whether the info level is enabled or not.

=head2 is_warn()

Return whether the warn level is enabled or not.

=head2 is_error()

Return whether the error level is enabled or not.

=head2 is_fatal()

Return whether the fatl level is enabled or not.

=head1 AUTHOR

Toru Yamaguchi, C<< <zigorou@cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-mozrepl-log@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.  I will be notified, and then you'll automatically be
notified of progress on your bug as I make changes.

=head1 COPYRIGHT & LICENSE

Copyright 2007 Toru Yamaguchi, All Rights Reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;    # End of MozRepl::Log
