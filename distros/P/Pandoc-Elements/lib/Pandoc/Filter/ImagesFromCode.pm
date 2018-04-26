package Pandoc::Filter::ImagesFromCode;
use strict;
use warnings;
use utf8;
use Encode;
use 5.010;

our $VERSION = '0.36';

use Digest::MD5 'md5_hex';
use IPC::Run3;
use File::Spec::Functions;
use File::stat;
use Pandoc::Elements;
use Scalar::Util 'reftype';
use parent 'Pandoc::Filter', 'Exporter';

our @EXPORT_OK = qw(read_file write_file);

sub new {
    my ($class, %opts) = @_;

    $opts{from} //= 'code';
    $opts{dir} //= '.';
    $opts{dir} =~ s!/$!!;
    $opts{name} //= sub {
        $_[0]->id =~ /^[a-z0-9_]+$/i ? $_[0]->id
            : md5_hex( encode( 'utf8', $_[0]->content ) );
    };

    die "missing option: to\n" unless $opts{to};

    if ('ARRAY' ne reftype $opts{run} or !@{$opts{run}}) {
        die "missing or empty option: run\n";
    }

    bless \%opts, $class;
}

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

sub action {
    my $self = shift;

    sub {
        my ($e, $format, $m) = @_;

        return if $e->name ne 'CodeBlock';

        my $code = $e->content;
        my $dir  = $self->{dir};

        my %args = (
            name => $self->{name}->($e),
            from => $self->{from},
            to   => $self->to($format),
        );
        $args{infile}  = catfile($self->{dir}, "$args{name}.$args{from}");
        $args{outfile} = catfile($self->{dir}, "$args{name}.$args{to}");

        # TODO: document or remove this experimental code. If keep, expand args
        my $kv = $e->keyvals;
        my @options = $kv->get_all('option');
        push @options, map { split /\s+/, $_ } $kv->get_all('options');

        # TODO: print args in debug mode?

        # skip transformation if nothing has changed
        my $in  = stat($args{infile});
        my $out = stat($args{outfile});
        if (!$self->{force} and $in and $out and $in->mtime <= $out->mtime) {
            if ($code eq read_file($args{infile}, ':utf8')) {
                # no need to rebuild the same outfile
                return build_image($e, $args{outfile});
            }
        }

        write_file($args{infile}, $code, ':utf8');

        my ($stderr, $stdout);
        my @command = map {
                  my $s = $_;
                  #if ($args{substr $s, 1, -1})
                  $s =~ s|\$([^\$]+)\$| $args{$1} // $1 |eg;
                  $s
                } @{$self->{run}};
        push @command, @options;

        run3 \@command, \undef, \$stdout, \$stderr,
            {
                binmode_stdin  => ':utf8',
                binmode_stdout => ':raw',
                binmode_stderr => ':raw',
            };

        if ($self->{capture}) {
            write_file($args{outfile}, $stdout, ':raw');
        }

        # TODO: include $code or $stderr on error in debug mode
        # TODO: skip error if requested
        die $stderr if $stderr;

        return build_image($e, $args{outfile});
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

    my $keyvals = $e->keyvals;
    my $title = $keyvals->get('title') // '';
    my $img = Image attributes { id => $e->id, class => $e->class },
        [], [$filename, $title];

    my $caption = $keyvals->get('caption') // '';
    if (defined $caption) {
        push @{$img->content}, Str($caption);
    }

    return Plain [ $img ];
}

sub write_file {
    my ($file, $content, $encoding) = @_;

    open my $fh, ">$encoding", $file
        or die "failed to create file $file: $!\n";
    print $fh $content;
    close $fh;
}

sub read_file {
    my ($file, $encoding) = @_;

    open my $fh, "<$encoding", $file
        or die "failed to open file: $file: $!\n";

    my $content = do { local $/; <$fh> };
    close $fh or die "failed to close file: $file: $!\n";

    return $content;
}

1;

__END__

=head1 NAME

Pandoc::Filter::ImagesFromCode - transform code blocks into images

=head1 DESCRIPTION

This L<Pandoc::Filter> transforms L<CodeBlock|Pandoc::Elements/CodeBlock>
elements into L<Image|Pandoc::Elements/Image> elements. Content of transformed
code section and resulting image files are written to files.

Attribute C<title> is mapped to the image title and attribute C<caption> to
an image caption, if available.

=head1 CONFIGURATION

=over

=item from

File extension of input files extracted from code blocks. Defaults to C<code>.

=item to

File extension of created image files. Can be a fixed string or a code reference that
gets the document output format (for instance L<latex> or C<html>) as argument to
produce different image formats depending on output format.

=item name

Code reference that maps the L<CodeBlock|Pandoc::Elements/CodeBlock> element to
a filename (without directory and extension). By default the element's C<id> is
used if it contains characters no other than C<a-zA-Z0-9_->. Otherwise the name
is the MD5 hash of the element's content.

=item dir

Directory where to place input and output files, relative to the current
directory. This directory (default C<.>) is prepended to all image references
in the target document.

=item run

Command to transform input files to output files. Variable references C<$...$>
can be used to refer to current values of C<from>, C<to>, C<name>, C<dir>,
C<infile> and C<outfile>. Example:

  run => ['ditaa', '-o', '$infile$', '$outfile$'],

=item capture

Capture output of command and write it to C<outfile>. Disabled by default.

=item force

Apply transformation also if input and output file already exists unchanged.
Disabled by default.

=back

=cut
