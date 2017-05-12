package String::Incremental::FormatParser;
use 5.008005;
use warnings;
use Mouse;
use Data::Validator;
use String::Incremental::Char;
use String::Incremental::String;
use MouseX::Types::Mouse qw( Str ArrayRef );
use String::Incremental::Types qw( CharOrderStr CharOrderArrayRef is_CharOrderStr );

has 'format' => ( is => 'ro', isa => Str );
has 'items'  => ( is => 'ro', isa => ArrayRef );

sub BUILDARGS {
    my ($class, @args) = @_;
    return _parse( @args );
}

sub _parse {
    my ($format, @rules) = @_;
    my $pf = _parse_format( $format );

    my $mismatch = ( grep {
        my $pos = $_->{pos};
        defined $pos ? ( defined $rules[$pos] ? 0 : 1 ) : 0;
    } @{$pf->{items}} ) ? 1 : 0;
    if ( $mismatch ) {
        my $msg = 'definition is mismatch: conversions v.s. rules';
        die $msg;
    }

    my @items;
    my $char_upper;
    for my $item ( @{$pf->{items}} ) {
        my $class = "String::Incremental::$item->{type}";
        my $obj;
        if ( $item->{type} eq 'Char' ) {
            $obj = $class->new(
                order => $rules[ $item->{pos} ],
                ( defined $char_upper ? ( upper => $char_upper ) : () ),
            );
            $char_upper = $obj;
        }
        else {
            $obj = $class->new(
                format => $item->{format},
                value  => ( defined $item->{pos} ? $rules[ $item->{pos} ] : '' ),
            );
        }
        push @items, $obj;
    }

    return +{
        format => $pf->{format},
        items  => \@items,
    };
}

sub _parse_format {
    my ($format) = @_;
    die 'no format is specified'  unless defined $format;

    my ($format_rpl, @items);

    ($format_rpl = $format) =~ s{%(\d+)?=}{
        my $n = $1;
        $n = 1 unless defined $n;
        join '', map '%s', (1..$n);
    }gex;

    my @conv = $format =~ /(%(?:\d+(?:\.?\d+)?)?\S)/g;
    my $pos = 0;
    for my $conv ( @conv ) {
        my ($dig, $type) = $conv =~ /%(\d+(?:\.?\d+)?)?(\S)/;
        if ( $type eq '=' ) {
            my $n = defined $dig ? $dig : 1;
            for ( 1 .. $n ) {
                push @items, +{ type => 'Char', pos => $pos };
            }
            $pos++;
        }
        elsif ( $type eq '%' ) {
            push @items, +{ type => 'String', format => $conv, pos => undef };
        }
        else {
            push @items, +{ type => 'String', format => $conv, pos => $pos };
            $pos++;
        }
    }

    return +{
        format     => $format_rpl,
        item_count => 0 + @items,
        items      => \@items,
    };
}

__PACKAGE__->meta->make_immutable();
__END__

=encoding utf-8

=head1 NAME

String::Incremental::Char

=head1 SYNOPSIS

    use String::Incremental::FormatParser;

    my $fp = String::Incremental::FormatParser->new(
        'foo-%2s-%2c-%c',
        sub { (localtime)[5] - 100 },
        [0..2],
        'abcd',
    );


=head1 DESCRIPTION

String::Incremental::FormatParser is ...

=head1 CONSTRUCTORS

=over 4

=item new( $format, @rules ) : String::Incremental::FormatParser

$format : Str

@rules : Araray[ Str|CodeRef ]

=back

=head1 METHODS

=over 4

=back


=head1 LICENSE

Copyright (C) issm.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

issm E<lt>issmxx@gmail.comE<gt>

=cut
