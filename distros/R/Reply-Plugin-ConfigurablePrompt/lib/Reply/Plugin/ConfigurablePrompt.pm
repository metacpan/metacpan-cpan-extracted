package Reply::Plugin::ConfigurablePrompt;
use parent qw(Reply::Plugin);
use 5.008005;
use strict;
use warnings;

our $VERSION = "0.02";

my $history_count = 0;

sub new {
    my $class = shift;
    my %opts  = @_;

    my $self = $class->SUPER::new(@_);
    $self->{prompt_string} = $opts{prompt};
    *main::history_count = \$history_count;
    $self->{prompted} = 0;
    return $self;
}

sub prompt {
    my $self = shift;
    my ($next) = @_;
    $self->{prompted} = 1;
    my $result = "";
    my $prompt = $self->{prompt_string};
    if ( $prompt ) {
        package main;

        $result = eval "$prompt" if ( $prompt );
        die $@ if ( $@ );
    }
    return $result ? $result                     # configured prompt
                   : $history_count . $next->(); # default prompt
}

sub loop {
    my $self = shift;
    my ($continue) = @_;
    $history_count++ if ( $self->{prompted} );
    $self->{prompted} = 0;
    $continue;
}



1;
__END__

=encoding utf-8

=for stopwords configurable

=head1 NAME

Reply::Plugin::ConfigurablePrompt - Configurable prompt for reply

=head1 SYNOPSIS

    ; in your .replyrc use following instead of [FancyPrompt] (or other prompt plugin)
    [ConfigurablePrompt]
    prompt="reply $history_count \$ "

=head1 DESCRIPTION

Reply::Plugin::ConfigurablePrompt is plugin for Reply. This plugin provides configurable prompt.

=head1 NOTE

This plugin is exclusive to other prompt plugin.

=head1 HOW TO CUSTOMIZE

You can use any perl syntax in prompt section. variables and functions are usable if these are exported in main package.

=head1 EXPORTED VARIABLES

=head2 $history_count

the history number of this command

=head1 LICENSE

Copyright (C) Takuya Tsuchida.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Takuya Tsuchida E<lt>tsucchi@cpan.orgE<gt>

=cut

