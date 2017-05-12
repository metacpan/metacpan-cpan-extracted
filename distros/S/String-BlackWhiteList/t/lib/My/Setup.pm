package My::Setup;
our $VERSION = '1.100860';
use warnings;
use strict;
use Test::More;
use String::BlackWhiteList;
use Exporter qw(import);
our %EXPORT_TAGS = (
    list => [qw(BLACKLIST WHITELIST)],
    test => [qw(is_valid is_invalid is_valid_relaxed is_invalid_relaxed)],
    make => [qw(get_matcher)],
);
our @EXPORT_OK = @{ $EXPORT_TAGS{all} = [ map { @$_ } values %EXPORT_TAGS ] };
use constant BLACKLIST => (
    'BOX',           'POB',      'POSTBOX',   'POST',
    'POSTSCHACHTEL', 'PO',       'P O',       'P O BOX',
    'P.O.',          'P.O.B.',   'P.O.BOX',   'P.O. BOX',
    'P. O.',         'P. O.BOX', 'P. O. BOX', 'POBOX',
    'PF',            'P.F.',     'POSTFACH',  'POSTLAGERND',
    'POSTBUS'
);
use constant WHITELIST => (
    'Post Road',
    'Post Rd',
    'Post Street',
    'Post St',
    'Post Avenue',
    'Post Av',
    'Post Alley',
    'Post Drive',
    'Post Grove',
    'Post Walk',
    'Post Parkway',
    'Post Row',
    'Post Lane',
    'Post Bridge',
    'Post Boulevard',
    'Post Square',
    'Post Garden',
    'Post Strasse',
    'Post Allee',
    'Post Gasse',
    'Post Platz',
    'Poststrasse',
    'Postallee',
    'Postgasse',
    'Postplatz',
);

sub is_valid {
    my ($matcher, @input) = @_;
    ok($matcher->valid($_), sprintf "[%s] valid", defined($_) ? $_ : 'undef')
      for @input;
}

sub is_invalid {
    my ($matcher, @input) = @_;
    ok(!$matcher->valid($_), sprintf "[%s] invalid", defined($_) ? $_ : 'undef')
      for @input;
}

sub is_valid_relaxed {
    my ($matcher, @input) = @_;
    ok( $matcher->valid_relaxed($_),
        sprintf "[%s] valid relaxed",
        defined($_) ? $_ : 'undef'
    ) for @input;
}

sub is_invalid_relaxed {
    my ($matcher, @input) = @_;
    ok( !$matcher->valid_relaxed($_),
        sprintf "[%s] invalid relaxed",
        defined($_) ? $_ : 'undef'
    ) for @input;
}

sub get_matcher {
    String::BlackWhiteList->new(
        blacklist => [BLACKLIST],
        whitelist => [WHITELIST]
    )->update;
}
1;
