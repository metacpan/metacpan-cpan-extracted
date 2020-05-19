package NewFangle::FFI 0.01 {

  use strict;
  use warnings;
  use 5.020;
  use FFI::CheckLib 0.27 ();
  use FFI::Platypus 1.26;
  use base qw( Exporter );

  our @EXPORT = qw( $ffi );

# ABSTRACT: Private class for NewFangle.pm


  our $ffi = FFI::Platypus->new(
    api => 1,
    lib => [do {
      my $lib = FFI::CheckLib::find_lib lib => 'newrelic';
      $lib
        ? $lib
        : FFI::CheckLib::find_lib lib => 'newrelic', alien => 'Alien::libnewrelic',
    }],
  );
  $ffi->mangler(sub { "newrelic_$_[0]" });
  $ffi->load_custom_type('::PtrObject', 'newrelic_segment_t', 'NewFangle::Segment',
    sub { bless { ptr => $_[0] }, 'NewFangle::Segment' });

  $ffi->type('uint64' => 'newrelic_time_us_t');
  $ffi->type('object(NewFangle::App)' => 'newrelic_app_t');
  $ffi->type('object(NewFangle::Transaction)' => 'newrelic_txn_t',);
  $ffi->type('object(NewFangle::CustomEvent)' => 'newrelic_custom_event_t');

};

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

NewFangle::FFI - Private class for NewFangle.pm

=head1 VERSION

version 0.01

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
