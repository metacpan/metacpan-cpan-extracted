package Software::Policy::CodeOfConduct;

# ABSTRACT: generate a Code of Conduct policy

use v5.20;

use Moo;

use File::ShareDir qw( module_file );
use Text::Template;
use Text::Wrap    qw( wrap $columns );
use Types::Common qw( InstanceOf Maybe NonEmptyStr NonEmptySimpleStr PositiveInt );

use experimental qw( signatures );

use namespace::autoclean;

our $VERSION = 'v0.1.0';


has name => (
    is        => 'ro',
    isa       => Maybe [NonEmptySimpleStr],
    predicate => 1,
);


has contact => (
    is       => 'ro',
    required => 1,
    isa      => NonEmptySimpleStr,
);


has policy => (
    is      => 'ro',
    default => 'Contributor_Covenant_1.4',
);


has template_path => (
    is      => 'lazy',
    isa     => Maybe [NonEmptySimpleStr],
    builder => sub($self) {
        return module_file( __PACKAGE__, $self->policy . ".md.tmpl", );
    },
);

has _template => (
    is       => 'lazy',
    isa      => InstanceOf ['Text::Template'],
    init_arg => undef,
    builder  => sub($self) {
        return Text::Template->new(
            TYPE   => "FILE",
            SOURCE => $self->template_path,
        );
    }

);


has text_columns => (
    is      => 'ro',
    isa     => PositiveInt,
    default => 78,
);


has text => (
    is      => 'lazy',
    isa     => NonEmptyStr,
    builder => sub($self) {
        $columns = $self->text_columns;
        my $raw = $self->_template->fill_in(
            HASH => {
                contact => $self->contact,
            }
        );
        my @lines = map { wrap( "", $_ =~ /^[\*\-]/ ? "  " : "", $_ ) } split /\n/, ( $raw =~ s/[ ][ ]+/ /gr );
        return join( "\n", @lines );

    }
);

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Software::Policy::CodeOfConduct - generate a Code of Conduct policy

=head1 VERSION

version v0.1.0

=head1 SYNOPSIS

    my $policy = Software::Policy::CodeOfConduct->new(
        name    => 'Foo',
        contact => 'team-foo@example.com',
        policy  => 'Contributor_Covenant_1.4',
    );

    open my $fh, '>', "CODE-OF-CONDUCT.md" or die $!;
    print {$fh} $policy->text;
    close $fh;

=head1 DESCRIPTION

This distribution generates code of conduct policies from a template.

=head1 ATTRIBUTES

=head2 name

This is the (optional) name of the project that the code of conduct is for,

=head2 has_name

True if there is a name.

=head2 contact

The is the contact for the project team about the code of conduct. It should be an email address or a URL.

It is required.

=head2 policy

This is the policy filename. It defaults to F<Contributor_Covenant_1.4> which is based on
L<https://www.contributor-covenant.org/version/1/4/code-of-conduct.html>.

=head2 template_path

This is the path to the template file. If omitted, it will assume it is an included file from L</policy>.

This should be a L<Text::Template> file.

=head2 text_columns

This is the number of text columns for word-wrapping the L</text>.

The default is C<78>.

=head2 text

This is the text generated from the template.

=head1 SOURCE

The development version is on github at L<https://github.com/robrwo/perl-Software-Policy-CodeOfConduct>
and may be cloned from L<git://github.com/robrwo/perl-Software-Policy-CodeOfConduct.git>

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<https://github.com/robrwo/perl-Software-Policy-CodeOfConduct/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

Robert Rothenberg <rrwo@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2025 by Robert Rothenberg.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
