package NewFangle::FFI 0.06 {

  use strict;
  use warnings;
  use 5.014;
  use FFI::CheckLib 0.27 ();
  use FFI::Platypus 1.26;
  use FFI::C 0.08;
  use base qw( Exporter );

  our @EXPORT = qw( $ffi );

# ABSTRACT: Private class for NewFangle.pm


  sub _lib {
    my $lib = FFI::CheckLib::find_lib lib => 'newrelic';
    $lib
      ? $lib
      : FFI::CheckLib::find_lib lib => 'newrelic', alien => 'Alien::libnewrelic'
    ;
  }


  our $ffi = FFI::Platypus->new(
    api => 1,
    lib => [_lib],
  );
  $ffi->mangler(sub { "newrelic_$_[0]" });
  $ffi->load_custom_type('::PtrObject', 'newrelic_segment_t', 'NewFangle::Segment',
    sub { bless { ptr => $_[0] }, 'NewFangle::Segment' });

  $ffi->type('uint64' => 'newrelic_time_us_t');
  $ffi->type('object(NewFangle::App)' => 'newrelic_app_t');
  $ffi->type('object(NewFangle::Transaction)' => 'newrelic_txn_t',);
  $ffi->type('object(NewFangle::CustomEvent)' => 'newrelic_custom_event_t');

  FFI::C->ffi($ffi);

  package NewFangle::NewrelicLoglevel 0.06 {
    FFI::C->enum([
      'error',
      'warning',
      'info',
      'debug',
    ], { prefix => 'NEWRELIC_LOG_' });
  }

  package NewFangle::NewrelicTransactionTracerThreshold 0.06 {
    FFI::C->enum([
      'is_apdex_failing',
      'is_over_duration',
    ], { prefix => 'NEWRELIC_THRESHOLD_' });
  }

  package NewFangle::NewrelicTtRecordsql 0.06 {
    FFI::C->enum([
      'off',
      'raw',
      'obfuscated',
    ], { prefix => 'NEWRELIC_SQL_' });
  }

  package NewFangle::DatastoreReporting 0.06 {
    FFI::C->struct([
      enabled      => 'bool',
      record_sql   => 'newrelic_tt_recordsql_t',
      threshold_us => 'newrelic_time_us_t',
    ]);
  };

  package NewFangle::NewrelicTransactionTracerConfig 0.06 {
    FFI::C->struct([
      enabled                  => 'bool',
      threshold                => 'newrelic_transaction_tracer_threshold_t',
      duration_us              => 'newrelic_time_us_t',
      stack_trace_threshold_us => 'newrelic_time_us_t',
      datastore_reporting      => 'datastore_reporting_t',
    ]);
  }

  package NewFangle::NewrelicDatastoreSegmentConfig 0.06 {
    FFI::C->struct([
      instance_reporting      => 'bool',
      database_name_reporting => 'bool',
    ]);
  }

  package NewFangle::NewrelicDistributedTracingConfig 0.06 {
    FFI::C->struct([
      enabled => 'bool',
    ]);
  }

  package NewFangle::NewrelicSpanEventConfig 0.06 {
    FFI::C->struct([
      enabled => 'bool',
    ]);
  }

  package NewFangle::NewrelicAppConfig 0.06 {
    FFI::C->struct([
      app_name            => 'string(255)',
      license_key         => 'string(255)',
      redirect_collector  => 'string(100)',
      log_filename        => 'string(512)',
      log_level           => 'newrelic_loglevel_t',
      transaction_tracer  => 'newrelic_transaction_tracer_config_t',
      datastore_tracer    => 'newrelic_datastore_segment_config_t',
      distributed_tracing => 'newrelic_distributed_tracing_config_t',
      span_events         => 'newrelic_span_event_config_t',
    ], { trim_string => 1 });
  }

};

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

NewFangle::FFI - Private class for NewFangle.pm

=head1 VERSION

version 0.06

=head1 SYNOPSIS

 % perldoc NewFangle

=head1 DESCRIPTION

This is part of the internal workings for L<NewFangle>.

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
