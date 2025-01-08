package Perl::MinimumVersion::Fast;
use 5.008005;
use strict;
use warnings;

use version ();

use Compiler::Lexer 0.13;
use List::Util qw(max);

our $VERSION = "0.22";

my $MIN_VERSION   = version->new('5.006');
my $VERSION_5_020 = version->new('5.020');
my $VERSION_5_018 = version->new('5.018');
my $VERSION_5_016 = version->new('5.016');
my $VERSION_5_014 = version->new('5.014');
my $VERSION_5_012 = version->new('5.012');
my $VERSION_5_010 = version->new('5.010');
my $VERSION_5_008 = version->new('5.008');

sub new {
    my ($class, $stuff) = @_;

    my $filename;
    my $src;
    if (ref $stuff ne 'SCALAR') {
        $filename = $stuff;
        open my $fh, '<', $filename
            or die "Unknown file: $filename";
        $src = do { local $/; <$fh> };
    } else {
        $filename = '-';
        $src = $$stuff;
    }

    my $lexer = Compiler::Lexer->new($filename);
    my @tokens = $lexer->tokenize($src);

    my $self = bless { }, $class;
    $self->{minimum_explicit_version} = $self->_build_minimum_explicit_version(\@tokens);
    $self->{minimum_syntax_version}   = $self->_build_minimum_syntax_version(\@tokens);
    $self;
}

sub _build_minimum_explicit_version {
    my ($self, $tokens) = @_;
    my @tokens = map { @$_ } @{$tokens};

    my $explicit_version;
    for my $i (0..@tokens-1) {
        if ($tokens[$i]->{name} eq 'UseDecl' || $tokens[$i]->{name} eq 'RequireDecl') {
            if (@tokens >= $i+1) {
                my $next_token = $tokens[$i+1];
                if ($next_token->{name} eq 'Double' or $next_token->{name} eq 'VersionString') {
                    $explicit_version = max($explicit_version || 0, version->new($next_token->{data}));
                }
            }
        }
    }
    return $explicit_version;
}

