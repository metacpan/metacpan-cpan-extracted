package Parse::RecDescent::Deparse;
use Parse::RecDescent;

use 5.006;
use strict;
use warnings;

$Parse::RecDescent::Deparse::VERSION = '1.00';

# This is not a Parse::RecDescent optimizer.

# Given a grammar
#
#       a : b 
#       b : 'foo' c 'baz'
#       c : 'bar'
#
# repeated calls to ->hoist will produce
#
#       a : 'foo' c 'baz'
#       b : 'foo' 'bar' 'baz'
#       c : 'bar'
#
# and
#
#       a : 'foo' 'bar' 'baz'
#       b : 'foo' 'bar' 'baz'
#       c : 'bar'

sub Parse::RecDescent::hoist {
    my $self = shift;
    RULE: for (values %{$self->{rules}}) {
        my @directly_calls = 
            map { $_->{subrule} }
            grep { ref $_ eq "Parse::RecDescent::Subrule" }
            map { @{$_->{items}} }
            @{$_->{prods}};
        for my $subrule (@directly_calls) {
            $subrule = $self->{rules}->{$subrule};
            next if @{$subrule->{prods}} > 1 or !@{$subrule->{prods}};
            #print "Hoisting $subrule->{name} into $_->{name}\n";
            for my $prod (@{$_->{prods}}) {
                for my $i (0..$#{$prod->{items}}) {
                    if (ref $prod->{items}[$i] eq 
                        "Parse::RecDescent::Subrule" and
                        $prod->{items}[$i]{subrule} eq $subrule->{name}) {
                    splice (@{$prod->{items}}, $i, 1, map {bless{ %$_ }, ref$_} @{$subrule->{prods}[0]->{items}}); # Ugly hack
                    return;
                    }
                }
            }
        }
    }
}

# Given a grammar
#
# a : 'b' /c/ "d"
#
# ->merge_literals will produce
#
# a : 'bcd'

sub Parse::RecDescent::merge_literals {
    my $self = shift;
    for (values %{$self->{rules}}) {
        for (@{$_->{prods}}) {
            for (@{$_->{items}}) {
                if (ref $_ eq "Parse::RecDescent::Token" and
                    $_->{pattern} !~ /[\(\[\]\)\+\*\?\\\^]/ and 
                    $_->{pattern} !~ /\$$/) {
                    bless $_, "Parse::RecDescent::InterpLit";
                }
                if (ref $_ eq "Parse::RecDescent::InterpLit" and
                    $_->{pattern} !~ /(^|[^\\])[\$\@]/) {
                    bless $_, "Parse::RecDescent::Literal";
                }
            }
            next unless @{$_->{items}} > 1;
            RETRY: for my $i (1..$#{$_->{items}}) {
                if (ref $_->{items}[$i] eq "Parse::RecDescent::Literal"
                    and (ref $_->{items}[$i-1] eq "Parse::RecDescent::Literal"
                    or ref $_->{items}[$i-1] eq "Parse::RecDescent::InterpLit")
                   ) {
                   if (ref $_->{items}[$i-1] eq "Parse::RecDescent::InterpLit") {
                       $_->{items}[$i-1]{pattern} =~ s/([\@\$])::(\w+)$/$1::{$2}/;
                   }
                   $_->{items}[$i-1]->{pattern} .= (splice @{$_->{items}}, $i, 1)->{pattern};
                   # XXX Swizzle item numbers here.
                   goto RETRY;
                }
            }
        }
    }
}

sub Parse::RecDescent::deparse {
    my $self = shift;
    return join "", map {" $_ : ".$self->{rules}->{$_}->deparse."\n"}
           sort {
                $self->{rules}->{$a}->{line}
                    <=>
                $self->{rules}->{$b}->{line}
              } 
           keys %{$self->{rules}};
}

sub Parse::RecDescent::Rule::deparse {
    my $self = shift;
    return join " | ", map { $_->deparse } @{$self->{prods}};
}

sub Parse::RecDescent::Production::deparse {
    my $self = shift;
    return join " ", map {$_->deparse} @{$self->{items}};
}

sub Parse::RecDescent::InterpLit::deparse {
    my $dq = (shift)->{pattern};
    return qq{"$dq"} if $dq !~ /"/;
    return "qq{$dq}" if $dq !~ /[\{\}]/;
    no warnings; # Sheesh
    for (qw(/ # !)) { return "qq$_$dq$_" if $dq !~ /$_/; }
    # Sodding hell.
    $dq =~ s/"/\\"/g;
    return qq{"$dq"};
}

sub Parse::RecDescent::Subrule::deparse {
    my $self = shift;
    return $self->{subrule};
}

sub Parse::RecDescent::Literal::deparse {
    my $self = shift;
    my $q = $self->{pattern};
    return qq{'$q'} if $q !~ /'/;
    return "q{$q}" if $q !~ /[\{\}]/;
    no warnings;
    for (qw(/ # !)) { return "q$_$q$_" if $q !~ /$_/; }
    # Sodding hell.
    $q =~ s/'/\\'/g;
    return qq{'$q'};
}

sub Parse::RecDescent::Token::deparse {
    my $self = shift;
    return "m".$self->{ldelim}.$self->{pattern}.$self->{rdelim};
}

sub Parse::RecDescent::Action::deparse {
    my $self = shift;
    return $self->{code};
}

sub Parse::RecDescent::Repetition::deparse {
    my $self = shift;
    return $self->{subrule}."($self->{repspec})";
}

=head1 NAME

Parse::RecDescent::Deparse - Turn a Parse::RecDescent object back into its grammar

=head1 SYNOPSIS

  use Parse::RecDescent::Deparse;

  my $foo = new Parse::RecDescent($grammar);
  print $foo->deparse;

=head1 DESCRIPTION

This module adds the C<deparse> method to the C<Parse::RecDescent>
class, which returns a textual description of the grammar.

Why? There are at least two equally unlikely reasons why this could be
useful:

=over 3

=item *

You're working on something which grovels around in the
C<Parse::RecDescent> object data structure and want to view the effects
of your changes. For instance, a C<Parse::RecDescent> optimizer. (This
 package does not contain a functional C<Parse::RecDescent> optimizer.)

=item *

You want to understand how C<Parse::RecDescent> does what it does, and
fancy the source of this package is a bit more of a gentle introduction
than the source of C<Parse::RecDescent> itself.

=back

=head2 BUGS

C<Parse::RecDescent::Deparse> can correctly deparse the metagrammar for
C<Parse::RecDescent> input, so that's a good thing. There are no bugs in
the C<Parse::RecDescent> optimizer as it clearly does not exist.


=head1 AUTHOR

Simon Cozens, C<simon@cpan.org>

=head1 SEE ALSO

L<Parse::RecDescent>.

=cut
