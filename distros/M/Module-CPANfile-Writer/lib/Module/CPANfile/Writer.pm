package Module::CPANfile::Writer;
use strict;
use warnings;
use Carp qw/croak/;

use Babble::Match;
use PPR;

our $VERSION = "0.01";

sub new {
    my ($class, $f) = @_;
    croak('Usage: Module::CPANfile::Writer->new($f)') unless defined $f;

    my $src;
    if (ref $f) {
        croak('Not a SCALAR reference') unless ref $f eq 'SCALAR';

        $src = $$f;
    } else {
        $src = do {
            open my $fh, '<', $f or die $!;
            local $/; <$fh>;
        };
    }

    return bless {
        src     => $src,
        prereqs => [],
    }, $class;
}

sub src {
    my $self = shift;

    my $top = Babble::Match->new(top_rule => 'Document', text => $self->{src});
    $top->each_match_within('Call' => [
        [ relationship => '(?:requires|recommends|suggests|conflicts)' ],
        '(?&PerlOWS) \(? (?&PerlOWS)',
        [ module => '(?: (?&PerlString) | (?&PerlBareword) )' ],
        [ arg1_before => '(?&PerlOWS) (?: (?>(?&PerlComma)) (?&PerlOWS) )*' ],
        [ arg1 => '(?&PerlAssignment)?' ],
        '(?&PerlOWS) (?: (?>(?&PerlComma)) (?&PerlOWS) )*',
        [ args => '(?&PerlCommaList)?' ],
        '\)? (?&PerlOWS)',
    ] => sub {
        my ($m) = @_;
        my $relationship = $m->submatches->{relationship}->text;
        my $module = _perl_string_or_bareword($m->submatches->{module}->text);

        my $prereq = _find_prereq($self->{add_prereqs}, $module, $relationship) or return;

        my $version = $prereq->{version};
        if ($m->submatches->{arg1}->text eq '' ||            # no arguments except module name
            _args_num($m->submatches->{args}->text) % 2 == 1 # not specify module version but there are options
        ) {
            # requires 'A';
            # requires 'B', dist => '...';
            if ($version) {
                $m->submatches->{module}->transform_text(sub { s/$/, '$version'/ });
            }
        } else {
            # requires 'C', '0.01';
            if ($version) {
                $m->submatches->{arg1}->replace_text(qq{'$version'});
            } else {
                $m->submatches->{arg1}->replace_text('');
                $m->submatches->{arg1_before}->replace_text('');
            }
        }
    });

    return $top->text;
}

sub save {
    my ($self, $file) = @_;
    croak('Usage: $self->save($file)') unless defined $file;

    open my $fh, '>', $file or die $!;
    print {$fh} $self->src;
}

sub add_prereq {
    my ($self, $module, $version, %opts) = @_;
    croak('Usage: $self->prereq($module, [$version, relationship => $relationship])') unless defined $module;

    my $relationship = $opts{relationship} || 'requires';

    push @{$self->{add_prereqs}}, {
        module       => $module,
        version      => $version,
        relationship => $relationship,
    };
}

sub _find_prereq {
    my ($prereqs, $module, $relationship) = @_;

    for my $prereq (@$prereqs) {
        if ($prereq->{module} eq $module && $prereq->{relationship} eq $relationship) {
            return $prereq;
        }
    }

    return undef;
}

sub _perl_string_or_bareword {
    my ($s) = @_;

    if ($s =~ /\A (?&PerlString) \Z $PPR::GRAMMAR/x) {
        return eval $s;
    }

    # bareword
    return $s;
}

sub _args_num {
    my ($s) = @_;

    # count number of arguments from PerlCommaList
    return scalar grep defined, $s =~ m{
        \G (?: (?>(?&PerlComma)) (?&PerlOWS) )* ((?&PerlAssignment))
            $PPR::GRAMMAR
    }gcx;
}

1;
__END__

=encoding utf-8

=head1 NAME

Module::CPANfile::Writer - Module for modifying the cpanfile

=head1 SYNOPSIS

    use Module::CPANfile::Writer;

    my $writer = Module::CPANfile::Writer->new('cpanfile');
    $writer->add_prereq('Moo', '2.003004');
    $writer->add_prereq('Test2::Suite', undef, relationship => 'recommends');
    $writer->save('cpanfile');

=head1 DESCRIPTION

Module::CPANfile::Writer lets you modify the version of modules in the existing cpanfile.

cpanfile is very flexible because it is written in Perl by using DSL, you can write comments and even code.
Therefore, modifying the cpanfile is not easy and you have to understand Perl code.

The idea of modifying the cpanfile was inspired by L<App::CpanfileSliptop>.
This module uses L<PPI> to parse and analyze the cpanfile as Perl code.
But PPI depends XS modules such as L<Clone> and L<Params::Util>, so these modules are annoying to fatpack in one pure-perl script.

Module::CPANfile::Writer has no XS modules in dependencies because it uses L<Babble> and L<PPR> to parse (recognize) Perl code.

=head1 METHODS

=over 4

=item $writer = Module::CPANfile::Writer->new($file)

=item $writer = Module::CPANfile::Writer->new(\$src)

This will create a new instance of L<Module::CPANfile::Writer>.

It takes the filename or the content of cpanfile as scalarref.

=item $writer->src

This will returns the content of modified cpanfile.

=item $writer->add_prereq($module, [$version, relationship => $relationship)

Modify the version of specified C<$module> in cpanfile.

You can also pass C<$version> to 0 or undef, this will remove the version requirement of C<$module>.

=item $writer->save($file);

Write the content of modified cpanfile to the C<$file>.

=back

=head1 SEE ALSO

L<Module::CPANfile>

=head1 LICENSE

Copyright (C) Takumi Akiyama.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Takumi Akiyama E<lt>t.akiym@gmail.comE<gt>

=cut

