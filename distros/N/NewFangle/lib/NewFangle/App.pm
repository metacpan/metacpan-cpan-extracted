package NewFangle::App 0.05 {

  use strict;
  use warnings;
  use 5.014;
  use NewFangle::FFI;
  use NewFangle::Transaction;
  use Carp ();

# ABSTRACT: NewRelic application class


  $ffi->attach( [ create_app => 'new' ] => ['newrelic_app_config_t', 'unsigned short'] => 'newrelic_app_t' => sub {
    my($xsub, undef, $config, $timeout) = @_;

    if(defined $ENV{NEWRELIC_APP_HOSTNAME}) {
      NewFangle::newrelic_set_hostname(
        $ENV{NEWRELIC_APP_HOSTNAME}
      );
    }

    $config //= {};
    $config = NewFangle::Config->new(%$config) if ref $config eq 'HASH';
    $timeout //= $ENV{PERL_NEWFANGLE_TIMEOUT} // 0;
    my $self = $xsub->($config->{config});
    unless(defined $self)
    {
      my $ptr = undef;
      $self = bless \$ptr, __PACKAGE__;
    }
    $self;
  });


  sub _txn_wrapper {
    my $xsub = shift;
    my $txn = $xsub->(@_);
    $txn //= do {
      my $ptr = undef;
      $txn = bless \$ptr, 'NewFangle::Transaction';
    };
    $txn;
  }

  $ffi->attach( start_non_web_transaction => ['newrelic_app_t','string'] => 'newrelic_txn_t', \&_txn_wrapper );
  $ffi->attach( start_web_transaction     => ['newrelic_app_t','string'] => 'newrelic_txn_t', \&_txn_wrapper );

  $ffi->attach( [ destroy_app => 'DESTROY' ] => ['opaque*'] => 'bool' => sub {
    my($xsub, $self) = @_;
    my $ptr = $$self;
    $xsub->(\$ptr);
  });


  sub connected
  {
    my $self = shift;
    !!$$self;
  }

};

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

NewFangle::App - NewRelic application class

=head1 VERSION

version 0.05

=head1 SYNOPSIS

 use NewFangle;
 my $app = NewFangle::App->new;

=head1 DESCRIPTION

NewRelic application class.

=head1 CONSTRUCTOR

=head2 new

 my $app = NewFangle::App->new($config, $timeout_ms);
 my $app = NewFangle::App->new(\%config, $timeout_ms);
 my $app = NewFangle::App->new;

Creates a NewFangle application instance.  On failure to connect an app instance will
still be created and usable, though of course no stats will be sent to NewRelic.  There
will be appropriate diagnostics sent to the log (configured with C<newrelic_configure_log>
in L<NewFangle>).  If you want  to check if the connection was successful, then you can
use the C<connected> method below:

The first argument may be one of:

=over 4

=item L<NewFangle::Config> instance

=item Hash reference

Containing the initialization for a config instance which will be created internally.

=back

If C<$timeout_ms> is the maximum time to wait for a connection to be established.  If not
specified, then only one attempt at connecting to the daemon will be made.

(csdk: newrelic_create_app)

=head2 start_web_transaction

 my $txn = $app->start_web_transaction($name);

Starts a web based transaction.  Returns the L<NewFangle::Transaction> instance.

(csdk: newrelic_start_web_transaction)

=head2 start_non_web_transaction

 my $txn = $app->start_non_web_transaction($name);

Starts a non-web based transaction.  Returns the L<NewFangle::Transaction> instance.

(csdk: newrelic_start_web_transaction)

=head2 connected

 my $bool = $app->connected;

Returns true if the app class was able to connect to the local NewRelic daemon on startup.

=head1 SEE ALSO

=over 4

=item L<NewFangle>

=back

=head1 AUTHOR

Graham Ollis <plicease@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by Graham Ollis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
