package PPIx::Grep;

use 5.008001;
use utf8;

use strict;
use warnings;

use version; our $VERSION = qv('v0.0.6');

use English qw<-no_match_vars>;
use Carp qw< confess >;
use Readonly;

use Exporter qw< import >;

our @EXPORT_OK =
    qw<
        run
        set_print_format
    >;
our %EXPORT_TAGS    = (
    all => [@EXPORT_OK],
);

use File::Next ();
use Getopt::Long ();
use List::MoreUtils qw< any none >;
use PPI::Document ();
use PPIx::Shorthand qw< get_ppi_class >;
use String::Format qw< stringf >;


Readonly my $NUMBER_OF_PPI_LOCATION_COMPONENTS => 3;
Readonly my $PPI_LINE_NUMBER        => 0;
Readonly my $PPI_CHARACTER_NUMBER   => 1;
Readonly my $PPI_COLUMN_NUMBER      => 2;
Readonly my @OPTIONS => qw<
    format=s
    match=s
    help|h|?
    version|V
>;
#    usage
#    man
#    chomp
#    ignore-case|i
#    files-with-matches|l
#    files-without-match|L
#    no-filename|h
#    with-filename|H
#    line-number|n
#    invert-match|v
#    tab-length
Readonly my $EXIT_CODE_FOUND      => 0;
Readonly my $EXIT_CODE_NOT_FOUND  => 1;
Readonly my $EXIT_CODE_ERROR      => 2;

Readonly my %ignored_directories =>
    map { $_ => 1 }
    qw<
        .bzr
        .cdv
        ~.dep
        ~.dot
        ~.nib
        ~.plst
        .git
        .hg
        .pc
        .svn
        blib
        CVS
        RCS
        SCCS
        _darcs
        _sgbak
        autom4te.cache
        cover_db
        _build
    >;


my $stdout       = *STDOUT;
my $stderr       = *STDERR;
my $match        = undef;
my $print_format = "%f:%l:%c:%s\n";


sub run {
    my @argv = @_;

    binmode _get_stdout(), ':utf8';
    binmode _get_stderr(), ':utf8';

    my %options = _initialize_from_command_line(\@argv);
    if (_handle_info_requests(\%options)) {
        return $EXIT_CODE_ERROR;
    } # end if

    if (@argv < 2) {
        _emit_usage_message();
        return $EXIT_CODE_ERROR;
    } # end if

    my ($pattern, @paths) = @argv;
    my @ppi_classes = _derive_ppi_classes($pattern)
        or return $EXIT_CODE_ERROR;

    my $file_error = 0;
    my $iterator = File::Next::files(
        {
            file_filter => sub {
                    not _is_ignored_file($_)
                and _is_perl_file($File::Next::name, $file_error)
            },
            descend_filter => sub { not _is_ignored_directory($_) },
        },
        @paths,
    );

    my $return_code = $EXIT_CODE_NOT_FOUND;
    while ( defined ( my $file = $iterator->() ) ) {
        my $found_something =
            _search_and_emit(
                $file,
                $file,
                _build_query(\@ppi_classes),
                _get_stdout()
            );

        if (not defined $found_something) {
            $return_code = $EXIT_CODE_ERROR;
        } elsif ( $EXIT_CODE_ERROR != $return_code and $found_something ) {
            $return_code = $EXIT_CODE_FOUND;
        } # end if
    } # end foreach

    if ($file_error) {
        $return_code = $EXIT_CODE_ERROR;
    }

    return $return_code;
} # end run()


sub _initialize_from_command_line {
    my ($argv) = @_;
    my %values;

    Getopt::Long::Configure( qw< bundling permute no_getopt_compat> );
    if ( Getopt::Long::GetOptionsFromArray($argv, \%values, @OPTIONS) ) {
        _set_options(\%values) or return;

        return %values;
    } # end if

    return;
} # end _initialize_from_command_line()


sub _handle_info_requests {
    my ($options) = @_;

    if ($options->{help}) {
        _emit_usage_message();

        return 1;
    } # end if

    if ($options->{version}) {
        _emit_version();

        return 1;
    } # end if

    return;
} # end _handle_info_requests()


