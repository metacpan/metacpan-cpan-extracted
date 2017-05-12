use strict;
use warnings;

package Template::AutoFilter::Parser;

our $VERSION = '0.143050'; # VERSION
# ABSTRACT: parses TT templates and automatically adds filters to tokens


use base 'Template::Parser';
use List::MoreUtils qw< part >;

sub new {
    my ( $class, $params ) = @_;

    my $self = $class->SUPER::new( $params );
    $self->{AUTO_FILTER} = $params->{AUTO_FILTER} || 'html';
    $self->{SKIP_DIRECTIVES} = $self->make_skip_directives( $params->{SKIP_DIRECTIVES} ) || $self->default_skip_directives;

    return $self;
}

sub split_text {
    my ( $self, @args ) = @_;
    my $tokens = $self->SUPER::split_text( @args ) or return;

    for my $token ( @{$tokens} ) {
        next if !ref $token;
        next if !ref $token->[2];   # Skip ITEXT (<foo>$bar</foo>)

        # Split a compound statement into individual directives
        my ($part, $is_directive) = (0, 1);
        my @directives = part {
            # Skip over interpolated fields; they are unpaired
            unless (ref) {
                $part++ if $is_directive and $_ eq ';';
                $is_directive = !$is_directive;
            }
            $part;
        } @{$token->[2]};

        for my $directive (@directives) {
            # Filter out interpolated values in strings; they don't matter for
            # our decision of whether to autofilter or not (e.g. an existing
            # filter).  Note, this is not the same as ITEXT.  Also ignore
            # semi-colon tokens, as they may make an empty directive look
            # non-empty.  They are also inconsequential to our decision to
            # autofilter or not.
            my %fields = grep { !ref and $_ ne ';' } @$directive;
            next if $self->has_skip_field( \%fields );
            next if ! %fields;

            push @$directive, qw( FILTER | IDENT ), $self->{AUTO_FILTER};
        }

        $token->[2] = [ map { @$_ } @directives ];
    }
    return $tokens;
}

sub has_skip_field {
    my ( $self, $fields ) = @_;

    my $skip_directives = $self->{SKIP_DIRECTIVES};

    for my $field ( keys %{$fields} ) {
        return 1 if $skip_directives->{$field};
    }

    return 0;
}

sub default_skip_directives {
    my ( $self ) = @_;
    my @skip_directives = qw(
        CALL SET DEFAULT INCLUDE PROCESS WRAPPER BLOCK IF UNLESS ELSIF ELSE
        END SWITCH CASE FOREACH FOR WHILE FILTER USE MACRO TRY CATCH FINAL
        THROW NEXT LAST RETURN STOP CLEAR META TAGS DEBUG ASSIGN PERL RAWPERL
    );
    return $self->make_skip_directives( \@skip_directives );
}

sub make_skip_directives {
    my ( $self, $skip_directives_list ) = @_;
    return if !$skip_directives_list;

    my %skip_directives = map { $_ => 1 } @{$skip_directives_list};
    return \%skip_directives;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Template::AutoFilter::Parser - parses TT templates and automatically adds filters to tokens

=head1 VERSION

version 0.143050

=head1 DESCRIPTION

Sub-class of Template::Parser.

=head1 METHODS

See L<Template::Parser> for most of these, documented here are added
methods.

=head2 new

Accepts all the standard L<Template::Parser> parameters, plus some extra:

=head3 AUTO_FILTER

Accepts a single string, which defines the name of a filter to be applied
to all directives omitted from the skip list. This parameter defaults to
'html'.

=head3 SKIP_DIRECTIVES

Allows customization of which L<Template::Manual::Directives> should be
exempt from having auto filters applied. Expects an array ref of strings.
Default value is the output from $self->default_skip_directives.

=head2 split_text

Modifies token processing by adding the filter specified in AUTO_FILTER
to all filter-less interpolation tokens.

=head2 has_skip_field

Checks the field list of a token to see if it contains directives that
should be excluded from filtering.

=head2 default_skip_directives

Provides a reference to a hash containing the default directives to be
excluded. Default value is:

    CALL SET DEFAULT INCLUDE PROCESS WRAPPER BLOCK IF UNLESS ELSIF ELSE
    END SWITCH CASE FOREACH FOR WHILE FILTER USE MACRO TRY CATCH FINAL
    THROW NEXT LAST RETURN STOP CLEAR META TAGS DEBUG

=head2 make_skip_directives

Prebuilds a hash of directives to be skipped while applying auto filters.

=head1 AUTHOR

Christian Walde <walde.christian@gmail.com>

=head1 COPYRIGHT AND LICENSE


Christian Walde has dedicated the work to the Commons by waiving all of his
or her rights to the work worldwide under copyright law and all related or
neighboring legal rights he or she had in the work, to the extent allowable by
law.

Works under CC0 do not require attribution. When citing the work, you should
not imply endorsement by the author.

=cut
