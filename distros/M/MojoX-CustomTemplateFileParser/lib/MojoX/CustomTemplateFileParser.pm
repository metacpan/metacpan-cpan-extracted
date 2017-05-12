package MojoX::CustomTemplateFileParser;

use strict;
use warnings;
use 5.10.1;
our $VERSION = '0.1002'; # VERSION
# ABSTRACT: Parses a custom Mojo template file format (deprecated)

use Moose;
with 'MooseX::Object::Pluggable';

use HTML::Entities;
use Path::Tiny();
use Storable qw/dclone/;

has path => (
    is => 'ro',
    isa => 'Str',
    required => 1,
);
has structure => (
    is => 'rw',
    isa => 'HashRef',
    default => sub { { } },
);
has test_index => (
    is => 'rw',
    isa => 'HashRef',
    default => sub { { } },
);
has output => (
    is => 'ro',
    isa => 'ArrayRef',
    default => sub { [ ] },
);

sub BUILD {
    my $self = shift;
    $self->_parse;

    foreach my $plugin (@{ $self->output } ) {
        $self->load_plugin("To::$plugin");
    }
}

sub _parse {
    my $self = shift;
    my $baseurl = $self->_get_baseurl;
    my @lines = split /\n/ => Path::Tiny::path($self->path)->slurp;

    # matches ==test== ==no test== ==test loop(a thing or two)== ==test example ==test 1== ==test example 2==
    my $test_start = qr/==(?:(NO) )?TEST(?: loop\(([^)]+)\))?( EXAMPLE)?(?: (?:\d+))?==/i;
    my $template_separator = '--t--';
    my $expected_separator = '--e--';

    my $environment = 'head';

    my $info = {
        head_lines => [],
        tests      => [],
        indexed    => {},
    };
    my $test = {};

    my $row = 0;
    my $testcount = 0;

    LINE:
    foreach my $line (@lines) {
        ++$row;

        if($environment eq 'head') {
            if($line =~ $test_start) {

                my $skipit = $1;
                $test->{'loop'} = defined $2 ? [ split / / => $2 ] : [];
                $test = $self->_reset_test();

                if(defined $skipit && $skipit eq lc 'no') {
                    $test->{'skip'} = $skipit;
                }

                push @{ $info->{'head_lines'} } => '';
                $test->{'test_number'} = ++$testcount;
                $test->{'is_example'} = defined $3 ? 1 : 0;;
                $test->{'test_start_line'} = $row;
                $test->{'test_number'} = $testcount;
                $test->{'test_name'} = sprintf '%s_%s' => $baseurl, $testcount;
                $environment = 'beginning';

                next LINE;
            }
            push @{ $info->{'head_lines'} } => $line;
            next LINE;
        }
        if($environment eq 'beginning') {
            if($line eq $template_separator) {
                $environment = 'template';
                next LINE;
            }
            push @{ $test->{'lines_before'} } => $line;
            next LINE;
        }
        if($environment eq 'template') {
            if($line eq $template_separator) {
                if(scalar @{ $test->{'lines_template'} }) {
                    unshift @{ $test->{'lines_template'} } => '';
                    push @{ $test->{'lines_template'} } => '';
                }
                $environment = 'between';
                next LINE;
            }
            # If we have no template lines, don't push empty lines.
            # This way we can avoid empty templates, meaning we can leave empty test blocks in the
            # source files without messing up the tests.
            push @{ $test->{'lines_template'} } => $line if scalar @{ $test->{'lines_template'} } || $line !~ m{^\s*$};
            next LINE;
        }
        if($environment eq 'between') {
            if($line eq $expected_separator) {
                $environment = 'expected';
                next LINE;
            }
            push @{ $test->{'lines_between'} } => $line;
            next LINE;
        }
        if($environment eq 'expected') {
            if($line eq $expected_separator) {
                $environment = 'ending';
                if(scalar @{ $test->{'lines_expected'} }) {
                    unshift @{ $test->{'lines_expected'} } => '';
                    push @{ $test->{'lines_expected'} } => '';
                }
                next LINE;
            }
            push @{ $test->{'lines_expected'} } => $line;
            next LINE;
        }
        if($environment eq 'ending') {
            if($line =~ $test_start) {
                $self->_add_test($info, $test);

                $test = $self->_reset_test();
                my $skipit = $1;
                if(defined $skipit && $skipit eq lc 'no') {
                    $test->{'skip'} = 1;
                }
                $test->{'loop'} = defined $2 ? [ split / / => $2 ] : [];
                $test->{'test_start_line'} = $row;
                $test->{'test_number'} = ++$testcount;;
                $test->{'is_example'} = $3 || 0;
                $test->{'test_name'} = sprintf '%s_%s' => $baseurl, $testcount;
                $environment = 'beginning';

                next LINE;
            }
            push @{ $test->{'lines_after'} } => $line if scalar @{ $test->{'lines_after'} } || $line !~ m{^\s*$};
            next LINE;
        }
    }

    $self->_add_test($info, $test);

    $self->test_index(delete $info->{'indexed'});
    $self->structure($info);

    return $self;
}

