# ABSTRACT: Write the POD of each sub from its blurb and the analysis of its code
# PODNAME: Pod::Coverage::More::Generator

package Pod::Coverage::More::Generator 0.005;

use 5.036;
use warnings FATAL => q{all};
use re q{/xsaa};

use Module::Runtime qw{module_notional_filename};
use mro;

use Pod::Coverage::More;
use Pod::Coverage::More::Blurb;
use Pod::Coverage::More::Documentation;


# A generator for the package C<package>, which must be loaded.
# @param   package  Str  the name of the package
# @param   file     Str  optional: the file to read the blurbs from, by default the file that the package was loaded from
# @returns Pod::Coverage::More::Generator  the generator
# @example my $generator = Pod::Coverage::More::Generator->new( package => 'Some::Module', file => 'lib/Some/Module.pm' );
sub new {
    my ( $class, %args ) = @_;
    my $package = $args{package};
    my $file    = $args{file} // $INC{ module_notional_filename($package) };
    return bless( { package => $package, file => $file, coverage => Pod::Coverage::More->new( package => $package ) }, $class );
}

# One section per sub that gets one, in the order of the names of the subs:
# a HASHREF with C<name>, the name of the sub, and C<pod>, the text of its section, which starts with a C<=head2>.
# @returns the sections, as a list
# @example my @sections = $generator->sections;
sub sections {
    my ($self)   = @_;
    my $coverage = $self->{coverage};
    my $blurbs   = defined $self->{file} ? Pod::Coverage::More::Blurb->read_file( $self->{file} ) : {};
    my $analysis = $coverage->analysis;
    my @sections;
    foreach my $name ( sort $coverage->public_subs ) {
        my $blurb = $blurbs->{$name} or next;
        next if $coverage->own_section_for($name);
        next if !_has_tag($blurb) && ( $coverage->section_for($name) || $self->_parent_has_blurb($name) );
        push @sections, { name => $name, pod => _section( $name, $blurb, $analysis->{$name} ) };
    }
    return @sections;
}

# Whether BLURB has a tag, which makes it the documentation of an override rather than a comment on it.
sub _has_tag {
    my ($blurb) = @_;
    return @{ $blurb->{params} } || $blurb->{returns} || @{ $blurb->{throws} } || @{ $blurb->{examples} } ? 1 : 0;
}

