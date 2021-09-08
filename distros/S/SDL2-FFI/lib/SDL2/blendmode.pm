package SDL2::blendmode 0.01 {
    use SDL2::Utils;
    #
    enum
        SDL_BlendMode => [
        [ SDL_BLENDMODE_NONE    => 0x00000000 ],
        [ SDL_BLENDMODE_BLEND   => 0x00000001 ],
        [ SDL_BLENDMODE_ADD     => 0x00000002, ],
        [ SDL_BLENDMODE_MOD     => 0x00000004, ],
        [ SDL_BLENDMODE_MUL     => 0x00000008, ],
        [ SDL_BLENDMODE_INVALID => 0x7FFFFFFF ]
        ],
        SDL_BlendOperation => [
        [ SDL_BLENDOPERATION_ADD          => 0x1 ],
        [ SDL_BLENDOPERATION_SUBTRACT     => 0x2 ],
        [ SDL_BLENDOPERATION_REV_SUBTRACT => 0x3 ],
        [ SDL_BLENDOPERATION_MINIMUM      => 0x4 ],
        [ SDL_BLENDOPERATION_MAXIMUM      => 0x5 ]
        ],
        SDL_BlendFactor => [
        [ SDL_BLENDFACTOR_ZERO                => 0x1 ],
        [ SDL_BLENDFACTOR_ONE                 => 0x2 ],
        [ SDL_BLENDFACTOR_SRC_COLOR           => 0x3 ],
        [ SDL_BLENDFACTOR_ONE_MINUS_SRC_COLOR => 0x4 ],
        [ SDL_BLENDFACTOR_SRC_ALPHA           => 0x5 ],
        [ SDL_BLENDFACTOR_ONE_MINUS_SRC_ALPHA => 0x6 ],
        [ SDL_BLENDFACTOR_DST_COLOR           => 0x7 ],
        [ SDL_BLENDFACTOR_ONE_MINUS_DST_COLOR => 0x8 ],
        [ SDL_BLENDFACTOR_DST_ALPHA           => 0x9 ],
        [ SDL_BLENDFACTOR_ONE_MINUS_DST_ALPHA => 0xA ]
        ];
    attach blendmode => {
        SDL_ComposeCustomBlendMode => [
            [   'SDL_BlendFactor',    'SDL_BlendFactor',
                'SDL_BlendOperation', 'SDL_BlendFactor',
                'SDL_BlendFactor',    'SDL_BlendOperation'
            ],
            'SDL_BlendMode'
        ],
    };

=encoding utf-8

=head1 NAME

SDL2::blendmode - SDL2 BlendMode Enumerations and Declarations

=head1 SYNOPSIS

    use SDL2 qw[:blendMode];

=head1 DESCRIPTION

SDL2::blendmode

=head1 Functions

These may be imported by name or with the C<:blendMode> tag.

=head2 C<SDL_ComposeCustomBlendMode( ... )>

Compose a custom blend mode for renderers.

A blend mode controls how the pixels from a drawing operation (source) get
combined with the pixels from the render target (destination). First, the
components of the source and destination pixels get multiplied with their blend
factors. Then, the blend operation takes the two products and calculates the
result that will get stored in the render target.

Expressed in pseudocode, it would look like this:

    $dstRGB = colorOperation( $srcRGB * $srcColorFactor, $dstRGB * $dstColorFactor );
    $dstA   = alphaOperation( $srcA * $srcAlphaFactor, $dstA * $dstAlphaFactor );

Where the functions C<colorOperation( $src, $dst)> and C<alphaOperation( $src,
$dst )> can return one of the following:

=over

=item - C<$src + $dst>

=item - C<$src - $dst>

=item - C<$dst - $src>

=item - C<min($src, $dst)>

=item - C<max($src, $dst)>

=back

The red, green, and blue components are always multiplied with the first,
second, and third components of the C<SDL_BlendFactor>, respectively. The
fourth component is not used.

The alpha component is always multiplied with the fourth component of the
C<SDL_BlendFactor>. The other components are not used in the alpha calculation.

Support for these blend modes varies for each renderer. To check if a specific
C<SDL_BlendMode> is supported, create a renderer and pass it to either
C<SDL_SetRenderDrawBlendMode> or C<SDL_SetTextureBlendMode>. They will return
with an error if the blend mode is not supported.

This list describes the support of custom blend modes for each renderer in SDL
2.0.6. All renderers support the four blend modes listed in the
C<SDL_BlendMode> enumeration.

=over

=item B<direct3d>: Supports C<SDL_BLENDOPERATION_ADD> with all factors.

=item B<direct3d11>: Supports all operations with all factors. However, some factors produce unexpected results with C<SDL_BLENDOPERATION_MINIMUM> and C<SDL_BLENDOPERATION_MAXIMUM>.

=item B<opengl>: Supports the C<SDL_BLENDOPERATION_ADD> operation with all factors. OpenGL versions 1.1, 1.2, and 1.3 do not work correctly with SDL 2.0.6.

=item B<opengles>: Supports the C<SDL_BLENDOPERATION_ADD> operation with all factors. Color and alpha factors need to be the same. OpenGL ES 1 implementation specific: May also support C<SDL_BLENDOPERATION_SUBTRACT> and C<SDL_BLENDOPERATION_REV_SUBTRACT>. May support color and alpha operations being different from each other. May support color and alpha factors being different from each other.

=item B<opengles2>: Supports the C<SDL_BLENDOPERATION_ADD>, C<SDL_BLENDOPERATION_SUBTRACT>, C<SDL_BLENDOPERATION_REV_SUBTRACT> operations with all factors.

=item B<psp>: No custom blend mode support.

=item B<software>: No custom blend mode support.

=back

Some renderers do not provide an alpha component for the default render target.
The C<SDL_BLENDFACTOR_DST_ALPHA> and C<SDL_BLENDFACTOR_ONE_MINUS_DST_ALPHA>
factors do not have an effect in this case.

Expected parameters include:

=over

=item C<srcColorFactor> - the SDL_BlendFactor applied to the red, green, and blue components of the source pixels

=item C<dstColorFactor> - the SDL_BlendFactor applied to the red, green, and blue components of the destination pixels

=item C<colorOperation> - the SDL_BlendOperation used to combine the red, green, and blue components of the source and destination pixels

=item C<srcAlphaFactor> - the C<SDL_BlendFactor> applied to the alpha component of the source pixels

=item C<dstAlphaFactor> - the C<SDL_BlendFactor> applied to the alpha component of the destination pixels

=item C<alphaOperation> - the C<SDL_BlendOperation> used to combine the alpha component of the source and destination pixels

=back

Returns an C<SDL_BlendMode> that represents the chosen factors and operations.

=head1 Defined Values and Enumerations

These may be imported by name.

=head2 C<SDL_BlendMode>

The blend mode used in C<SDL_RenderCopy( )> and drawing operations. These may
be imported by name or with the C<:blendMode> tag.

=over

=item C<SDL_BLENDMODE_NONE> - no blending

    dstRGBA = srcRGBA

=item C<SDL_BLENDMODE_BLEND> - alpha blending

    dstRGB = (srcRGB * srcA) + (dstRGB * (1-srcA))
    dstA = srcA + (dstA * (1-srcA))

=item C<SDL_BLENDMODE_ADD> - additive blending

    dstRGB = (srcRGB * srcA) + dstRGB
    dstA = dstA

=item C<SDL_BLENDMODE_MOD> - color modulate

    dstRGB = srcRGB * dstRGB
    dstA = dstA

=item C<SDL_BLENDMODE_MUL> - color multiply

    dstRGB = (srcRGB * dstRGB) + (dstRGB * (1-srcA))
    dstA = (srcA * dstA) + (dstA * (1-srcA))

=item C<SDL_BLENDMODE_INVALID>

=back

Additional custom blend modes can be returned by L<<
C<SDL_ComposeCustomBlendMode( ... )>|/C<SDL_ComposeCustomBlendMode( ... )> >>.

=head2 C<SDL_BlendOperation>

The blend operation used when combining source and destination pixel
components. These may be imported with the C<:blendOperation> tag.

=over

=item C<SDL_BLENDOPERATION_ADD> - supported by all renderers

    dst + src

=item C<SDL_BLENDOPERATION_SUBTRACT> - supported by D3D9, D3D11, OpenGL, OpenGLES

    dst - src

=item C<SDL_BLENDOPERATION_REV_SUBTRACT> - supported by D3D9, D3D11, OpenGL, OpenGLES

    src - dst

=item C<SDL_BLENDOPERATION_MINIMUM> - supported by D3D11

    min(dst, src)

=item C<SDL_BLENDOPERATION_MAXIMUM> - supported by D3D11

    max(dst, src)

=back

=head2 C<SDL_BlendFactor>

The normalized factor used to multiply pixel components. These may be imported
with the C<:blendfactor> tag.

=over

=item C<SDL_BLENDFACTOR_ZERO> - C< 0, 0, 0, 0 >

=item C<SDL_BLENDFACTOR_ONE> - C< 1, 1, 1, 1 >

=item C<SDL_BLENDFACTOR_SRC_COLOR> - C< srcR, srcG, srcB, srcA >

=item C<SDL_BLENDFACTOR_ONE_MINUS_SRC_COLOR> - C< 1-srcR, 1-srcG, 1-srcB, 1-srcA >

=item C<SDL_BLENDFACTOR_SRC_ALPHA> - C< srcA, srcA, srcA, srcA >

=item C<SDL_BLENDFACTOR_ONE_MINUS_SRC_ALPHA> - C< 1-srcA, 1-srcA, 1-srcA, 1-srcA >

=item C<SDL_BLENDFACTOR_DST_COLOR> - C< dstR, dstG, dstB, dstA >

=item C<SDL_BLENDFACTOR_ONE_MINUS_DST_COLOR> - C< 1-dstR, 1-dstG, 1-dstB, 1-dstA >

=item C<SDL_BLENDFACTOR_DST_ALPHA> - C< dstA, dstA, dstA, dstA >

=item C<SDL_BLENDFACTOR_ONE_MINUS_DST_ALPHA> - C< 1-dstA, 1-dstA, 1-dstA, 1-dstA >

=back

=head1 LICENSE

Copyright (C) Sanko Robinson.

This library is free software; you can redistribute it and/or modify it under
the terms found in the Artistic License 2. Other copyrights, terms, and
conditions may apply to data transmitted through this module.

=head1 AUTHOR

Sanko Robinson E<lt>sanko@cpan.orgE<gt>

=begin stopwords

pseudocode opengl opengls opengles opengles2 psp OpenGLES

=end stopwords

=cut

};
1;
