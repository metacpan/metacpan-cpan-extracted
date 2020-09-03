#!perl

use lib '.', 't/';
use File::Temp qw/tempfile/;
use Test::More;
use TestNvim;

my $tester = TestNvim->new;
my $vim = $tester->start();

sub current_buffer_number
{
	return tied (@{$vim->current->buffer})->number;
}

sub current_buffer_index
{
	return current_buffer_number()-1;
}

is scalar (@{$vim->buffers}), 1;
ok tied (@{$vim->buffers->[current_buffer_index()]}) == tied (@{$vim->current->buffer});
ok tied (@{tied (@{$vim->buffers})->get_bynumber (current_buffer_number())}) == tied (@{$vim->current->buffer});

my @buffers;
push @buffers, $vim->current->buffer;

$vim->command ('new');
is scalar (@{$vim->buffers}), 2;
push @buffers, $vim->current->buffer;
ok tied (@{$vim->buffers->[current_buffer_index()]}) == tied (@{$vim->current->buffer});
$vim->current->buffer (tied (@{$buffers[0]}));
ok tied (@{$vim->buffers->[current_buffer_index()]}) == tied (@{$buffers[0]});

done_testing();
