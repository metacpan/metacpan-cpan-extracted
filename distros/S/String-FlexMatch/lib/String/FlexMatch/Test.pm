use 5.008;
use strict;
use warnings;

package String::FlexMatch::Test;
our $VERSION = '1.100820';
# ABSTRACT: test methods that can handle flexible strings
use Test::Builder;

# Code that uses this testing package will likely need String::FlexMatch as
# well, therefore we load it here so the other code won't have to.
use String::FlexMatch;
use Exporter qw(import);
our @EXPORT = qw(is_deeply_flex isnt_deeply_flex eq_array_flex eq_hash_flex);
my $Test = Test::Builder->new;

# Basically copied code from Test::More 0.45, which didn't yet break
# String::FlexMatch. Back in that version the sane view was taken that if an
# object overrides stringification, it probably does so for a reason, and that
# stringification defines how the object wants to be compared. Newer versions
# of Test::More simply say that if you have a string and a reference, they
# can't possibly be the same.
use vars qw(@Data_Stack);
my $DNE = bless [], 'Does::Not::Exist';

sub is_deeply_flex {
    my ($got, $expect, $name) = @_;
    my $ok;
    if (!ref $got || !ref $expect) {
        $ok = is_eq($got, $expect, $name);
    } else {
        local @Data_Stack = ();
        if (_deep_check($got, $expect)) {
            $ok = $Test->ok(1, $name);
        } else {
            $ok = $Test->ok(0, $name);
            $ok = $Test->diag(_format_stack(@Data_Stack));
        }
    }
    return $ok;
}

sub is_eq {
    my ($got, $expect, $name) = @_;
    if (!defined $got || !defined $expect) {

        # undef only matches undef and nothing else
        my $test = !defined $got && !defined $expect;
        $Test->ok($test, $name);
        $Test->_is_diag($got, 'eq', $expect) unless $test;
        return $test;
    }
    return cmp_ok($got, 'eq', $expect, $name);
}

sub cmp_ok {
    my ($got, $type, $expect, $name) = @_;
    my $test;
    {
        local $^W = 0;
        local ($@, $!);    # don't interfere with $@
                           # eval() sometimes resets $!
        $test = eval "\$got $type \$expect";
    }
    my $ok = $Test->ok($test, $name);
    unless ($ok) {
        if ($type =~ /^(eq|==)$/) {
            $Test->_is_diag($got, $type, $expect);
        } else {
            $Test->_cmp_diag($got, $type, $expect);
        }
    }
    return $ok;
}

sub _format_stack {
    my (@Stack)   = @_;
    my $var       = '$FOO';
    my $did_arrow = 0;
    foreach my $entry (@Stack) {
        my $type = $entry->{type} || '';
        my $idx = $entry->{'idx'};
        if ($type eq 'HASH') {
            $var .= "->" unless $did_arrow++;
            $var .= "{$idx}";
        } elsif ($type eq 'ARRAY') {
            $var .= "->" unless $did_arrow++;
            $var .= "[$idx]";
        } elsif ($type eq 'REF') {
            $var = "\${$var}";
        }
    }
    my @vals = @{ $Stack[-1]{vals} }[ 0, 1 ];
    my @vars = ();
    ($vars[0] = $var) =~ s/\$FOO/     \$got/;
    ($vars[1] = $var) =~ s/\$FOO/\$expected/;
    my $out = "Structures begin differing at:\n";
    foreach my $idx (0 .. $#vals) {
        my $val = $vals[$idx];
        $vals[$idx] =
            !defined $val ? 'undef'
          : $val eq $DNE ? "Does not exist"
          :                "'$val'";
    }
    $out .= "$vars[0] = $vals[0]\n";
    $out .= "$vars[1] = $vals[1]\n";
    $out =~ s/^/    /msg;
    return $out;
}

