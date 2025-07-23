package Software::Policy::CodeOfConduct;

# ABSTRACT: generate a Code of Conduct policy

use v5.20;

use Moo;

use File::ShareDir qw( dist_file );
use Path::Tiny 0.018 qw( cwd path );
use Text::Template 1.48;
use Text::Wrap    qw( wrap $columns );
use Types::Common qw( InstanceOf Maybe NonEmptyStr NonEmptySimpleStr PositiveInt );

use experimental qw( lexical_subs signatures );

use namespace::autoclean;

our $VERSION = 'v0.3.0';


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


has entity => (
    is      => 'ro',
    isa     => NonEmptySimpleStr,
    default => 'project',
);


has Entity => (
    is      => 'lazy',
    isa     => NonEmptySimpleStr,
    builder => sub($self) {
        return ucfirst( $self->entity );
    },
);


has policy => (
    is      => 'ro',
    default => 'Contributor_Covenant_1.4',
);


has template_path => (
    is      => 'lazy',
    isa     => InstanceOf ['Path::Tiny'],
    coerce  => \&path,
    builder => sub($self) {
        return path( dist_file( __PACKAGE__ =~ s/::/-/gr , $self->policy . ".md.tmpl" ) );
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
        state $c = 1;
        my $pkg = __PACKAGE__ . "::Run_" . $c++;
        my $raw = $self->_template->fill_in(
            PACKAGE => $pkg,
            STRICT  => 1,
            BROKEN  => sub(%args) { die $args{error} },
            HASH    => {
                name    => $self->name,
                contact => $self->contact,
                entity  => $self->entity,
                Entity  => $self->Entity,
            },
        );

        $columns = $self->text_columns;
        my sub _wrap($line) {
            return $line if $line =~ /^[ ]{4}/; # ignore preformatted code
            return wrap( "", $line =~ /^[\*\-](?![\*\-]) ?/ ? "  " : "", $line =~ s/[ ][ ]+/ /gr );
        }

        my @lines = map { _wrap($_) } split /\n/, $raw;
        return join( "\n", @lines );

    }
);


has filename => (
    is      => 'ro',
    isa     => NonEmptySimpleStr,
    coerce  => sub($name) { return path($name)->basename },
    default => 'CODE_OF_CONDUCT.md',
);


sub save($self, $dir = undef) {
    my $path = path( $dir // cwd, $self->filename );
    $path->spew_raw( $self->text );
    return $path;
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Software::Policy::CodeOfConduct - generate a Code of Conduct policy

=head1 VERSION

version v0.3.0

=head1 SYNOPSIS

    my $policy = Software::Policy::CodeOfConduct->new(
        name     => 'Foo',
        contact  => 'team-foo@example.com',
        policy   => 'Contributor_Covenant_1.4',
        filename => 'CODE-OF-CONDUCT.md',
    );

    $policy->save($dir); # create CODE-OF-CONDUCT.md in $dir

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

=head2 entity

A generating name for the project. It defaults to "project" but the original templates used "community".

=head2 Entity

A sentence-case (ucfirst) form of L</entity>.

=head2 policy

This is the policy filename. It defaults to "Contributor_Covenant_1.4" which is based on
L<https://www.contributor-covenant.org/version/1/4/code-of-conduct.html>.

Available policies include

=over

=item "Contributor_Covenant_1.4"

=item "Contributor_Covenant_2.0"

=item "Contributor_Covenant_2.1"

=back

=head2 template_path

This is the path to the template file. If omitted, it will assume it is an included file from L</policy>.

This should be a L<Text::Template> file.

=head2 text_columns

This is the number of text columns for word-wrapping the L</text>.

The default is C<78>.

=head2 text

This is the text generated from the template.

=head2 filename

This is the file to be generated.

This defaults to F<CODE_OF_CONDUCT.md>.

=head1 METHODS

=head2 save

    my $path = $policy->save( $dir );

This saves a file named L</filename> in directory C<$dir>.

If C<$dir> is omitted, then it will save the file in the current directory.

=head1 SOURCE

The development version is on github at L<https://github.com/robrwo/perl-Software-Policy-CodeOfConduct>
and may be cloned from L<git://github.com/robrwo/perl-Software-Policy-CodeOfConduct.git>

=head1 SUPPORT

Only the latest version of this module will be supported.

This module requires Perl v5.20 or later.  Future releases may only support Perl versions released in the last ten
years.

=head2 Reporting Bugs

Please report any bugs or feature requests on the bugtracker website
L<https://github.com/robrwo/perl-Software-Policy-CodeOfConduct/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

If the bug you are reporting has security implications which make it inappropriate to send to a public issue tracker,
then see F<SECURITY.md> for instructions how to report security vulnerabilities.

=head1 AUTHOR

Robert Rothenberg <rrwo@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2025 by Robert Rothenberg.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
