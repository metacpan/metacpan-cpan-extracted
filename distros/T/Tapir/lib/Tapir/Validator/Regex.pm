package Tapir::Validator::Regex;

use strict;
use warnings;

sub new {
    my ($class, %self) = @_;
    return bless \%self, $class;
}

sub new_from_string {
    my ($class, $string) = @_;
    my $regex;
    my ($lq, $body, $rq, $opts) = $string =~ m{^\s* (\S)(.+?)(\S) ([xsmei]*) \s*$}x;

    my $left_brackets  = '[{(';
    my $right_brackets = ']})';
    if ($lq eq $rq || (
            index($left_brackets, $lq) >= 0 &&
            index($left_brackets, $lq) == index($right_brackets, $rq)
        )) {
        $regex = eval "qr{$body}$opts";
        die $@ if $@;
    }
    if (! $regex) {
        Tapir::InvalidSpec->throw(
            error => "Can't parse regex pattern from '$string'",
        );
    }
    return $class->new(string => $string, regex => $regex, body => $body, opts => $opts);
}

sub validate_field {
    my ($self, $field, $desc) = @_;
    $desc ||= defined $field->value ? '"' . $field->value . '"' : 'undef';

    if (! $field->isa('Thrift::Parser::Type::string')) {
        Tapir::InvalidSpec->throw(
            error => "Validator ".ref($self)." is only valid for string",
            key => ref($field)
        );
    }

    if (defined $field->value && $field->value !~ $self->{regex}) {
        Tapir::InvalidArgument->throw(
            error => "Argument $desc doesn't pass regex $self->{string}",
            key => $field->name, value => $field->value,
        );
    }
}

sub documentation {
    my $self = shift;
    return "Must match m/$self->{body}/$self->{opts}";
}

1;
