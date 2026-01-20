use v5.26; ## no critic(ProhibitVersionStrings)
package PawsX::S3::Uploader;
use strict;
use warnings;
use Feature::Compat::Class 0.07;
use Feature::Compat::Try 0.05;
use builtin::compat 0.003003 qw(true false);
use Carp ();

class PawsX::S3::Uploader;

our $VERSION = '0.0.2'; # VERSION
# ABSTRACT: upload to S3 from a streaming source


# aws doesn't want small multiparts
sub MULTIPART_MIN_SIZE { 5*1024*1024 }


field $s3               :param;
field $bucket           :param;
field $key              :param;
field $min_part_size    :param = MULTIPART_MIN_SIZE;
field $_under_testing   :param = false;
field $extra_arguments  :param = {};
field $always_multipart :param = false;
field $callback         :param = undef;

field $output :reader;
    
field $upload_id;
field @parts;
field $part_body = '';
field $aborted = false;

## no critic(RequireEndWithOne) # critic gets confused

ADJUST {
    if (!$_under_testing && $min_part_size < MULTIPART_MIN_SIZE) {
        $min_part_size = MULTIPART_MIN_SIZE;
    }
}

method _maybe_callback($op, $details) {
    return unless $callback;
    $callback->($op, $details);
}

method _start_multipart() {
    my $upload = $s3->CreateMultipartUpload(
        $extra_arguments->%*,
        Bucket => $bucket,
        Key    => $key,
    );
    $upload_id = $upload->UploadId;

    $self->_maybe_callback(start_multipart => { upload_id => $upload_id });
}


method _upload_part() {
    my $part_number = 1+@parts;

    try {
        my $part_res = $s3->UploadPart(
            Body       => $part_body,
            Bucket     => $bucket,
            Key        => $key,
            PartNumber => $part_number,
            UploadId   => $upload_id,
        );
        push @parts, {
            PartNumber => $part_number,
            ETag       => $part_res->ETag,
        };
        $self->_maybe_callback(upload_part => {
            size        => length($part_body),
            part_number => $part_number,
        });
    }
    catch ($e) {
        $self->abort({
            size        => length($part_body),
            part_number => $part_number,
        });
        die $e; ## no critic(RequireCarping)
    }
}

method _complete_multipart() {
    $output = $s3->CompleteMultipartUpload(
        Bucket          => $bucket,
        Key             => $key,
        UploadId        => $upload_id,
        MultipartUpload => { Parts => \@parts },
    );
    $self->_maybe_callback(complete_multipart => {});
}

method _put_object() {
    $output = $s3->PutObject(
        $extra_arguments->%*,
        Body   => $part_body,
        Bucket => $bucket,
        Key    => $key,
    );
    $self->_maybe_callback(put_object => { size => length($part_body) });
}


method add($body) {
    Carp::croak('Upload already completed') if $output;
    Carp::croak('Upload aborted') if $aborted;

    # accumulate
    $part_body .= $body;

    $self->_maybe_callback(add => { size => length($body) });

    if (length($part_body) >= $min_part_size) {
        $self->_start_multipart() unless $upload_id;
        $self->_upload_part();
        $part_body = '';
    }
}


method finish() {
    Carp::croak('Upload already completed') if $output;
    Carp::croak('Upload aborted') if $aborted;

    if ($upload_id) {
        $self->_upload_part() if length($part_body);
        $self->_complete_multipart();
    } elsif ($always_multipart) {
        $self->_start_multipart();
        $self->_upload_part();
        $self->_complete_multipart();
    } else {
        $self->_put_object();
    }

    $self->_maybe_callback(finish => { output => $output });

    return $output;
}


method abort($details={}) {
    Carp::croak('Upload already completed') if $output;

    # pretend we can abort more than once
    return if $aborted;

    # if we haven't started the multipart upload, there's nothing to abort
    if ($upload_id) {
        $s3->AbortMultipartUpload(
            Bucket   => $bucket,
            Key      => $key,
            UploadId => $upload_id,
        );
    }

    $aborted = true;
    $self->_maybe_callback(abort_multipart => $details);
}


