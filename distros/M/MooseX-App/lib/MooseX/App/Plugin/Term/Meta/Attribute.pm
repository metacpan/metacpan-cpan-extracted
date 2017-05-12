# ============================================================================
package MooseX::App::Plugin::Term::Meta::Attribute;
# ============================================================================

use utf8;
use 5.010;

use namespace::autoclean;
use Moose::Role;

no if $] >= 5.018000, warnings => qw(experimental::smartmatch);

use Term::ReadKey;

has 'cmd_term' => (
    is          => 'ro',
    isa         => 'Bool',
    default     => sub {0},
);

has 'cmd_term_label' => (
    is          => 'ro',
    isa         => 'Str',
    predicate   => 'has_cmd_term_label',
);

sub cmd_term_label_full {
    my ($self) = @_;

    my $label = $self->cmd_term_label_name;
    my @tags;
    if ($self->is_required) {
        push(@tags,'Required');
    } else {
        push(@tags,'Optional');
    }

    if ($self->has_type_constraint) {
        my $type_constraint = $self->type_constraint;
        if ($type_constraint->is_a_type_of('Bool')) {
            push(@tags,'Y/N');
        } else {
            push(@tags,$self->cmd_type_constraint_description($type_constraint));
        }
    }
    if (scalar @tags) {
        $label .= ' ('.join(', ',@tags).')';
    }

    return $label;
}

sub cmd_term_label_name {
    my ($self) = @_;

    my $label;
    if ($self->has_cmd_term_label) {
        return $self->cmd_term_label;
    } elsif ($self->has_documentation) {
        return $self->documentation;
    } else {
        return $self->name;
    }
}

sub cmd_term_read {
    my ($self) = @_;

    if ($self->has_type_constraint
        && $self->type_constraint->is_a_type_of('Bool')) {
        return $self->cmd_term_read_bool();
    } else {
        return $self->cmd_term_read_string();
    }
}

