package School::Evaluation::Gibbmers::Chart;
$School::Evaluation::Gibbmers::Chart::VERSION = '0.004';
# No guarantee given, use at own risk and will
# ABSTRACT: render a chart
use strict;
use warnings;

use Chart::Clicker;
use Chart::Clicker::Context;
use Chart::Clicker::Data::DataSet;
use Chart::Clicker::Data::Marker;
use Chart::Clicker::Data::Series::Size;
use Geometry::Primitive::Rectangle;
use Chart::Clicker::Renderer::Bubble;
use Geometry::Primitive::Circle;

# only needed to monkey with color changing
use Graphics::Color::RGB;
use Chart::Clicker::Drawing::ColorAllocator;

sub new {
    my $class = shift;
    my $self  = {
                    bad => [0, 0, 0],
                    mid => [0, 0, 0],
                    hig => [0, 0, 0],
                    sup => [0, 0, 0],
        };
    bless ($self, $class);
}
sub set_1bad_sizes {
    my $self = shift;
    $self->{bad} = shift;
}
sub set_2mid_sizes {
    my $self = shift;
    $self->{mid} = shift;
}
sub set_3hig_sizes {
    my $self = shift;
    $self->{hig} = shift;
}
sub set_4sup_sizes {
    my $self = shift;
    $self->{sup} = shift;
}

sub render_chart {
    my $self     = shift;
    my $title    = shift;
    my $filename = shift;

    my $cc = Chart::Clicker->new(   width  => 400,
                                    height => 300,
                                    format => 'png');
    
    my $values_bad = Chart::Clicker::Data::Series::Size->new(
        keys    => [qw(1 2 3)],
        values  => [qw(1 1 1)],
        sizes   => $self->{bad},
        name    => "Schlecht"
    );
    
    my $values_mid = Chart::Clicker::Data::Series::Size->new(
        keys    => [qw(1 2 3)],
        values  => [qw(2 2 2)],
        sizes   => $self->{mid},
        name    => "Naja"
    );
    
    my $values_hig = Chart::Clicker::Data::Series::Size->new(
        keys    => [qw(1 2 3)],
        values  => [qw(3 3 3)],
        sizes   => $self->{hig},
        name    => "Gut"
    );
    
    my $values_sup = Chart::Clicker::Data::Series::Size->new(
        keys    => [qw(1 2 3)],
        values  => [qw(4 4 4)],
        sizes   => $self->{sup},
        name    => "Super"
    );
    
    $cc->title->text($title);
    $cc->title->padding->bottom(5);
    
    my $ds = Chart::Clicker::Data::DataSet->new(
        series => [ $values_bad,
                    $values_mid,
                    $values_hig,
                    $values_sup,
                  ]);
    
    $cc->add_to_datasets($ds);

    # COLORS #
    ##########
    # build the color allocator
    my $ca = Chart::Clicker::Drawing::ColorAllocator->new;
    # this hash is simply here to make things readable and cleaner,
    # can always call G::C::R inline
    my $green = Graphics::Color::RGB->new({
        red => 0,green => 1, blue=> 0, alpha=> .9
    });
    my $green_red = Graphics::Color::RGB->new({
        red => 0.25,green => .75, blue=> 0, alpha=> .9
    });
    my $red_green = Graphics::Color::RGB->new({
        red => .75, green => 0.25, blue => 0, alpha => .9
    });
    my $red= Graphics::Color::RGB->new({
        red => 1, green => 0, blue => 0, alpha => .9
    });
    # add colors
    $ca->add_to_colors($red);
    $ca->add_to_colors($red_green);
    $ca->add_to_colors($green_red);
    $ca->add_to_colors($green);
    $cc->color_allocator($ca);

    
    my $cnf = $cc->get_context('default');
    
    $cnf->range_axis->fudge_amount(.2);
    $cnf->domain_axis->fudge_amount(.2);
    $cnf->range_axis->hidden(0);
    $cnf->domain_axis->hidden(0);
    $cnf->range_axis->tick_values([qw(1 2 3 4)]);
    $cnf->range_axis->tick_labels(['Schlecht', 'Naja', 'Gut', 'Super']);
    $cnf->domain_axis->tick_values([qw(1 2 3)]);
    $cnf->domain_axis->tick_labels(['wenig Interesse', 'Interessant', 'Lieblingsfach']);
    $cnf->renderer(Chart::Clicker::Renderer::Bubble->new);
    
    $cc->write_output($filename);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

School::Evaluation::Gibbmers::Chart - render a chart

=head1 VERSION

version 0.004

=head1 SYNOPSIS

 my $chart = School::Evaluation::Gibbmers::Chart->new();
  
 $chart->set_1bad_sizes(\@bad_values);
 $chart->set_2mid_sizes(\@ok_values);
 $chart->set_3hig_sizes(\@good_values);
 $chart->set_4sup_sizes(\@supherb_values);
  
 $chart->render_chart( 'title', 'path/pic.png' );

=head1 WARNINGS

This is an early release.
Currently the app is only in German.

=head1 AUTHOR

Boris Däppen <bdaeppen.perl@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Boris Däppen.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
