package Test::Chimps::Client;

use warnings;
use strict;

use Carp;
use Params::Validate qw/:all/;
use LWP::UserAgent;
use Storable qw/nfreeze/;

use constant PROTO_VERSION => 0.2;

=head1 NAME

Test::Chimps::Client - Send smoke test results to a server

=head1 VERSION

Version 0.05

=cut

our $VERSION = '0.05';

=head1 SYNOPSIS

This module simplifies the process of sending smoke test results
(in the form of C<Test::TAP::Model>s) to a smoke server.

    use Test::Chimps::Client;
    use Test::TAP::Model::Visual;

    chdir "some/module/directory";

    my $model = Test::TAP::Model::Visual->new_with_tests(glob("t/*.t"));

    my $client = Test::Chimps::Client->new(
      server => 'http://www.example.com/cgi-bin/smoke-server.pl',
      model  => $model
    );
    
    my ($status, $msg) = $client->send;
    
    if (! $status) {
      print "Error: $msg\n";
      exit(1);
    }


=head1 METHODS

=head2 new ARGS

Creates a new Client object.  ARGS is a hash whose valid keys are:

=over 4

=item * compress

Optional.  Does not currently work

=item * model

Mandatory.  The value must be a C<Test::TAP::Model>.  These are the
test results that will be submitted to the server.

=item * report_variables

Optional.  A hashref of report variables and values to send to the
server.

=item * server

Mandatory.  The URI of the server script to upload the model to.

=back

=cut

use base qw/Class::Accessor/;

__PACKAGE__->mk_ro_accessors(qw/model server compress report_variables/);

sub new {
  my $class = shift;
  my $obj = bless {}, $class;
  $obj->_init(@_);
  return $obj;
}

sub _init {
  my $self = shift;
  my %args = validate_with(
    params => \@_,
    called => 'The Test::Chimps::Client constructor',
    spec   => {
      model            => { isa => 'Test::TAP::Model' },
      server           => 1,
      compress         => 0,
      report_variables => {
        optional => 1,
        type     => HASHREF,
        default  => {}
      }
    }
  );

  foreach my $key (keys %args) {
    $self->{$key} = $args{$key};
  }

}

=head2 send

Submit the specified model to the server.  This function's return
value is a list, the first of which indicates success or failure,
and the second of which is an error string.

=cut

sub send {
  my $self = shift;
  
  my $ua = LWP::UserAgent->new;
  $ua->agent("Test-Chimps-Client/" . PROTO_VERSION);
  $ua->env_proxy;

  my %request = (upload => 1, version => PROTO_VERSION,
                 model_structure => nfreeze($self->model->structure),
                 report_variables => nfreeze($self->report_variables));

  my $resp = $ua->post($self->server => \%request);
  if($resp->is_success) {
    if($resp->content =~ /^ok/) {
      return (1, '');
    } else {
      return (0, $resp->content);
    }
  } else {
    return (0, $resp->status_line);
  }
}

=head1 ACCESSORS

There are read-only accessors for compress, model,
report_variables, and server.

=head1 AUTHOR

Zev Benjamin, C<< <zev at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-test-chimps at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Test-Chimps-Client>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Test::Chimps::Client

You can also look for information at:

=over 4

=item * Mailing list

Chimps has a mailman mailing list at
L<chimps@bestpractical.com>.  You can subscribe via the web
interface at
L<http://lists.bestpractical.com/cgi-bin/mailman/listinfo/chimps>.

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Test-Chimps-Client>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Test-Chimps-Client>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Test-Chimps-Client>

=item * Search CPAN

L<http://search.cpan.org/dist/Test-Chimps-Client>

=back

=head1 ACKNOWLEDGEMENTS

Some code in this module is based on smokeserv-client.pl from the
Pugs distribution.

=head1 COPYRIGHT & LICENSE

Copyright 2006 Best Practical Solutions.
Portions copyright 2005-2006 the Pugs project.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;

