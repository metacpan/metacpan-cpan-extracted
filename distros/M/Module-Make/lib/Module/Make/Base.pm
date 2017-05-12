package Module::Make::Base;
use strict;
use warnings;
use IO::All 0.37;
use Class::Field qw'field const';
use XXX;

sub import {
    my $class = shift;
    my $flag = shift || '';
    my $package = caller;
    no strict 'refs';
    if ($flag eq '-base') {
        push @{$package . "::ISA"}, $class;
        *{$package . "::$_"} = \&$_
          for qw'io field const XXX';
    }
}

sub new {
    my $class = shift;
    return bless {@_}, $class;
}

sub require_class {
    my $self = shift;
    my $name = shift;
    my $class_name = $self->$name;
    eval "require $class_name";
    die $@ if $@;
    return $class_name;
}

sub prompt_yn {
    my ($self, $msg, $default_string) = @_;
    my $hash = {};
    $hash->{default} =
      $default_string eq 'Yn' ? 'y' :
      $default_string eq 'yN' ? 'n' :
      die "No default";
    
    $hash->{prompt} = "$msg [$default_string] > ";
    $hash->{validate} = sub { /^[yn]$/i };
    return lc $self->do_prompt($hash);
}

sub prompt_path {
    my ($self, $msg, $default) = @_;
    my $hash = {
        msg => $msg,
        default => $default || '',
    };
    $hash->{validate} = sub {
        /\S/ and not /\s/;
    };
    my $path = $self->do_prompt($hash);
    $path =~ s/^~/$ENV{HOME} || '~'/e;
    return $path;
}

sub do_prompt {
    my ($self, $hash) = @_;
    my ($msg, $default, $validate, $prompt) =
      @{$hash}{qw(msg default validate prompt)};
    return $default if $ENV{MODULE_MAKE_TEST};
    $prompt ||= "$msg [$default] > ";
    $prompt =~ s/\n /\n/;
    my $answer = '';
    while (1) {
        print $prompt;
        $answer = <STDIN>;
        chomp $answer;
        $answer ||= $default;
        local $_ = $answer;
        last if &$validate;
        print "$answer is an invalid response\n";
    }
    return $answer;
}

1;