# Whether a parent class has a blurb for the sub NAME, which becomes its section when the parent is woven.
# Only a parent from the tree of the package counts: it is woven with the package.  A parent from elsewhere, as an
# installed one, either was woven already, so that its POD documents the sub, or never was, so that its comment is none.
sub _parent_has_blurb {
    my ( $self, $name ) = @_;
    my $tree = _tree_of( $self->{package} ) // return 0;
    foreach my $parent ( @{ mro::get_linear_isa( $self->{package} ) } ) {
        next if $parent eq $self->{package};
        my $file = $INC{ module_notional_filename($parent) } or next;
        next if ( _tree_of($parent) // q{} ) ne $tree;
        $self->{parent_blurbs}{$parent} //= Pod::Coverage::More::Blurb->read_file($file);
        return 1 if $self->{parent_blurbs}{$parent}{$name};
    }
    return 0;
}

# The directory on @INC that PACKAGE was loaded from, or nothing when it was not loaded from a file.
sub _tree_of {
    my ($package) = @_;
    my $notional  = module_notional_filename($package);
    my $file      = $INC{$notional} // return;
    return $file =~ s{/?\Q$notional\E\z}{}r;
}

# Whether the text of a @throws is a sentence already, as "croaks when", because it starts with a word of termination.
# The noun "exception" does not count: "with a Some::Exception" still needs "Dies".
sub _says_how_it_dies {
    my ($throws) = @_;
    return $throws =~ m/\A$Pod::Coverage::More::Documentation::TERMINATION/ && $throws !~ m/\Aexceptions?\b/i;
}

# The text of all the sections, one after another.
# @returns Str  the POD, or the empty string when no sub gets a section
# @example my $pod = $generator->pod;
sub pod {
    my ($self) = @_;
    return join q{}, map { $_->{pod} } $self->sections;
}

# The POD of one sub, from its BLURB and the analysis REC of its code.
sub _section {
    my ( $name, $blurb, $rec ) = @_;
    my @args = _arguments( $blurb, $rec );
    my $pod  = "=head2 $name" . ( @args ? '(' . join( ', ', map { $_->{name} } @args ) . ')' : q{} ) . "\n\n";
    foreach my $paragraph ( @{ $blurb->{description} } ) {
        $pod .= "$paragraph\n\n";
    }

    if (@args) {
        $pod .= "=over 4\n\n";
        foreach my $arg (@args) {
            my @parts = ( "$arg->{sigil}$arg->{name}", $arg->{type} ? $arg->{type}->display_name : (), $arg->{description} ne q{} ? $arg->{description} : () );
            $pod .= '=item ' . join( ' - ', @parts ) . "\n\n";
        }
        $pod .= "=back\n\n";
    }

    my $returns = _returns( $blurb, $rec );
    $pod .= "$returns\n\n" if defined $returns;
    foreach my $throws ( @{ $blurb->{throws} } ) {
        $pod .= _sentence( _says_how_it_dies($throws) ? $throws : "Dies $throws" ) . "\n\n";
    }
    foreach my $example ( @{ $blurb->{examples} } ) {
        $pod .= join( "\n", map { "    $_" } @$example ) . "\n\n";
    }
    return $pod;
}

# The arguments of the heading: the parameters, or the keys of a hash of named arguments, with what the blurb and the code say of each.
sub _arguments {
    my ( $blurb, $rec ) = @_;
    my %documented;
    foreach my $param ( @{ $blurb->{params} } ) {
        $documented{ Pod::Coverage::More::Documentation->bare_name( $param->{name} ) } = $param;
    }
    my @names;
    foreach my $param ( @{ $rec->{params} || [] } ) {
        next if !defined $param->{name} || $param->{source} eq 'invocant' || $param->{name} =~ m/\A\$(?:self|class|proto)\z/;
        if ( $param->{name} =~ m/\A%/ && $param->{keys} ) {
            push @names, map { [ $_, undef ] } @{ $param->{keys} };
            next;
        }
        push @names, [ Pod::Coverage::More::Documentation->bare_name( $param->{name} ), $param ];
    }
    if ( !@names ) {
        foreach my $param ( @{ $blurb->{params} } ) {
            push @names, [ Pod::Coverage::More::Documentation->bare_name( $param->{name} ), undef ];
        }
    }

    my @args;
    foreach my $entry (@names) {
        my ( $name, $param ) = @$entry;
        my $documented = $documented{$name} // {};
        push @args, {
            name        => $name,
            sigil       => ( $documented->{name} // q{} ) =~ m/\A([@%])/ ? $1 : q{},
            type        => $documented->{type}        // ( $param ? $param->{declared} : undef ),
            description => $documented->{description} // q{},
        };
    }
    return @args;
}

# The paragraph of the return value, or undef when neither the blurb nor what the code shows for certain says anything.
sub _returns {
    my ( $blurb, $rec ) = @_;
    my $stated      = $blurb->{returns}      // {};
    my $description = $stated->{description} // q{};
    my @types       = $stated->{type} ? ( $stated->{type} ) : _code_return_types($rec);
    return if !@types && $description eq q{};

    my $text = 'Returns';
    $text .= q{ } . join( q{ or }, _type_texts(@types) ) if @types;
    $text .= ( @types ? q{, } : q{ } ) . $description    if $description ne q{};
    return _sentence($text);
}

# The return types that the code declares, or else those that its literals and objects show for certain.
sub _code_return_types {
    my ($rec) = @_;
    return if !$rec;
    my @declared = @{ $rec->{declared}{returns} || [] };
    return @declared if @declared;
    my ( @types, %seen );
    foreach my $returned ( @{ $rec->{returns} } ) {
        next if $returned->{weak} || !$returned->{constraint} || $returned->{type} eq 'empty';
        push @types, $returned->{constraint} if !$seen{ $returned->{constraint}->display_name }++;
    }
    return @types;
}

# Constraints as the POD writes them in a Returns paragraph: an instance of one class in prose, a union as its alternatives,
# and any other by its name.  Type::Tiny flattens a union of unions, so its members are no unions.
sub _type_texts {
    my (@types) = @_;
    my @texts;
    foreach my $type (@types) {
        my @members = $type->isa('Type::Tiny::Union') ? @{ $type->type_constraints } : ($type);
        foreach my $member (@members) {
            push @texts, $member->isa('Type::Tiny::Class') ? 'a ' . $member->class . ' object' : $member->display_name;
        }
    }
    return @texts;
}

sub _sentence {
    my ($text) = @_;
    $text =~ s/\s+\z//;
    $text = ucfirst $text;
    return $text =~ m/[.!?]\z/ ? $text : "$text.";
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Pod::Coverage::More::Generator - Write the POD of each sub from its blurb and the analysis of its code

=head1 VERSION

version 0.005

=head1 SYNOPSIS

    use Pod::Coverage::More::Generator;

    my $generator = Pod::Coverage::More::Generator->new( package => 'Pod::Coverage::More::Generator' );
    print $generator->pod;

=head1 DESCRIPTION

Writes a POD section for each public sub that has a blurb, as L<Pod::Coverage::More::Blurb> reads it,
and no section in the POD of its own package.  A sub without a blurb gets no section:
the blurb is how a sub opts in, as C<# ABSTRACT:> is how a module does.

An override, a sub that the POD or a blurb of a parent class documents, gets a section when its blurb has at least one tag,
C<@param>, C<@returns>, C<@throws> or C<@example>, and then L<Pod::Coverage::More> checks it against that section.
A comment with no tag above an override is no documentation of it: it gets no section,
and the checks read the section of the parent, as they do for an override with no comment.

A section says what the blurb says, and fills in what the code declares where the blurb is silent:

=over 4

=item The arguments are the parameters of the sub, and the keys of a hash of named arguments.
A sub whose code shows no parameters, as a stub, takes the arguments of its blurb.

=item The type of an argument is the type in its C<@param>, or else the type that the code declares.
A C<@param> that names a list parameter with its sigil, as C<@param @paths Str>, gives the type of each element,
and its item keeps the sigil, as C<=item @paths - Str>.

=item The return value is the C<@returns>, or else the type that the code declares,
or else the types of the values that it returns for certain, as literals and C<bless> into a class.

=item Each C<@throws> is a sentence of its own.  It starts with "Dies", unless its text starts with a verb that says how,
such as C<croaks when>.

=back

The result of an operator and the uses of a variable are only probable, so they are never written.
The sections follow the forms that L<Pod::Coverage::More::Documentation> reads, so that L<Pod::Coverage::More> can check them.

=head1 METHODS

=head2 new(package, file)

A generator for the package C<package>, which must be loaded.

=over 4

=item package - Str - the name of the package

=item file - Str - optional: the file to read the blurbs from, by default the file that the package was loaded from

=back

Returns a Pod::Coverage::More::Generator object, the generator.

    my $generator = Pod::Coverage::More::Generator->new( package => 'Some::Module', file => 'lib/Some/Module.pm' );

=head2 pod

The text of all the sections, one after another.

Returns Str, the POD, or the empty string when no sub gets a section.

    my $pod = $generator->pod;

=head2 sections

One section per sub that gets one, in the order of the names of the subs: a HASHREF with C<name>, the name of the sub, and C<pod>, the text of its section, which starts with a C<=head2>.

Returns the sections, as a list.

    my @sections = $generator->sections;

=head1 SEE ALSO

Please see those modules/websites for more information related to this module.

=over 4

=item *

L<Pod::Coverage::More|Pod::Coverage::More>

=item *

L<Pod::Coverage::More::Blurb>

=item *

L<Pod::Coverage::More>

=back

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<https://github.com/teodesian/Pod-Coverage-More/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHORS

Current Maintainers:

=over 4

=item *

George S. Baugh <teodesian@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014-2026 George S. Baugh


Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:
The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.
THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

=cut
