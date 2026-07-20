#!/usr/bin/env perl
##----------------------------------------------------------------------------
## Person Name Format - ~/bench/format.pl
## Version v0.1.0
## Copyright(c) 2026 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2026/07/17
## Modified 2026/07/17
## All rights reserved
## 
## This program is free software; you can redistribute  it  and/or  modify  it
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
use v5.10.1;
use strict;
use warnings;
use utf8;
use Benchmark qw( cmpthese );
use Getopt::Long qw( GetOptions );
use PersonName::Format;
use PersonName::Format::SimpleName;

my $iterations = 100_000;
my $suite = 'all';
my $help;
GetOptions(
    'iterations=i' => \$iterations,
    'suite=s'      => \$suite,
    'help'         => \$help,
) || die( "Invalid benchmark arguments.\n" );

if( $help )
{
    print <<'USAGE';
Usage: perl -Mblib bench/format.pl [options]

Options:
  --iterations N   Number of calls per benchmark (default: 100000)
  --suite NAME     all, latin, japanese, multiscript, or grapheme
  --help           Show this help

Run once with XS and once with PERSONNAME_FORMAT_PUREPERL=1.
USAGE
    exit(0);
}

die( "--iterations must be greater than zero.\n" )
    unless( $iterations > 0 );

my $backend = $PersonName::Format::IsPurePerl ? 'PP' : 'XS';
print( "Backend: ${backend}\n" );
print( "Iterations per case: ${iterations}\n" );

my $en = PersonName::Format->new(
    'en',
    length      => 'medium',
    usage       => 'referring',
    formality   => 'formal',
) || die( PersonName::Format->error );

my $ja = PersonName::Format->new(
    'ja-JP',
    length      => 'medium',
    usage       => 'referring',
    formality   => 'formal',
) || die( PersonName::Format->error );

my $latin = PersonName::Format::SimpleName->new(
    given      => 'Jacques',
    surname    => 'Deguest',
    nameLocale => 'fr-FR',
) || die( PersonName::Format::SimpleName->error );

my $japanese = PersonName::Format::SimpleName->new(
    given      => '駿',
    surname    => '宮崎',
    nameLocale => 'ja-JP',
) || die( PersonName::Format::SimpleName->error );

my $arabic = PersonName::Format::SimpleName->new(
    given      => 'محمد',
    surname    => 'علي',
    nameLocale => 'ar-EG',
) || die( PersonName::Format::SimpleName->error );

my $devanagari = PersonName::Format::SimpleName->new(
    given      => 'अमित',
    surname    => 'शर्मा',
    nameLocale => 'hi-IN',
) || die( PersonName::Format::SimpleName->error );

my $cases =
{
    latin => sub
    {
        $en->format( $latin ) || die( $en->error );
    },
    japanese => sub
    {
        $ja->format( $japanese ) || die( $ja->error );
    },
    arabic => sub
    {
        $en->format( $arabic ) || die( $en->error );
    },
    devanagari => sub
    {
        $en->format( $devanagari ) || die( $en->error );
    },
    grapheme => sub
    {
        PersonName::Format::_first_grapheme( "👩‍💻 engineer" );
    },
    script => sub
    {
        PersonName::Format::_get_name_script( '宮崎', '駿' );
    },
};

my @selected;
if( $suite eq 'all' )
{
    @selected = qw( latin japanese arabic devanagari grapheme script );
}
elsif( $suite eq 'latin' )
{
    @selected = qw( latin );
}
elsif( $suite eq 'japanese' )
{
    @selected = qw( japanese );
}
elsif( $suite eq 'multiscript' )
{
    @selected = qw( latin japanese arabic devanagari );
}
elsif( $suite eq 'grapheme' )
{
    @selected = qw( grapheme script );
}
else
{
    die( "Unknown benchmark suite '${suite}'.\n" );
}

my $selected = {};
foreach my $name ( @selected )
{
    $selected->{ $name } = $cases->{ $name };
}

# Warm caches before timing.
$_->() foreach( values( %$selected ) );

cmpthese( $iterations, $selected );
