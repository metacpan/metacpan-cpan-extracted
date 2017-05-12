package Perl::PrereqScanner::Lite;
use 5.008005;
use strict;
use warnings;
use Carp ();
use Compiler::Lexer;
use CPAN::Meta::Requirements;
use Perl::PrereqScanner::Lite::Constants;

our $VERSION = "0.26";

sub new {
    my ($class, $opt) = @_;

    my $lexer;
    if ($opt->{no_prereq}) {
        $lexer = Compiler::Lexer->new({verbose => 1}),
    }
    else {
        $lexer = Compiler::Lexer->new(),
    }

    my $extra_scanners = [];
    if (my $scanner_names = $opt->{extra_scanners}) {
        if (ref $scanner_names eq 'ARRAY') {
            for my $scanner_name (@$scanner_names) {
                my $extra_scanner;
                if (substr($scanner_name, 0, 1) eq '+') {
                    $extra_scanner = substr $scanner_name, 1;
                }
                else {
                    $extra_scanner = "Perl::PrereqScanner::Lite::Scanner::$scanner_name";
                }

                eval "require $extra_scanner"; ## no critic
                push @$extra_scanners, $extra_scanner;
            }
        } else {
            Carp::croak "'extra_scanners' option must be array reference";
        }
    }

    bless {
        lexer          => $lexer,
        extra_scanners => $extra_scanners,
        module_reqs    => CPAN::Meta::Requirements->new,
    }, $class;
}

sub add_extra_scanner {
    my ($self, $scanner_name) = @_;

    my $extra_scanner;
    if (substr($scanner_name, 0, 1) eq '+') {
        $extra_scanner = substr $scanner_name, 1;
    }
    else {
        $extra_scanner = "Perl::PrereqScanner::Lite::Scanner::$scanner_name";
    }

    eval "require $extra_scanner"; ## no critic
    push @{$self->{extra_scanners}}, $extra_scanner;
}

sub scan_string {
    my ($self, $string) = @_;

    my $tokens = $self->{lexer}->tokenize($string);
    $self->_scan($tokens);
}

sub scan_file {
    my ($self, $file) = @_;

    open my $fh, '<', $file or die "Cannot open file: $file";
    my $script = do { local $/; <$fh>; };

    $self->scan_string($script);
}

sub scan_tokens {
    my ($self, $tokens) = @_;
    $self->_scan($tokens);
}

sub scan_module {
    my ($self, $module) = @_;

    require Module::Path;

    if (defined(my $path = Module::Path::module_path($module))) {
        return $self->scan_file($path);
    }
}

