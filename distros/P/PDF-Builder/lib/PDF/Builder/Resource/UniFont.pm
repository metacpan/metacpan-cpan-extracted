package PDF::Builder::Resource::UniFont;

use strict;
use warnings;

our $VERSION = '3.017'; # VERSION
my $LAST_UPDATE = '3.016'; # manually update whenever code is changed

use Carp;
use Encode qw(:all);

=head1 NAME

PDF::Builder::Resource::UniFont - Unicode Font Support

=head1 METHODS

=over

=item $font = PDF::Builder::Resource::UniFont->new($pdf, @fontspecs, %options)

Returns a uni-font object.

=cut

=pod

B<FONTSPECS:> fonts can be registered using the following hash-ref:

    {
        font   => $fontobj,     # the font to be registered
        blocks => $blockspec,   # the unicode blocks the font is being registered for
        codes  => $codespec,    # the unicode codepoints, -"-
    }

B<BLOCKSPECS:>

    [
         $block1, $block3,    # register font for block 1 + 3
        [$blockA, $blockZ],   # register font for blocks A .. Z
    ]

B<CODESPECS:>

    [
         $cp1, $cp3,          # register font for codepoint 1 + 3
        [$cpA, $cpZ],         # register font for codepoints A .. Z
    ]

B<NOTE:> if you want to register a font for the entire unicode space
(ie. U+0000 .. U+FFFF), then simply specify a font-object without the hash-ref.

Valid %options are:

  '-encode' ... changes the encoding of the font from its default.
    (see "perldoc Encode" for a list of valid tags)

=cut

sub new {
    my $class = shift();
    $class = ref($class) if ref($class);

    my $self = {
        'fonts' => [],
        'block' => {},
        'code'  => {},
	'pdf'   => shift(),
    };
    bless $self, $class;

    my @fonts;
    push @fonts, shift() while ref($_[0]);

    my %options = @_;
    $self->{'encode'} = $options{'-encode'} if defined $options{'-encode'};
    # note that self->encode is undefined if -encode not given!

    my $font_number = 0;
    foreach my $font (@fonts) {
        if      (ref($font) eq 'ARRAY') {
            push @{$self->{'fonts'}}, shift(@$font);
            
            while (defined $font->[0]) {
                my $blockspec = shift @$font;
                if (ref($blockspec)) {
                    foreach my $block ($blockspec->[0] .. $blockspec->[-1]) {
                        $self->{'block'}->{$block} = $font_number;
                    }
                } else {
                    $self->{'block'}->{$blockspec} = $font_number;
                }
            }
        } elsif (ref($font) eq 'HASH') {
            push @{$self->{'fonts'}}, $font->{'font'};

            if (defined $font->{'blocks'} and 
		ref($font->{'blocks'}) eq 'ARRAY') {
                foreach my $blockspec (@{$font->{'blocks'}}) {
                    if (ref($blockspec)) {
                        foreach my $block($blockspec->[0] .. $blockspec->[-1]) {
                            $self->{'block'}->{$block} = $font_number;
                        }
                    } else {
                        $self->{'block'}->{$blockspec} = $font_number;
                    }
                }
            }

            if (defined $font->{'codes'} and
	        ref($font->{'codes'}) eq 'ARRAY') {
                foreach my $codespec (@{$font->{'codes'}}) {
                    if (ref($codespec)) {
                        foreach my $code ($codespec->[0] .. $codespec->[-1]) {
                            $self->{'code'}->{$code} = $font_number;
                        }
                    } else {
                        $self->{'code'}->{$codespec} = $font_number;
                    }
                }
            }
        } else {
            push @{$self->{'fonts'}}, $font;
            foreach my $block (0 .. 255) {
                $self->{'block'}->{$block} = $font_number;
            }
        }
        $font_number++;
    }

    return $self;
}

sub isvirtual { 
    return 1; 
}

sub fontlist {
    my ($self) = @_;

    return [@{$self->{'fonts'}}];
}

sub width {
    my ($self, $text) = @_;

    if (defined $self->{'encode'}) { # is self->encode guaranteed set?
        $text = decode($self->{'encode'}, $text) unless utf8::is_utf8($text);
    }
    my $width = 0;
    my @blocks = ();

    foreach my $u (unpack('U*', $text)) {
        my $font_number = 0;
        if      (defined $self->{'code'}->{$u}) {
            $font_number = $self->{'code'}->{$u};
        } elsif (defined $self->{'block'}->{($u >> 8)}) {
            $font_number = $self->{'block'}->{($u >> 8)};
        } else {
            $font_number = 0;
        }
        if (scalar @blocks == 0 or $blocks[-1]->[0] != $font_number) {
            push @blocks, [$font_number, pack('U', $u)];
        } else {
            $blocks[-1]->[1] .= pack('U', $u);
        }
    }
    foreach my $block (@blocks) {
	my ($font_number, $string) = @$block;
        $width += $self->fontlist()->[$font_number]->width($string);
    }

    return $width;
}

sub text {
    my ($self, $text, $size, $indent) = @_;

    if (defined $self->{'encode'}) { # is self->encode guaranteed to be defined?
        $text = decode($self->{'encode'}, $text) unless utf8::is_utf8($text);
    }
    croak 'Font size not specified' unless defined $size;

    my $newtext = '';
    my $last_font_number;
    my @codes;

    foreach my $u (unpack('U*', $text)) {
        my $font_number = 0;
        if      (defined $self->{'code'}->{$u}) {
            $font_number = $self->{'code'}->{$u};
        } elsif (defined $self->{'block'}->{($u >> 8)}) {
            $font_number = $self->{'block'}->{($u >> 8)};
        }

        if (defined $last_font_number and 
	    $font_number != $last_font_number) {
            my $font = $self->fontlist()->[$last_font_number];
	    $newtext .= '/' . $font->name() . ' ' . $size. ' Tf ';
	    $newtext .= $font->text(pack('U*', @codes), $size, $indent) . ' ';
	    $indent = undef;
            @codes = ();
        }

        push @codes, $u;
        $last_font_number = $font_number;
    }

    if (scalar @codes > 0) {
        my $font = $self->fontlist()->[$last_font_number];
        $newtext .= '/' . $font->name() . ' ' . $size . ' Tf ';
	$newtext .= $font->text(pack('U*', @codes), $size, $indent);
    }

    return $newtext;
}

=back

=cut

1;
