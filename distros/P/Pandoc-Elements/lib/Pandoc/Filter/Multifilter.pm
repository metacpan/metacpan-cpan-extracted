package Pandoc::Filter::Multifilter;
use strict;
use warnings;
use 5.010;

our $VERSION = '0.34';

use parent 'Pandoc::Filter';
our @EXPORT_OK = (qw(find_filter apply_filter));

use Pandoc::Elements 'pandoc_json';
use Pandoc;
use IPC::Cmd 'can_run';
use IPC::Run3;

sub new {
    bless { }, shift;
}

sub apply {
    my ( $self, $doc, $format, $meta ) = @_;
	return $doc if $doc->name ne 'Document';

    my $multi = $doc->meta->{multifilter};
    return $doc if !$multi or $multi->name ne 'MetaList';

    my @filters = map {
        if ($_->name eq 'MetaMap' and $_->{filter}) {
            $_->value
        } elsif ($_->name eq 'MetaString' or $_->name eq 'MetaInlines') {
            { filter => $_->value }
        }
    } @{$multi->content};

    foreach (@filters) {
        my @filter = find_filter($_->{filter});
    	apply_filter($doc, $format, @filter);
    }

    $doc;
}

our %SCRIPTS = (
    hs => 'runhaskell',
    js => 'node',
    php => 'php',
    pl => 'perl',
    py => 'python',
    rb => 'ruby',
);

sub find_filter {
    my $name = shift;
    my $data_dir = shift // pandoc_data_dir;
    $data_dir =~ s|/$||;

    foreach my $filter ("$data_dir/filters/$name", $name) {
        return $filter if -x $filter;
        if (-e $filter and $filter =~ /\.([a-z]+)$/i) {
            if ( my $cmd = $SCRIPTS{lc($1)} ) {
                die "cannot execute filter with $cmd\n" unless can_run($cmd);
                return ($cmd, $filter);
            }
        }
    }

    return (can_run($name) or die "filter not found: $name\n");
}

sub apply_filter {
    my ($doc, $format, @filter) = @_;

    my $stdin  = $doc->to_json;
    my $stdout = "";
    my $stderr = "";

    run3 [@filter, $format // ''], \$stdin, \$stdout, \$stderr;
    if ($?) {
        $stderr .= "\n" if $stderr ne '' and $stderr !~ /\n\z/s;
        die join(' ','filter failed:',@filter)."\n$stderr";
    }

    my $transformed =  eval { pandoc_json($stdout) };
    die join(' ','filter emitted no valid JSON:',@filter)."\n" if $@;

	# modify original document
	$doc->meta($transformed->meta);
	$doc->content($transformed->content);

    return $doc;
}

__END__

=head1 NAME

Pandoc::Filter::Multifilter - apply filters from metadata field C<multifilter>

=head1 DESCRIPTION

This filter is provided as system-wide executable L<multifilter>, see there for
additional documentation.

=head1 METHODS

=head2 new

Create a new multifilter.

=head2 apply( $doc [, $format [, $metadata ] ] )

Apply all filters specified in document metadata field C<metafilters>.

=head1 FUNCTIONS

=head2 find_filter( $name [, $DATADIR ] )

Find a filter by its name in C<$DATADIR/filters>, where C<$DATADIR> is the user
data directory (L<~/.pandoc> or L<%appdata%\pandoc>), and in L<$PATH>. Returns
a list of command line arguments to execute the filter or throw an exception.

=head2 apply_filter( $doc, $format, @filter )

Apply a filter, given by its command line arguments, to a Pandoc
L<Document|Pandoc::Elements/Document> element and return a transformed
Document or throw an exception on error. Can be called like this:

  apply_filter( $doc, $format, find_filter( $name ) );

=cut