sub _scan {
    my ($self, $tokens) = @_;

    my $module_name    = '';
    my $module_version = 0;

    my $not_decl_module_name = '';

    my $is_in_reglist   = 0;
    my $is_in_usedecl   = 0;
    my $is_in_reqdecl   = 0;
    my $is_inherited    = 0;
    my $is_in_list      = 0;
    my $is_version_decl = 0;
    my $is_aliased      = 0;
    my $is_prev_version = 0;
    my $is_prev_module_name = 0;

    my $does_garbage_exist = 0;
    my $does_use_lib_or_constant = 0;

    my $latest_prereq = '';

    TOP:
    for (my $i = 0; my $token = $tokens->[$i]; $i++) {
        my $token_type = $token->{type};

        # For require statement
        if ($token_type == REQUIRE_DECL || ($token_type == BUILTIN_FUNC && $token->{data} eq 'no')) {
            $is_in_reqdecl = 1;
            next;
        }
        if ($is_in_reqdecl) {
            # e.g.
            #   require Foo;
            if ($token_type == REQUIRED_NAME || $token_type == KEY) {
                $latest_prereq = $self->add_minimum($token->{data} => 0);

                $is_in_reqdecl = 0;
                next;
            }

            # e.g.
            #   require Foo::Bar;
            if ($token_type == NAMESPACE || $token_type == NAMESPACE_RESOLVER) {
                $module_name .= $token->{data};
                next;
            }

            # End of declare of require statement
            if ($token_type == SEMI_COLON) {
                if ($module_name) {
                    $latest_prereq = $self->add_minimum($module_name => 0);
                }

                $module_name   = '';
                $is_in_reqdecl = 0;
                next;
            }

            next;
        }

        # For use statement
        if ($token_type == USE_DECL) {
            $is_in_usedecl = 1;
            next;
        }
        if ($is_in_usedecl) {
            # e.g.
            #   use Foo;
            #   use parent qw/Foo/;
            #
            if ($token_type == USED_NAME || $token_type == IF_STMT) {
                # XXX                       ~~~~~~~~~~~~~~~~~~~~~~
                # Workaround for `use if` statement
                # It is a matter of Compiler::Lexer (maybe).
                #
                #   use if $] < 5.009_005, 'MRO::Compat';

                $module_name = $token->{data};

                if ($module_name eq 'lib' || $module_name eq 'constant') {
                    $latest_prereq = $self->add_minimum($module_name, 0);
                    $does_use_lib_or_constant = 1;
                }
                elsif ($module_name =~ /(?:base|parent)/) {
                    $is_inherited = 1;
                }
                elsif ($module_name =~ 'aliased') {
                    $is_aliased = 1;
                }

                $is_prev_module_name = 1;
                next;
            }

            # End of declare of use statement
            if ($token_type == SEMI_COLON || $token_type == LEFT_BRACE || $token_type == LEFT_BRACKET) {
                if ($module_name && !$does_use_lib_or_constant) {
                    $latest_prereq = $self->add_minimum($module_name => $module_version);
                }

                $module_name    = '';
                $module_version = 0;
                $is_in_reglist  = 0;
                $is_inherited   = 0;
                $is_in_list     = 0;
                $is_in_usedecl  = 0;
                $is_aliased     = 0;
                $does_garbage_exist  = 0;
                $is_prev_module_name = 0;
                $does_use_lib_or_constant = 0;

                next;
            }

            # e.g.
            #   use Foo::Bar;
            if ($token_type == NAMESPACE || $token_type == NAMESPACE_RESOLVER) {
                $module_name .= $token->{data};
                $is_prev_module_name = 1;
                next;
            }

            # Section for parent/base
            if ($is_inherited) {
                # For qw() notation
                # e.g.
                #   use parent qw/Foo Bar/;
                if ($token_type == REG_LIST) {
                    $is_in_reglist = 1;
                }
                elsif ($is_in_reglist) {
                    if ($token_type == REG_EXP) {
                        for my $_module_name (split /\s+/, $token->{data}) {
                            $latest_prereq = $self->add_minimum($_module_name => 0);
                        }
                        $is_in_reglist = 0;
                    }
                }

                # For simply list
                # e.g.
                #   use parent ('Foo' 'Bar');
                elsif ($token_type == LEFT_PAREN) {
                    $is_in_list = 1;
                }
                elsif ($token_type == RIGHT_PAREN) {
                    $is_in_list = 0;
                }
                elsif ($is_in_list) {
                    if ($token_type == STRING || $token_type == RAW_STRING) {
                        $latest_prereq = $self->add_minimum($token->{data} => 0);
                    }
                }

                # For string
                # e.g.
                #   use parent "Foo"
                elsif ($token_type == STRING || $token_type == RAW_STRING) {
                    $latest_prereq = $self->add_minimum($token->{data} => 0);
                }

                $is_prev_module_name = 0;
                next;
            }

            if ($token_type == DOUBLE || $token_type == INT || $token_type == VERSION_STRING) {
                if (!$module_name) {
                    if (!$does_garbage_exist) {
                        # For perl version
                        # e.g.
                        #   use 5.012;
                        my $perl_version = $token->{data};
                        $latest_prereq = $self->add_minimum('perl' => $perl_version);
                        $is_in_usedecl = 0;
                    }
                }
                elsif($is_prev_module_name) {
                    # For module version
                    # e.g.
                    #   use Foo::Bar 0.0.1;'
                    #   use Foo::Bar v0.0.1;
                    #   use Foo::Bar 0.0_1;
                    $module_version = $token->{data};
                }

                $is_prev_module_name = 0;
                $is_prev_version = 1;
                next;
            }

            if ($is_aliased) {
                if ($token_type == STRING || $token_type == RAW_STRING) {
                    $latest_prereq = $self->add_minimum($token->{data} => 0);
                    $is_aliased = 0;
                }
                next;
            }

            if (($is_prev_module_name || $is_prev_version) && $token_type == LEFT_PAREN) {
                my $left_paren_num = 1;
                for ($i++; $token = $tokens->[$i]; $i++) { # skip content that is surrounded by parens
                    $token_type = $token->{type};

                    if ($token_type == LEFT_PAREN) {
                        $left_paren_num++;
                    }
                    elsif ($token_type == RIGHT_PAREN) {
                        last if --$left_paren_num <= 0;
                    }
                }
                next;
            }

            if ($token_type != WHITESPACE) {
                $does_garbage_exist  = 1;
                $is_prev_module_name = 0;
                $is_prev_version = 0;
            }
            next;
        }

        for my $extra_scanner (@{$self->{extra_scanners}}) {
            if ($extra_scanner->scan($self, $token, $token_type)) {
                next TOP;
            }
        }

        if ($token_type == COMMENT && $token->{data} =~ /\A##\s*no prereq\Z/) {
            $self->{module_reqs}->clear_requirement($latest_prereq);
            next;
        }
    }

    return $self->{module_reqs};
}

sub add_minimum {
    my ($self, $module_name, $module_version) = @_;

    if ($module_name) {
        $self->{module_reqs}->add_minimum($module_name => $module_version);
    }

    return $module_name;
}

1;
__END__

=encoding utf-8

=for stopwords prepend reimplement