sub _emit_usage_message {
    print {_get_stderr()} <<'END_USAGE';  ## no critic (RequireCheckedSyscalls)
ppigrep [--match regex] [--format format] PPI-class file [...]

ppigrep { -h | --help | -V | --version }

--format escapes:
    %f – The name of the file.
    %l – The starting line number of the element.
    %c – The starting character within the first line of the element.
    %C – The starting column within the first line of the element.
    %L – The class of the element, with the 'PPI::' prefix removed.
    %s – The source-code/content for the element.
    %S – The source-code/content for the element, C<chomp>ed.
    %W – The source-code/content for the element, whitespace shrunk.

(Note: file argument is required-- STDIN is not yet handled.)
END_USAGE

    return;
} # end _emit_usage_message()

sub _emit_version {
    print {_get_stderr()} <<"END_VERSION";  ## no critic (RequireCheckedSyscalls)
ppigrep $VERSION, Copyright ©2007-2008, Elliot Shank <perl\@galumph.com>.
END_VERSION

    return;
} # end _emit_usage_message()


sub _derive_ppi_classes {
    my ($pattern) = @_;

    my @ppi_classes;
    foreach my $subpattern ( split m/,/xms, $pattern ) {
        my $ppi_class = get_ppi_class($subpattern);
        if (not $ppi_class) {
            print
                {_get_stderr()}
                qq<Could not figure out what PPI::Element subclass to use for "$subpattern".\n>;
            return;
        } # end if

        push @ppi_classes, $ppi_class;
    } # end foreach

    if (not @ppi_classes) {
        print
            {_get_stderr()}
            qq<Could not find any PPI::Element subclasses to use for "$pattern".\n>;

        return;
    } # end if

    return @ppi_classes;
} # end _derive_ppi_classes()


sub _build_query {
    my ($ppi_classes) = @_;

    my $ppi_class;
    if ( 1 == @{$ppi_classes} ) {
        $ppi_class = $ppi_classes->[0]
    } # end if

    if ( my $match = _get_match() ) {
        if ($ppi_class) {
            return sub {
                my (undef, $element) = @_;

                return 0 if not $element->isa($ppi_class);
                return 1 if $element->content() =~ $match;
                return 0;
            };
        } # end if

        return sub {
            my (undef, $element) = @_;

            return 0 if none { $element->isa($_) } @{$ppi_classes};
            return 1 if $element->content() =~ $match;
            return 0;
        };
    } # end if

    return $ppi_class if ($ppi_class);

    return sub {
        my (undef, $element) = @_;

        return 1 if any { $element->isa($_) } @{$ppi_classes};
        return 0;
    };
} # end _build_query()


sub _search_and_emit {
    my ($source, $source_description, $query, $destination) = @_;

    my $document = _create_document($source, $source_description)
        or return;
    $document->index_locations();

    my $elements = $document->find($query);
    if ($elements) {
        foreach my $element ( @{$elements} ) {
            my $location = $element->location();
            my @location_components;
            if ($location) {
                @location_components = @{$location};
            } else {
                @location_components = (q<>) x $NUMBER_OF_PPI_LOCATION_COMPONENTS;
            } # end if

            print
                {$destination}
                _format_element($element, $source, \@location_components);
        } # end foreach

        return 1;
    } # end if

    return 0;
} # end _search_and_emit()

sub _create_document {
    my ($source, $source_description) = @_;

    if ( not -e $source ) {
        print {_get_stderr()} qq<"$source_description" does not exist.\n>;
        return;
    } # end if

    if ( not -r $source ) {
        print {_get_stderr()} qq<"$source_description" is not readable.\n>;
        return;
    } # end if

    if ( -d $source ) {
        print {_get_stderr()} qq<"$source_description" is a directory.\n>;
        return;
    } # end if

    if ( -z $source ) {
        # PPI barfs on empty documents for some reason.
        return PPI::Document->new();
    }

    my $document = PPI::Document->new($source, readonly => 1);
    if (not $document) {
        print {_get_stderr()} qq<Could not parse "$source_description".\n>;
        return;
    } # end if

    return $document;
} # _create_document()


