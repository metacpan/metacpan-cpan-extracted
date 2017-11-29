package School::Code::Compare::Out;
# ABSTRACT: oragnize the output to different formats
$School::Code::Compare::Out::VERSION = '0.002';
use strict;
use warnings;

use Template;
use School::Code::Compare::Out::Template::Path;

sub new {
    my $class = shift;

    my $self = {
                    name   => time(),
                    format => 'tab',
                    lines  => [],
                    title  => 'Comparion',
                    description => 'a list of files',
               };
    bless $self, $class;

    return $self;
}

sub set_name {
    my $self = shift;

    $self->{name} = shift;

    return $self;
}

sub set_format {
    my $self = shift;

    $self->{format} = shift;

    return $self;
}

sub set_lines {
    my $self = shift;

    $self->{lines} = shift;

    return $self;
}

sub set_title {
    my $self = shift;

    $self->{title} = shift;

    return $self;
}

sub set_description {
    my $self = shift;

    $self->{description} = shift;

    return $self;
}

sub write {
    my $self        = shift;

    my @result      = @{$self->{lines}};
    my $format      =   $self->{format};
    my $filename    =   $self->{name};
    my $title       =   $self->{title};
    my $description =   $self->{description};

    my $tt     = Template->new;
    my $tt_dir = School::Code::Compare::Out::Template::Path->get();
    
    # sort by ratio, but make sure undef values are "big" (meaning, bottom/last)
    my @result_sorted = sort { return  1 if (not defined $a->{ratio});
                               return -1 if (not defined $b->{ratio});
                               return $a->{ratio} <=> $b->{ratio};
                             } @result;
    
    # we render all rows, appending it to one string
    my $rendered_data_rows = '';
    
    foreach my $comparison (@result_sorted) {
        my $vars = {
            ratio        => $comparison->{ratio},
            distance     => $comparison->{distance},
            delta_length => $comparison->{delta_length},
            suspicious   => $comparison->{suspicious},
            file1        => $comparison->{file1},
            file2        => $comparison->{file2},
            comment      => $comparison->{comment},
        };
    
        $tt->process("$tt_dir/$format.tt", $vars, \$rendered_data_rows)
            || die $tt->error(), "\n";
    }
    
    # render again, this time merging the rendered rows into the wrapping body
    $tt->process(   "$tt_dir/Body$format.tt",
                    {
                      data        => $rendered_data_rows,
                      title       => $title,
                      description => $description
                    },
                    $filename
                )   || die $tt->error(), "\n";

}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

School::Code::Compare::Out - oragnize the output to different formats

=head1 VERSION

version 0.002

=head1 AUTHOR

Boris Däppen <bdaeppen.perl@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Boris Däppen.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