=head1 NAME

Perl::PrereqScanner::Lite - Lightweight Prereqs Scanner for Perl

=head1 SYNOPSIS

    use Perl::PrereqScanner::Lite;

    my $scanner = Perl::PrereqScanner::Lite->new;
    $scanner->add_extra_scanner('Moose'); # add extra scanner for moose style
    my $modules = $scanner->scan_file('path/to/file');

=head1 DESCRIPTION

Perl::PrereqScanner::Lite is the lightweight prereqs scanner for perl.
This scanner uses L<Compiler::Lexer> as tokenizer, therefore processing speed is really fast.

=head1 METHODS

=head2 new($opt)

Create a scanner instance.

C<$opt> must be hash reference. It accepts following keys of hash:

=over 4

=item * extra_scanners

It specifies extra scanners. This item must be array reference.

e.g.

    my $scanner = Perl::PrereqScanner::Lite->new(
        extra_scanners => [qw/Moose Version/]
    );

See also L</add_extra_scanner($scanner_name)>.

=item * no_prereq

It specifies to use C<## no prereq> or not. Please see also L</ADDITIONAL NOTATION>.

=back

=head2 scan_file($file_path)

Scan and figure out prereqs which is instance of C<CPAN::Meta::Requirements> by file path.

=head2 scan_string($string)

Scan and figure out prereqs which is instance of C<CPAN::Meta::Requirements> by source code string written in perl.

e.g.

    open my $fh, '<', __FILE__;
    my $string = do { local $/; <$fh> };
    my $modules = $scanner->scan_string($string);

=head2 scan_module($module_name)

Scan and figure out prereqs which is instance of C<CPAN::Meta::Requirements> by module name.

e.g.

    my $modules = $scanner->scan_module('Perl::PrereqScanner::Lite');

=head2 scan_tokens($tokens)

Scan and figure out prereqs which is instance of C<CPAN::Meta::Requirements> by tokens of L<Compiler::Lexer>.

e.g.

    open my $fh, '<', __FILE__;
    my $string = do { local $/; <$fh> };
    my $tokens = Compiler::Lexer->new->tokenize($string);
    my $modules = $scanner->scan_tokens($tokens);

=head2 add_extra_scanner($scanner_name)

Add extra scanner to scan and figure out prereqs. This module loads extra scanner such as C<Perl::PrereqScanner::Lite::Scanner::$scanner_name> if specifying scanner name through this method.

If you want to specify an extra scanner from external package without C<Perl::PrereqScanner::Lite::> prefix, you can prepend C<+> to C<$scanner_name>. Like so C<+Your::Awesome::Scanner>.

Extra scanners that are default supported are followings;

=over 8

=item * L<Perl::PrereqScanner::Lite::Scanner::Moose>

=item * L<Perl::PrereqScanner::Lite::Scanner::Version>

=back

=head1 ADDITIONAL NOTATION

If C<no_prereq> is enabled by C<new()> (like so: C<Perl::PrereqScanner::Lite-E<gt>new({no_prereq =E<gt> 1})>),
this module recognize C<## no prereq> optional comment. The requiring declaration with this comment on the same line will be ignored as prereq.

For example

    use Foo;
    use Bar; ## no prereq

In this case C<Foo> is the prereq, however C<Bar> is ignored.

=head1 SPEED COMPARISON

=head2 Plain

                                Rate   Perl::PrereqScanner Perl::PrereqScanner::Lite
    Perl::PrereqScanner       8.57/s                    --                      -97%
    Perl::PrereqScanner::Lite  246/s                 2770%                        --

=head2 With Moose scanner

                                Rate   Perl::PrereqScanner Perl::PrereqScanner::Lite
    Perl::PrereqScanner       9.00/s                    --                      -94%
    Perl::PrereqScanner::Lite  152/s                 1587%                        --

=head1 NOTES

This is a quotation from L<https://github.com/moznion/Perl-PrereqScanner-Lite/issues/13>.

=begin text

The interface of an this module object suggests every scan_* call is not affected by any other, yet the code is storing the requirements in that object. This is quite surprising.

I'd suggest that either it must change to be more functional-style, or this behavior should be clearly documented.

=end text

Yes, it's true. This design is so ugly and not smart.
So I have to redesign and reimplement this module, and I have some plans.

If you have a mind to expand this module by implementing external scanner,
please be careful.
Every C<scan_*> calls must not affect to any others through the
singleton of this module (called it C<$c> in L<https://github.com/moznion/Perl-PrereqScanner-Lite/blob/c03638b2e2a39d92f4d7df360af5a6be65dc417a/lib/Perl/PrereqScanner/Lite/Scanner/Moose.pm#L8>).

=head1 SEE ALSO

L<Perl::PrereqScanner>, L<Compiler::Lexer>

=head1 LICENSE

Copyright (C) moznion.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

moznion E<lt>moznion@gmail.comE<gt>

=cut

