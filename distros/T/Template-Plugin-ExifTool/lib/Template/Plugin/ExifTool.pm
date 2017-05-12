package Template::Plugin::ExifTool;

use strict;
use base qw(Template::Plugin);
use vars qw($VERSION $AUTOLOAD);
$VERSION = '0.01';

use Template::Plugin;
use Image::ExifTool;

sub new {
    my ($class, $context, $file, @params) = @_;
    return $class->error("file is not specified") unless $file;
    return $class->error("$file: No such file") unless -e $file;

    my $exiftool = Image::ExifTool->new;
    my $info = $exiftool->ImageInfo($file, @params);
    bless {
	_CONTEXT  => $context,
	_exiftool => $exiftool,
	_info     => $info,
    }, $class;
}

sub info { shift->{_info} }

sub AUTOLOAD {
    my $self = shift;
    (my $meth = $AUTOLOAD) =~ s/.*:://;

    if (exists $self->{_info}->{$meth}) {
        return $self->{_info}->{$meth} ;
    }
    elsif ($self->{_exiftool}->can($meth)) {
        return $self->{_exiftool}->$meth(@_);
    }
    else {
	return;
    }
}

1;

__END__

=head1 NAME

Template::Plugin::ExifTool - Interface to Image::ExifTool Module

=head1 SYNOPSIS

  [% # filepath is full path of image file. %]
  [% USE image = ExifTool(filepath) %]

  [% # Return meta information for 2 tags only %]
  [% USE image = ExifTool(filepath, 'tag1', 'tag2') %]

  [% # get hash of meta information from an image %]
  [% FOREACH info = image.info %]
  [% info.key %] => [% info.value %]
  [% END %]

  [% # using ExifTool methods %]
  [% image.GetValue(tag, type) %]
  [% image.GetDescription(tag) %]
  ...

=head1 DESCRIPTION

Template::Plugin::ExifTool is interface to Image::ExifTool Module.

=head1 METHODS

=over 4

=item info

Return hash of meta information tag names/values from an image.
This return value is same as Image::ExifTool::ImageInfo.

  [% image.info %]

=item Using Image::ExifTool methods

It can use methods of Image::ExifTool.
Get the value of specified tag.

  [% image.GetValue(tag, type) %]

Get the description for specified tag.

  [% image.GetDescription(tag) %]

...

=back

=head1 AUTHOR

Author E<lt>kurihara@cpan.orgE<gt>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<Image::ExifTool>, L<Template::Plugin>

=cut
