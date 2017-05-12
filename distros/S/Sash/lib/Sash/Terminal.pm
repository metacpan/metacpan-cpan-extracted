package Sash::Terminal;

use strict;
use warnings;

use Carp;
use Term::ReadKey;
use base qw( Term::ShellUI );
use Sash::Command;

sub new {
    my $class = shift;
    my $args = shift;

    my $terminal = Term::ShellUI->new(
        prompt => [ 'sash> ', '    > ' ],
        #commands => Sash::Command->defaults,
        history_file => $args->{history_file} || $ENV{HOME} . '/.sash_history',
        backslash_continues_command => 1,
        keep_quotes => 1,
        history_max => 500,
        display_summary_in_help => 0,
    );

    my $self = bless $terminal, ref $class || $class;

    return $self;
}

sub prompt_for {
    my $class = shift;
    my $for = shift;
    my $read_mode = ( shift ) ? 'noecho' : 1;

    print "$for: ";

    Term::ReadKey::ReadMode( $read_mode );
    my $input = Term::ReadKey::ReadLine( 0 );
    Term::ReadKey::ReadMode( 0 );

    print "\n" if $read_mode;

    chomp $input;
    
    return $input;
}

sub set_standard_prompt {
    my $self = shift;
    my $prompts = shift || [ 'sash> ', '    > ' ];

    $self->SUPER::prompt( $prompts );

    return;
}

sub set_continue_prompt {
    my $self = shift;
    my $prompts = shift || [ '    > ', 'sash> ' ];

    $self->SUPER::prompt( $prompts );

    return;
}

1;
