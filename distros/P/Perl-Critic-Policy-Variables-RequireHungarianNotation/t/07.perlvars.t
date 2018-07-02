#!/usr/bin/env perl

use strict;
use warnings;
use Test::More tests => 7;
use Perl::Critic;
use Perl::Critic::Config;
use Perl::Critic::TestUtils 'pcritique';

Perl::Critic::TestUtils::block_perlcriticrc();

# testing vars samples from perl doc.
my @a_tests = (
    {
        code => q~
package YourModule;
require Exporter;
@ISA = qw(Exporter);
@EXPORT_OK = qw(munge frobnicate);  # symbols to export on request
        ~,
        violations => 0,
        comment    => 'check ISA and EXPORT_OK',
    },
    {
        code => q~
@EXPORT_OK = qw(&bfunc %hash *typeglob); # explicit prefix on &bfunc
    ~,
        violations => 0,
        comment    => 'check EXPORT_OK',
    },
    {
        code => q/
%EXPORT_TAGS = (foo => [qw(aa bb cc)], bar => [qw(aa cc dd)]);
# add all the other ":class" tags to the ":all" class,
# deleting duplicates
{
my %h_seen;
push @{$EXPORT_TAGS{all}},
  grep {!$seen{$_}++} @{$EXPORT_TAGS{$_}} foreach keys %EXPORT_TAGS;
}
/,
        violations => 0,
        comment    => 'check EXPORT_TAGS',
    },
    { code => q/use vars qw($frob @mung %seen); /,       violations => 1, comment => 'use vars failing' },
    { code => q/use vars qw($s_frob @a_mung %h_seen); /, violations => 0, comment => 'use vars ok' },
    { code => q/use vars qw($s_frob @a_mung %a_seen); /, violations => 1, comment => 'use vars failing' },
    { code => q/use vars qw($s_frob @h_mung %h_seen); /, violations => 1, comment => 'use vars failing' },
);

is( pcritique( 'Variables::RequireHungarianNotation', \$_->{code} ), $_->{violations}, $_->{comment} ) for @a_tests;

exit 0;

__END__
