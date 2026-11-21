#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

use Path::Tiny qw( tempdir );
use Skilletor::Gitignore qw( block_entries has_block update_gitignore update_worktree_include );

my $BEGIN = '# >>> skilletor >>>';
my $END   = '# <<< skilletor <<<';

subtest 'CRLF managed blocks stay idempotent and preserve unrelated bytes' => sub {
  my @consumers = (
    [ '.gitignore',       sub { update_gitignore(@_) } ],
    [ '.worktreeinclude', sub { update_worktree_include(@_) } ],
  );
  for my $consumer (@consumers) {
    my ( $name, $update ) = @$consumer;
    my $tmp  = tempdir;
    my $dir  = $tmp->child( substr( $name, 1 ) );
    my $file = $dir->child($name);
    $dir->mkpath;
    my $before = "before\r\n  keep exactly \t\r\n$BEGIN\r\nold\r\n$END\r\nafter\r\n";
    $file->spew_raw($before);
    my $inode = ( stat "$file" )[1];

    is_deeply( [ block_entries("$file") ], ['old'], "$name: entries" );
    is( has_block("$dir"), 1, "$name: detected" ) if $name eq '.gitignore';
    is( $update->( dir => "$dir", entries => ['old'], enabled => 1 ), 'unchanged', "$name: unchanged" );
    is( $file->slurp_raw, $before, "$name: unchanged bytes" );
    is( ( stat "$file" )[1], $inode, "$name: unchanged file was not replaced" );

    is( $update->( dir => "$dir", entries => ['new'], enabled => 1 ), 'changed', "$name: changed" );
    is( $file->slurp_raw, "before\r\n  keep exactly \t\r\n$BEGIN\r\nnew\r\n$END\r\nafter\r\n", "$name: changed bytes" );
    my $changed = $file->slurp_raw;
    is( scalar( () = $changed =~ /\Q$BEGIN\E/g ), 1, "$name: one block" );

    is( $update->( dir => "$dir", entries => [], enabled => 1 ), 'removed', "$name: removed" );
    is( $file->slurp_raw, "before\r\n  keep exactly \t\r\nafter\r\n", "$name: unrelated bytes" );
    is_deeply( [ block_entries("$file") ], [], "$name: entries removed" );
    is( has_block("$dir"), 0, "$name: no block" ) if $name eq '.gitignore';
  }
};

subtest 'removing a CRLF block at EOF retains user-owned blank lines for both consumers' => sub {
  my @consumers = (
    [ '.gitignore',       sub { update_gitignore(@_) } ],
    [ '.worktreeinclude', sub { update_worktree_include(@_) } ],
  );
  for my $consumer (@consumers) {
    my ( $name, $update ) = @$consumer;
    my $tmp  = tempdir;
    my $dir  = $tmp->child( 'eof-'.substr( $name, 1 ) );
    my $file = $dir->child($name);
    $dir->mkpath;
    $file->spew_raw("foreign\r\n\r\n$BEGIN\r\nold\r\n$END\r\n");
    is( $update->( dir => "$dir", entries => [], enabled => 1 ), 'removed', "$name: removed" );
    is( $file->slurp_raw, "foreign\r\n\r\n", "$name: outside blank line retained" );
  }
};

done_testing;