sub _build_minimum_syntax_version {
    my ($self, $tokens) = @_;
    my @tokens = map { @$_ } @{$tokens};
    my $syntax_version = $MIN_VERSION;

    my $test = sub {
        my ($reason, $version) = @_;
        $syntax_version = max($syntax_version, $version);
        push @{$self->{version_markers}->{$version}}, $reason;
    };

    for my $i (0..@tokens-1) {
        my $token = $tokens[$i];
        if ($token->{name} eq 'ToDo') {
            # ... => 5.12
            $test->('yada-yada-yada operator(...)' => $VERSION_5_012);
        } elsif ($token->{name} eq 'Package') {
            if (@tokens > $i+2 && $tokens[$i+1]->name eq 'Class') {
                my $number = $tokens[$i+2];
                if ($number->{name} eq 'Int' || $number->{name} eq 'Double' || $number->{name} eq 'VersionString') {
                    # package NAME VERSION; => 5.012
                    $test->('package NAME VERSION' => $VERSION_5_012);

                    if (@tokens > $i+3 && $tokens[$i+3]->{name} eq 'LeftBrace') {
                        $test->('package NAME VERSION BLOCK' => $VERSION_5_014);
                    }
                } elsif ($tokens[$i+2]->{name} eq 'LeftBrace') {
                    $test->('package NAME BLOCK' => $VERSION_5_014);
                }
            }
        } elsif ($token->{name} eq 'UseDecl' || $token->{name} eq 'RequireDecl') {
            if (@tokens >= $i+1) {
                # use feature => 5.010
                my $next_token = $tokens[$i+1];
                if ($next_token->{data} eq 'feature') {
                    if (@tokens > $i+2) {
                        my $next_token = $tokens[$i+2];
                        if ($next_token->name eq 'String') {
                            my $arg = $next_token->data;
                            my $ver = do {
                                if ($arg eq 'fc' || $arg eq 'unicode_eval' || $arg eq 'current_sub') {
                                    $VERSION_5_016;
                                } elsif ($arg eq 'unicode_strings') {
                                    $VERSION_5_012;
                                } elsif ($arg eq 'experimental::lexical_subs') {
                                    $VERSION_5_018;
                                } elsif ($arg =~ /\A:5\.(.*)\z/) {
                                    version->new("v5.$1");
                                } else {
                                    $VERSION_5_010;
                                }
                            };
                            $test->('use feature' => $ver);
                        } else {
                            $test->('use feature' => $VERSION_5_010);
                        }
                    } else {
                        $test->('use feature' => $VERSION_5_010);
                    }
                } elsif ($next_token->{data} eq 'utf8') {
                    $test->('utf8 pragma included in 5.6. Broken until 5.8' => $VERSION_5_008);
                }
            }
        } elsif ($token->{name} eq 'DefaultOperator') {
            if ($token->{data} eq '//' && $i >= 1) {
                my $prev_token = $tokens[$i-1];
                unless (
                    ($prev_token->name eq 'BuiltinFunc' && $prev_token->data =~ m{\A(?:split|grep|map)\z})
                    || $prev_token->name eq 'LeftParenthesis') {
                    $test->('// operator' => $VERSION_5_010);
                }
            }
        } elsif ($token->{name} eq 'PolymorphicCompare') {
            if ($token->{data} eq '~~') {
                $test->('~~ operator' => $VERSION_5_010);
            }
        } elsif ($token->{name} eq 'DefaultEqual') {
            if ($token->{data} eq '//=') {
                $test->('//= operator' => $VERSION_5_010);
            }
        } elsif ($token->{name} eq 'GlobalHashVar') {
            if ($token->{data} eq '%-' || $token->{data} eq '%+') {
                $test->('%-/%+' => $VERSION_5_010);
            }
        } elsif ($token->{name} eq 'SpecificValue') {
            # $-{"a"}
            # $+{"a"}
            if ($token->{data} eq '$-' || $token->{data} eq '$+') {
                $test->('%-/%+' => $VERSION_5_010);
            }
        } elsif ($token->{name} eq 'GlobalArrayVar') {
            if ($token->{data} eq '@-' || $token->{data} eq '@+') {
                $test->('%-/%+' => $VERSION_5_010);
            }
        } elsif ($token->{name} eq 'WhenStmt') {
            if ($i >= 1 && (
                       $tokens[$i-1]->{name} ne 'SemiColon'
                    && $tokens[$i-1]->{name} ne 'RightBrace'
                    && $tokens[$i-1]->{name} ne 'LeftBrace'
                )) {
                $test->("postfix when" => $VERSION_5_012);
            } else {
                $test->("normal when" => $VERSION_5_010);
            }
        } elsif ($token->{name} eq 'BuiltinFunc') {
            if ($token->data eq 'each' || $token->data eq 'keys' || $token->data eq 'values') {
                my $func = $token->data;
                if (@tokens >= $i+1) {
                    my $next_token = $tokens[$i+1];
                    if ($next_token->name eq 'GlobalVar' || $next_token->name eq 'Var') {
                        # each $hashref
                        # each $arrayref
                        $test->("$func \$hashref, $func \$arrayref" => $VERSION_5_014);
                    } elsif ($next_token->name eq 'GlobalArrayVar' || $next_token->name eq 'ArrayVar') {
                        $test->("$func \@array" => $VERSION_5_012);
                    }
                }
            }
            if ($token->data eq 'push' || $token->data eq 'unshift' || $token->data eq 'pop' || $token->data eq 'shift' || $token->data eq 'splice') {
                my $func = $token->data;
                if (@tokens >= $i+1) {
                    my $offset = 1;
                    my $next_token;
                    do {
                      $next_token = $tokens[$i+$offset++];
                    } while $next_token->name eq 'LeftParenthesis';
                    if ($next_token->name eq 'GlobalVar' || $next_token->name eq 'Var') {
                        # shift $arrayref
                        # shift($arrayref, ...)
                        $test->("$func \$arrayref" => $VERSION_5_014);
                    }
                }
            }
            if ($token->data eq 'pack' || $token->data eq 'unpack') {
                if (@tokens >= $i+1 and my $next_token = $tokens[$i+1]) {
                    if ($next_token->{name} eq 'String' && $next_token->data =~ m/[<>]/) {
                        $test->($token->data." uses < or >" => $VERSION_5_010);
                    }
                }
            }
        } elsif ($token->{name} eq 'PostDeref' || $token->{name} eq 'PostDerefStar') {
			$test->("postfix dereference" => $VERSION_5_020);
        }
    }
    return $syntax_version;
}

