package Dist::Zilla::App::Command::interact;
{
  $Dist::Zilla::App::Command::interact::VERSION = '0.91';
}
# ABSTRACT: Run the Module::Build::Service 'interact' command for your app

use Dist::Zilla::App -command;
use File::Temp;
use Path::Class;


sub abstract { "Run the Module::Build::Service 'interact' command for your app" }

sub execute {
    my ($self) = @_;
    $self->zilla->run_in_build ([qw{./Build interact}]);
}

1;

__END__
=pod

=head1 NAME

Dist::Zilla::App::Command::interact - Run the Module::Build::Service 'interact' command for your app

=head1 VERSION

version 0.91

=head1 SYNOPSIS

    $ dzil interact

=head1 DESCRIPTION

This is a command plugin for L<Dist::Zilla>. It provides the
C<interact> command, which leverages the capabilities of
L<Module::Build::Service> to bootstrap an environment for your
application which you can use to interact with it.

It doesn't bother to examine the results or raise exceptions, since we
assume you'll assess how things are going by hand---since you've taken
the trouble to start an interactive session at all.

=head1 AUTHOR

Michael Alan Dorman <mdorman@ironicdesign.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Ironic Design, Inc..

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

