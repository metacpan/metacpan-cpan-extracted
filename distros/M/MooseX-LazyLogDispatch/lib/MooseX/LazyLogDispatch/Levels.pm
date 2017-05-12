package MooseX::LazyLogDispatch::Levels;

use strict;

our $VERSION = '0.02';

use Moose::Role;

with 'MooseX::LazyLogDispatch';

sub log { shift->logger->log(@_) }
sub debug { shift->logger->debug(@_) }
sub info { shift->logger->info(@_) }
sub notice { shift->logger->notice(@_) }
sub warning { shift->logger->warning(@_) }
sub error { shift->logger->error(@_) }
sub critical { shift->logger->critical(@_) }
sub alert { shift->logger->alert(@_) }
sub emergency { shift->logger->emergency(@_) }

no Moose::Role; 1;
__END__

=head1 NAME

MooseX::LazyLogDispatch::Levels - Like MX::LazyLogDispatch, but with level-methods

=head1 SYNOPSIS

    package Foo;
    use Moose;
    with 'MooseX::LazyLogDispatch::Levels'

    # ... See MooseX::LazyLogDispatch synposis
    #  for configuration

    # But now you have direct level methods:
    sub foo { 
        my ($self) = @_;
        $self->debug('started foo');
        # ^ is identical to v
        $self->logger->debug("started foo");
    }
  
=head1 DESCRIPTION

See L<MooseX::LazyLogDispatch> for the main docs.

This just adds level methods for the C<$self->logger> levels directly
to your class, in addition to bringing in that role.

=head1 LEVEL METHOD NAMES

=head2 log

=head2 debug

=head2 info

=head2 notice

=head2 warning

=head2 error

=head2 critical

=head2 alert

=head2 emergency

=head1 SEE ALSO

L<MooseX::LazyLogDispatch>
L<MooseX::LogDispatch>
L<Log::Dispatch::Configurator>
L<Log::Dispatch::Config>
L<Log::Dispatch>

=head1 AUTHOR

Brandon Black C<< <blblack@gmail.com> >>

Based in part on L<MooseX::LogDispatch> by Ash Berlin C<< <ash@cpan.org> >> and C<< <perigrin@cpan.org> >>

=head1 LICENCE

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

