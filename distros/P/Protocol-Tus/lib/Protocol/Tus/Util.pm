package Protocol::Tus::Util;
{ our $VERSION = '0.004' }
use v5.24;
use warnings;
use experimental qw< signatures >;

use Carp;
use Exporter qw< import >;
use Module::Runtime qw< use_module >;
use Ouch qw< :trytiny_var >;
use Scalar::Util qw< blessed >;

our @EXPORT_OK = qw<
   as_ouch
   coerce_model
   lc_hash
   ouch_rethrow
   response
   response_augment
   response_from_exception
   validate_checksum
   validate_id
   validate_length
   validate_tus_resumable
>;

sub as_ouch ($exception) {
   return $exception if eval { $exception->isa('Ouch') };
   return Ouch->new(500, 'Internal Server Error', $exception);
}

sub coerce_model ($spec) {
   return $spec if blessed($spec); # assume it's OK
   my $class = $spec->{class}
      or croak 'no class name in provided spec';
   my $args = $spec->{args} // {};
   return use_module($class)->new($args);
}

sub lc_hash ($input) {
   return { map { lc($_) => $input->{$_} } keys($input->%*) };
}

sub ouch_rethrow ($e) {
   die as_ouch($e);
}

sub response (@args) {
   require Protocol::Tus::Response;
   return Protocol::Tus::Response->new(@args);
}

sub response_from_exception ($exception, %args) {
   require Protocol::Tus::Response;
   return Protocol::Tus::Response->new_from_exception($exception, %args);
}

sub validate_checksum ($dref, $chk) {
   return unless defined($chk);

   $chk =~ s{\A\s+|\s+\z}{}gmxs;
   my ($type, $expected) = split m{\s+}mxs, $chk, 2;
   ouch 400, 'Bad Request, unsupported checksum algorithm'
      if ($type // '') ne 'sha1';

   $expected //= '';
   my $got = sha1_base64($$dref);
   ouch 460, 'Checksum Mismatch' if $got ne $expected;

   return;
}

sub validate_id ($id) {
   # just a basic assumption
   return if length($id // '');
   ouch 400, 'missing upload identifier';
}

sub validate_length ($length, $args) {
   # collect length from arguments, if present
   if (defined(my $l = $args->{'upload-length'} // undef)) {
      $length //= $l;
      ouch 400, 'cannot update Upload-Length', { cleanup => 1 }
         if $l != $length;
   }

   if (defined(my $udl = $args->{'upload-defer-length'} // undef)) {
      ouch 400, 'found both Upload-Length and Upload-Defer-Length',
            { cleanup => 1 }
         if defined($length);
      ouch 400, 'invalid value for Upload-Defer-Length', { cleanup => 1 }
         if $udl ne '1';
   }
   else { # insist on length
      ouch 400, 'unknown length and no Upload-Defer-Length',
            { cleanup => 1 }
         unless defined($length);
   }

   return $length;
}

sub validate_tus_resumable ($headers, $version) {
   my $value = $headers->{'tus-resumable'};
   ouch 400, 'Missing header Tus-Resumable',
         { headers => { 'Tus-Version' => $version } }
      unless length($value // '');
   ouch 412, "Unsupported version",
         {
            headers => { 'Tus-Version' => $version },
            log => "version<$value>",
         }
      if $value ne $version;
   return;
}

1;
