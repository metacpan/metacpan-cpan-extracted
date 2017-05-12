package Tak;

use Tak::Loop;
use strictures 1;

our $VERSION = '0.001004'; # 0.1.4

our ($loop, $did_upgrade);

sub loop { $loop ||= Tak::Loop->new }

sub loop_upgrade {
  return if $did_upgrade;
  require IO::Async::Loop;
  my $new_loop = IO::Async::Loop->new;
  $loop->pass_watches_to($new_loop) if $loop;
  $loop = $new_loop;
  $did_upgrade = 1;
}

sub loop_until {
  my ($class, $done) = @_;
  return if $done;
  $class->loop->loop_once until $_[1];
}

sub await_all {
  my ($class, @requests) = @_;
  @requests = grep !$_->is_done, @requests;
  return unless @requests;
  my %req = map +("$_" => "$_"), @requests;
  my $done;
  my %on_r = map {
    my $orig = $_->{on_result};
    my $tag = $req{$_};
    ($_ => sub { delete $req{$tag}; $orig->(@_); $done = 1 unless keys %req; })
  } @requests;
  my $call = sub { $class->loop_until($done) };
  foreach (@requests) {
    my $req = $_;
    my $inner = $call;
    $call = sub { local $req->{on_result} = $on_r{$req}; $inner->() };
  }
  $call->();
  return;
}

1;

=head1 NAME

Tak - Multi host remote control over ssh (then I wrote Object::Remote)

=head1 SYNOPSIS

  # Curse at mst for doing it again under a different name
  # Curse at mst some more
  $ cpanm Object::Remote
  # Now go use that

(sorry, I should've done a tombstone release ages back)

  bin/tak -h user1@host1 -h user2@host2 exec cat /etc/hostname

or

  in Takfile:

  package Tak::MyScript;
  
  use Tak::Takfile;
  use Tak::ObjectClient;
  
  sub each_get_homedir {
    my ($self, $remote) = @_;
    my $oc = Tak::ObjectClient->new(remote => $remote);
    my $home = $oc->new_object('Path::Class::Dir')->absolute->stringify;
    $self->stdout->print(
      $remote->host.': '.$home."\n"
    );
  }
  
  1;

then

  tak -h something get-homedir

=head1 WHERE'S THE REST?

A drink leaked in my bag on the way back from LPW. My laptop is finally
alive again though so I'll try and turn my slides into a vague attempt
at documentation while I'm traveling to/from christmas things.

=head1 Example

$ cat Takfile
package Tak::MyScript;

use strict;
use warnings;

use Tak::Takfile;
use Tak::ObjectClient;
use lib "./lib";

sub each_host {
    my ($self, $remote) = @_;

    my $oc = Tak::ObjectClient->new(remote => $remote);
    my $name = $oc->new_object('My::Hostname');
    print "Connected to hostname: " . $name . "\n";
    }

1;

-----

$cat ./lib/My/Hostname
package My::Hostname;

use Sys::Hostname;

sub new {
    my ($self) = @_;
    my $name = hostname;
    return $name;
    }

1;

=head1 AUTHOR

mst - Matt S. Trout (cpan:MSTROUT) <mst@shadowcat.co.uk>

=head1 CONTRIBUTORS

None required yet. Maybe this module is perfect (hahahahaha ...).

=head1 COPYRIGHT

Copyright (c) 2011 the Tak L</AUTHOR> and L</CONTRIBUTORS>
as listed above.

=head1 LICENSE

This library is free software and may be distributed under the same terms
as perl itself.

=cut