sub eq_array_flex {
    my ($a1, $a2) = @_;
    return 1 if $a1 eq $a2;
    my $ok = 1;
    my $max = $#$a1 > $#$a2 ? $#$a1 : $#$a2;
    for (0 .. $max) {
        my $e1 = $_ > $#$a1 ? $DNE : $a1->[$_];
        my $e2 = $_ > $#$a2 ? $DNE : $a2->[$_];
        push @Data_Stack, { type => 'ARRAY', idx => $_, vals => [ $e1, $e2 ] };
        $ok = _deep_check($e1, $e2);
        pop @Data_Stack if $ok;
        last unless $ok;
    }
    return $ok;
}

sub _deep_check {
    my ($e1, $e2) = @_;
    my $ok = 0;
    my $eq;
    {

        # Quiet uninitialized value warnings when comparing undefs.
        local $^W = 0;

        # even after $^W we still got uninitialized warnings, so...
        no warnings 'uninitialized';
        if ($e1 eq $e2) {
            $ok = 1;
        } else {
            if (    UNIVERSAL::isa($e1, 'ARRAY')
                and UNIVERSAL::isa($e2, 'ARRAY')) {
                $ok = eq_array_flex($e1, $e2);
            } elsif (UNIVERSAL::isa($e1, 'HASH')
                and UNIVERSAL::isa($e2, 'HASH')) {
                $ok = eq_hash_flex($e1, $e2);
            } elsif (UNIVERSAL::isa($e1, 'REF')
                and UNIVERSAL::isa($e2, 'REF')) {
                push @Data_Stack, { type => 'REF', vals => [ $e1, $e2 ] };
                $ok = _deep_check($$e1, $$e2);
                pop @Data_Stack if $ok;
            } elsif (UNIVERSAL::isa($e1, 'SCALAR')
                and UNIVERSAL::isa($e2, 'SCALAR')) {
                push @Data_Stack, { type => 'REF', vals => [ $e1, $e2 ] };
                $ok = _deep_check($$e1, $$e2);
            } else {
                push @Data_Stack, { vals => [ $e1, $e2 ] };
                $ok = 0;
            }
        }
    }
    return $ok;
}

sub eq_hash_flex {
    my ($a1, $a2) = @_;
    return 1 if $a1 eq $a2;
    my $ok = 1;
    my $bigger = keys %$a1 > keys %$a2 ? $a1 : $a2;
    foreach my $k (keys %$bigger) {
        my $e1 = exists $a1->{$k} ? $a1->{$k} : $DNE;
        my $e2 = exists $a2->{$k} ? $a2->{$k} : $DNE;
        push @Data_Stack, { type => 'HASH', idx => $k, vals => [ $e1, $e2 ] };
        $ok = _deep_check($e1, $e2);
        pop @Data_Stack if $ok;
        last unless $ok;
    }
    return $ok;
}
1;


__END__
=pod

=head1 NAME

String::FlexMatch::Test - test methods that can handle flexible strings

=head1 VERSION

version 1.100820

=head1 METHODS

=head2 cmp_ok

FIXME

=head2 eq_array_flex

FIXME

=head2 eq_hash_flex

FIXME

=head2 is_deeply_flex

FIXME

=head2 is_eq

FIXME

=head1 INSTALLATION

See perlmodinstall for information and options on installing Perl modules.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests through the web interface at
L<http://rt.cpan.org/Public/Dist/Display.html?Name=String-FlexMatch>.

=head1 AVAILABILITY

The latest version of this module is available from the Comprehensive Perl
Archive Network (CPAN). Visit L<http://www.perl.com/CPAN/> to find a CPAN
site near you, or see
L<http://search.cpan.org/dist/String-FlexMatch/>.

The development version lives at
L<http://github.com/hanekomu/String-FlexMatch/>.
Instead of sending patches, please fork this project using the standard git
and github infrastructure.

=head1 AUTHOR

  Marcel Gruenauer <marcel@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2004 by Marcel Gruenauer.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

