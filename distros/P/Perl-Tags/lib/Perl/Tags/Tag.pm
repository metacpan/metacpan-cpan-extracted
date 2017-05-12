package Perl::Tags::Tag;
use strict; use warnings;

use overload q("") => \&to_string;

our $VERSION = '0.32';

=head2 C<new>

Returns a new tag object

=cut

sub new {
    my $class = shift;
    my %options = @_;

    $options{type} = $class->type;

    # chomp and escape line
    chomp (my $line = $options{line});

    $line =~ s{\\}{\\\\}g;
    $line =~ s{/}{\\/}g;
    # $line =~ s{\$}{\\\$}g;

    my $self = bless {
        name   => $options{name},
        file   => $options{file},
        type   => $options{type},
        is_static => $options{is_static},
        line   => $line,
        linenum => $options{linenum},
        exts   => $options{exts}, # exuberant?
        pkg    => $options{pkg},  # package name
    }, $class;

    $self->modify_options();
    return $self;
}

=head2 C<type>, C<modify_options>

Abstract methods

=cut

sub type {
    die "Tried to call 'type' on virtual superclass";
}

sub modify_options { return } # no change

=head2 C<to_string>

A tag stringifies to an appropriate line in a ctags file.

=cut

sub to_string {
    my $self = shift;

    my $name = $self->{name} or die;
    my $file = $self->{file} or die;
    my $line = $self->{line} or die;
    my $linenum = $self->{linenum};
    my $pkg  = $self->{pkg} || '';

    my $tagline = "$name\t$file\t/$line/";

    # Exuberant extensions
    if ($self->{exts}) {
        $tagline .= qq(;"\t$self->{type});
        $tagline .= "\tline:$linenum";
        $tagline .= ($self->{is_static} ? "\tfile:" : '');
        $tagline .= ($self->{pkg} ? "\tclass:$self->{pkg}" : '');
    }
    return $tagline;
}

=head2 C<on_register>

Allows tag to meddle with process when registered with the main tagger object.
Return false if want to prevent registration (e.g. for control tags such as
C<Perl::Tags::Tag::Recurse>.)

=cut

sub on_register {
    # my $self = shift;
    # my $tags = shift;
    # .... do stuff in subclasses

    return 1;  # or undef to prevent registration
}

=head1 C<Perl::Tags::Tag::Package>

=head2 C<type>: p

=head2 C<modify_options>

Sets static=0

=head2 C<on_register>

Sets the package name

=cut

package Perl::Tags::Tag::Package;
our @ISA = qw/Perl::Tags::Tag/;

    # QUOTE:
        # Make a tag for this package unless we're told not to.  A
        # package is never static.

sub type { 'p' }

sub modify_options {
    my $self = shift;
    $self->{is_static} = 0;
}

sub on_register {
    my ($self, $tags) = @_;
    $tags->{current}{package_name} = $self->{name};
}

=head1 C<Perl::Tags::Tag::Var>

=head2 C<type>: v

=head2 C<on_register>

        Make a tag for this variable unless we're told not to.  We
        assume that a variable is always static, unless it appears
        in a package before any sub.  (Not necessarily true, but
        it's ok for most purposes and Vim works fine even if it is
        incorrect)
            - pltags.pl comments

=cut

package Perl::Tags::Tag::Var;
our @ISA = qw/Perl::Tags::Tag/;

sub type { 'v' }

    # QUOTE:

sub on_register {
    my ($self, $tags) = @_;
    $self->{is_static} = ( $tags->{current}{package_name} || $tags->{current}{has_subs} ) ? 1 : 0;

    return 1;
}
=head1 C<Perl::Tags::Tag::Sub>

=head2 C<type>: s

=head2 C<on_register>

        Make a tag for this sub unless we're told not to.  We assume
        that a sub is static, unless it appears in a package.  (Not
        necessarily true, but it's ok for most purposes and Vim works
        fine even if it is incorrect)
            - pltags comments

=cut

package Perl::Tags::Tag::Sub;
our @ISA = qw/Perl::Tags::Tag/;

sub type { 's' }

sub on_register {
    my ($self, $tags) = @_;
    $tags->{current}{has_subs}++ ;
    $self->{is_static}++ unless $tags->{current}{package_name};

    return 1;
} 

=head1 C<Perl::Tags::Tag::Constant>

=head2 C<type>: c

=cut

package Perl::Tags::Tag::Constant;
our @ISA = qw/Perl::Tags::Tag/;

sub type { 'c' }

=head1 C<Perl::Tags::Tag::Label>

=head2 C<type>: l

=cut

package Perl::Tags::Tag::Label;
our @ISA = qw/Perl::Tags::Tag/;

sub type { 'l' }

=head1 C<Perl::Tags::Tag::Recurse>

=head2 C<type>: dummy

This is a pseudo-tag, see L<Perl::Tags/register>.

=head2 C<on_register>

Recurse adding this new module to the queue.

=cut

package Perl::Tags::Tag::Recurse;
our @ISA = qw/Perl::Tags::Tag/;

use Module::Locate qw/locate/;

sub type { 'dummy' }

sub on_register {
    my ($self, $tags) = @_;

    my $name = $self->{name};
    my $path;
    eval {
        $path = locate( $name ); # or warn "Couldn't find path for $name";
    };
    # return if $@;
    return unless $path;
    $tags->queue( { file=>$path, level=>$tags->{current}{level}+1 , refresh=>0} );
    return; # don't get added
}

1;
