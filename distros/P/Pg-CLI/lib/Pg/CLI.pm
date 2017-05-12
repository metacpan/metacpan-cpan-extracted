package Pg::CLI;
{
  $Pg::CLI::VERSION = '0.11';
}

1;

# ABSTRACT: Run Postgres CLI utilities

__END__

=pod

=head1 NAME

Pg::CLI - Run Postgres CLI utilities

=head1 VERSION

version 0.11

=head1 SYNOPSIS

  my $psql = Pg::CLI::psql->new(
      username => 'foo',
      password => 'bar',
      host     => 'pg.example.com',
      port     => 5433,
  );

  $psql->run(
      name    => 'database',
      options => [ '-c', 'DELETE FROM table' ],
  );

=head1 DESCRIPTION

This distribution provides some simple wrapper around the command line
utilities that ship with Postgres. Currently, it includes the following
classes:

=over 4

=item * L<Pg::CLI::psql>

=item * L<Pg::CLI::pg_dump>

=item * L<Pg::CLI::pg_restore>

=item * L<Pg::CLI::pg_config>

=back

=head1 BUGS

Please report any bugs or feature requests to C<bug-pg-cli@rt.cpan.org>, or
through the web interface at L<http://rt.cpan.org>.  I will be notified, and
then you'll automatically be notified of progress on your bug as I make
changes.

=head1 DONATIONS

If you'd like to thank me for the work I've done on this module, please
consider making a "donation" to me via PayPal. I spend a lot of free time
creating free software, and would appreciate any support you'd care to offer.

Please note that B<I am not suggesting that you must do this> in order for me
to continue working on this particular software. I will continue to do so,
inasmuch as I have in the past, for as long as it interests me.

Similarly, a donation made in this way will probably not make me work on this
software much more, unless I get so many donations that I can consider working
on free software full time, which seems unlikely at best.

To donate, log into PayPal and send money to autarch@urth.org or use the
button on this page: L<http://www.urth.org/~autarch/fs-donation.html>

=head1 AUTHOR

Dave Rolsky <autarch@urth.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2013 by Dave Rolsky.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
