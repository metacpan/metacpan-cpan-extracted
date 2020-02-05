package Perinci::Sub::To::FuncBase;

our $DATE = '2020-01-31'; # DATE
our $VERSION = '0.870'; # VERSION

use 5.010;
use Log::ger;
use Moo;

use Data::Dump::OneLine qw(dump1);
use Data::Sah::Terse qw(terse_schema);
use Perinci::Object;
use Perinci::Sub::Normalize qw(normalize_function_metadata);

with 'Perinci::To::Doc::Role::Section';

has meta => (is=>'rw');
has name => (is=>'rw');
has url  => (is=>'rw');
has _pa => (is=>'rw');
has parent => (is=>'rw'); # points fo Perinci::To::* object
has export => (is=>'rw', default=>undef); # undef=unknown, 0=not exported by default but exportable, 1=exported by default, -1=never export

sub BUILD {
    my ($self, $args) = @_;

    $args->{meta} or die "Please specify meta";

    my $parent = $self->{parent};
    my $pdres  = $self->{parent}{_doc_res};

    if ($pdres &&
            @{ $pdres->{function_names_by_meta_addr}{"$args->{meta}"} } > 1) {
        # function is an alias to another function, no need to duplicate
        # documenting the function, just mention that this function is alias to
        # another.
        $self->{doc_sections} //= [
            # actually not needed but gen_doc_section_summary() et al currently
            # sets dres->{name}, dres->{summary}, etc. this will be refactored
            # later, gen_doc_section_summary() et al should've just add doc
            # lines.
            'summary',
            'arguments',
            'result',

            'alias',
        ];
    }

    $self->{doc_sections} //= [
        'summary',
        'synopsis',
        'description',
        'arguments',
        'result',
        'links',
    ];
    $self->{_pa} = do {
        require Perinci::Access;
        Perinci::Access->new;
    };
}

sub before_gen_doc {
    my ($self, %opts) = @_;
    log_trace("=> FuncBase's before_gen_doc(opts=%s)", \%opts);

    $self->{_orig_meta} = $self->{meta};
    $self->{meta} = normalize_function_metadata($self->{meta});

    # initialize hash to store [intermediate] result
    $self->{_doc_res} = {};
}

# provide simple default implementation without any text wrapping. subclass such
# as Perinci::Sub::To::Text will use another implementation, one that supports
# text wrapping for example (provided by
# Perinci::To::Doc::Role::Section::AddTextLines).
sub add_doc_lines {
    my $self = shift;
    my $opts;
    if (ref($_[0]) eq 'HASH') { $opts = shift }
    $opts //= {};

    my @lines = map { $_ . (/\n\z/s ? "" : "\n") }
        map {/\n/ ? split /\n/ : $_} @_;

    my $indent = $self->doc_indent_str x $self->doc_indent_level;
    push @{$self->doc_lines},
        map {"$indent$_"} @lines;
}

sub gen_doc_section_alias {
    # currently in after_gen_doc()
}

sub gen_doc_section_summary {
    my ($self) = @_;

    my $rimeta = rimeta($self->meta);
    my $dres   = $self->{_doc_res};

    my $name = $self->name // $rimeta->langprop("name") //
        "unnamed_function";
    my $summary = $rimeta->langprop("summary");

    $dres->{name}    = $name;
    $dres->{summary} = $summary;
}

sub gen_doc_section_synopsis {
    # currently in after_gen_doc()
}

sub gen_doc_section_description {
    my ($self) = @_;

    my $rimeta = rimeta($self->meta);
    my $dres   = $self->{_doc_res};

    # XXX proper alt. search
    $dres->{description} = $self->{meta}{'description.alt.env.perl'} //
        $rimeta->langprop("description");
}

sub gen_doc_section_arguments {
    my ($self) = @_;

    my $meta   = $self->meta;
    my $rimeta = rimeta($meta);
    my $dres   = $self->{_doc_res};
    my $args_p = $meta->{args} // {};

    # perl term for args, whether '$arg1, $arg2, ...', or '%args', etc
    my $aa = $meta->{_orig_args_as} // 'hash';
    my $aplt;
    if (!keys(%$args_p)) {
        $aplt = '()';
    } elsif ($aa eq 'hash') {
        $aplt = '(%args)';
    } elsif ($aa eq 'hashref') {
        $aplt = '(\%args)';
    } elsif ($aa =~ /\Aarray(ref)?\z/) {
        $aplt = join(
            '',
            '(',
            ($aa eq 'arrayref' ? '[' : ''),
            join(', ',
                 map {
                     my $var = $_; $var =~ s/[^A-Za-z0-9_]+/_/g;
                     "\$$var" . (($args_p->{$_}{slurpy} // $args_p->{$_}{greedy}) ? ', ...' : '');
                 }
                     sort {
                         ($args_p->{$a}{pos} // 9999) <=>
                             ($args_p->{$b}{pos} // 9999)
                         } keys %$args_p),
            ($aa eq 'arrayref' ? ']' : ''),
            ')'
        );
    } else {
        die "BUG: Unknown value of args_as '$aa'";
    }
    $dres->{args_plterm} = $aplt;

    my $args  = $meta->{args} // {};
    $dres->{args} = {};
    my $raa = $dres->{args};
    for my $name (keys %$args) {
        my $arg = $args->{$name};
        my $riargmeta = rimeta($arg);
        $arg->{default_lang} //= $meta->{default_lang};
        $arg->{schema} //= ['any'=>{}];
        my $s = $arg->{schema};
        my $ra = $raa->{$name} = {schema=>$s};
        $ra->{human_arg} = terse_schema($s);
        if (exists $arg->{default}) {
            $ra->{human_arg_default} = dump1($arg->{default});
        } elsif (defined $s->[1]{default}) {
            $ra->{human_arg_default} = dump1($s->[1]{default});
        }
        $ra->{summary}     = $riargmeta->langprop('summary');
        $ra->{description} = $riargmeta->langprop('description');
        $ra->{arg}         = $arg;

        $raa->{$name} = $ra;
    }
}

sub gen_doc_section_result {
    my ($self) = @_;

    my $meta      = $self->meta;
    my $riresmeta = rimeta($meta->{result});
    my $dres      = $self->{_doc_res};

    my $orig_result_naked = $meta->{_orig_result_naked} // $meta->{result_naked};

    $dres->{res_schema} = $meta->{result} ? $meta->{result}{schema} : undef;
    $dres->{res_schema} //= [any => {}];
    $dres->{human_res} = terse_schema($dres->{res_schema});

    if ($orig_result_naked) {
        $dres->{human_ret} = $dres->{human_res};
    } else {
        $dres->{human_ret} = '[status, msg, payload, meta]';
    }

    $dres->{res_summary}     = $riresmeta->langprop("summary");
    $dres->{res_description} = $riresmeta->langprop("description");
}

sub gen_doc_section_links {
    # not yet
}

1;
# ABSTRACT: Base class for Perinci::Sub::To::* function documentation generators

__END__

=pod

=encoding UTF-8

=head1 NAME

Perinci::Sub::To::FuncBase - Base class for Perinci::Sub::To::* function documentation generators

=head1 VERSION

This document describes version 0.870 of Perinci::Sub::To::FuncBase (from Perl distribution Perinci-To-Doc), released on 2020-01-31.

=for Pod::Coverage .+

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Perinci-To-Doc>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Perinci-To-Doc>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Perinci-To-Doc>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020, 2019, 2018, 2017, 2016, 2015, 2014, 2013 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
