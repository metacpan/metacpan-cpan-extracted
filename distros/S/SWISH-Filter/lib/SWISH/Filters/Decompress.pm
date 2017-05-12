package SWISH::Filters::Decompress;
use strict;
use warnings;
use Carp;
use vars qw( $VERSION @ISA );
$VERSION = '0.191';
@ISA     = ('SWISH::Filters::Base');
use SWISH::Filter::MIMETypes;

my %mimes = (
    'application/x-gzip' => 'gz',

    # deferred till we have way to deal with
    # multiple docs in single file
    #'application/x-compress' => 'zip',
);

my %ext = reverse %mimes;

sub new {
    my $class = shift;
    my $self = bless( {}, $class );
    my $ok;

    $self->{type} = 1;

    $self->{_mimetypes} = SWISH::Filter::MIMETypes->new;

    # set mimetypes etc. based on which modules/programs we have
    # preference is to use Perl lib over binary cmd
    if ( $self->use_modules(qw/ Compress::Zlib /) ) {
        push( @{ $self->{mimetypes} }, qr!$ext{gz}! );
        $self->{gz}->{perl}++;
        $ok++;
    }
    elsif ( $self->find_binary('gunzip') ) {
        $self->set_programs('gunzip');
        push( @{ $self->{mimetypes} }, qr!$ext{gz}! );
        $self->{gz}->{bin}++;
        $ok++;
    }

    #    if ($self->use_modules(qw/ Archive::Zip /))
    #    {
    #        push(@{$self->{mimetypes}}, qr!$ext{zip}!);
    #        $self->{zip}->{perl}++;
    #        $ok++;
    #    }
    #    elsif ($self->find_binary('unzip'))
    #    {
    #        $self->set_programs('unzip');
    #        push(@{$self->{mimetypes}}, qr!$ext{zip}!);
    #        $self->{zip}->{bin}++;
    #        $ok++;
    #    }

    return $ok ? $self : undef;
}

# TODO
sub zipinfo {
    my $self  = shift;
    my $zfile = shift or croak "need zipfile";
    my $i     = $self->run_program( 'unzip', "-Z -1 $zfile" );
    return split( /\n/, $i || '' );
}

sub get_type {
    my ( $self, $doc ) = @_;
    ( my $name = $doc->name ) =~ s/\.(gz|zip)$//i;
    $self->mywarn(" decompress: getting mime for $name");
    return $self->{_mimetypes}->get_mime_type($name);
}

sub decompress {
    my ( $self, $doc ) = @_;

    my ( $buf, $status );

    if ( $self->{gz}->{perl} ) {
        my $r = $doc->fetch_doc_reference;
        $buf = Compress::Zlib::memGunzip($r);
    }
    elsif ( $self->{gz}->{bin} ) {
        $buf = $self->run_program( 'gunzip', '-c', $doc->fetch_filename );
    }

    $self->mywarn(" decompress: $doc was decompressed");

    #$self->mywarn(ref($buf) ? $$buf : $buf);

    # TODO .zip support

    # return a scalar ref
    return ref($buf) ? $buf : \$buf;
}

sub filter {
    my ( $self, $doc ) = @_;

    my $buf = $self->decompress($doc);    # returns scalar ref

    return undef unless $$buf;

    my $mime = $self->get_type($doc);

    $self->mywarn(
        " decompress: " . $doc->name . " is now flagged as $mime" );

    $doc->set_content_type($mime);
    $doc->set_continue(1);

    # return the document
    return ( $buf, $doc->meta_data );
}

1;

__END__

=head1 NAME

SWISH::Filters::Decompress - deflate your compressed files for further filtering

=head1 DESCRIPTION

SWISH::Filters::Decompress is a B<type 1> Filter designed to come first in a chain
of filters. The Decompress filter can handle C<.gz> files, using either the relevant
Perl module or binary command.

=head1 LIMITATIONS

I<.zip> files are B<not> currently supported because they might contain multiple
files. The current plan is to restructure SWISH::Filter to allow for a single
returned document composed of multiple files (as with .zip and .tar files).

=head1 AUTHOR

Peter Karman C<perl@peknet.com>

Thanks to Atomic Learning Inc. for supporting the development of this module.

=head1 COPYRIGHT

This library is free software; you can redistribute it
and/or modify it under the same terms as Perl itself.


=head1 SEE ALSO

L<SWISH::Filter>,
gzip,
zip,
L<Compress::Zlib>,
L<Archive::Zip>
