package OData::QueryParams::DBIC::FilterUtils;

# ABSTRACT: parse filter param

use v5.20;

use strict;
use warnings;

use feature 'signatures';
no warnings 'experimental::signatures';

use parent 'Exporter';

our @EXPORT_OK = qw(parser);
our $VERSION   = '0.06';

use constant Operators => {
    EQUALS             => 'eq',
    AND                => 'and',
    OR                 => 'or',
    GREATER_THAN       => 'gt',
    GREATER_THAN_EQUAL => 'ge',
    LESS_THAN          => 'lt',
    LESS_THAN_EQUAL    => 'le',
    LIKE               => 'like',
    IS_NULL            => 'is null',
    NOT_EQUAL          => 'ne',
};

sub predicate ($config) {

    $config ||= {};

    my $this = {
        subject  => $config->{subject},
        value    => $config->{value},
        operator => ($config->{operator}) ? $config->{operator} : Operators->{EQUALS},
    };

    return $this;
}

sub parser {
    state $order = [qw/parenthesis andor math op startsWith endsWith contains substringof/];
    state $REGEX = {
        parenthesis => qr/^([(](.*)[)])$/x,
        andor       => qr/^(.*?) \s+ (or|and) \s+ (.*)$/x,
        math        => qr/\(? ([A-Za-z0-9\/\._]*) \s+ (mod|div|add|sub|mul) \s+ ([0-9]+(?:\.[0-9]+)? ) \)? \s+ (.*) /x,
        op          => qr/
            ((?:(?:\b[A-Za-z]+\(.*?\))
                | [A-Za-z0-9\/\._]
                | '.*?')*)
            \s+
            (eq|gt|lt|ge|le|ne)
            \s+
            (true|false|datetimeoffset'(.*)'|'(.*)'|(?:[0-9]+(?:\.[0-9]+)?)*)
        /x,
        startsWith  => qr/^startswith[(](.*), \s* '(.*)'[)]/x,
        endsWith    => qr/^endswith[(](.*), \s* '(.*)'[)]/x,
        contains    => qr/^contains[(](.*), \s* '(.*)'[)]/x,
        substringof => qr/^substringof[(]'(.*?)', \s* (.*)[)]/x,
    };

    sub parse_fragment ($filter) {
        my $found;
        my $obj;

        KEY:
        for my $key ( @{$order} ) {
            last KEY if $found;

            my $regex = $REGEX->{$key};

            my @match = $filter =~ $regex;

            if ( @match ) {
                if ( $key eq 'parenthesis' ) {
                    if( index( $match[1], ')' ) < index( $match[1], '(' ) ) {
                        next KEY;
                    }

                    $obj = parse_fragment($match[1]);
                }
                elsif ( $key eq 'math' ) {
                    $obj = parse_fragment( $match[2] . ' ' . $match[3] );
                    $obj->{subject} = predicate({
                        subject  => $match[0],
                        operator => $match[1],
                        value    => $match[2],
                    });
                }
                elsif ( $key eq 'andor' ) {
                    $obj = predicate({
                        subject  => parse_fragment( $match[0] ),
                        operator => $match[1],
                        value    => parse_fragment( $match[2] ),
                    });
                }
                elsif ( $key eq 'op' ) {
                    $obj = predicate({
                        subject  => $match[0],
                        operator => $match[1],
                        value    => $match[2],
                    });

                    if ( $match[0] =~ m{\(.*?\)} ) {
                        $obj->{subject} = parse_fragment( $match[0] );
                    }

                    #if(typeof obj.value === 'string') {
                    #    var quoted = obj.value.match(/^'(.*)'$/);
                    #    var m = obj.value.match(/^datetimeoffset'(.*)'$/);
                    #    if(quoted && quoted.length > 1) {
                    #        obj.value = quoted[1];
                    #    } else if(m && m.length > 1) {
                    #        obj.value = new Date(m[1]);
                    #    }
                    #}
                }
                # ( $key eq 'startsWith' || $key eq 'endsWith' || $key eq 'contains' || $key eq 'substringof' ) {
                else {
                    $obj = predicate({
                        subject  => $match[0],
                        operator => $key,
                        value    => $match[1],
                    });
                }

                $found++;
            }
        }

        return $obj;
    }

    return 
        sub ($filter_string) {

            return if !defined $filter_string;

            $filter_string =~ s{\A\s+}{};
            $filter_string =~ s{\s+\z}{};

            return if $filter_string eq '';
            return parse_fragment($filter_string);
        };
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

OData::QueryParams::DBIC::FilterUtils - parse filter param

=head1 VERSION

version 0.06

=head1 SYNOPSIS

    use OData::QueryParams::DBIC::FilterUtils qw(parser);
    
    my $filter = 'Price lt 10';
    my $vars   = parser->( $filter );

=head1 METHODS

=head2 predicate

=head2 parser

=head2 parse_fragment

=head1 AUTHOR

Renee Baecker <reneeb@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Renee Baecker.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