sub _set_options {
    my ($options) = @_;

    my $match = $options->{match};
    if ($match) {
        my $compiled_match;

        eval { $compiled_match = qr/$match/; 1; } ## no critic (RegularExpressions)
            or do {
                if ($EVAL_ERROR) {
                    (my $error = $EVAL_ERROR) =~
                        s< \s+ at \s+ \S+ \s+ line \s+ \d+ .* ><>xms;
                    chomp $error;

                    print {_get_stderr()} qq<Invalid regex "$match": $error.>;

                    return;
                }

                print {_get_stderr()} qq<Invalid regex "$match".>;
                return;
            };

        set_match( $compiled_match );
    } # end if

    my $format = $options->{format};
    if ($format) {
        set_print_format( "$format\n" );
    } # end if

    return 1;
} # end _set_options()


sub _get_stdout {
    return $stdout;
} # end _get_stdout()

sub set_stdout {
    my ($destination) = @_;

    $stdout = $destination;

    return;
} # end set_stdout()


sub _get_stderr {
    return $stderr;
} # end _get_stderr()

sub set_stderr {
    my ($destination) = @_;

    $stderr = $destination;

    return;
} # end set_stderr()


sub _get_match {
    return $match;
} # end _get_match()

sub set_match {
    my ($new_pattern) = @_;

    $match = $new_pattern;

    return;
} # end set_match()


sub _get_print_format {
    return $print_format;
} # end _get_print_format()

sub set_print_format {
    my ($new_format) = @_;

    $print_format = $new_format;

    return;
} # end set_print_format()

Readonly my $PPI_PREFIX_LENGTH => length 'PPI::';

sub _format_element {
    my ($element, $filename, $location_components) = @_;

    my %format_specification = (
        f => $filename,
        l => $location_components->[$PPI_LINE_NUMBER],
        c => $location_components->[$PPI_CHARACTER_NUMBER],
        C => $location_components->[$PPI_COLUMN_NUMBER],
        L => sub { substr $element->class(), $PPI_COLUMN_NUMBER },
        s => sub { $element->content() },
        S => sub { _invoke_method($element, $_[0]) },
        t => sub { my $source = $element->content(); chomp $source; $source },
        T => sub { my $source = _invoke_method($element, $_[0]); chomp $source; $source },
        w => sub { _strip( $element ) },
        W => sub { _strip( _invoke_method($element, $_[0]) ) },
    );

    return stringf(_get_print_format(), %format_specification);
} # end _format_element()

# Invoke an arbitrary method safely on an element.
sub _invoke_method {
    my ($element, $method_name) = @_;

    my $value;
    local $EVAL_ERROR = undef;
    eval { $value = $element->$method_name(); 1; } or return '<error>';

    if (not defined $value) {
        return '<undef>';
    } # end if

    return $value;
} # end _invoke_method()

sub _strip {
    my ($element) = @_;

    my $source = "$element"; # no content(): may be a plain string.
    $source =~ s< \A \s+ ><>xms;
    $source =~ s< \s+ \z ><>xms;
    $source =~ s< \s+ >< >xmsg;

    return $source;
} # end _strip()


sub _is_ignored_directory {
    my ($directory) = @_;

    return 1 if $ignored_directories{$directory};
    return 0;
}

