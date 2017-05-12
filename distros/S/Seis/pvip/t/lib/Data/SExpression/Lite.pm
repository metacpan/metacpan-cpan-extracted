package Data::SExpression::Lite;
use strict;
use warnings;
use utf8;
use 5.010000;
use Carp ();

sub new {
    my $class = shift;
    my $self = bless {}, $class;
    return $self;
}

sub parse {
    my ($self, $sexp) = @_;
    unless (defined $sexp) {
        Carp::confess("sexp should be defined.");
    }
    if (length($sexp) == 0) {
        Carp::confess("Do not pass the empty string.");
    }
    $self->lex(\$sexp) eq '(' or die "No opening paren";
    $self->_parse(\$sexp);
}

sub _parse {
    my ($self, $sexp) = @_;
    my @tokens;
    while ($$sexp =~ /\S/) {
        my $token = $self->lex($sexp);
        if ($token eq ')') {
            return \@tokens;
        } elsif ($token eq '(') {
            push @tokens, $self->_parse($sexp);
        } else {
            push @tokens, $token;
        }
    }
    die "Unexpected EOF in sexp";
}

sub lex {
    my ($self, $sexp) = @_;
    $$sexp =~ s/^\s+//;

    if ($$sexp =~ s/^\(//) {
        return '(';
    } elsif ($$sexp =~ s/^\)//) {
        return ')';
    } elsif ($$sexp =~ s/^"(.*?)"//) {
        return $1;
    } elsif ($$sexp =~ s/^([0-9.]+)//) {
        return $1;
    } elsif ($$sexp =~ s/^([a-zA-Z0-9_-]+)//) {
        return $1;
    } elsif ($$sexp =~ s/^([^)]+)//) {
        return $1;
    } elsif ($$sexp eq '') {
        die "Unexpected EOF";
    } else {
        die "Unknown token: $$sexp";
    }
}

1;