sub minimum_version {
    my $self = shift;
    return defined $self->{minimum_explicit_version} && ($self->{minimum_explicit_version} > $self->{minimum_syntax_version})
        ? $self->{minimum_explicit_version}
        : $self->{minimum_syntax_version};
}

sub minimum_syntax_version {
    my $self = shift;
    return $self->{minimum_syntax_version};
}

sub minimum_explicit_version {
    my $self = shift;
    return $self->{minimum_explicit_version};
}

sub version_markers {
    my $self = shift;

    if ( my $explicit = $self->minimum_explicit_version ) {
        $self->{version_markers}->{$explicit} = [ 'explicit' ];
    }

    my @rv;

    foreach my $ver ( sort { version->new($a) <=> version->new($b) } keys %{$self->{version_markers}} ) {
        push @rv, version->new($ver) => $self->{version_markers}->{$ver};
    }

    return @rv;
}

1;
__END__

=encoding utf-8

=head1 NAME

Perl::MinimumVersion::Fast - Find a minimum required version of perl for Perl code

=head1 SYNOPSIS

    use Perl::MinimumVersion::Fast;

    my $p = Perl::MinimumVersion::Fast->new($filename);
    print $p->minimum_version, "\n";

=head1 DESCRIPTION

"Perl::MinimumVersion::Fast" takes Perl source code and calculates the minimum
version of perl required to be able to run it. Because it is based on goccy's L<Compiler::Lexer>,
it can do this without having to actually load the code.

Perl::MinimumVersion::Fast is an alternative fast & lightweight implementation of Perl::MinimumVersion.

=head1 METHODS

=over 4

=item C<< my $p = Perl::MinimumVersion::Fast->new($filename); >>

=item C<< my $p = Perl::MinimumVersion::Fast->new(\$src); >>

Create new instance. You can create object from C<< $filename >> and C<< \$src >> in string.

=item C<< $p->minimum_version(); >>

Get a minimum perl version the code required.

=item C<< $p->minimum_explicit_version() >>

The C<minimum_explicit_version> method checks through Perl code for the
use of explicit version dependencies such as.

  use 5.006;
  require 5.005_03;

Although there is almost always only one of these in a file, if more than
one are found, the highest version dependency will be returned.

Returns a L<version> object, C<undef> if no dependencies could be found.

=item C<< $p->minimum_syntax_version() >>

The C<minimum_syntax_version> method will explicitly test only the
Document's syntax to determine it's minimum version, to the extent
that this is possible.

Returns a L<version> object, C<undef> if no dependencies could be found.

=item  version_markers

This method returns a list of pairs in the form:

    ($version, \@markers)

Each pair represents all the markers that could be found indicating that the
version was the minimum needed version.  C<@markers> is an array of strings.
Currently, these strings are not as clear as they might be, but this may be
changed in the future.  In other words: don't rely on them as specific
identifiers.

=back

=head1 BENCHMARK

Perl::MinimumVersion::Fast is faster than Perl::MinimumVersion.
Because Perl::MinimumVersion::Fast uses L<Compiler::Lexer>, that is a Perl5 lexer implemented in C++.
And Perl::MinimumVersion::Fast omits some features implemented in Perl::MinimumVersion.

But, but, L<Perl::MinimumVersion::Fast> is really fast.

                                Rate Perl::MinimumVersion Perl::MinimumVersion::Fast
    Perl::MinimumVersion       5.26/s                   --                       -97%
    Perl::MinimumVersion::Fast  182/s                3365%                         --

=head1 LICENSE

Copyright (C) tokuhirom.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 THANKS TO

Most of documents are taken from L<Perl::MinimumVersion>.

=head1 AUTHOR

tokuhirom E<lt>tokuhirom@gmail.comE<gt>

=head1 SEE ALSO

This module using L<Compiler::Lexer> as a lexer for Perl5 code.

This module is inspired from L<Perl::MinimumVersion>.

=cut