sub cmd_term_read_string {
    my ($self) = @_;

    my $label = $self->cmd_term_label_full;
    my ($return,@history,$history_disable,$allowed);

    binmode STDIN,':encoding(UTF-8)';

    # Prefill history with enums
    if ($self->has_type_constraint) {
        my $type_constraint = $self->type_constraint;
        if ($type_constraint->isa('Moose::Meta::TypeConstraint::Enum')) {
            push(@history,@{$self->type_constraint->values});
            $history_disable = 1
        } elsif (!$type_constraint->has_coercion) {
            if ($type_constraint->is_a_type_of('Int')) {
                $allowed = qr/[0-9]/;
            } elsif ($type_constraint->is_a_type_of('Num')) {
                $allowed = qr/[0-9.]/;
            }
        }
    }

    push(@history,"")
        unless scalar @history;

    my $history_index = 0;
    my $history_add = sub {
        my $entry = shift;
        if (! $history_disable
            && defined $entry
            && $entry !~ m/^\s*$/
            && ! ($entry ~~ \@history)) {
            push(@history,$entry);
        }
    };

    ReadMode('cbreak'); # change input mode
    TRY_STRING:
    while (1) {
        print "\n"
            if defined $return
            && $return !~ /^\s*$/;
        $return = '';

        if (defined $Term::ANSIColor::VERSION) {
            say Term::ANSIColor::color('white bold').$label.' :'.Term::ANSIColor::color('reset');
        } else {
            say $label.": ";
        }

        1 while defined ReadKey -1; # discard any previous input

        my $cursor = 0;

        KEY_STRING:
        while (1) {
            my $key         = ReadKey 0; # read a single character
            my $length      = length($return);
            my $key_code    = ord($key);

            if ($key_code == 10) { # Enter
                print "\n";
                my $error;
                if ($return =~ m/^\s*$/) {
                    if ($self->is_required) {
                        $error = 'Value is required';
                    } else {
                        $return = undef;
                        last TRY_STRING;
                    }
                } else {
                    $error = $self->cmd_type_constraint_check($return);
                }
                if ($error) {
                    if (defined $Term::ANSIColor::VERSION) {
                        say Term::ANSIColor::color('bright_red bold').$error.Term::ANSIColor::color('reset');
                    } else {
                        say $error;
                    }
                    $history_add->($return);
                    next TRY_STRING;
                } else {
                    last TRY_STRING;
                }
            } elsif ($key_code == 27) { # Escape sequence
                my $escape;
                while (1) { # Read rest of escape sequence
                    my $code = ReadKey -1;
                    last unless defined $code;
                    $escape .= $code;
                }
                if (defined $escape) {
                    given ($escape) {
                        when ('[D') { # Cursor left
                            if ($cursor > 0) {
                                print "\b";
                                $cursor--;
                            }
                        }
                        when ($escape eq '[C') { # Cursor right
                            if ($cursor < length($return)) {
                                print substr $return,$cursor,1;
                                $cursor++;
                            }
                        }
                        when ($escape eq '[A') { # Cursor up
                            $history_add->($return);
                            print "\b" x $cursor;
                            print " " x length($return);
                            print "\b" x length($return);

                            $history_index ++
                                if defined $history[$history_index]
                                && $history[$history_index] eq $return;
                            $history_index = 0
                                unless defined $history[$history_index];

                            $return = $history[$history_index];
                            $cursor = length($return);
                            print $return;
                            $history_index++;
                        }
                        when ($escape eq '[3~') { # Del
                            if ($cursor != length($return)) {
                                substr $return,$cursor,1,'';
                                print substr $return,$cursor;
                                print " ".(("\b") x (length($return) - $cursor + 1));
                            }
                        }
                        when ($escape eq 'OH') { # Pos 1
                            print (("\b") x $cursor);
                            $cursor = 0;
                        }
                        when ($escape eq 'OF') { # End
                            print substr $return,$cursor;
                            $cursor = length($return);
                        }
                        #default {
                        #    print $escape;
                        #}
                    }
                } else {
                    $history_add->($return);
                    next TRY_STRING;
                }

            } elsif ($key_code == 127) { # Backspace
                if ($cursor == 0) { # Ignore first
                    next KEY_STRING;
                }
                $cursor--;
                substr $return,$cursor,1,''; # string
                print "\b".substr $return,$cursor; # print
                print " ".(("\b") x (length($return) - $cursor + 1)); # cursor
            } else { # Character
                if ($_ <= 31) { # ignore controll chars
                    print "\a";
                    next KEY_STRING;
                } elsif (defined $allowed
                    && $key !~ /$allowed/) {
                    print "\a";
                    next KEY_STRING;
                }
                substr $return,$cursor,0,$key; # string
                print substr $return,$cursor; # print
                $cursor++;
                print (("\b") x (length($return) - $cursor)); # cursor
            }
        }
    }
    ReadMode 0;

    return $return;
}

sub cmd_term_read_bool {
    my ($self) = @_;

    my $label = $self->cmd_term_label_full;
    my $return;

    if (defined $Term::ANSIColor::VERSION) {
        say Term::ANSIColor::color('white bold').$label.' :'.Term::ANSIColor::color('reset');
    } else {
        say $label.": ";
    }
    ReadMode 4; # change to raw input mode
    TRY:
    while (1) {
        1 while defined ReadKey -1; # discard any previous input
        my $key = ReadKey 0; # read a single character
        if ($key =~ /^[yn]$/i) {
            say uc($key);
            $return = uc($key) eq 'Y' ? 1:0;
            last;
        } elsif ((ord($key) == 10 || ord($key) == 27) && ! $self->is_required) {
            last;
        } elsif (ord($key) == 3) {
            ReadMode 0;
            kill INT => $$; # Not sure ?
        }
    }
    ReadMode 0;

    return $return;
}

around 'cmd_tags_list' => sub {
    my $orig = shift;
    my ($self) = @_;

    my @tags = $self->$orig();

    push(@tags,'Term')
        if $self->can('cmd_term')
        && $self->cmd_term;

    return @tags;
};

{
    package Moose::Meta::Attribute::Custom::Trait::AppTerm;

    use strict;
    use warnings;

    sub register_implementation { return 'MooseX::App::Plugin::Term::Meta::Attribute' }
}

1;
