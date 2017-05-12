package Pod::Perldoc::Cache;
use 5.008005;
use strict;
use warnings;
use File::Spec::Functions qw(catfile catdir);
use File::Path qw(mkpath);
use Digest::MD5 qw(md5_hex);
use Pod::Text ();
use constant DEFAULT_PARSER_CLASS => 'Pod::Text';

our @ISA = ('Pod::Text');

our $VERSION = "0.02";

sub parse_from_file {
    my ($self, $pod_file, $out_fh) = @_;
    my $parser_class = do {
        if (exists $self->{_parser_class}) {
            $self->{_parser_class};
        } else {
            DEFAULT_PARSER_CLASS;
        }
    };

    my $cache_dir = _cache_dir($ENV{POD_PERLDOC_CACHE_DIR});
    my $cache_file = _cache_file($cache_dir, $pod_file, $parser_class);

    if (-f $cache_file && not $self->{_ignore_cache}) {
        open my $cache_fh, '<', $cache_file
            or die "Can't open $cache_file: $!";
        print $out_fh $_ while <$cache_fh>;
    } else {
        my $parser = $parser_class->new;
        $parser->parse_from_file($pod_file, $out_fh);

        open my $cache_fh, '>', $cache_file
            or die "Can't write formatted pod to $cache_file\n";
        seek $out_fh, 0, 0;
        print $cache_fh $_ while <$out_fh>;
    }
}

sub _cache_file {
    my ($cache_dir, $file_path, $parser_class) = @_;

    $parser_class =~ s/::/_/g;
    my $digest = _calc_pod_md5($file_path);
    my $suffix = ".$parser_class.$digest";

    $file_path =~ s!/!_!g;
    return catfile($cache_dir, $file_path) . $suffix;
}

sub _cache_dir {
    my $cache_dir = shift;
    unless ($cache_dir) {
        $cache_dir = catdir($ENV{HOME}, '.pod_perldoc_cache');
    }
    unless (-e $cache_dir) {
        mkpath $cache_dir
            or die "Can't create cache directory: $cache_dir";
    }

    return $cache_dir;
}

sub _calc_pod_md5 {
    my $pod_file = shift;
    my $pod = do {
        local $/;
        open my $pod_fh, '<', $pod_file
            or die "Can't read pod file: $!";
        <$pod_fh>;
    };
    return md5_hex($pod);
}

# called by -w option
sub parser {
    my ($self, $parser_class) = @_;

    my $parser_file = $parser_class;
    $parser_file =~ s!\::!/!g;
    eval {
        require "$parser_file.pm";
    };
    if ($@) {
        die $@;
    } else {
        $self->{_parser_class} = $parser_class;
    }
}

# called by -w option
sub ignore {
    my $self = shift;
    $self->{_ignore_cache} = 1;
}

1;
__END__

=encoding utf-8

=head1 NAME

Pod::Perldoc::Cache - Caching perldoc output for quick reference

=head1 SYNOPSIS

    $ perldoc -MPod::Perldoc::Cache CGI
    $ perldoc -MPod::Perldoc::Cache -w parser=Pod::Text::Color::Delight CGI

=head1 DESCRIPTION

Pod::Perldoc::Cache caches the formatted output from perldoc command and references it for the next time. Once the cache file is generated, perldoc command no more formats the pod file, but replies the cache contents instantly. This module keeps track of the pod file contents so that the old cache is invalidated when the pod is updated.

=head1 CONFIGURATION

In default, Pod::Perldoc::Cache uses F<$HOME/.pod_perldoc_cache directory> for keeping cache files. By setting the environment variable B<POD_PERLDOC_CACHE_DIR>, you can select cache directory anywhere you want.

=head1 COMMAND LINE OPTIONS

=over 4

=item -w parser=Parser::Module

With "-w parser" command line option, you can specify the parser (formatter) module for perldoc which is used when the cache file doesn't exist.

=item -w ignore

If "-w ignore" command line option is given, the cache file is ignored and the pod file is re-rendered.

=back

=head1 SEE ALSO

L<Pod::Text>,
L<Pod::Text::Color::Delight>

=head1 LICENSE

Copyright (C) Yuuki Furuyama.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Yuuki Furuyama E<lt>addsict@gmail.comE<gt>

=cut

