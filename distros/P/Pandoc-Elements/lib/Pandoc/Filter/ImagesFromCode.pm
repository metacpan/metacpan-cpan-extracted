package Pandoc::Filter::ImagesFromCode;
use strict;
use warnings;
use 5.010;

our $VERSION = '0.34';

use Digest::MD5 'md5_hex';
use IPC::Run3;
use Pandoc::Elements;
use parent 'Pandoc::Filter';

sub new {
    my ($class, %opts) = @_;
    bless \%opts, $class;
}

# input type extension
sub from {
    $_[0]->{from} // 'code';
}

# output type extension
sub to {
    my $to     = $_[0]->{to};
    my $format = $_[1];
    if (ref $to) {
        return $to->($format);
    } elsif ($to) {
        return $to;
    } else {
        return 'png';
    }
}

# conversion command
sub run {
    $_[0]->{run};
}

sub action {
    my $filter = shift;
    my $run = $filter->run or return sub {};

    sub {
        my ($e, $f, $m) = @_;

        return if $e->name ne 'CodeBlock';

        my $code = $e->content;
        my $dir  = "."; # TODO: configure this
     
        my %args;
        $args{md5}      = md5_hex($code);
        $args{from}     = $filter->from;
        $args{to}       = $filter->to($f);
        $args{infile}   = "$dir/".$args{md5}.".".$args{from};
        $args{outfile}  = "$dir/".$args{md5}.".".$args{to};

        # TODO: document this
        my $kv = $e->keyvals;
        my @options = $kv->get_all('option');
        push @options, map { split /\s+/, $_ } $kv->get_all('options');
        # TODO: expand args in options

        # TODO: print args in debug mode?

        open my $fh, ">", $args{infile} 
            or die "failed to create file: ".$args{infile}."\n";
        binmode $fh, ':encoding(UTF-8)';
        print $fh $code;
        close $fh;

        my ($stderr, $stdout);
        my @command = map { 
                  my $s = $_; 
                  #if ($args{substr $s, 1, -1}) 
                  $s =~ s|\$([^\$]+)\$| $args{$1} // $1 |eg; 
                  $s 
                } @$run;
        push @command, @options;

        run3 \@command, \undef, \$stdout, \$stderr,
            {
                binmode_stdin  => ':utf8',
                binmode_stdout => ':raw',
                binmode_stderr => ':raw',
            };

        # TODO: include $code or $stderr on error in debug mode
        # TODO: skip error if requested
        die $stderr if $stderr;

        my $img = build_image($e, $args{outfile});
        # TODO: move/add attributes to the Div
        return Div attributes {}, [ Plain [ $img ] ];
    }
}

# build_image( $element [, $filename ] )
#
# Maps an element to an L<Image|Pandoc::Elements/Image> element with attributes
# from the given element. The attribute C<caption>, if available, is transformed
# into image caption. This utility function is useful for filters that transform
# content to images. See graphviz, tikz, lilypond and similar filters in the
# L<examples|https://metacpan.org/pod/distribution/Pandoc-Elements/examples/>.

sub build_image {
    my $e = shift;
    my $filename = shift // '';

    my $img = Image [$e->id, $e->classes, []], [], [$filename, ''];
    my $keyvals = $e->keyvals;

    my $caption = $keyvals->get('caption');
    if (defined $caption) {
        push @{$img->content}, Str($caption);
        $img->target->[1] = 'fig:';
        $keyvals->remove('caption');
    }
    $img->keyvals($keyvals);

    return $img;
}

1;

__END__

=head1 NAME

Pandoc::Filter::ImagesFromCode - transform code blocks into images

=head1 DESCRIPTION

This L<Pandoc::Filter> transforms L<CodeBlock|Pandoc::Elements/CodeBlock>
elements into images. The specific interface may change in a future version.

=cut
