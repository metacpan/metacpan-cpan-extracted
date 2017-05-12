package Plack::App::DataSection;
use strict;
use warnings;
our $VERSION = '0.05';

use parent qw/Plack::Component/;
use MIME::Base64;
use Data::Section::Simple;
use Plack::MIME;
use HTTP::Date;

use Plack::Util::Accessor qw(encoding);

sub call {
    my $self = shift;
    my $env  = shift;

    my $path = $env->{PATH_INFO} || '';
    if ($path =~ /\0/) {
        return $self->return_400;
    }
    $path =~ s!^/!!;

    my ($data, $content_type) = $path ? $self->get_content($path) : ();

    return $self->return_404 unless $data;

    return [ 200, [
        'Content-Type'   => $content_type,
        'Content-Length' => length($data),
        'Last-Modified'  => $self->last_modified,
    ], [ $data ] ];
}

sub return_400 {
    my $self = shift;
    return [400, ['Content-Type' => 'text/plain', 'Content-Length' => 11], ['Bad Request']];
}

sub return_404 {
    my $self = shift;
    return [404, ['Content-Type' => 'text/plain', 'Content-Length' => 9], ['not found']];
}

sub data_section {
    my $self = shift;

    $self->{_reader} ||= Data::Section::Simple->new(ref $self);
}

sub get_data_section {
    my ($self, $path) = @_;
    $self->{_data_section_hash} ||= $self->data_section->get_data_section;
    if ($path) {
        $self->{_data_section_hash}{$path};
    }
    else {
        $self->{_data_section_hash};
    }
}

sub _cache { shift->{_cache} ||= {} }

sub get_content {
    my ($self, $path) = @_;

    my $mime_type = Plack::MIME->mime_type($path);
    my $is_binary = is_binary($mime_type);

    unless ($is_binary) {
        my $encoding = $self->encoding || 'utf-8';
        $mime_type .= "; charset=$encoding";
    }

    my $content = $self->_cache->{$path} ||= do {
        my $content = $self->get_data_section($path);
        $content = decode_base64($content) if $content && $is_binary;
        $content;
    };

    ($content, $mime_type);
}

sub is_binary {
    my $mime_type = shift;

    $mime_type !~ /\b(?:text|xml|javascript|json)\b/;
}

sub last_modified {
    my $self = shift;

    $self->{last_modified} ||= do {
        my $mod = ref $self;
        $mod =~ s!::!/!g;
        $mod .= '.pm';
        my $full_path = $INC{$mod};

        my @stat = stat $full_path;
        HTTP::Date::time2str( $stat[9] )
    };
}

sub dump_dir {
    my ($self, $dir) = @_;
    require Errno;
    require Path::Class;

    my %data_section = %{ $self->get_data_section };
    my $base_dir = Path::Class::Dir->new($dir);

    $base_dir->mkpath or $! != Errno::EEXIST() or die "failed to create dir:$base_dir:$!";

    for my $key (keys %data_section) {
        my ($content) = $self->get_content($key);

        $key =~ s!^/!!g;
        my ($sub_dir, $file) = $key =~ m!^(.*?)([^/]+)$!;

        my $dir_path = $base_dir;
        if ($sub_dir) {
            $dir_path = $dir_path->subdir($sub_dir);
            $dir_path->mkpath or $! != Errno::EEXIST() or die "failed to create dir:$dir_path:$!";
        }

        $file = $dir_path->file($file);
        my $fh = $file->openw;
        $fh->print($content);
    }
}

1;
__DATA__
@@ sample.txt
さんぷる

__END__

=head1 NAME

Plack::App::DataSection - psgi application for serving contents in data section

=head1 SYNOPSIS

  # create your module from directory.
  % dir2data_section.pl --dir=dir/ --module=Your::Module

  # generated module is like this.
  package Your::Module;
  use parent qw/Plack::App::DataSection/;
  __DATA__
  @@ index.html
  <html>
  ...

  # app.psgi
  use Your::Module;
  Your::Module->new->to_app;

  # you can get contents in data section
  % curl http://localhost:5000/index.thml

=head1 DESCRIPTION

Plack::App::DataSection is psgi application for serving contents in data section.

Inherit this module and you can easily create psgi application for serving contents in data section.

You can even serve binary contents!


=head1 AUTHOR

Masayuki Matsuki E<lt>y.songmu@gmail.comE<gt>

=head1 SEE ALSO

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
