#!/usr/bin/env perl
use strict;
use warnings;
use utf8;
use FindBin;
use lib "$FindBin::Bin/../lib";
use Path::Maker;

my ($name, $email) = @ARGV;
die "usage: $0 NAME EMAIL\n" unless $email;

my $maker = Path::Maker->new(
    base_dir => $ENV{HOME},
    template_header => "? my \$arg = shift;\n"
);
$maker->render_to_file('.gitconfig' => '.gitconfig', {name => $name, email => $email});
$maker->render_to_file('.vimrc' => '.vimrc', {home => $ENV{HOME}});
$maker->create_dir('.swap');

__DATA__

@@ .gitconfig
[user]
    name = <?= $arg->{name} ?>
    email = <?= $arg->{email} ?>
[color]
    ui = auto

@@ .vimrc
set number
set directory=<?= $arg->{home} ?>/.swap
