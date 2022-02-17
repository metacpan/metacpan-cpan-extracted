#!/usr/bin/perl

use 5.014;
use warnings;
use open qw( :std :encoding(UTF-8) );
use FindBin;
use lib "$FindBin::Bin/../lib";

use Term::CLI;

my $Start_Credit = 5;

my $cli = Term::CLI->new(name => 'capitalism');

$cli->state->{credit} = $Start_Credit;

$cli->add_command(
   Term::CLI::Command::Help->new(),
   show_command(),
   buy_command(),
   borrow_command(),
);

while (my $line = $cli->readline(prompt => mk_prompt($cli))) {
   $cli->execute($line);
}

sub mk_prompt {
    my ($cli) = @_;
    return '['.money_str($cli->state->{credit}).']~> ';
}

sub money_str {
   my @l = map { 
       "\N{THAI CURRENCY SYMBOL BAHT} ".commify(sprintf("%0.2f", $_));
   } @_;
   return wantarray ? @l : $l[0];
}

sub commify {
   my $s = reverse(shift);
   return reverse $s =~ s{ (\d{3}) (?=\d) (?!\d*\.) }{$1,}gxmsr;
}


sub buy_command {
    return Term::CLI::Command->new(
        name     => 'buy',
        summary  => 'spend money (decrease credit)',
        arguments => [ Term::CLI::Argument::Number::Float->new(
            name => 'amount',
            min => 0,
            min_occur => 0,
        )],
        callback => sub {
            my ($self, %args) = @_;
            return %args if $args{status} < 0;

            my $cli = $self->root_node;

            my $amount = $args{arguments}->[0] // 1;

            if ($cli->state->{credit} >= $amount) {
                $cli->state->{credit} -= $amount;
                printf( "purchased stuff for %s, credit is now: %s\n",
                    money_str($amount, $cli->state->{credit}) );
                return %args;
            }
            return (%args,
                error => "cannot purchase: not enough credit",
                status => -1
            );
        },
    );
}

sub borrow_command {
    return Term::CLI::Command->new(
        name     => 'borrow',
        summary  => 'borrow money (decrease credit)',
        arguments => [ Term::CLI::Argument::Number::Float->new(
            name => 'amount',
            min => 0,
            min_occur => 0,
        )],
        callback => sub {
            my ($self, %args) = @_;
            return %args if $args{status} < 0;

            my $cli = $self->root_node;
            my $amount = $args{arguments}->[0] // $Start_Credit;

            $cli->state->{credit} += $amount;
            printf( "stole %s, credit is now: %s\n",
                money_str($amount, $cli->state->{credit}) );
            return %args;
        },
    );
}

sub show_command {
    return Term::CLI::Command->new(
        name     => 'show',
        summary  => 'show things',
        commands => [
            Term::CLI::Command->new(
                name     => 'balance',
                summary  => 'show balance',
                callback => sub {
                    my ($self, %args) = @_;
                    return %args if $args{status} < 0;

                    my $credit = $self->root_node->state->{credit};
                    say "your balance is: ", money_str($credit);
                    return %args;
                },
            ),
            Term::CLI::Command->new(
                name     => 'clock',
                summary  => 'show time',
                callback => sub {
                    my ($self, %args) = @_;
                    return %args if $args{status} < 0;

                    say scalar localtime(time);
                    return %args;
                },
            ),
        ],
    );
}