sub _is_ignored_file {
    my ($file) = @_;

    return 1 if $file =~ qr< (?: [.] bak | ~ ) \z >xms;
    return 1 if $file =~ qr< [#] .+ [#] \z       >xms;
    return 1 if $file =~ qr< [._] .* \.swp \z    >xms;
    return $file =~ qr< core [.] \d+ \z      >xms;
}

sub _is_perl_file {
    my ($file, $error) = @_;

    return 1 if $file =~ m/ [.] (?: p (?: l x? | m ) | t | PL ) \z /xms; ## no critic (ProhibitSingleCharAlternation)
    return 0 if index($file, q<.>) >= 0;
    return _is_perl_program($file, $error);
}

sub _is_perl_program {
    my ($file, $error) = @_;

    if (open my $handle, '<', $file) {
        my $first_line = <$handle>;

        if (not close $handle) {
            print {*STDERR} qq<Could not close "$file": $OS_ERROR\n>;
            ${$error} = 1;
            return 0;
        }

        return $first_line =~ m< \A [#]! .* \bperl >xms;
    }

    print {*STDERR} qq<Could not open "$file": $OS_ERROR\n>;
    ${$error} = 1;
    return 0;
}


1; # Magic true value required at end of module.

__END__

=encoding utf8

=for stopwords TODO

=head1 NAME

PPIx::Grep - Search L<PPI> documents (not Perl code).


=head1 VERSION

This document describes PPIx::Grep version 0.0.6.


=head1 SYNOPSIS

    use PPIx::Grep qw< run set_print_format >;

    set_print_format('%f> %s\n');  # Yes, single quotes.
    my $return_code = run( qw< include lib/PPIx/Grep.pm > );


=head1 DESCRIPTION

This is the guts of L<ppigrep>.  You're most likely more interested in
that.


=head1 INTERFACE

Nothing is exported by default, but you can import everything using
the C<:all> tag.


=over

=item C< run(@ARGV) >

Parse command-line options, find PPI elements, and emit the results.

Returns the expected exit value for the program.  This value is
equivalent to the one for C<grep>.  If a match was found, this is 0.
If no match was found, this is 1.  And if any problems occurred, this
is 2.


=item C< set_stdout($destination) >

Specifies where the regular output will go.


=item C< set_stderr($destination) >

Specifies where the error output will go.


=item C< set_match($regex) >

Sets the pattern that elements will be matched against.  This needs to
be a compiled regex and not merely a string.


=item C< set_print_format($format) >

Sets the format to be used to emit an individual L<PPI::Element>.
Note that newlines are not automatically printed for each Element; if
you want them, you need to specify them as part of the parameter.


=back


=head1 DIAGNOSTICS

=over

=item Could not figure out what PPI class to use for "%s".

The pattern argument could not be resolved to a subclass of
C<PPI::Element> via L<PPIx::Shorthand>.


=item Could not find any PPI::Element subclasses to use for "%s".

The pattern argument didn't resolve to any L<PPI::Element> subclasses.
Did you specify the empty string?


=item Invalid regex "%s": %s.

The regex specified via C<--match> could not be compiled.


=item "%s" does not exist.

Cannot find the file.


=item "%s" is not readable.

Cannot read the file.


=item "%s" is a directory.

The "file" was actually a directory.


=item Could not parse "%s".

L<PPI> could not interpret the file as a Perl document.


=back


=head1 CONFIGURATION AND ENVIRONMENT

None, currently.


=head1 DEPENDENCIES

L<Getopt::Long>
L<List::MoreUtils>
L<PPI::Document>
L<PPIx::Shorthand>
L<String::Format>


=head1 INCOMPATIBILITIES

None reported.


=head1 BUGS AND LIMITATIONS

=over

=item · This thing is way too limited in functionality.


=back

Please report any bugs or feature requests to
C<bug-ppix-grep@rt.cpan.org>, or through the web
interface at L<http://rt.cpan.org>.


=head1 SEE ALSO

L<App::Ack>
L<App::Grepl>


=head1 AUTHOR

Elliot Shank C<< <perl@galumph.com> >>


=head1 LICENSE AND COPYRIGHT

Copyright ©2007-2008, Elliot Shank C<< <perl@galumph.com> >>. All
rights reserved.

This module is free software; you can redistribute it and/or modify it
under the same terms as Perl itself. See L<perlartistic>.


=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT
WHEN OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER
PARTIES PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND,
EITHER EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
PURPOSE. THE ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE
SOFTWARE IS WITH YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME
THE COST OF ALL NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENSE, BE LIABLE
TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE THE
SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH
DAMAGES.

=cut

# setup vim: set filetype=perl tabstop=4 softtabstop=4 expandtab :
# setup vim: set shiftwidth=4 shiftround textwidth=78 nowrap autoindent :
# setup vim: set foldmethod=indent foldlevel=0 :
