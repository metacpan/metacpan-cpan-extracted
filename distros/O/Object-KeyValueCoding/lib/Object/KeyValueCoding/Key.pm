package Object::KeyValueCoding::Key;

our $VERSION = "0.94";

use strict;

my $_KEY_CACHE = undef;

sub enableCache {
    $_KEY_CACHE = {};
}

sub flushCache {
    if ( $_KEY_CACHE ) {
        $_KEY_CACHE = {};
    }
}

sub disableCache {
    undef $_KEY_CACHE;
}

sub new {
    my ( $class, $key ) = @_;
    $key ||= "";
    if ( $_KEY_CACHE && $key && exists $_KEY_CACHE->{$key} ) {
        return $_KEY_CACHE->{$key};
    }

    my $parts = __normalise( $key );

    my ( $leadingUnderscores ) = $key =~ /^(_+)/;
    my ( $trailingUnderscores ) = $key =~ /(_+)$/;
    my $self = bless {
        parts => $parts,
        leadingUnderscores => $leadingUnderscores || "",
        trailingUnderscores => $trailingUnderscores || "",
    }, $class;
    if ( $_KEY_CACHE ) {
        $_KEY_CACHE->{$key} = $self;
    }
    return $self;
}

sub __normalise {
    my ( $key ) = @_;

    # $key can be
    # 1. constant format LIKE_THIS
    # 2. camel case format likeThis
    # 3. capital camel case format LikeThis
    # 4. underscorey like_this

    my $bits = [];
    $key =~ s/^_+//g;

    if ( $key =~ /[A-Za-z0-9]_[A-Za-z0-9]/ ) {
        $bits = [ split(/_+/, $key) ];
        $bits = [ map { lc } @$bits ];
    } else {
        my $new = $key;
        $new =~ s/((^[a-z]+)|([0-9]+)|([A-Z]{1}[a-z]+)|([A-Z]+(?=([A-Z][a-z])|($)|([0-9]))))/$1 /g;
        $bits = [ map { $_ =~ /^[A-Z]+$/ ? $_ : lc($_) } split(/\s+/, $new) ];
    }
    return $bits;
}

sub __camelCase {
    my ( $parts ) = @_;
    $parts ||= [];
    if ( $parts->[0] =~ /^[A-Z0-9]+$/ ) {
        return __titleCase( $parts );
    }
    return lcfirst(__titleCase( $parts ));
}

sub __constant {
    my ( $parts ) = @_;
    return join("_", map { uc } @$parts );
}

sub __titleCase {
    my ( $parts ) = @_;
    return join("", map { ucfirst } @$parts);
}

sub __underscorey {
    my ( $parts ) = @_;
    return join("_", @$parts );
}

sub asCamelCase   {   __camelCase( $_[0]->{parts} ) }
sub asConstant    {    __constant( $_[0]->{parts} ) }
sub asTitleCase   {   __titleCase( $_[0]->{parts} ) }
sub asUnderscorey { __underscorey( $_[0]->{parts} ) }

sub asCamelCaseProperty   { sprintf( "%s%s%s", $_[0]->{leadingUnderscores}, $_[0]->asCamelCase(),   $_[0]->{trailingUnderscores} ) };
sub asTitleCaseProperty   { sprintf( "%s%s%s", $_[0]->{leadingUnderscores}, $_[0]->asTitleCase(),   $_[0]->{trailingUnderscores} ) };
sub asConstantProperty    { sprintf( "%s%s%s", $_[0]->{leadingUnderscores}, $_[0]->asConstant(),    $_[0]->{trailingUnderscores} ) };
sub asUnderscoreyProperty { sprintf( "%s%s%s", $_[0]->{leadingUnderscores}, $_[0]->asUnderscorey(), $_[0]->{trailingUnderscores} ) };

sub asCamelCaseSetter   { sprintf( "%sset%s%s",  $_[0]->{leadingUnderscores}, $_[0]->asTitleCase(),   $_[0]->{trailingUnderscores} ) };
sub asTitleCaseSetter   { sprintf( "%sset%s%s",  $_[0]->{leadingUnderscores}, $_[0]->asTitleCase(),   $_[0]->{trailingUnderscores} ) };
sub asConstantSetter    { sprintf( "%sset_%s%s", $_[0]->{leadingUnderscores}, $_[0]->asConstant(),    $_[0]->{trailingUnderscores} ) };
sub asUnderscoreySetter { sprintf( "%sset_%s%s", $_[0]->{leadingUnderscores}, $_[0]->asUnderscorey(), $_[0]->{trailingUnderscores} ) };

sub asCamelCaseGetter   { sprintf( "%sget%s%s",  $_[0]->{leadingUnderscores}, $_[0]->asTitleCase(),   $_[0]->{trailingUnderscores} ) };
sub asTitleCaseGetter   { sprintf( "%sget%s%s",  $_[0]->{leadingUnderscores}, $_[0]->asTitleCase(),   $_[0]->{trailingUnderscores} ) };
sub asConstantGetter    { sprintf( "%sget_%s%s", $_[0]->{leadingUnderscores}, $_[0]->asConstant(),    $_[0]->{trailingUnderscores} ) };
sub asUnderscoreyGetter { sprintf( "%sget_%s%s", $_[0]->{leadingUnderscores}, $_[0]->asUnderscorey(), $_[0]->{trailingUnderscores} ) };

1;