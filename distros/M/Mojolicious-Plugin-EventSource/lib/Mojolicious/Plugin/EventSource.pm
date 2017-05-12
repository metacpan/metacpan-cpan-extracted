package Mojolicious::Plugin::EventSource;
use Mojo::Base 'Mojolicious::Plugin';

our $VERSION = 0.3;

sub register {
   my $self = shift;
   my $app  = shift;
   my $conf = shift;
   $conf->{ timeout } ||= 300;
   $app->routes->add_shortcut('event_source' => sub {
      my $self = shift;
      my @pars = map {
         if(ref $_ eq "CODE") {
            my $copy = $_;
            $_ = sub {
               my $self = shift;
               Mojo::IOLoop->stream($self->tx->connection)->timeout($conf->{ timeout });
               $self->res->headers->content_type('text/event-stream');
               $self->$copy(@_);
            };
         }
         $_;
      } @_;

      $app->routes->get( @_ );
   });

   *{ main::event_source } = sub { $app->routes->event_source( @_ ) };

   $app->helper( 'emit' => sub {
      my $self  = shift;
      my $event = shift;
      my $data  = shift;

      $self->write("event:$event\ndata: $data\n\n");
   } );
}

42

__END__

=head1 NAME

Mojolicious::Plugin::EventSource - A plugin to make it eazy to use EventSource with Mojolicious

=head1 VERSION

Version 0.3

=cut

=head1 SYNOPSIS

    use Mojolicious::Lite;
    BEGIN{ plugin 'Mojolicious::Plugin::EventSource', timeout => 300 }
    
    get '/' => 'index';
    
    event_source '/event' => sub {
      my $self = shift;
    
      my $id = Mojo::IOLoop->recurring(1 => sub {
        my $pips = int(rand 6) + 1;
        $self->emit("dice", $pips);
      });
      $self->on(finish => sub { Mojo::IOLoop->drop($id) });
    } => "event";
    
    app->start;
    __DATA__
    
    @@ index.html.ep
    <!doctype html><html>
      <head><title>Roll The Dice</title></head>
      <body>
        <script>
          var events = new EventSource('<%= url_for 'event' %>');
    
          // Subscribe to "dice" event
          events.addEventListener('dice', function(event) {
            document.body.innerHTML += event.data + '<br/>';
          }, false);
        </script>
      </body>
    </html>

=head1 EXPORT

If you are using L<Mojolicious::Lite> it exports the shortcut event_source to your main.

=head1 HELPERS

=head2 emit

Emits a event.

=head1 METHODS

L<Mojolicious::Plugin::EventSource> inherits all methods from L<Mojolicious::Plugin>
and implements the following new one.

=head2 C<register>

$plugin->register;

Register plugin helper and shortcut in L<Mojolicious> application.

=head1 AUTHOR

Fernando Correa de Oliveira, C<< <fco at cpan.org> >>

Thanks to Gabriel Vieira and #mojo (irc.perl.org) for the help.

=head1 BUGS

Please report any bugs or feature requests to C<bug-mojolicious-plugin-eventsource at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Mojolicious-Plugin-EventSource>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Mojolicious::Plugin::EventSource


You can also look for information at:

=over 4

=item * GitHub: GitHug Repo

L<https://github.com/FCO/Mojolicious-Plugin-EventSource>

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Mojolicious-Plugin-EventSource>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Mojolicious-Plugin-EventSource>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Mojolicious-Plugin-EventSource>

=item * Search CPAN

L<http://search.cpan.org/dist/Mojolicious-Plugin-EventSource/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2012 Fernando Correa de Oliveira.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

