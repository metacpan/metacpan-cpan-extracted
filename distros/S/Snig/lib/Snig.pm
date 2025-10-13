use v5.40;
use feature 'class';
no warnings "experimental::class";

class Snig {
    our $VERSION = '1.001'; # VERSION
    # ABSTRACT: (Simple|Static|Small|S..) Image Gallery
    # PODNAME: Snig

    use Log::Any qw($log);
    use Path::Tiny qw(path);

    use Snig::Collection;
    use Snig::Image;

    field $name :reader :param;
    field $th_size :reader :param = 200;
    field $detail_size :reader :param = 1000;
    field $sort_by :reader :param = 'created'; # TODO
    field $input :reader :param;
    field $output :reader :param;
    field $force :reader :param;

    ADJUST {
        $input = path($input);
        $output = path($output);
        $output->mkdir;

        $force = { map { $_ => 1 } $force->@* };
    }

    method run {
        my $collection = Snig::Collection->new(input => $input, sort_by => $sort_by, name => $name);
        $collection->resize_images($output, $th_size, $detail_size, $force->{resize} || 0);
        $collection->write_html_pages($output);
        $collection->write_index($output, $force->{zip} || 0);
    }
}

__END__

=pod

=encoding UTF-8

=head1 NAME

Snig - (Simple|Static|Small|S..) Image Gallery

=head1 VERSION

version 1.001

=head1 SYNOPSIS

Yet another static image HTML photo gallery generator.

I wanted to play with new Perl class syntax instead of learning to configure one of the hundred existings generators, so...

This class is basically only the runner calling L<Snig::Collection>. See L<snig.pl> for command line opts etc.

=head1 AUTHOR

Thomas Klausner <domm@plix.at>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2025 by Thomas Klausner.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
