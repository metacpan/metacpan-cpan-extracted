use strictures 1;

# ABSTRACT: Turns a quoted string into a single line

package Syntax::Feature::Ql;
{
  $Syntax::Feature::Ql::VERSION = '0.001000';
}
BEGIN {
  $Syntax::Feature::Ql::AUTHORITY = 'cpan:PHAYLON';
}
use Devel::Declare          0.006007    ();
use B::Hooks::EndOfScope    0.09;
use Sub::Install            0.925       qw( install_sub );

use aliased 'Devel::Declare::Context::Simple', 'Context';

use syntax qw( simple/v2 );
use namespace::clean;

my @NewOps  = qw( ql qql );
my %QuoteOp = (ql => 'q', qql => 'qq');

method install ($class: %args) {
    my $target = $args{into};
    Devel::Declare->setup_for($target => {
        map {
            my $name = $_;
            ($name => {
                const => sub {
                    my $ctx = Context->new;
                    $ctx->init(@_);
                    return $class->_transform($name, $ctx);
                },
            });
        } @NewOps,
    });
    for my $name (@NewOps) {
        install_sub {
            into => $target,
            as   => $name,
            code => $class->_run_callback,
        };
    }
    on_scope_end {
        namespace::clean->clean_subroutines($target, @NewOps);
    };
    return 1;
}

method _run_callback {
    return sub ($) {
        my $string = shift;
        $string =~ s{(?:^\s+|\s+$)}{}gsm;
        return join ' ', split m{\s*\n\s*}, $string;
    };
}

method _transform ($class: $name, $ctx) {
    $ctx->skip_declarator;
    my $length = Devel::Declare::toke_scan_str($ctx->offset);
    my $string = Devel::Declare::get_lex_stuff;
    Devel::Declare::clear_lex_stuff;
    my $linestr = $ctx->get_linestr;
    my $quoted = substr $linestr, $ctx->offset, $length;
    my $spaced = '';
    $quoted =~ m{^(\s*)}sm;
    $spaced = $1;
    my $new = sprintf '(%s)', join '',
        $QuoteOp{$name},
        $spaced,
        substr($quoted, length($spaced), 1),
        $string,
        substr($quoted, -1, 1);
    substr($linestr, $ctx->offset, $length) = $new;
    $ctx->set_linestr($linestr);
    return 1;
}

1;


__END__
=pod

=encoding utf-8

=head1 NAME

Syntax::Feature::Ql - Turns a quoted string into a single line

=head1 VERSION

version 0.001000

=head1 SYNOPSIS

    use syntax qw( ql );

    # prints on one line
    say ql{
        Do you know the feeling when you want to generate a long
        string for a message without having to concatenate or end
        up with newlines and indentation?
    };

=head1 DESCRIPTION

This is a syntax extension feature suitable for the L<syntax> extension
dispatcher.

It provides two new quote-like operators named C<ql> and C<qql>. These
work in the same way as C<q> and C<qq> (including the ability to change
the delimiters), except they put the returned string on a single line.

The following all output C<foo bar baz>:

    # simple
    say ql{foo bar baz};

    # multiline
    say ql{
        foo
        bar
        baz
    };

    # different delimiters and interpolation
    my $qux = q{ # <- this is a normal quote!
        bar
        baz
    };
    say qql!
        foo
        $qux
    !;

As you can see with the last example, interpolated values are also
normalized to fit on the single line.

=head1 METHODS

=head2 install

    Syntax::Feature::Ql->install( into => $target );

Installs the C<ql> and C<qql> operators into the C<$target>.

=head1 SEE ALSO

=over

=item * L<syntax>

=item * L<perlop>

=back

=head1 BUGS

Please report any bugs or feature requests to bug-syntax-feature-ql@rt.cpan.org or through the web interface at:
 http://rt.cpan.org/Public/Dist/Display.html?Name=Syntax-Feature-Ql

=head1 AUTHOR

Robert 'phaylon' Sedlacek <rs@474.at>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Robert 'phaylon' Sedlacek.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

