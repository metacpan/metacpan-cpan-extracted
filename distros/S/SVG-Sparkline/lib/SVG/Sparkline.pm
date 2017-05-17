package SVG::Sparkline;

use warnings;
use strict;
use Carp;
use SVG;

use overload  '""' => \&to_string;

use 5.008000;
our $VERSION = 1.12;

my %valid_parms = map { $_ => 1 } qw(
        -allns color -sized
        height width xscale yscale pady padx
        color bgcolor mark values
);

sub new
{
    my ($class, $type, $args) = @_;
    croak "No Sparkline type specified.\n" unless defined $type;
    croak "'$type' is not a valid Sparkline type.\n" unless $type =~ m/\A[A-Z]\w+\z/;
    # Use eval to load plugin. Should be safe because of the test above.
    eval "use SVG::Sparkline::$type;";  ## no critic (ProhibitStringyEval)
    croak "Unrecognized Sparkline type '$type'.\n" if $@;
    croak "Missing arguments hash.\n" unless defined $args;
    croak "Arguments not supplied as a hash reference.\n" unless 'HASH' eq ref $args;
    _no_unrecognized_parameters( $type, $args );

    my $self = bless {
        -allns => 0,
        color => '#000',
        -sized => 1,
        %{$args},
    }, $class;

    $self->_validate_pos_param( 'height', 12 );
    $self->_validate_pos_param( 'width', 0 );
    $self->_validate_pos_param( 'xscale' );
    $self->_validate_pos_param( 'yscale' );
    $self->_validate_nonneg_param( 'pady', 1 );
    $self->_validate_nonneg_param( 'padx', 0 );
    $self->_validate_mark_param();
    foreach my $arg (qw/color bgcolor/)
    {
        next unless exists $self->{$arg};
        croak "The value of $arg is not a valid color.\n"
            unless _is_color( $self->{$arg} );
    }

    $self->{xoff} = -$self->{padx};
    $self->_make( $type );

    return $self;
}

sub get_height { return $_[0]->{height}; }
sub get_width { return $_[0]->{width}; }

sub to_string
{
    my ($self) = @_;
    my $str = $self->{_SVG}->xmlify();
    # Cleanup
    $str =~ s/ xmlns:(?:svg|xlink)="[^"]+"//g unless $self->{'-allns'};
    unless( $self->{'-sized'} )
    {
        # If I try to keep them from being created, default '100%' values
        # show up instead.
        $str =~ s/(<svg[^>]*) height="[^"]+"/$1/;
        $str =~ s/(<svg[^>]*) width="[^"]+"/$1/;
    }
    return $str;
}

sub _make
{
    my ($self, $type) = @_;
    $self->{_SVG} = "SVG::Sparkline::$type"->make( $self );
    return;
}

sub _no_unrecognized_parameters {
    my ( $type, $args ) = @_;
    my $class = "SVG::Sparkline::$type";
    foreach my $parm (keys %{$args}) {
        croak "Parameter '$parm' not recognized for '$type'\n"
            unless exists $valid_parms{$parm} || $class->valid_param( $parm );
    }
    return;
}

sub _validate_pos_param
{
    my ($self, $name, $default) = @_;
    croak "'$name' must have a positive numeric value.\n"
        if exists $self->{$name} && $self->{$name} <= 0;
    return if exists $self->{$name};

    $self->{$name} = $default if defined $default;
    return;
}

sub _validate_nonneg_param
{
    my ($self, $name, $default) = @_;
    croak "'$name' must be a non-negative numeric value.\n"
        if exists $self->{$name} && $self->{$name} < 0;
    return if exists $self->{$name};

    $self->{$name} = $default if defined $default;
    return;
}

sub _validate_mark_param
{
    my ($self) = @_;

    return unless exists $self->{mark};

    croak "'mark' parameter must be an array reference.\n"
        unless 'ARRAY' eq ref $self->{mark};
    croak "'mark' array parameter must have an even number of elements.\n"
        unless 0 == (@{$self->{mark}}%2);

    my @marks = @{$self->{mark}};
    while(@marks)
    {
        my ($index, $color) = splice( @marks, 0, 2 );
        croak "'$index' is not a valid mark index.\n"
            unless $index =~ /^(?:first|last|high|low|\d+)$/;
        croak "'$color' is not a valid mark color.\n"
            unless _is_color( $color );
    }
    return;
}

sub _is_color
{
    my ($color) = @_;
    return 1 if $color =~ /^#[[:xdigit:]]{3}$/;
    return 1 if $color =~ /^#[[:xdigit:]]{6}$/;
    return 1 if $color =~ /^rgb\(\d+,\d+,\d+\)$/;
    return 1 if $color =~ /^rgb\(\d+%,\d+%,\d+%\)$/;
    return 1 if $color =~ /^[[:alpha:]]+$/;
    return;
}

1;

__END__

=head1 NAME

SVG::Sparkline - Create Sparklines in SVG

=head1 VERSION

This document describes SVG::Sparkline version 1.11

=head1 SYNOPSIS

    use SVG::Sparkline;

    my $sl1 = SVG::Sparkline->new( Whisker => { values=>\@values, color=>'#eee', height=>12 } );
    print $sl1->to_string();

    my $sl2 = SVG::Sparkline->new( Line => { values=>\@values, color=>'blue', height=>12 } );
    print $sl2->to_string();

    my $sl3 = SVG::Sparkline->new( Area => { values=>\@values, color=>'green', height=>10 } );
    print $sl3->to_string();

    my $sl4 = SVG::Sparkline->new( Bar => { values=>\@values, color=>'#66f', height=>10 } );
    print $sl4->to_string();
  
    my $sl5 = SVG::Sparkline->new( RangeBar => { values=>\@value_pairs, color=>'#66f', height=>10 } );
    print $sl5->to_string();
  
=head1 DESCRIPTION

In the book I<Beautiful Evidence>, Edward Tufte describes sparklines as
I<small, high-resolution, graphics embedded in a context of words, numbers, images>. 

This module provides a relatively easy interface for creating different
kinds of sparklines. This class is not intended to be used to build large,
complex graphs (there are other modules much more suited to that job). The
focus here is on the kinds of data well-suited to the sparklines concept.

See L<SVG::Sparkline::Manual> for the full usage documentation for the module.

=head1 INTERFACE

=head2 SVG::Sparkline->new( $type, $args_hr )

Create a new L<SVG::Sparkline> object of the specified type, using the
parameters in the C<$args_hr> hash reference.

See L<SVG::Sparkline::Manual> for the details.

=head2 get_height

Returns in height in pixels of the completed sparkline.

=head2 get_width

Returns in width in pixels of the completed sparkline.

=head2 to_string

Convert the L<SVG::Sparkline> object to an XML string. This is the method that
is used by the stringification overload.

=head1 DIAGNOSTICS

Diagnostic message for the various types are documented in the appropriate
F<SVG::Sparkline::*> module.

=head1 CONFIGURATION AND ENVIRONMENT

SVG::Sparkline requires no configuration files or environment variables.

=head1 DEPENDENCIES

L<Carp>, L<SVG>.

=head1 INCOMPATIBILITIES

None reported.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-svg-sparkline@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.

=head1 ACKNOWLEDGEMENTS

This module has been greatly improved by suggestions and corrections supplied
but Robert Boone, Debbie Campbell, and Joshua Keroes.

=head1 AUTHOR

G. Wade Johnson  C<< <gwadej@cpan.org> >>

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2015, G. Wade Johnson C<< <gwadej@cpan.org> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl 5.8.0. See L<perlartistic>.

=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.
