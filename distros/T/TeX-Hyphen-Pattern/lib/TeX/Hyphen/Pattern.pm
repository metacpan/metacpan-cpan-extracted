# -*- cperl; cperl-indent-level: 4 -*-
# Copyright (C) 2009-2021, Roland van Ipenburg
package TeX::Hyphen::Pattern v1.1.7;
use Moose;
use 5.014000;
use utf8;

use English '-no_match_vars';
use Log::Log4perl qw(:easy get_logger);
use Set::Scalar ();
use Encode      ();
use Module::Pluggable
  'sub_name'    => '_available',
  'search_path' => ['TeX::Hyphen::Pattern'],
  'require'     => 1;

use File::Temp ();

use Readonly ();
## no critic (ProhibitCallsToUnexportedSubs)
Readonly::Scalar my $EMPTY              => q{};
Readonly::Scalar my $DASH               => q{-};
Readonly::Scalar my $UNDERSCORE         => q{_};
Readonly::Scalar my $TEX_COMMENT_LINE   => q{%};
Readonly::Scalar my $CARON_ESCAPE       => q{"};
Readonly::Scalar my $CLASS_BEGIN        => q{[};
Readonly::Scalar my $CLASS_END          => q{]};
Readonly::Scalar my $DEFAULT_LABEL      => q{en-US};
Readonly::Scalar my $UTF8               => q{:utf8};
Readonly::Scalar my $PLUGGABLE          => q{TeX::Hyphen::Pattern::};
Readonly::Scalar my $TEX_PATTERN_START  => qq@\\patterns{\n#@;
Readonly::Scalar my $TEX_PATTERN_FINISH => qq@\n}@;
Readonly::Scalar my $TEX_INPUT_COMMAND  => q{\\\input\s+hyph-(.*?)\.tex};
Readonly::Scalar my $TEX_MESSAGE        => q{\\\message};

Readonly::Scalar my $ERR_CANT_WRITE => q{Can't write to file '%s', stopped %s};

Readonly::Hash my %FALLBACK => (
    'De_DE' => q{De_1996_ec},
    'Af_za' => q{Af_ec},
    'Da_DK' => q{Da_ec},
    'Et_ee' => q{Et_ec},
    'Fr_fr' => q{Fr_ec},
    'It_it' => q{It},
    'Lt_lt' => q{Lt},
    'Nl_nl' => q{Nl},
    'Pl_pl' => q{Pl},
    'Pt_br' => q{Pt},
    'Sh'    => q{Sh_latn},
    'Sl'    => q{Sl},
);

Readonly::Hash my %LOG => (
    'MATCH_MODULE'      => q{Looking for a match for '%s'},
    'NO_MATCH_CS'       => q{No case sensitive pattern match found for '%s'},
    'NO_MATCH_CI'       => q{No case insensitive pattern match found for '%s'},
    'NO_MATCH_PARTIAL'  => q{No partial pattern match found for '%s'},
    'NO_MATCH'          => q{No pattern match found for '%s'},
    'MATCHES'           => q{Pattern match(es) found '%s'},
    'CACHE_HIT'         => q{Cache hit for '%s'},
    'CACHE_MISS'        => q{Cache miss for '%s'},
    'FILE_UNDEF'        => q{Returning undef file for '%s'},
    'PATCH_OPENOFFICE'  => q{Patching OpenOffice.org pattern},
    'PATCH_TEX_INPUT'   => q{Patching TeX pattern with \input},
    'PATCH_CARONS'      => q{Patching "x encoded carons},
    'PATCH_TEX_MESSAGE' => q{Patching TeX pattern with \message},
    'DELETING'          => q{Deleting %d temporary file(s) %s},
    'DELETE_FAIL'       => q{Could not delete all temporary files},
    'DELETE_SUCCES'     => q{Deleted all temporary files},
);
Readonly::Hash my %CARON_MAP => ( q{c} => q{č}, q{s} => q{š}, q{z} => q{ž} );
## use critic

Log::Log4perl->easy_init($ERROR);
my $log = get_logger();

## no critic (ProhibitCallsToUndeclaredSubs)
has 'label'  => ( 'is' => 'rw', 'isa' => 'Str', 'default' => $DEFAULT_LABEL );
has '_cache' => ( 'is' => 'rw', 'isa' => 'HashRef',  'default' => sub { {} } );
has '_plugs' => ( 'is' => 'rw', 'isa' => 'ArrayRef', 'default' => sub { [] } );
## use critic

sub filename {
    my ($self) = @_;
    if ( exists $self->_cache->{ $self->label } ) {
        $log->debug( sprintf $LOG{'CACHE_HIT'}, $self->label );
        return $self->_cache->{ $self->label };
    }
    $log->debug( sprintf $LOG{'CACHE_MISS'}, $self->label );

    # Return undef if the label could not be matched to a pattern:
    if ( !$self->_replug() ) {
        $log->warn( sprintf $LOG{'FILE_UNDEF'}, $self->label );
        return;
    }
    my $patterns = $self->_plugs->[0]->pattern_data();

    # Strip comments to prevent parsing of commands in comments
    ## no critic qw(RequireDotMatchAnything)
    $patterns =~ s{^$TEX_COMMENT_LINE.*?$}{}gixm;
    ## use critic

    # Take care of \input command in TeX:
    while ( my ($module) = $patterns =~ /$TEX_INPUT_COMMAND/xmis ) {
        $log->debug( $LOG{'PATCH_TEX_INPUT'} );
        $module = $PLUGGABLE . ucfirst $module;
        my $input_patterns = $module->new()->pattern_data();
        $patterns =~ s/$TEX_INPUT_COMMAND/$input_patterns/xmgis;
    }

    # Take care of "x encoded carons:
    my $caron = $CARON_ESCAPE . $CLASS_BEGIN . join $EMPTY,
      keys(%CARON_MAP) . $CLASS_END;
    $log->debug( $LOG{'PATCH_CARONS'} );
    $patterns =~ s{($caron)}{$CARON_MAP{$1}}xmgis;

    # Take care of \message command in TeX that TeX::Hyphen can't handle:
    # uncoverable branch true
    if ( $patterns =~ /^$TEX_MESSAGE/xmgis ) {
        $log->debug( $LOG{'PATCH_TEX_MESSAGE'} );    # uncoverable statement
                                                     # uncoverable statement
        $patterns =~ s{^($TEX_MESSAGE)}{$TEX_COMMENT_LINE$1}xmgis;
    }

    # Patch OpenOffice.org pattern data for TeX::Hyphen:
    if ( $patterns !~ /\\patterns/xmgis ) {
        $log->debug( $LOG{'PATCH_OPENOFFICE'} );
        $patterns = $TEX_PATTERN_START . $patterns . $TEX_PATTERN_FINISH;
    }

    my $fh = File::Temp->new();
    binmode $fh, $UTF8;
    $fh->unlink_on_destroy(0);

    # uncoverable branch true
    if ( !print {$fh} $patterns ) {

        # uncoverable statement
        $log->logdie( sprintf $ERR_CANT_WRITE, ( $fh->filename, $ERRNO ) );
    }
    my %cache = %{ $self->_cache };
    $cache{ $self->label } = $fh->filename;
    $self->_cache( {%cache} );
    return $fh->filename;
}

sub available {
    my ($self) = @_;
    return map { ref }
      grep     { $_->version == $TeX::Hyphen::Pattern::VERSION }
      map      { $_->new() } $self->_available;
}

sub packaged {
    my ($self) = @_;
    return $self->_available;
}

sub _replug {
    my ($self) = @_;
    my $module = ucfirst $self->label;
    $module =~ s/$DASH/$UNDERSCORE/xmgis;
    my $label = $module;
    $module = $PLUGGABLE . $module;

    # Find a match with decreasing strictness:
    $log->debug( sprintf $LOG{'MATCH_MODULE'}, $module );
    my @available = grep { /^$module$/xmgs } $self->available();
    if ( !@available ) {
        $log->info( sprintf $LOG{'NO_MATCH_CS'}, $module );
        @available = grep { /^$module$/xmgis } $self->available();
    }
    if ( !@available ) {
        $log->warn( sprintf $LOG{'NO_MATCH_CI'}, $module );
        @available = grep { /^$module/xmgis } $self->available();
    }
    if ( !@available ) {
        $log->warn( sprintf $LOG{'NO_MATCH_PARTIAL'}, $module );
        if ( exists $FALLBACK{$label} ) {
            $module    = $PLUGGABLE . $FALLBACK{$label};
            @available = grep { /^$module/xmgis } $self->available();
        }
    }
    @available = sort @available;
    $log->info( sprintf $LOG{'MATCHES'}, join q{, }, @available );
    @available || $log->warn( sprintf $LOG{'NO_MATCH'}, $module );
    $self->_plugs( [ map { $_->new() } @available ] );
    return 0 + @available;
}

sub DESTROY {
    my ($self) = @_;
    my @temp_files = values %{ $self->_cache };
    $log->debug( sprintf $LOG{'DELETING'},
        ( 0 + @temp_files, join ', ', @temp_files ) );
    my $deleted = unlink @temp_files;
    ( $deleted != ( 0 + @temp_files ) )
      ? $log->warn( $LOG{'DELETE_FAIL'} )
      : $log->debug( $LOG{'DELETE_SUCCES'} );
    return;
}

1;
__END__

=encoding utf8

=for stopwords Bitbucket CPAN OpenOffice Readonly Subtags Apali tex Ipenburg

=head1 NAME

TeX::Hyphen::Pattern - class for providing a collection of TeX hyphenation
patterns for use with TeX::Hyphen.

=head1 VERSION

This is version C<v1.1.7>. To prevent plugging in of incompatible modules the
version of the pluggable modules must be the same as this module.

=head1 SYNOPSIS

    use TeX::Hyphen;
    use TeX::Hyphen::Pattern;

    $pat = TeX::Hyphen::Pattern->new();
    $pat->label('Sh_ltn'); # Serbocroatian hyphenation patterns
    $hyph = TeX::Hyphen->new($pat->filename);

=head1 DESCRIPTION

The L<TeX::Hyphen|TeX::Hyphen> module parses TeX files containing hyphenation
patterns for use with TeX based systems. This module includes TeX hyphenation
files from L<CPAN|http://www.ctan.org> and hyphenation patterns from
L<OpenOffice|http://www.openoffice.org> and provides a single interface to
use them in L<TeX::Hyphen|TeX::Hyphen>.

=over 4

=item L<http://tug.org/svn/texhyphen/trunk/hyph-utf8/tex/generic/hyph-utf8/patterns/>

=item L<http://svn.services.openoffice.org/ooo/trunk/dictionaries/>

=back

=head1 SUBROUTINES/METHODS

=over 4

=item TeX::Hyphen::Pattern-E<gt>new();

=item TeX::Hyphen::Pattern-E<gt>new(label => $label);

Constructs a new TeX::Hyphen::Pattern object.

=item $pattern-E<gt>label($label);

Sets the label that determines the pattern to use. The label can be a simple
language code, but since some languages can use multiple scripts with
different hyphenation rules we talk about patterns and not just languages.

=item $pattern-E<gt>available();

Returns a list of the available patterns.

=item $pattern-E<gt>packaged();

Returns a list of the available patterns. (alias for available)

=item $pattern-E<gt>filename();

Returns the name of a temporary file that TeX::Hyphen can read it's pattern
from for the current label. Returns C<undef> if no pattern language matching the
label was found.

=back

=head1 CONFIGURATION AND ENVIRONMENT

The script F<tools/build_catalog_from_ctan.pl> was used to get the TeX
patterns file from the source on the internet and include them in this module.
After that the copyright messages were manually checked and inserted to make
sure this distribution complies with them.

=head1 DEPENDENCIES

=over 4

=item L<Moose|Moose>
=item L<Encode|Encode>
=item L<File::Temp|File::Temp>
=item L<Log::Log4perl|Log::Log4perl>
=item L<Module::Pluggable|Module::Pluggable>
=item L<Readonly|Readonly>
=item L<Set::Scalar|Set::Scalar>

=back

L<TeX::Hyphen|TeX::Hyphen> is only a test requirement of
C<TeX::Hyphen::Pattern>. You might want to use the patterns in another way and
this module then just provides them independent of L<TeX::Hyphen|TeX::Hyphen>.

=head1 INCOMPATIBILITIES

=over 4

Not all available pattern files are parsed correctly by
L<TeX::Hyphen|TeX::Hyphen>.

=back

=head1 DIAGNOSTICS

This module uses L<Log::Log4perl|Log::Log4perl> for logging. It's a fatal
error when the temporary file containing the pattern can't be written.

=over 4

=item C<Can't write to file '%s', stopped %s>

The temporary file created by L<File::Temp|File::Temp> could not be written.

=back

=head1 BUGS AND LIMITATIONS

=over 4

=item * Subtags aren't handled: C<en> could pick C<en_US>, C<en_UK> or C<ena>
(when Apali would be available) and this is silently ignored, it just does a
match on the string and picks what partly matches sorted, so using more exotic
scripts this can go wrong badly.

=back

Please report any bugs or feature requests at
L<Bitbucket|
https://bitbucket.org/rolandvanipenburg/tex-hyphen-pattern/issues>.

=head1 AUTHOR

Roland van Ipenburg, E<lt>roland@rolandvanipenburg.comE<gt>

=head1 LICENSE AND COPYRIGHT

Copyright 2009-2021 by Roland van Ipenburg

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl 5 you may have available.

The included pattern files in lib/TeX/Hyphen/Pattern/ are licensed as stated
in those files.

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
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENSE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.

=cut
