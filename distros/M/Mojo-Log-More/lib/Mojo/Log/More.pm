package Mojo::Log::More;

use Mojo::Base 'Mojo::Log';
use Time::Piece;
use File::Spec;

our $VERSION = '1.02';

# Increment this if you are using a wrapper
our $caller_depth = 0;

has format => sub { \&_format };

sub debug { shift->emit('message', 'debug', @_, [caller($caller_depth)]) }
sub info  { shift->emit('message', 'info',  @_, [caller($caller_depth)]) }
sub warn  { shift->emit('message', 'warn',  @_, [caller($caller_depth)]) }
sub error { shift->emit('message', 'error', @_, [caller($caller_depth)]) }
sub fatal { shift->emit('message', 'fatal', @_, [caller($caller_depth)]) }

sub _format {
  my $caller = pop;
  my $filename = (File::Spec->splitpath($caller->[1]))[2];

  sprintf "%s %s:%i %s> %s", localtime(shift)->datetime, $filename,
    $caller->[2], uc(shift), join("\n", @_, '');
}

1;

__END__

=encoding utf8

=head1 NAME

Mojo::Log::More - Mojo::Log with More details

=head1 SYNOPSIS

  use Mojo::Log::More;

  # Constructor is identical to Mojo::Log
  my $log = Mojo::Log::More->new;

  # Replace the default log in a Mojolicious::Lite application
  app->log($log);

  # Output: 2015-02-20T23:30:53 filename.pl:13 INFO> something happened...
  app->log->info("something happened...");

  # Create a wrapper function
  sub debug {
    local Mojo::Log::More::caller_depth += 1;
    $log->debug(@_);
  }

=head1 DESCRIPTION

This module is a small wrapper around L<Mojo::Log> which allows you to log
C<caller()> information with your log messages automatically. You do not need
to use big logging systems like L<Log::Dispatch> or L<Log::Log4perl>
to get this feature anymore.

=head2 C<format> arguments

The C<format> method receives the same arguments as in L<Mojo::Log>, but with
one more argument at the end: an arrayref containing the result of C<caller()>.
You must C<pop> it before accessing the log messages.

This modules includes its own C<format> method wich uses the C<caller>
arguments, in particular the source filename and line number. It also
prints the date in a more compact format (ISO 8601).

=head1 BUGS

Please report any bugs or feature requests at L<https://github.com/oliwer/mojo-log-more/issues>

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Mojo::Log::More


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (please use Github instead)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Mojo-Log-More>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Mojo-Log-More>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Mojo-Log-More>

=item * Search CPAN

L<http://search.cpan.org/dist/Mojo-Log-More/>

=back

=head1 AUTHOR

Olivier Duclos, C<< <odc at cpan.org> >>

=head1 LICENSE

Copyright 2015 Olivier Duclos.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<Mojolicious>

=cut
