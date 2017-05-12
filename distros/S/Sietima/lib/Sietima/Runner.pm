package Sietima::Runner;
use Moo;
use Sietima::Policy;
use namespace::clean;

our $VERSION = '1.0.1'; # VERSION
# ABSTRACT: C<App::Spec::Run> for Sietima


extends 'App::Spec::Run';

sub run_op($self,$op,$args=[]) {
    if ($op =~ /^cmd_/) {
        $self->$op($args);
    }
    else {
        $self->cmd->$op($self,$args);
    }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Sietima::Runner - C<App::Spec::Run> for Sietima

=head1 VERSION

version 1.0.1

=head1 DESCRIPTION

You should never need to care about this class, it's used internally
by L<< C<Sietima::CmdLine> >>.

This is a subclass of L<< C<App::Spec::Run> >> that uses directly
itself to execute the built-in commands, instead of delegating to the
C<cmd> object (in our case, a C<Sietima> instance) which would
delegate back via L<< C<App::Spec::Run::Cmd> >>.

=for Pod::Coverage run_op

=head1 AUTHOR

Gianni Ceccarelli <dakkar@thenautilus.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Gianni Ceccarelli <dakkar@thenautilus.net>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
