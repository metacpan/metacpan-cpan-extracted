package Perl::Achievements::Command;
BEGIN {
  $Perl::Achievements::Command::AUTHORITY = 'cpan:YANICK';
}
{
  $Perl::Achievements::Command::VERSION = '0.4.0';
}

use strict;
use warnings;

use Moose;
use MooseX::SemiAffordanceAccessor;

use Path::Class qw/ dir file /;
use File::HomeDir;

extends qw/
    MooseX::App::Cmd::Command
    Perl::Achievements
/;

has verbose => (
    isa => 'Bool',
    is => 'ro',
);

sub BUILDARGS {
    my $self = shift;

    my %args = @_ == 1 ? %{$_[0]} : @_;

    my @args = %args;

    unshift @args, debug => 1, log_to_stdout => 1 if $args{verbose};

    $self->SUPER::BUILDARGS( @args );
}


1;


__END__
=pod

=head1 NAME

Perl::Achievements::Command

=head1 VERSION

version 0.4.0

=head1 AUTHOR

Yanick Champoux <yanick@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Yanick Champoux.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

