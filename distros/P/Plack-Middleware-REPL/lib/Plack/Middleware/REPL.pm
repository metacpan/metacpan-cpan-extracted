package Plack::Middleware::REPL;

use strict;
use 5.008_001;
our $VERSION = '0.01';

use parent qw(Plack::Middleware);
use Plack::Util::Accessor qw(warn noprofile nodie);

use Carp::REPL ();

sub repl_options {
    my $self = shift;
    my @options;
    for my $opt (qw(warn noprofile nodie)) {
        push @options, $opt if $self->$opt;
    }
    @options;
}

sub call {
    my($self, $env) = @_;
    Carp::REPL->import($self->repl_options);
    return $self->app->($env);
}

1;
__END__

=encoding utf-8

=for stopwords

=head1 NAME

Plack::Middleware::REPL - REPL when your application throws errors or warnings

=head1 SYNOPSIS

  enable "REPL";

=head1 DESCRIPTION

Plack::Middleware::REPL is a PSGI middleware component that enables
REPL (read-eval-print-loop) when your application raises errors.

  # your Dancer app
  use Dancer;
  get '/' => sub {
      my $self = shift;
      my $n = parms()->{name}; # typo
      return "Hi there $n";
  };
  dance;

Run it with the REPL middleware:

  plackup -e 'enable "REPL"' app.pl

Hit your application, and you'll get a REPL shell on the console:

  Trace begun at ...
  ...
  $ :l
  File /Users/miyagawa/development/dancer/app.pl
    5: use Dancer;
    6:
    7: get '/' => sub {
    8:     my $self = shift;
  * 9:     my $n = parms()->{name};
   10:     return "Hi there $n";
   11: };
   12: dance;
  $ request->path
  /
  $ :u
  Now at /Users/miyagawa/perl5/perlbrew/perls/perl-5.12.3/lib/site_perl/5.12.3/Dancer/Route.pm:246 (frame 1).
  $ $self
  $Dancer_Route1 = Dancer::Route=HASH(0x10089d278);

See L<Carp::REPL> for more commands in the REPL shell.

=head1 OPTIONS

=over 4

=item warn

  enable "REPL", warn => 1;

Also enables REPL when your app throws warnings.

=back

=head1 LIMITATIONS

Because of the way C<< $SIG{__DIE__} >> works in Perl, this middleware
doesn't work well with web application frameworks that sets its own
exception handler, such as L<Mojolicious>.

=head1 AUTHOR

Tatsuhiko Miyagawa E<lt>miyagawa@bulknews.netE<gt>

=head1 COPYRIGHT

Copyright 2011- Tatsuhiko Miyagawa

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<Carp::REPL> L<Devel::REPL> L<CatalystX::REPL>

=cut
