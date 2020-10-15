#!/usr/bin/env perl

use 5.010;
use strict;
use warnings;
use autodie;

our $VERSION = '9999';

use Carp;
use File::Temp;
use Rex::Commands::File;
use Rex::Hook::File::Impostor;
use Test2::V0;
use Test::File 1.443;

plan tests => 9;

my $original_file = File::Temp->new('original_XXXX')->filename();
my $impostor_file = Rex::Hook::File::Impostor::get_impostor_for($original_file);
my $impostor_dir  = Rex::Hook::File::Impostor::get_impostor_dir();

my $original_content = 'original';
my $impostor_content = 'impostor';

open my $FILE, '>', $original_file;
print {$FILE} $original_content or croak "Couldn't write to $original_file";
close $FILE;

file_exists_ok($original_file);
file_not_exists_ok($impostor_file);
file_contains_like( $original_file, qr{$original_content}msx );

file $original_file, content => $impostor_content;

file_exists_ok($original_file);
file_exists_ok($impostor_file);

file_contains_like( $original_file, qr{$original_content}msx );
file_contains_like( $impostor_file, qr{$impostor_content}msx );

unlink $original_file, $impostor_file;
rmdir $impostor_dir;

file_not_exists_ok($original_file);
file_not_exists_ok($impostor_dir);
