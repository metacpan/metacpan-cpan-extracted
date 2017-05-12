package SWFEditor;

use 5.008;
use strict;
use warnings;

use Carp;

our $VERSION       = '0.09';
our $SWFED_VERSION = '0.61';

require XSLoader;
XSLoader::load('SWFEditor', $VERSION);

# Preloaded methods go here.

sub new {
    my ($class) = @_;
    my $self = bless {}, $class;
    _swf_object_open($self);
    return $self;
}

sub DESTROY {
    my $self = shift;
    _swf_object_close($self);
}

our $SHAPE_BITMAP_NONE           = 0;
our $SHAPE_BITMAP_MATRIX_RESCALE = 1;
our $SHAPE_BITMAP_RECT_RESIZE    = 2;
our $SHAPE_BITMAP_TYPE_TILLED    = 4;

sub input {
    my $self = shift;
    my $data = shift;
    return $self->_input(_load($data));
}

sub replace_movie_clip {
    my $self             = shift;
    my $instance_name    = shift;
    my $data             = shift;
    my $unused_cid_purge = shift || 1;
    return $self->_replace_movie_clip(
        $instance_name,
        _load($data),
        $unused_cid_purge,
    );
}

sub replace_png_data {
    my $self     = shift;
    my $image_id = shift;
    my $data     = shift;
    my $opts     = shift;
    return $self->_replace_png_data(
        $image_id,
        _load($data),
        $opts,
    );
}

sub set_shape_adjust_mode_none {
    my $self = shift;
    $self->set_shape_adjust_mode($SHAPE_BITMAP_NONE);
}

sub set_shape_adjust_mode_matrix_rescale {
    my $self = shift;
    $self->set_shape_adjust_mode($SHAPE_BITMAP_MATRIX_RESCALE);
}

sub set_shape_adjust_mode_rect_resize {
    my $self = shift;
    $self->set_shape_adjust_mode($SHAPE_BITMAP_RECT_RESIZE);
}

sub set_shape_adjust_mode_type_tilled {
    my $self = shift;
    $self->set_shape_adjust_mode($SHAPE_BITMAP_TYPE_TILLED);
}

sub replace_shape_data {
    my $self = shift;
    my $cid  = shift;
    my $data = shift;
    return $self->_replace_shape_data($cid, _load($data));
}

sub replace_gif_data {
    my $self     = shift;
    my $image_id = shift;
    my $data     = shift;
    return $self->_replace_gif_data(
        $image_id,
        _load($data),
    );
}

sub replace_jpeg_data {
    my $self       = shift;
    my $image_id   = shift;
    my $data       = shift;
    my $alpha_data = shift;

    my $alpha_data_len = 0;

    if ($alpha_data) {
        ($alpha_data, $alpha_data_len) = _load($alpha_data);
    } else {
        ($alpha_data, $alpha_data_len) = (0, 0);
    }

    return $self->_replace_jpeg_data(
        $image_id,
        _load($data),
        $alpha_data,
        $alpha_data_len,
    );
}

sub replace_bitmap_data {
    my $self       = shift;
    my $image_cond = shift;
    my $data       = shift;
    my $alpha_data = shift;
    my $opts       = shift;

    my $alpha_data_len = 0;

    if ($alpha_data) {
        ($alpha_data, $alpha_data_len) = _load($alpha_data);
    } else {
        ($alpha_data, $alpha_data_len) = (0, 0);
    }
    return $self->_replace_bitmap_data(
        $image_cond,
        _load($data),
        $alpha_data,
        $alpha_data_len,
        $opts,
    );
}

sub replace_tag_data {
    my $self  = shift;
    my $seqno = shift;
    my $data  = shift;
    return $self->_replace_tag_data(
        $seqno,
        _load($data),
    );
}

sub replace_tag_data_by_cid {
    my $self = shift;
    my $cid  = shift;
    my $data = shift;
    return $self->_replace_tag_data_by_cid(
        $cid,
        _load($data),
    );
}

sub replace_tag_contents_by_cid {
    my $self = shift;
    my $cid  = shift;
    my $data = shift;
    return $self->_replace_tag_contents_by_cid(
        $cid,
        _load($data),
    );
}

sub is_shape_tag_data {
    my $self = shift;
    my $data = shift;
    return $self->_is_shape_tag_data(
        _load($data),
    );
}

sub is_bitmap_tag_data {
    my $self = shift;
    my $data = shift;
    return $self->_is_bitmap_tag_data(
        _load($data),
    );
}

sub print_tag_data {
    my $self = shift;
    my $data = shift;
    return $self->_print_tag_data(_load($data));
}

sub remove_tag {
    my $self = shift;
    my $tag_seqno           = shift ||  0;
    my $tag_seqno_in_sprite = shift || -1;
    return $self->_remove_tag($tag_seqno, $tag_seqno_in_sprite);
}

