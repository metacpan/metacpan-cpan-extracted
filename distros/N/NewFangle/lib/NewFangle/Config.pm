package NewFangle::Config 0.08 {

  use strict;
  use warnings;
  use 5.014;
  use NewFangle::FFI;
  use FFI::C::Util ();
  use Carp ();

# ABSTRACT: NewRelic Configuration class.


  $ffi->attach( [ create_app_config => 'new' ] => [ 'string', 'string' ] => 'newrelic_app_config_t' => sub {
    my($xsub, $class, %config) = @_;
    my $app_name    = delete $config{app_name}    // $ENV{NEWRELIC_APP_NAME}    // 'AppName';
    my $license_key = delete $config{license_key} // $ENV{NEWRELIC_LICENSE_KEY} // '';
    my $config = $xsub->($app_name, $license_key) // Carp::croak("Error creating $class, bad license key");
    FFI::C::Util::perl_to_c($config, \%config);
    bless {
      config => $config,
    }, $class;
  });


  sub to_perl
  {
    my($self) = @_;
    FFI::C::Util::c_to_perl($self->{config});
  }

  $ffi->attach( [ destroy_app_config => 'DESTROY' ] => [ 'opaque*' ] => 'bool' => sub {
    my($xsub, $self) = @_;
    my $ptr = delete $self->{config}->{ptr};
    $xsub->(\$ptr);
  });
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

NewFangle::Config - NewRelic Configuration class.

=head1 VERSION

version 0.08

=head1 SYNOPSIS

 use NewFangle;
 my $config = NewFangle::Config->new(
   app_name => 'AppName',
   license_key => '',
   datastore_tracer => {
     database_name_reporting => 1,
     instance_reporting      => 1,
   },
   distributed_tracing => {
     enabled => 0,
   },
   log_filename => '',
   log_level => 'error',
   redirect_collector => '',
   span_events => {
     enabled => 1,
   },
   transaction_tracer => {
     datastore_reporting => {
       enabled => 1,
       record_sql => 'obfuscated',
       threshold_us => 500000,
     },
     duration_us => 0,
     enabled => 1,
     stack_trace_threshold_us => 500000,
     threshold => 'is_apdex_failing',
   },
 );

=head1 DESCRIPTION

This class provides an interface to the NewFangle configuration.

=head1 CONSTRUCTOR

=head2 new

 my $config = NewFangle::Config->new(%config);
 my $config = NewFangle::Config->new;

Creates a new configuration instance.  The synopsis above provides all of the configurable items
that can be passed to the constructor.  Please see the C-SDK documentation for details on what
these all mean.

If C<app_name> is not specified then the environment variable C<NEWRELIC_APP_NAME> will be used.
If C<license_key> is not specified then the environment variable C<NEWRELIC_LICENSE_KEY> will be
used.

(csdk: newrelic_create_app_config)

=head1 METHODS

=head2 to_perl

 my $hash = $config->to_perl;

Convert the configuration back to a Perl hash reference.  This may be useful to debugging or diagnostics.

=head1 SEE ALSO

=over 4

=item L<NewFangle>

=back

=head1 AUTHOR

Author: Graham Ollis E<lt>plicease@cpan.orgE<gt>

Contributors:

Owen Allsopp (ALLSOPP)

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by Graham Ollis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
