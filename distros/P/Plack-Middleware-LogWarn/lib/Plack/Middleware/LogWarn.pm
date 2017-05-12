package Plack::Middleware::LogWarn;
BEGIN {
  $Plack::Middleware::LogWarn::VERSION = '0.001002';
}

# ABSTRACT: converts to warns to log messages

use strict;
use warnings;
use parent qw( Plack::Middleware );
use Plack::Util::Accessor qw( logger );

sub call {
   my($self, $env) = @_;

   local $SIG{__WARN__} = $self->logger || sub {
      $env->{'psgix.logger'}->({
         level => 'warn',
         message => join '', @_
      });
   };
   my $res = $self->app->($env);

   return $res;
}

1;



=pod

=head1 NAME

Plack::Middleware::LogWarn - converts to warns to log messages

=head1 VERSION

version 0.001002

=head1 SYNOPSIS

 builder {
    enable 'LogWarn';
    $app;
 }

 # use it with another logger middleware

 builder {
    enable 'LogWarn';
    enable 'Log4perl', category => 'plack', conf => '/path/to/log4perl.conf';
    $app;
 }

=head1 DESCRIPTION

LogWarn is a C<Plack::Middleware> component that will help you get warnings into
a logger. You probably want to use some sort of real logging system such as
L<Log::Log4perl> and another C<Plack::Middleware> such as L<Plack::Middleware::Log4perl>.

=head1 CONFIGURATION

=over 4

=item logger

optional, C<coderef> that will capture warnings. By default it uses
C<< $env->{'psgix.logger'} >> with a level of C<warn>.

=back

=head1 SEE ALSO

L<Plack::Middleware::Log4perl>

=head1 CREDITS

Thanks to Micro Technology Services, Inc. for funding the initial development
of this module and frew (Arthur Axel "fREW" Schmidt <frioux@gmail.com>) for his
extensive patience and assistance.

=cut

=head1 AUTHOR

Geoffrey Darling <geoffreydarling@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Geoffrey Darling.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__

