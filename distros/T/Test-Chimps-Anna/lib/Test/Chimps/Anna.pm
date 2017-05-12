package Test::Chimps::Anna;

use warnings;
use strict;

use Carp;
use Jifty::DBI::Handle;
use Test::Chimps::Report;
use Test::Chimps::ReportCollection;
use YAML::Syck;

use base 'Bot::BasicBot';

=head1 NAME

Test::Chimps::Anna - An IRQ bot that announces test failures (and unexpected passes)

=head1 VERSION

Version 0.04

=cut

our $VERSION = '0.04';

=head1 SYNOPSIS

Anna is a bot.  Specifically, she is an implementation of
L<Bot::BasicBot>.  She will query your smoke report database and
print smoke report summaries when tests fail or unexpectedly
succeed.

    use Test::Chimps::Anna;

    my $anna = Test::Chimps::Anna->new(
      server   => "irc.perl.org",
      port     => "6667",
      channels => ["#example"],
    
      nick      => "anna",
      username  => "nice_girl",
      name      => "Anna",
      database_file => '/path/to/chimps/chimpsdb/database',
      config_file => '/path/to/chimps/anna-config.yml',
      server_script => 'http://example.com/cgi-bin/chimps-server.pl'
      );
    
    $anna->run;

=head1 METHODS

=head2 new ARGS

ARGS is a hash who's keys are mostly passed through to
L<Bot::BasicBot>.  Keys which are recognized beyond the ones from
C<Bot::BasicBot> are as follows:

=over 4

=item * database_file

Mandatory.  The SQLite database Anna should connect to get smoke
report data.

=item * server_script

Mandatory.  The URL of the server script.  This is used to display
URLs to the full smoke report.

=item * config_file

If your server accepts report variables, you must specify a config
file.  The config file is a YAML dump of an array containing the
names of those variables.  Yes, this is a hack.

=back

=cut

sub new {
  my $class = shift;
  my $self = $class->SUPER::new(@_);
  $self = bless $self, $class;
  my %args = @_;
  if (! exists $args{database_file}) {
    croak "You must specify SQLite database file!";
  }
  if (exists $args{config_file}) {
    my $columns = LoadFile($args{config_file});
    foreach my $var (@$columns) {
      package Test::Chimps::Report::Schema;
      column($var, type(is('text')));
    }
  }
  $self->{database_file} = $args{database_file};
  
  $self->{handle} = Jifty::DBI::Handle->new();
  $self->{handle}->connect(driver => 'SQLite', database => $self->{database_file})
    or die "Couldn't connect to database";

  $self->{oid} = $self->_get_highest_oid;
  $self->{first_run} = 1;
  $self->{passing_projects} = {};
  return $self;
}

sub _get_highest_oid {
  my $self = shift;
  
  my $reports = Test::Chimps::ReportCollection->new(handle => $self->_handle);
  $reports->columns(qw/id/);
  $reports->unlimit;
  $reports->order_by(column => 'id', order => 'DES');
  $reports->rows_per_page(1);

  my $report = $reports->next;
  return $report->id;
}

sub _handle {
  my $self = shift;
  return $self->{handle};
}

sub _oid {
  my $self = shift;
  return $self->{oid};
}

=head2 tick

Overrided method.  Checks for new smoke reports every 2 minutes and
prints summaries if there were failed tests or if tests
unexpectedly succeeded.

=cut

sub tick {
  my $self = shift;

  if ($self->{first_run}) {
    $self->_say_to_all("I'm going to ban so hard");
    $self->{first_run} = 0;
  }

  my $reports = Test::Chimps::ReportCollection->new(handle => $self->_handle);
  $reports->limit(column => 'id', operator => '>', value => $self->_oid);
  $reports->order_by(column => 'id');

  while(my $report = $reports->next) {
    if ($report->total_failed || $report->total_unexpectedly_succeeded) {
      $self->{passing_projects}->{$report->project} = 0;
      my $msg =
        "Smoke report for " .  $report->project . " r" . $report->revision . " submitted: "
        . sprintf( "%.2f", $report->total_ratio * 100 ) . "\%, "
        . $report->total_seen . " total, "
        . $report->total_ok . " ok, "
        . $report->total_failed . " failed, "
        . $report->total_todo . " todo, "
        . $report->total_skipped . " skipped, "
        . $report->total_unexpectedly_succeeded . " unexpectedly succeeded.  "
        . $self->{server_script} . "?id=" . $report->id;

      $self->_say_to_all($msg);
    } else {
      if (! exists $self->{passing_projects}->{$report->project}) {
        # don't announce if we've never seen this project before
        $self->{passing_projects}->{$report->project} = 1;
      }
      next if $self->{passing_projects}->{$report->project};
      $self->{passing_projects}->{$report->project} = 1;
      
      $self->{passing_projects}->{$report->project}++;
      $self->_say_to_all("Smoke report for " .  $report->project
                         . " r" . $report->revision . " submitted: "
                         . "all " . $report->total_ok . " tests pass");
    }
  }

  my $last = $reports->last;
  if (defined $last) {
    # we might already be at the highest oid
    $self->{oid} = $last->id;
  }
  
  return 5;
}
  
sub _say_to_all {
  my $self = shift;
  my $msg = shift;

  $self->say(channel => $_, body => $msg)
    for (@{$self->{channels}});
}

=head1 AUTHOR

Zev Benjamin, C<< <zev at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-test-chimps-anna at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Test-Chimps-Anna>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Test::Chimps::Anna

You can also look for information at:

=over 4

=item * Mailing list

Chimps has a mailman mailing list at
L<chimps@bestpractical.com>.  You can subscribe via the web
interface at
L<http://lists.bestpractical.com/cgi-bin/mailman/listinfo/chimps>.

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Test-Chimps-Anna>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Test-Chimps-Anna>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Test-Chimps-Anna>

=item * Search CPAN

L<http://search.cpan.org/dist/Test-Chimps-Anna>

=back

=head1 COPYRIGHT & LICENSE

Copyright 2006 Best Practical Solutions.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;
