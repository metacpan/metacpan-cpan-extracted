package PDF::FromHTML::Template::Context;

use strict;

BEGIN {
    use vars qw(@ISA);
    @ISA = qw(PDF::FromHTML::Template::Base);

    use PDF::FromHTML::Template::Base;

    use PDF::FromHTML::Template::Constants qw( %PointsPer );
}

# This is a helper object.    It is not instantiated by the user,
# nor does it represent an XML object.    Rather, every container
# will use this object to maintain the context for its children.

sub new {
    my $class = shift;
    my $self = $class->SUPER::new(@_);

    $self->{FONTS}     = {} unless UNIVERSAL::isa($self->{FONTS},     'HASH');
    $self->{IMAGES}    = {} unless UNIVERSAL::isa($self->{IMAGES},    'HASH');
    $self->{PARAM_MAP} = [] unless UNIVERSAL::isa($self->{PARAM_MAP}, 'ARRAY');
    $self->{STACK}     = [] unless UNIVERSAL::isa($self->{STACK},     'ARRAY');

    $self->reset_pagebreak;

    return $self;
}

sub param {
    my $self = shift;
    my ($param, $depth) = @_;
    $param = uc $param;
    $depth ||= 0;

    my $val = undef;
    my $found = 0;
    for my $map (reverse @{$self->{PARAM_MAP}}) {
        next unless exists $map->{$param};
        $depth--, next if $depth;

        $found = 1;
        $val = $map->{$param};
        last;
    }

    die "Parameter '$param' not found", $/
        if !$found && $self->{DIE_ON_NO_PARAM};

    return $val;
}

#GGG This is god-awful
my %isDimension = map { $_ => 1 } qw(
    X Y W H R
    START_Y END_Y
    X1 X2 Y1 Y2
    PAGE_HEIGHT PAGE_WIDTH
    HEADER_HEIGHT FOOTER_HEIGHT
    LEFT_MARGIN RIGHT_MARGIN
    LMARGIN RMARGIN
    SIZE WIDTH SCALE
);

sub resolve {
    my $self = shift;
    my ($obj, $key, $depth) = @_;
    $key = uc $key;
    $depth ||= 0;

    my $obj_val = $obj->{$key};

    my $is_param = 0;
    $is_param = 1 if $obj_val =~ s/\$(\w+)/$self->param($1)/eg;
    return $obj_val unless $isDimension{$key};

#GGG Does this adequately test values to make sure they're legal??
    # A value is defined as:
    #    1) An optional operator (+, -, *, or /)
    #    2) A decimal number
    #    3)    An optional unit (currently I, P, or C) or % (indicating percentage)

#GGG Convert this to use //x
    my ($op, $val, $unit) = $obj_val =~ m!^\s*([\+\*\/\-])?\s*([\d.]*\d)\s*([a-z%]+)?\s*$!oi;
    $op ||= '';

    if ($unit) {
        # Only the first character of the unit is useful, and it needs to be uppercase to key
        # into %PointsPer.
        my $uom = uc substr($unit, 0, 1);

        if ($uom eq '%') {
#GGG Is this all that's needed?
            if ($key eq 'W') {
                $val *= ($self->get($obj, 'PAGE_WIDTH') -
                            $self->get($obj, 'LEFT_MARGIN') -
                            $self->get($obj, 'RIGHT_MARGIN'));
            }
            elsif ($key eq 'H') {
                $val *= ($self->get($obj, 'PAGE_HEIGHT') -
                            $self->get($obj, 'HEADER_HEIGHT') -
                            $self->get($obj, 'FOOTER_HEIGHT'));
            }
            $val /= 100;
        }
        elsif (exists $PointsPer{$uom}) {
            $val *= $PointsPer{$uom};
        }
        else {
            warn "'$unit' is not a recognized unit of measurement.", $/;
        }

        $obj->{$key} = $op . $val unless $is_param;

        $obj_val = $val;
    }

    return $obj_val unless $op;

    my $prev_val = $key eq 'X' || $key eq 'Y'
        ? $self->{$key}
        : $self->get($obj, $key, $depth + 1);

    return $obj_val unless defined $prev_val;
    return $prev_val unless defined $obj_val;

    # Prevent divide-by-zero issues.
    return $val if $op eq '/' and $val == 0;

    my $new_val;
    for ($op) {
        /^\+$/ && do { $new_val = ($prev_val + $val); last; };
        /^\-$/ && do { $new_val = ($prev_val - $val); last; };
        /^\*$/ && do { $new_val = ($prev_val * $val); last; };
        /^\/$/ && do { $new_val = ($prev_val / $val); last; };

        die "Unknown operator '$op' in arithmetic resolve", $/;
    }

    return $new_val if defined $new_val;
    return;
}

