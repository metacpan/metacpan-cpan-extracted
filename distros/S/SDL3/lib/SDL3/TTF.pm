package SDL3::TTF v0.0.6 {
    use v5.40;
    use base 'Exporter';
    use Affix qw[:all];
    use Alien::SDL3;
    use SDL3   qw[:all];
    use Carp   qw[croak confess];
    use Config qw[%Config];

=encoding utf-8

=head1 NAME

SDL3::TTF - TrueType Font support for SDL3

=head1 SYNOPSIS

    use v5.40;
    use SDL3      qw[:all :main];
    use SDL3::TTF qw[:all];

    TTF_Init() or die SDL_GetError();

    my $font = TTF_OpenFont( 'C:/Windows/Fonts/arial.ttf', 48.0 )
        or die SDL_GetError();

    my $surface =
        TTF_RenderText_Blended( $font, 'Hello, World!', 0, { r => 255, g => 255, b => 255, a => 255 } );
    my $texture = SDL_CreateTextureFromSurface( $renderer, $surface );

    TTF_CloseFont($font);
    TTF_Quit();

=head1 DESCRIPTION

C<SDL3::TTF> binds SDL_ttf, a companion library to SDL for working with TrueType (tm) fonts.

The library is a wrapper around the FreeType and HarfBuzz libraries, allowing you to use TrueType fonts to render text
in SDL applications. Text can be rendered to a surface or directly to a texture, with control over the font size,
style, hinting, and color. Complex scripts are shaped with HarfBuzz, fallback fonts extend the glyphs a font can draw,
and outlines can be stroked with an arbitrary width.

Open a font with C<TTF_OpenFont( ... )> or C<TTF_OpenFontWithProperties( ... )>, then render with the
C<TTF_RenderText_*( ... )> and C<TTF_RenderGlyph_*( ... )> families. For styled, wrapped, and measured text, build a
reusable C<TTF_Text> object against a C<TTF_TextEngine> and draw it into the renderer. Free fonts with C<TTF_CloseFont(
... )> and call C<TTF_Quit( )> when you are done.

There are a few examples in this distribution's C<eg/ttf> directory.

=head2 Features

Each feature listed below is a tag you may use.

=head3 C<:all> - SDL3_ttf Functions

This binds all functions, defines all types, and imports them into your package.

See L<the SDL3_ttf Wiki|https://wiki.libsdl.org/SDL3_ttf/FrontPage> for documentation of the functions and types you
will have access to with this import tag.

=cut

    my $alien = Alien::SDL3->new;
    my $info  = $alien->alt('libsdl3_ttf')->package_info;
    croak 'SDL3_ttf is not installed' unless $info;
    my ($lib) = @{ $info->libfiles };
    $ENV{PATH} = join( $Config{path_sep}, ( map { @{ $_->bindirs // [] } } $info ), $ENV{PATH} // '' );
    our ( %EXPORT_TAGS, @EXPORT_OK );

    sub import ( $pkg, @wants ) {
        {
            no strict 'refs';
            (s[^:][_]r)->() for @wants;
        }
        require List::Util;
        @EXPORT_OK = sort map {@$_} values %EXPORT_TAGS;
        $EXPORT_TAGS{all} = [@EXPORT_OK];
        __PACKAGE__->export_to_level( 1, $pkg, @wants );
    }

    sub _affix_and_export ( $name, $args, $ret ) {
        my ( $n, $r ) = ref $name ? @$name : ( $name, $name );
        confess "Failed to affix $n" unless affix( $lib, $name, $args, $ret );
        push @{ $EXPORT_TAGS{ [ caller(1) ]->[3] =~ s/^.+?_//r } }, $n;
    }

    sub _const_and_export ( $name, $value ) {
        no strict 'refs';
        *{$name} = sub () {$value};
        push @{ $EXPORT_TAGS{ [ caller(1) ]->[3] =~ s/^.+?_//r } }, $name;
    }

    sub _func_and_export ( $name, $sub ) {
        no strict 'refs';
        *{$name} = $sub;
        push @{ $EXPORT_TAGS{ [ caller(1) ]->[3] =~ s/^.+?_//r } }, $name;
    }

    sub _typedef_and_export ( $name, $type //= () ) {
        no strict 'refs';
        if ( defined $type ) {
            typedef $name, $type;
        }
        else {
            typedef $name;
        }
        push @{ $EXPORT_TAGS{ [ caller(1) ]->[3] =~ s/^.+?_//r } }, $name;
    }

    sub _enum_and_export ( $name, $values ) {
        no strict 'refs';
        if ( defined $values ) {
            typedef $name, Enum [@$values];
            push @{ $EXPORT_TAGS{ [ caller(1) ]->[3] =~ s/^.+?_//r } }, $name;
            for my $enum (@$values) {
                push @{ $EXPORT_TAGS{ [ caller(1) ]->[3] =~ s/^.+?_//r } }, ref $enum ? $enum->[0] : $enum;
            }
        }
    }

    sub _ttf () {
        state $done++ && return;

        # Runtime version discovery
        _affix_and_export 'TTF_Version', [], Int;
        _func_and_export TTF_VERSIONNUM       => sub ( $major, $minor, $patch ) { ( ($major) * 1000000 + ($minor) * 1000 + ($patch) ) };
        _func_and_export TTF_VERSIONNUM_MAJOR => sub ($version) { int( ($version) / 1000000 ) };
        _func_and_export TTF_VERSIONNUM_MINOR => sub ($version) { int( ( ($version) / 1000 ) % 1000 ) };
        _func_and_export TTF_VERSIONNUM_MICRO => sub ($version) { int( ($version) % 1000 ) };
        _func_and_export TTF_MAJOR_VERSION    => sub () { state $i //= TTF_VERSIONNUM_MAJOR( TTF_Version() ); $i };
        _func_and_export TTF_MINOR_VERSION    => sub () { state $i //= TTF_VERSIONNUM_MINOR( TTF_Version() ); $i };
        _func_and_export TTF_MICRO_VERSION    => sub () { state $i //= TTF_VERSIONNUM_MICRO( TTF_Version() ); $i };
        _const_and_export TTF_VERSION => TTF_VERSIONNUM( TTF_MAJOR_VERSION(), TTF_MINOR_VERSION(), TTF_MICRO_VERSION() );
        _func_and_export TTF_VERSION_ATLEAST => sub ( $X, $Y, $Z ) { ( TTF_VERSION() >= TTF_VERSIONNUM( $X, $Y, $Z ) ); };
        _affix_and_export TTF_GetFreeTypeVersion => [ Pointer [Int], Pointer [Int], Pointer [Int] ], Void;
        _affix_and_export TTF_GetHarfBuzzVersion => [ Pointer [Int], Pointer [Int], Pointer [Int] ], Void;
        _typedef_and_export TTF_Font => Void;
        _affix_and_export TTF_Init                   => [], Bool;
        _affix_and_export TTF_Quit                   => [], Void;
        _affix_and_export TTF_WasInit                => [], Int;
        _affix_and_export TTF_OpenFont               => [ String, Float ], Pointer [ TTF_Font() ];
        _affix_and_export TTF_OpenFontIO             => [ Pointer [ SDL_IOStream() ], Bool, Float ], Pointer [ TTF_Font() ];
        _affix_and_export TTF_OpenFontWithProperties => [ SDL_PropertiesID() ], Pointer [ TTF_Font() ];
        _const_and_export TTF_PROP_FONT_CREATE_FILENAME_STRING            => 'SDL_ttf.font.create.filename';
        _const_and_export TTF_PROP_FONT_CREATE_IOSTREAM_POINTER           => 'SDL_ttf.font.create.iostream';
        _const_and_export TTF_PROP_FONT_CREATE_IOSTREAM_OFFSET_NUMBER     => 'SDL_ttf.font.create.iostream.offset';
        _const_and_export TTF_PROP_FONT_CREATE_IOSTREAM_AUTOCLOSE_BOOLEAN => 'SDL_ttf.font.create.iostream.autoclose';
        _const_and_export TTF_PROP_FONT_CREATE_SIZE_FLOAT                 => 'SDL_ttf.font.create.size';
        _const_and_export TTF_PROP_FONT_CREATE_FACE_NUMBER                => 'SDL_ttf.font.create.face';
        _const_and_export TTF_PROP_FONT_CREATE_HORIZONTAL_DPI_NUMBER      => 'SDL_ttf.font.create.hdpi';
        _const_and_export TTF_PROP_FONT_CREATE_VERTICAL_DPI_NUMBER        => 'SDL_ttf.font.create.vdpi';
        _const_and_export TTF_PROP_FONT_CREATE_EXISTING_FONT_POINTER      => 'SDL_ttf.font.create.existing_font';
        _affix_and_export TTF_CopyFont          => [ Pointer [ TTF_Font() ] ], Pointer [ TTF_Font() ];
        _affix_and_export TTF_CloseFont         => [ Pointer [ TTF_Font() ] ], Void;
        _affix_and_export TTF_GetFontProperties => [ Pointer [ TTF_Font() ] ], SDL_PropertiesID();
        _const_and_export TTF_PROP_FONT_OUTLINE_LINE_CAP_NUMBER    => 'SDL_ttf.font.outline.line_cap';
        _const_and_export TTF_PROP_FONT_OUTLINE_LINE_JOIN_NUMBER   => 'SDL_ttf.font.outline.line_join';
        _const_and_export TTF_PROP_FONT_OUTLINE_MITER_LIMIT_NUMBER => 'SDL_ttf.font.outline.miter_limit';
        _affix_and_export TTF_GetFontGeneration  => [ Pointer [ TTF_Font() ] ], UInt32;
        _affix_and_export TTF_AddFallbackFont    => [ Pointer [ TTF_Font() ], Pointer [ TTF_Font() ] ], Bool;
        _affix_and_export TTF_RemoveFallbackFont => [ Pointer [ TTF_Font() ], Pointer [ TTF_Font() ] ], Void;
        _affix_and_export TTF_ClearFallbackFonts => [ Pointer [ TTF_Font() ] ], Void;
        _affix_and_export TTF_SetFontSize        => [ Pointer [ TTF_Font() ], Float ], Bool;
        _affix_and_export TTF_SetFontSizeDPI     => [ Pointer [ TTF_Font() ], Float, Int, Int ], Bool;
        _affix_and_export TTF_GetFontSize        => [ Pointer [ TTF_Font() ] ], Float;
        _affix_and_export TTF_GetFontDPI         => [ Pointer [ TTF_Font() ], Pointer [Int], Pointer [Int] ], Bool;
        _typedef_and_export TTF_FontStyleFlags => UInt32;
        _const_and_export TTF_STYLE_NORMAL        => 0x00;
        _const_and_export TTF_STYLE_BOLD          => 0x01;
        _const_and_export TTF_STYLE_ITALIC        => 0x02;
        _const_and_export TTF_STYLE_UNDERLINE     => 0x04;
        _const_and_export TTF_STYLE_STRIKETHROUGH => 0x08;
        _affix_and_export TTF_SetFontStyle   => [ Pointer [ TTF_Font() ], TTF_FontStyleFlags() ], Void;
        _affix_and_export TTF_GetFontStyle   => [ Pointer [ TTF_Font() ] ], TTF_FontStyleFlags();
        _affix_and_export TTF_SetFontOutline => [ Pointer [ TTF_Font() ], Int ], Bool;
        _affix_and_export TTF_GetFontOutline => [ Pointer [ TTF_Font() ] ], Int;
        _enum_and_export TTF_HintingFlags =>
            [ [ TTF_HINTING_INVALID => -1 ], qw[TTF_HINTING_NORMAL TTF_HINTING_LIGHT TTF_HINTING_MONO TTF_HINTING_NONE TTF_HINTING_LIGHT_SUBPIXEL] ];
        _affix_and_export TTF_SetFontHinting  => [ Pointer [ TTF_Font() ], TTF_HintingFlags() ], Void;
        _affix_and_export TTF_GetFontHinting  => [ Pointer [ TTF_Font() ] ], TTF_HintingFlags();
        _affix_and_export TTF_GetNumFontFaces => [ Pointer [ TTF_Font() ] ], Int;
        _affix_and_export TTF_SetFontSDF      => [ Pointer [ TTF_Font() ], Bool ], Bool;
        _affix_and_export TTF_GetFontSDF      => [ Pointer [ TTF_Font() ] ], Bool;

        # Added in SDL_ttf 3.2.2
        if ( TTF_VERSION_ATLEAST( 3, 2, 2 ) ) {
            _affix_and_export TTF_GetFontWeight => [ Pointer [ TTF_Font() ] ], Int;
        }
        _const_and_export TTF_FONT_WEIGHT_THIN        => 100;
        _const_and_export TTF_FONT_WEIGHT_EXTRA_LIGHT => 200;
        _const_and_export TTF_FONT_WEIGHT_LIGHT       => 300;
        _const_and_export TTF_FONT_WEIGHT_NORMAL      => 400;
        _const_and_export TTF_FONT_WEIGHT_MEDIUM      => 500;
        _const_and_export TTF_FONT_WEIGHT_SEMI_BOLD   => 600;
        _const_and_export TTF_FONT_WEIGHT_BOLD        => 700;
        _const_and_export TTF_FONT_WEIGHT_EXTRA_BOLD  => 800;
        _const_and_export TTF_FONT_WEIGHT_BLACK       => 900;
        _const_and_export TTF_FONT_WEIGHT_EXTRA_BLACK => 950;
        _enum_and_export TTF_HorizontalAlignment =>
            [ [ TTF_HORIZONTAL_ALIGN_INVALID => -1 ], qw[TTF_HORIZONTAL_ALIGN_LEFT TTF_HORIZONTAL_ALIGN_CENTER TTF_HORIZONTAL_ALIGN_RIGHT] ];
        _affix_and_export TTF_SetFontWrapAlignment => [ Pointer [ TTF_Font() ], TTF_HorizontalAlignment() ], Void;
        _affix_and_export TTF_GetFontWrapAlignment => [ Pointer [ TTF_Font() ] ], TTF_HorizontalAlignment();
        _affix_and_export TTF_GetFontHeight        => [ Pointer [ TTF_Font() ] ], Int;
        _affix_and_export TTF_GetFontAscent        => [ Pointer [ TTF_Font() ] ], Int;
        _affix_and_export TTF_GetFontDescent       => [ Pointer [ TTF_Font() ] ], Int;
        _affix_and_export TTF_SetFontLineSkip      => [ Pointer [ TTF_Font() ], Int ], Void;
        _affix_and_export TTF_GetFontLineSkip      => [ Pointer [ TTF_Font() ] ], Int;
        _affix_and_export TTF_SetFontKerning       => [ Pointer [ TTF_Font() ], Bool ], Void;
        _affix_and_export TTF_GetFontKerning       => [ Pointer [ TTF_Font() ] ], Bool;
        _affix_and_export TTF_FontIsFixedWidth     => [ Pointer [ TTF_Font() ] ], Bool;
        _affix_and_export TTF_FontIsScalable       => [ Pointer [ TTF_Font() ] ], Bool;
        _affix_and_export TTF_GetFontFamilyName    => [ Pointer [ TTF_Font() ] ], String;
        _affix_and_export TTF_GetFontStyleName     => [ Pointer [ TTF_Font() ] ], String;
        _enum_and_export TTF_Direction =>
            [ [ TTF_DIRECTION_INVALID => 0 ], [ TTF_DIRECTION_LTR => 4 ], qw[TTF_DIRECTION_RTL TTF_DIRECTION_TTB TTF_DIRECTION_BTT] ];
        _affix_and_export TTF_SetFontDirection => [ Pointer [ TTF_Font() ], TTF_Direction() ], Bool;
        _affix_and_export TTF_GetFontDirection => [ Pointer [ TTF_Font() ] ], TTF_Direction();

        # Added in SDL_ttf 3.4.0
        if ( TTF_VERSION_ATLEAST( 3, 4, 0 ) ) {
            _affix_and_export TTF_SetFontCharSpacing => [ Pointer [ TTF_Font() ], Int ], Bool;
            _affix_and_export TTF_GetFontCharSpacing => [ Pointer [ TTF_Font() ], Int ], Int;
        }
        _affix_and_export TTF_StringToTag     => [String], UInt32;
        _affix_and_export TTF_TagToString     => [ UInt32, Pointer [Char], Size_t ], Void;
        _affix_and_export TTF_SetFontScript   => [ Pointer [ TTF_Font() ], UInt32 ], Bool;
        _affix_and_export TTF_GetFontScript   => [ Pointer [ TTF_Font() ] ], UInt32;
        _affix_and_export TTF_GetGlyphScript  => [UInt32], UInt32;
        _affix_and_export TTF_SetFontLanguage => [ Pointer [ TTF_Font() ], String ], Bool;
        _affix_and_export TTF_FontHasGlyph    => [ Pointer [ TTF_Font() ], UInt32 ], Bool;
        _enum_and_export TTF_ImageType => [qw[TTF_IMAGE_INVALID TTF_IMAGE_ALPHA TTF_IMAGE_COLOR TTF_IMAGE_SDF]];
        _affix_and_export TTF_GetGlyphImage         => [ Pointer [ TTF_Font() ], UInt32, Pointer [ TTF_ImageType() ] ], Pointer [ SDL_Surface() ];
        _affix_and_export TTF_GetGlyphImageForIndex => [ Pointer [ TTF_Font() ], UInt32, Pointer [ TTF_ImageType() ] ], Pointer [ SDL_Surface() ];
        _affix_and_export
            TTF_GetGlyphMetrics => [ Pointer [ TTF_Font() ], UInt32, Pointer [Int], Pointer [Int], Pointer [Int], Pointer [Int], Pointer [Int] ],
            Bool;
        _affix_and_export TTF_GetGlyphKerning          => [ Pointer [ TTF_Font() ], UInt32, UInt32, Pointer [Int] ], Bool;
        _affix_and_export TTF_GetStringSize            => [ Pointer [ TTF_Font() ], String, Size_t, Pointer [Int], Pointer [Int] ], Bool;
        _affix_and_export TTF_GetStringSizeWrapped     => [ Pointer [ TTF_Font() ], String, Size_t, Int, Pointer [Int], Pointer [Int] ],    Bool;
        _affix_and_export TTF_MeasureString            => [ Pointer [ TTF_Font() ], String, Size_t, Int, Pointer [Int], Pointer [Size_t] ], Bool;
        _affix_and_export TTF_RenderText_Solid         => [ Pointer [ TTF_Font() ], String, Size_t, SDL_Color() ], Pointer [ SDL_Surface() ];
        _affix_and_export TTF_RenderText_Solid_Wrapped => [ Pointer [ TTF_Font() ], String, Size_t, SDL_Color(), Int ], Pointer [ SDL_Surface() ];
        _affix_and_export TTF_RenderGlyph_Solid        => [ Pointer [ TTF_Font() ], UInt32, SDL_Color() ], Pointer [ SDL_Surface() ];
        _affix_and_export TTF_RenderText_Shaded => [ Pointer [ TTF_Font() ], String, Size_t, SDL_Color(), SDL_Color() ], Pointer [ SDL_Surface() ];
        _affix_and_export
            TTF_RenderText_Shaded_Wrapped => [ Pointer [ TTF_Font() ], String, Size_t, SDL_Color(), SDL_Color(), Int ],
            Pointer [ SDL_Surface() ];
        _affix_and_export TTF_RenderGlyph_Shaded         => [ Pointer [ TTF_Font() ], UInt32, SDL_Color(), SDL_Color() ], Pointer [ SDL_Surface() ];
        _affix_and_export TTF_RenderText_Blended         => [ Pointer [ TTF_Font() ], String, Size_t, SDL_Color() ], Pointer [ SDL_Surface() ];
        _affix_and_export TTF_RenderText_Blended_Wrapped => [ Pointer [ TTF_Font() ], String, Size_t, SDL_Color(), Int ], Pointer [ SDL_Surface() ];
        _affix_and_export TTF_RenderGlyph_Blended        => [ Pointer [ TTF_Font() ], UInt32, SDL_Color() ], Pointer [ SDL_Surface() ];
        _affix_and_export TTF_RenderText_LCD => [ Pointer [ TTF_Font() ], String, Size_t, SDL_Color(), SDL_Color() ], Pointer [ SDL_Surface() ];
        _affix_and_export
            TTF_RenderText_LCD_Wrapped => [ Pointer [ TTF_Font() ], String, Size_t, SDL_Color(), SDL_Color(), Int ],
            Pointer [ SDL_Surface() ];
        _affix_and_export TTF_RenderGlyph_LCD => [ Pointer [ TTF_Font() ], UInt32, SDL_Color(), SDL_Color() ], Pointer [ SDL_Surface() ];

        # Text Engine API (from SDL_textengine.h)
        _enum_and_export TTF_DrawCommand => [qw[TTF_DRAW_COMMAND_NOOP TTF_DRAW_COMMAND_FILL TTF_DRAW_COMMAND_COPY]];
        _typedef_and_export TTF_FillOperation => Struct [ cmd => TTF_DrawCommand(), rect => SDL_Rect() ];
        _typedef_and_export TTF_CopyOperation => Struct [
            cmd         => TTF_DrawCommand(),
            text_offset => Int,
            glyph_font  => Pointer [ TTF_Font() ],
            glyph_index => UInt32,
            src         => SDL_Rect(),
            dst         => SDL_Rect(),
            reserved    => Pointer [Void]
        ];
        _typedef_and_export TTF_DrawOperation => Union [ cmd => TTF_DrawCommand(), fill => TTF_FillOperation(), copy => TTF_CopyOperation() ];
        _typedef_and_export TTF_TextLayout    => Void;
        typedef 'TTF_Text';
        typedef 'TTF_TextEngine';
        _typedef_and_export TTF_SubStringFlags => UInt32;
        _const_and_export TTF_SUBSTRING_DIRECTION_MASK => 0x000000FF;
        _const_and_export TTF_SUBSTRING_TEXT_START     => 0x00000100;
        _const_and_export TTF_SUBSTRING_LINE_START     => 0x00000200;
        _const_and_export TTF_SUBSTRING_LINE_END       => 0x00000400;
        _const_and_export TTF_SUBSTRING_TEXT_END       => 0x00000800;
        _typedef_and_export TTF_SubString =>
            Struct [ flags => TTF_SubStringFlags(), offset => Int, length => Int, line_index => Int, cluster_index => Int, rect => SDL_Rect() ];
        _typedef_and_export TTF_TextData => Struct [
            font                => Pointer [ TTF_Font() ],
            color               => SDL_FColor(),
            needs_layout_update => Bool,
            layout              => Pointer [ TTF_TextLayout() ],
            x                   => Int,
            y                   => Int,
            w                   => Int,
            h                   => Int,
            num_ops             => Int,
            ops                 => Pointer [ TTF_DrawOperation() ],
            num_clusters        => Int,
            clusters            => Pointer [ TTF_SubString() ],
            props               => SDL_PropertiesID(),
            needs_engine_update => Bool,
            engine              => Pointer [ TTF_TextEngine() ],
            engine_text         => Pointer [Void]
        ];
        _typedef_and_export TTF_Text => Struct [ text => String, num_lines => Int, refcount => Int, internal => Pointer [ TTF_TextData() ] ];
        _typedef_and_export TTF_TextEngine => Struct [
            version     => UInt32,
            userdata    => Pointer [Void],
            CreateText  => Callback [ [ Pointer [Void], Pointer [ TTF_Text() ] ] => Bool ],
            DestroyText => Callback [ [ Pointer [Void], Pointer [ TTF_Text() ] ] => Void ]
        ];
        _affix_and_export TTF_CreateSurfaceTextEngine                => [], Pointer [ TTF_TextEngine() ];
        _affix_and_export TTF_DrawSurfaceText                        => [ Pointer [ TTF_Text() ], Int, Int, Pointer [ SDL_Surface() ] ], Bool;
        _affix_and_export TTF_DestroySurfaceTextEngine               => [ Pointer [ TTF_TextEngine() ] ], Void;
        _affix_and_export TTF_CreateRendererTextEngine               => [ Pointer [ SDL_Renderer() ] ],   Pointer [ TTF_TextEngine() ];
        _affix_and_export TTF_CreateRendererTextEngineWithProperties => [ SDL_PropertiesID() ], Pointer [ TTF_TextEngine() ];
        _const_and_export TTF_PROP_RENDERER_TEXT_ENGINE_RENDERER_POINTER          => 'SDL_ttf.renderer_text_engine.create.renderer';
        _const_and_export TTF_PROP_RENDERER_TEXT_ENGINE_ATLAS_TEXTURE_SIZE_NUMBER => 'SDL_ttf.renderer_text_engine.create.atlas_texture_size';
        _affix_and_export TTF_DrawRendererText                  => [ Pointer [ TTF_Text() ], Float, Float ], Bool;
        _affix_and_export TTF_DestroyRendererTextEngine         => [ Pointer [ TTF_TextEngine() ] ], Void;
        _affix_and_export TTF_CreateGPUTextEngine               => [ Pointer [ SDL_GPUDevice() ] ],  Pointer [ TTF_TextEngine() ];
        _affix_and_export TTF_CreateGPUTextEngineWithProperties => [ SDL_PropertiesID() ], Pointer [ TTF_TextEngine() ];
        _const_and_export TTF_PROP_GPU_TEXT_ENGINE_DEVICE_POINTER            => 'SDL_ttf.gpu_text_engine.create.device';
        _const_and_export TTF_PROP_GPU_TEXT_ENGINE_ATLAS_TEXTURE_SIZE_NUMBER => 'SDL_ttf.gpu_text_engine.create.atlas_texture_size';
        typedef 'TTF_GPUAtlasDrawSequence';
        _typedef_and_export TTF_GPUAtlasDrawSequence => Struct [
            atlas_texture => Pointer [ SDL_GPUTexture() ],
            xy            => Pointer [ SDL_FPoint() ],
            uv            => Pointer [ SDL_FPoint() ],
            num_vertices  => Int,
            indices       => Pointer [Int],
            num_indices   => Int,
            image_type    => TTF_ImageType(),
            next          => Pointer [ TTF_GPUAtlasDrawSequence() ]
        ];
        _affix_and_export TTF_GetGPUTextDrawData   => [ Pointer [ TTF_Text() ] ],       Pointer [ TTF_GPUAtlasDrawSequence() ];
        _affix_and_export TTF_DestroyGPUTextEngine => [ Pointer [ TTF_TextEngine() ] ], Void;
        _enum_and_export TTF_GPUTextEngineWinding =>
            [ [ TTF_GPU_TEXTENGINE_WINDING_INVALID => -1 ], 'TTF_GPU_TEXTENGINE_WINDING_CLOCKWISE', 'TTF_GPU_TEXTENGINE_WINDING_COUNTER_CLOCKWISE' ];
        _affix_and_export TTF_SetGPUTextEngineWinding => [ Pointer [ TTF_TextEngine() ], TTF_GPUTextEngineWinding() ], Void;
        _affix_and_export TTF_GetGPUTextEngineWinding => [ Pointer [ TTF_TextEngine() ] ], TTF_GPUTextEngineWinding();

        # Added in SDL_ttf 3.3.0
        if ( TTF_VERSION_ATLEAST( 3, 3, 0 ) ) {
            _affix_and_export TTF_CreateGLTextEngine => [], Pointer [ TTF_TextEngine() ];
            _affix_and_export TTF_CreateGLTextEngineWithProperties => [ SDL_PropertiesID() ], Pointer [ TTF_TextEngine() ];
            _const_and_export TTF_PROP_GL_TEXT_ENGINE_ATLAS_TEXTURE_SIZE_NUMBER => 'SDL_ttf.gl_text_engine.create.atlas_texture_size';
            _typedef_and_export TTF_GLAtlasDrawVertex => Struct [ position => SDL_FPoint(), texcoord => SDL_FPoint() ];
            typedef 'TTF_GLAtlasDrawSequence';
            _typedef_and_export TTF_GLAtlasDrawSequence => Struct [
                atlas_texture => UInt,
                vertices      => Pointer [ TTF_GLAtlasDrawVertex() ],
                num_vertices  => Int,
                indices       => Pointer [UShort],
                num_indices   => Int,
                image_type    => TTF_ImageType(),
                next          => Pointer [ TTF_GLAtlasDrawSequence() ]
            ];
            _affix_and_export TTF_GetGLTextDrawData   => [ Pointer [ TTF_Text() ] ],       Pointer [ TTF_GLAtlasDrawSequence() ];
            _affix_and_export TTF_DestroyGLTextEngine => [ Pointer [ TTF_TextEngine() ] ], Void;
            _enum_and_export TTF_GLTextEngineWinding =>
                [ [ TTF_GL_TEXTENGINE_WINDING_INVALID => -1 ], 'TTF_GL_TEXTENGINE_WINDING_CLOCKWISE', 'TTF_GL_TEXTENGINE_WINDING_COUNTER_CLOCKWISE' ];
            _affix_and_export TTF_SetGLTextEngineWinding => [ Pointer [ TTF_TextEngine() ], TTF_GLTextEngineWinding() ], Void;
            _affix_and_export TTF_GetGLTextEngineWinding => [ Pointer [ TTF_TextEngine() ] ], TTF_GLTextEngineWinding();
        }
        _affix_and_export TTF_CreateText        => [ Pointer [ TTF_TextEngine() ], Pointer [ TTF_Font() ], String, Size_t ], Pointer [ TTF_Text() ];
        _affix_and_export TTF_GetTextProperties => [ Pointer [ TTF_Text() ] ], SDL_PropertiesID();
        _affix_and_export TTF_SetTextEngine     => [ Pointer [ TTF_Text() ], Pointer [ TTF_TextEngine() ] ], Bool;
        _affix_and_export TTF_GetTextEngine     => [ Pointer [ TTF_Text() ] ], Pointer [ TTF_TextEngine() ];
        _affix_and_export TTF_SetTextFont       => [ Pointer [ TTF_Text() ], Pointer [ TTF_Font() ] ], Bool;
        _affix_and_export TTF_GetTextFont       => [ Pointer [ TTF_Text() ] ], Pointer [ TTF_Font() ];
        _affix_and_export TTF_SetTextDirection  => [ Pointer [ TTF_Text() ], TTF_Direction() ], Bool;
        _affix_and_export TTF_GetTextDirection  => [ Pointer [ TTF_Text() ] ], TTF_Direction();
        _affix_and_export TTF_SetTextScript     => [ Pointer [ TTF_Text() ], UInt32 ], Bool;
        _affix_and_export TTF_GetTextScript     => [ Pointer [ TTF_Text() ] ], UInt32;
        _affix_and_export TTF_SetTextColor      => [ Pointer [ TTF_Text() ], UInt8, UInt8, UInt8, UInt8 ], Bool;
        _affix_and_export TTF_SetTextColorFloat => [ Pointer [ TTF_Text() ], Float, Float, Float, Float ], Bool;
        _affix_and_export TTF_GetTextColor => [ Pointer [ TTF_Text() ], Pointer [UInt8], Pointer [UInt8], Pointer [UInt8], Pointer [UInt8] ], Bool;
        _affix_and_export
            TTF_GetTextColorFloat => [ Pointer [ TTF_Text() ], Pointer [Float], Pointer [Float], Pointer [Float], Pointer [Float] ],
            Bool;
        _affix_and_export TTF_SetTextPosition              => [ Pointer [ TTF_Text() ], Int, Int ], Bool;
        _affix_and_export TTF_GetTextPosition              => [ Pointer [ TTF_Text() ], Pointer [Int], Pointer [Int] ], Bool;
        _affix_and_export TTF_SetTextWrapWidth             => [ Pointer [ TTF_Text() ], Int ], Bool;
        _affix_and_export TTF_GetTextWrapWidth             => [ Pointer [ TTF_Text() ], Pointer [Int] ], Bool;
        _affix_and_export TTF_SetTextWrapWhitespaceVisible => [ Pointer [ TTF_Text() ], Bool ], Bool;
        _affix_and_export TTF_TextWrapWhitespaceVisible    => [ Pointer [ TTF_Text() ] ], Bool;
        _affix_and_export TTF_SetTextString                => [ Pointer [ TTF_Text() ], String, Size_t ], Bool;
        _affix_and_export TTF_InsertTextString             => [ Pointer [ TTF_Text() ], Int, String, Size_t ], Bool;
        _affix_and_export TTF_AppendTextString             => [ Pointer [ TTF_Text() ], String, Size_t ], Bool;
        _affix_and_export TTF_DeleteTextString             => [ Pointer [ TTF_Text() ], Int, Int ],       Bool;
        _affix_and_export TTF_GetTextSize                  => [ Pointer [ TTF_Text() ], Pointer [Int], Pointer [Int] ], Bool;
        _affix_and_export TTF_GetTextSubString             => [ Pointer [ TTF_Text() ], Int, Pointer [ TTF_SubString() ] ], Bool;
        _affix_and_export TTF_GetTextSubStringForLine      => [ Pointer [ TTF_Text() ], Int, Pointer [ TTF_SubString() ] ], Bool;
        _affix_and_export
            TTF_GetTextSubStringsForRange => [ Pointer [ TTF_Text() ], Int, Int, Pointer [Int] ],
            Pointer [ Pointer [ TTF_SubString() ] ];
        _affix_and_export TTF_GetTextSubStringForPoint => [ Pointer [ TTF_Text() ], Int, Int, Pointer [ TTF_SubString() ] ], Bool;
        _affix_and_export TTF_GetPreviousTextSubString => [ Pointer [ TTF_Text() ], Pointer [ TTF_SubString() ], Pointer [ TTF_SubString() ] ], Bool;
        _affix_and_export TTF_GetNextTextSubString     => [ Pointer [ TTF_Text() ], Pointer [ TTF_SubString() ], Pointer [ TTF_SubString() ] ], Bool;
        _affix_and_export TTF_UpdateText               => [ Pointer [ TTF_Text() ] ], Bool;
        _affix_and_export TTF_DestroyText              => [ Pointer [ TTF_Text() ] ], Void;
    }

    sub _all () {
        state $done++ && return;
        _ttf();
    }
}
1;

=head1 See Also

The project's repo: L<https://github.com/Perl-SDL3/>

The SDL3_ttf Wiki: L<https://wiki.libsdl.org/SDL3_ttf/FrontPage>

L<SDL3>

L<Affix>

=head1 LICENSE

This software is Copyright (c) 2026 by Sanko Robinson.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

See the F<LICENSE> file for full text.

=head1 AUTHOR

Sanko Robinson L<https://github.com/sanko>

=begin stopwords


=end stopwords

=cut
