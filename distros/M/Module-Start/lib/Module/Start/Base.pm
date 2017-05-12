package Module::Start::Base;
use strict;
use warnings;

use Term::ReadLine;

sub new {
    my $self = bless {}, shift;
    while (@_) {
        my ($key, $value) = splice(@_, 0, 2);
        $self->$key($value);
    }
    return $self;
}

# XXX In the future support a config class override in the config file.
sub new_config_object {
    require Module::Start::Config;
    return Module::Start::Config->new;
}

sub exit {
    my ($self, $msg, $option) = (@_, '', '');
    chomp $msg;
    print "$msg\n" if $msg;
    print "Exiting...\n" unless $option eq -noExitMsg;
    CORE::exit;
}

# prompt a query and return true or false
sub p {
    my ($self, $query, $default) = @_;
    $query ||= '';
    $default ||= '';
    PROMPT: {
        my $answer = read_line($query . ' ');
        chomp $answer;
        $answer =~ s/^\s*(.*?)\s*$/$1/;
        $answer = $default unless length $answer;
        redo PROMPT unless length $answer;
        return $answer;
    }
}

sub q {
    my ($self, $query, $default) = @_;
    $query ||= '';
    $default ||= '';
    $query .=
        $default eq 'y' ? ' [Yn] ' : 
        $default eq 'n' ? ' [yN] ' : 
                          ' [yn] ';
    PROMPT: {
        my $answer = lc read_line($query);
        chomp $answer;
        $answer = $default unless $answer;
        redo PROMPT unless $answer =~ /^[yn]$/;
        return $answer =~ /y/;
    }
}

{
    $| = 1;
    my $rl;
    $rl = Term::ReadLine->new if -t STDOUT;
    sub read_line {
        my $query = shift;
        my $input;
        if ($rl) {
            $input = $rl->readline($query);
        }
        else {
            print $query;
            $input = readline();
        }
        if (not defined $input) {
            print "\n";
            CORE::exit;
        }
        $input .= "\n";
    }
}

sub read_data_files {
    my ($self, $package) = @_;
    my $hash;
    %$hash = $self->get_packed_files($package);
    return $hash;
}

sub get_packed_files {
    my ($self, $package) = @_;
    my $data = $self->data($package) or return;
    my @data = split $self->file_separator_regexp, $data;
    shift @data;
    return @data;
}

sub file_separator_regexp {
    return qr/^__+\[\s*(.+?)\s*\]__+\n/m;
}

sub data {
    my $self = shift;
    my $package = shift;
    local $SIG{__WARN__} = sub {};
    local $/;
    eval "package $package; <DATA>";
}

sub render_template {
    require Template;
    my ($self, $template, %vars) = @_;

    $vars{self} = $self;

    my $t = Template->new;

    my $output;
    eval {
        $t->process($template, \%vars, \$output) or die $t->error;
    };
    die "Template Toolkit error:\n$@" if $@;
    return $output;
}

1;

=head1 NAME

Module::Start::Base - Base class for Module::Start

=head1 SYNOPSIS

