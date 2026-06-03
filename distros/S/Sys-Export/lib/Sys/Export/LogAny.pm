package Sys::Export::LogAny;

our $VERSION = '0.004'; # VERSION
# ABSTRACT: Use Log::Any without depending on it


use v5.26;
use warnings;

if (eval 'use Log::Any 1.051; 1') {
   our @ISA= ( 'Log::Any' );
   Log::Any->import(default_adapter => [ 'Stderr', log_level => 'info' ]);
} else {
   *get_logger= sub { bless {}, 'Sys::Export::LogAny::_Logger'; };
   *import= sub {
      my $class= shift;
      for (@_) {
         if ($_ eq '$log') {
            my $caller= caller;
            my $logger= $class->get_logger($caller);
            no strict 'refs';
            *{$caller . '::log'}= \$logger;
         }
         else { die "Can't export '$_'"; }
      }
   };
}

package Sys::Export::LogAny::_Logger {
   use v5.26;
   use warnings;
   use experimental qw( signatures );
   sub _dump {
      state $dumper_loaded= require Data::Dumper;
      chomp(my $s= Data::Dumper->new([$_[0]])->Terse(1)->Sortkeys(1)->Dump);
      $s;
   }
   sub is_info { 1 }
   sub info($self, @msg) {
      print STDERR join(' ', @msg)."\n"
   }
   sub infof($self, $fmt, @args) {
      printf STDERR $fmt."\n", map +(ref? _dump($_) : defined? $_ : '(undef)'), @args;
   }
   *error = *warn  = *notice = *info;
   *errorf= *warnf = *noticef= *infof;
   *is_error= *is_warn= *is_notice= *is_info;
   sub is_debug { ($ENV{DEBUG} // 0) >= 1 }
   sub is_trace { ($ENV{DEBUG} // 0) >= 2 }
   sub debug  { is_debug? info (@_) : () }
   sub debugf { is_debug? infof(@_) : () }
   sub trace  { is_trace? info (@_) : () }
   sub tracef { is_trace? infof(@_) : () }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Sys::Export::LogAny - Use Log::Any without depending on it

=head1 DESCRIPTION

Sys::Export aims to be dependency-free at runtime, so that it can be mounted into arbitrary
environments without needing to install any other modules.  But Log::Any sure is useful...
This shim module loads the real Log::Any if it is installed, else it falls back to a bare
minimum log object that logs to STDERR.

=head1 VERSION

version 0.004

=head1 AUTHOR

Michael Conrad <mike@nrdvana.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Michael Conrad.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