sub replace_mld_data {
    my $self     = shift;
    my $sound_id = shift;
    my $data     = shift;
    return $self->_replace_mld_data (
        $sound_id,
        _load($data),
    );
}

sub _load {
    my $input = shift;
    if (ref($input) eq 'SCALAR') {
        my $data = $$input;
        return ($data, length $data);
    }
    open my $fh, $input or croak "Can't open file \"$input\" : $!";
    my $data = do { local $/; <$fh> };
    close $fh;
    return ($data, length $data);
}

1;

__END__

=pod

=head1 NAME

SWFEditor - SWFEditor for Perl

=head1 SYNOPSIS

    use SWFEditor;

    # case: file path
    my $swfed = SWFEditor->new();
    $swfed->input('resource/negimiku.swf');
    $swfed->replace_movie_clip('miku', 'resource/saitama3.swf');
    print $swfed->output();

    # case: binary data
    my $data1 = do {local $/; <$fh>};
    my $data2 = do {local $/; <$fh>};
    my $swfed = SWFEditor->new();
    $swfed->input(\$data1);
    $swfed->replace_movie_clip('miku', \$data2);
    print $swfed->output();

=head1 DESCRIPTION

This module is perl binding of SWF Editor.

More description: L<http://sourceforge.jp/projects/swfed/wiki/FrontPage>

=head1 METHODS

Implemented function list

=head2 i/o

=over

=item $swfed->input(string $swfdata)

=item $swfed->output()

=back

=head2 dump

=over

=item $swfed->swf_info()

=item $swfed->get_tag_list()

=item $swfed->get_tag_detail(int $seqno)

=back

=head2 header

=over

=item $swfed->get_header_info()

=item $swfed->set_header_info(hashref \%header_info)

=back

=head2 tag

=over

=item $swfed->get_tag_data(int $seqno)

=item $swfed->get_tag_data_by_cid(int $cid)

=item $swfed->replace_tag_data(int $seqno, string $data)

=item $swfed->replace_tag_data_by_cid(int $cid, string $data)

=item $swfed->get_tag_contents_by_cid(int $cid)

=item $swfed->replace_tag_contents_by_cid(int $cid, string $data)

=item $swfed->is_shape_tag_data(string $data)

=item $swfed->is_bitmap_tag_data(string $data)

=item $swfed->print_tag_data(string $tagdata)

=item $swfed->remove_tag(int $tag_seqno, int $tag_seqno_in_sprite)

=back

=head2 sprite

=over

=item $swfed->replace_movie_clip(string $instance_name, string $swfdata, int $unused_cid_purge = 1)

=back

=head2 shape

=over

=item $swfed->get_shape_data(int $shape_id)

=item $swfed->replace_shape_data(int $shape_id, string $shapedata)

=item $swfed->set_shape_adjust_mode($int mode)

=item $swfed->set_shape_adjust_mode_none()

=item $swfed->set_shape_adjust_mode_matrix_rescale()

=item $swfed->set_shape_adjust_mode_rect_resize()

=item $swfed->set_shape_adjust_mode_type_tilled()

=back

=head2 image

=over

=item $swfed->get_jpeg_data(int $image_id)

=item $swfed->get_jpeg_alpha(int $image_id)

=item $swfed->get_png_data(int $image_id)

=item $swfed->replace_bitmap_data(hashref \%image_cond | $image_id, string $bitmapdata, string $alphadata = undef, hashref \%opts | int $without_converting)

=item $swfed->replace_png_data($image_id, $pngdata)

=item $swfed->replace_gif_data($image_id, $gifdata)

=item $swfed->replace_jpeg_data($image_id, $jpegdata)

=item $swfed->get_bitmap_size(int $image_id)

=back

=head2 text

=over

=item $swfed->get_edit_string(string $variable_name | int $edit_id)

=item $swfed->replace_edit_string(string $variable_name | int $edit_id, string $text)

=back

=head2 sound

=over

=item $swfed->get_sound_data(int $sound_id)

=item $swfed->replace_mld_data(int $sound_id, string $mlddata)

=back

=head2 action

=over

=item $sefed->get_action_data(int $tag_seqno)

=item $swfed->set_action_variables(hashref \%replace_key_value_pair)

=item $swfed->replace_action_strings(hashref \%replace_key_values_pair)

=back

=head2 misc

=over

=item $swfed->set_compress_level(int $level)

=item $swfed->purge_unless_contents()

=item $swfed->rebuild()

=back

=head1 SEE ALSO

SWF Editor for PHP: L<http://sourceforge.jp/projects/swfed/>

=head1 RESOURCES

REPOSITORY: L<https://github.com/mix3/p5-SWFEditor/>

=head1 AUTHOR

Wataru Seto(mix3) E<lt>himachocost333@gmail.comE<gt>

=cut
