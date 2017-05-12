package Term::Chart;

$VERSION = '0.04';

use 5.010000;
use strict;
use warnings;
use overload ( q{""} => \&_strigify );
{
    use Carp;
    use Readonly;
    use Term::ReadKey qw( GetTerminalSize );
}

my ( $CELL, %COLON_FOR, %BORDER );
{
    # extended set foreground color: 0-255
    Readonly $CELL  => qq{\x{1B}[1;38;5;%dm%s\x{1B}[0m};
    Readonly %COLON_FOR => (
        horizontal => ':',
        vertical   => "\x{0705}",
    );
    Readonly %BORDER => (
        'horizontal,tl' => "\x{250F}",
        'horizontal,tr' => "\x{2513}",
        'horizontal,hz' => "\x{2501}",
        'horizontal,vt' => "\x{2503}",
        'horizontal,br' => "\x{251B}",
        'horizontal,bl' => "\x{2517}",
        'vertical,tl'   => "\x{2517}",
        'vertical,tr'   => "\x{250F}",
        'vertical,hz'   => "\x{2503}",
        'vertical,vt'   => "\x{2501}",
        'vertical,br'   => "\x{2513}",
        'vertical,bl'   => "\x{251B}",
    );
}

sub new {
    my ( $class, $param_rh ) = @_;

    $param_rh ||= {};

    my $bar           = $param_rh->{bar};
    my $tip           = $param_rh->{tip};
    my $height        = $param_rh->{height} || 0;
    my $width         = $param_rh->{width} || 0;
    my $color_ar      = $param_rh->{color_range};
    my $orientation   = $param_rh->{orientation} || 'horizontal';
    my $style         = $param_rh->{style} || 'bar';
    my $border        = $param_rh->{border} || 0;

    croak "orientation is either horizontal or vertical"
        if $orientation !~ m{\A (?: horizontal|vertical ) \z}xms;

    croak "style is either dot or bar"
        if $style !~ m{\A (?: dot|bar ) \z}xms;

    croak "color_range paramter must be an array ref"
        if $color_ar && ref $color_ar ne 'ARRAY';

    croak 'height and width must be int values'
        if $height !~ m{\A \d+ \z}xms || $width !~ m{\A \d+ \z}xms;

    $bar //= $orientation eq 'horizontal' ? "\x{2585}" : "\x{2589}";
    $tip //= $orientation eq 'horizontal' ? "\x{2585}" : "\x{2589}";

    my %self = (
        data_ra       => [],
        low_value     => undef,
        high_value    => undef,
        label_size    => undef,
        border        => $border,
        height        => $height,
        width         => $width,
        char_for      => { bar => $bar, tip => $tip },
        color_range   => $color_ar,
        orientation   => $orientation,
        style         => $style,
    );
    return bless \%self, $class;
}

sub add_values {
    my ( $self, @values ) = @_;

    if ( @values == 1 && ref $values[0] eq 'ARRAY' )
    {
        @values = @{ $values[0] };
    }

    for my $value (@values)
    {
        $self->add_value( { value => $value } );
    }

    return scalar @{ $self->{data_ra} };
}

sub add_value {
    my ( $self, $datum_rh ) = @_;

    $datum_rh ||= {};

    my %datum = (
        label => "",
        value => 0,
    );
    for my $key ( keys %datum )
    {
        if ( exists $datum_rh->{$key} && defined $datum_rh->{$key} )
        {
            $datum{$key} = delete $datum_rh->{$key};
        }
    }

    for my $key ( keys %{$datum_rh} )
    {
        carp "$key is not a supported value parameter";
    }

    if ( $datum{value} !~ m{\A \d+ (?: [.] \d+ )? \z}xms )
    {
        $datum{value} = length $datum{value};
    }

    if (  !defined $self->{label_size}
        || length $datum{label} > $self->{label_size} )
    {
        $self->{label_size} = length $datum{label};
    }

    if (  !defined $self->{high_value}
        || $datum{value} > $self->{high_value} )
    {
        $self->{high_value} = $datum{value};
    }

    if (  !defined $self->{low_value}
        || $datum{value} < $self->{low_value} )
    {
        $self->{low_value} = $datum{value};
    }

    push @{ $self->{data_ra} }, \%datum;

    return scalar @{ $self->{data_ra} };
}

sub print {
    my ($self) = @_;
    print $self->_stringiy();
}

sub _strigify {
    my ($self) = @_;
    return $self->_render( $self->_build_matrix() );
}

sub _build_matrix {
    my ($self) = @_;

    my @matrix;

    my ( $width, $height ) = $self->_dimensions();

    my $orientation = $self->{orientation};
    my $size        = $self->{orientation} eq 'vertical' ? $height : $width;
    my $high_value  = $self->{high_value};
    my $label_size  = $self->{label_size};
    my $color_ar    = $self->{color_range};
    my $style       = $self->{style};
    my $slop        = $self->{border} ? 2 : 0;

    my ( $tl, $tr, $bl, $br, $hz, $vt ) = ( "" ) x 6;

    if ( $self->{border} )
    {
        ( $tl, $tr, $bl, $br, $hz, $vt )
            = (
                $BORDER{"$orientation,tl"},
                $BORDER{"$orientation,tr"},
                $BORDER{"$orientation,bl"},
                $BORDER{"$orientation,br"},
                $BORDER{"$orientation,hz"},
                $BORDER{"$orientation,vt"},
            );

        if ( $self->{border} > 1 )
        {
            for my $sr ( \$tl, \$tr, \$bl, \$br, \$hz, \$vt )
            {
                ${$sr} = sprintf $CELL, $self->{border}, ${$sr};
            }
        }

        my @row = (
            { char => $tl },
            ( { char => $hz } ) x ( $size - $slop ),
            { char => $tr },
        );
        push @matrix, \@row;
    }

    my $col_count
        = $label_size
        ? $size - ( $slop + $label_size + 1 )
        : $size - $slop;

    for my $datum_rh ( @{ $self->{data_ra} } )
    {
        my $magnitude = sprintf '%d',
            ( $datum_rh->{value} / $high_value ) * ( $col_count - 1 );

        my @row;

        if ( $label_size )
        {
            my $label = sprintf "% ${label_size}s%s",
                ( $datum_rh->{label} // "" ),
                $COLON_FOR{$self->{orientation}};

            push @row, { char => $vt };
            push @row, map { { char => $_ } } split //, $label;
        }
        elsif ( $vt )
        {
            @row = ( { char => $vt } );
        }

        for my $n ( 0 .. $col_count - 1 )
        {
            my $char;

            if ( $style eq 'dot' )
            {
                $char
                    = $n == $magnitude ? $self->{char_for}->{tip}
                    :                    " ";
            }
            else
            {
                $char
                    = $n == $magnitude ? $self->{char_for}->{tip}
                    : $n < $magnitude  ? $self->{char_for}->{bar}
                    :                    " ";
            }

            if ( $color_ar && $char ne " " )
            {
                my $percent = $n / $col_count;

                $percent
                    = $percent > 0.95 ? 1
                    : $percent < 0.05 ? 0
                    :                   $percent;

                my $j = int $percent * $#{$color_ar};

                $char = sprintf $CELL, $color_ar->[$j], $char;
            }

            push @row, { char => $char };
        }

        if ( $vt )
        {
            push @row, { char => $vt };
        }

        push @matrix, \@row;
    }

    if ( $self->{border} )
    {
        my @row = (
            { char => $bl },
            ( { char => $hz } ) x ( $size - 2 ),
            { char => $br },
        );
        push @matrix, \@row;
    }

    return _pivot( \@matrix )
        if $self->{orientation} eq 'vertical';

    return \@matrix;
}

sub _render {
    my ($self, $matrix_ar) = @_;

    my @lines;

    for my $row_ar (@{ $matrix_ar })
    {
        my @line;

        for my $col_hr (@{ $row_ar })
        {
            push @line, $col_hr->{char};
        }

        push @lines, join "", @line;
    }

    my $chart = join "\n", @lines;

    utf8::encode($chart);

    return $chart;
}

sub _dimensions {
    my ($self) = @_;

    my ( $width, $height ) = GetTerminalSize();

    $height--; # leave one line for the command prompt

    $self->{width}  ||= $width;
    $self->{height} ||= $height;

    $width  = $width < $self->{width}   ? $width  : $self->{width};
    $height = $height < $self->{height} ? $height : $self->{height};

    return ( $width, $height );
}

sub _pivot {
    my ($matrix_ar) = @_;

    my @matrix;

    for my $row_i ( 0 .. $#{$matrix_ar} )
    {
        for my $col_i ( 0 .. $#{ $matrix_ar->[$row_i] } )
        {
            my $p_row_i = $#{ $matrix_ar->[$row_i] } - $col_i;
            my $p_col_i = $row_i;

            $matrix[$p_row_i] //= [];
            $matrix[$p_row_i]->[$p_col_i] = $matrix_ar->[$row_i]->[$col_i];
        }
    }

    return \@matrix;
}

1;
