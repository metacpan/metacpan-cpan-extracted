package TestHighlight;
use warnings;
use Syntax::Highlight::Engine::Kate;
use File::Find;
use File::Spec::Functions 'catfile';
use Exporter 'import';
our @EXPORT_OK = qw(
  get_highlighter
  highlight_perl
  slurp
  get_sample_perl_files
);
our %EXPORT_TAGS = ( all => \@EXPORT_OK );

my ( $BEFORE, $HIGHLIGHTED ) = ( 't/perl/before', 't/perl/highlighted' );

=head1 EXPORT

=over 4

=item * get_highlighter

 my $highlighter = get_highlighter($language);

Returns a new C<Syntax::Highlight::Engine::Kate> highlighter for testing.
Defaults to Perl if no language specified.

All tokens are wrapped in tags corresponding to the token type:

 <keyword>my</keyword>

=item * slurp

Slurps and returns the contents of a file.

=teim * get_sample_perl_files

 my $files = get_sample_perl_files();
 while ( my ( $perl, $highlighted ) = each %$files ) {
    ...
 }

Returns a hashref. Keys are the names of the raw Perl files in
F<t/perl/before> and values are the filenames of the highlighted versions
found in F<t/perl/highlighted>.

See F<bin/regen.pl> to understand how to regenerate these fixtures.

See F<t/perl_highlighting.t> for an example of testing with this.

=back

=cut

sub highlight_perl {
    my $code = shift;
    return get_highlighter('Perl')->highlightText($code);
}

sub get_highlighter {
    my $syntax = shift || 'Perl';
    return Syntax::Highlight::Engine::Kate->new(
        language     => $syntax,
        format_table => {
            map { _make_token($_) }
              qw/
              Alert
              BaseN
              BString
              Char
              Comment
              DataType
              DecVal
              Error
              Float
              Function
              IString
              Keyword
              Normal
              Operator
              Others
              RegionMarker
              Reserved
              String
              Variable
              Warning
              /
        }
    );
}

sub _make_token {
    my $name  = shift;
    my $token = lc $name;
    return $name => [ "<$token>" => "</$token>" ];
}

sub slurp {
    my $file = shift;
    open my $fh, '<', $file or die "Cannot open $file for reading: $!";
    return do { local $/; <$fh> };
}

sub get_sample_perl_files {
    my %highlighted_file_for;
    find(
        sub {
            $highlighted_file_for{ catfile( $BEFORE, $_ ) } =
              catfile( $HIGHLIGHTED, $_ )
              if -f $_ && /\.pl$/;
        },
        $BEFORE
    );
    return \%highlighted_file_for;
}

1;