sub enter_scope {
    my $self = shift;
    my ($obj) = @_;

    push @{$self->{STACK}}, $obj;

    for my $key (qw(X Y)) {
        next unless exists $obj->{$key};
        $self->{$key} = $self->resolve($obj, $key);
    }

    return 1;
}

sub exit_scope {
    my $self = shift;
    my ($obj, $no_delta) = @_;

    unless ($no_delta) {
        my $deltas = $obj->deltas($self);
        $self->{$_} += $deltas->{$_} for keys %$deltas;
    }

    pop @{$self->{STACK}};

    return 1;
}

sub get {
    my $self = shift;
    my ($dummy, $key, $depth) = @_;
    $depth ||= 0;
    $key = uc $key;

    return unless @{$self->{STACK}};

    my $obj = $self->{STACK}[-1];
    if (exists $obj->{"TEMP_$key"}) {
        my $val = delete $obj->{"TEMP_$key"};
        return $val;
    }

    return $self->{$key} if $key eq 'X' || $key eq 'Y';

    my $val = undef;
    my $this_depth = $depth;
    foreach my $e (reverse @{$self->{STACK}}) {
        next unless exists $e->{$key};
        next if $this_depth-- > 0;

        $val = $self->resolve($e, $key, $depth);
        last;
    }

    $val = $self->{$key} unless defined $val;
    return $val unless defined $val;

    return $self->param($1, $depth) if $val =~ /^\$(\S+)$/o;

    return $val;
}

sub should_render {
    my $self = shift;
    my ($obj) = @_;

    # The objects for which this would be bad are going to bypass this check as they
    # see fit. All other objects should not render if the pagebreak has been tripped.
    return 0 if $self->pagebreak_tripped;

    return $self->check_end_of_page($obj);
}

sub check_end_of_page {
    my $self = shift;
    my ($obj) = @_;

    my $deltas = $obj->deltas($self);

    if (
        ($self->get($obj, 'Y') || 0) + ($deltas->{Y} || 0)
            < ($self->get($obj, 'END_Y') || 0)
    ) {
        $self->trip_pagebreak;
        return 0;
    }

    return 1;
}

sub close_images {
    my $self = shift;
    my $p = $self->{PDF};

    $p->close_image($_) for values %{$self->{IMAGES}};
}

sub new_page_def {
    my $self = shift;

    $self->{PARAM_MAP}[0]{__PAGEDEF__}++;
    $self->{PARAM_MAP}[0]{__PAGEDEF_PAGE__} = 1;
}

sub trip_pagebreak       { $_[0]{PB_TRIP} = 1 }
sub reset_pagebreak      { $_[0]{PB_TRIP} = 0 }
sub pagebreak_tripped    { $_[0]{PB_TRIP} = $_[1] if defined $_[1]; $_[0]{PB_TRIP} }
sub store_font           { $_[0]{FONTS}{$_[1]} ||= $_[2] }
sub retrieve_font        { $_[0]{FONTS}{$_[1]} }
sub delete_fonts         { $_[0]{FONTS} = {}; }
sub store_image          { $_[0]{IMAGES}{$_[1]} ||= $_[2] }
sub retrieve_image       { $_[0]{IMAGES}{$_[1]} }
sub increment_pagenumber { $_[0]{PARAM_MAP}[0]{$_}++ for qw(__PAGE__ __PAGEDEF_PAGE__) }

1;
__END__
