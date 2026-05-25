package Protocol::Tus;
{ our $VERSION = '0.001' }
use Moo;
use v5.24;
use warnings;
use experimental qw< signatures >;

use Carp;
use Module::Runtime qw< use_module >;
use Ouch qw< :trytiny_var >;
use Protocol::Tus::Util qw< as_ouch coerce_model lc_hash
   response response_from_exception
   validate_checksum validate_id validate_length validate_tus_resumable
>;
use Scalar::Util qw< blessed >;
use Try::Catch;

use constant TUS_VERSION => '1.0.0';

sub augment_response ($response) {
   # ensure mandatory header for OK response
   $response->more_headers({ 'Tus-Resumable' => TUS_VERSION })
      unless $response->is_error;
   return $response;
}

use namespace::clean;

has model => (is => 'ro', required => 1, coerce => \&coerce_model);
has id_to_location => (is => 'ro', default => undef);

sub HTTP_request ($self, $method, $headers, $id, $body) {
   my $response;

   try {
      # honor overriding the method as per Tus spec
      $headers = lc_hash($headers);
      $method = uc($headers->{'x-http-method-override'} // $method);

      # hand over to the right sub-method
      $response =
           $method eq 'HEAD'    ? $self->HTTP_HEAD($headers, $id)
         : $method eq 'OPTIONS' ? $self->HTTP_OPTIONS
         : $method eq 'PATCH'   ? $self->HTTP_PATCH($headers, $id, $body)
         : $method eq 'POST'    ? $self->HTTP_POST($headers, $body, $id)
         : $method eq 'DELETE'  ? $self->HTTP_DELETE($headers, $id)
         : ouch 405, 'Method Not Allowed';
   }
   catch { $response = response_from_exception($_) };

   return augment_response($response);
}

# Core Protocol
sub HTTP_HEAD ($self, $headers, $id) {
   my $response;

   try {
      validate_id($id);

      $headers = lc_hash($headers);
      validate_tus_resumable($headers, TUS_VERSION);

      # collect data
      my $model = $self->model;
      my $info = $model->get_info($id) or ouch 404, 'Not Found';
      my %headers = (
         'Cache-Control' => 'no-store',
         'Upload-Offset' => $info->{offset},
      );
      if (defined(my $length = $info->{length})) {
         $headers{'Upload-Length'} = $length;
      }
      else {
         ouch 400, 'deferring length is unsupported'
            unless $model->supports_extension('creation-defer-length');
         $headers{'Upload-Defer-Length'} = 1;
      }
      $headers{'Upload-Metadata'} = $info->{metadata}
         if defined($info->{metadata});

      # return back, we use 204 because we have nothing more to add
      $response = response(
         status => 204,
         body   => '',
         headers => \%headers,
      );
   }
   catch { $response = response_from_exception($_) };
   
   return augment_response($response);
}

sub HTTP_OPTIONS ($self) {
   my $response;

   try { # not really need, yet...
      my $model = $self->model;
      my %response_headers = (
         'Tus-Extension' => $model->extensions_as_string,
         'Tus-Version' => TUS_VERSION,
      );
      my $max_size = $model->max_size;
      $response_headers{'Tus-Max-Size'} = $max_size if defined($max_size);
      $response = response(
         status => 204,
         body   => '',
         headers => \%response_headers,
      );
   }
   catch { $response = response_from_exception($_) };

   return augment_response($response);
}

sub HTTP_PATCH ($self, $headers, $id, $data) {
   my $response;

   try {
      validate_id($id);

      $headers = lc_hash($headers);
      validate_tus_resumable($headers, TUS_VERSION);

      my $model = $self->model;
      my $info = $model->get_info($id) or ouch 404, 'Not Found';

      my $args = lc_hash($headers);

      # preliminary check on the input data and congruence with any
      # expected content-length argument
      my $dref = ref($data) ? $data : defined ($data) ? \$data : \'';
      my $chunk_length = length($$dref);
      my $expected_length = $args->{'content-length'} // $chunk_length;
      $expected_length =~ m{\A(?: 0 | [1-9]\d*)\z}mxs
         or ouch 400, 'invalid header Content-Length';
      ouch 400, 'length mismatch',
         "request<$expected_length> body-length<$chunk_length>"
            if $chunk_length != $expected_length;

      my $saved_length = $info->{length};
      my $full_length = validate_length($saved_length, $args);
      if ($chunk_length > 0) { # ignore zero-length requests
         ouch 400, 'file is complete, nothing more goes'
            if $info->{complete};

         # check offsets
         my $expected_offset = $args->{'upload-offset'} // '';
         $expected_offset =~ m{\A(?: 0 | [1-9]\d*)\z}mxs
            or ouch 400, 'invalid or missing header Upload-Offset';

         my $current_offset = $info->{offset};
         ouch 409, 'offset mismatch',
               "request<$expected_offset> current<$current_offset>"
            if $current_offset != $expected_offset;

         # if we add this chunk, we will eventually have this minimum
         # amount of uploaded bytes
         my $min_uploaded = $current_offset + $chunk_length;

         # check this length against both $max_length and $full_length
         if (defined(my $max_length = $model->max_size)) {
            ouch 413, 'upload is too big', { cleanup => 1 }
               if $max_length < $min_uploaded
               || (defined($full_length) && $max_length < $full_length);

         }
         if (defined($full_length)) {
            ouch 400, 'too much data',
                  join (' ',
                     "length<$full_length>",
                     "offset<$current_offset>",
                     "chunk-length<$chunk_length>"
                  )
               if $full_length < $min_uploaded;

            $self->set_length($id, $full_length)
               unless defined($saved_length);
         }

         # take a look at the checksum, if present
         validate_checksum($dref, $args->{'upload-checksum'});

         # we have no more excuses to refuse to write incoming data
         $model->save_chunk($id, $current_offset, $dref);
      }

      my $offset = $model->get_offset($id);
      $model->finalize($id)
         if defined($full_length) && $offset >= $full_length;

      $response = response(
         status => 204,
         body   => '',
         headers => { 'Upload-Offset' => $offset },
      );
   }
   catch {
      my $e = as_ouch($_);
      eval {
         my $data = $e->data;
         $self->model->cleanup($id)
            if ref($data) eq 'HASH' && $data->{cleanup}
      };
      $response = response_from_exception($e);
   };

   return augment_response($response);
}

# Extensions
sub HTTP_POST ($self, $headers, $data, $id = undef) {
   my $response;

   try {
      ouch 405, 'Method Not Allowed' if length($id // '');

      my $args = lc_hash($headers);
      validate_tus_resumable($args, TUS_VERSION);

      # create resource allocating an identifier
      my $length = validate_length(undef, $args);
      my $metadata = $args->{'upload-metadata'};
      $id = $self->model->create_upload($length, $metadata);

      # save any data we might have received
      $args->{'upload-offset'} //= 0;
      $self->HTTP_PATCH($args, $id, $data);

      # ok, creation went fine so we have to give back the 201.
      $response = response(status => 201, id => $id);

      # if we got a callback to generate a Location header we do this,
      # otherwise the caller will have to generate it by itself using
      # $response->id
      if (defined(my $cb = $self->id_to_location)) {
         $response->headers->{Location} = $cb->($id);
      }
   }
   catch {
      my $e = $_;
      eval { $self->model->cleanup($id) if length($id // '') };
      $response = response_from_exception($e);
   };
   
   return augment_response($response);
}

sub HTTP_DELETE ($self, $headers, $id) {
   my $response;

   try {
      validate_id($id);

      $headers = lc_hash($headers);
      validate_tus_resumable($headers, TUS_VERSION);

      my $model = $self->model;
      my $info = $model->get_info($id) or ouch 404, 'Not Found';
      $model->cleanup($id);
      $response = response(
         status  => 204,
         body    => '',
         headers => {},
      );
   }
   catch { $response = response_from_exception($_) };

   return augment_response($response);
}

1;