method upload_fh($fh) {
    my ($part, $done) = ('',false);

    while (!$done) {
        my $size = sysread $fh, $part, $min_part_size;
        if (!defined $size) {
            my $error = $!;
            $self->abort({ error => $error });
            Carp::croak("sysread failed: $error");
        }

        $self->add($part) if $size > 0;
        $part='';
        $done = $size==0;
    }

    return $self->finish;
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

PawsX::S3::Uploader - upload to S3 from a streaming source

=head1 VERSION

version 0.0.2

=head1 SYNOPSIS

    use Paws;
    use PawsX::S3::Uploader;
    use Feature::Compat::Try; # or a recent perl

    my $s3 = Paws->service(S3 => ( region => 'eu-west-1' ));

    my $uploader = PawsX::S3::Uploader->new(
        s3     => $s3,
        bucket => 'my-bucket',
        key    => 'my-object-key',

        # optional, anything that PutObject and CreateMultipartUpload
        # can understand
        extra_arguments => {
            ServerSideEncryption => 'aws:kms',
            SSEKMSKeyId          => 'the-secret-key-id',
            Metadata             => { foo => 'bar' },
            Tagging              => 'foo=bar&baz=3',
        }
    );

    try {
        while (my $block = read_data_from_somewhere()) {
            $uploader->add($block);
        }

        $uploader->finish;
    }
    catch ($error) {
        # if `read_data_from_somewhere` can throw, you need to abort
        # the upload yourself
        $uploader->abort();

        warn $error;
    }

=head1 DESCRIPTION

This class automates uploading objects to AWS S3 via L<Paws>, for the
cases where you can't keep the whole data in memory, or you can't even
generate it all ahead of time.

Underneath, it uses L<< C<PutObject>|Paws::S3::PutObject >> for
objects smaller than 5MB, and L<<
C<CreateMultipartUpload>|Paws::S3::CreateMultipartUpload >> / L<<
C<UploadPart>|Paws::S3::UploadPart >> / L<<
C<CompleteMultipartUpload>|Paws::S3::CompleteMultipartUpload >> for
larger objects.

Exceptions in C<UploadPart> cause the upload to be L<aborted|/abort>,
and the exception is re-thrown (so you can trap it yourself if you
need to). You should also explicitly L<abort|/abort> the upload if
something goes wrong in your own code.

=head1 ATTRIBUTES

=head2 C<s3>

Required, a L<< C<Paws::S3> >> object.

=head2 C<bucket>

Required, the S3 bucket to upload to.

=head2 C<key>

Required, the object key to use.

=head2 C<extra_arguments>

Optional hashref, its contents will be passed to C<PutObject> or
C<CreateMultipartUpload>.

=head2 C<min_part_size>

Optional integer, the minimum size for a part. Defaults to 5MB because
uploading smaller parts via C<UploadPart> fails with an "Entity too
small" error.

You can set a larger value to reduce the number of requests. If you
try setting a value smaller than 5MB, your value will be ignored.

=head2 C<always_multipart>

Optional boolean, defaults to false. If true, the uploader will do a
multipart upload even for objects smaller than C<min_part_size>. This
may be useful if the credentials you're using don't allow C<PutObject>
but allow the other methods.

=head2 C<callback>

Optional coderef, a progress callback. See L</Progress tracking>,
below.

=head1 METHODS

=head2 C<add>

    $uploader->add($some_data);

Appends the given string to the object being uploaded. You keep adding
data until you're done, then call L<< /C<finish> >>.

This method can die with any exception that L<<
C<CreateMultipartUpload>|Paws::S3::CreateMultipartUpload >> or L<<
C<UploadPart>|Paws::S3::UploadPart >> can throw. In that case, L<<
/C<abort> >> will be called automatically, because the multipart
upload cannot continue.

This method will also die if you call it after L<< /C<finish> >> or
after L<< /C<abort> >>: you can't re-use uploader objects, you need to
create one for each upload.

=head2 C<finish>

    my $output = $uploader->finish();

Completes the upload, once all the data has been L<added|/add>.

This method can die with any exception that L<<
C<PutObject>|Paws::S3::PutObject >>, L<<
C<CreateMultipartUpload>|Paws::S3::CreateMultipartUpload >>, L<<
C<UploadPart>|Paws::S3::UploadPart >>, or L<<
C<CompleteMultipartUpload>|Paws::S3::CompleteMultipartUpload >> can
throw.

It will also die if you call it more than once or after L<< /C<abort>
>>: you can't re-use uploader objects, you need to create one for each
upload.

This method returns the Paws response object for the whole upload,
either a L<< C<Paws::S3::PutObjectOutput> >> or L<<
C<Paws::S3::CompleteMultipartUploadOutput> >>. After this method
returns, the same value is also available via the L<< /C<output> >>
method.

=head2 C<abort>

    $uploader->abort();

If, for whatever reason, you cannot complete the upload, you should
call this method. It will call L<<
C<AbortMultipartUpload>|Paws::S3::AbortMultipartUpload >> and free up
the resources in AWS that were created by L<<
C<CreateMultipartUpload>|Paws::S3::CreateMultipartUpload >>.

This method gets called automatically if L<<
C<UploadPart>|Paws::S3::UploadPart >> died inside L<< /C<add> >>.

It's safe to call this method multiple times on the same uploader
object, and even if no multipart upload was actually started, so you
don't have to worry about the internal state of the uploader: if you
caught an exception, or your code can't complete the upload, you call
C<abort> and it will do (or not do) what's needed.

This method I<will> die if you call it after L<< /C<finish> >>,
though.

=head2 C<output>

Once an upload is L<finished|/finish>, this method returns the Paws
response object for the whole upload, either a L<<
C<Paws::S3::PutObjectOutput> >> or L<<
C<Paws::S3::CompleteMultipartUploadOutput> >>. It's the same value
that was returned by C<finish>.

=head2 C<upload_fh>

    my $output = $uploader->upload_fh($filehandle);

Uploads all data from the filehandle. This is a shortcut method that
repeatedly reads data from the given filehandle, L<adds|/add> it to
the upload, and L<finishes|/finish> once it reaches end-of-file.

=for Pod::Coverage MULTIPART_MIN_SIZE new

=head1 Progress tracking

If you provide a L</callback> to the constructor, it will be called
whenever the uploader does something. It will receive 2 arguments: a
string identifying the event, and a hashref with some details. These
are the events:

=over 4

=item *

C<< add => { size => ... } >>

=item *

C<< start_multipart => { upload_id => ... } >>

=item *

C<< upload_part => { size => ..., part_number => ... } >>

=item *

C<< complete_multipart => {} >>

=item *

C<< abort_multipart => { size => ..., part_number => ... } >>

=item *

C<< put_object => { size => ... } >>

=item *

C<< finish => { ouput => ... } >>

=back

The C<finish> event provides the same output as returned by L<<
/C<finish> >> and L<< /C<output> >>.

=head1 AUTHOR

Gianni Ceccarelli <gceccarelli@veritone.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Veritone Hire.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
