package PerlActor::test::LineTokenizerTest;

use base 'PerlActor::test::TestCase';
use strict;
use Error qw( :try );
use PerlActor::LineTokenizer;

#===============================================================================================
# Public Methods
#===============================================================================================

sub set_up
{
	my $self = shift;
	$self->{tokenizer} = new PerlActor::LineTokenizer();
}

sub test_getTokens_undef_returns_no_tokens
{
	my $self = shift;
	my @tokens = $self->{tokenizer}->getTokens();
	$self->assert_array_equals([], \@tokens);
}

sub test_getTokens_empty_string_returns_no_tokens
{
	my $self = shift;
	my @tokens = $self->{tokenizer}->getTokens('');
	$self->assert_array_equals([], \@tokens);
}

sub test_getTokens_whitespace_only_string_returns_no_tokens
{
	my $self = shift;
	my @tokens = $self->{tokenizer}->getTokens("   \t    ");
	$self->assert_array_equals([], \@tokens);
}

sub test_getTokens_comment_string_returns_no_tokens
{
	my $self = shift;
	my @tokens = $self->{tokenizer}->getTokens("# This is a comment line");
	$self->assert_array_equals([], \@tokens);
}

sub test_getTokens_one_token_line
{
	my $self = shift;
	my @tokens = $self->{tokenizer}->getTokens('test');
	$self->assert_array_equals(['test'], \@tokens);
}

sub test_getTokens_one_token_line_with_newline
{
	my $self = shift;
	my @tokens = $self->{tokenizer}->getTokens("test\n");
	$self->assert_array_equals(['test'], \@tokens);
}

sub test_getTokens_multiple_token_line
{
	my $self = shift;
	my @tokens = $self->{tokenizer}->getTokens('test 1 2 3');
	$self->assert_array_equals(['test',1,2,3], \@tokens);
}

sub test_getTokens_quoted_token
{
	my $self = shift;
	my @tokens = $self->{tokenizer}->getTokens('"test me"');
	$self->assert_array_equals(['test me'], \@tokens);
}

sub test_getTokens_number_token
{
	my $self = shift;
	my @tokens = $self->{tokenizer}->getTokens("test 0");
	$self->assert_array_equals(['test', '0'], \@tokens);
}

sub test_getTokens_multiple_quoted_tokens_with_mixed_quoting
{
	my $self = shift;
	my @tokens = $self->{tokenizer}->getTokens(qq|"test me'" 'and "me" too' ~don't forget me~|);
	$self->assert_array_equals(["test me'",'and "me" too', "don't forget me"], \@tokens);
}

sub test_getTokens_multi_token_line_with_placeholders
{
	my $self = shift;
	my @tokens = $self->{tokenizer}->getTokens('test $0 $1 $2 "$0 again"','one','two','three');
	$self->assert_array_equals(['test','one','two','three','one again'], \@tokens);
}

sub test_getTokens_multi_placeholders_per_token
{
	my $self = shift;
	my @tokens = $self->{tokenizer}->getTokens('test "$0 $1 $2"','one','two','three');
	$self->assert_array_equals(['test','one two three'], \@tokens);
}

sub test_getTokens_escaped_placeholders
{
	my $self = shift;
	my @tokens = $self->{tokenizer}->getTokens('test $$0 $0','one');
	$self->assert_array_equals(['test','$0','one'], \@tokens);
}

#===============================================================================================
# Protected Methods - Don't even think about calling these from outside the class.
#===============================================================================================

# Keep Perl happy.
1;