sub test_count {
    my $self = shift;
    return keys %{ $self->{'test_index'} };
}

sub _add_test {
    my $self = shift;
    my $info = shift;
    my $test = shift;

    #* Nothing to test
    return if !scalar @{ $test->{'lines_template'} } || $test->{'skip'};

    #* No loop, just add it
    if(!scalar @{ $test->{'loop'} }) {
        push @{ $info->{'tests'} } => $test;
        $info->{'indexed'}{ $test->{'test_number'} } = [ $test ];
        return;
    }
    $info->{'indexed'}{ $test->{'test_number'} } = [ ];

    foreach my $var (@{ $test->{'loop'} }) {
        my $copy = dclone $test;

        map { $_ =~ s{\[var\]}{$var}g } @{ $copy->{'lines_template'} };
        map { $_ =~ s{\[var\]}{$var}g } @{ $copy->{'lines_expected'} };
        $copy->{'loop_variable'} = $var;
        $copy->{'test_name'} .= "_$var";
        push @{ $info->{'tests'} } => $copy;
        push @{ $info->{'indexed'}{ $copy->{'test_number'} } } => $copy;
    }
    return;

}

sub _reset_test {
    my $self = shift;
    return {
        is_example => 0,
        lines_before => [],
        lines_template => [],
        lines_after => [],
        lines_between => [],
        lines_expected => [],
        test_number => undef,
        test_start_line => undef,
        test_name => undef,
        loop => [],
        loop_variable => undef,
    };
}

sub _get_filename {
    return Path::Tiny::path(shift->path)->basename;
}

sub _get_baseurl {
    my $self = shift;
    my $filename = $self->_get_filename;
    (my $baseurl = $filename) =~ s{^([^\.]+)\..*}{$1}; # remove suffix
    $baseurl =~ s{-}{_};
    return $baseurl;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MojoX::CustomTemplateFileParser - Parses a custom Mojo template file format (deprecated)



=begin HTML

<p><img src="https://img.shields.io/badge/perl-5.14+-brightgreen.svg" alt="Requires Perl 5.14+" /> <a href="https://travis-ci.org/Csson/p5-mojox-customtemplatefileparser"><img src="https://api.travis-ci.org/Csson/p5-mojox-customtemplatefileparser.svg?branch=master" alt="Travis status" /></a></p>

=end HTML


=begin markdown

![Requires Perl 5.14+](https://img.shields.io/badge/perl-5.14+-brightgreen.svg) [![Travis status](https://api.travis-ci.org/Csson/p5-mojox-customtemplatefileparser.svg?branch=master)](https://travis-ci.org/Csson/p5-mojox-customtemplatefileparser)

=end markdown

=head1 VERSION

Version 0.1002, released 2015-11-26.

=head1 SYNOPSIS

  use MojoX::CustomTemplateFileParser;

  my $parser = MojoX::CustomTemplateFileParser->new(path => '/path/to/file.mojo', output => [qw/Html Pod Test]);

  print $parser->to_html;
  print $parser->to_pod;
  print $parser->to_test;

=head1 STATUS

Deprecated. Replaced by L<Stenciller>.

=head1 DESCRIPTION

MojoX::CustomTemplateFileParser parses files containing L<Mojo::Templates|Mojo::Template> mixed with the expected rendering.

The parsing creates a data structure that can be output in various formats using plugins.

Its purpose is to facilitate development of tag helpers.

=head2 Options

B<C<path>>

The path to the file that should be parsed. Parsing occurs at object creation.

B<C<output>>

An array reference to plugins in the C<::Plugin::To> namespace.

=head2 Methods

No public methods. See plugins for output options.

=head1 PLUGINS

Currently available plugins:

=over 4

=item *

L<MojoX::CustomTemplateFileParser::To::Html>

=item *

L<MojoX::CustomTemplateFileParser::To::Pod>

=item *

L<MojoX::CustomTemplateFileParser::To::Test>

=back

=head1 SEE ALSO

=over 4

=item *

L<Dist::Zilla::Plugin::Test::CreateFromMojoTemplates>

=item *

L<Dist::Zilla::Plugin::InsertExample::FromMojoTemplates>

=back

=head1 SOURCE

L<https://github.com/Csson/p5-mojox-customtemplatefileparser>

=head1 HOMEPAGE

L<https://metacpan.org/release/MojoX-CustomTemplateFileParser>

=head1 AUTHOR

Erik Carlsson <info@code301.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Erik Carlsson.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
