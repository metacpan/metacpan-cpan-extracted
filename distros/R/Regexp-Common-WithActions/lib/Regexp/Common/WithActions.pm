use 5.008;
use strict;
use warnings;

package Regexp::Common::WithActions;

our $VERSION = '0.01';

=head1 NAME

Regexp::Common::WithActions - adds actions to Regexp::Common

=head1 SYNOPSIS

    use Regexp::Common::WithActions;
    my $quoted = $RE{quoted}->action('quote')->(q{a string with ' or "});
    my $dequoted = $RE{quoted}->action('dequote')->(q{'a string with \' or "'});

=head1 DESCRIPTION

Some regular expressions from L<Regexp::Common> may be much better with
actions to manipulate matched data, for example for all variants
L<delimited|Regexp::Common::delimited> provides it's good to have quoter
and de-quoter actions.

This module extends %RE with action method. It can be used in the same
way as subs or match methods. For example:

    $RE{some}{re}{-with => 'arguments'}->action('action')->('do something');

As you can see action method returns a reference to a function implementing
particular action.

=head1 CAVEAT

Regexp::Common 2.122 has a problem that makes this module less useable. You
must load Regexp::Common::WithActions as the last thing (after all other
modules that can load R::C) in you programm.

Patch for this issue exists and waiting for abigail to release a new version.

=head1 ACTIONS

=head2 delimited and quoted

'quote' and 'dequote' are two actions provided for these regexps. Both work
in place in void context and return new value in other cases.

=head2 more

It's very easy to add a new action for other regexps in the module. Patches
are welcome.

=cut

our @ISA;

our %ACTION = (
    static => {},
    generated => { },
);

use Regexp::Common;

sub _croak { goto &Regexp::Common::_croak }

sub import {
    my $self = shift;

    my $parent = ref tied %Regexp::Common::RE;
    $parent ||= 'Regexp::Common';
    push @ISA, $parent unless $self->isa($parent);

    tie %Regexp::Common::RE, __PACKAGE__
        if !defined tied %Regexp::Common::RE
        || !tied( %Regexp::Common::RE )->isa(__PACKAGE__);

    {
        no strict 'refs';
        *{caller() . "::RE"} = \%Regexp::Common::RE;
    }
}

sub action {
    my ($self, $name, @rest) = @_;
    $name = '' unless defined $name;
    my $entry = $self->_decache;

    my $key = join '_', grep !/^-/, @{ $entry->{'args'} };

    my $action = $ACTION{'static'}{$key}{$name};
    return $action if $action;

    my $generator = $ACTION{'generated'}{$key}{$name};
    unless ( $generator ) {
        if ( length $name ) {
            _croak "Regexp has no action '$name'";
        } else {
            _croak 'Regexp has no default action';
        }
    }

    return $generator->(
        $entry, $entry->{flags}, $entry->{args},
        $name, @rest
    );
}

package Regexp::Common::WithActions::Actions;
sub _croak { goto &Regexp::Common::_croak }

sub gen_quoter {
    my ($dels, $escs) = @_;

    my $res;
    if ( length $escs ) {
        substr ($dels, 1) = '' foreach $dels, $escs;
        $res = sub {
            my $s = defined wantarray? \"$_[0]": \$_[0];
            $$s =~ s/(\Q$dels\E|\Q$dels\E)/$escs$1/g;
            substr($$s, 0, 0) = $dels;
            $$s .= $dels;
            $$s;
        }
    } else {
        my @dels = split //, $dels;
        $res = sub {
            my $del;
            foreach ( @dels ) {
                next if index($_[0], $_) >= 0;
                $del = $_; last;
            }
            _croak "Can not quote, string contains all possible delimiters"
                unless defined $del;

            my $s = defined wantarray? \"$_[0]": \$_[0];
            substr($$s, 0, 0) = $del;
            $$s .= $del;
            $$s;
        }
    }
    return $res;
}

sub gen_dequoter {
    my ($dels, $escs) = @_;

    my $res;
    if ( length $escs ) {
        $escs .= substr ($escs, -1) x (length ($dels) - length ($escs));
        my %del = map { $_ => (substr($escs,0,1,'')) } split //, $dels;
        $res = sub {
            my $esc = $del{ substr($_[0], 0, 1) };
            return $_[0] unless defined $esc
                && substr($_[0], 0, 1) eq substr($_[0], -1);

            my $s = defined wantarray? \"$_[0]": \$_[0];
            my $del = substr($$s, 0, 1, '');
            substr($$s, -1) = '';
            if ( $del ne $esc ) {
                $$s =~ s/\Q$esc\E(.)/$1/g;
            } else {
                $$s =~ s/\Q$del$del/$del/g;
            }
            $$s;
        }
    } else {
        my %del = map {$_=>1} split //, $dels;
        $res = sub {
            return $_[0] unless $del{ substr($_[0], 0, 1) }
                && substr($_[0], 0, 1) eq substr($_[0], -1);
            my $s = defined wantarray? \"$_[0]": \$_[0];
            substr($$s, 0, 1) = '';
            substr($$s, -1) = '';
            $$s
        }
    }
    return $res;
}



$Regexp::Common::WithActions::ACTION{'generated'}{'delimited'} = {
    quote => sub {
        return gen_quoter (@{$_[1]}{-delim, -esc});
    },
    dequote => sub {
        return gen_dequoter (@{$_[1]}{-delim, -esc});
    },
};

$Regexp::Common::WithActions::ACTION{'generated'}{'quoted'} = {
    quote => sub {
        return gen_quoter (@{$_[1]}{-delim, -esc});
    },
    dequote => sub {
        return gen_dequoter (@{$_[1]}{-delim, -esc});
    },
};

1;

=head1 AUTHOR

Ruslan.Zakirov@gmail.com

=head1 LICENSE

Under the same terms as perl itself.

=cut

